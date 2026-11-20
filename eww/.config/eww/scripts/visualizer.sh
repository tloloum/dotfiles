#!/usr/bin/env bash
# Visualiseur pour eww (deflisten `bars`) : cava en sortie brute, niveaux 0-7 → ▁▂▃▄▅▆▇█
# eww arrête ce script quand le popup est fermé (cava ne tourne donc qu'à l'affichage).
exec cava -p "$HOME/.config/eww/cava.conf" 2>/dev/null \
  | sed -u 's/;//g; y/01234567/▁▂▃▄▅▆▇█/'
