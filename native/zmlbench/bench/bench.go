// Package bench is ZML-Lab's load generator: it replays ShareGPT
// conversations against an OpenAI-compatible server with a fixed number of
// concurrent workers and reports one Event per streamed chunk. The C API
// (../capi) streams them as CSV to the app.
package bench

import (
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	openai "github.com/openai/openai-go"
	"github.com/openai/openai-go/option"
)

type Server string

const (
	ServerOpenAI  Server = "openai"
	ServerZML     Server = "zml"
	ServerVLLM    Server = "vllm"
	ServerUnknown Server = "unknown"
)

// Options configures a run. The zero value of each field falls back to a
// default.
type Options struct {
	// BaseURL is the API root, e.g. http://127.0.0.1:8000/v1/.
	BaseURL string
	// APIKey is sent as a Bearer token. Empty falls back to $OPENAI_API_KEY.
	APIKey string
	Model  string
	// Concurrency is the number of workers, each with one request in flight.
	Concurrency int
	// Duration stops the run after this long; 0 runs until ctx is cancelled
	// or every conversation has been sent.
	Duration            time.Duration
	MaxCompletionTokens int64
	// Mode is "all" (every prompt of a conversation, accumulating the
	// replies) or "first" (only its first prompt).
	Mode string
	// SequenceType is "long" (whole prompts) or "short" (at most 512 chars).
	SequenceType string
	SessionID    string
	// Server labels the events; empty detects it from the response's
	// Server header.
	Server Server
	// Logf receives progress lines. Nil logs with log.Printf.
	Logf func(format string, args ...any)
}

func (o *Options) withDefaults() {
	if o.Concurrency <= 0 {
		o.Concurrency = 128
	}
	if o.Model == "" {
		o.Model = "meta-llama/Llama-3.1-8B-Instruct"
	}
	if o.MaxCompletionTokens <= 0 {
		o.MaxCompletionTokens = 256
	}
	if o.Mode == "" {
		o.Mode = "all"
	}
	if o.SequenceType == "" {
		o.SequenceType = "long"
	}
	if o.SessionID == "" {
		o.SessionID = time.Now().Local().Format("2006-01-02-15-04-05")
	}
	if o.Logf == nil {
		o.Logf = log.Printf
	}
}

// Validate reports an invalid mode or sequence type.
func (o Options) Validate() error {
	if o.Mode != "" && o.Mode != "first" && o.Mode != "all" {
		return fmt.Errorf("mode must be either 'first' or 'all'")
	}
	if o.SequenceType != "" && o.SequenceType != "long" && o.SequenceType != "short" {
		return fmt.Errorf("sequence_type must be either 'long' or 'short'")
	}
	return nil
}

// Event is one streamed chunk of one request (or, with Error set, a request
// that failed).
type Event struct {
	Timestamp        int64  `json:"timestamp"`
	RequestID        string `json:"request_id"`
	Seq              int    `json:"seq"`
	Token            string `json:"token"`
	RequestTimestamp int64  `json:"request_timestamp"`
	InputTokens      uint   `json:"inputs_tokens"`
	OutputTokens     uint   `json:"outputs_tokens"`
	Server           Server `json:"server"`
	Concurrency      int    `json:"concurrency"`
	SessionID        string `json:"session_id"`
	Error            string `json:"error"`
}

// Stats summarises a finished run.
type Stats struct {
	Server Server
	Events int
	Errors int
}

type ShareGPTFile []Conversation

type Conversation struct {
	ID      string   `json:"id"`
	Prompts []Prompt `json:"conversations"`
}

type Prompt struct {
	From  string `json:"from"`
	Value string `json:"value"`
}

// LoadShareGPT reads a ShareGPT JSON file.
func LoadShareGPT(path string) (ShareGPTFile, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("Error reading file @%s: %w", path, err)
	}
	file := ShareGPTFile{}
	if err := json.Unmarshal(data, &file); err != nil {
		return nil, fmt.Errorf("Error unmarshalling file @%s: %w", path, err)
	}
	return file, nil
}

const conversationDateLayout = "2006-01-02T15:04:05.000000000Z07:00"

func newConversationPrefix(now time.Time) string {
	return fmt.Sprintf("Date: %s. ", now.UTC().Format(conversationDateLayout))
}

// DetectServer asks the server who it is (its Server response header).
func DetectServer(client *http.Client, baseURL, apiKey string) (Server, error) {
	req, err := http.NewRequest(http.MethodPost, baseURL+"/chat/completions", nil)
	if err != nil {
		return ServerUnknown, err
	}
	req.Header.Set("Content-Type", "application/json")
	if apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+apiKey)
	}
	resp, err := client.Do(req)
	if err != nil {
		return ServerUnknown, fmt.Errorf("Error connecting to server: %w", err)
	}
	resp.Body.Close()
	switch resp.Header.Get("server") {
	case "openai":
		return ServerOpenAI, nil
	case "zml/httpd":
		return ServerZML, nil
	case "uvicorn":
		return ServerVLLM, nil
	}
	return ServerUnknown, nil
}

// Run replays conversations against the server until ctx is cancelled,
// opts.Duration elapses, or every conversation was sent. sink receives every
// event, from a single goroutine, in order; Run returns once it has seen the
// last one.
func Run(ctx context.Context, opts Options, conversations []Conversation, sink func(Event)) (Stats, error) {
	if err := opts.Validate(); err != nil {
		return Stats{}, err
	}
	opts.withDefaults()

	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	if opts.Duration > 0 {
		go func() {
			select {
			case <-time.After(opts.Duration):
				cancel()
			case <-ctx.Done():
			}
		}()
	}

	httpClient := &http.Client{
		Transport: &http.Transport{
			MaxIdleConns:        opts.Concurrency,
			MaxIdleConnsPerHost: opts.Concurrency,
			MaxConnsPerHost:     opts.Concurrency,
		},
	}
	defer httpClient.CloseIdleConnections()

	stats := Stats{Server: opts.Server}
	if stats.Server == "" {
		server, err := DetectServer(httpClient, opts.BaseURL, opts.APIKey)
		if err != nil {
			return stats, err
		}
		stats.Server = server
		opts.Logf("Discovering server type: %s\n", stats.Server)
	}

	queries := make(chan Conversation, len(conversations))
	for _, c := range conversations {
		queries <- c
	}
	close(queries)

	events := make(chan Event, 16*1024)
	sinkDone := make(chan struct{})
	go func() {
		defer close(sinkDone)
		for event := range events {
			sink(event)
			stats.Events++
		}
	}()

	clientOptions := []option.RequestOption{
		option.WithHTTPClient(httpClient),
		option.WithBaseURL(opts.BaseURL),
	}
	if opts.APIKey != "" {
		clientOptions = append(clientOptions, option.WithAPIKey(opts.APIKey))
	}
	client := openai.NewClient(clientOptions...)

	var errors atomic.Int64
	var wg sync.WaitGroup
	opts.Logf("Starting %d workers\n", opts.Concurrency)
	for i := 0; i < opts.Concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case query, ok := <-queries:
					if !ok {
						return
					}
					runConversation(ctx, client, opts, stats.Server, query, events, &errors)
				}
			}
		}()
	}

	wg.Wait()
	close(events)
	<-sinkDone
	stats.Errors = int(errors.Load())
	return stats, nil
}

// runConversation sends a conversation's user prompts in turn (only the first
// with Mode "first"), each request carrying the replies so far.
func runConversation(
	ctx context.Context,
	client *openai.Client,
	opts Options,
	server Server,
	query Conversation,
	events chan<- Event,
	errors *atomic.Int64,
) {
	promptData := make([]openai.ChatCompletionMessageParamUnion, 0)
	conversationPrefix := newConversationPrefix(time.Now())
	isFirstTurn := true
	seq := 0
	for j, prompt := range query.Prompts {
		if j > 0 && opts.Mode == "first" {
			break
		}
		if prompt.From == "gpt" {
			continue
		}

		value := prompt.Value
		if isFirstTurn {
			value = conversationPrefix + value
			isFirstTurn = false
		}
		if opts.SequenceType != "long" && len(value) > 512 {
			value = value[:511]
		}
		promptData = append(promptData, openai.UserMessage(value))

		requestID := fmt.Sprintf("%s-%d", query.ID, j)
		nCompletionTokens := uint(0)
		requestTimestamp := time.Now().UnixNano()

		stream := client.Chat.Completions.NewStreaming(ctx,
			openai.ChatCompletionNewParams{
				Messages:            openai.F(promptData),
				MaxCompletionTokens: openai.F(opts.MaxCompletionTokens),
				Model:               openai.F(opts.Model),
				StreamOptions: openai.F(openai.ChatCompletionStreamOptionsParam{
					IncludeUsage: openai.F(true),
				}),
			},
		)

		var acc strings.Builder
		for stream.Next() {
			evt := stream.Current()
			token := ""
			if len(evt.Choices) > 0 {
				token = evt.Choices[0].Delta.Content
				nCompletionTokens += 1
			}
			events <- Event{
				Timestamp:        time.Now().UnixNano(),
				Seq:              seq,
				Token:            token,
				RequestID:        requestID,
				RequestTimestamp: requestTimestamp,
				InputTokens:      uint(evt.Usage.PromptTokens),
				OutputTokens:     nCompletionTokens,
				Server:           server,
				Concurrency:      opts.Concurrency,
				SessionID:        opts.SessionID,
			}
			acc.WriteString(token)
			seq += 1
		}

		promptData = append(promptData, openai.AssistantMessage(acc.String()))
		if err := stream.Err(); err != nil {
			if ctx.Err() == nil {
				errors.Add(1)
				events <- Event{
					Timestamp:        time.Now().UnixNano(),
					Seq:              seq,
					RequestID:        requestID,
					RequestTimestamp: requestTimestamp,
					Server:           server,
					Concurrency:      opts.Concurrency,
					SessionID:        opts.SessionID,
					Error:            err.Error(),
				}
			}
			// No Close: on a cancelled request the stream has no decoder and
			// Close panics.
			return
		}
		stream.Close()
	}
}

// CSVHeader is the column order of the event CSV.
var CSVHeader = []string{
	"timestamp",
	"request_id",
	"seq",
	"token",
	"request_timestamp",
	"inputs_tokens",
	"outputs_tokens",
	"concurrency",
	"server",
	"session_id",
	"error",
}

// CSVWriter writes events as the reports' CSV, flushing after every row.
type CSVWriter struct {
	w *csv.Writer
}

// NewCSVWriter writes the header and returns a writer for the rows.
func NewCSVWriter(w io.Writer) (*CSVWriter, error) {
	cw := &CSVWriter{w: csv.NewWriter(w)}
	if err := cw.w.Write(CSVHeader); err != nil {
		return nil, err
	}
	cw.w.Flush()
	return cw, cw.w.Error()
}

func (cw *CSVWriter) Write(event Event) error {
	if err := cw.w.Write([]string{
		fmt.Sprintf("%d", event.Timestamp),
		event.RequestID,
		fmt.Sprintf("%d", event.Seq),
		event.Token,
		fmt.Sprintf("%d", event.RequestTimestamp),
		fmt.Sprintf("%d", event.InputTokens),
		fmt.Sprintf("%d", event.OutputTokens),
		fmt.Sprintf("%d", event.Concurrency),
		string(event.Server),
		event.SessionID,
		event.Error,
	}); err != nil {
		return err
	}
	cw.w.Flush()
	return cw.w.Error()
}
