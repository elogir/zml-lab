# Queries for the usual follow-up questions

Run them with `scripts/zmlrun.py sql RUN.jsonl.gz "…"`. The views (`events`, `tokens`, `requests`, `gaps`, `series`, `chips`, `meta`) are described in [format.md](format.md).

The `requests` view also has:
- `conversation`, `turn`;
- `last_token_ns`: the last text chunk, before the usage chunk;
- `tokens`: the number of text chunks;
- `error`.

`series` also has `decoding` (in flight with a first token).

Times relative to the run's start are `(x_ns - (SELECT min(sent_ns) FROM requests)) / 1e9` seconds.

## Contents
- [Timeline, a row per second](#timeline)
- [What happened around a moment](#around)
- [The decode step against the position in the reply](#step-vs-position)
- [TTFT against the queue at send time](#ttft-vs-queue)
- [One request's life](#one-request)
- [Are the pauses periodic?](#periodic)
- [Decode rate against prompt length](#rate-vs-prompt)
- [Two runs, request by request](#paired)

<a id="timeline"></a>
## Timeline, a row per second

This lines up throughput dips with the batch, the queue and the chips.

```sql
WITH s AS (
  SELECT i // 10 AS sec, avg(tokens_per_second) AS tps, max(in_flight) AS in_flight,
         max(waiting) AS waiting, min(decoding) AS decoding_min
  FROM series GROUP BY 1),
c AS (
  SELECT (ts_ns - (SELECT min(sent_ns) FROM requests)) // 1000000000 AS sec,
         avg(util_percent) AS util, avg(power_w) AS power, min(clock_graphics_mhz) AS clock
  FROM chips GROUP BY 1)
SELECT s.*, c.util, c.power, c.clock FROM s LEFT JOIN c USING (sec) ORDER BY sec
```

<a id="around"></a>
## What happened around a moment

Set `t1` and `t2` in seconds from the start. The query lists who sent, who got a first token, and who streamed how many tokens. Put a pause from the report between `t1` and `t2`.

```sql
WITH t AS (SELECT min(sent_ns) AS t0 FROM requests), w AS (SELECT 45.0 AS t1, 46.6 AS t2)
SELECT request_id, turn,
       round((sent_ns - t0) / 1e9, 3) AS sent_s,
       round((first_token_ns - t0) / 1e9, 3) AS first_token_s,
       (SELECT count(*) FROM tokens k WHERE k.request_id = r.request_id
          AND (k.ts_ns - t0) / 1e9 BETWEEN w.t1 AND w.t2) AS tokens_in_window,
       input_tokens
FROM requests r, t, w
WHERE (sent_ns - t0) / 1e9 <= w.t2 AND (last_ns - t0) / 1e9 >= w.t1
ORDER BY sent_s
```

<a id="step-vs-position"></a>
## The decode step against the position in the reply

The median decode step by position in the reply, in 256-token buckets. The query keeps only gaps with no other request in prefill.

```sql
WITH g AS (
  SELECT request_id, ts_ns, prev_ns, gap_ms,
         row_number() OVER (PARTITION BY request_id ORDER BY ts_ns) AS pos
  FROM gaps),
clean AS (
  SELECT g.* FROM g WHERE NOT EXISTS (
    SELECT 1 FROM requests r WHERE r.request_id <> g.request_id
      AND r.sent_ns < g.ts_ns AND coalesce(r.first_token_ns, r.last_ns) > g.prev_ns))
SELECT pos // 256 * 256 AS from_token, count(*) AS gaps,
       round(quantile_cont(gap_ms, 0.5), 2) AS step_ms_p50
FROM clean GROUP BY 1 ORDER BY 1
```

The position counts only the reply. With `turns: all`, add the turn's prompt length (`input_tokens`, for finished requests) to get the context length.

<a id="ttft-vs-queue"></a>
## TTFT against the queue at send time

```sql
SELECT r.request_id, r.turn, round((r.first_token_ns - r.sent_ns) / 1e6) AS ttft_ms, r.input_tokens,
       s.in_flight, s.waiting, s.decoding
FROM requests r ASOF JOIN series s ON r.sent_ns >= s.t_ns - 100000000
WHERE r.first_token_ns IS NOT NULL
ORDER BY ttft_ms DESC LIMIT 30
```

Here `in_flight`, `waiting` and `decoding` are the state just before the send.

<a id="one-request"></a>
## One request's life

```sql
SELECT round((ts_ns - (SELECT sent_ns FROM requests WHERE request_id = 'QWJhYvA_0-2')) / 1e6) AS ms_since_sent,
       token_chars, reasoning_chars, output_tokens, input_tokens, error,
       round((ts_ns - lag(ts_ns) OVER (ORDER BY ts_ns)) / 1e6, 1) AS gap_ms
FROM events WHERE request_id = 'QWJhYvA_0-2' ORDER BY ts_ns LIMIT 50
```

<a id="periodic"></a>
## Are the pauses periodic?

```sql
WITH all_tok AS (SELECT ts_ns, lag(ts_ns) OVER (ORDER BY ts_ns) AS prev_ns FROM tokens),
p AS (SELECT prev_ns, (ts_ns - prev_ns) / 1e6 AS ms FROM all_tok WHERE (ts_ns - prev_ns) / 1e6 > 100)
SELECT round((prev_ns - (SELECT min(sent_ns) FROM requests)) / 1e9, 2) AS at_s, round(ms) AS ms,
       round((prev_ns - lag(prev_ns) OVER (ORDER BY prev_ns)) / 1e9, 2) AS since_last_s
FROM p ORDER BY prev_ns
```

<a id="rate-vs-prompt"></a>
## Decode rate against prompt length

```sql
SELECT request_id, input_tokens, tokens,
       round((tokens - 1) / ((last_token_ns - first_token_ns) / 1e9), 1) AS decode_tok_s
FROM requests WHERE input_tokens > 0 AND tokens >= 10 ORDER BY input_tokens
```

<a id="paired"></a>
## Two runs, request by request

Run this with `zmlrun.py sql A.jsonl.gz B.jsonl.gz "…"`, which gives the views `a_` and `b_` prefixes. Same dataset and settings means same `request_id`, same prompt.

```sql
SELECT request_id,
       round((a.first_token_ns - a.sent_ns) / 1e6) AS a_ttft_ms,
       round((b.first_token_ns - b.sent_ns) / 1e6) AS b_ttft_ms,
       round((a.tokens - 1) / ((a.last_token_ns - a.first_token_ns) / 1e9), 1) AS a_tok_s,
       round((b.tokens - 1) / ((b.last_token_ns - b.first_token_ns) / 1e9), 1) AS b_tok_s
FROM a_requests a JOIN b_requests b USING (request_id)
ORDER BY request_id
```
