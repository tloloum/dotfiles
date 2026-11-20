"""Palette du rice pour les scripts Python (lit ~/.config/theme/colors.json).

    import sys, os; sys.path.insert(0, os.path.expanduser("~/.config/theme"))
    from palette import C          # C["fg_dim"], C["accent"]…
"""
import json
import os

_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), "colors.json")
C = {k: v for k, v in json.load(open(_PATH)).items() if not k.startswith("_")}
