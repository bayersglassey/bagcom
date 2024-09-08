#!/bin/bash
set -euo pipefail

cfile="$1"
binfile="$2"
chans="$3"
shift 3

echo "
#define PROG (`cat -`)
#define CHANS $chans

`cat bb/template.c`" >"$cfile"

gcc "$cfile" -o "$binfile"
