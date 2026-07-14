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
  # base / build
  git stow curl unzip zsh software-properties-common build-essential
  # éditeurs / gestionnaires de fichiers
  neovim vim ranger
  # environnement graphique i3
  i3 i3status i3lock picom feh network-manager-gnome
  pulseaudio-utils brightnessctl suckless-tools
  # terminal & fetch
  alacritty neofetch fontconfig
  # outils CLI référencés par la config (fzf, bat, fd, eza, tree, ripgrep)
  fzf bat fd-find tree eza ripgrep
  # runtime nvim : python3 (ranger), node/npm (copilot + serveurs LSP Mason),
  #                cargo (pour compiler le CLI tree-sitter, cf. install_nvim_toolchain)
  python3 nodejs npm cargo
)

install_apt() {
  if ! command -v apt-get >/dev/null; then
    warn "apt-get introuvable : distribution non Debian/Ubuntu. Installe les paquets à la main : ${APT_PACKAGES[*]}"
    return
  fi

  log "Mise à jour des dépôts apt…"
  sudo apt-get update -qq

  # Le neovim des dépôts Debian/Ubuntu/Mint est souvent trop vieux (0.9.x) pour
  # la config (nvim-tree, tree-sitter-manager… exigent nvim >= 0.10), et le git
  # des dépôts (2.43) est trop vieux pour `git --no-advice` (utilisé par
  # tree-sitter-manager.nvim pour cloner les parsers, dispo depuis git 2.46).
  # On passe par les PPA officiels pour avoir des versions récentes des deux.
  command -v add-apt-repository >/dev/null || sudo apt-get install -y -qq software-properties-common
  if command -v add-apt-repository >/dev/null; then
    local need_update=0
    if ! grep -rq "neovim-ppa/unstable" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
      log "Ajout du PPA neovim-ppa/unstable (nvim récent)…"
      sudo add-apt-repository -y ppa:neovim-ppa/unstable \
        && need_update=1 \
        || warn "Impossible d'ajouter le PPA neovim — nvim risque d'être trop ancien."
    fi
    if ! grep -rq "git-core/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
      log "Ajout du PPA git-core/ppa (git récent)…"
      sudo add-apt-repository -y ppa:git-core/ppa \
        && need_update=1 \
        || warn "Impossible d'ajouter le PPA git-core — git risque d'être trop ancien."
    fi
    [ "$need_update" -eq 1 ] && sudo apt-get update -qq
  else
    warn "add-apt-repository absent (paquet software-properties-common) — nvim/git viendront des dépôts par défaut, potentiellement trop anciens."
  fi

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

# ── polices (Maple Mono NF pour alacritty, MesloLGS NF pour powerlevel10k) ────
# Elles ne sont pas versionnées : on récupère la dernière release GitHub.
install_fonts() {
  local FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  # $1 = repo GitHub, $2 = regex de l'asset .zip, $3 = sous-dossier cible
  _install_font_zip() {
    local repo="$1" pat="$2" dest="$FONT_DIR/$3"
    if [ -d "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
      log "Police déjà présente : $3"; return
    fi
    local url
    url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
          | grep -oE '"browser_download_url": *"[^"]*"' \
          | sed 's/.*: *"//; s/"$//' \
          | grep -iE "$pat" | head -1)
    if [ -z "$url" ]; then
      warn "Police introuvable dans la dernière release de $repo (motif: $pat) — à installer à la main."
      return
    fi
    log "Téléchargement police $3 depuis $repo…"
    local tmp; tmp=$(mktemp -d)
    if curl -fsSL "$url" -o "$tmp/font.zip" && mkdir -p "$dest" && unzip -qo "$tmp/font.zip" -d "$dest"; then
      :
    else
      warn "Échec installation police $3."
    fi
    rm -rf "$tmp"
  }

  # Maple Mono NF : police principale d'alacritty (obligatoire).
  _install_font_zip subframe7536/maple-font 'MapleMono-?NF\.zip' MapleMono
  # MesloLGS NF : police recommandée par powerlevel10k (icônes du prompt).
  _install_font_zip ryanoasis/nerd-fonts 'Meslo\.zip' Meslo

  log "Rafraîchissement du cache de polices…"
  fc-cache -f >/dev/null 2>&1 || true
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

# ── toolchain treesitter pour nvim ───────────────────────────────────────────
# La config nvim utilise tree-sitter-manager.nvim, qui shell-out vers le CLI
# `tree-sitter build` (sous-commande ≥ 0.22). Le paquet apt est figé en 0.20.8 :
# on installe le CLI récent via cargo. Le plugin utilise aussi `git --no-advice`
# (git ≥ 2.44).  Cf. note mémoire nvim-treesitter-toolchain.
install_nvim_toolchain() {
  # 1. git ≥ 2.44 — sur Ubuntu, le PPA git-core fournit une version récente.
  local git_major git_minor
  git_major=$(git --version | grep -oE '[0-9]+' | sed -n 1p)
  git_minor=$(git --version | grep -oE '[0-9]+' | sed -n 2p)
  if [ "$git_major" -lt 2 ] || { [ "$git_major" -eq 2 ] && [ "$git_minor" -lt 44 ]; }; then
    if command -v add-apt-repository >/dev/null 2>&1 || sudo apt-get install -y -qq software-properties-common 2>/dev/null; then
      log "git $git_major.$git_minor trop ancien (< 2.44) → ajout ppa:git-core/ppa…"
      sudo add-apt-repository -y ppa:git-core/ppa && sudo apt-get update -qq && sudo apt-get install -y -qq git \
        || warn "Échec upgrade git via PPA — mets git ≥ 2.44 à la main."
    else
      warn "git $git_major.$git_minor < 2.44 : treesitter cassera. Mets git à jour manuellement."
    fi
  fi

  # 2. CLI tree-sitter ≥ 0.22 via cargo (installe dans ~/.cargo/bin).
  if command -v cargo >/dev/null 2>&1; then
    if ! "$HOME/.cargo/bin/tree-sitter" --version >/dev/null 2>&1 && ! command -v tree-sitter >/dev/null 2>&1; then
      log "Installation du CLI tree-sitter via cargo (peut prendre quelques minutes)…"
      cargo install tree-sitter-cli || warn "cargo install tree-sitter-cli a échoué."
    else
      log "CLI tree-sitter déjà présent."
    fi
  else
    warn "cargo absent : impossible d'installer le CLI tree-sitter récent (treesitter cassera)."
  fi
}

# ── réglages nécessaires au fonctionnement de la config zsh ───────────────────
setup_zsh_env() {
  # La config zsh vit dans ~/.config/zsh et s'appuie sur $ZDOTDIR. zsh ne lit
  # ZDOTDIR que depuis ~/.zshenv (ou /etc/zsh/zshenv) : on le pose ici. On y
  # ajoute aussi ~/.cargo/bin au PATH (pour trouver le CLI tree-sitter récent).
  local ZSHENV="$HOME/.zshenv"
  touch "$ZSHENV"
  grep -qF 'ZDOTDIR' "$ZSHENV"   || { log "ZDOTDIR → ~/.zshenv"; printf '%s\n' 'export ZDOTDIR="$HOME/.config/zsh"' >> "$ZSHENV"; }
  grep -qF '.cargo/bin' "$ZSHENV" || printf '%s\n' 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$ZSHENV"

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
  alacritty autostart chrome i3 i3status neofetch nvim ranger script vim xdg zsh
)

run_stow() {
  if ! command -v stow >/dev/null; then
    warn "stow n'est pas installé — impossible de créer les liens."; return 1
  fi
  log "Création des liens symboliques (stow) vers $HOME…"
  for pkg in "${STOW_PACKAGES[@]}"; do
    [ -d "$DOTFILES/$pkg" ] || { warn "paquet absent : $pkg"; continue; }
    # --ignore : ne jamais lier d'éventuels .claude (artefacts Claude Code) qui
    # traîneraient dans un arbre de travail non propre.
    if stow -v --restow --ignore='\.claude' --target="$HOME" "$pkg" 2>&1 | sed 's/^/    /'; then
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

if [ "$DO_APT" -eq 1 ]; then
  install_apt
  install_fonts
fi
init_submodules
install_zsh_stack
install_nvim_toolchain
setup_zsh_env
run_stow
notice_wallpaper

log "Terminé. Ouvre un nouveau terminal (ou 'exec zsh') pour charger la config."
echo
warn "nvim / treesitter : au premier lancement, installe les gros parsers UN PAR UN"
warn "  (:TSInstall cpp puis :TSInstall vim) — l'install groupée peut OOM sur < 8 Gio RAM."
warn "Firefox : le profil chrome/ pointe vers 'nwp6ml0j.default-release' ; renomme le"
warn "  dossier lié pour correspondre à ton nouveau profil."
warn "Polices : configure le terminal sur 'Maple Mono NF' si les icônes manquent."
