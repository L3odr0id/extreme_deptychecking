#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}/scripts"

BENCHMARKS=("$@")
if [[ ${#BENCHMARKS[@]} -eq 0 ]]; then
  BENCHMARKS=(00_safe_select 01_second_fuel 02_helper_type 03_constructive_predicate)
fi

status=0
for bench in "${BENCHMARKS[@]}"; do
  echo "==> Derivation: ${bench}"
  python3 measure_derivation.py "${bench}"
  python3 summarize_benchmark.py \
    "${ROOT_DIR}/results/${bench}_derivation.json"

  echo "==> Execution: ${bench}"
  exec_rc=0
  python3 measure_execution.py "${bench}" || exec_rc=$?
  # Always summarize so TIMEOUT rows are visible even when execution fails.
  if [[ -f "${ROOT_DIR}/results/${bench}_execution.json" ]]; then
    python3 summarize_benchmark.py \
      "${ROOT_DIR}/results/${bench}_execution.json"
  fi
  if [[ "${exec_rc}" -ne 0 ]]; then
    status="${exec_rc}"
  fi
done
exit "${status}"
