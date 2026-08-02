#!/usr/bin/env python3
"""Build and measure generator execution time for registered benchmarks."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bench_common import BENCHMARKS, measure_execution, resolve_benchmarks


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "benchmarks",
        nargs="*",
        metavar="BENCHMARK",
        help=f"Benchmark ids to run (default: all). Known: {', '.join(BENCHMARKS)}",
    )
    parser.add_argument(
        "-n",
        "--values-count",
        type=int,
        default=10,
        help="Values to generate per mode (default: 10).",
    )
    args = parser.parse_args(argv)
    for bench in resolve_benchmarks(args.benchmarks or None):
        measure_execution(bench, values_count=args.values_count)
    return 0


if __name__ == "__main__":
    sys.exit(main())
