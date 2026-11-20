#!/usr/bin/env python3
"""Génère le logo fastfetch : un trou noir (façon Interstellar) en caractères ▀ colorés.

  blackhole.py [COLONNES]      écrit ~/.config/fastfetch/blackhole.ans (défaut : 40 colonnes)

Rendu procédural (numpy) : ombre noire, anneau de photons, disque d'accrétion qui
traverse l'ombre, halo du disque arrière courbé au-dessus/en dessous, côté gauche plus
lumineux (effet Doppler). Chaque caractère ▀ porte 2 pixels (couleur du texte en haut,
du fond en bas) en couleurs 24 bits ; le noir reste transparent (fond du terminal).
Couleurs tirées de la palette du rice (~/.config/theme/colors.json) : appelé par apply.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.expanduser("~/.config/theme"))
from palette import C  # noqa: E402

COLS = int(sys.argv[1]) if len(sys.argv) > 1 else 40
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "blackhole.ans")
SS = 4  # suréchantillonnage (anticrénelage)


def hex_rgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=float)


def render(w, h):
    """Luminosité 0..1 du trou noir sur une grille w×h (pixels carrés)."""
    y, x = np.mgrid[0:h, 0:w].astype(float)
    zoom = 0.68  # < 1 : trou noir plus grand dans le cadre (le disque déborde sur les côtés)
    x = ((x + 0.5) / w * 2 - 1) * zoom
    y = ((y + 0.5) / h * 2 - 1) * h / w * zoom
    r = np.hypot(x, y)
    shadow = 0.30

    # halo : disque arrière vu « par-dessus » et « par-dessous » l'ombre (lentille gravitationnelle),
    # fin, plus marqué au-dessus qu'en dessous
    up = np.clip(-y / np.maximum(r, 1e-6), -1, 1)
    halo = np.exp(-((r - 0.345) / 0.045) ** 2) * (0.62 + 0.38 * up)
    halo += 0.18 * np.exp(-((r - 0.42) / 0.06) ** 2) * (0.5 + 0.5 * up)
    # anneau de photons : fin et très brillant au bord de l'ombre
    ring = 0.9 * np.exp(-((r - 0.31) / 0.011) ** 2)
    # disque d'accrétion presque de profil, légèrement incliné, plus brillant à gauche (Doppler)
    tilt = y - 0.05 * x
    band = np.exp(-(tilt / 0.065) ** 2)
    radial = np.clip(1.25 - np.abs(x) ** 1.3, 0, 1)
    doppler = 1 + 0.4 * (-x)
    disk = band * radial * doppler
    # stries discrètes le long du disque
    disk *= 0.93 + 0.07 * np.sin(x * 40 + tilt * 6)

    lum = np.maximum.reduce([halo, ring * 1.1, disk * 1.05])
    behind = (r < shadow) & (np.abs(tilt) > 0.07)  # l'ombre masque tout sauf le disque avant
    lum[behind] = 0
    lum[r > 1.0] = 0
    return np.clip(lum, 0, 1.2)


def colorize(lum):
    """0 → noir, puis warn (extérieur) → accent → presque blanc (cœur)."""
    warn, accent = hex_rgb(C["warn"]), hex_rgb(C["accent"])
    hot = np.array([255.0, 248, 236])
    dark = warn * 0.18
    l = lum[..., None]
    c = np.where(l < 0.35, dark + (warn - dark) * (l / 0.35),
         np.where(l < 0.8, warn + (accent - warn) * ((l - 0.35) / 0.45),
                  accent + (hot - accent) * np.clip((l - 0.8) / 0.4, 0, 1)))
    return np.clip(c * np.clip(l * 3, 0, 1), 0, 255)


def to_ansi(rgb):
    rows = []
    for top, bottom in zip(rgb[0::2], rgb[1::2]):
        line = []
        for t, b in zip(top, bottom):
            t_on, b_on = t.max() > 14, b.max() > 14
            if not t_on and not b_on:
                line.append("\x1b[0m ")
            elif t_on and not b_on:
                line.append("\x1b[0m\x1b[38;2;%d;%d;%dm▀" % tuple(t))
            elif b_on and not t_on:
                line.append("\x1b[0m\x1b[38;2;%d;%d;%dm▄" % tuple(b))
            else:
                line.append("\x1b[38;2;%d;%d;%dm\x1b[48;2;%d;%d;%dm▀" % (*t, *b))
        rows.append("".join(line) + "\x1b[0m")
    return "\n".join(rows) + "\n"


def main():
    w, h = COLS, COLS  # carré : COLS pixels de large → COLS/2 lignes de texte
    lum = render(w * SS, h * SS).reshape(h, SS, w, SS).mean(axis=(1, 3))
    rgb = colorize(lum).astype(int)
    # retire les lignes vides en haut et en bas (par paires : 1 ligne de texte = 2 pixels)
    lit = np.where(rgb.max(axis=(1, 2)) > 14)[0]
    top, bottom = lit[0] // 2 * 2, (lit[-1] // 2 + 1) * 2
    rgb = rgb[top:bottom]
    with open(OUT, "w") as f:
        f.write(to_ansi(rgb))
    print("  ", OUT, f"({COLS}×{len(rgb) // 2} caractères)")


if __name__ == "__main__":
    main()
