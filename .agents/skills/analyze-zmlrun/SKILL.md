---
name: analyze-zmlrun
description: Analyze LLM serving performance from a perf run file, a .jsonl.gz whose first line is a meta line (recorded by ZML-Lab or another benchmarker, with per-chunk stream timestamps, accelerator samples and meta.json) together with the server's launch command. It measures throughput, time to first token, inter-token latency, queueing, decode steps by batch, stalls around prefills and chip usage, and compares two servers or builds. From that, it proposes server-side improvements, each with an experiment to verify it. Use this whenever someone hands over such a .jsonl.gz or "zmlrun" file, a perf run or a benchmark trace of llmd, vLLM, SGLang or any OpenAI-compatible server, and asks why it is slow, how to make it faster, what changed between two runs or how two servers compare, even if they never name the file format.
---

# Analyze a serving run

A `.jsonl.gz` file is a load test of an LLM server, recorded from the client:
- a fixed number of concurrent streaming chat requests (ShareGPT prompts), with every streamed chunk timestamped as it arrived;
- the accelerators sampled about every 500 ms through `zml-smi`, when it was reachable;
- the run's settings and context in `meta.json`.

Your job is to turn the run into a diagnosis of the server and a ranked list of changes worth trying, each with the experiment that would confirm it. The person asking usually works on the server (often `llmd`, ZML's server), so make the recommendations about the server. The benchmark client is not the subject.

## Tools

`scripts/zmlrun.py`, next to this file, wraps DuckDB. Call it by its full path, from wherever this skill is installed (for example `<repo>/.agents/skills/analyze-zmlrun/scripts/zmlrun.py`). It runs through `uv` (`uv run` installs DuckDB on first use; with DuckDB already installed, `python3 …/zmlrun.py` works too):

```sh
zmlrun.py report RUN.jsonl.gz             # findings, then the evidence behind them
zmlrun.py compare A.jsonl.gz B.jsonl.gz   # side by side, paired by request
zmlrun.py sql RUN.jsonl.gz "SELECT …"     # ad-hoc SQL over ready-made views
zmlrun.py meta RUN.jsonl.gz               # the run's meta.json
```

The `sql` command creates these views, so a query can use them directly:
- `events`: every streamed chunk.
- `tokens`: the chunks that carry text.
- `requests`: one row per HTTP request.
- `gaps`: the time between consecutive tokens of a request.
- `series`: the run every 100 ms, with tokens/s and the number of requests in flight, waiting and decoding.
- `chips`: the accelerator samples.
- `meta`: the run's meta.json.

With several files, the views get `a_`, `b_`, … prefixes. [references/format.md](references/format.md) gives every column and the exact metric definitions; read it before writing your own SQL. [references/queries.md](references/queries.md) has queries for the usual follow-up questions.

## Workflow

1. **Gather the inputs.**
   - The run file(s).
   - The server's exact launch command. Ask for it if you don't have it: flags such as batch size, max sequences, chunked prefill, tensor parallelism, quantization or async scheduling change what every number means. `meta.notes` sometimes holds it.
   - The server's source, if you are in its repository. You can then point at code, not just at flags.
2. **Run `report`** on each file, and `compare` on pairs.
   - Read the Findings first, then check each one against the tables under it. The findings are observations past a threshold: they say what stands out, not why.
3. **Reconcile the numbers with the command.** Note which observations follow directly from the launch flags and which don't.
4. **Dig into what the report leaves open** with `sql`.
5. **Explain causes from the evidence.** Form your own hypotheses from the data, the hardware and, when you have it, the server's code; cite file and line. For each hypothesis, say what supports it, what could rule it out, and which run or profile would decide.
6. **Write the report** (below).

## What the data can and cannot show

Keep these limits in mind; they decide how strong a conclusion can be.

- **Timestamps come from the client machine.** Time to first token (TTFT) includes network, HTTP, tokenization, queueing and prefill, with no direct split between them. Token gaps are mostly server-side once streaming has started. On a remote target, the network adds a constant to TTFT.
- **A token here is a streamed chunk with text** (answer or reasoning). About 4 characters per chunk means one token per chunk. Many more means chunks carry several tokens, and gap timings are per chunk.
- **Prompt length (`input_tokens`) comes from the final usage chunk.** Only finished requests have it. Requests cut off at the end of the run have no usage, and their latency and length aren't final.
- **The load is a closed loop.** `concurrency` requests are always outstanding from the client. The server may run fewer at once and queue the rest: `decoding` in `series` estimates the server's active batch.
- **Warm-up is excluded** (when `params.warmup` is true). The run starts on a warmed server.
- **With `turns: all`, later turns carry the whole conversation so far**, so their prompts grow.
- **There is no kernel-level view.** To attribute time to kernels or host code, profile: Nsight or XProf, or the `profile-llmd` skill. Recommend that when the client-side data runs out.
- **Comparing two servers on `turns: all`:** only first turns send the same prompts. A later turn embeds the server's own earlier answer. Pair runs on first turns, and check the turn mix: `compare` warns about both.
- **Small runs are noisy.** With few finished requests, trust the per-gap statistics (thousands of samples) more than the per-request percentiles.

## The report

Write it for the engineer who will change the server.

1. **Setup:**
   - server, version and launch command, model, hardware;
   - run settings: concurrency, duration, output cap, ignore EOS, prompts, turns, warm-up;
   - anything that limits comparability.
2. **Headline:** three to six numbers that frame the rest. For example tokens/s, TTFT p50/p90, token gap p50/p99, per-request decode tok/s, the server's effective batch, and J/token if there were chip samples.
3. **Findings:** for each one,
   - the observation, with its number and how it was measured;
   - the interpretation;
   - your confidence in it.
   Keep observations and hypotheses visibly apart.
4. **Recommendations, ranked by expected gain.** For each:
   - the concrete change: a flag, a code area or a design change;
   - the effect you expect, in the metric it should move;
   - the experiment that would verify it, with exact settings for the next run.
5. **What would sharpen the diagnosis:** the missing data or the next run to record (see below).

## Designing the next run

Suggest runs that isolate one effect at a time:
- **Decode scaling:** sweep concurrency at 1, 2, 4, 8, … up to the server's batch and one step past it.
- **Comparable decode:** set a fixed output length with `ignore_eos` and a max-tokens cap.
- **Prefill on its own:** compare `prompts: short` with `long`, and `turns: first` with `all`.
- **Enough samples:** run long enough for at least 50 finished requests.
- **Defaults:** keep the warm-up on, and have `zml-smi` reachable for chip samples.

When comparing two servers or builds, change one thing at a time and keep the run settings identical; `compare` warns when they differ.
