#!/usr/bin/env bash
# Déplie/replie le tiroir des stats système de polybar (clic sur module/drawer).
# Liste à garder en phase avec modules-right et les « hidden = true » de config.ini.
for m in filesystem sep-drawer memory sep-drawer2 cpu sep-drawer3 temperature; do
  polybar-msg action "$m" module_toggle >/dev/null
done
polybar-msg action drawer next >/dev/null   # change le sens de la flèche
