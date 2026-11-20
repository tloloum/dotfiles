#!/usr/bin/env python3
"""Module polybar des mises à jour (custom/script, tail = true).

  au repos      : icône + nombre de mises à jour apt (recompté toutes les 30 min,
                  ou tout de suite sur clic droit : SIGUSR1)
  en cours      : barre de progression lue dans PROGRESS (écrit par system-update)
  à la fin      : notification succès/erreur, puis recompte ; si Spotify a été mis
                  à jour, le thème spicetify est réappliqué (spicetify backup apply)
"""
import os
import signal
import subprocess
import sys
import threading
import time

sys.path.insert(0, os.path.expanduser("~/.config/theme"))
from palette import C  # noqa: E402  (palette du rice)

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
PROGRESS = os.path.join(RUNTIME, "system-update.progress")
LOG = os.path.expanduser("~/.cache/system-update.log")
RECOUNT_EVERY = 30 * 60

ICON = "\U000F06B0"
DIM, WARN, ACCENT, ALERT = C["fg_dim"], C["warn"], C["accent"], C["alert"]
BAR_WIDTH = 10

recount_requested = True


def on_usr1(*_):
    global recount_requested
    recount_requested = True


def count_updates():
    out = subprocess.run(["apt", "list", "--upgradable"], capture_output=True, text=True).stdout
    return sum(1 for line in out.splitlines() if "upgradable from" in line)


def idle_label(count):
    if count:
        return f"%{{F{WARN}}}{ICON}%{{F-}} {count}"
    return f"%{{F{DIM}}}{ICON}%{{F-}}"


def progress_label(phase, percent):
    filled = round(BAR_WIDTH * percent / 100)
    bar = f"%{{F{ACCENT}}}{'━' * filled}%{{F{DIM}}}{'━' * (BAR_WIDTH - filled)}%{{F-}}"
    return f"%{{F{WARN}}}{ICON}%{{F-}} {phase} {bar} {percent:>3}%"


def notify(summary, body="", urgency="normal"):
    subprocess.run(["notify-send", "-a", "system-update", "-u", urgency, summary, body])


def reapply_spicetify():
    """Une mise à jour de Spotify efface le thème spicetify : on le réapplique."""
    spicetify = os.path.expanduser("~/.local/share/spicetify/spicetify")
    try:
        updated = "Setting up spotify-client" in open(LOG).read()
    except OSError:
        updated = False
    if not (updated and os.path.exists(spicetify)):
        return
    res = subprocess.run([spicetify, "backup", "apply"], capture_output=True, text=True)
    if res.returncode == 0:
        notify("Spotify updated", "spicetify theme re-applied")
    else:
        notify("Spotify updated", "spicetify backup apply failed — run it manually", "critical")


def read_progress():
    try:
        phase, value = open(PROGRESS).read().split()
        return phase, int(value)
    except (OSError, ValueError):
        return None


def main():
    global recount_requested
    signal.signal(signal.SIGUSR1, on_usr1)
    count, last_count_at, last_line = 0, 0.0, None
    while True:
        state = read_progress()
        if state and state[0] in ("done", "failed"):
            os.remove(PROGRESS)
            if state[0] == "done":
                notify("System up to date")
                # ~20 s (et redémarre Spotify) : en parallèle pour ne pas figer le module
                threading.Thread(target=reapply_spicetify, daemon=True).start()
            else:
                notify("System update failed", f"exit code {state[1]} — see {LOG}", "critical")
            recount_requested, state = True, None
        if state:
            line = progress_label(*state)
        else:
            if recount_requested or time.time() - last_count_at > RECOUNT_EVERY:
                count, last_count_at, recount_requested = count_updates(), time.time(), False
            line = idle_label(count)
        if line != last_line:
            print(line, flush=True)
            last_line = line
        time.sleep(0.5 if state else 2)


if __name__ == "__main__":
    main()
