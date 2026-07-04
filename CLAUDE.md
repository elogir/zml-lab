ZML-Lab is a desktop control panel for launching and babysitting machine-learning inference jobs that run on a small fleet of remote machines. It's built for an ML engineer who starts and watches these jobs all day and wants one calm, organized place to do it — a focused working tool, not a metrics dashboard.

The setup: a couple of remote GPU machines (one NVIDIA box, one AMD box) that inference servers run on, plus a set of saved launch configurations the engineer reuses.

The app centers on a few things:

A jobs dashboard — the home view. A dense, scannable list of jobs (mostly the ones currently running), each showing its name, which machine it's on, what program it's running, its port, and a status indicator. Color is used sparingly and only to signal status (running, starting, failed, exited). A prominent "New job" action sits above the list.

Starting a job — two paths: pick one of the saved configs, or build a custom one from scratch. Building a custom job walks through choosing the machine, entering the command to run (with an optional working directory), a port that comes pre-filled with a free one, custom environment variables, and a name and description. It can be launched immediately, saved as a reusable config, or both. Picking a saved config drops you into the same form pre-filled so you can tweak before launching.

Job detail — clicking a job opens a view dominated by live terminal output from the command running on that machine. The terminal behaves like a multiplexer (tmux/cmux-style): you can split panes horizontally and vertically and keep multiple tabs per pane. Alongside it is a collapsible list of actions for that job — kill the process, restart, run a profiler, copy the launch command, test the endpoint. The header shows the job's name, machine, program, and port.

A benchmark/test mode (available on running jobs) — sends batches of requests to the server to measure throughput. A grid shows each request streaming its response with a live tokens-per-second reading; you set the batch size to test different concurrency levels, watch aggregate throughput, and can cancel a run. Any request can be focused and expanded to fullscreen, where you can also send a request manually and watch the response.

A machines view — lists the available remote hosts and lets you add a new one (name, address, port, optional user and SSH key, optional hardware details).

Aesthetic and tone: a clean, flat, utilitarian developer tool that works in light and dark. Generous whitespace, restrained color reserved for status only, and monospace type for anything machine-ish — machine names, ports, repository paths, commands, and log output. The whole thing lives inside a desktop window. Minimal and a little utilitarian: every element earns its place, no filler, no decorative charts.
