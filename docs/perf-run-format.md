# Perf run format

The contract between ZML-Lab (which records perf runs) and the results website
(which loads them into DuckDB-WASM to analyse, compare and chart). It is meant
to be dumb: any benchmarker, in any language, can write a run by printing JSON,
and anyone can check a run's numbers without a library.

A run is **one gzipped [JSON Lines](https://jsonlines.org) file**,
`<name>.jsonl.gz`: one JSON object per line, each with a `type`.

- The first line is the run's `meta.json`, with `"type": "meta"`.
- Each later line is either a request (`"type": "request"`), one HTTP request
  with the arrival time of every chunk it streamed, or a chip sample
  (`"type": "chip"`), one accelerator reading from `zml-smi`.

```jsonc
{"type":"meta","schema_version":1,"t0_unix_us":1792876902319189,"run_id":"p-1792876900967068","label":"zml · c=64", …}
{"type":"request","id":"QWJhYvA_0-0","conversation":"QWJhYvA_0","turn":0,"sent_us":0,"end_us":4754177,"input_tokens":120,"output_tokens":258,"error":null,"chunk_us":[866563,916373,964244,…],"answer_chars":[0,0,0,…],"reasoning_chars":[2,5,3,…]}
{"type":"chip","t_us":-1153562,"device":0,"kind":"cuda","name":"NVIDIA GB300","util_percent":0,"power_w":497.544,"power_limit_w":1400.0,"temperature_c":44, …}
```

ZML-Lab writes the lines after the meta line in time order: a request at
its `sent_us` and a chip sample at its `t_us`. Readers must not depend on that
order.

A file is a run only if it is gzipped and its first line is a meta line with
`schema_version` 1. There is no other version: readers report anything else as
not a run file.

## Time

Every time is an **integer number of microseconds since `t0_unix_us`**, which
the meta line gives as microseconds since the Unix epoch. ZML-Lab sets t0 to
the moment the run's first request was sent, so that request has
`sent_us: 0`. Chip samples taken before then have negative times.

All times come from one clock, the clock of the machine running the benchmark,
so requests and chip samples line up without any sync with the server.
Times stay small integers, so JavaScript and spreadsheets keep them exact. They
would not keep nanoseconds since the epoch, which have 19 digits.

## Lines

### `request`: one per HTTP request

A conversation's turns are separate requests.

| Field             | Type          | Meaning |
| ----------------- | ------------- | ------- |
| `id`              | string        | Unique in the run. ZML-Lab uses `<conversation>-<turn>` |
| `conversation`    | string        | The conversation the request belongs to (ZML-Lab: the ShareGPT conversation) |
| `turn`            | integer       | The turn within its conversation, from 0 |
| `sent_us`         | integer       | When the request was sent |
| `chunk_us`        | integer[]     | When each streamed chunk arrived, in order. Empty chunks are included: the opening role chunk, the finish chunk and the usage chunk |
| `answer_chars`    | integer[]     | For each chunk, the length of its answer text (`content`), in Unicode code points |
| `reasoning_chars` | integer[]     | For each chunk, the length of its reasoning text (`reasoning_content` or `reasoning`) |
| `end_us`          | integer\|null | When the response ended: its usage chunk arrived, or its error did. `null` if no end was seen, because the run's end cut the request off or the server sends no usage |
| `input_tokens`    | integer\|null | Prompt tokens, from the server's usage. `null` if not reported |
| `output_tokens`   | integer       | Tokens generated, as the benchmarker counted them. ZML-Lab counts chunks that carried a choice, so the count includes the role and finish chunks |
| `error`           | string\|null  | Why the request failed. `null` if it didn't |

The three chunk lists have the same length. **A token is a chunk that carries
text** (`answer_chars + reasoning_chars > 0`). The text itself is not kept.

A request can have no chunk and no end: it was sent, then the run's end cut
it off before any reply. It counts as a request, but it has no last moment, so
latency leaves it out, and so does the in-flight series when no request in the
run ended. ZML-Lab never writes such a line, because its benchmarker logs a
request from its first chunk or its error. ZML-Lab's report also leaves one out
when it reads a run.

### `chip`: one accelerator reading

ZML-Lab polls `zml-smi --api` about every 500 ms during the run. Each poll
gives a line per device.

| Field                | Type    | Meaning |
| -------------------- | ------- | ------- |
| `t_us`               | integer | When the sample arrived |
| `device`             | integer | Index in zml-smi's `devices` |
| `kind`               | string  | `cuda` · `rocm` · `oneapi` · `neuron` · `tpu` |
| `name`               | string  | Device name |
| `util_percent`       | integer | Utilization |
| `power_w`            | number  | Power draw (zml-smi `power_mw` / 1000) |
| `power_limit_w`      | number  | Power limit |
| `temperature_c`      | integer | Temperature |
| `mem_used_bytes`     | integer | Memory used |
| `mem_total_bytes`    | integer | Memory total |
| `clock_graphics_mhz` | integer | Graphics clock |
| `clock_mem_mhz`      | integer | Memory clock |
| `pcie_tx_kbps`       | integer | PCIe TX |
| `pcie_rx_kbps`       | integer | PCIe RX |

A metric the device doesn't report is left out of the line.

### `meta`: the first line, the run's `meta.json`

Every field is optional unless marked required. A top-level key never reuses a
request or chip field name (`id`, `name`, `error`, `kind`, …), because readers
load every line with one column list. ZML-Lab fills in what it can detect. The rest is entered or corrected in the export dialog.

```jsonc
{
  "type": "meta",                            // required
  "schema_version": 1,                       // required
  "t0_unix_us": 1792836000123456,            // required: the times' origin (see Time)
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
                                             // it is in the run's lines
  },
  "dataset": {                               // auto
    "name": "ShareGPT_V3_unfiltered_cleaned_split.json",
    "sha256": "35f0e213ce091ed9b9af2a1f0755e9d39f9ccec34ab281cd4ca60d70f6479ba4"
  },
  "chip_metrics": { "url": "http://10.0.0.5:9090", "interval_ms": 500 },  // auto, null if none

  "summary": {                               // auto — ZML-Lab's own numbers, for listings;
    "requests": 144,                         //   the website recomputes them from the lines
    "tokens_per_second": 872.0,
    "joules_per_token": 0.36                 // when zml-smi reported power
  }
}
```

## Checking a run with no dependencies

The headline numbers, with Python's standard library only. They are the same
numbers the SQL below gives:

```python
import gzip, json, statistics, sys

lines = [json.loads(l) for l in gzip.open(sys.argv[1], "rt")]
requests = [o for o in lines if o["type"] == "request"]

ttft, itl, tokens = [], [], 0
for r in requests:
    # The chunks that carry text are the tokens.
    t = [c for c, a, rc in zip(r["chunk_us"], r["answer_chars"], r["reasoning_chars"]) if a + rc > 0]
    tokens += len(t)
    if t:
        ttft.append((t[0] - r["sent_us"]) / 1000)
    itl += [(b - a) / 1000 for a, b in zip(t, t[1:])]

start = min(r["sent_us"] for r in requests)
end = max(max(r["chunk_us"] + [r["end_us"] or 0]) for r in requests)
print("TTFT ms p50", statistics.median(ttft), " ITL ms p50", statistics.median(itl))
print("tokens/s", tokens / ((end - start) / 1e6))
```

pandas reads the lines with `pd.read_json(path, lines=True)` and `jq` with
`zcat run.jsonl.gz | jq -c 'select(.type == "request")'`.

## Loading a run (DuckDB SQL)

These views are what the metrics below are written against.

```sql
-- On the website (DuckDB-WASM). The columns are listed so their types don't
-- depend on which lines DuckDB samples. The meta line's other keys are ignored.
CREATE VIEW lines AS
SELECT * FROM read_json('llmd.jsonl.gz', format = 'newline_delimited', columns = {
  type: 'VARCHAR',
  id: 'VARCHAR', conversation: 'VARCHAR', turn: 'INTEGER',
  sent_us: 'BIGINT', end_us: 'BIGINT',
  input_tokens: 'INTEGER', output_tokens: 'INTEGER', error: 'VARCHAR',
  chunk_us: 'BIGINT[]', answer_chars: 'INTEGER[]', reasoning_chars: 'INTEGER[]',
  t_us: 'BIGINT', device: 'INTEGER', kind: 'VARCHAR', name: 'VARCHAR',
  util_percent: 'INTEGER', power_w: 'DOUBLE', power_limit_w: 'DOUBLE',
  temperature_c: 'INTEGER', mem_used_bytes: 'BIGINT', mem_total_bytes: 'BIGINT',
  clock_graphics_mhz: 'INTEGER', clock_mem_mhz: 'INTEGER',
  pcie_tx_kbps: 'INTEGER', pcie_rx_kbps: 'INTEGER'
});

-- The meta line, as JSON.
SELECT json AS meta FROM read_ndjson_objects('llmd.jsonl.gz') LIMIT 1;

-- A row per chunk: the three lists unnest side by side.
CREATE VIEW chunks AS
SELECT id AS request_id, sent_us,
       unnest(chunk_us)        AS t_us,
       unnest(answer_chars)    AS answer_chars,
       unnest(reasoning_chars) AS reasoning_chars
FROM lines WHERE type = 'request';

CREATE VIEW chips AS
SELECT t_us, device, kind, name, util_percent, power_w, power_limit_w,
       temperature_c, mem_used_bytes, mem_total_bytes, clock_graphics_mhz,
       clock_mem_mhz, pcie_tx_kbps, pcie_rx_kbps
FROM lines WHERE type = 'chip';
```

To compare several runs at once, read them together:
`read_json(['llmd.jsonl.gz', 'vllm.jsonl.gz'], filename = true, …)`.
The file name then tells the runs apart.

## Metrics (DuckDB SQL)

These are per run. ZML-Lab's report uses exactly these definitions, and
`test/perf_contract_test.dart` checks it against this SQL.

```sql
CREATE VIEW tokens AS
SELECT * FROM chunks WHERE answer_chars + reasoning_chars > 0;

-- One row per request (each turn of a conversation is its own request).
-- Its last moment is its last chunk, or its end if that came later.
CREATE VIEW requests AS
SELECT r.id, r.sent_us, c.first_token_us,
       greatest(c.last_chunk_us, r.end_us) AS last_us,
       r.output_tokens, r.input_tokens,
       r.error IS NOT NULL                 AS failed,
       r.end_us IS NOT NULL                AS ended
FROM lines r LEFT JOIN (
  SELECT request_id,
         min(t_us) FILTER (WHERE answer_chars + reasoning_chars > 0) AS first_token_us,
         max(t_us)                                                    AS last_chunk_us
  FROM chunks GROUP BY request_id
) c ON c.request_id = r.id
WHERE r.type = 'request';

-- Time to first token, per request.
SELECT quantile_cont((first_token_us - sent_us) / 1e3, [0.5, 0.9, 0.99]) AS ttft_ms
FROM requests WHERE first_token_us IS NOT NULL;

-- Inter-token latency: gaps between consecutive tokens of a request.
SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99]) AS itl_ms FROM (
  SELECT (t_us - lag(t_us) OVER (PARTITION BY request_id ORDER BY t_us)) / 1e3 AS gap_ms
  FROM tokens
) WHERE gap_ms IS NOT NULL;

-- Request latency, output and input lengths.
SELECT quantile_cont((last_us - sent_us) / 1e3, [0.5, 0.9, 0.99]) AS latency_ms FROM requests;
SELECT quantile_cont(output_tokens, [0.5, 0.9, 0.99]) AS osl FROM requests;
SELECT quantile_cont(input_tokens, [0.5, 0.9, 0.99]) AS isl FROM requests WHERE input_tokens > 0;

-- Throughput over the run, from its first request to its last moment.
SELECT (SELECT count(*) FROM tokens) / ((max(last_us) - min(sent_us)) / 1e6) AS tokens_per_second,
       count(*)                      / ((max(last_us) - min(sent_us)) / 1e6) AS requests_per_second
FROM requests;
```

The chip metrics are per device. Chips share the clock with requests, so
energy divides by the run's tokens:

```sql
-- Energy: power integrated between a device's consecutive readings
-- (trapezoids), in joules.
CREATE VIEW energy AS
SELECT device, sum(j) AS energy_j FROM (
  SELECT device,
         (power_w + lag(power_w) OVER w) / 2 * (t_us - lag(t_us) OVER w) / 1e6 AS j
  FROM chips WHERE power_w IS NOT NULL
  WINDOW w AS (PARTITION BY device ORDER BY t_us)
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

The benchmarker's own `duckdb/report.sql` differs in three ways:
- It takes TTFT from a conversation's first chunk only. Later turns have no
  first chunk of their own there, and that chunk can be the empty role chunk.
- It counts every chunk, empty ones included, for ITL and throughput.
- Its OSL counts chunks with a choice, so it includes the role and finish
  chunks.

## Time series (DuckDB SQL)

This is the run as ZML-Lab charts it, a point every 100 ms.
`test/perf_contract_test.dart` checks it against the app's series.
- Time is measured from `t0`, the moment the run's first request was sent.
- Point `i` sits at the end of 100 ms bucket `i`, at `t0 + (i + 1) × 100 ms`.
- Buckets run from `t0` to the bucket of the run's last moment.
- While a run streams, the app leaves out the newest bucket, which is still
  filling.

```sql
CREATE VIEW points AS
WITH t AS (SELECT min(sent_us) AS t0 FROM requests)
SELECT range AS i, t0 + (range + 1) * 100000 AS t_us
FROM t, range((SELECT max(greatest(0, (last_us - t0) // 100000)) + 1
               FROM requests, t));

-- Throughput: tokens per second over the trailing second (10 buckets;
-- fewer at the start, averaged over what they cover). Not smoothed beyond
-- that, so a stall shows.
WITH t AS (SELECT min(sent_us) AS t0 FROM requests),
buckets AS (
  SELECT greatest(0, (t_us - t0) // 100000) AS b, count(*) AS tokens
  FROM tokens, t GROUP BY 1
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       coalesce(sum(b.tokens), 0) / ((p.i - greatest(0, p.i - 9) + 1) / 10)
         AS tokens_per_second
FROM points p LEFT JOIN buckets b ON b.b BETWEEN greatest(0, p.i - 9) AND p.i
GROUP BY p.i ORDER BY p.i;

-- Requests in flight at each point (sent, response not ended) and, of those,
-- the ones still waiting for a first token (queued, or in prefill).
-- - A request that never ended (cut off at the run's end) stays in flight to
--   the last point.
-- - If no request in the run ended (a server that reports no usage), each one
--   ends at its last chunk instead.
WITH r AS (
  SELECT sent_us, first_token_us, last_us,
         ended OR NOT (SELECT bool_or(ended) FROM requests) AS ends_at_last
  FROM requests
)
SELECT p.i, (p.i + 1) * 100 AS elapsed_ms,
       count(*) FILTER (WHERE r.sent_us <= p.t_us
                          AND (NOT r.ends_at_last OR p.t_us < r.last_us))
         AS in_flight,
       count(*) FILTER (WHERE r.sent_us <= p.t_us
                          AND (NOT r.ends_at_last OR p.t_us < r.last_us)
                          AND (r.first_token_us IS NULL OR p.t_us < r.first_token_us))
         AS waiting
FROM points p, r
GROUP BY p.i ORDER BY p.i;
```

## Analyzing runs with an agent

`.agents/skills/analyze-zmlrun/` is an agent skill in the open Agent Skills format. Codex reads it from `.agents/skills`, and Claude Code reads it through the `.claude/skills/analyze-zmlrun` symlink. Hand an agent a run (or two) and the server's launch command. It reports what the run shows and proposes server-side changes to try. Its `scripts/zmlrun.py` (`report`, `compare`, `sql`) also works on its own, through `uv`.

## In ZML-Lab

- **During a run** the benchmarker's event stream is spooled to disk.
  - If `zml-smi --api` answers, chip samples are kept as well. ZML-Lab asks
    the target's host on the Settings port (9090 by default) unless the
    Metrics popover points elsewhere; Metrics is in the Perf tool's target bar.
  - Chip samples are shown live and summed up in the report, per chip and as
    energy per token.
- **When the run ends**, the spool becomes the run's file, together with the
  automatic `meta.json`. The text is dropped and its length kept. The file is
  kept under `~/Library/Application Support/ZML-Lab/runs/`. Saving the report
  keeps it, and discarding the run deletes it.
- **Edit details** on a saved run edits the fields a person types and
  rewrites the meta line of the kept run file.
  - The fields are `label` (shown as Name), `model.name`,
    `hardware.description`, `server.version`, `server.commit`, `tags` and
    `notes`.
  - The website's run page edits exactly the same fields under the same
    rules: values are trimmed, only changed fields are written, a cleared
    field drops its key (never null or `""`), and every other key is kept as
    is.
  - ZML-Lab keeps the model the requests actually sent in its own database. A
    cleared Model puts that name back.
- **Export run** opens a dialog with `meta.json` prefilled and writes the
  final `.jsonl.gz` where you choose.
  - The fields are the same: hardware comes from the target machine or
    zml-smi, and name and model are as ZML-Lab shows them. All are editable.
  - Uploading to the website comes later.
- **Import** (Saved) takes `.jsonl.gz` files, ZML-Lab's own or any
  benchmarker's, and rebuilds each run's report from its lines. A file it
  doesn't recognize is reported and skipped.
