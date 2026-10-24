# Perf run format (v1)

The contract between ZML-Lab (which records perf runs) and the results website
(which loads them into DuckDB-WASM to analyse, compare and chart). Status:
**draft — under review**.

A run is a folder, `<name>.zmlrun/`:

| File             | What                                                      | Always |
| ---------------- | --------------------------------------------------------- | ------ |
| `meta.json`      | What was run, against what, on what — see below           | yes    |
| `events.csv.gz`  | One row per streamed chunk of every request               | yes    |
| `chips.csv.gz`   | Accelerator metrics sampled during the run (`zml-smi`)    | no     |

CSVs are gzipped, with a header row. DuckDB reads them directly
(`read_csv('events.csv.gz')`), and the website may convert them to Parquet on
upload. All timestamps are **nanoseconds since the Unix epoch, on the clock of
the machine running ZML-Lab** — events and chip samples share that clock, so
they line up without any sync with the server.

## `meta.json`

Every field is optional unless marked required. ZML-Lab fills in what it can
detect; the rest is entered (or corrected) in the export dialog.

```jsonc
{
  "schema_version": 1,                       // required
  "run_id": "2026-10-24T12-00-00Z-a1b2c3",   // required, unique
  "label": "llmd · Qwen3-8B · 4090 · c=16",  // manual — how it reads in charts
  "notes": "",                               // manual
  "tags": ["llmd", "fp8"],                   // manual

  "started_at": "2026-10-24T12:00:00Z",      // auto (ISO 8601, UTC)
  "ended_at": "2026-10-24T12:00:31Z",        // auto
  "cancelled": false,                        // auto — stopped before its duration

  "app": { "version": "1.0.0+1", "benchmarker_api": 1 },          // auto
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
    "chips": [                               // auto — from zml-smi, when connected
      { "index": 0, "kind": "cuda", "name": "NVIDIA GeForce RTX 4090", "driver_version": "580.82" }
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
    "tokens_per_second": 872.0,
    "ttft_p50_ms": 212.4
  }
}
```

## `events.csv.gz`

One row per streamed chunk (from the benchmarker; the token text itself is
dropped — it's most of the size, it's model output, and no metric needs it).

| Column          | Type   | Meaning |
| --------------- | ------ | ------- |
| `ts_ns`         | int64  | When the chunk arrived |
| `request_id`    | string | `<conversation>-<turn>`: one HTTP request |
| `seq`           | int    | Chunk number within the **conversation** (keeps counting across its turns) |
| `request_ts_ns` | int64  | When the request was sent |
| `token_chars`   | int    | Length of the chunk's text; `0` for empty chunks (the role chunk, the final usage chunk) |
| `output_tokens` | int    | Chunks with a choice received so far for this request |
| `input_tokens`  | int    | Prompt tokens, if the server reports usage (else `0`) |
| `error`         | string | Empty, or the request's error (on its last row) |

## `chips.csv.gz`

One row per device per sample of `zml-smi --api`, polled about every 500 ms.
Metrics a device doesn't report are empty.

| Column               | Type   | From zml-smi |
| -------------------- | ------ | ------------ |
| `ts_ns`              | int64  | When the sample arrived |
| `device`             | int    | Index in zml-smi's `devices` |
| `kind`               | string | `cuda` · `rocm` · `oneapi` · `neuron` · `tpu` |
| `name`               | string | `name` |
| `util_percent`       | int    | `util_percent` |
| `power_w`            | double | `power_mw` / 1000 |
| `power_limit_w`      | double | `power_limit_mw` / 1000 |
| `temperature_c`      | int    | `temperature` |
| `mem_used_bytes`     | int64  | `mem_used_bytes` |
| `mem_total_bytes`    | int64  | `mem_total_bytes` |
| `clock_graphics_mhz` | int    | `clock_graphics_mhz` |
| `clock_mem_mhz`      | int    | `clock_mem_mhz` |
| `pcie_tx_kbps`       | int    | `pcie_tx_kbps` |
| `pcie_rx_kbps`       | int    | `pcie_rx_kbps` |

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

Joining chips: both tables share the clock, so e.g. energy per token is
`∫ power_w dt` over the run (sum of `power_w × Δt` between samples) divided by
the text chunks.

**Differences from ZML-Lab's current report** (to be aligned): it takes TTFT
from `seq = 0` rows — the first turn of each conversation only, and possibly
the empty role chunk — and counts every chunk (empty ones included) as a
token. The definitions above fix both; `token_chars` is what makes that
possible.

## In ZML-Lab

- During a run: events stream to a temp folder (text dropped, `token_chars`
  kept); if a chip-metrics URL is set, `zml-smi` is polled into `chips`.
- After it: **Export run…** opens a dialog with `meta.json` prefilled — fill
  in the label, commit, quantization, notes, tags — then writes the
  `.zmlrun` folder where you choose. Saved reports keep their run files, so a
  past run can be exported too. Uploading to the website comes later.
