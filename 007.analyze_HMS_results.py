#!/usr/bin/env python3

import csv
import math
import re
import statistics
import sys
from pathlib import Path

try:
    import matplotlib.pyplot as plt
except ImportError:
    print("ERROR: matplotlib is required.")
    print("Install it in your Python environment before running this script.")
    sys.exit(1)


SCRIPT_DIR = Path(__file__).resolve().parent

RUN_DIR = SCRIPT_DIR
ANALYSIS_DIR = SCRIPT_DIR

SUMMARY_CSV = SCRIPT_DIR / "HMS_analysis_summary.csv"
ISLAND_CSV = SCRIPT_DIR / "HMS_island_statistics.csv"
MEMBER_CSV = SCRIPT_DIR / "HMS_member_statistics.csv"

RUNTIME_PLOT = SCRIPT_DIR / "HMS_runtime_vs_cutoff.png"
ISLAND_COUNT_PLOT = SCRIPT_DIR / "HMS_island_count_vs_cutoff.png"
CLUSTER_SIZE_PLOT = SCRIPT_DIR / "HMS_cluster_size_vs_cutoff.png"
SIMILARITY_PLOT = SCRIPT_DIR / "HMS_similarity_vs_cutoff.png"
CALCULATIONS_PLOT = SCRIPT_DIR / "HMS_calculations_vs_cutoff.png"



def mean_or_nan(values):
    return statistics.mean(values) if values else math.nan


def median_or_nan(values):
    return statistics.median(values) if values else math.nan


def stdev_or_nan(values):
    if len(values) < 2:
        return 0.0 if len(values) == 1 else math.nan
    return statistics.stdev(values)


def min_or_nan(values):
    return min(values) if values else math.nan


def max_or_nan(values):
    return max(values) if values else math.nan


def safe_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return math.nan


def safe_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def cutoff_label(cutoff):
    if float(cutoff).is_integer():
        return str(int(cutoff))
    return f"{cutoff:g}"


def find_output_files():

    output_files = []

    for path in sorted(SCRIPT_DIR.glob("HMS_Island_*.out")):

        if "summary" in path.name.lower():
            continue

        if path.name.startswith("HMS_slurm_"):
            continue

        output_files.append(path)

    return output_files



def parse_hms_output(output_file):
    run = {
        "source_file": str(output_file),
        "cutoff": math.nan,
        "molecules_to_cluster": 0,
        "molecules_clustered": 0,
        "total_islands": 0,
        "total_hms_calculations": 0,
        "avg_hms_calculations_per_island": math.nan,
        "elapsed_seconds": math.nan,
        "molecules_per_second": math.nan,
        "virtual_memory_kb": 0,
        "physical_memory_kb": 0,
        "islands": [],
    }

    current_island = None
    in_calculation_table = False
    island_calculations = {}

    cutoff_re = re.compile(
        r"^Similarity Cutoff:\s*([-+]?\d+(?:\.\d+)?)"
    )

    molecules_to_cluster_re = re.compile(
        r"^Molecules to Cluster:\s*(\d+)"
    )

    island_re = re.compile(
        r"^HMS ISLAND\s+(\d+)"
    )

    island_head_re = re.compile(
        r"^Island Head:\s+(\S+)"
    )

    island_size_re = re.compile(
        r"^Island Size:\s+(\d+)"
    )

    member_re = re.compile(
        r"^\s*(\d+)\s+(\S+)\s+([-+]?\d+(?:\.\d+)?)\s+(HEAD|MEMBER)\s*$"
    )

    molecules_clustered_re = re.compile(
        r"^Molecules Clustered:\s*(\d+)"
    )

    total_islands_re = re.compile(
        r"^Total Islands:\s*(\d+)"
    )

    total_calculations_re = re.compile(
        r"^Total HMS Calculations:\s*(\d+)"
    )

    avg_calculations_re = re.compile(
        r"^Average HMS Calculations per Island:\s*([-+]?\d+(?:\.\d+)?)"
    )

    calculation_table_re = re.compile(
        r"^\s*(\d+)\s+(\d+)\s+(\d+)\s*$"
    )

    elapsed_re = re.compile(
        r"^Total elapsed time:\s*([-+]?\d+(?:\.\d+)?)\s+seconds"
    )

    rate_re = re.compile(
        r"^Number of molecules per second:\s*([-+]?\d+(?:\.\d+)?)"
    )

    virtual_memory_re = re.compile(
        r"^Virtual memory used for this process:\s*(\d+)\s+kilobytes"
    )

    physical_memory_re = re.compile(
        r"^Physical memory used for this process:\s*(\d+)\s+kilobytes"
    )

    with output_file.open("r", errors="replace") as handle:
        for raw_line in handle:
            line = raw_line.strip()

            match = cutoff_re.match(line)
            if match:
                run["cutoff"] = float(match.group(1))
                continue

            match = molecules_to_cluster_re.match(line)
            if match:
                run["molecules_to_cluster"] = int(match.group(1))
                continue

            match = island_re.match(line)
            if match:
                current_island = {
                    "island_id": int(match.group(1)),
                    "head": "",
                    "size": 0,
                    "hms_calculations": 0,
                    "members": [],
                }
                run["islands"].append(current_island)
                in_calculation_table = False
                continue

            if current_island is not None:
                match = island_head_re.match(line)
                if match:
                    current_island["head"] = match.group(1)
                    continue

                match = island_size_re.match(line)
                if match:
                    current_island["size"] = int(match.group(1))
                    continue

                match = member_re.match(line)
                if match:
                    rank = int(match.group(1))
                    molecule = match.group(2)
                    hms = float(match.group(3))
                    role = match.group(4)

                    if role == "MEMBER":
                        current_island["members"].append(
                            {
                                "rank": rank,
                                "molecule": molecule,
                                "hms": hms,
                            }
                        )

                    continue

            if line.startswith("Similarity Island clustering complete"):
                current_island = None
                continue

            match = molecules_clustered_re.match(line)
            if match:
                run["molecules_clustered"] = int(match.group(1))
                continue

            match = total_islands_re.match(line)
            if match:
                run["total_islands"] = int(match.group(1))
                continue

            match = total_calculations_re.match(line)
            if match:
                run["total_hms_calculations"] = int(match.group(1))
                continue

            match = avg_calculations_re.match(line)
            if match:
                run["avg_hms_calculations_per_island"] = float(
                    match.group(1)
                )
                continue

            if line == "Similarity Island Calculations by HMS:":
                in_calculation_table = True
                continue

            if in_calculation_table:
                if line.startswith("Island"):
                    continue

                match = calculation_table_re.match(line)

                if match:
                    island_id = int(match.group(1))
                    calculations = int(match.group(2))
                    molecules = int(match.group(3))

                    island_calculations[island_id] = {
                        "calculations": calculations,
                        "molecules": molecules,
                    }
                    continue

                if line.startswith("Rescoring"):
                    in_calculation_table = False

            match = elapsed_re.match(line)
            if match:
                run["elapsed_seconds"] = float(match.group(1))
                continue

            match = rate_re.match(line)
            if match:
                run["molecules_per_second"] = float(match.group(1))
                continue

            match = virtual_memory_re.match(line)
            if match:
                run["virtual_memory_kb"] = int(match.group(1))
                continue

            match = physical_memory_re.match(line)
            if match:
                run["physical_memory_kb"] = int(match.group(1))
                continue

    for island in run["islands"]:
        info = island_calculations.get(island["island_id"])

        if info:
            island["hms_calculations"] = info["calculations"]

            if island["size"] == 0:
                island["size"] = info["molecules"]

    if run["total_islands"] == 0:
        run["total_islands"] = len(run["islands"])

    if run["molecules_clustered"] == 0:
        run["molecules_clustered"] = run["molecules_to_cluster"]

    return run


def calculate_statistics(run):
    island_sizes = [
        island["size"]
        for island in run["islands"]
        if island["size"] > 0
    ]

    member_scores = []

    for island in run["islands"]:
        member_scores.extend(
            member["hms"]
            for member in island["members"]
        )

    run["largest_island"] = max(island_sizes) if island_sizes else 0
    run["smallest_island"] = min(island_sizes) if island_sizes else 0

    run["mean_island_size"] = mean_or_nan(island_sizes)
    run["median_island_size"] = median_or_nan(island_sizes)
    run["std_island_size"] = stdev_or_nan(island_sizes)

    run["singleton_islands"] = sum(
        1 for size in island_sizes if size == 1
    )

    run["mean_member_hms"] = mean_or_nan(member_scores)
    run["median_member_hms"] = median_or_nan(member_scores)
    run["std_member_hms"] = stdev_or_nan(member_scores)
    run["min_member_hms"] = min_or_nan(member_scores)
    run["max_member_hms"] = max_or_nan(member_scores)

    run["member_hms_count"] = len(member_scores)

    for island in run["islands"]:
        scores = [
            member["hms"]
            for member in island["members"]
        ]

        island["member_count"] = len(scores)
        island["mean_hms"] = mean_or_nan(scores)
        island["median_hms"] = median_or_nan(scores)
        island["std_hms"] = stdev_or_nan(scores)
        island["min_hms"] = min_or_nan(scores)
        island["max_hms"] = max_or_nan(scores)


def write_summary_csv(runs):
    fields = [
        "cutoff",
        "molecules_clustered",
        "total_islands",
        "largest_island",
        "smallest_island",
        "mean_island_size",
        "median_island_size",
        "std_island_size",
        "singleton_islands",
        "total_hms_calculations",
        "avg_hms_calculations_per_island",
        "member_hms_count",
        "mean_member_hms",
        "median_member_hms",
        "std_member_hms",
        "min_member_hms",
        "max_member_hms",
        "elapsed_seconds",
        "molecules_per_second",
        "virtual_memory_kb",
        "physical_memory_kb",
        "source_file",
    ]

    with SUMMARY_CSV.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()

        for run in runs:
            writer.writerow(
                {
                    field: run.get(field, "")
                    for field in fields
                }
            )


def write_island_csv(runs):
    fields = [
        "cutoff",
        "island_id",
        "island_head",
        "island_size",
        "hms_calculations",
        "member_count",
        "mean_hms",
        "median_hms",
        "std_hms",
        "min_hms",
        "max_hms",
        "source_file",
    ]

    with ISLAND_CSV.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()

        for run in runs:
            for island in run["islands"]:
                writer.writerow(
                    {
                        "cutoff": run["cutoff"],
                        "island_id": island["island_id"],
                        "island_head": island["head"],
                        "island_size": island["size"],
                        "hms_calculations": island["hms_calculations"],
                        "member_count": island["member_count"],
                        "mean_hms": island["mean_hms"],
                        "median_hms": island["median_hms"],
                        "std_hms": island["std_hms"],
                        "min_hms": island["min_hms"],
                        "max_hms": island["max_hms"],
                        "source_file": run["source_file"],
                    }
                )


def write_member_csv(runs):
    fields = [
        "cutoff",
        "island_id",
        "island_head",
        "island_size",
        "rank",
        "molecule",
        "hms",
    ]

    with MEMBER_CSV.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()

        for run in runs:
            for island in run["islands"]:
                for member in island["members"]:
                    writer.writerow(
                        {
                            "cutoff": run["cutoff"],
                            "island_id": island["island_id"],
                            "island_head": island["head"],
                            "island_size": island["size"],
                            "rank": member["rank"],
                            "molecule": member["molecule"],
                            "hms": member["hms"],
                        }
                    )


def plot_runtime(runs):
    x = [run["cutoff"] for run in runs]
    y = [run["elapsed_seconds"] for run in runs]

    valid = [
        (cutoff, runtime)
        for cutoff, runtime in zip(x, y)
        if not math.isnan(runtime)
    ]

    if not valid:
        print("Skipping runtime plot: no elapsed times found.")
        return

    x, y = zip(*valid)

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.plot(x, y, marker="o")
    ax.set_xlabel("HMS cutoff")
    ax.set_ylabel("Elapsed time (seconds)")
    ax.set_title("HMS Similarity Island Runtime vs Cutoff")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(RUNTIME_PLOT, dpi=300)
    plt.close(fig)


def plot_island_count(runs):
    x = [run["cutoff"] for run in runs]
    y = [run["total_islands"] for run in runs]

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.plot(x, y, marker="o")
    ax.set_xlabel("HMS cutoff")
    ax.set_ylabel("Number of islands")
    ax.set_title("Number of HMS Similarity Islands vs Cutoff")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(ISLAND_COUNT_PLOT, dpi=300)
    plt.close(fig)


def plot_cluster_sizes(runs):
    fig, ax = plt.subplots(figsize=(9, 6))

    for run in runs:
        cutoff = run["cutoff"]

        sizes = [
            island["size"]
            for island in run["islands"]
            if island["size"] > 0
        ]

        if not sizes:
            continue

        ax.scatter(
            [cutoff] * len(sizes),
            sizes,
            alpha=0.55,
            s=28,
        )

    x = [run["cutoff"] for run in runs]

    mean_sizes = [
        run["mean_island_size"]
        for run in runs
    ]

    median_sizes = [
        run["median_island_size"]
        for run in runs
    ]

    largest_sizes = [
        run["largest_island"]
        for run in runs
    ]

    ax.plot(
        x,
        mean_sizes,
        marker="o",
        linewidth=2,
        label="Mean island size",
    )

    ax.plot(
        x,
        median_sizes,
        marker="s",
        linewidth=2,
        label="Median island size",
    )

    ax.plot(
        x,
        largest_sizes,
        marker="^",
        linewidth=2,
        label="Largest island",
    )

    ax.set_xlabel("HMS cutoff")
    ax.set_ylabel("Molecules per island")
    ax.set_title("HMS Similarity Island Size vs Cutoff")
    ax.set_yscale("log")
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(CLUSTER_SIZE_PLOT, dpi=300)
    plt.close(fig)


def plot_similarity(runs):
    fig, ax = plt.subplots(figsize=(9, 6))

    for run in runs:
        cutoff = run["cutoff"]

        island_means = [
            island["mean_hms"]
            for island in run["islands"]
            if not math.isnan(island["mean_hms"])
        ]

        if not island_means:
            continue

        ax.scatter(
            [cutoff] * len(island_means),
            island_means,
            alpha=0.55,
            s=28,
        )

    x = [run["cutoff"] for run in runs]

    overall_mean = [
        run["mean_member_hms"]
        for run in runs
    ]

    overall_median = [
        run["median_member_hms"]
        for run in runs
    ]

    ax.plot(
        x,
        overall_mean,
        marker="o",
        linewidth=2,
        label="Mean member HMS",
    )

    ax.plot(
        x,
        overall_median,
        marker="s",
        linewidth=2,
        label="Median member HMS",
    )

    ax.set_xlabel("HMS cutoff")
    ax.set_ylabel("HMS score")
    ax.set_title("Within-Island HMS Similarity vs Cutoff")
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(SIMILARITY_PLOT, dpi=300)
    plt.close(fig)


def plot_calculations(runs):
    x = [run["cutoff"] for run in runs]
    y = [run["total_hms_calculations"] for run in runs]

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.plot(x, y, marker="o")
    ax.set_xlabel("HMS cutoff")
    ax.set_ylabel("Total HMS calculations")
    ax.set_title("HMS Pairwise Calculations vs Cutoff")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(CALCULATIONS_PLOT, dpi=300)
    plt.close(fig)


def print_summary(runs):
    print()
    print("HMS Similarity Island Analysis")
    print()

    header = (
        f"{'Cutoff':>10} "
        f"{'Molecules':>10} "
        f"{'Islands':>9} "
        f"{'Largest':>9} "
        f"{'MeanSize':>10} "
        f"{'MeanHMS':>10} "
        f"{'HMSCalcs':>12} "
        f"{'Time(s)':>10}"
    )

    print(header)

    for run in runs:
        mean_size = run["mean_island_size"]
        mean_hms = run["mean_member_hms"]
        elapsed = run["elapsed_seconds"]

        print(
            f"{cutoff_label(run['cutoff']):>10} "
            f"{run['molecules_clustered']:>10d} "
            f"{run['total_islands']:>9d} "
            f"{run['largest_island']:>9d} "
            f"{mean_size:>10.2f} "
            f"{mean_hms:>10.4f} "
            f"{run['total_hms_calculations']:>12d} "
            f"{elapsed:>10.3f}"
        )

    print()
    print("Analysis files:")
    print(f"  {SUMMARY_CSV}")
    print(f"  {ISLAND_CSV}")
    print(f"  {MEMBER_CSV}")
    print()
    print("Plots:")
    print(f"  {RUNTIME_PLOT}")
    print(f"  {ISLAND_COUNT_PLOT}")
    print(f"  {CLUSTER_SIZE_PLOT}")
    print(f"  {SIMILARITY_PLOT}")
    print(f"  {CALCULATIONS_PLOT}")
    print()


def main():
    ANALYSIS_DIR.mkdir(parents=True, exist_ok=True)

    output_files = find_output_files()

    if not output_files:
        print("ERROR: No HMS output files were found under:")
        print(RUN_DIR)
        sys.exit(1)

    print()
    print(f"Found {len(output_files)} HMS output file(s).")
    print()

    runs = []

    for output_file in output_files:
        print(f"Parsing: {output_file}")

        run = parse_hms_output(output_file)

        if math.isnan(run["cutoff"]):
            print("WARNING: Could not determine cutoff. Skipping.")
            continue

        if not run["islands"]:
            print(
                "WARNING: No completed HMS islands were found. "
                "Skipping."
            )
            continue

        calculate_statistics(run)
        runs.append(run)

    if not runs:
        print("ERROR: No completed HMS calculations could be analyzed.")
        sys.exit(1)

    runs.sort(key=lambda run: run["cutoff"])

    write_summary_csv(runs)
    write_island_csv(runs)
    write_member_csv(runs)

    plot_runtime(runs)
    plot_island_count(runs)
    plot_cluster_sizes(runs)
    plot_similarity(runs)
    plot_calculations(runs)

    print_summary(runs)


if __name__ == "__main__":
    main()
