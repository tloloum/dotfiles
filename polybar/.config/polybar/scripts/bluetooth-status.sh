#!/usr/bin/env bash
# État Bluetooth pour le module polybar custom/bluetooth :
#   éteint → icône barrée (grisée) · allumé → icône simple · appareil connecté → icône « connect » (accent)
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  echo "%{F#3a3a3a}󰂲%{F-}"
elif bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then
  echo "%{F#e6e6e6}󰂱%{F-}"
else
  echo "󰂯"
fi
