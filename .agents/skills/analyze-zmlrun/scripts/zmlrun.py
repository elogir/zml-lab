#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["duckdb>=1.1"]
# ///
"""Analyze LLM serving runs recorded as .zmlrun.parquet files.

  zmlrun.py report RUN.zmlrun.parquet          findings + the evidence behind them
  zmlrun.py compare A.zmlrun.parquet B.zmlrun.parquet
  zmlrun.py sql RUN.zmlrun.parquet "SELECT ..."  ad-hoc SQL over ready-made views
  zmlrun.py meta RUN.zmlrun.parquet            the run's meta.json

Views available to `sql` (see references/format.md): run, events, tokens,
requests, gaps, series, chips, meta.
"""

from __future__ import annotations

import json
import sys

import duckdb

BUCKET_NS = 100_000_000  # the time series' 100 ms buckets


# --------------------------------------------------------------------------
# Loading


def _q(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def load(con: duckdb.DuckDBPyConnection, path: str, p: str = "") -> dict:
    """Creates the views for one run (names prefixed with p) and returns its
    meta.json (empty when absent)."""
    src = f"read_parquet({_q(path)})"
    cols = {r[0] for r in con.execute(f"DESCRIBE SELECT * FROM {src}").fetchall()}
    rc = "reasoning_chars" if "reasoning_chars" in cols else "0"
    con.execute(f"CREATE OR REPLACE VIEW {p}run AS SELECT * FROM {src}")
    con.execute(f"""
      CREATE OR REPLACE VIEW {p}events AS
      SELECT ts_ns, request_id, seq, request_ts_ns, token_chars,
             {rc} AS reasoning_chars, output_tokens, input_tokens,
             coalesce(error, '') AS error,
             token_chars + {rc} > 0 AS is_token
      FROM {p}run WHERE source = 'event'""")
    # Runs without chip samples have no chip columns at all.
    chip_cols = {
        "device": "INTEGER", "kind": "VARCHAR", "name": "VARCHAR",
        "util_percent": "INTEGER", "power_w": "DOUBLE", "power_limit_w": "DOUBLE",
        "temperature_c": "INTEGER", "mem_used_bytes": "BIGINT",
        "mem_total_bytes": "BIGINT", "clock_graphics_mhz": "INTEGER",
        "clock_mem_mhz": "INTEGER", "pcie_tx_kbps": "INTEGER", "pcie_rx_kbps": "INTEGER",
    }
    sel = ", ".join(
        (c if c in cols else f"NULL::{t} AS {c}") for c, t in chip_cols.items()
    )
    has_chips = "device" in cols
    con.execute(f"""
      CREATE OR REPLACE VIEW {p}chips AS
      SELECT ts_ns, {sel} FROM {p}run
      WHERE {"source = 'chip'" if has_chips else "false"}""")
    con.execute(f"CREATE OR REPLACE VIEW {p}tokens AS SELECT * FROM {p}events WHERE is_token")
    con.execute(f"""
      CREATE OR REPLACE VIEW {p}requests AS
      SELECT request_id,
             regexp_replace(request_id, '-[0-9]+$', '') AS conversation,
             try_cast(regexp_extract(request_id, '-([0-9]+)$', 1) AS INTEGER) AS turn,
             min(request_ts_ns) AS sent_ns,
             min(ts_ns) FILTER (WHERE is_token) AS first_token_ns,
             max(ts_ns) FILTER (WHERE is_token) AS last_token_ns,
             max(ts_ns) AS last_ns,
             count(*) FILTER (WHERE is_token) AS tokens,
             max(output_tokens) AS output_tokens,
             max(input_tokens) AS input_tokens,
             bool_or(error <> '') AS failed,
             any_value(error) FILTER (WHERE error <> '') AS error,
             bool_or(input_tokens > 0 OR error <> '') AS ended
      FROM {p}events GROUP BY request_id""")
    con.execute(f"""
      CREATE OR REPLACE VIEW {p}gaps AS
      SELECT request_id, prev_ns, ts_ns, (ts_ns - prev_ns) / 1e6 AS gap_ms FROM (
        SELECT request_id, ts_ns,
               lag(ts_ns) OVER (PARTITION BY request_id ORDER BY ts_ns) AS prev_ns
        FROM {p}tokens)
      WHERE prev_ns IS NOT NULL""")
    # The 100 ms time series (the run format's definitions), plus `decoding`:
    # in flight and past its first token.
    con.execute(f"""
      CREATE OR REPLACE VIEW {p}series AS
      WITH t AS (SELECT min(request_ts_ns) AS t0 FROM {p}events),
      pts AS (
        SELECT range AS i, t0 + (range + 1) * {BUCKET_NS} AS t_ns FROM t,
               range((SELECT max(greatest(0, (ts_ns - t0) // {BUCKET_NS})) + 1
                      FROM {p}events, t))),
      b AS (
        SELECT greatest(0, (ts_ns - t0) // {BUCKET_NS}) AS b, count(*) AS n
        FROM {p}tokens, t GROUP BY 1),
      tp AS (
        SELECT pts.i, coalesce(sum(b.n), 0) / ((pts.i - greatest(0, pts.i - 9) + 1) * 0.1) AS tps
        FROM pts LEFT JOIN b ON b.b BETWEEN greatest(0, pts.i - 9) AND pts.i GROUP BY pts.i),
      r AS (
        SELECT sent_ns, first_token_ns, last_ns,
               ended OR NOT (SELECT bool_or(ended) FROM {p}requests) AS ends_at_last
        FROM {p}requests),
      fl AS (
        SELECT pts.i, pts.t_ns,
          count(*) FILTER (WHERE r.sent_ns <= pts.t_ns
                             AND (NOT r.ends_at_last OR pts.t_ns < r.last_ns)) AS in_flight,
          count(*) FILTER (WHERE r.sent_ns <= pts.t_ns
                             AND (NOT r.ends_at_last OR pts.t_ns < r.last_ns)
                             AND (r.first_token_ns IS NULL OR pts.t_ns < r.first_token_ns)) AS waiting
        FROM pts, r GROUP BY pts.i, pts.t_ns)
      SELECT fl.i, (fl.i + 1) * 100 AS elapsed_ms, fl.t_ns, tp.tps AS tokens_per_second,
             fl.in_flight, fl.waiting, fl.in_flight - fl.waiting AS decoding
      FROM fl JOIN tp USING (i) ORDER BY fl.i""")
    rows = con.execute(
        f"SELECT decode(value) FROM parquet_kv_metadata({_q(path)}) "
        "WHERE decode(key) = 'zml.run'").fetchall()
    meta = json.loads(rows[0][0]) if rows else {}
    con.execute(f"CREATE OR REPLACE TABLE {p}meta AS SELECT {_q(json.dumps(meta))}::JSON AS meta")
    return meta


def one(con, sql):
    rows = con.execute(sql).fetchall()
    return rows[0] if rows else None


def val(con, sql):
    r = one(con, sql)
    return r[0] if r else None


# --------------------------------------------------------------------------
# Analysis


def analyze(con, meta: dict, p: str = "") -> dict:
    """Every number the report and compare print, plus the findings."""
    a: dict = {"meta": meta}
    params = meta.get("params") or {}
    conc = params.get("concurrency")

    (a["requests"], a["ended"], a["failed"], a["tokens"], a["duration_s"]) = one(con, f"""
      SELECT count(*), count(*) FILTER (WHERE ended), count(*) FILTER (WHERE failed),
             sum(tokens),
             ((SELECT max(ts_ns) FROM {p}events) - min(sent_ns)) / 1e9
      FROM {p}requests""")
    d = a["duration_s"] or 0
    a["tps"] = (a["tokens"] or 0) / d if d else 0
    a["rps"] = a["requests"] / d if d else 0
    a["cut_off"] = a["requests"] - a["ended"]

    def qs(sql):
        r = val(con, sql)
        return list(r) if r else None

    a["ttft"] = qs(f"SELECT quantile_cont((first_token_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) FROM {p}requests WHERE first_token_ns IS NOT NULL")
    a["itl"] = qs(f"SELECT quantile_cont(gap_ms, [0.5, 0.9, 0.99, 0.999]) FROM {p}gaps")
    a["itl_max"] = val(con, f"SELECT max(gap_ms) FROM {p}gaps")
    a["latency_ended"] = qs(f"SELECT quantile_cont((last_ns - sent_ns) / 1e6, [0.5, 0.9, 0.99]) FROM {p}requests WHERE ended")
    a["osl_ended"] = qs(f"SELECT quantile_cont(tokens, [0.5, 0.9, 0.99]) FROM {p}requests WHERE ended AND NOT failed")
    a["osl_max"] = val(con, f"SELECT max(tokens) FROM {p}requests")
    a["isl"] = qs(f"SELECT quantile_cont(input_tokens, [0.5, 0.9, 0.99]) FROM {p}requests WHERE input_tokens > 0")
    a["isl_n"] = val(con, f"SELECT count(*) FROM {p}requests WHERE input_tokens > 0")
    a["decode_rate"] = qs(f"""
      SELECT quantile_cont((tokens - 1) / ((last_token_ns - first_token_ns) / 1e9), [0.1, 0.5, 0.9])
      FROM {p}requests WHERE tokens >= 10 AND last_token_ns > first_token_ns""")
    a["chars_per_chunk"] = val(con, f"SELECT avg(token_chars + reasoning_chars) FROM {p}tokens")
    a["reasoning_share"] = val(con, f"SELECT sum(reasoning_chars) / nullif(sum(token_chars + reasoning_chars), 0) FROM {p}tokens")

    # Load shape over the steady part (the first and last second left out).
    n_pts = val(con, f"SELECT count(*) FROM {p}series") or 0
    lo, hi = (10, n_pts - 10) if n_pts > 30 else (0, n_pts)
    steady = f"FROM {p}series WHERE i >= {lo} AND i < {hi}"
    (a["tps_steady_p50"], a["tps_steady_p10"], a["tps_steady_p90"], a["tps_cv"]) = one(con, f"""
      SELECT quantile_cont(tokens_per_second, 0.5), quantile_cont(tokens_per_second, 0.1),
             quantile_cont(tokens_per_second, 0.9),
             stddev_samp(tokens_per_second) / nullif(avg(tokens_per_second), 0) {steady}""")
    a["tps_first_s"] = val(con, f"SELECT tokens_per_second FROM {p}series WHERE i = 9")
    (a["in_flight_p50"], a["in_flight_max"], a["decoding_p50"], a["decoding_max"],
     a["waiting_share"], a["waiting_p50_when"]) = one(con, f"""
      SELECT quantile_disc(in_flight, 0.5), max(in_flight),
             quantile_disc(decoding, 0.5), max(decoding),
             avg((waiting > 0)::INT), quantile_disc(waiting, 0.5) FILTER (WHERE waiting > 0)
      {steady}""")

    # Decode step time by how many requests were decoding at once.
    con.execute(f"""
      CREATE OR REPLACE TEMP TABLE {p}gap_ctx AS
      SELECT g.request_id, g.prev_ns, g.ts_ns, g.gap_ms,
             (SELECT count(*) FROM {p}requests r
              WHERE r.first_token_ns <= (g.prev_ns + g.ts_ns) // 2
                AND (g.prev_ns + g.ts_ns) // 2 < r.last_token_ns) AS decoding,
             (SELECT count(*) FROM {p}requests r
              WHERE r.request_id <> g.request_id
                AND r.sent_ns < g.ts_ns
                AND coalesce(r.first_token_ns, r.last_ns) > g.prev_ns) AS prefills
      FROM {p}gaps g""")
    # Pure decode steps: gaps with no other request in prefill (those are
    # reported apart, below).
    a["by_batch"] = con.execute(f"""
      SELECT decoding, count(*), quantile_cont(gap_ms, 0.5), quantile_cont(gap_ms, 0.9)
      FROM {p}gap_ctx WHERE decoding > 0 AND prefills = 0 GROUP BY 1 ORDER BY 1""").fetchall()
    itl50 = a["itl"][0] if a["itl"] else None
    # The usual decode step: at the batch most gaps saw.
    step = (max(a["by_batch"], key=lambda b: b[1])[2] if a["by_batch"] else itl50) or 0
    a["step_ms"] = step
    # Each gap once, even when several prefills overlapped it.
    a["prefill_extra_ms"] = val(con, f"""
      SELECT coalesce(sum(gap_ms - {step}), 0) FROM {p}gap_ctx
      WHERE prefills > 0 AND gap_ms > 1.5 * {step}""") if step else 0
    (a["itl_with_prefill"], a["itl_without_prefill"], a["gaps_with_prefill"],
     a["itl_with_prefill_max"]) = one(con, f"""
      SELECT quantile_cont(gap_ms, 0.5) FILTER (WHERE prefills > 0),
             quantile_cont(gap_ms, 0.5) FILTER (WHERE prefills = 0),
             count(*) FILTER (WHERE prefills > 0),
             max(gap_ms) FILTER (WHERE prefills > 0) FROM {p}gap_ctx""")
    # Each prefill that ran while others decoded: what it cost them. A
    # median over the gaps can hide one big stall; this can't. (Prefills
    # that overlap share their pauses: each row counts them.)
    a["prefill_stalls"] = con.execute(f"""
      SELECT r.request_id, r.turn,
             (r.sent_ns - (SELECT min(sent_ns) FROM {p}requests)) / 1e9 AS at_s,
             (r.first_token_ns - r.sent_ns) / 1e6 AS ttft_ms, r.input_tokens,
             count(*) AS gaps, max(g.gap_ms) AS max_gap_ms,
             coalesce(sum(g.gap_ms - {step}) FILTER (WHERE g.gap_ms > 1.5 * {step}), 0) AS extra_ms
      FROM {p}requests r JOIN {p}gaps g
        ON g.request_id <> r.request_id AND r.sent_ns < g.ts_ns
       AND coalesce(r.first_token_ns, r.last_ns) > g.prev_ns
      GROUP BY ALL ORDER BY max_gap_ms DESC""").fetchall() if step else []
    a["ttft_first"] = qs(f"""
      SELECT quantile_cont(ttft, [0.5, 0.9]) FROM (
        SELECT turn = min(turn) OVER (PARTITION BY conversation) AS first_turn,
               (first_token_ns - sent_ns) / 1e6 AS ttft
        FROM {p}requests WHERE first_token_ns IS NOT NULL) WHERE first_turn""")
    a["later_turns"] = val(con, f"""
      SELECT count(*) FROM (SELECT turn > min(turn) OVER (PARTITION BY conversation) AS later
                            FROM {p}requests) WHERE later""")
    if itl50:
        stall = max(3 * itl50, 50.0)
        (a["stalls"], a["stall_ms"], a["stall_ms_prefill"], a["decode_ms"]) = one(con, f"""
          SELECT count(*) FILTER (WHERE gap_ms > {stall}),
                 coalesce(sum(gap_ms) FILTER (WHERE gap_ms > {stall}), 0),
                 coalesce(sum(gap_ms) FILTER (WHERE gap_ms > {stall} AND prefills > 0), 0),
                 sum(gap_ms) FROM {p}gap_ctx""")
        a["stall_threshold_ms"] = stall
        # Server-wide pauses: no token from any request while some decode.
        glob = max(8 * itl50, 150.0)
        a["global_stalls"] = con.execute(f"""
          WITH all_tok AS (
            SELECT ts_ns, lag(ts_ns) OVER (ORDER BY ts_ns) AS prev_ns FROM {p}tokens),
          t AS (SELECT min(sent_ns) AS t0 FROM {p}requests)
          SELECT (prev_ns - t0) / 1e9 AS at_s, (ts_ns - prev_ns) / 1e6 AS ms,
                 (SELECT count(*) FROM {p}requests r
                  WHERE r.first_token_ns <= prev_ns AND prev_ns < r.last_token_ns) AS decoding,
                 (SELECT count(*) FROM {p}requests r
                  WHERE r.sent_ns < ts_ns AND coalesce(r.first_token_ns, r.last_ns) > prev_ns) AS prefills
          FROM all_tok, t WHERE (ts_ns - prev_ns) / 1e6 > {glob}
          ORDER BY ms DESC LIMIT 8""").fetchall()
        a["global_threshold_ms"] = glob

    # Prefill: time to first token against prompt length (requests whose
    # usage reported it), and by turn.
    (a["fit_slope"], a["fit_intercept"], a["fit_r2"], a["fit_n"]) = one(con, f"""
      SELECT regr_slope(ttft, input_tokens), regr_intercept(ttft, input_tokens),
             regr_r2(ttft, input_tokens), count(*) FROM (
        SELECT (first_token_ns - sent_ns) / 1e6 AS ttft, input_tokens
        FROM {p}requests WHERE input_tokens > 0 AND first_token_ns IS NOT NULL)""")
    a["ttft_by_turn"] = con.execute(f"""
      SELECT turn = min(turn) OVER (PARTITION BY conversation) AS first_turn, count(*),
             quantile_cont((first_token_ns - sent_ns) / 1e6, 0.5)
      FROM {p}requests WHERE first_token_ns IS NOT NULL
      GROUP BY ALL ORDER BY 1 DESC""").fetchall() if False else con.execute(f"""
      SELECT first_turn, count(*), quantile_cont(ttft, 0.5) FROM (
        SELECT turn = min(turn) OVER (PARTITION BY conversation) AS first_turn,
               (first_token_ns - sent_ns) / 1e6 AS ttft
        FROM {p}requests WHERE first_token_ns IS NOT NULL)
      GROUP BY 1 ORDER BY 1 DESC""").fetchall()
    a["slowest_ttft"] = con.execute(f"""
      SELECT request_id, (first_token_ns - sent_ns) / 1e6, input_tokens,
             (sent_ns - (SELECT min(sent_ns) FROM {p}requests)) / 1e9
      FROM {p}requests WHERE first_token_ns IS NOT NULL ORDER BY 2 DESC LIMIT 5""").fetchall()

    # Chips.
    a["chips"] = con.execute(f"""
      WITH e AS (
        SELECT device, sum(j) AS energy_j FROM (
          SELECT device, (power_w + lag(power_w) OVER w) / 2
                         * (ts_ns - lag(ts_ns) OVER w) / 1e9 AS j
          FROM {p}chips WHERE power_w IS NOT NULL
          WINDOW w AS (PARTITION BY device ORDER BY ts_ns))
        GROUP BY device)
      SELECT c.device, any_value(c.name), count(*),
             avg(util_percent), max(util_percent),
             avg(power_w), max(power_w), max(power_limit_w),
             max(temperature_c), min(clock_graphics_mhz), max(clock_graphics_mhz),
             max(mem_used_bytes), max(mem_total_bytes), any_value(e.energy_j)
      FROM {p}chips c LEFT JOIN e USING (device) GROUP BY c.device ORDER BY c.device""").fetchall()
    energy = sum(r[13] or 0 for r in a["chips"])
    a["joules_per_token"] = energy / a["tokens"] if energy and a["tokens"] else None
    a["errors"] = con.execute(f"""
      SELECT left(error, 160), count(*) FROM {p}requests WHERE failed GROUP BY 1 ORDER BY 2 DESC LIMIT 5""").fetchall()

    a["findings"] = findings(a, conc)
    return a


def findings(a: dict, conc) -> list[tuple[str, str]]:
    """Observations worth a look, each with its evidence. (severity, text)"""
    f: list[tuple[str, str]] = []
    itl50 = a["itl"][0] if a["itl"] else None

    if a["ended"] < 20:
        f.append(("note", f"Small sample: {a['ended']} finished requests ({a['requests']} in all). "
                          "Percentiles rest on few values; the per-gap numbers (ITL, decode steps) are sturdier."))
    if a["cut_off"] and a["requests"] and a["cut_off"] / a["requests"] > 0.3:
        f.append(("note", f"{a['cut_off']} of {a['requests']} requests were cut off by the run's end "
                          "(replies long against the duration): their latency and length aren't final."))
    if a["failed"]:
        top = "; ".join(f"{n}× {e}" for e, n in a["errors"])
        f.append(("warn", f"{a['failed']} failed requests: {top}"))

    if conc and a["waiting_share"] and a["waiting_share"] > 0.2 and a["decoding_max"] and a["decoding_max"] < conc:
        f.append(("warn", f"Queueing: some request waited for a first token in {a['waiting_share']:.0%} of the run, "
                          f"while at most {a['decoding_max']} decoded at once against a concurrency of {conc}."))
    elif conc and a["decoding_p50"] is not None and a["decoding_p50"] < conc and (a["waiting_share"] or 0) <= 0.2:
        f.append(("note", f"Median {a['decoding_p50']} requests decoding against a concurrency of {conc}, "
                          f"with someone waiting for a first token in only {a['waiting_share'] or 0:.0%} of the run."))

    step = a.get("step_ms")
    stalling = [s for s in a.get("prefill_stalls", []) if step and s[6] > max(3 * step, 50)]
    if stalling:
        worst = stalling[0]
        together = sum(1 for s in stalling if s[6] == worst[6])
        who = f"{worst[0]} prefilled" if together == 1 else f"{together} requests prefilled together"
        decode_s = (a.get("decode_ms") or 0) / 1000
        extra = (a.get("prefill_extra_ms") or 0) / 1000
        share = f" ({extra / decode_s:.0%} of all decoding time)" if decode_s else ""
        f.append(("warn", f"Prefill stalls the others' decode: {len(stalling)} of "
                          f"{len(a['prefill_stalls'])} prefills that overlapped decoding made someone wait "
                          f"over 3× the {step:.1f} ms step; worst {worst[6]:.0f} ms ({worst[6] / step:.0f}×) "
                          f"while {who}; {extra:.1f} s of extra waiting summed over the "
                          f"waiting requests{share}. Per-prefill detail in the table under Load."))
    elif a["itl_with_prefill"] and a["itl_without_prefill"] and a["gaps_with_prefill"] >= 20:
        ratio = a["itl_with_prefill"] / a["itl_without_prefill"]
        if ratio > 1.3:
            f.append(("note", f"Decode slows a little while others prefill: median token gap "
                              f"{a['itl_with_prefill']:.1f} ms during a prefill vs "
                              f"{a['itl_without_prefill']:.1f} ms otherwise ({ratio:.1f}×)."))
    if itl50 and a.get("stall_ms") and a.get("decode_ms"):
        share = a["stall_ms"] / a["decode_ms"]
        if share > 0.05:
            pre = a["stall_ms_prefill"] / a["stall_ms"] if a["stall_ms"] else 0
            f.append(("warn", f"Token stalls: {a['stalls']} gaps over {a['stall_threshold_ms']:.0f} ms "
                              f"(3× the median gap) hold {share:.0%} of decode time; {pre:.0%} of that "
                              "overlaps another request's prefill."))
    if a.get("global_stalls"):
        unexplained = [g for g in a["global_stalls"] if g[3] == 0]
        if unexplained:
            worst = unexplained[0]
            f.append(("warn", f"Server-wide pauses with no prefill in flight: {len(unexplained)} windows over "
                              f"{a['global_threshold_ms']:.0f} ms without a token from anyone (worst "
                              f"{worst[1]:.0f} ms at {worst[0]:.1f} s, {worst[2]} decoding)."))
    by = [b for b in a["by_batch"] if b[1] >= 30]
    if by and a["tps"]:
        # What pure decode at the usual batch would give, against what the
        # run got.
        k, _, step, _ = max(by, key=lambda b: b[1])
        ceiling = k * 1000 / step
        if a["tps"] < 0.85 * ceiling:
            f.append(("warn", f"Throughput {a['tps']:,.0f} tok/s is {a['tps'] / ceiling:.0%} of what decode alone "
                              f"gives at the usual batch ({k} sequences × 1000 / {step:.1f} ms = {ceiling:,.0f})."))
    if len(by) >= 2:
        k1, kn = by[0], by[-1]
        gain = (kn[0] * 1000 / kn[2]) / (k1[0] * 1000 / k1[2])
        ideal = kn[0] / k1[0]
        if gain < 0.6 * ideal:
            f.append(("warn", f"Batching gains little: {kn[0]} sequences decode at {kn[2]:.1f} ms/step vs "
                              f"{k1[2]:.1f} ms with {k1[0]} — {gain:.1f}× the aggregate tokens/s for "
                              f"{ideal:.0f}× the sequences."))
    if a["fit_n"] and a["fit_n"] >= 8 and a["fit_slope"] and a["fit_r2"] is not None:
        if a["fit_r2"] > 0.5 and a["fit_slope"] > 0:
            rate = 1000 / a["fit_slope"]
            f.append(("note", f"Prefill: time to first token ≈ {a['fit_intercept']:.0f} ms + "
                              f"{a['fit_slope'] * 1000:.0f} ms per 1k prompt tokens (R² {a['fit_r2']:.2f}, "
                              f"n={a['fit_n']}) → about {rate:,.0f} prompt tokens/s per request."))
        elif a["fit_r2"] <= 0.5:
            f.append(("note", f"Time to first token barely follows prompt length (R² {a['fit_r2']:.2f}, "
                              f"n={a['fit_n']})."))
    if a["tps_first_s"] is not None and a["tps_steady_p50"]:
        if a["tps_first_s"] < 0.5 * a["tps_steady_p50"]:
            warm = (a["meta"].get("params") or {}).get("warmup")
            f.append(("note", f"Slow start: {a['tps_first_s']:.0f} tok/s over the first second vs "
                              f"{a['tps_steady_p50']:.0f} steady (warm-up {'on' if warm else 'off'})."))
    if a["tps_cv"] and a["tps_cv"] > 0.25:
        f.append(("note", f"Throughput unsteady: coefficient of variation {a['tps_cv']:.2f} over the steady part "
                          f"(p10 {a['tps_steady_p10']:.0f}, p90 {a['tps_steady_p90']:.0f} tok/s)."))
    if a["chars_per_chunk"] and a["chars_per_chunk"] > 10:
        f.append(("note", f"{a['chars_per_chunk']:.1f} characters per streamed chunk: chunks likely carry "
                          "several tokens, so token gaps measure chunks (and tokens/s counts chunks)."))
    if a["osl_max"] and a["ended"] >= 5 and a["osl_ended"]:
        p50, _, p99 = a["osl_ended"]
        params = a["meta"].get("params") or {}
        if p50 == p99 and params.get("max_completion_tokens") is None and not params.get("ignore_eos"):
            f.append(("note", f"Every finished reply has {p50:.0f} tokens, though no cap was sent and "
                              "EOS wasn't ignored."))

    for c in a["chips"]:
        dev, name, n, ua, um, pa, pm, pl, tm, cmin, cmax, mu, mt, _ = c
        if n < 3:
            continue
        if ua is not None and ua < 60:
            f.append(("note", f"Chip {dev} ({name}): {ua:.0f}% average utilization."))
        if pm and pl and pm >= 0.95 * pl:
            f.append(("note", f"Chip {dev}: power reached {pm:.0f} W of a {pl:.0f} W limit."))
        if cmin and cmax and cmin < 0.8 * cmax:
            f.append(("note", f"Chip {dev}: graphics clock ranged {cmin}–{cmax} MHz during the run."))
        if tm and tm >= 85:
            f.append(("note", f"Chip {dev}: {tm} °C peak."))
        if mu and mt and mu / mt < 0.7:
            f.append(("note", f"Chip {dev}: memory peaked at {mu / 1e9:.0f} of {mt / 1e9:.0f} GB."))
    utils = [c[3] for c in a["chips"] if c[3] is not None]
    if len(utils) > 1 and max(utils) - min(utils) > 15:
        f.append(("warn", f"Uneven chips: average utilization {min(utils):.0f}–{max(utils):.0f}% across devices."))
    return f


# --------------------------------------------------------------------------
# Printing


def fmt(x, nd=1):
    if x is None:
        return "–"
    if isinstance(x, float):
        return f"{x:,.{nd}f}"
    return f"{x:,}" if isinstance(x, int) else str(x)


def qfmt(q, nd=1):
    return " / ".join(fmt(v, nd) for v in q) if q else "–"


def identity(meta: dict, path: str) -> list[str]:
    s = meta.get("server") or {}
    p = meta.get("params") or {}
    hw = (meta.get("hardware") or {}).get("description")
    out = [f"# {meta.get('label') or path}", "", f"File: `{path}`"]
    out.append(
        f"Server: kind {s.get('kind', '?')}"
        + (f", version {s['version']}" if s.get("version") else "")
        + (f", commit {s['commit']}" if s.get("commit") else "")
        + f" · model {(meta.get('model') or {}).get('name', '?')}"
        + (f" · hardware {hw}" if hw else ""))
    out.append(
        f"Params: concurrency {p.get('concurrency')}, duration {p.get('duration_s')} s, "
        f"max tokens {p.get('max_completion_tokens') or 'none'}, ignore EOS {p.get('ignore_eos')}, "
        f"prompts {p.get('prompts')}, turns {p.get('turns')}, warm-up {p.get('warmup')}")
    extra = []
    if meta.get("started_at"):
        extra.append(f"started {meta['started_at']}")
    if meta.get("cancelled"):
        extra.append("**stopped early**")
    if (meta.get("target") or {}).get("url"):
        extra.append(f"target {meta['target']['url']}")
    if (meta.get("client") or {}).get("host"):
        extra.append(f"client {meta['client']['host']}")
    if meta.get("notes"):
        extra.append(f"notes: {meta['notes']}")
    if extra:
        out.append(" · ".join(extra))
    return out


def report(a: dict, path: str) -> str:
    m = a["meta"]
    out = identity(m, path)
    out += ["", "## Findings", ""]
    if a["findings"]:
        for sev, text in a["findings"]:
            out.append(f"- {'⚠' if sev == 'warn' else '·'} {text}")
    else:
        out.append("- Nothing stands out.")
    out += ["", "## Headline", "",
            "| metric | value |", "| --- | --- |",
            f"| requests | {a['requests']} ({a['ended']} finished, {a['cut_off']} cut off, {a['failed']} failed) |",
            f"| tokens/s (whole run) | {fmt(a['tps'])} |",
            f"| requests/s | {fmt(a['rps'], 3)} |",
            f"| tokens/s steady p10 / p50 / p90 | {qfmt([a['tps_steady_p10'], a['tps_steady_p50'], a['tps_steady_p90']], 0)} |",
            f"| TTFT ms p50 / p90 / p99 | {qfmt(a['ttft'])} |",
            f"| token gap (ITL) ms p50 / p90 / p99 / p99.9 | {qfmt(a['itl'])} (max {fmt(a['itl_max'])}) |",
            f"| per-request decode tok/s p10 / p50 / p90 | {qfmt(a['decode_rate'])} |",
            f"| latency ms p50 / p90 / p99 (finished) | {qfmt(a['latency_ended'], 0)} |",
            f"| output tokens p50 / p90 / p99 (finished) | {qfmt(a['osl_ended'], 0)} |",
            f"| prompt tokens p50 / p90 / p99 | {qfmt(a['isl'], 0)} (reported for {a['isl_n']}) |",
            f"| duration s | {fmt(a['duration_s'])} |",
            f"| chars per token chunk | {fmt(a['chars_per_chunk'])} (reasoning {fmt((a['reasoning_share'] or 0) * 100, 0)}%) |"]
    out += ["", "## Load", "",
            f"In flight (sent, not ended): median {a['in_flight_p50']}, max {a['in_flight_max']}; "
            f"decoding: median {a['decoding_p50']}, max {a['decoding_max']}; "
            f"someone waiting for a first token in {fmt((a['waiting_share'] or 0) * 100, 0)}% of the steady run"
            + (f" (median {a['waiting_p50_when']} waiting then)" if a["waiting_p50_when"] else "") + ".",
            f"Throughput over the first second: {fmt(a['tps_first_s'], 0)} tok/s.",
            "", "### Decode step by batch", "",
            "Token gaps grouped by how many requests were decoding at that moment "
            "(per-sequence tok/s = 1000 / step; aggregate = batch × that).", "",
            "| decoding | gaps | step ms p50 | p90 | per-seq tok/s | aggregate tok/s |",
            "| ---: | ---: | ---: | ---: | ---: | ---: |"]
    for k, n, p50, p90 in a["by_batch"]:
        out.append(f"| {k} | {n} | {fmt(p50)} | {fmt(p90)} | {fmt(1000 / p50 if p50 else None)} | "
                   f"{fmt(k * 1000 / p50 if p50 else None, 0)} |")
    out += ["", f"Median token gap while another request prefills: {fmt(a['itl_with_prefill'])} ms "
                f"({a['gaps_with_prefill']} gaps); otherwise {fmt(a['itl_without_prefill'])} ms."]
    if a.get("prefill_stalls"):
        out += ["", f"### Prefills while others decoded (worst first, step {fmt(a['step_ms'])} ms)", "",
                "Extra waiting = the time the others' gaps ran over the step, summed over gaps above 1.5× it.", "",
                "| request | turn | at s | TTFT ms | prompt tokens | others' gaps | max gap ms | extra waiting ms |",
                "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
        for rid, turn, at, ttft, inp, n, mx, extra in a["prefill_stalls"][:10]:
            out.append(f"| {rid} | {turn} | {at:.1f} | {fmt(ttft, 0)} | {inp or '?'} | {n} | "
                       f"{fmt(mx, 0)} | {fmt(extra, 0)} |")
        if len(a["prefill_stalls"]) > 10:
            out.append(f"({len(a['prefill_stalls'])} prefills in all)")
    if a.get("global_stalls"):
        out += ["", f"### Pauses: no token from anyone for over {a['global_threshold_ms']:.0f} ms", "",
                "| at s | ms | decoding | prefilling |", "| ---: | ---: | ---: | ---: |"]
        for at, ms, dec, pre in a["global_stalls"]:
            out.append(f"| {at:.1f} | {ms:.0f} | {dec} | {pre} |")
    out += ["", "## Prefill", ""]
    if a["fit_n"] and a["fit_n"] >= 5:
        out.append(f"TTFT vs prompt tokens (n={a['fit_n']}): intercept {fmt(a['fit_intercept'], 0)} ms, "
                   f"slope {fmt((a['fit_slope'] or 0) * 1000, 1)} ms per 1k tokens, R² {fmt(a['fit_r2'], 2)}.")
    else:
        out.append(f"Too few requests with a reported prompt length ({a['fit_n'] or 0}) to fit TTFT against "
                   "it (only finished requests report usage).")
    for first, n, ttft in a["ttft_by_turn"]:
        out.append(f"{'First turns' if first else 'Later turns'}: {n} requests, TTFT p50 {fmt(ttft)} ms.")
    out += ["", "Slowest first tokens:", "", "| request | TTFT ms | prompt tokens | sent at s |",
            "| --- | ---: | ---: | ---: |"]
    for rid, t, inp, at in a["slowest_ttft"]:
        out.append(f"| {rid} | {fmt(t, 0)} | {inp or '?'} | {at:.1f} |")
    if a["chips"]:
        out += ["", "## Chips", "",
                "| dev | name | samples | util avg / max % | power avg / max / limit W | temp max °C "
                "| clock MHz min–max | mem peak / total GB |",
                "| ---: | --- | ---: | --- | --- | ---: | --- | --- |"]
        for c in a["chips"]:
            dev, name, n, ua, um, pa, pm, pl, tm, cmin, cmax, mu, mt, _ = c
            out.append(f"| {dev} | {name} | {n} | {fmt(ua, 0)} / {fmt(um)} | {fmt(pa, 0)} / {fmt(pm, 0)} / "
                       f"{fmt(pl, 0)} | {fmt(tm)} | {fmt(cmin)}–{fmt(cmax)} | "
                       f"{fmt(mu / 1e9 if mu else None, 0)} / {fmt(mt / 1e9 if mt else None, 0)} |")
        if a["joules_per_token"]:
            out.append(f"\nEnergy: {a['joules_per_token']:.3f} J per token (all chips).")
    else:
        out += ["", "No chip samples in this run (zml-smi wasn't reachable)."]
    return "\n".join(out)


COMPARE_PARAMS = ["concurrency", "duration_s", "max_completion_tokens", "ignore_eos",
                  "prompts", "turns", "warmup"]


def compare(con, a: dict, b: dict, pa: str, pb: str) -> str:
    ma, mb = a["meta"], b["meta"]
    la, lb = ma.get("label") or pa, mb.get("label") or pb
    out = [f"# {la}  vs  {lb}", "", f"A: `{pa}`", f"B: `{pb}`", ""]
    diffs = []
    for k in COMPARE_PARAMS:
        va, vb = (ma.get("params") or {}).get(k), (mb.get("params") or {}).get(k)
        if va != vb:
            diffs.append(f"{k} {va} → {vb}")
    if (ma.get("model") or {}).get("name") != (mb.get("model") or {}).get("name"):
        diffs.append(f"model {(ma.get('model') or {}).get('name')} → {(mb.get('model') or {}).get('name')}")
    if (ma.get("dataset") or {}).get("name") != (mb.get("dataset") or {}).get("name"):
        diffs.append("dataset differs")
    out.append("**Not like for like:** " + "; ".join(diffs) if diffs else
               "Same model and run settings: comparable.")
    ra, rb = a["reasoning_share"] or 0, b["reasoning_share"] or 0
    if abs(ra - rb) > 0.3:
        out.append(f"Reasoning text: {ra:.0%} of A's characters, {rb:.0%} of B's — one server streams "
                   "thinking as `reasoning_content`, the other inside the answer (e.g. vLLM without "
                   "`--reasoning-parser`). Tokens count either way, but later turns differ: the "
                   "benchmark feeds only the answer back into the next turn, so the server that "
                   "streams thinking as answer gets much longer later-turn prompts.")
    if (a["later_turns"] or 0) != (b["later_turns"] or 0):
        out.append(f"Turn mix: {a['later_turns']} later-turn requests in A, {b['later_turns']} in B. "
                   "Later turns carry the conversation so far (longer prompts), so overall TTFT isn't "
                   "like for like: use the first-turn and paired rows.")
    out.append("Servers: A " + json.dumps(ma.get("server") or {}) + ", B " + json.dumps(mb.get("server") or {}))

    def row(name, x, y, lower_better=False, nd=1):
        r = (y / x) if (x and y) else None
        tag = ""
        if r:
            better = (r < 1) if lower_better else (r > 1)
            tag = f"{r:.2f}×" + (" (B better)" if better and abs(r - 1) > 0.05 else
                                  " (A better)" if abs(r - 1) > 0.05 else "")
        return f"| {name} | {fmt(x, nd)} | {fmt(y, nd)} | {tag} |"

    q = lambda s, i: (s or [None] * 4)[i]
    out += ["", "| metric | A | B | B / A |", "| --- | ---: | ---: | --- |",
            row("tokens/s (whole run)", a["tps"], b["tps"]),
            row("tokens/s steady p50", a["tps_steady_p50"], b["tps_steady_p50"]),
            row("requests/s", a["rps"], b["rps"], nd=3),
            row("first-turn TTFT p50 ms", q(a["ttft_first"], 0), q(b["ttft_first"], 0), True),
            row("first-turn TTFT p90 ms", q(a["ttft_first"], 1), q(b["ttft_first"], 1), True),
            row("TTFT p50 ms (all turns)", q(a["ttft"], 0), q(b["ttft"], 0), True),
            row("decode step ms (usual batch)", a["step_ms"], b["step_ms"], True),
            row("token gap p50 ms", q(a["itl"], 0), q(b["itl"], 0), True),
            row("token gap p99 ms", q(a["itl"], 2), q(b["itl"], 2), True),
            row("token gap max ms", a["itl_max"], b["itl_max"], True),
            row("worst prefill stall ms",
                a["prefill_stalls"][0][6] if a.get("prefill_stalls") else None,
                b["prefill_stalls"][0][6] if b.get("prefill_stalls") else None, True, 0),
            row("per-request decode tok/s p50", q(a["decode_rate"], 1), q(b["decode_rate"], 1)),
            row("decoding at once (max)", a["decoding_max"], b["decoding_max"]),
            row("finished requests", a["ended"], b["ended"]),
            row("J per token", a["joules_per_token"], b["joules_per_token"], True, 3)]
    # Same dataset, same order: the same request ids got the same prompts.
    paired = con.execute("""
      SELECT count(*),
             median(((b.first_token_ns - b.sent_ns) / (a.first_token_ns - a.sent_ns))),
             median(((b.tokens - 1) / ((b.last_token_ns - b.first_token_ns) / 1e9))
                    / ((a.tokens - 1) / ((a.last_token_ns - a.first_token_ns) / 1e9)))
               FILTER (WHERE a.tokens >= 10 AND b.tokens >= 10
                         AND a.last_token_ns > a.first_token_ns AND b.last_token_ns > b.first_token_ns)
      FROM a_requests a JOIN b_requests b USING (request_id)
      WHERE a.first_token_ns IS NOT NULL AND b.first_token_ns IS NOT NULL""").fetchall()[0]
    if paired[0]:
        out += ["", f"Paired by request (same prompt in both runs, {paired[0]} requests): median B/A TTFT "
                    f"{fmt(paired[1], 2)}×, median B/A decode rate {fmt(paired[2], 2)}×."]
    out += ["", "## Decode step by batch", "", "| decoding | A step ms p50 | B step ms p50 |",
            "| ---: | ---: | ---: |"]
    ka, kb = {r[0]: r for r in a["by_batch"]}, {r[0]: r for r in b["by_batch"]}
    for k in sorted(set(ka) | set(kb)):
        out.append(f"| {k} | {fmt(ka[k][2]) if k in ka else '–'} | {fmt(kb[k][2]) if k in kb else '–'} |")
    for name, x in (("A", a), ("B", b)):
        out += ["", f"## Findings, {name}", ""]
        out += [f"- {'⚠' if s == 'warn' else '·'} {t}" for s, t in x["findings"]] or ["- Nothing stands out."]
    return "\n".join(out)


def table(con, sql: str, limit: int = 200) -> str:
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description] if cur.description else []
    rows = cur.fetchmany(limit + 1)
    out = ["| " + " | ".join(cols) + " |", "|" + " --- |" * len(cols)]
    for r in rows[:limit]:
        out.append("| " + " | ".join(fmt(v, 3) if isinstance(v, float) else str(v) for v in r) + " |")
    if len(rows) > limit:
        out.append(f"(first {limit} rows)")
    return "\n".join(out)


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[0] not in {"report", "compare", "sql", "meta"}:
        print(__doc__)
        return 2
    cmd, args = argv[0], argv[1:]
    con = duckdb.connect()
    if cmd == "report":
        for path in args:
            meta = load(con, path)
            print(report(analyze(con, meta), path))
            print()
    elif cmd == "meta":
        print(json.dumps(load(con, args[0]), indent=2))
    elif cmd == "compare":
        if len(args) != 2:
            print("compare takes two runs")
            return 2
        ma, mb = load(con, args[0], "a_"), load(con, args[1], "b_")
        a, b = analyze(con, ma, "a_"), analyze(con, mb, "b_")
        print(compare(con, a, b, args[0], args[1]))
    elif cmd == "sql":
        if len(args) < 2:
            print('sql takes a run and a query: zmlrun.py sql RUN "SELECT ..."')
            return 2
        *paths, query = args
        if len(paths) == 1:
            load(con, paths[0])
        else:  # several runs: a_, b_, c_… prefixes
            for i, path in enumerate(paths):
                load(con, path, chr(ord("a") + i) + "_")
        print(table(con, query))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
