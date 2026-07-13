#!/usr/bin/env bash
#
# install.sh — déploie cette configuration sur une machine Debian/Ubuntu vierge.
#
# Layout : dépôt « GNU Stow ». Chaque dossier de premier niveau (nvim, zsh, i3…)
# contient une arborescence qui reflète $HOME et est liée symboliquement via stow.
#
# Usage :
#   ./install.sh              # installation complète
#   ./install.sh --no-apt     # saute l'installation des paquets système
#   ./install.sh --restow     # se contente de (re)faire les liens stow
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# ── options ────────────────────────────────────────────────────────────────
DO_APT=1
RESTOW_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-apt)  DO_APT=0 ;;
    --restow)  RESTOW_ONLY=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }

# ── paquets système (apt) ────────────────────────────────────────────────────
APT_PACKAGES=(
  # base
  git stow curl zsh
  # éditeurs / gestionnaires de fichiers
  neovim vim ranger
  # environnement graphique i3
  i3 i3status i3lock picom feh network-manager-gnome
  pulseaudio-utils brightnessctl suckless-tools
  # terminal & fetch
  alacritty neofetch
  # outils CLI référencés par la config (fzf, bat, fd, eza, tree)
  fzf bat fd-find tree eza
  # ranger a besoin de python3
  python3
)

install_apt() {
  if ! command -v apt-get >/dev/null; then
    warn "apt-get introuvable : distribution non Debian/Ubuntu. Installe les paquets à la main : ${APT_PACKAGES[*]}"
    return
  fi
  log "Mise à jour des dépôts apt…"
  sudo apt-get update -qq

  log "Installation des paquets…"
  # On installe paquet par paquet : 'eza' n'existe pas sur les vieilles distros,
  # inutile de faire échouer tout le lot pour un absent.
  for pkg in "${APT_PACKAGES[@]}"; do
    if ! sudo apt-get install -y -qq "$pkg" 2>/dev/null; then
      warn "Paquet indisponible dans apt : $pkg (à installer manuellement)"
    fi
  done

  # Sur Debian, fd → fdfind et bat → batcat. La config prévoit un fallback pour
  # fd, mais on crée les liens dans ~/.local/bin pour retrouver les noms courts.
  mkdir -p "$HOME/.local/bin"
  [ -e /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
  [ -e /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
}

# ── oh-my-zsh + powerlevel10k + plugins ──────────────────────────────────────
install_zsh_stack() {
  local ZSH_DIR="$HOME/.oh-my-zsh"
  if [ ! -d "$ZSH_DIR" ]; then
    log "Installation de oh-my-zsh…"
    RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "oh-my-zsh déjà présent."
  fi

  local CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
  clone_if_absent() {  # $1 = url, $2 = dossier cible
    if [ ! -d "$2" ]; then
      log "Clonage $(basename "$2")…"
      git clone --depth=1 "$1" "$2"
    fi
  }
  clone_if_absent https://github.com/romkatv/powerlevel10k.git            "$CUSTOM/themes/powerlevel10k"
  clone_if_absent https://github.com/zsh-users/zsh-autosuggestions.git    "$CUSTOM/plugins/zsh-autosuggestions"
  clone_if_absent https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
}

# ── réglages nécessaires au fonctionnement de la config zsh ───────────────────
setup_zsh_env() {
  # La config zsh vit dans ~/.config/zsh et s'appuie sur $ZDOTDIR. zsh ne lit
  # ZDOTDIR que depuis ~/.zshenv (ou /etc/zsh/zshenv) : on le pose ici.
  local ZSHENV="$HOME/.zshenv"
  local LINE='export ZDOTDIR="$HOME/.config/zsh"'
  if ! { [ -f "$ZSHENV" ] && grep -qF 'ZDOTDIR' "$ZSHENV"; }; then
    log "Configuration de ZDOTDIR dans ~/.zshenv"
    printf '%s\n' "$LINE" >> "$ZSHENV"
  fi

  # Dossier de l'historique (HISTFILE=~/.local/state/zsh/history).
  mkdir -p "$HOME/.local/state/zsh"

  # zsh comme shell par défaut.
  if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    log "Passage de zsh en shell par défaut (chsh)…"
    chsh -s "$(command -v zsh)" || warn "chsh a échoué — change de shell manuellement."
  fi
}

# ── sous-modules git (thème alacritty) ───────────────────────────────────────
init_submodules() {
  log "Initialisation des sous-modules git…"
  git -C "$DOTFILES" submodule update --init --recursive
}

# ── liens symboliques via stow ───────────────────────────────────────────────
# On liste explicitement les paquets : on exclut 'wallpaper' (asset brut, pas
# une arbo $HOME) et les fichiers de notes à la racine.
STOW_PACKAGES=(
  alacritty autostart chrome i3 i3status neofetch nvim ranger vim xdg zsh
)

run_stow() {
  if ! command -v stow >/dev/null; then
    warn "stow n'est pas installé — impossible de créer les liens."; return 1
  fi
  log "Création des liens symboliques (stow) vers $HOME…"
  for pkg in "${STOW_PACKAGES[@]}"; do
    [ -d "$DOTFILES/$pkg" ] || { warn "paquet absent : $pkg"; continue; }
    # --restow nettoie les liens obsolètes ; --no-folding pour du lien fichier à
    # fichier (évite d'adopter tout un ~/.config/xxx existant par erreur).
    if stow -v --restow --target="$HOME" "$pkg" 2>&1 | sed 's/^/    /'; then
      :
    else
      warn "Conflit stow sur '$pkg'. Sauvegarde/supprime le fichier existant puis relance : stow --restow -t \$HOME $pkg"
    fi
  done
}

# ── wallpaper : rien à stow, on rappelle juste où il est ─────────────────────
notice_wallpaper() {
  log "Fond d'écran disponible : $DOTFILES/wallpaper/foret.jpg"
  echo "    (i3 charge ~/.fehbg au démarrage ; règle-le avec : feh --bg-scale '$DOTFILES/wallpaper/foret.jpg')"
}

# ── déroulé ──────────────────────────────────────────────────────────────────
if [ "$RESTOW_ONLY" -eq 1 ]; then
  run_stow
  exit 0
fi

[ "$DO_APT" -eq 1 ] && install_apt
init_submodules
install_zsh_stack
setup_zsh_env
run_stow
notice_wallpaper

log "Terminé. Ouvre un nouveau terminal (ou 'exec zsh') pour charger la config."
warn "Note Firefox : le profil chrome/ pointe vers 'nwp6ml0j.default-release'. Renomme le dossier lié pour correspondre à ton nouveau profil si besoin."
