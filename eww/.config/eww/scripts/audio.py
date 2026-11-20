#!/usr/bin/env python3
"""Son pour eww : sortie/micro par défaut, volume, mute, appareils disponibles.

  audio.py                 flux JSON (deflisten `audio`), mis à jour via `pactl subscribe`
  audio.py set-sink NAME   change la sortie par défaut et y déplace les sons en cours
  audio.py set-source NAME change le micro par défaut et y déplace les enregistrements
"""
import json
import subprocess
import sys


def pactl(*args):
    return subprocess.run(["pactl", *args], capture_output=True, text=True).stdout


def pactl_json(*args):
    try:
        return json.loads(pactl("-f", "json", *args) or "[]")
    except json.JSONDecodeError:
        return []


def pretty(desc, kind):
    """Noms courts pour les cartes son intégrées (« Family 17h/19h HD Audio Controller… »)."""
    if "HD Audio" in desc or "Built-in" in desc:
        return "Built-in speakers" if kind == "sink" else "Built-in mic"
    return desc


def volume_of(dev):
    vols = [int(v["value_percent"].rstrip("%")) for v in dev.get("volume", {}).values()]
    return round(sum(vols) / len(vols)) if vols else 0


def devices(kind):
    """(liste des appareils, appareil par défaut) pour kind = 'sink' ou 'source'."""
    default = pactl(f"get-default-{kind}").strip()
    items = []
    for dev in pactl_json("list", f"{kind}s"):
        if kind == "source" and dev.get("properties", {}).get("device.class") == "monitor":
            continue  # « Monitor of … » : pas un vrai micro
        items.append({"name": dev["name"], "desc": pretty(dev.get("description", dev["name"]), kind),
                      "default": dev["name"] == default, "muted": dev.get("mute", False),
                      "volume": volume_of(dev)})
    current = next((d for d in items if d["default"]), None)
    return items, current


def state():
    sinks, sink = devices("sink")
    sources, source = devices("source")
    return {
        "volume": sink["volume"] if sink else 0,
        "muted": sink["muted"] if sink else True,
        "sink": sink["desc"] if sink else "No output",
        "sinks": sinks,
        "source": source["desc"] if source else "No mic",
        "mic_muted": source["muted"] if source else True,
        "sources": sources,
    }


def listen():
    last = None
    proc = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True)
    lines = iter(proc.stdout)
    while True:
        current = json.dumps(state())
        if current != last:
            print(current, flush=True)
            last = current
        line = next(lines, None)
        if line is None:
            return
        while not any(k in line for k in ("sink", "source", "server")):
            line = next(lines, None)
            if line is None:
                return


def move_to(kind, name):
    pactl(f"set-default-{kind}", name)
    streams = "sink-inputs" if kind == "sink" else "source-outputs"
    move = "move-sink-input" if kind == "sink" else "move-source-output"
    for stream in pactl_json("list", streams):
        pactl(move, str(stream["index"]), name)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] in ("set-sink", "set-source"):
        move_to(sys.argv[1].split("-")[1], sys.argv[2])
    else:
        listen()
