# Neovim migration — October 3, 2026

Neovim was upgraded through Homebrew from 0.10.4 to **0.12.5**. This configuration now follows [Kickstart commit `8e35dbed`](https://github.com/nvim-lua/kickstart.nvim/commit/8e35dbedb7966e3a95e1f26f9fc1179ab6c68db4), with your customizations carried forward. Verified normal startup, Slang attachment to `.sv` and `.v` files, document symbols, an intentional undefined-signal diagnostic, Tree-sitter highlighting, and Verible formatting. Kickstart and Tree-sitter health checks passed, as did Lua syntax and formatting checks.

Homebrew reported an outdated Apple Command Line Tools warning. The Neovim upgrade and plugin/parser builds completed successfully. Update Apple Command Line Tools through System Settings → Software Update before future Homebrew source builds.

## What changed

- Native `vim.pack` manages plugins in place of Lazy. `nvim-pack-lock.json` is the active lockfile and should be committed with the configuration. The obsolete Lazy installation and live `lazy-lock.json` were removed during the October 4 cleanup; the original lockfile remains in the configuration backup.
- Tree-sitter now uses its `systemverilog` parser for both HDL filetypes. The required Tree-sitter CLI 0.27.0 was installed through Homebrew.
- `blink.cmp` replaces `nvim-cmp`. LuaSnip remains, including `<C-l>` / `<C-h>` for forward / backward snippet jumps.
- LSP configuration uses `vim.lsp.config()` and `vim.lsp.enable()`. Original navigation and action keys remain as aliases: `gd`, `gr`, `gI`, `gD`, `<leader>D`, `<leader>ds`, `<leader>ws`, `<leader>rn`, and `<leader>ca`.
- Slang server **0.3.0** is installed. `slang_server` is the Neovim server ID; `slang-server` is the Mason package and executable. Current `mason-lspconfig` translates the names. Its `ensure_installed` list comes from the configured server keys, while `automatic_enable = false` and explicit enables prevent dormant installed servers from starting.
- `mason-tool-installer` separately installs tools by Mason package name. Verible remains the Verilog/SystemVerilog formatter through Conform, and Slang supplies HDL diagnostics. The initially retained single-file Verilator linter was removed after it produced false missing-module errors. Slang replaces the Verible language server.

The original `gr` shortcut shares a prefix with new `grr` / `grn` actions, so bare `gr` waits for the existing 300 ms mapping timeout. Restart existing Neovim sessions to use the new executable and configuration.

## October 4 follow-up: appearance and cleanup

The theme now loads `tokyonight` without forcing its dark variant. Neovim detects the terminal background and selects a light or dark theme accordingly. Verified a light → dark → light cycle using terminal color responses. Restart existing Neovim sessions to pick up the change.

Removed the 33 obsolete Lazy plugin checkouts, Lazy state cache, old live lockfile, 1,849 compiled cache files belonging to removed installations, and the Homebrew Neovim 0.10.4_1 keg. The 22 active native plugins now exactly match `nvim-pack-lock.json`; all nine remaining Mason packages are configured and required. Slang, symbols, diagnostics, syntax highlighting, and Verible formatting passed checks after cleanup.

Verible remains necessary for formatting; its package also contains a language-server executable, but that server is disabled. The separate Homebrew Verible installation supplies terminal commands and was retained because its use outside Neovim is unknown. Tree-sitter CLI remains required; Verilator is retained as a standalone command-line tool. Migration backups, editor history, undo data, and recovery files were preserved.

## October 4 follow-up: cross-file HDL diagnostics

In the lab project, Slang correctly resolved `clk_div` from `clk_gen.sv` and returned its module signature. The apparent missing-module error came from the independent Verilator linter, which received only the current file and lacked the other source files. Automatic HDL linting through `nvim-lint` was removed, and the now-unused plugin was uninstalled. Slang continues to provide diagnostics; Verible continues to format files. No HDL source or project indexing changes were needed.

After restarting Neovim, `gd` on `clk_div` jumps to its definition and `K` shows its module signature. Verilator is still available from the terminal for explicit project-wide linting.

## Routine updates and checks

In a terminal, update Neovim with `brew update` followed by `brew upgrade neovim`. Check the active executable with `nvim --version`.

In Neovim:

| Command | Purpose |
| --- | --- |
| `:lua vim.pack.update()` | Fetch plugin updates and show the review buffer; `:write` applies them, `:quit` discards them. Restart afterward. |
| `:lua vim.pack.update(nil, { offline = true })` | Inspect installed plugin state without fetching. |
| `:MasonUpdate` | Refresh the package registry. |
| `:Mason` | Inspect and update language servers; `g?` shows available actions. Slang's package is `slang-server`. |
| `:MasonToolsUpdate` | Update the separately configured formatter/tool packages. |
| `:checkhealth` | Check configuration, dependencies, and providers. |
| `:checkhealth vim.lsp` | Inspect enabled and attached language servers. Open a `.sv` or `.v` file first; expect `slang_server`. |
| `:ConformInfo` | Verify that Verible formatting is available in Verilog/SystemVerilog buffers. |

Review and commit changes to `nvim-pack-lock.json` after plugin updates. Kickstart changes are merged into this customized configuration separately; plugin updates do not update `init.lua`.

For project include paths, defines, indexing exclusions, or compilation files, use `.slang/server.json` in the project. See [Slang's project configuration documentation](https://hudson-trading.github.io/slang-server/start/config/). The upstream LSP configuration recognizes `.git` and `.slang` as project root markers.

## Backups and restoring the previous configuration

Original files, including pre-existing uncommitted edits, were saved to:

- `/Users/nohgoering/.local/state/nvim-migration/20261003/config-before.tar.gz`
- `/Users/nohgoering/.local/state/nvim-migration/20261003/uncommitted-before.patch`

To restore the previous configuration, first close Neovim and preserve the current configuration. These commands keep both versions and do not delete plugin data:

```sh
restore_snapshot="$HOME/.local/state/nvim-migration/before-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$restore_snapshot" -C "$HOME/.config/nvim" --exclude=.git .
tar -tzf "$HOME/.local/state/nvim-migration/20261003/config-before.tar.gz"
# After reviewing the archive listing:
tar -xzf "$HOME/.local/state/nvim-migration/20261003/config-before.tar.gz" -C "$HOME/.config/nvim"
```

The restored `init.lua` uses Lazy and the backed-up `lazy-lock.json`. Because the obsolete Lazy installation has now been removed, the first startup after restoring will download Lazy and reinstall the locked plugins; an internet connection is required. Newly added files such as `nvim-pack-lock.json` may remain on disk but are inactive under the restored configuration. The patch is a reference copy of the original edits; do not apply it again over the restored archive. Configuration restoration does not downgrade the Homebrew Neovim executable, so verify startup after restoring.
