#!/usr/bin/env bash
# Ouvre/ferme le popup CPU par cœur (clic sur la stat CPU de polybar).
if eww active-windows 2>/dev/null | grep -q '^cpu'; then
  eww close cpu
else
  eww open cpu
fi
