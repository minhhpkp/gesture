#!/usr/bin/env python3
"""
Triton Inference Server — per-request trace visualizer
Usage:
    python triton_trace_chart.py trace.json
    python triton_trace_chart.py trace.json --output chart.png
    python triton_trace_chart.py --sample          # run with generated sample data
"""

import argparse
import json
import random
import sys
import time
from collections import defaultdict

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def parse_trace(traces: list[dict]) -> dict[str, list[dict]]:
    traces_concat = {}
    for trace in traces:
        if trace["id"] not in traces_concat:
            traces_concat[trace["id"]] = {}
            traces_concat[trace["id"]]["timestamps"] = {}
        if "timestamps" in trace:
            traces_concat[trace["id"]]["timestamps"].update({ts["name"]: ts["ns"] for ts in trace["timestamps"]})
        else:
            traces_concat[trace["id"]].update(trace)

    model_stats = defaultdict(list)
    for id, trace in traces_concat.items():
        ts = trace["timestamps"]
        
        try:
            queue   = (ts["COMPUTE_START"]         - ts["QUEUE_START"])          / 1_000
            cin     = (ts["COMPUTE_INPUT_END"]     - ts["COMPUTE_START"])        / 1_000
            compute = (ts["COMPUTE_OUTPUT_START"]  - ts["COMPUTE_INPUT_END"])    / 1_000
            cout    = (ts["COMPUTE_END"]           - ts["COMPUTE_OUTPUT_START"]) / 1_000
        except KeyError as e:
            print(f"Warning: request {id} missing timestamp {e}, skipping.")
            continue
        model_stats[trace["model_name"]].append({
            "id":      id,
            "queue":   queue,
            "cin":     cin,
            "compute": compute,
            "cout":    cout,
            "total":   queue + cin + compute + cout,
        })
    
    return model_stats


# ---------------------------------------------------------------------------
# Sample data
# ---------------------------------------------------------------------------

def make_sample_traces(n: int = 16) -> list[dict]:
    random.seed(42)
    base_ns = int(time.time()) * 1_000_000_000
    traces = []
    for i in range(n):
        t0 = base_ns + i * 15_000_000
        queue   = int(300_000  + random.random() * 400_000)
        cin     = int(150_000  + random.random() * 150_000)
        compute = int(7_000_000 + random.random() * 5_000_000)
        cout    = int(200_000  + random.random() * 200_000)
        traces.append({
            "id": i + 1,
            "model_name": "resnet50",
            "model_version": "1",
            "timestamps": [
                {"name": "HTTP_RECV_START",       "ns": t0},
                {"name": "HTTP_RECV_END",         "ns": t0 + 180_000},
                {"name": "QUEUE_START",           "ns": t0 + 200_000},
                {"name": "COMPUTE_START",         "ns": t0 + 200_000 + queue},
                {"name": "COMPUTE_INPUT_END",     "ns": t0 + 200_000 + queue + cin},
                {"name": "COMPUTE_OUTPUT_START",  "ns": t0 + 200_000 + queue + cin + compute},
                {"name": "COMPUTE_END",           "ns": t0 + 200_000 + queue + cin + compute + cout},
                {"name": "HTTP_SEND_START",       "ns": t0 + 200_000 + queue + cin + compute + cout + 100_000},
                {"name": "HTTP_SEND_END",         "ns": t0 + 200_000 + queue + cin + compute + cout + 280_000},
            ],
        })
    return traces


# ---------------------------------------------------------------------------
# Plotting
# ---------------------------------------------------------------------------

PHASES = [
    ("queue",   "Queue",           "#BA7517"),
    ("cin",     "Compute input",   "#1D9E75"),
    ("compute", "Compute",         "#378ADD"),
    ("cout",    "Compute output",  "#D85A30"),
]


def smart_fmt(us: float) -> str:
    """Format a microsecond value as µs or ms depending on magnitude."""
    if us >= 1_000:
        return f"{us / 1_000:.1f} ms"
    return f"{us:.0f} µs"


def y_formatter(us, _pos):
    return smart_fmt(us)


def plot(rows: list[dict], model_name: str, output: str | None = None) -> None:
    labels  = [f"req {r['id']}" for r in rows]
    bottoms = np.zeros(len(rows))

    fig, axes = plt.subplots(
        2, 1,
        figsize=(max(10, len(rows) * 0.7), 9),
        gridspec_kw={"height_ratios": [3, 1]},
    )
    ax_bar, ax_table = axes

    # --- stacked bar chart --------------------------------------------------
    for key, label, color in PHASES:
        values = np.array([r[key] for r in rows])
        ax_bar.bar(labels, values, bottom=bottoms, label=label, color=color, width=0.6)
        bottoms += values

    ax_bar.set_ylabel("Duration", fontsize=11)
    ax_bar.yaxis.set_major_formatter(ticker.FuncFormatter(y_formatter))
    ax_bar.tick_params(axis="x", rotation=45, labelsize=9)
    ax_bar.tick_params(axis="y", labelsize=9)
    ax_bar.set_title(
        f"Triton per-request latency breakdown  ·  {model_name}  ·  {len(rows)} requests",
        fontsize=12, pad=12,
    )
    ax_bar.legend(loc="upper right", fontsize=9, framealpha=0.8)
    ax_bar.spines[["top", "right"]].set_visible(False)
    ax_bar.grid(axis="y", linestyle="--", linewidth=0.5, alpha=0.5)

    # summary line: avg total
    avg_total = np.mean([r["total"] for r in rows])
    ax_bar.axhline(avg_total, color="gray", linewidth=1, linestyle="--", alpha=0.7)
    ax_bar.text(
        len(rows) - 0.5, avg_total * 1.01,
        f"avg total: {smart_fmt(avg_total)}",
        fontsize=8, color="gray", ha="right",
    )

    # --- summary table ------------------------------------------------------
    ax_table.axis("off")
    col_labels = ["phase", "min", "avg", "max", "% of total"]
    table_data = []
    totals = np.array([r["total"] for r in rows])

    for key, label, color in PHASES:
        vals = np.array([r[key] for r in rows])
        pct  = vals.sum() / totals.sum() * 100
        table_data.append([
            label,
            smart_fmt(vals.min()),
            smart_fmt(vals.mean()),
            smart_fmt(vals.max()),
            f"{pct:.1f}%",
        ])

    tbl = ax_table.table(
        cellText=table_data,
        colLabels=col_labels,
        cellLoc="center",
        loc="center",
    )
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.scale(1, 1.5)

    # color the phase name cells to match the bars
    for row_idx, (_, _, color) in enumerate(PHASES):
        cell = tbl[row_idx + 1, 0]
        cell.set_facecolor(color)
        cell.set_text_props(color="white", fontweight="bold")

    # header row styling
    for col_idx in range(len(col_labels)):
        tbl[0, col_idx].set_facecolor("#333333")
        tbl[0, col_idx].set_text_props(color="white", fontweight="bold")

    plt.tight_layout(pad=2.0)

    if output:
        plt.savefig(output, dpi=150, bbox_inches="tight")
        print(f"Saved to {output}")
    else:
        plt.show()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Visualize Triton trace.json as a chart.")
    parser.add_argument("trace_file", nargs="?", help="Path to trace.json")
    parser.add_argument("--output", "-o", help="Save chart to file (e.g. chart.png) instead of displaying it")
    parser.add_argument("--sample", action="store_true", help="Use generated sample data instead of a file")
    args = parser.parse_args()

    if args.sample:
        traces = make_sample_traces()
    elif args.trace_file:
        with open(args.trace_file) as f:
            traces = json.load(f)
        if isinstance(traces, dict):
            traces = [traces]
    else:
        parser.print_help()
        sys.exit(1)

    model_stats = parse_trace(traces)
    if not model_stats:
        print("No valid trace entries found.")
        sys.exit(1)

    for model_name, rows in model_stats.items():
        plot(rows, model_name, output=f"{model_name}_{args.output}")


if __name__ == "__main__":
    main()