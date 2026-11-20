#!/usr/bin/env bash
# (Re)lance picom — appelé par i3 (exec_always), donc aussi à chaque restart d'i3.
pkill -x picom
for _ in $(seq 20); do pgrep -x picom >/dev/null || break; sleep 0.1; done
exec picom --config "$HOME/.config/picom/picom.conf"
