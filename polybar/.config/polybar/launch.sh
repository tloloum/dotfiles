#!/usr/bin/env bash
# Relance polybar (appelé par i3 via exec_always, donc aussi à chaque restart ($mod+Shift+r)).

# Arrête les instances en cours et attend qu'elles soient parties
# (délais maximaux : un polybar figé ne répond plus à polybar-msg ni à SIGTERM)
timeout 2 polybar-msg cmd quit >/dev/null 2>&1 || killall -q polybar
for _ in $(seq 25); do pgrep -u "$UID" -x polybar >/dev/null || break; sleep 0.2; done
pkill -KILL -u "$UID" -x polybar 2>/dev/null

# Capteur CPU AMD (k10temp) : l'index /sys/class/hwmon/hwmonN change d'un boot à l'autre
for d in /sys/class/hwmon/hwmon*; do
  if [ "$(cat "$d/name" 2>/dev/null)" = "k10temp" ]; then
    export POLYBAR_HWMON="$d/temp1_input"
    break
  fi
done

# Une barre par écran connecté
log="${XDG_RUNTIME_DIR:-/tmp}/polybar.log"
: >"$log"
for m in $(polybar --list-monitors | cut -d: -f1); do
  MONITOR=$m polybar --reload main >>"$log" 2>&1 &
done
disown -a
