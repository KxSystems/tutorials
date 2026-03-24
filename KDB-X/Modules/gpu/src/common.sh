#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob 

: "${QEXEC:?Error: QEXEC not set. Probably skipped sourcing config/kdbenv}"

function die () {
  local msg="$1"
  local code="${2:-1}"
  echo "ERROR: $msg" >&2
  return "$code" 2>/dev/null || exit "$code"
}

if [[ $# -lt 1 ]]; then
  die "ERROR: Missing required argument - data directory" 1
fi

readonly DATADIR="$1"
readonly CSVDIR=$DATADIR/raw
readonly DST=$DATADIR/tq

if [[ $(uname) == "Linux" ]]; then
    SOCKETNR=$(lscpu | grep "Socket(s)" | cut -d":" -f 2 |xargs)
    COREPERSOCKET=$(lscpu | grep "Core(s) per socket" | cut -d":" -f 2 |xargs)
    THREADPERCORE=$(lscpu | grep "Thread(s) per core" | cut -d":" -f 2 |xargs)
else
    SOCKETNR=1
    COREPERSOCKET=$(sysctl -n hw.ncpu)
    THREADPERCORE=1
fi
COMPUTECOUNT=$((COREPERSOCKET * SOCKETNR * THREADPERCORE))
