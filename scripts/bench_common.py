"""Shared helpers and benchmark definitions for derivation/execution measurements."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
RESULTS_DIR = ROOT_DIR / "results"
EXECUTION_TIMEOUT_SECONDS = 2 * 60

IPKG_TEMPLATE = """\
package {package_name}
version = 0.1.0

depends = common
        , deptycheck

modules = {modules}

sourcedir = "../src"
builddir = "../build"
"""


@dataclass(frozen=True)
class Benchmark:
    id: str
    package_dir: str
    ipkg: str
    executable: str
    core_module: str
    # Display name -> Derived submodule prefix (e.g. "BoolPred" -> BoolPred.Derived)
    derivation_variants: dict[str, str]
    # Display name -> CLI --mode value
    execution_modes: dict[str, str]

    @property
    def dir(self) -> Path:
        return ROOT_DIR / self.package_dir

    @property
    def bench_tmp_dir(self) -> Path:
        return self.dir / "bench"

    @property
    def executable_path(self) -> Path:
        return self.dir / "build" / "exec" / self.executable

    def results_path(self, metric: str) -> Path:
        return RESULTS_DIR / f"{self.id}_{metric}.json"


BENCHMARKS: dict[str, Benchmark] = {
    "00_safe_select": Benchmark(
        id="00_safe_select",
        package_dir="00_safe_select",
        ipkg="safe_select.ipkg",
        executable="safe_select",
        core_module="SafeSelect",
        derivation_variants={
            "BoolPred": "BoolPred",
            "SimpleDepTyPred": "SimpleDepTyPred",
            "CompValues": "CompValues",
            "FuncPred": "FuncPred",
            "DepTyPred": "DepTyPred",
        },
        execution_modes={
            "BoolPred": "boolpred",
            "SimpleDepTyPred": "simpledeptypred",
            "CompValues": "compvalues",
            "FuncPred": "funcpred",
            "DepTyPred": "deptypred",
        },
    ),
    "01_second_fuel": Benchmark(
        id="01_second_fuel",
        package_dir="01_second_fuel",
        ipkg="second_fuel.ipkg",
        executable="second_fuel",
        core_module="SecondFuel",
        derivation_variants={
            "ConsumersListFin": "ConsumersListFin",
            "ConsumersListFNat": "ConsumersListFNat",
        },
        execution_modes={
            "ConsumersListFin": "consumerslistfin",
            "ConsumersListFNat": "ConsumersListFNat",
        },
    ),
    "02_helper_type": Benchmark(
        id="02_helper_type",
        package_dir="02_helper_type",
        ipkg="02_helper_type.ipkg",
        executable="helper_type",
        core_module="HelperType",
        derivation_variants={
            "Naive": "Naive",
            "Helper": "Helper",
        },
        execution_modes={
            "Naive": "naive",
            "Helper": "helper",
        },
    ),
    "03_constructive_predicate": Benchmark(
        id="03_constructive_predicate",
        package_dir="03_constructive_predicate",
        ipkg="constructive_predicate.ipkg",
        executable="constructive_predicate",
        core_module="ConstructivePredicate",
        derivation_variants={
            "DepTyPred": "DepTyPred",
            "FuncPred": "FuncPred",
            "FilteredFins": "FilteredFins",
            "ConstructiveDepTyPred": "ConstructiveDepTyPred",
        },
        execution_modes={
            "DepTyPred": "deptypred",
            "FuncPred": "funcpred",
            "FilteredFins": "filteredfins",
            "ConstructiveDepTyPred": "constructivedeptypred",
        },
    ),
}


def log(message: str) -> None:
    print(f"[measure] {message}", flush=True)


def camel_to_snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def render_ipkg(package_name: str, modules: list[str]) -> str:
    if not modules:
        raise ValueError("modules must be non-empty")
    modules_block = modules[0]
    for module in modules[1:]:
        modules_block += f"\n        , {module}"
    return IPKG_TEMPLATE.format(package_name=package_name, modules=modules_block)


def write_ipkg(path: Path, package_name: str, modules: list[str]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_ipkg(package_name, modules), encoding="utf-8")
    return path


def run_pack(bench: Benchmark, args: list[str]) -> None:
    completed = subprocess.run(["pack", *args], cwd=bench.dir, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)


def write_results(path: Path, payload: dict) -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    log(f"Wrote {path}")
    print(path)


def resolve_benchmarks(names: list[str] | None) -> list[Benchmark]:
    if not names:
        return list(BENCHMARKS.values())
    selected: list[Benchmark] = []
    for name in names:
        bench = BENCHMARKS.get(name)
        if bench is None:
            known = ", ".join(BENCHMARKS)
            print(f"error: unknown benchmark `{name}`. Expected one of: {known}", file=sys.stderr)
            raise SystemExit(2)
        selected.append(bench)
    return selected


def measure_derivation(bench: Benchmark) -> Path:
    generated: list[Path] = []
    output = bench.results_path("derivation")

    try:
        log(f"[{bench.id}] Removing build folder")
        shutil.rmtree(bench.dir / "build", ignore_errors=True)

        log(f"[{bench.id}] Installing dependencies")
        run_pack(bench, ["install-deps", bench.ipkg])

        baseline_ipkg = write_ipkg(
            bench.bench_tmp_dir / "core_only.ipkg",
            "core_only",
            [bench.core_module],
        )
        generated.append(baseline_ipkg)
        log(f"[{bench.id}] Building {bench.core_module} without derivation (not timed)")
        run_pack(bench, ["--log-level=warning", "typecheck", "bench/core_only.ipkg"])

        results: dict[str, float] = {}
        for variant, generator in bench.derivation_variants.items():
            package_name = f"{camel_to_snake(variant)}_bench"
            ipkg = write_ipkg(
                bench.bench_tmp_dir / f"{package_name}.ipkg",
                package_name,
                [bench.core_module, f"{generator}.Derived"],
            )
            generated.append(ipkg)
            rel = ipkg.relative_to(bench.dir).as_posix()
            log(f"[{bench.id}] Timing derivation for {variant} ({rel})")

            started = time.perf_counter()
            completed = subprocess.run(
                ["pack", "--log-level=warning", "typecheck", rel],
                cwd=bench.dir,
                check=False,
            )
            elapsed = time.perf_counter() - started
            if completed.returncode != 0:
                print(f"error: pack typecheck failed for {rel}", file=sys.stderr)
                raise SystemExit(completed.returncode)

            results[variant] = elapsed
            log(f"[{bench.id}] {variant}: {elapsed:.6f}s")

        write_results(
            output,
            {
                "benchmark": bench.id,
                "metric": "derivation_typecheck_seconds",
                "timestamp_utc": datetime.now(timezone.utc).isoformat(),
                "results": results,
            },
        )
        return output
    finally:
        for path in generated:
            path.unlink(missing_ok=True)
        if bench.bench_tmp_dir.exists() and not any(bench.bench_tmp_dir.iterdir()):
            bench.bench_tmp_dir.rmdir()


def measure_execution(bench: Benchmark, values_count: int = 10) -> Path:
    output = bench.results_path("execution")

    log(f"[{bench.id}] Building {bench.ipkg}")
    run_pack(bench, ["--log-level=warning", "build", bench.ipkg])

    if not bench.executable_path.is_file():
        print(f"error: executable not found: {bench.executable_path}", file=sys.stderr)
        raise SystemExit(1)

    results: dict[str, float] = {}
    timed_out: list[str] = []
    for variant, mode in bench.execution_modes.items():
        log(
            f"[{bench.id}] Timing execution for {variant} (--mode {mode}, "
            f"timeout {EXECUTION_TIMEOUT_SECONDS}s)"
        )
        started = time.perf_counter()
        try:
            completed = subprocess.run(
                [
                    str(bench.executable_path),
                    "--mode",
                    mode,
                    "--values-count",
                    str(values_count),
                ],
                cwd=bench.dir,
                stdout=subprocess.DEVNULL,
                check=False,
                timeout=EXECUTION_TIMEOUT_SECONDS,
            )
        except subprocess.TimeoutExpired:
            elapsed = float(EXECUTION_TIMEOUT_SECONDS)
            results[variant] = elapsed
            timed_out.append(variant)
            log(
                f"[{bench.id}] {variant}: TIMEOUT after {EXECUTION_TIMEOUT_SECONDS}s "
                f"(recorded as {elapsed:.6f}s)"
            )
            continue

        elapsed = time.perf_counter() - started
        if completed.returncode != 0:
            print(
                f"error: {bench.executable} failed for --mode {mode}",
                file=sys.stderr,
            )
            raise SystemExit(completed.returncode)

        results[variant] = elapsed
        log(f"[{bench.id}] {variant}: {elapsed:.6f}s")

    write_results(
        output,
        {
            "benchmark": bench.id,
            "metric": "execution_seconds",
            "values_count": values_count,
            "execution_timeout_seconds": EXECUTION_TIMEOUT_SECONDS,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "results": results,
            "timed_out": timed_out,
        },
    )
    if timed_out:
        # Timeouts are expected for some variants; record them and continue.
        log(f"[{bench.id}] execution timed out for: {', '.join(timed_out)}")
    return output
