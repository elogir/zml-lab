# The .zmlrun.parquet format (v1)

One Parquet file per run (zstd). It holds:
- one table, with a row per streamed chunk (`source = 'event'`) and a row per accelerator sample (`source = 'chip'`);
- `meta.json` in the footer's key-value metadata, under the key `zml.run`.

```sql
CREATE VIEW run    AS SELECT * FROM read_parquet('x.zmlrun.parquet');
CREATE VIEW events AS SELECT * FROM run WHERE source = 'event';
CREATE VIEW chips  AS SELECT * FROM run WHERE source = 'chip';
SELECT decode(value)::JSON AS meta
FROM parquet_kv_metadata('x.zmlrun.parquet') WHERE decode(key) = 'zml.run';
-- Several runs: read_parquet([...], filename = true)
```

## The clock

All timestamps are nanoseconds since the Unix epoch, on the clock of the machine that ran the benchmark (the client). Events and chip samples share that clock. The server's own clock is never involved: compare timestamps with server logs only roughly, allowing for clock skew.

## Columns

| Column | Type | event | chip | Meaning |
| --- | --- | :-: | :-: | --- |
| `source` | VARCHAR | ✓ | ✓ | `'event'` or `'chip'` |
| `ts_ns` | BIGINT | ✓ | ✓ | When the chunk or sample arrived |
| `request_id` | VARCHAR | ✓ | | `<conversation>-<turn>`: one HTTP request (see below) |
| `seq` | INTEGER | ✓ | | Chunk number within the **conversation**; it keeps counting across turns |
| `request_ts_ns` | BIGINT | ✓ | | When the request was sent |
| `token_chars` | INTEGER | ✓ | | Characters of answer text in the chunk. `0` for empty chunks: the opening role chunk, the finish chunk and the usage chunk. The text itself isn't kept |
| `reasoning_chars` | INTEGER | ✓ | | Characters of reasoning (thinking) text, streamed as `reasoning_content` or `reasoning`. Missing in files recorded before it existed: treat it as 0 |
| `output_tokens` | INTEGER | ✓ | | Chunks with a choice received so far in this request. The role and finish chunks count too |
| `input_tokens` | INTEGER | ✓ | | Prompt tokens, from the final usage chunk. Only finished requests have it, and only on that row; `0` elsewhere |
| `error` | VARCHAR | ✓ | | Empty, or the request's error, on its last row |
| `device` | INTEGER | | ✓ | Device index in zml-smi |
| `kind` | VARCHAR | | ✓ | `cuda` · `rocm` · `oneapi` · `neuron` · `tpu` |
| `name` | VARCHAR | | ✓ | Device name |
| `util_percent` | INTEGER | | ✓ | Utilization: the share of time a kernel was running, not a measure of FLOP efficiency |
| `power_w`, `power_limit_w` | DOUBLE | | ✓ | Power draw and its limit |
| `temperature_c` | INTEGER | | ✓ | Temperature |
| `mem_used_bytes`, `mem_total_bytes` | BIGINT | | ✓ | Device memory. Servers usually preallocate their KV cache, so "used" is often near the total |
| `clock_graphics_mhz`, `clock_mem_mhz` | INTEGER | | ✓ | Clocks |
| `pcie_tx_kbps`, `pcie_rx_kbps` | INTEGER | | ✓ | PCIe traffic |

**When a run has no chip samples** (zml-smi wasn't reachable), the chip columns are **absent from the file**, not null. `scripts/zmlrun.py` handles that; your own SQL over `read_parquet` must check the columns first (`DESCRIBE`).

**`request_id` is `<conversation id>_<n>-<turn>`.** `<turn>` is the message's index in the ShareGPT conversation, so a conversation's user turns are 0, 2, 4, …. Each turn is its own request. With `params.turns = "first"`, only turn 0 is sent.

- **Each prompt holds the conversation so far.** It starts with a `Date: <timestamp>.` prefix, unique per conversation, which defeats prefix caching across conversations. Then come the earlier user turns, and **the server's own earlier answers**: only their answer text (`content`), never their reasoning.
- **The order is deterministic.** On the same dataset, the same `request_id` gets the same prompt, but **only for first turns**. A later turn embeds that server's earlier answer, so it differs from run to run and from server to server. A server that streams its thinking as `content` gets much longer later-turn prompts than one that sends it as `reasoning_content`. Pair runs request by request on first turns only.

**Prompt length of an unfinished request.** It's unknown (there's no usage chunk). To estimate it, add up:
- the conversation's earlier user turns, from the dataset file named in `meta.dataset`;
- the server's earlier answers in this run (their `token_chars` ÷ about 4);
- the new user turn.

ZML-Lab keeps the dataset under `~/Library/Application Support/ZML-Lab/`.

**A request is finished** when its usage chunk arrived (`input_tokens > 0`) or it failed. Requests still streaming when the run's duration ran out never finish: they have no usage, and their latency and length are truncated.

## meta.json

Every field is optional unless marked otherwise.

```jsonc
{
  "schema_version": 1, "run_id": "p-…",       // required
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

A **token** is a chunk that carries text, answer or reasoning. Empty chunks don't count.

```sql
CREATE VIEW tokens AS SELECT * FROM events WHERE token_chars + reasoning_chars > 0;

CREATE VIEW requests AS
SELECT request_id,
       min(request_ts_ns)                                          AS sent_ns,
       min(ts_ns) FILTER (WHERE token_chars + reasoning_chars > 0) AS first_token_ns,
       max(ts_ns)                                                  AS last_ns,
       max(output_tokens)                                          AS output_tokens,
       max(input_tokens)                                           AS input_tokens,
       bool_or(error <> '')                                        AS failed,
       bool_or(input_tokens > 0 OR error <> '')                    AS ended
FROM events GROUP BY request_id;

-- TTFT
SELECT quantile_cont((first_token_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) FROM requests
WHERE first_token_ns IS NOT NULL;
-- Inter-token latency: gaps between consecutive tokens of a request
SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99]) FROM (
  SELECT (ts_ns - lag(ts_ns) OVER (PARTITION BY request_id ORDER BY ts_ns)) / 1e6 AS gap_ms
  FROM tokens) WHERE gap_ms IS NOT NULL;
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
| `run` | the file as is |
| `events` | the event columns above, with `reasoning_chars` as 0 when absent, `error` with no nulls, and `is_token` |
| `tokens` | `events` where `is_token` |
| `requests` | `request_id`, `conversation`, `turn`, `sent_ns`, `first_token_ns`, `last_token_ns` (last text chunk), `last_ns` (last event, including usage), `tokens` (text chunks), `output_tokens`, `input_tokens`, `failed`, `error`, `ended` |
| `gaps` | `request_id`, `prev_ns`, `ts_ns`, `gap_ms`: consecutive tokens of one request |
| `series` | `i`, `elapsed_ms`, `t_ns` (end of the 100 ms bucket), `tokens_per_second`, `in_flight`, `waiting`, `decoding` |
| `chips` | `ts_ns` and the chip columns, all of them (null when the file has none) |
| `meta` | one row, `meta` JSON |

With several files, every view is prefixed `a_`, `b_`, ….

**The benchmarker's own `duckdb/report.sql` differs from these definitions.** It counts empty chunks too, and takes TTFT from `seq = 0`, which only a conversation's first turn has. Don't mix numbers computed the two ways.
