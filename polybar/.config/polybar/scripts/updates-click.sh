#!/usr/bin/env bash
# Clic sur le module polybar des mises à jour :
#   mise à jour en cours → ouvre le journal dans un terminal flottant
#   sinon                → demande le mot de passe (polkit) et lance la mise à jour
progress="${XDG_RUNTIME_DIR:-/tmp}/system-update.progress"
log="$HOME/.cache/system-update.log"

if [ -f "$progress" ]; then
  exec alacritty --class update-float --title "System update" -e tail -n 200 -f "$log"
fi
mkdir -p "$(dirname "$log")"
# PAS de « exec » : pkexec refuse de tourner si son parent est mort (« Refusing to
# render service to dead parents ») — or polybar lance ce script en arrière-plan.
# Ce shell reste donc en vie comme parent de pkexec jusqu'à la fin.
pkexec "$HOME/.config/polybar/scripts/system-update" "$progress" "$log"
code=$?
# 126/127 : mot de passe annulé / refusé → on n'affiche rien de plus
[ "$code" -eq 126 ] || [ "$code" -eq 127 ] && exit 0
exit "$code"
