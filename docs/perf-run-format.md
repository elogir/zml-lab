# Perf run format (v1)

The contract between ZML-Lab (which records perf runs) and the results website
(which loads them into DuckDB-WASM to analyse, compare and chart).

A run is **one Parquet file**, `<name>.zmlrun.parquet` (zstd), holding:

- one table — a row per streamed chunk (`source = 'event'`) and a row per
  accelerator sample (`source = 'chip'`, from `zml-smi`), columns the other
  kind doesn't use left null;
- `meta.json` in the footer's key-value metadata, under the key `zml.run`.

```sql
-- On the website (DuckDB-WASM):
CREATE VIEW run    AS SELECT * FROM read_parquet('llmd.zmlrun.parquet');
CREATE VIEW events AS SELECT * FROM run WHERE source = 'event';
CREATE VIEW chips  AS SELECT * FROM run WHERE source = 'chip';
SELECT decode(value)::JSON AS meta
FROM parquet_kv_metadata('llmd.zmlrun.parquet') WHERE decode(key) = 'zml.run';

-- Several runs at once (compare): the file name tells them apart.
SELECT * FROM read_parquet(['llmd.zmlrun.parquet', 'vllm.zmlrun.parquet'], filename = true);
```

All timestamps are **nanoseconds since the Unix epoch, on the clock of the
machine running ZML-Lab** — events and chip samples share that clock, so they
line up without any sync with the server.

## Columns

| Column               | Type    | event | chip | Meaning |
| -------------------- | ------- | :---: | :--: | ------- |
| `source`             | VARCHAR | ✓ | ✓ | `'event'` or `'chip'` |
| `ts_ns`              | BIGINT  | ✓ | ✓ | When the chunk / sample arrived |
| `request_id`         | VARCHAR | ✓ |   | `<conversation>-<turn>`: one HTTP request |
| `seq`                | INTEGER | ✓ |   | Chunk number within the **conversation** (keeps counting across its turns) |
| `request_ts_ns`      | BIGINT  | ✓ |   | When the request was sent |
| `token_chars`        | INTEGER | ✓ |   | Length of the chunk's answer text (characters); `0` for empty chunks (the role chunk, the final usage chunk). The text itself is not kept |
| `reasoning_chars`    | INTEGER | ✓ |   | Length of the chunk's reasoning (thinking) text, streamed as `reasoning_content` or `reasoning`; `0` for other chunks |
| `output_tokens`      | INTEGER | ✓ |   | Chunks with a choice received so far for this request |
| `input_tokens`       | INTEGER | ✓ |   | Prompt tokens, if the server reports usage (else `0`) |
| `error`              | VARCHAR | ✓ |   | Empty, or the request's error (on its last row) |
| `device`             | INTEGER |   | ✓ | Index in zml-smi's `devices` |
| `kind`               | VARCHAR |   | ✓ | `cuda` · `rocm` · `oneapi` · `neuron` · `tpu` |
| `name`               | VARCHAR |   | ✓ | Device name |
| `util_percent`       | INTEGER |   | ✓ | Utilization |
| `power_w`            | DOUBLE  |   | ✓ | Power draw (zml-smi `power_mw` / 1000) |
| `power_limit_w`      | DOUBLE  |   | ✓ | Power limit |
| `temperature_c`      | INTEGER |   | ✓ | Temperature |
| `mem_used_bytes`     | BIGINT  |   | ✓ | Memory used |
| `mem_total_bytes`    | BIGINT  |   | ✓ | Memory total |
| `clock_graphics_mhz` | INTEGER |   | ✓ | Graphics clock |
| `clock_mem_mhz`      | INTEGER |   | ✓ | Memory clock |
| `pcie_tx_kbps`       | INTEGER |   | ✓ | PCIe TX |
| `pcie_rx_kbps`       | INTEGER |   | ✓ | PCIe RX |

Chip metrics a device doesn't report are null. Chips are sampled by polling
`zml-smi --api` about every 500 ms during the run.

## `meta.json`

Every field is optional unless marked required. ZML-Lab fills in what it can
detect; the rest is entered (or corrected) in the export dialog.

```jsonc
{
  "schema_version": 1,                       // required
  "run_id": "p-1792836000000000",            // required, unique
  "label": "llmd · Qwen3-8B · 4090 · c=16",  // manual — how it reads in charts
  "notes": "",                               // manual
  "tags": ["llmd", "fp8"],                   // manual

  "started_at": "2026-10-24T12:00:00Z",      // auto (ISO 8601, UTC)
  "ended_at": "2026-10-24T12:00:31Z",        // auto
  "cancelled": false,                        // auto — stopped before its duration

  "app": { "benchmarker_api": 2 },           // auto
  "client": { "os": "macOS 27.0", "host": "bench-mac" }, // auto

  "target": {
    "url": "http://10.0.0.5:8000/v1/",       // auto
    "machine": "4090-box"                    // auto — ZML-Lab machine name, if one was picked
  },
  "server": {
    "kind": "zml",                           // auto — the benchmarker's detection, from the
                                             //   Server header: zml | vllm | openai | unknown
                                             //   (the list grows as it learns more servers).
                                             //   Data only, not a label: runs are named by `label`
    "version": "0.11.0",                     // auto for vLLM (/version), else manual
    "commit": "a1b2c3d"                      // manual
  },
  "model": {
    "name": "Qwen/Qwen3-8B"                  // auto — sent in requests / from /v1/models
  },
  "hardware": {
    "description": "1× RTX 4090, 64 GB",     // auto, editable — the target machine's hardware field,
                                             //   else the chips zml-smi saw ("1× NVIDIA GeForce RTX 4090")
    "chips": [                               // auto — from zml-smi, when it answered
      { "device": 0, "kind": "cuda", "name": "NVIDIA GeForce RTX 4090", "driver_version": "580.82" }
    ]
  },

  "params": {                                // auto — the run's settings
    "duration_s": 30,
    "concurrency": 16,
    "max_completion_tokens": 256,            // null = no cap (the server stops at EOS)
    "ignore_eos": false,                     // true: every reply runs to max_completion_tokens
    "prompts": "long",                       // long | short (capped at 512 chars)
    "turns": "all",                          // all | first
    "warmup": true                           // warmed up first (prefill, decode,
                                             // mixed at `concurrency`); none of
                                             // it is in `events` or `chips`
  },
  "dataset": {                               // auto
    "name": "ShareGPT_V3_unfiltered_cleaned_split.json",
    "sha256": "35f0e213ce091ed9b9af2a1f0755e9d39f9ccec34ab281cd4ca60d70f6479ba4"
  },
  "chip_metrics": { "url": "http://10.0.0.5:9090", "interval_ms": 500 },  // auto, null if none

  "summary": {                               // auto — ZML-Lab's own numbers, for listings;
    "requests": 144,                         //   the website recomputes from the rows
    "tokens_per_second": 872.0,
    "joules_per_token": 0.36                 // when zml-smi reported power
  }
}
```

## Metrics (DuckDB SQL)

Per run, over `events`. A **token** is a chunk carrying text, answer or
reasoning; servers also stream empty chunks (the opening role, the finish
reason, usage), which don't count. ZML-Lab's report uses exactly these
definitions (checked against this SQL in `test/perf_contract_test.dart`).

```sql
CREATE VIEW tokens AS
SELECT * FROM events WHERE token_chars + reasoning_chars > 0;

-- One row per request (each turn of a conversation is its own request).
CREATE VIEW requests AS
SELECT request_id,
       min(request_ts_ns)                                               AS sent_ns,
       min(ts_ns) FILTER (WHERE token_chars + reasoning_chars > 0)      AS first_token_ns,
       max(ts_ns)                                                       AS last_ns,
       max(output_tokens)                                               AS output_tokens,
       max(input_tokens)                                                AS input_tokens,
       bool_or(error <> '')                                             AS failed,
       -- Its stream ended: the usage chunk (the only row with prompt
       -- tokens) or an error came. Requests the run's duration cut off
       -- never end.
       bool_or(input_tokens > 0 OR error <> '')                         AS ended
FROM events GROUP BY request_id;

-- Time to first token, per request.
SELECT quantile_cont((first_token_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) AS ttft_ms
FROM requests WHERE first_token_ns IS NOT NULL;

-- Inter-token latency: gaps between consecutive tokens of a request.
SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99]) AS itl_ms FROM (
  SELECT (ts_ns - lag(ts_ns) OVER (PARTITION BY request_id ORDER BY ts_ns)) / 1e6 AS gap_ms
  FROM tokens
) WHERE gap_ms IS NOT NULL;

-- Request latency, output and input lengths (input 0 = not reported).
SELECT quantile_cont((last_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) AS latency_ms FROM requests;
SELECT quantile_cont(output_tokens, [0.5, 0.9, 0.99]) AS osl FROM requests;
SELECT quantile_cont(input_tokens, [0.5, 0.9, 0.99]) AS isl FROM requests WHERE input_tokens > 0;

-- Throughput over the run.
SELECT (SELECT count(*) FROM tokens)
         / ((max(ts_ns) - min(request_ts_ns)) / 1e9)                    AS tokens_per_second,
       count(DISTINCT request_id)
         / ((max(ts_ns) - min(request_ts_ns)) / 1e9)                    AS requests_per_second
FROM events;
```

Over `chips`, per device — they share the clock with events, so energy
divides by the run's tokens:

```sql
-- Energy: power integrated between a device's consecutive readings
-- (trapezoids), in joules.
CREATE VIEW energy AS
SELECT device, sum(j) AS energy_j FROM (
  SELECT device,
         (power_w + lag(power_w) OVER w) / 2 * (ts_ns - lag(ts_ns) OVER w) / 1e9 AS j
  FROM chips WHERE power_w IS NOT NULL
  WINDOW w AS (PARTITION BY device ORDER BY ts_ns)
) GROUP BY device;

SELECT c.device, any_value(c.name) AS name,
       avg(util_percent) AS util_avg, max(util_percent) AS util_max,
       avg(power_w) AS power_avg_w, max(power_w) AS power_max_w,
       max(temperature_c) AS temperature_max_c,
       max(mem_used_bytes) AS mem_peak_bytes, max(mem_total_bytes) AS mem_total_bytes,
       any_value(e.energy_j) AS energy_j
FROM chips c LEFT JOIN energy e USING (device)
GROUP BY c.device ORDER BY c.device;

SELECT sum(energy_j) / (SELECT count(*) FROM tokens) AS joules_per_token FROM energy;
```

The benchmarker's own `duckdb/report.sql` differs: it takes TTFT from
`seq = 0` rows (only a conversation's first turn has one, and it can be the
empty role chunk) and counts every chunk, empty ones included, for ITL and
throughput. `output_tokens` counts chunks with a choice, so OSL includes the
role and finish chunks.

## Time series (DuckDB SQL)

The run as ZML-Lab charts it, a point every 100 ms (checked against the
app's series in `test/perf_contract_test.dart`). Time is measured from `t0`,
the run's first request; point `i` sits at the end of 100 ms bucket `i`,
`t0 + (i + 1) × 100 ms`. Buckets run from `t0` to the bucket of the run's
last event, whatever its kind. While a run streams, the app leaves out the
newest bucket, which is still filling.

```sql
CREATE VIEW points AS
WITH t AS (SELECT min(request_ts_ns) AS t0 FROM events)
SELECT range AS i, t0 + (range + 1) * 100000000 AS t_ns
FROM t, range((SELECT max(greatest(0, (ts_ns - t0) // 100000000)) + 1
               FROM events, t));

-- Throughput: tokens per second over the trailing second (10 buckets;
-- fewer at the start, averaged over what they cover). Not smoothed beyond
-- that, so a stall shows.
WITH t AS (SELECT min(request_ts_ns) AS t0 FROM events),
buckets AS (
  SELECT greatest(0, (ts_ns - t0) // 100000000) AS b, count(*) AS tokens
  FROM tokens, t GROUP BY 1
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       coalesce(sum(b.tokens), 0) / ((p.i - greatest(0, p.i - 9) + 1) * 0.1)
         AS tokens_per_second
FROM points p LEFT JOIN buckets b ON b.b BETWEEN greatest(0, p.i - 9) AND p.i
GROUP BY p.i ORDER BY p.i;

-- Requests in flight at each point — sent, stream not ended — and, of those,
-- the ones still waiting for a first token (queued, or in prefill). A
-- request that never ended (cut off at the run's end) stays in flight to
-- the last point. If no request ever ended (a server that reports no
-- usage), each one ends at its last chunk instead.
WITH r AS (
  SELECT sent_ns, first_token_ns, last_ns,
         ended OR NOT (SELECT bool_or(ended) FROM requests) AS ends_at_last
  FROM requests
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       count(*) FILTER (WHERE r.sent_ns <= p.t_ns
                          AND (NOT r.ends_at_last OR p.t_ns < r.last_ns))
         AS in_flight,
       count(*) FILTER (WHERE r.sent_ns <= p.t_ns
                          AND (NOT r.ends_at_last OR p.t_ns < r.last_ns)
                          AND (r.first_token_ns IS NULL OR p.t_ns < r.first_token_ns))
         AS waiting
FROM points p, r
GROUP BY p.i ORDER BY p.i;
```

## Analyzing runs with an agent

`.agents/skills/analyze-zmlrun/` is an agent skill, in the open Agent Skills format: Codex reads it from `.agents/skills`, and Claude Code through the `.claude/skills/analyze-zmlrun` symlink. Hand an agent a run (or two) and the server's launch command: it reports what the run shows and proposes server-side changes to try. Its `scripts/zmlrun.py` (`report`, `compare`, `sql`) works on its own too, through `uv`.

## In ZML-Lab

- During a run the benchmarker's event stream is spooled to disk, and — when
  `zml-smi --api` answers (Metrics, in the Perf tool's target bar: the target's
  host on the Settings port, 9090 by default, unless the popover points
  elsewhere) — chip samples too, shown live and summed up in the report (per
  chip, and energy per token).
- When the run ends, embedded DuckDB (`dart_duckdb`) turns the spools into
  the run's Parquet file (text dropped, its length kept) with the
  automatic `meta.json`, kept under `~/Library/Application Support/ZML-Lab/runs/`.
  Saving the report keeps it; discarding the run deletes it.
- **Export run** opens a dialog with `meta.json` prefilled — label, model,
  server version and commit, hardware (from the target machine or zml-smi),
  notes, tags, all editable — and writes the final `.zmlrun.parquet` where
  you choose. Uploading to the website comes later.
