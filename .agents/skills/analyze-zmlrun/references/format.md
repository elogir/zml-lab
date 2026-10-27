# The perf run format

One gzipped JSON Lines file per run (`.jsonl.gz`): one JSON object per line, each with a `type`. The full spec is ZML-Lab's `docs/perf-run-format.md`.
- The first line is `meta.json`, with `"type": "meta"`.
- Then come `"type": "request"` lines, one per HTTP request, with the arrival time of every chunk it streamed.
- Then come `"type": "chip"` lines, one per accelerator sample per device.

```jsonc
{"type":"meta","schema_version":1,"t0_unix_us":1792876902319189,"run_id":"p-…","label":"zml · c=64", …}
{"type":"request","id":"QWJhYvA_0-0","conversation":"QWJhYvA_0","turn":0,"sent_us":0,"end_us":4754177,"input_tokens":120,"output_tokens":258,"error":null,"chunk_us":[866563,916373,…],"answer_chars":[0,0,…],"reasoning_chars":[2,5,…]}
{"type":"chip","t_us":-1153562,"device":0,"kind":"cuda","name":"NVIDIA GB300","util_percent":0,"power_w":497.544, …}
```

`zcat x.jsonl.gz | jq -c 'select(.type == "request")' | head` shows the raw lines.

## The clock

Times in the file are integer **microseconds since `t0_unix_us`** (in the meta line), and t0 is when the run's first request was sent. Chip samples taken before that have negative times. Every time comes from the clock of the machine that ran the benchmark (the client), so requests and chip samples share it. The server's own clock is never involved: compare times with server logs only roughly, allowing for clock skew.

`scripts/zmlrun.py` turns them back into **nanoseconds since the Unix epoch** (`ts_ns`, `request_ts_ns`) in its `events` and `chips` views.

## Lines

`request`:

| Field | Meaning |
| --- | --- |
| `id` | `<conversation>-<turn>`: one HTTP request (see below) |
| `conversation`, `turn` | The two halves of `id` |
| `sent_us` | When the request was sent |
| `chunk_us` | When each streamed chunk arrived, empty ones included: the opening role chunk, the finish chunk and the usage chunk |
| `answer_chars` | Per chunk, the characters of answer text (code points). The text itself isn't kept |
| `reasoning_chars` | Per chunk, the characters of reasoning (thinking) text, streamed as `reasoning_content` or `reasoning` |
| `end_us` | When the response ended: the usage chunk arrived (the last chunk) or the error did. `null` when the run's end cut the request off, or the server sends no usage |
| `input_tokens` | Prompt tokens, from the usage chunk. `null` when not reported |
| `output_tokens` | Chunks with a choice. The role and finish chunks count too |
| `error` | `null`, or why the request failed |

`chip`:

| Field | Meaning |
| --- | --- |
| `t_us` | When the sample arrived |
| `device` | Device index in zml-smi |
| `kind` | `cuda` · `rocm` · `oneapi` · `neuron` · `tpu` |
| `name` | Device name |
| `util_percent` | Utilization: the share of time a kernel was running, not a measure of FLOP efficiency |
| `power_w`, `power_limit_w` | Power draw and its limit |
| `temperature_c` | Temperature |
| `mem_used_bytes`, `mem_total_bytes` | Device memory. Servers usually preallocate their KV cache, so "used" is often near the total |
| `clock_graphics_mhz`, `clock_mem_mhz` | Clocks |
| `pcie_tx_kbps`, `pcie_rx_kbps` | PCIe traffic |

A metric the device doesn't report is left out of its line. A run without chip samples (zml-smi wasn't reachable) has no chip lines.

**`request_id` is `<conversation id>_<n>-<turn>`.** `<turn>` is the message's index in the ShareGPT conversation, so a conversation's user turns are 0, 2, 4, …. Each turn is its own request. With `params.turns = "first"`, only turn 0 is sent.

- **Each prompt holds the conversation so far.** It starts with a `Date: <timestamp>.` prefix, unique per conversation, which defeats prefix caching across conversations. Then come the earlier user turns, and **the server's own earlier answers**: only their answer text (`content`), never their reasoning.
- **The order is deterministic.** On the same dataset, the same `request_id` gets the same prompt, but **only for first turns**. A later turn embeds that server's earlier answer, so it differs from run to run and from server to server. A server that streams its thinking as `content` gets much longer later-turn prompts than one that sends it as `reasoning_content`. Pair runs request by request on first turns only.

**Prompt length of an unfinished request.** It's unknown (there's no usage chunk). To estimate it, add up:
- the conversation's earlier user turns, from the dataset file named in `meta.dataset`;
- the server's earlier answers in this run (their `token_chars` ÷ about 4);
- the new user turn.

ZML-Lab keeps the dataset under `~/Library/Application Support/ZML-Lab/`.

**A request is finished** when it has an end (`end_us`): its usage chunk arrived or it failed. Requests still streaming when the run's duration ran out never finish: they have no usage, and their latency and length are truncated.

## meta.json

Every field is optional unless marked otherwise.

```jsonc
{
  "type": "meta", "schema_version": 1,        // required
  "t0_unix_us": 1792876902319189,             // required: the times' origin
  "run_id": "p-…",                            // required
  "label": "…",                               // how the run is named in charts
  "notes": "", "tags": [],
  "started_at": "…", "ended_at": "…",         // ISO 8601, UTC
  "cancelled": false,                         // stopped before its duration
  "app": { "benchmarker_api": 2 },
  "client": { "os": "…", "host": "…" },       // the machine that ran the benchmark
  "target": { "url": "http://host:port/v1/", "machine": "…" },
  "server": {
    "kind": "zml",                            // detected from the HTTP Server header: zml (llmd) | vllm | openai | unknown
    "version": "…",                           // auto for vLLM (/version), else manual
    "commit": "…"
  },
  "model": { "name": "…" },
  "hardware": { "description": "4x GB300", "chips": [{ "device": 0, "kind": "cuda", "name": "…", "driver_version": "…" }] },
  "params": {
    "duration_s": 30, "concurrency": 16,       // concurrency = requests always in flight from the client
    "max_completion_tokens": null,            // null: no cap sent (the server may have its own default)
    "ignore_eos": false,                      // true: every reply runs to the cap
    "prompts": "long",                        // long | short (prompts cut to 512 chars)
    "turns": "all",                           // all | first
    "warmup": true                            // the server was warmed up first, at this concurrency; none of it is recorded
  },
  "dataset": { "name": "ShareGPT_V3_unfiltered_cleaned_split.json", "sha256": "…" },
  "chip_metrics": { "url": "…", "interval_ms": 500 },  // null: no chip samples
  "summary": { "requests": 0, "tokens_per_second": 0, "joules_per_token": 0 }  // recorder's own numbers
}
```

The warm-up, when on, ran before the measured run:
1. Prefill: `concurrency` requests at once.
2. Decode: a few tokens each.
3. Mixed: half of them restarted beside the others' decoding.

Its requests were cancelled at the instant the measured ones were sent, so the run starts on a busy, warm server, with no idle gap between the two.

## Metric definitions (DuckDB SQL)

A **token** is a chunk that carries text, answer or reasoning. Empty chunks don't count. Over `zmlrun.py`'s views:

```sql
-- TTFT
SELECT quantile_cont((first_token_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) FROM requests
WHERE first_token_ns IS NOT NULL;
-- Inter-token latency: gaps between consecutive tokens of a request
SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99]) FROM gaps;
-- Throughput: tokens over the time from the first request sent to the last event
SELECT (SELECT count(*) FROM tokens) / ((max(ts_ns) - min(request_ts_ns)) / 1e9) FROM events;
```

**Energy:** integrate each device's power over consecutive samples (trapezoids) and sum the devices. Divide by the run's token count to get J/token.

**Time series:** one point every 100 ms from `t0` (the first request sent). It gives:
- tokens/s over the trailing second;
- `in_flight`: sent and not finished;
- `waiting`: in flight with no first token yet, either queued or in prefill.

A request that never finished stays in flight until the end. `scripts/zmlrun.py` builds this as the `series` view and adds `decoding = in_flight - waiting`, which estimates how many sequences the server is decoding at once.

## Views `zmlrun.py sql` creates

| View | Columns |
| --- | --- |
| `lines` | the file's lines as is, every field a column (null where a line doesn't have it) |
| `events` | the stream as the benchmarker logged it: a row per chunk, plus one for a request's end when that isn't its last chunk (an error). `ts_ns`, `request_id`, `seq` (counts a conversation's rows across its turns), `request_ts_ns`, `token_chars` (answer), `reasoning_chars`, `output_tokens`, `input_tokens` (on the request's end), `error` (`''` or the error, on its end), `ends`, `is_token` |
| `tokens` | `events` where `is_token` |
| `requests` | `request_id`, `conversation`, `turn`, `sent_ns`, `first_token_ns`, `last_token_ns` (last text chunk), `last_ns` (last event, including usage), `tokens` (text chunks), `output_tokens`, `input_tokens`, `failed`, `error`, `ended` |
| `gaps` | `request_id`, `prev_ns`, `ts_ns`, `gap_ms`: consecutive tokens of one request |
| `series` | `i`, `elapsed_ms`, `t_ns` (end of the 100 ms bucket), `tokens_per_second`, `in_flight`, `waiting`, `decoding` |
| `chips` | `ts_ns` and the chip fields, all of them (null when a device doesn't report one) |
| `meta` | one row, `meta` JSON |

With several files, every view is prefixed `a_`, `b_`, ….

**The benchmarker's own `duckdb/report.sql` differs from these definitions.** It counts empty chunks too, and takes TTFT from `seq = 0`, which only a conversation's first turn has. Don't mix numbers computed the two ways.
