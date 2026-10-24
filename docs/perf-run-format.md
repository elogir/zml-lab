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
| `token_chars`        | INTEGER | ✓ |   | Length of the chunk's text (characters); `0` for empty chunks (the role chunk, the final usage chunk). The text itself is not kept |
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

  "app": { "benchmarker_api": 1 },           // auto
  "client": { "os": "macOS 27.0", "host": "bench-mac" }, // auto

  "target": {
    "url": "http://10.0.0.5:8000/v1/",       // auto
    "machine": "4090-box"                    // auto — ZML-Lab machine name, if one was picked
  },
  "server": {
    "kind": "zml",                           // auto — zml | vllm | openai | unknown (Server header)
    "version": "0.11.0",                     // auto for vLLM (/version), else manual
    "commit": "a1b2c3d"                      // manual
  },
  "model": {
    "name": "Qwen/Qwen3-8B",                 // auto — sent in requests / from /v1/models
    "quantization": "fp8"                    // manual
  },
  "hardware": {
    "description": "1× RTX 4090, 64 GB",     // auto — the machine's hardware field, editable
    "chips": [                               // auto — from zml-smi, when it answered
      { "device": 0, "kind": "cuda", "name": "NVIDIA GeForce RTX 4090", "driver_version": "580.82" }
    ]
  },

  "params": {                                // auto — the run's settings
    "duration_s": 30,
    "concurrency": 16,
    "max_completion_tokens": 256,            // null = server default
    "prompts": "long",                       // long | short (capped at 512 chars)
    "turns": "all",                          // all | first
    "warmup": true
  },
  "dataset": {                               // auto
    "name": "ShareGPT_V3_unfiltered_cleaned_split.json",
    "sha256": "35f0e213ce091ed9b9af2a1f0755e9d39f9ccec34ab281cd4ca60d70f6479ba4"
  },
  "chip_metrics": { "url": "http://10.0.0.5:9090", "interval_ms": 500 },  // auto, null if none

  "summary": {                               // auto — ZML-Lab's own numbers, for listings;
    "requests": 144,                         //   the website recomputes from events
    "tokens_per_second": 872.0
  }
}
```

## Metrics (DuckDB SQL)

Per run, over `events`:

```sql
-- One row per request.
CREATE VIEW requests AS
SELECT request_id,
       min(request_ts_ns)                                            AS sent_ns,
       min(ts_ns) FILTER (WHERE token_chars > 0)                     AS first_token_ns,
       max(ts_ns)                                                    AS last_ns,
       max(output_tokens)                                            AS output_tokens,
       max(input_tokens)                                             AS input_tokens,
       bool_or(error <> '')                                          AS failed
FROM events GROUP BY request_id;

-- Time to first token: first chunk with text, per request (every turn).
SELECT quantile_cont((first_token_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) AS ttft_ms
FROM requests WHERE first_token_ns IS NOT NULL;

-- Inter-token latency: gaps between consecutive text chunks of a request.
SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99]) FROM (
  SELECT (ts_ns - lag(ts_ns) OVER (PARTITION BY request_id ORDER BY ts_ns)) / 1e6 AS gap_ms
  FROM events WHERE token_chars > 0
) WHERE gap_ms IS NOT NULL;

-- Request latency, and throughput over the run.
SELECT quantile_cont((last_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) AS latency_ms FROM requests;
SELECT count(*) FILTER (WHERE token_chars > 0)
       / ((max(ts_ns) - min(request_ts_ns)) / 1e9)                    AS tokens_per_second
FROM events;
```

Joining chips: they share the clock with events, so e.g. energy per token is
`∫ power_w dt` over the run (sum of `power_w × Δt` between a device's
samples) divided by the text chunks.

**Differences from ZML-Lab's current report** (to be aligned): it takes TTFT
from `seq = 0` rows — the first turn of each conversation only, and possibly
the empty role chunk — and counts every chunk (empty ones included) as a
token. The definitions above fix both; `token_chars` is what makes that
possible.

## In ZML-Lab

- During a run the benchmarker's event stream is spooled to disk, and — when
  `zml-smi --api` answers at the configured URL (default
  `http://<target host>:9090`) — chip samples too.
- When the run ends, embedded DuckDB (`dart_duckdb`) turns the spools into
  the run's Parquet file (token text dropped, `token_chars` kept) with the
  automatic `meta.json`, kept under `~/Library/Application Support/ZML-Lab/runs/`.
  Saving the report keeps it; discarding the run deletes it.
- **Export run…** opens a dialog with `meta.json` prefilled — label, commit,
  quantization, notes, tags — and writes the final `.zmlrun.parquet` where you
  choose. Uploading to the website comes later.
