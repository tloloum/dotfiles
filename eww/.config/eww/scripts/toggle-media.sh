#!/usr/bin/env bash
# Ouvre/ferme le popup média (clic sur l'icône de son de polybar).
if eww active-windows 2>/dev/null | grep -q '^media'; then
  eww close media
else
  eww update show_sinks=false show_sources=false 2>/dev/null
  eww open media
fi
