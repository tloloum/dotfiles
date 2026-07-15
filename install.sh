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
  # (le paquet alacritty est gardé pour son .desktop/ses icônes, mais
  # install_alacritty_from_source() compile une version plus récente par-dessus
  # — voir le commentaire de cette fonction)
  alacritty neofetch fontconfig
  cmake pkg-config libfreetype-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev
  # outils CLI référencés par la config (fzf, bat, fd, eza, tree, ripgrep)
  fzf bat fd-find tree eza ripgrep
  # runtime nvim : python3 (ranger, LSP), node/npm (copilot + serveurs LSP Mason)
  python3 python3-pip python3-venv nodejs npm
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

# ── terminfo alacritty ────────────────────────────────────────────────────────
# alacritty.toml force TERM=alacritty, mais le paquet apt "alacritty" ne fournit
# pas l'entrée terminfo correspondante sur Debian/Ubuntu/Mint : sans elle, zsh
# (ZLE) et toute appli basée sur terminfo ne savent plus effacer/repositionner
# le curseur (texte qui se dédouble en se redessinant, Ctrl+L cassé, etc.).
install_alacritty_terminfo() {
  if infocmp alacritty >/dev/null 2>&1; then
    log "Terminfo alacritty déjà installée."
    return
  fi
  log "Installation de la terminfo alacritty…"
  local tmp; tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/alacritty.info" \
      https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info; then
    mkdir -p "$HOME/.terminfo"
    tic -xe alacritty,alacritty-direct -o "$HOME/.terminfo" "$tmp/alacritty.info" \
      || warn "Échec de compilation de la terminfo alacritty (tic)."
  else
    warn "Téléchargement de la terminfo alacritty échoué — installe-la à la main."
  fi
  rm -rf "$tmp"
}

# ── alacritty compilé depuis les sources ─────────────────────────────────────
# Le paquet apt "alacritty" traîne souvent plusieurs versions de retard et gère
# mal le protocole clavier étendu (CSI u / Kitty keyboard protocol) : dans nvim,
# Return finit par être interprété comme deux retours à la ligne d'un coup.
# On compile la dernière release depuis les sources et on la place dans
# ~/.local/bin (prioritaire dans le PATH), le paquet apt restant en place pour
# son .desktop/ses icônes.
install_alacritty_from_source() {
  if ! command -v cargo >/dev/null 2>&1; then
    log "Installation de rustup (requis pour compiler alacritty)…"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
      || { warn "Échec installation rustup — alacritty restera en version apt."; return; }
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi

  local SRC_DIR="$HOME/.local/src/alacritty"
  mkdir -p "$(dirname "$SRC_DIR")"
  if [ -d "$SRC_DIR" ]; then
    log "Mise à jour des sources alacritty…"
    git -C "$SRC_DIR" fetch --tags -q
  else
    log "Clonage d'alacritty…"
    git clone -q https://github.com/alacritty/alacritty.git "$SRC_DIR" \
      || { warn "Échec clonage alacritty — version apt conservée."; return; }
  fi

  local latest_tag
  latest_tag=$(git -C "$SRC_DIR" describe --tags "$(git -C "$SRC_DIR" rev-list --tags --max-count=1)")
  git -C "$SRC_DIR" checkout -q "$latest_tag"

  log "Compilation d'alacritty $latest_tag (peut prendre quelques minutes)…"
  mkdir -p "$HOME/.local/bin"
  if (cd "$SRC_DIR" && cargo build --release --no-default-features --features x11); then
    cp "$SRC_DIR/target/release/alacritty" "$HOME/.local/bin/alacritty"
    log "alacritty $latest_tag installé dans ~/.local/bin (devant le paquet apt dans le PATH)."
  else
    warn "Échec de compilation d'alacritty — le paquet apt reste utilisé."
  fi
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
# on récupère le binaire précompilé de la dernière release GitHub plutôt que de
# compiler via cargo (rustc de l'apt "cargo" est trop vieux, et même en passant
# par rustup, une dépendance annexe de tree-sitter-cli — rquickjs-sys — casse
# sur le bindgen/clang de cette distro : autant éviter toute la toolchain Rust).
# Le plugin utilise aussi `git --no-advice` (git ≥ 2.44).
install_nvim_toolchain() {
  # git ≥ 2.44 — sur Ubuntu, le PPA git-core fournit une version récente.
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

  # CLI tree-sitter ≥ 0.22 : binaire précompilé dans ~/.local/bin.
  if command -v tree-sitter >/dev/null 2>&1; then
    log "CLI tree-sitter déjà présent."
    return
  fi
  log "Installation du CLI tree-sitter (binaire précompilé)…"
  mkdir -p "$HOME/.local/bin"
  local tmp; tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/tree-sitter.gz" \
      https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
      && gunzip "$tmp/tree-sitter.gz" \
      && chmod +x "$tmp/tree-sitter" \
      && mv "$tmp/tree-sitter" "$HOME/.local/bin/tree-sitter"; then
    :
  else
    warn "Échec installation du CLI tree-sitter — installe-le à la main dans ~/.local/bin."
  fi
  rm -rf "$tmp"
}

# ── réglages nécessaires au fonctionnement de la config zsh ───────────────────
setup_zsh_env() {
  # La config zsh vit dans ~/.config/zsh et s'appuie sur $ZDOTDIR. zsh ne lit
  # ZDOTDIR que depuis ~/.zshenv (ou /etc/zsh/zshenv) : on le pose ici. On y
  # ajoute aussi ~/.local/bin au PATH (fd/bat renommés, CLI tree-sitter…).
  local ZSHENV="$HOME/.zshenv"
  touch "$ZSHENV"
  grep -qF 'ZDOTDIR' "$ZSHENV"    || { log "ZDOTDIR → ~/.zshenv"; printf '%s\n' 'export ZDOTDIR="$HOME/.config/zsh"' >> "$ZSHENV"; }
  grep -qF '.local/bin' "$ZSHENV" || printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHENV"

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
# une arbo $HOME), les notes à la racine, et 'chrome' (Firefox, géré à part par
# deploy_firefox car le nom de profil est aléatoire → pas stowable).
STOW_PACKAGES=(
  alacritty autostart i3 i3status neofetch nvim ranger script vim xdg zsh
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

# ── Firefox (thème DownToneUI + user.js + policy Sidebery) ───────────────────
# Non stowable : le profil Firefox de Mint est ~/.config/mozilla/firefox/
# <aléatoire>.default-release. On détecte le profil et on y lie chrome/ + user.js.
FF_ROOT="$HOME/.config/mozilla/firefox"
SIDEBERY_ID="{3c078156-979c-498b-8990-85f7987dd929}"

_find_ff_profile() {
  # 1) valeur Default= de la section [Install*] de profiles.ini (profil lancé)
  # 2) sinon un dossier *.default-release existant
  local ini="$FF_ROOT/profiles.ini" rel=""
  if [ -f "$ini" ]; then
    rel=$(awk -F= '/^\[Install/{i=1;next} i&&/^Default=/{print $2; exit}' "$ini")
  fi
  if [ -n "$rel" ] && [ -d "$FF_ROOT/$rel" ]; then
    printf '%s\n' "$FF_ROOT/$rel"; return 0
  fi
  local p; p=$(ls -d "$FF_ROOT"/*.default-release 2>/dev/null | head -1)
  [ -n "$p" ] && { printf '%s\n' "$p"; return 0; }
  return 1
}

deploy_firefox() {
  local src="$DOTFILES/chrome"
  [ -d "$src/chrome" ] || { warn "chrome/ absent du dépôt — Firefox ignoré."; return; }

  local prof
  if ! prof=$(_find_ff_profile); then
    warn "Aucun profil Firefox trouvé. Lance Firefox une fois (pour le créer), puis :"
    warn "  ./install.sh --restow   (ou relance ./install.sh)"
    return
  fi
  log "Profil Firefox : $prof"

  # chrome/ et user.js → liens symboliques dans le profil (sauvegarde si réels).
  local ts; ts=$(date +%s)
  for item in chrome user.js; do
    local tgt="$prof/$item"
    if [ -L "$tgt" ]; then rm -f "$tgt"
    elif [ -e "$tgt" ]; then mv "$tgt" "$tgt.bak.$ts"; warn "Sauvegarde: $tgt → $tgt.bak.$ts"; fi
    ln -s "$src/$item" "$tgt"
    log "lié: $item → $tgt"
  done

  # policies.json → auto-install Sidebery (system-wide, nécessite sudo).
  if [ -f "$src/policies.json" ]; then
    local poldir="/etc/firefox/policies"
    if sudo mkdir -p "$poldir" && sudo cp "$src/policies.json" "$poldir/policies.json"; then
      log "policies.json installée ($poldir) — Sidebery s'installera au 1er lancement."
    else
      warn "Échec install policies.json — installe Sidebery à la main depuis addons.mozilla.org."
    fi
  fi

  # Rappel réglages Sidebery (IndexedDB, non versionnable en fichier).
  if [ -f "$src/sidebery-backup.json" ]; then
    warn "Sidebery : importe tes réglages via Sidebery → Aide → Import settings from file → $src/sidebery-backup.json"
  else
    warn "Sidebery : pense à exporter tes réglages (Sidebery → Aide → Export settings) vers $src/sidebery-backup.json et à les committer."
  fi
}

# ── wallpaper : rien à stow, on rappelle juste où il est ─────────────────────
notice_wallpaper() {
  log "Fond d'écran disponible : $DOTFILES/wallpaper/foret.jpg"
  echo "    (i3 charge ~/.fehbg au démarrage ; règle-le avec : feh --bg-scale '$DOTFILES/wallpaper/foret.jpg')"
}

# ── déroulé ──────────────────────────────────────────────────────────────────
if [ "$RESTOW_ONLY" -eq 1 ]; then
  run_stow
  deploy_firefox
  exit 0
fi

if [ "$DO_APT" -eq 1 ]; then
  install_apt
  install_fonts
  install_alacritty_terminfo
  install_alacritty_from_source
fi
init_submodules
install_zsh_stack
install_nvim_toolchain
setup_zsh_env
run_stow
deploy_firefox
notice_wallpaper

log "Terminé. Ouvre un nouveau terminal (ou 'exec zsh') pour charger la config."
echo
warn "nvim / treesitter : au premier lancement, installe les gros parsers UN PAR UN"
warn "  (:TSInstall cpp puis :TSInstall vim) — l'install groupée peut OOM sur < 8 Gio RAM."
warn "Firefox : lance-le une fois pour que Sidebery s'installe, puis importe tes réglages"
warn "  Sidebery (voir chrome/README.md). Redémarre Firefox pour appliquer le thème."
warn "Polices : configure le terminal sur 'Maple Mono NF' si les icônes manquent."
