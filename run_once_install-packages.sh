#!/bin/bash
# Installs tools referenced in dotfiles. Runs once; re-runs only if this file changes.
set -e

BOLD='\033[1m'
RESET='\033[0m'
OS="$(uname)"

info()    { echo -e "${BOLD}==> $1${RESET}"; }
skip()    { echo "==> $1 already installed ($2), skipping"; }
done_()   { echo "==> $1 $2 installed"; }
warn()    { echo "==> WARNING: $1"; }
version() { "$@" 2>&1 | grep -oE '[0-9]+\.[0-9]+[a-z]?[0-9]*(\.[0-9]+[a-z]?)?' | head -1; }

try_install_apt() {
  local pkg="$1"
  if sudo apt-get install -y "$pkg"; then
    return 0
  fi
  warn "Could not install ${pkg} (missing sudo privileges or apt failure). Continuing."
  return 1
}

# starship
if command -v starship &>/dev/null; then
  skip "starship" "$(version starship --version)"
else
  info "Installing starship"
  if [ "$OS" = "Darwin" ]; then
    if brew install starship; then
      done_ "starship" "$(version starship --version)"
    else
      warn "starship not installed"
    fi
  else
    if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
      done_ "starship" "$(version starship --version)"
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
    if brew install zoxide; then
      done_ "zoxide" "$(version zoxide --version)"
    else
      warn "zoxide not installed"
    fi
  else
    if curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
      done_ "zoxide" "$(version zoxide --version)"
    else
      warn "zoxide not installed"
    fi
  fi
fi

# fzf
if command -v fzf &>/dev/null; then
  skip "fzf" "$(version fzf --version)"
elif [ -d ~/.fzf ]; then
  skip "fzf" "$(version ~/.fzf/bin/fzf --version)"
else
  info "Installing fzf"
  if [ "$OS" = "Darwin" ]; then
    brew install fzf
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-update-rc
  fi
  done_ "fzf" "$(version fzf --version)"
fi

# eza
if command -v eza &>/dev/null; then
  skip "eza" "$(version eza --version)"
else
  info "Installing eza"
  if [ "$OS" = "Darwin" ]; then
    brew install eza
    done_ "eza" "$(version eza --version)"
  else
    if try_install_apt eza; then
      done_ "eza" "$(version eza --version)"
    fi
  fi
fi

# tmux
if command -v tmux &>/dev/null; then
  skip "tmux" "$(version tmux -V)"
else
  info "Installing tmux"
  if [ "$OS" = "Darwin" ]; then
    brew install tmux
    done_ "tmux" "$(version tmux -V)"
  else
    if try_install_apt tmux; then
      done_ "tmux" "$(version tmux -V)"
    fi
  fi
fi

# libtmux (python) — required by the tmux-window-name plugin
if python3 -c "import libtmux" &>/dev/null; then
  skip "libtmux (python)" "already present"
else
  if ! command -v python3 &>/dev/null; then
    if [ "$OS" = "Darwin" ]; then
      info "Installing python3 (Homebrew) for tmux-window-name plugin"
      brew install python3 || warn "python3 not installed; tmux-window-name plugin renaming will not work"
    else
      warn "python3 not found; tmux-window-name plugin renaming will not work"
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
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "==> tpm installed"
fi

# JetBrains Mono Nerd Font
if [ "$OS" = "Darwin" ]; then
  info "Installing JetBrains Mono Nerd Font (macOS)"
  brew install --cask font-jetbrains-mono-nerd-font
else
  if fc-list | grep -qi "JetBrainsMono"; then
    echo "==> JetBrains Mono Nerd Font already installed, skipping"
  else
    info "Installing JetBrains Mono Nerd Font (Linux)"
    if command -v unzip &>/dev/null; then
      skip "unzip" "$(version unzip -v)"
    else
      info "Installing unzip"
      if try_install_apt unzip; then
        done_ "unzip" "$(version unzip -v)"
      else
        warn "Skipping JetBrains Mono Nerd Font install (unzip unavailable)"
      fi
    fi

    if command -v unzip &>/dev/null; then
      curl -fLo /tmp/JetBrainsMono.zip \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
      mkdir -p ~/.local/share/fonts/JetBrainsMono
      unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono/ '*.ttf'
      fc-cache -fv
      rm /tmp/JetBrainsMono.zip
      echo "==> JetBrains Mono Nerd Font installed"
    fi
  fi
fi
