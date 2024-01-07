#!/bin/bash
set -euo pipefail

(cd dst && python3 -m http.server "$@")
