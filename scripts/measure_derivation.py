#!/usr/bin/env python3
"""Measure derivation typecheck time for registered benchmarks."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bench_common import BENCHMARKS, measure_derivation, resolve_benchmarks


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "benchmarks",
        nargs="*",
        metavar="BENCHMARK",
        help=f"Benchmark ids to run (default: all). Known: {', '.join(BENCHMARKS)}",
    )
    args = parser.parse_args(argv)
    for bench in resolve_benchmarks(args.benchmarks or None):
        measure_derivation(bench)
    return 0


if __name__ == "__main__":
    sys.exit(main())
