#!/usr/bin/env bash
set -euo pipefail

exec npx -y -p @mermaid-js/mermaid-cli mmdc "$@"
