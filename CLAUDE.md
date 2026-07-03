# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for Linux, managed with [chezmoi](https://www.chezmoi.io/). Config files live here and are applied to `$HOME` via `chezmoi apply`.

chezmoi config points to this repo as its source dir: `~/.config/chezmoi/chezmoi.toml`

## Bootstrap a new machine

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Clone repo and apply in one shot
~/.local/bin/chezmoi init --apply https://github.com/mkilivan/dotfiles.git
```

`chezmoi apply` will also run `run_once_install-packages.sh` automatically on first apply, which installs all tool dependencies.

## Daily workflow

| Task | Command |
|------|---------|
| Edit a dotfile | `chezmoi edit ~/.zshrc` |
| Preview pending changes | `chezmoi diff` |
| Apply changes to home | `chezmoi apply` |
| Check source dir | `chezmoi cd` |
| Re-add a file modified in home | `chezmoi add ~/.zshrc` |

## File naming convention

chezmoi source files use `dot_` prefix instead of a leading `.`:

| Source file     | Applied to      |
|-----------------|-----------------|
| `dot_zshrc`     | `~/.zshrc`      |
| `dot_config/git/config.tmpl` | `~/.config/git/config` |
| `dot_tmux.conf` | `~/.tmux.conf`  |

Files listed in `.chezmoiignore` (CLAUDE.md, README.md) are not applied to home.

## Dependencies

Installed automatically by `run_once_install-packages.sh` on first `chezmoi apply`:

| Tool | Purpose |
|------|---------|
| [starship](https://starship.rs/) | Cross-shell prompt |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` (use: `z <dir>`) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (`Ctrl-R` history, `Ctrl-T` files) |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement |
| [tpm](https://github.com/tmux-plugins/tpm) | Tmux plugin manager |
| [libtmux](https://github.com/tmux-python/libtmux) (pip, `--user`) | Python dependency for the tmux-window-name plugin |

After tpm is installed, press `prefix + I` inside tmux to install plugins (tmux-resurrect, tmux-continuum, tmux-window-name, catppuccin).

## Key configuration notes

- **tmux prefix**: `C-a`; requires tmux 2.4+
- **tmux clipboard**: uses `xclip -sel clip`; swap for `wl-copy` on Wayland
- **tmux-resurrect**: saves/restores sessions across reboots (`prefix + Ctrl-s` save, `prefix + Ctrl-r` restore)
- **git editor**: VS Code (`code --wait`)
