# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap

> macOS prerequisite: [Homebrew](https://brew.sh/) must be installed before running `chezmoi apply` — the install script uses it for zoxide, fzf, eza, and the Nerd Font.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply mkilivan
```

Both shell configs add `~/.local/bin` to `PATH` on Linux and macOS. On Apple
Silicon Macs, they also initialize Homebrew from `/opt/homebrew`. Until the
shell config is loaded, use `~/.local/bin/chezmoi` directly.

### macOS

Default shell is zsh — `~/.zshrc` is managed by chezmoi directly, no extra step needed.
Run `source ~/.zshrc` after applying to update the current shell.

### Linux

Defaults to bash. Personal customizations are applied to `~/.bashrc.d/custom.bash`
(from `dot_bashrc.d/custom.bash.tmpl`) and line-editing settings to `~/.inputrc`.
The stock RHEL/Fedora `~/.bashrc` sources `~/.bashrc.d/*` automatically, so no
extra step is needed there — open a new terminal after applying.

If your `~/.bashrc` doesn't load `~/.bashrc.d` (e.g. Ubuntu's default), add it once:

```bash
echo 'for rc in ~/.bashrc.d/*; do [ -f "$rc" ] && . "$rc"; done; unset rc' >> ~/.bashrc
```

**Optional: switch to zsh.** `~/.zshrc` is already managed by chezmoi, so this just needs zsh installed and set as your login shell:

```bash
# install zsh if it's not already present
command -v zsh &>/dev/null || sudo apt-get install -y zsh

# set it as your login shell (must be listed in /etc/shells)
chsh -s "$(command -v zsh)"
```

Log out and back in for the change to take effect.

## Font setup

The install script automatically installs **JetBrains Mono Nerd Font**. After it runs, set this font in your terminal emulator's font settings for prompt icons to render correctly.
