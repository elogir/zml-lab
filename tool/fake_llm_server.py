#!/usr/bin/env python3
"""A fake OpenAI-compatible LLM server for exercising ZML-Lab's benchmark tab
without a GPU: /v1/chat/completions streams canned markdown at a set pace, plus
/v1/models and /health. Standard library only; one asyncio loop serves
thousands of concurrent streams.

    python3 tool/fake_llm_server.py --port 8000 --tokens 2000 --rate 40

Then point the Benchmark tab at 127.0.0.1:8000. Every request streams
--tokens tokens (capped by the request's max_tokens or max_completion_tokens)
at --rate tok/s each,
after --ttft-ms. --reasoning N streams N "thinking" tokens first.

macOS caps a listen backlog at kern.ipc.somaxconn (128 by default), so a burst
of more connections than that can be reset before the server accepts them.
For batches above ~128, raise it first (resets on reboot):

    sudo sysctl -w kern.ipc.somaxconn=2048
"""

import argparse
import asyncio
import json
import random
import time

SAMPLE = """\
## Tensor vs pipeline parallelism

**Tensor parallelism** splits each layer's weight matrices across devices, so
every device holds a slice of every layer and they all-reduce activations after
each `matmul`. It keeps latency low but needs fast interconnect.

**Pipeline parallelism** gives each device a contiguous block of layers and
streams micro-batches through them. Communication is small (activations at the
stage boundary), but bubbles appear while the pipeline fills and drains.

```python
# Megatron-style column-parallel linear
y_local = x @ w[:, rank * shard:(rank + 1) * shard]
y = all_gather(y_local, axis=-1)
```

| | tensor | pipeline |
|---|---|---|
| comm volume | high | low |
| latency | low | higher |
| memory per device | split weights | split layers |

In practice large models combine both, plus data parallelism on top.

"""

TOKENS = [t + " " for t in SAMPLE.replace("\n", " \n").split(" ") if t]


def chunk(model, delta, finish=None, usage=None):
    body = {
        "id": "chatcmpl-fake",
        "object": "chat.completion.chunk",
        "created": int(time.time()),
        "model": model,
        "choices": [{"index": 0, "delta": delta, "finish_reason": finish}],
    }
    if usage is not None:
        body["usage"] = usage
    return ("data: " + json.dumps(body) + "\n\n").encode()


async def read_request(reader):
    head = await reader.readuntil(b"\r\n\r\n")
    lines = head.decode("latin-1").split("\r\n")
    method, path, _ = lines[0].split(" ", 2)
    headers = {}
    for line in lines[1:]:
        if ":" in line:
            k, v = line.split(":", 1)
            headers[k.strip().lower()] = v.strip()
    body = b""
    if headers.get("transfer-encoding", "").lower() == "chunked":
        while True:
            size = int((await reader.readuntil(b"\r\n")).strip().split(b";")[0], 16)
            if size == 0:
                await reader.readuntil(b"\r\n")
                break
            body += await reader.readexactly(size)
            await reader.readexactly(2)
    elif headers.get("content-length"):
        body = await reader.readexactly(int(headers["content-length"]))
    return method, path.split("?")[0], body


def respond(writer, status, content_type, payload):
    writer.write(
        (
            f"HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\n"
            f"Content-Length: {len(payload)}\r\nConnection: close\r\n\r\n"
        ).encode()
        + payload
    )


async def stream_reply(writer, args, req):
    model = req.get("model") or "fake-model"
    n = args.tokens
    # max_completion_tokens is what openai-go (the perf benchmarker) sends.
    for key in ("max_tokens", "max_completion_tokens"):
        if isinstance(req.get(key), int) and req[key] > 0:
            n = min(n, req[key])
    writer.write(
        b"HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n"
        b"Cache-Control: no-cache\r\nConnection: close\r\n\r\n"
    )
    writer.write(chunk(model, {"role": "assistant", "content": ""}))
    await writer.drain()
    await asyncio.sleep(args.ttft_ms / 1000 * random.uniform(0.8, 1.2))

    # Per-request speed varies a little, like a real batch.
    delay = 1 / (args.rate * random.uniform(0.9, 1.1))
    offset = random.randrange(len(TOKENS))
    sent = 0
    for i in range(args.reasoning):
        writer.write(chunk(model, {"reasoning_content": "thinking… "}))
        sent += 1
        await writer.drain()
        await asyncio.sleep(delay)
    for i in range(n):
        writer.write(chunk(model, {"content": TOKENS[(offset + i) % len(TOKENS)]}))
        sent += 1
        await writer.drain()
        await asyncio.sleep(delay)
    finish = "length" if n < args.tokens else "stop"
    usage = {"prompt_tokens": 20, "completion_tokens": sent, "total_tokens": sent + 20}
    writer.write(chunk(model, {}, finish=finish, usage=usage))
    writer.write(b"data: [DONE]\n\n")
    await writer.drain()


async def handle(reader, writer, args):
    try:
        method, path, body = await read_request(reader)
        if path == "/health":
            respond(writer, "200 OK", "text/plain", b"ok")
        elif path in ("/v1/models", "/v1/models/"):
            payload = {"object": "list", "data": [{"id": "fake-model", "object": "model"}]}
            respond(writer, "200 OK", "application/json", json.dumps(payload).encode())
        elif path in ("/v1/chat/completions", "/v1/chat/completions/") and method == "POST":
            req = json.loads(body or b"{}")
            if random.random() < args.fail_rate:
                respond(writer, "500 Internal Server Error", "text/plain", b"simulated failure")
            elif req.get("stream"):
                await stream_reply(writer, args, req)
            else:
                text = "".join(TOKENS[: args.tokens])
                payload = {
                    "object": "chat.completion",
                    "model": req.get("model") or "fake-model",
                    "choices": [{"index": 0, "message": {"role": "assistant", "content": text}, "finish_reason": "stop"}],
                    "usage": {"completion_tokens": args.tokens},
                }
                respond(writer, "200 OK", "application/json", json.dumps(payload).encode())
        else:
            respond(writer, "404 Not Found", "text/plain", b"not found")
        await writer.drain()
    except (asyncio.IncompleteReadError, ConnectionError):
        pass  # client went away (cancelled run)
    finally:
        writer.close()


async def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=8000)
    p.add_argument("--tokens", type=int, default=500, help="tokens per reply")
    p.add_argument("--rate", type=float, default=40, help="tok/s per request")
    p.add_argument("--ttft-ms", type=float, default=200, help="delay before the first token")
    p.add_argument("--reasoning", type=int, default=0, help="thinking tokens before the answer")
    p.add_argument("--fail-rate", type=float, default=0, help="fraction of requests that 500")
    args = p.parse_args()

    server = await asyncio.start_server(
        lambda r, w: handle(r, w, args), args.host, args.port, backlog=4096
    )
    print(
        f"fake LLM on http://{args.host}:{args.port} — {args.tokens} tokens/reply "
        f"at {args.rate:g} tok/s, ttft {args.ttft_ms:g} ms",
        flush=True,
    )
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
