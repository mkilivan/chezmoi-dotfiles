# dotfiles

My shell, git, tmux and Neovim config for macOS and Linux, managed with [chezmoi](https://www.chezmoi.io/).

## Setup

**macOS only:** install [Homebrew](https://brew.sh/) first.

1. Install chezmoi and apply the dotfiles:

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply mkilivan
   ```

   It asks for your name, email and GitHub username (used for git), then installs the tools. No sudo needed on Linux. If a tool needs a system package, the last line tells you what to install.

2. Open a new terminal.

   On Linux, if the new config doesn't load (e.g. on Ubuntu), run this once:

   ```bash
   echo 'for rc in ~/.bashrc.d/*; do [ -f "$rc" ] && . "$rc"; done; unset rc' >> ~/.bashrc
   ```

3. Set your terminal font to **JetBrainsMono Nerd Font** so prompt icons show up.

4. In tmux, press `Ctrl-a` then `I` to install the plugins.

## Daily use

| Task | Command |
|------|---------|
| Edit a file | `chezmoi edit ~/.zshrc` |
| See what would change | `chezmoi diff` |
| Apply changes | `chezmoi apply` |
| Pull in updates from GitHub | `chezmoi update` |

Until your shell config is loaded, run chezmoi as `~/.local/bin/chezmoi`.

## Optional: use zsh on Linux

Linux uses bash by default. `~/.zshrc` is already set up, so you only need zsh installed:

```bash
chsh -s "$(command -v zsh)"   # install zsh first if it's missing
```

Log out and back in.
