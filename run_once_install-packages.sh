#!/bin/bash
# Installs tools referenced in dotfiles. Runs once; re-runs only if this file changes.
#
# Every install step warns and carries on when it fails, so one missing tool
# never stops the rest. macOS uses Homebrew. On Linux nothing needs sudo: tools
# are installed user-locally from upstream releases, and tools that only exist
# as system packages are listed at the end for you to install manually.
set -e

BOLD='\033[1m'
RESET='\033[0m'
OS="$(uname)"
LOCAL_BIN="$HOME/.local/bin"

# chezmoi may run this before the shell config has set up PATH (e.g. on a
# fresh machine), so make user-local installs and Homebrew visible here too
export PATH="$LOCAL_BIN:$HOME/.fzf/bin:$PATH"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info()    { echo -e "${BOLD}==> $1${RESET}"; }
skip()    { echo "==> $1 already installed ($2), skipping"; }
done_()   { echo "==> $1 $2 installed"; }
warn()    { echo "==> WARNING: $1"; }
version() { "$@" 2>&1 | grep -oE '[0-9]+\.[0-9]+[a-z]?[0-9]*(\.[0-9]+[a-z]?)?' | head -1; }

# brew_install <formula> <version command...> — e.g. brew_install neovim nvim --version
brew_install() {
  local formula="$1"; shift
  if brew install "$formula"; then
    done_ "$formula" "$(version "$@")"
  else
    warn "$formula not installed"
  fi
}

# Linux system packages that couldn't be installed user-locally; printed at the end
missing_pkgs=()

case "$(uname -m)" in
  x86_64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) ARCH="" ;;
esac

# starship
if command -v starship &>/dev/null; then
  skip "starship" "$(version starship --version)"
else
  info "Installing starship"
  if [ "$OS" = "Darwin" ]; then
    brew_install starship starship --version
  else
    if mkdir -p "$LOCAL_BIN" &&
      curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN"; then
      done_ "starship" "$(version "$LOCAL_BIN/starship" --version)"
    else
      warn "starship not installed"
    fi
  fi
fi

# zoxide
if command -v zoxide &>/dev/null; then
  skip "zoxide" "$(version zoxide --version)"
else
  info "Installing zoxide"
  if [ "$OS" = "Darwin" ]; then
    brew_install zoxide zoxide --version
  else
    if curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
      done_ "zoxide" "$(version "$LOCAL_BIN/zoxide" --version)"
    else
      warn "zoxide not installed"
    fi
  fi
fi

# fzf
if command -v fzf &>/dev/null; then
  skip "fzf" "$(version fzf --version)"
else
  info "Installing fzf"
  if [ "$OS" = "Darwin" ]; then
    brew_install fzf fzf --version
  else
    # Reuse an existing clone so a previously failed ~/.fzf/install is retried
    if { [ -d ~/.fzf ] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; } &&
      ~/.fzf/install --all --no-update-rc; then
      done_ "fzf" "$(version ~/.fzf/bin/fzf --version)"
    else
      warn "fzf not installed"
    fi
  fi
fi

# eza
if command -v eza &>/dev/null; then
  skip "eza" "$(version eza --version)"
else
  info "Installing eza"
  if [ "$OS" = "Darwin" ]; then
    brew_install eza eza --version
  elif [ -z "$ARCH" ]; then
    warn "eza prebuilt binary unavailable for Linux architecture $(uname -m)"
  else
    case "$ARCH" in
      x86_64) eza_arch="x86_64-unknown-linux-gnu" ;;
      arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
    esac
    eza_tmpdir="$(mktemp -d)"
    if mkdir -p "$LOCAL_BIN" &&
      curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${eza_arch}.tar.gz" \
        -o "$eza_tmpdir/eza.tar.gz" &&
      tar -xzf "$eza_tmpdir/eza.tar.gz" -C "$eza_tmpdir" &&
      install -m 755 "$eza_tmpdir/eza" "$LOCAL_BIN/eza"; then
      done_ "eza" "$(version "$LOCAL_BIN/eza" --version)"
    else
      warn "eza not installed"
    fi
    rm -rf "$eza_tmpdir"
  fi
fi

# tmux — no official prebuilt binary, so system package only on Linux
if command -v tmux &>/dev/null; then
  skip "tmux" "$(version tmux -V)"
elif [ "$OS" = "Darwin" ]; then
  info "Installing tmux"
  brew_install tmux tmux -V
else
  missing_pkgs+=(tmux)
fi

# neovim — official release tarball on Linux, so no sudo or EPEL needed
if command -v nvim &>/dev/null; then
  skip "neovim" "$(version nvim --version)"
else
  info "Installing neovim"
  if [ "$OS" = "Darwin" ]; then
    brew_install neovim nvim --version
  elif [ -z "$ARCH" ]; then
    warn "neovim prebuilt binary unavailable for Linux architecture $(uname -m)"
  else
    nvim_dist="$HOME/.local/share/nvim-dist"
    nvim_tmpdir="$(mktemp -d)"
    if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz" \
        -o "$nvim_tmpdir/nvim.tar.gz" &&
      rm -rf "$nvim_dist" &&
      mkdir -p "$nvim_dist" "$LOCAL_BIN" &&
      tar -xzf "$nvim_tmpdir/nvim.tar.gz" -C "$nvim_dist" --strip-components=1 &&
      ln -sf "$nvim_dist/bin/nvim" "$LOCAL_BIN/nvim"; then
      done_ "neovim" "$(version "$LOCAL_BIN/nvim" --version)"
    else
      warn "neovim not installed"
    fi
    rm -rf "$nvim_tmpdir"
  fi
fi

# xclip — X11 clipboard tool, best-effort only: tmux copies via OSC 52
# without it (macOS uses the built-in pbcopy/pbpaste, nothing to install there)
if [ "$OS" = "Darwin" ]; then
  skip "clipboard tool" "pbcopy/pbpaste built in"
elif command -v xclip &>/dev/null; then
  skip "xclip" "$(version xclip -version)"
else
  missing_pkgs+=(xclip)
fi

# libtmux (python) — required by the tmux-window-name plugin
if python3 -c "import libtmux" &>/dev/null; then
  skip "libtmux (python)" "already present"
else
  if ! command -v python3 &>/dev/null; then
    if [ "$OS" = "Darwin" ]; then
      info "Installing python3 for tmux-window-name plugin"
      brew install python3 || warn "python3 not installed; tmux-window-name plugin renaming will not work"
    else
      missing_pkgs+=(python3)
    fi
  fi

  if command -v python3 &>/dev/null; then
    info "Installing libtmux (python) for tmux-window-name plugin"
    if python3 -m pip install --user libtmux &>/dev/null; then
      done_ "libtmux" "installed"
    elif python3 -m pip install --user --break-system-packages libtmux &>/dev/null; then
      done_ "libtmux" "installed (--break-system-packages)"
    else
      warn "libtmux not installed; tmux-window-name plugin renaming will not work"
    fi
  fi
fi

# tpm (tmux plugin manager)
if [ -d ~/.tmux/plugins/tpm ]; then
  echo "==> tpm already installed, skipping"
else
  info "Installing tpm"
  if git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; then
    echo "==> tpm installed"
  else
    warn "tpm not installed"
  fi
fi

# JetBrains Mono Nerd Font
if [ "$OS" = "Darwin" ]; then
  if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    echo "==> JetBrains Mono Nerd Font already installed, skipping"
  else
    info "Installing JetBrains Mono Nerd Font (macOS)"
    if brew install --cask font-jetbrains-mono-nerd-font; then
      echo "==> JetBrains Mono Nerd Font installed"
    else
      warn "JetBrains Mono Nerd Font not installed"
    fi
  fi
elif command -v fc-list &>/dev/null && fc-list | grep -qi "JetBrainsMono"; then
  echo "==> JetBrains Mono Nerd Font already installed, skipping"
else
  info "Installing JetBrains Mono Nerd Font (Linux)"
  font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  font_tmpdir="$(mktemp -d)"
  if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
      -o "$font_tmpdir/JetBrainsMono.tar.xz" &&
    mkdir -p "$font_dir" &&
    tar -xJf "$font_tmpdir/JetBrainsMono.tar.xz" -C "$font_dir" --wildcards '*.ttf'; then
    if command -v fc-cache &>/dev/null; then
      fc-cache -f "$font_dir" >/dev/null || warn "fc-cache failed; font may need a re-login to appear"
    fi
    echo "==> JetBrains Mono Nerd Font installed"
  else
    warn "JetBrains Mono Nerd Font not installed"
  fi
  rm -rf "$font_tmpdir"
fi

if [ ${#missing_pkgs[@]} -gt 0 ]; then
  warn "Some tools need a system package; install them manually if you have admin rights:"
  if command -v dnf &>/dev/null; then
    echo "      sudo dnf install ${missing_pkgs[*]}"
  elif command -v apt-get &>/dev/null; then
    echo "      sudo apt-get install ${missing_pkgs[*]}"
  else
    echo "      ${missing_pkgs[*]} (with your system package manager)"
  fi
fi
