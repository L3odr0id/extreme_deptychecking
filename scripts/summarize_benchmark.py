#!/usr/bin/env python3
"""Summarize benchmark timing results."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def metric_label(data: dict, path: Path) -> str:
    metric = data.get("metric", path.stem)
    if metric == "derivation_typecheck_seconds":
        return "derivation"
    if metric == "execution_seconds":
        return "execution"
    return str(metric)


def sorted_rows(
    results: dict[str, float],
    timed_out: set[str],
) -> list[tuple[str, float, str, str, str]]:
    fastest_name = min(results, key=results.get)
    fastest_time = results[fastest_name]
    rows: list[tuple[str, float, str, str, str]] = []
    for name in sorted(results, key=results.get):
        seconds = results[name]
        delta = seconds - fastest_time
        if name == fastest_name:
            rel = "fastest"
            delta_txt = "—"
        else:
            rel = f"+{(seconds / fastest_time - 1.0) * 100.0:.1f}%"
            delta_txt = f"+{delta:.3f}s"
        status = "TIMEOUT" if name in timed_out else "ok"
        rows.append((name, seconds, delta_txt, rel, status))
    return rows


def format_text(data: dict, path: Path) -> str:
    results: dict[str, float] = data["results"]
    timed_out = set(data.get("timed_out", []))
    rows = sorted_rows(results, timed_out)
    fastest_name, fastest_time, _, _, _ = rows[0]

    lines = [
        f"Benchmark : {data.get('benchmark', path)}",
    ]
    if "values_count" in data:
        lines.append(f"Values    : {data['values_count']}")
    if "execution_timeout_seconds" in data:
        lines.append(f"Timeout   : {data['execution_timeout_seconds']}s")
    lines.append(f"Fastest   : {fastest_name} ({fastest_time:.3f}s)")
    if timed_out:
        lines.append(f"Timed out : {', '.join(sorted(timed_out, key=results.get))}")
    lines.append("")

    name_width = max(len("Variant"), max(map(len, results), default=0))
    header = (
        f"{'Variant':<{name_width}} {'Seconds':>10} {'Delta':>10} "
        f"{'vs fastest':>14} {'Status':>8}"
    )
    lines.append(header)
    lines.append("-" * len(header))
    for name, seconds, delta_txt, rel, status in rows:
        lines.append(
            f"{name:<{name_width}} {seconds:>10.3f} {delta_txt:>10} "
            f"{rel:>14} {status:>8}"
        )
    return "\n".join(lines) + "\n"


def format_markdown(data: dict, path: Path) -> str:
    results: dict[str, float] = data["results"]
    timed_out = set(data.get("timed_out", []))
    rows = sorted_rows(results, timed_out)
    bench = data.get("benchmark", path)
    title = f"{bench} — {metric_label(data, path)}"

    lines = [
        f"### {title}",
        "",
    ]
    if "values_count" in data:
        lines.append(f"Values: `{data['values_count']}`")
        lines.append("")
    if "execution_timeout_seconds" in data:
        lines.append(f"Execution timeout: `{data['execution_timeout_seconds']}s`")
        lines.append("")
    if timed_out:
        names = ", ".join(f"`{name}`" for name in sorted(timed_out, key=results.get))
        lines.append(f"**Timed out:** {names}")
        lines.append("")
    lines.extend(
        [
            "| Variant | Seconds | Delta | vs fastest | Status |",
            "| --- | ---: | ---: | ---: | --- |",
        ]
    )
    for name, seconds, delta_txt, rel, status in rows:
        lines.append(
            f"| {name} | {seconds:.3f} | {delta_txt} | {rel} | {status} |"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <results.json>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    data = json.loads(path.read_text(encoding="utf-8"))

    text = format_text(data, path)
    print(text, end="")

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as summary:
            summary.write(format_markdown(data, path))

    return 0


if __name__ == "__main__":
    sys.exit(main())
