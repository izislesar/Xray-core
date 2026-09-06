#!/usr/bin/env bash
set -euo pipefail

command -v bd >/dev/null || {
  echo "error: bd (Beads) is not installed" >&2
  echo "install Beads, then rerun this script" >&2
  exit 1
}

if [[ ! -f .beads/metadata.json && ! -d .beads/embeddeddolt && ! -d .beads/dolt ]]; then
  bd init --prefix xray --quiet
fi

# Read-only bootstrap is intentional: do not invent or duplicate existing work.
# Current M3 state reconstructed from the project handoff.

epic="$(bd create --type epic --priority 1 "M3: Kernel TCP connect observation" --description "Complete the privileged kernel TCP connect observation milestone. M0R/M1/M2 are historical completed work; M4 flow_id <-> socket_cookie mapping is explicitly out of scope." --json | jq -r '.id')"

t1="$(bd create --type task --priority 1 "M3 Task 1: event contract" --description "56-byte v1 event ABI, big-endian encoding, strict decoder rejection. Already implemented; preserve as completed historical state." --json | jq -r '.id')"
t2="$(bd create --type task --priority 1 "M3 Task 2: BPF loader" --description "cgroup/connect4+connect6 TCP/STREAM filter, socket cookie, ktime, pid/tgid, ringbuf, per-CPU dropped accounting, generated bindings, Linux observer implementation. Already implemented; preserve as completed historical state." --json | jq -r '.id')"
t3="$(bd create --type task --priority 1 "M3 Task 3: privileged hook, cookie, concurrency and loss proof" --description "Create observer/kernel/integration_linux_test.go: child cgroup, gated helper, move PID before connect, JSON pipe exchange of literal destination + SO_COOKIE. Cover IPv4 loopback, IPv6 loopback, concurrent IPv4 cookie-set equality, and one-page ringbuf loss accounting. Skip only on precise cgroup/BPF authority errors; otherwise fail. Do not use ordering-based matching." --json | jq -r '.id')"
t4="$(bd create --type task --priority 1 "M3 Task 4: documentation and verification" --description "Update durable kernel-observer docs/callchain/current-state and milestone state after Task 3. Run gofmt, go test ./observer/kernel, race tests, go generate + diff check, context verification and git diff --check. Do not claim flow_id <-> socket_cookie mapping; that is an M4 gate." --json | jq -r '.id')"

bd dep add "$t1" "$epic" --type parent-child || true
bd dep add "$t2" "$epic" --type parent-child || true
bd dep add "$t3" "$epic" --type parent-child || true
bd dep add "$t4" "$epic" --type parent-child || true
bd dep add "$t3" "$t2" --type blocks || true
bd dep add "$t4" "$t3" --type blocks || true

bd close "$t1" --reason "Implemented before Beads bootstrap; reconstructed from project handoff."
bd close "$t2" --reason "Implemented before Beads bootstrap; reconstructed from project handoff."

printf '\nBeads initialized. Ready work:\n'
bd ready
