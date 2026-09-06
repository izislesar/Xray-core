#!/usr/bin/env bash
set -euo pipefail

command -v bd >/dev/null || {
  echo "error: bd (Beads) is not installed" >&2
  echo "install Beads, then rerun this script" >&2
  exit 1
}
command -v jq >/dev/null || {
  echo "error: jq is required by this bootstrap script" >&2
  exit 1
}

if [[ ! -f .beads/metadata.json && ! -d .beads/embeddeddolt && ! -d .beads/dolt ]]; then
  bd init --prefix xray --quiet --skip-agents
fi

# Current M3 state reconstructed from the project handoff. The checks below
# make the bootstrap safe to rerun without creating duplicate beads.
existing() {
  bd list --status all --json 2>/dev/null | jq -r --arg title "$1" '.[] | select(.title == $title) | .id' | head -n1
}

create() {
  local title="$1"
  local description="$2"
  local type="$3"
  local priority="$4"
  local id
  id="$(existing "$title")"
  if [[ -n "$id" ]]; then
    printf '%s\n' "$id"
    return
  fi
  bd create --type "$type" --priority "$priority" "$title" --description "$description" --json | jq -r '.id'
}

epic="$(create "M3: Kernel TCP connect observation" "Complete the privileged kernel TCP connect observation milestone. M0R/M1/M2 are historical completed work; M4 flow_id <-> socket_cookie mapping is explicitly out of scope." epic 1)"
t1="$(create "M3 Task 1: event contract" "56-byte v1 event ABI, big-endian encoding, strict decoder rejection. Already implemented; preserve as completed historical state." task 1)"
t2="$(create "M3 Task 2: BPF loader" "cgroup/connect4+connect6 TCP/STREAM filter, socket cookie, ktime, pid/tgid, ringbuf, per-CPU dropped accounting, generated bindings, Linux observer implementation. Already implemented; preserve as completed historical state." task 1)"
t3="$(create "M3 Task 3: privileged hook, cookie, concurrency and loss proof" "Create observer/kernel/integration_linux_test.go: child cgroup, gated helper, move PID before connect, JSON pipe exchange of literal destination + SO_COOKIE. Cover IPv4 loopback, IPv6 loopback, concurrent IPv4 cookie-set equality, and one-page ringbuf loss accounting. Skip only on precise cgroup/BPF authority errors; otherwise fail. Do not use ordering-based matching." task 1)"
t4="$(create "M3 Task 4: documentation and verification" "Update durable kernel-observer docs/callchain/current-state and milestone state after Task 3. Run gofmt, go test ./observer/kernel, race tests, go generate + diff check, context verification and git diff --check. Do not claim flow_id <-> socket_cookie mapping; that is an M4 gate." task 1)"

bd dep add "$t1" "$epic" --type parent-child 2>/dev/null || true
bd dep add "$t2" "$epic" --type parent-child 2>/dev/null || true
bd dep add "$t3" "$epic" --type parent-child 2>/dev/null || true
bd dep add "$t4" "$epic" --type parent-child 2>/dev/null || true
bd dep add "$t3" "$t2" --type blocks 2>/dev/null || true
bd dep add "$t4" "$t3" --type blocks 2>/dev/null || true

# These two tasks are historical implementation work and were complete before
# Beads was added. Do not close them if a prior run already did so.
bd close "$t1" --reason "Implemented before Beads bootstrap; reconstructed from project handoff." 2>/dev/null || true
bd close "$t2" --reason "Implemented before Beads bootstrap; reconstructed from project handoff." 2>/dev/null || true

printf '\nBeads initialized. Ready work:\n'
bd ready
