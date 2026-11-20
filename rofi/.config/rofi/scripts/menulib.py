"""Briques communes aux menus rofi de la barre (wifi-menu, bluetooth-menu).

Thème : ~/.config/rofi/bar-menu.rasi (ancré sous les icônes réseau de polybar).
"""
import html
import subprocess

THEME = "bar-menu"
DIM = "#6e6e6e"  # = fg-dim du thème
KEY_FORGET = "Alt+d"
FORGET = 10  # code de sortie de rofi pour -kb-custom-1

ICON_KNOWN = ""  # marque-page : déjà enregistré / appairé
ICON_TRASH = "\U000F01B4"
ICON_RESCAN = "\U000F0450"
ICON_POWER = "\U000F0425"


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def esc(text):
    return html.escape(text, quote=False)


def dim(text):
    return f'<span foreground="{DIM}">{text}</span>'


def notify(summary, body="", urgency="normal", app="bar-menu"):
    subprocess.run(["notify-send", "-a", app, "-u", urgency, summary, body])


def forget_hint():
    return f'<span foreground="{DIM}" size="small">{KEY_FORGET}  forget</span>'


def rofi(rows, prompt, mesg="", active=None, password=False, header=None, theme_str=None):
    """Lance rofi. Renvoie (code, index choisi en str) ; (None, None) si Échap.

    header : ligne non sélectionnable placée en tête (absente des index renvoyés).
    theme_str : surcharge du thème propre à un menu (taille, position…).
    """
    cmd = ["rofi", "-dmenu", "-i", "-theme", THEME, "-p", prompt]
    if theme_str:
        cmd += ["-theme-str", theme_str]
    if password:
        cmd += ["-password", "-theme-str", "listview { lines: 0; }"]
    else:
        cmd += ["-markup-rows", "-no-custom", "-format", "i", "-kb-custom-1", KEY_FORGET]
    if mesg:
        cmd += ["-mesg", mesg]
    if header is not None:
        rows = [header + "\0nonselectable\x1ftrue"] + rows
        active = None if active is None else active + 1
        cmd += ["-selected-row", "1"]  # curseur sur la 1re vraie ligne, pas sur l'en-tête
    if active is not None:
        cmd += ["-a", str(active)]
    res = subprocess.run(cmd, input="\n".join(rows), capture_output=True, text=True)
    if res.returncode not in (0, FORGET):  # Échap
        return None, None
    out = res.stdout.rstrip("\n")
    if header is not None and out.isdigit():
        out = str(int(out) - 1)
    return res.returncode, out


def confirm_forget(name):
    """Demande confirmation avant d'oublier `name`. True si confirmé."""
    _, choice = rofi([f"{ICON_TRASH}  Forget", "Cancel"], ICON_TRASH,
                     header=f"Forget <b>{esc(name)}</b> ?")
    return choice == "0"
