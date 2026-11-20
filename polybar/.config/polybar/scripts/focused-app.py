#!/usr/bin/env python3
"""Appli au focus pour polybar (module custom/focused, tail = true).

Écoute les événements i3 (focus, fermeture, changement de workspace) et affiche
l'icône + le nom de l'application active (sa classe X11), pas le titre de la fenêtre.
Workspace vide → rien.
"""
import json
import subprocess

ICON_DEFAULT = "󰣆"
APPS = {  # classe (minuscules) → (icône, nom affiché)
    "firefox": ("󰈹", "Firefox"),
    "alacritty": ("󰆍", "Alacritty"),
    "spotify": ("󰓇", "Spotify"),
    "nemo": ("󰉋", "Nemo"),
    "code": ("󰨞", "VS Code"),
    "thunderbird": ("󰇮", "Thunderbird"),
}


def focused_class():
    tree = json.loads(subprocess.run(["i3-msg", "-t", "get_tree"],
                                     capture_output=True, text=True).stdout or "{}")
    stack = [tree]
    while stack:
        node = stack.pop()
        if node.get("focused"):
            return (node.get("window_properties") or {}).get("class", "")
        stack += node.get("nodes", []) + node.get("floating_nodes", [])
    return ""


def label(wm_class):
    if not wm_class:
        return ""
    icon, name = APPS.get(wm_class.lower(), (ICON_DEFAULT, wm_class))
    return f"%{{F#6e6e6e}}{icon}%{{F-}}  {name}"


def main():
    last = None
    events = subprocess.Popen(["i3-msg", "-t", "subscribe", "-m", '["window","workspace"]'],
                              stdout=subprocess.PIPE, text=True)
    current = label(focused_class())
    while True:
        if current != last:
            print(current, flush=True)
            last = current
        line = events.stdout.readline()
        if not line:
            return
        try:
            change = json.loads(line).get("change")
        except json.JSONDecodeError:
            continue
        if change == "title":  # le titre change souvent (terminal…) mais pas l'appli
            continue
        current = label(focused_class())


if __name__ == "__main__":
    main()
