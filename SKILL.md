# box.hopbox.dev — Platform Skill

**boxd: compute boxes over SSH.** `ssh box@box.hopbox.dev` drops you into a real
Linux **microVM** (Firecracker — hardware-isolated, a full kernel, not a
container) in about a second. **Your SSH key is your identity** — no signup, no
account, no cloud console. You are `root` inside the box.

This page teaches an AI agent (or a human) how to use it. It is plain text on
purpose: `curl -fsSL https://box.hopbox.dev/SKILL.md`.

## Quick start

```bash
ssh myproject@box.hopbox.dev                       # spawn an Ubuntu microVM, drop into a shell
ssh myproject:debian-12@box.hopbox.dev             # pick the Debian image instead
ssh images@box.hopbox.dev                          # list available images (spawns no box)
ssh myproject@box.hopbox.dev "python3 file.py"     # run a one-off command, capture stdout
scp ./app.py myproject@box.hopbox.dev:             # copy a file in (sftp / rsync work too)
```

Boxes are **ephemeral**: reaped a couple of minutes after you disconnect.
Reconnect within that window (same name + key) to land back in the same box, or
use `box-guest keep-alive` to pin it. The images come tooled — `git`, `vim`,
`nano`, `curl`, `wget`, `tmux`, `htop`, `python3` are already there.

## SSH username grammar

The username **is** the request, parsed left-to-right:

```
name[:image][+duration]
```

| Segment      | Default        | Meaning                                                        |
|--------------|----------------|----------------------------------------------------------------|
| `name`       | —              | Your box name. Per-owner: your `app` is private to your key.   |
| `:image`     | `ubuntu-22.04` | Image to boot. `ssh images@box.hopbox.dev` lists them.         |
| `+duration`  | ~2m            | Stay-alive grace after you disconnect, Go-style (`+30m`, `+1h`).|

Modifiers / specials:
- A bare trailing `+` on the name forces a **fresh** box: `ssh app+@box.hopbox.dev`.
- `ssh images@box.hopbox.dev` lists images and spawns no box.

```bash
ssh app@box.hopbox.dev               # ubuntu box named "app"
ssh app:debian-12@box.hopbox.dev     # debian-12 box
ssh app+30m@box.hopbox.dev           # keep it alive 30 min after disconnect
ssh app+@box.hopbox.dev              # discard any existing "app", start fresh
```

## Identity & ownership

Your SSH **public key is your identity** — there is no login step. Box names are
scoped to your key: your `myproject` is a different box from anyone else's
`myproject`. To act as a different identity, connect with a different key
(`ssh -i ~/.ssh/other_key …`).

## Available images

| Image          | Notes                                  |
|----------------|----------------------------------------|
| `ubuntu-22.04` | Ubuntu 22.04 (default), dev-tooled      |
| `debian-12`    | Debian 12, dev-tooled                   |

`ssh images@box.hopbox.dev` always returns the current list. Self-hosters add
their own with `build/microvm/build-deboot.sh` — see the docs.

## From inside the box: `box-guest`

Every box ships a `box-guest` CLI so the box can inspect and tune its **own**
lifecycle (it talks to the control plane over the box's metadata IP):

```bash
box-guest info                       # this box's metadata: image, ip, idle timeout, load, ...
box-guest time                       # the control plane's wall clock
box-guest keep-alive [DURATION]      # pin the box alive (no reap/suspend) for DURATION (default 5m)
box-guest auto-suspend on|off|status # toggle / show auto-suspend
box-guest idle [DURATION]            # set the idle timeout (empty = back to default)
box-guest mcp                        # run an MCP server (stdio) exposing the above as tools
```

Durations are Go-style: `30s`, `5m`, `1h30m`.

## For AI agents: the MCP server

`box-guest mcp` runs a **Model Context Protocol** server over stdio, exposing the
box's lifecycle as tools — `box_info`, `box_keep_alive`, `box_auto_suspend`,
`box_set_idle`. Point your MCP client at it and an agent running **inside** the
box can manage its own sandbox: e.g. `box_keep_alive("1h")` before a long build
so the box isn't reaped mid-task, or `box_info` to check how idle it is.

```jsonc
// example MCP client entry (the box-guest binary is on $PATH inside every box)
{ "command": "box-guest", "args": ["mcp"] }
```

## Persistence

box.hopbox.dev boxes are **ephemeral** — reaped a couple of minutes after you
disconnect; nothing survives between sessions there. Keep the same box by
reconnecting within the grace window, extending it (`ssh name+1h@…` or
`box-guest keep-alive 1h`), or streaming artifacts out before you leave.

A **persistent tier** exists in boxd — boxes auto-suspend to disk when idle and
wake instantly from a snapshot on reconnect, with a durable disk that survives
restarts and host reboots. It is enabled on self-hosted deployments (and for
registered keys), not on the public box.hopbox.dev demo.

## File transfer

`scp`, `sftp`, and `rsync` work — paths are relative to the box home:

```bash
scp -r ./src myproject@box.hopbox.dev:src     # copy a tree in
scp myproject@box.hopbox.dev:out.tgz .        # copy results out
sftp myproject@box.hopbox.dev                 # interactive
rsync -az ./ myproject@box.hopbox.dev:proj/   # sync
```

## What a box gives you

- A real Firecracker **microVM** — a full Linux kernel, hardware isolation. Run
  Docker, nested workloads, and kernel modules that containers can't.
- **Root** in the box, a clean home, internet egress (the box can reach the
  public internet; a default egress firewall blocks the host's other services).
- Sub-second boot; SSH-native (interactive shells, one-off `exec`, scp/sftp/rsync).

## Run your own

boxd is **open-source** and self-hostable — one daemon + Firecracker on a host
with KVM:

```bash
curl -fsSL https://box.hopbox.dev/install.sh | sudo sh
```

- Docs: https://docs.hopbox.dev
- Source: https://github.com/hopboxdev/hopbox
- The broader self-hosted dev-environment platform built on boxd: https://hopbox.dev
