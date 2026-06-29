#!/usr/bin/env bash
# ~/.config/i3/lock.sh
# Ecran de verrouillage i3lock-color, palette Ganbaru blue.
# Utilise par le raccourci i3 ET par xss-lock (d'ou --nofork, indispensable
# pour que xss-lock sache quand l'ecran est deverrouille).
#
# Format des couleurs : RRGGBBAA (les 2 derniers caracteres = transparence,
# ff = opaque, 00 = transparent). PAS de '#'.

# --- Palette Ganbaru ---
BG='151b23ff'        # fond de l'ecran
INSIDE='293039cc'    # interieur du cercle (legerement transparent)
RING='505860ff'      # anneau au repos (gris)
VERIF='7cd5f1ff'     # anneau pendant la verification (cyan)
WRONG='ff6d7eff'     # anneau si mauvais mot de passe (rouge)
TEXT='d0dbdeff'      # texte (heure, date, messages)
KEYHL='f3ace2ff'     # surbrillance a chaque touche (rose)
BSHL='ffb270ff'      # surbrillance backspace (orange)
TRANSPARENT='00000000'

IMG="$HOME/Documents/img/wallpaper/big_tree.png"

i3lock \
  --nofork \
  --ignore-empty-password \
  --color="$BG" \
  --clock \
  --indicator \
  --radius=120 \
  --ring-width=10 \
  --inside-color="$INSIDE" \
  --ring-color="$RING" \
  --insidever-color="$INSIDE" \
  --ringver-color="$VERIF" \
  --insidewrong-color="$INSIDE" \
  --ringwrong-color="$WRONG" \
  --line-color="$TRANSPARENT" \
  --separator-color="$TRANSPARENT" \
  --keyhl-color="$KEYHL" \
  --bshl-color="$BSHL" \
  --verif-color="$TEXT" \
  --wrong-color="$WRONG" \
  --time-color="$TEXT" \
  --date-color="$TEXT" \
  --layout-color="$TEXT" \
  --time-str="%H:%M" \
  --date-str="%A %d %B" \
  --verif-text="Verification..." \
  --wrong-text="Mauvais mot de passe" \
  --noinput-text="" \
  --lock-text="Verrouillage..." \
  --lockfailed-text="Echec du verrouillage" \
  --pass-media-keys \
  --pass-volume-keys \
  --image="$IMG" \
  --fill \

# --- Options a decommenter selon tes envies ---
# Ajouter \ a la fin de la derniere ligne active avant de decommenter :
#
#   --blur=5                     # floute le contenu de l'ecran en fond
#   --time-font="FantasqueSansM Nerd Font" \
#   --date-font="FantasqueSansM Nerd Font" \
#   --verif-font="FantasqueSansM Nerd Font" \
#   --wrong-font="FantasqueSansM Nerd Font"
# (les options --time-size / --date-size existent selon la version d'i3lock-color)
