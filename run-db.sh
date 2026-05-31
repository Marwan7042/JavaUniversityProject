#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/UniReg_Optimized_GoodGUI_Base" && pwd)"
exec bash "${project_root}/docker/run-local.sh"
