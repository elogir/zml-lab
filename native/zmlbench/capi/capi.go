// Command capi builds the benchmarker as the C shared library ZML-Lab loads
// over Dart FFI (hook/build.dart builds and bundles it):
//
//	go build -buildmode=c-shared -o libzmlbench.dylib ./capi
//
// A run streams its event CSV and its progress lines to a callback, which
// may be invoked from any thread.
// Every buffer handed to the callback belongs to the caller, who releases it
// with zmlbench_free.
package main

/*
#include <stdint.h>
#include <stdlib.h>

// kind: 0 = CSV chunk, 1 = log line, 2 = done (JSON summary; last call for
// this run).
typedef void (*zmlbench_callback)(int64_t run, int32_t kind, uint8_t *data, int64_t len);

static inline void zmlbench_call(zmlbench_callback cb, int64_t run, int32_t kind, uint8_t *data, int64_t len) {
	cb(run, kind, data, len);
}
*/
import "C"

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
	"unsafe"

	"zmlbench/bench"
)

const (
	kindCSV  = 0
	kindLog  = 1
	kindDone = 2
)

// Version of the C API; bumped on any incompatible change.
const apiVersion = 1

// config is zmlbench_start's JSON argument.
type config struct {
	URL                 string `json:"url"`
	APIKey              string `json:"api_key"`
	Model               string `json:"model"`
	Concurrency         int    `json:"concurrency"`
	DurationS           int    `json:"duration_s"`
	MaxCompletionTokens int64  `json:"max_completion_tokens"`
	Mode                string `json:"mode"`
	SequenceType        string `json:"sequence_type"`
	InputFile           string `json:"input_file"`
	SessionID           string `json:"session_id"`
	// FlushMS batches CSV rows into one callback per interval (default 50).
	FlushMS int `json:"flush_ms"`
}

// summary is the done event's JSON payload.
type summary struct {
	Error     string `json:"error,omitempty"`
	Server    string `json:"server,omitempty"`
	Events    int    `json:"events"`
	Errors    int    `json:"errors"`
	ElapsedMS int64  `json:"elapsed_ms"`
}

var (
	nextRun atomic.Int64
	runsMu  sync.Mutex
	runs    = map[int64]context.CancelFunc{}
)

// run posts its output to the callback.
type run struct {
	id int64
	cb C.zmlbench_callback
}

func (r run) post(kind int32, data []byte) {
	var p unsafe.Pointer
	if len(data) > 0 {
		p = C.CBytes(data)
	}
	C.zmlbench_call(r.cb, C.int64_t(r.id), C.int32_t(kind), (*C.uint8_t)(p), C.int64_t(len(data)))
}

func (r run) logf(format string, args ...any) {
	line := fmt.Sprintf(format, args...)
	for len(line) > 0 && line[len(line)-1] == '\n' {
		line = line[:len(line)-1]
	}
	r.post(kindLog, []byte(line))
}

// lockedBuffer collects CSV rows between flushes.
type lockedBuffer struct {
	mu  sync.Mutex
	buf bytes.Buffer
}

func (b *lockedBuffer) Write(p []byte) (int, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.Write(p)
}

func (b *lockedBuffer) take() []byte {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.buf.Len() == 0 {
		return nil
	}
	out := bytes.Clone(b.buf.Bytes())
	b.buf.Reset()
	return out
}

// zmlbench_start starts a run described by configJSON and returns its id
// (> 0). Everything after that — the dataset loading included — happens in
// the background and is reported through cb, ending with exactly one done
// event (which carries the error, if the run failed).
//
//export zmlbench_start
func zmlbench_start(configJSON *C.char, cb C.zmlbench_callback) C.int64_t {
	r := run{id: nextRun.Add(1), cb: cb}
	raw := C.GoString(configJSON)
	ctx, cancel := context.WithCancel(context.Background())
	runsMu.Lock()
	runs[r.id] = cancel
	runsMu.Unlock()

	go func() {
		start := time.Now()
		s := execute(ctx, r, raw)
		s.ElapsedMS = time.Since(start).Milliseconds()
		runsMu.Lock()
		delete(runs, r.id)
		runsMu.Unlock()
		cancel()
		payload, _ := json.Marshal(s)
		r.post(kindDone, payload)
	}()
	return C.int64_t(r.id)
}

func execute(ctx context.Context, r run, raw string) summary {
	var cfg config
	if err := json.Unmarshal([]byte(raw), &cfg); err != nil {
		return summary{Error: fmt.Sprintf("bad config: %v", err)}
	}
	opts := bench.Options{
		BaseURL:             cfg.URL,
		APIKey:              cfg.APIKey,
		Model:               cfg.Model,
		Concurrency:         cfg.Concurrency,
		Duration:            time.Duration(cfg.DurationS) * time.Second,
		MaxCompletionTokens: cfg.MaxCompletionTokens,
		Mode:                cfg.Mode,
		SequenceType:        cfg.SequenceType,
		SessionID:           cfg.SessionID,
		Logf:                r.logf,
	}
	if err := opts.Validate(); err != nil {
		return summary{Error: err.Error()}
	}

	conversations, err := bench.LoadShareGPT(cfg.InputFile)
	if err != nil {
		return summary{Error: err.Error()}
	}
	r.logf("ShareGPT file read successfully")
	r.logf("Number of conversations: %d", len(conversations))
	if ctx.Err() != nil {
		return summary{}
	}

	var out lockedBuffer
	csvWriter, err := bench.NewCSVWriter(&out)
	if err != nil {
		return summary{Error: err.Error()}
	}

	flushEvery := time.Duration(cfg.FlushMS) * time.Millisecond
	if flushEvery <= 0 {
		flushEvery = 50 * time.Millisecond
	}
	stopFlush := make(chan struct{})
	flushed := make(chan struct{})
	go func() {
		defer close(flushed)
		ticker := time.NewTicker(flushEvery)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				if chunk := out.take(); chunk != nil {
					r.post(kindCSV, chunk)
				}
			case <-stopFlush:
				if chunk := out.take(); chunk != nil {
					r.post(kindCSV, chunk)
				}
				return
			}
		}
	}()

	stats, err := bench.Run(ctx, opts, conversations, func(event bench.Event) {
		if err := csvWriter.Write(event); err != nil {
			r.logf("failed to write CSV record: %v", err)
		}
	})
	close(stopFlush)
	<-flushed

	s := summary{Server: string(stats.Server), Events: stats.Events, Errors: stats.Errors}
	if err != nil {
		s.Error = err.Error()
	}
	return s
}

// zmlbench_stop asks a run to finish: in-flight requests are cancelled, the
// remaining CSV is flushed, then the done event follows. Unknown or finished
// runs are ignored.
//
//export zmlbench_stop
func zmlbench_stop(id C.int64_t) {
	runsMu.Lock()
	cancel := runs[int64(id)]
	runsMu.Unlock()
	if cancel != nil {
		cancel()
	}
}

// zmlbench_free releases a buffer passed to the callback.
//
//export zmlbench_free
func zmlbench_free(p unsafe.Pointer) {
	C.free(p)
}

// zmlbench_version returns the C API version.
//
//export zmlbench_version
func zmlbench_version() C.int32_t {
	return apiVersion
}

func main() {}
