#!/usr/bin/env python3
"""Charge CPU par cœur virtuel pour le popup eww `cpu` (deflisten), façon htop.

Lit /proc/stat chaque seconde : rien n'est écrit en dur, le nombre de cœurs
(8, 16, 24…) et le modèle du processeur sont lus sur la machine.
Les cœurs sont répartis en colonnes de PER_COLUMN pour que le popup reste lisible.
"""
import json
import math
import time

PER_COLUMN = 8


def read_stat():
    """{nom: (inactif, total)} pour « cpu » (global) et chaque « cpuN »."""
    stats = {}
    with open("/proc/stat") as f:
        for line in f:
            if not line.startswith("cpu"):
                break
            name, *values = line.split()
            values = list(map(int, values))
            idle = values[3] + (values[4] if len(values) > 4 else 0)  # idle + iowait
            stats[name] = (idle, sum(values[:8]))  # sans guest (déjà compté dans user)
    return stats


def model_name():
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if line.startswith("model name"):
                    return " ".join(line.split(":", 1)[1].split())
    except OSError:
        pass
    return ""


def usage(before, after):
    idle = after[0] - before[0]
    total = after[1] - before[1]
    return round(100 * (1 - idle / total)) if total > 0 else 0


def main():
    model = model_name()
    before = read_stat()
    while True:
        time.sleep(1)
        after = read_stat()
        cores = sorted((n for n in after if n != "cpu"), key=lambda n: int(n[3:]))
        loads = [{"id": int(n[3:]), "pct": usage(before[n], after[n])} for n in cores if n in before]
        ncols = max(1, math.ceil(len(loads) / PER_COLUMN))
        per_col = math.ceil(len(loads) / ncols) if loads else 0
        print(json.dumps({
            "total": usage(before["cpu"], after["cpu"]),
            "count": len(loads),
            "model": model,
            "columns": [loads[i:i + per_col] for i in range(0, len(loads), per_col)],
        }), flush=True)
        before = after


if __name__ == "__main__":
    main()
