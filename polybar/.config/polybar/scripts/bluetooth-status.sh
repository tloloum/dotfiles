#!/usr/bin/env bash
# État Bluetooth pour le module polybar custom/bluetooth :
#   éteint → icône barrée (grisée) · allumé → icône simple · appareil connecté → icône « connect » (accent)
. "$HOME/.config/theme/colors.sh"  # palette du rice

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  echo "%{F$THEME_BORDER}󰂲%{F-}"
elif bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then
  echo "%{F$THEME_ACCENT}󰂱%{F-}"
else
  echo "󰂯"
fi
