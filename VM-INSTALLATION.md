# School VM: Neovim installation and maintenance

Recorded and verified on **2026-10-06**. This is a snapshot of the Linux installation; update the version numbers and paths here when you change it.

**Addition on 2026-10-15:** Codex CLI was installed separately; see the Codex section at the end. The Neovim inventory above remains the October 6 snapshot.

SSH destination: `nohgoering@linux.ece.ufl.edu`. The host inspected during installation was `ece-lnx-01`, running **RHEL 8.10, x86_64, glibc 2.28**. Everything added for Neovim is installed under your home directory, without sudo or Conda.

On this VM, `~` means `/home/UFAD/nohgoering`. Your home is stored on NFS and also appears as `/ecel/UFAD/nohgoering`; those two paths can refer to the same files. `/tmp` is local storage and was used only for disposable compilation and testing.

## How the parts fit together

```text
Your terminal
  └── ~/.local/bin/nvim                     launcher script
        ├── adds editor dependencies to PATH
        └── ~/.local/opt/nvim-0.12.5/bin/nvim actual editor
              ├── ~/.config/nvim/           your Git-managed configuration
              ├── vim.pack                  downloads Neovim plugins
              ├── Mason                     installs language servers/formatters
              └── nvim-treesitter            installs/compiles syntax parsers
```

**Pulling your config does not upgrade the Neovim executable or every external tool.** Each layer has its own update procedure below.

## Directory map

All paths in this table are on the Linux VM.

| Location | Contents | Managed by |
| --- | --- | --- |
| `~/.config/nvim/` | Kickstart-derived config, custom Lua, plugin lockfile | Your Git repository |
| `~/.local/bin/nvim` | Small launcher script | Manual installation |
| `~/.local/opt/nvim-0.12.5/` | Full Neovim distribution: executable, libraries, runtime, bundled parsers | Manual installation |
| `~/.local/bin/tree-sitter` | Standalone Tree-sitter CLI built for this VM | Manual installation |
| `~/.local/bin/rg` | Standalone ripgrep search executable | Manual installation |
| `~/.local/opt/node-22.23.3/` | Node.js, npm, npx | Manual installation |
| `~/.local/opt/go-1.27.1/` | Go toolchain | Manual installation |
| `~/.local/opt/nvim-tools/bin/` | Symlinks exposing Node, Go, and Python to Neovim | Manual installation |
| `~/.local/share/nvim/site/pack/core/opt/` | 22 Neovim plugins | Native `vim.pack` |
| `~/.config/nvim/nvim-pack-lock.json` | Resolved plugin revisions | Native `vim.pack`, tracked in Git |
| `~/.local/share/nvim/mason/packages/` | Language servers, formatters, their private dependencies and receipts | Mason |
| `~/.local/share/nvim/mason/bin/` | Executable links/wrappers for Mason tools | Mason |
| `~/.local/share/nvim/mason/registries/` | Package registry metadata | Mason |
| `~/.local/share/nvim/site/parser/` | Compiled syntax parsers (`.so` files) | `nvim-treesitter` |
| `~/.local/share/nvim/site/queries/` | Highlighting, folding, and related syntax queries | `nvim-treesitter` |
| `~/.local/state/nvim/` | Logs, state, and other Neovim records | Neovim/plugins |
| `~/.cache/nvim/` | Disposable Neovim cache | Neovim/plugins |
| `~/.local/share/doc/nvim/VM-INSTALLATION.md` | VM copy of this guide | Manual documentation |

Go builds can also create caches under `~/.cache/go-build/` and modules under `~/go/pkg/mod/`. These are build caches/dependencies, rather than another environment to activate.

## PATH and shell startup

Your existing `~/.bash_profile` already adds `~/.local/bin` and `~/bin` to your login shell's PATH. No new shell initialization or environment activation was added.

The installed `~/.local/bin/nvim` is exactly:

```sh
#!/bin/sh
# Native editor dependencies are exposed only to Neovim and its child tools.
export PATH="$HOME/.local/opt/nvim-tools/bin:$HOME/.local/bin:$PATH"
exec "$HOME/.local/opt/nvim-0.12.5/bin/nvim" "$@"
```

The private tool directory contains these symlinks:

| Command | Target |
| --- | --- |
| `node`, `npm`, `npx` | Corresponding commands in `~/.local/opt/node-22.23.3/bin/` |
| `go`, `gofmt` | Corresponding commands in `~/.local/opt/go-1.27.1/bin/` |
| `python3` | `/usr/bin/python3.12`, already provided by the school |

Inside Neovim, Mason prepends its own `bin` directory. The effective order is therefore Mason tools, private editor dependencies, `~/.local/bin`, then the inherited PATH. This lets installers find npm, Go, and a recent Python without overriding the school's Python or adding activation work to every terminal startup.

Use `nvim` or `~/.local/bin/nvim` to get this setup. Launching the versioned executable directly skips the private dependency PATH. A non-login SSH command may need the explicit `~/.local/bin/nvim` path.

Bash caches executable locations. After replacing or removing an executable, `hash -r` clears that cache. A fresh SSH login also starts with a fresh command cache.

## Installed versions and responsibilities

### Manually installed tools

| Tool | Version | Purpose / compatibility choice |
| --- | --- | --- |
| Neovim | 0.12.5 | Older-glibc distribution from the Neovim project's compatibility release repository |
| Tree-sitter CLI | 0.27.0 | Built on RHEL 8 so it runs with glibc 2.28 |
| ripgrep | 15.2.0 | Upstream x86_64 musl build, used by search |
| Node.js / npm | 22.23.3 / 10.9.9 | Pyright and npm-based Mason installations |
| Go | 1.27.1 | Builds Go-based Mason tools such as gopls and goimports |
| Python | 3.12.13 | School-provided interpreter used by Neovim's installers; supports virtual environments |
| GCC / G++ | 8.5.0 | School-provided compiler, used for syntax parsers and native plugin builds |

The Neovim compatibility repository explicitly describes its builds as best-effort and unsupported. Its older-glibc build was tested successfully here. It is distinct from the main supported release artifacts, which may require a newer system library. See the [Neovim compatibility repository](https://github.com/neovim/neovim-releases).

### Mason-managed tools

| Mason package | Version recorded in receipt | Role |
| --- | --- | --- |
| `slang-server` | 0.3.0 | Verilog/SystemVerilog language server |
| `clangd` | 22.1.6 | C/C++ language server |
| `gopls` | 0.23.0 | Go language server |
| `pyright` | 1.1.414 | Python language server |
| `lua-language-server` | 3.18.2 | Lua language server; executable reports `3.18.2-dev` |
| `stylua` | 2.5.2 | Lua formatter; compatible musl target explicitly selected |
| `clang-format` | 23.1.2 | C/C++ formatter, installed in a Mason-owned Python virtual environment |
| `goimports` | `golang.org/x/tools` 0.51.0 | Go import management/formatting |
| `verible` | `v0.0-4084-gf3e4d98b` | HDL formatter; its language server is not enabled |

Mason package names, LSP configuration names, and executable names can differ. In particular, **`slang_server` is the Neovim LSP ID; `slang-server` is the Mason package and executable**. `mason-lspconfig` supplies the translation. Likewise, `lua_ls` maps to `lua-language-server`.

Mason is a separate package manager from `vim.pack`: `vim.pack` installs the Mason plugin itself, while Mason installs the external tools. See [Mason's documentation](https://github.com/mason-org/mason.nvim).

## Tree-sitter: what needs compiling

There are three separate parts:

1. Neovim has its own Tree-sitter runtime, included in the editor distribution.
2. `~/.local/bin/tree-sitter` is a command-line tool used when installing/generating parsers.
3. The language parsers are shared libraries compiled by the system C compiler and loaded by Neovim.

The downloaded Tree-sitter CLI initially required newer glibc versions than this VM provides. We instead built the same CLI from upstream source with system GCC and a temporary Rust toolchain. **Rust is not required to start Neovim or for ordinary C-based parser compilation.** The temporary Rust installation, downloads, source tree, and build output were removed afterward. No permanent `~/.cargo` or `~/.rustup` was created.

Build record for the installed CLI:

```text
Source: https://github.com/tree-sitter/tree-sitter
Tag: v0.27.0
Commit: 6070dbfefd326bd735e5683eb128cc1b57dad0c0
Build toolchain: official Rust 1.90.0 minimal + system GCC 8.5
Command: cargo build --release --locked --package tree-sitter-cli --jobs 4
```

For a future CLI rebuild, use a temporary directory on `/tmp` and point `RUSTUP_HOME`, `CARGO_HOME`, and `CARGO_TARGET_DIR` into it. Install Rust with `--no-modify-path`, use the Rust version required by the chosen source release, verify the resulting executable, and copy only that executable to `~/.local/bin/tree-sitter`. Delete the temporary build directory after testing. The [Rustup installation documentation](https://rust-lang.github.io/rustup/installation/index.html) describes installation options.

The configured parsers are `bash`, `c`, `diff`, `html`, `lua`, `luadoc`, `markdown`, `markdown_inline`, `query`, `vim`, `vimdoc`, and `systemverilog`. The `systemverilog` parser handles both Verilog and SystemVerilog buffers. The config also installs additional available parsers when you first open a matching file type.

Blink completion uses its Lua fuzzy matcher. It does not need a Rust toolchain. Telescope's native FZF extension was compiled successfully with the system compiler.

## Updating each layer

### 1. Pull your configuration from Git

Repository: `https://github.com/nohgo/nvim.git`, branch `master`. Installation snapshot: commit `ddc45c7` (`Update and switch to slang`).

On the VM:

```bash
cd ~/.config/nvim
git status --short
git pull --ff-only
nvim
```

Preserve any local edits before pulling. After pulling a changed plugin lockfile, use this **inside Neovim** to synchronize existing plugins to its recorded revisions:

```vim
:lua vim.pack.update(nil, { target = 'lockfile' })
```

Review the confirmation buffer, save it to apply, and restart Neovim. Newly added plugins are installed when the config loads. This synchronization procedure is documented in the installed `:help vim.pack` under “Synchronize config across machines.”

### 2. Update Neovim plugins to newer revisions

Inside Neovim:

```vim
:lua vim.pack.update()
```

This fetches plugin updates and opens a review buffer. `:write` accepts the updates; `:quit` discards them. Restart after applying. Check `git diff -- nvim-pack-lock.json`; commit and push the lockfile when you want other machines to use the same plugin versions.

This updates plugins, not the Neovim executable. Your config has native build hooks for Telescope FZF and a parser-update hook for nvim-treesitter.

### 3. Update syntax parsers

Inside Neovim:

```vim
:TSUpdate
:checkhealth nvim-treesitter vim.treesitter
```

Wait for compilation to finish before closing Neovim. If a newer nvim-treesitter version requires a newer CLI, update `~/.local/bin/tree-sitter` separately using a tested binary or source build. Parser downloads and builds require network access and the system compiler.

### 4. Update language servers and formatters

Use `:Mason` to inspect packages, refresh registry metadata with `:MasonUpdate`, and install/reinstall selected tools. Registry refresh is not the same as upgrading every installed package.

After an update, test the executable and open a file that uses it. A package being marked “installed” does not prove its binary can run on RHEL 8.

**StyLua compatibility:** Mason's ordinary GNU/Linux artifact for 2.5.2 could not run on glibc 2.28. The working installation uses the `linux_x64` musl target. If reinstalling/updating StyLua selects an incompatible binary, use:

```vim
:lua require('mason-registry').get_package('stylua'):install({ force = true, target = 'linux_x64' })
```

Wait for completion and verify `stylua --version` from Neovim's environment. This target selection is recorded in the package receipt; it is not a global rule forcing every future Mason installation to use musl.

### 5. Update the Neovim executable, Node, Go, or standalone tools

These are manually installed. Neither Git pull nor Mason updates them.

For Neovim, download an x86_64 build compatible with glibc 2.28 into `/tmp`, verify its upstream checksum, extract it, inspect `ldd` output, and test a clean headless startup before switching. Install the complete extracted distribution in a new `~/.local/opt/nvim-<version>/` directory. Change only the final `exec` path in `~/.local/bin/nvim`; keep the old directory until the new version passes normal startup and HDL checks. Do not copy just the editor executable: it needs the accompanying runtime.

For Node or Go, similarly test first, install into a new versioned directory under `~/.local/opt/`, then repoint the appropriate symlinks in `~/.local/opt/nvim-tools/bin/`. Keep the old version until Mason installations and the language tools work. Go-based tools may request a newer Go toolchain as their minimum supported version changes.

For ripgrep or Tree-sitter, verify a replacement in `/tmp` before replacing the standalone executable in `~/.local/bin/`. Prefer upstream musl builds when available and tested. If a binary reports `GLIBC_... not found`, choose a compatible artifact or build on this VM; the original problem does not require reinstalling Conda.

## Slang's project configuration

Slang's project file belongs in **each HDL project**, not in the global Neovim installation:

```text
your-project/
  .slang/server.json
  src/clk_gen.sv
  src/clk_div.sv
```

A minimal example used successfully in our disposable cross-file test was:

```json
{
  "index": [
    { "dirs": ["./src"] }
  ]
}
```

The current LSP config detects roots using `.git` and `.slang`. Indexing source directories allows Slang to find modules in separate files without adding Verilog `include` directives. Adapt directories and compilation settings to each actual project. See [Slang server configuration](https://hudson-trading.github.io/slang-server/start/config/).

This installation provides digital Verilog/SystemVerilog checking. It does not add Verilog-AMS analog checking or simulation; that remains a separate Cadence/tool workflow.

## Checks after an update

In your SSH terminal:

```bash
hash -r
command -v nvim tree-sitter rg
nvim --version
tree-sitter --version
```

Inside Neovim:

```vim
:checkhealth nvim-treesitter vim.treesitter mason
:lua print(vim.fn.exepath('slang-server'))
:lua print(vim.fn.exepath('node'))
:lua print(vim.fn.exepath('go'))
:lua print(vim.fn.exepath('python3'))
:lua print(vim.system({ 'slang-server', '--version' }, { text = true }):wait().stdout)
```

Open a SystemVerilog file, run `:checkhealth vim.lsp`, and try go-to-definition on a module from another source file. That checks the project configuration as well as executable startup. Check the formatter versions from Neovim's environment when updating them; Mason's executable directory is not automatically on the ordinary terminal PATH.

Verification completed on 2026-10-06:

- Full startup completed without a startup error.
- All 22 plugins installed; all 12 configured parsers loaded.
- Tree-sitter and its query health checks passed.
- Slang found `clk_div` from `clk_gen` without an `include`, with no diagnostics in the small test project.
- Native Telescope FZF and Blink's Lua completion backend passed checks.
- All nine configured Mason packages were installed and their executables were checked.
- Conda and the temporary Rust/build directory were absent after cleanup.

Mason health reports missing optional language ecosystems such as Cargo, Ruby, and PHP, plus no pip module in the system Python. Those warnings did not block this configuration: Python virtual environments have pip, and the configured packages installed successfully.

The shared custom config still selects the macOS-only Skim viewer for VimTeX. Linux LaTeX/PDF viewing was not configured or validated as part of this installation.

## Backups, cleanup, and rollback

Installation records are stored at:

```text
~/.local/state/nvim-native-install-1791302913/
  config-before.tar.gz              old config, including its Git metadata
  config-before-commit.txt          previous config revision
  verified-runtime-manifest.json    downloaded runtime archive names/checksums
  neovim-archive-sha256.txt          Neovim archive checksum
  installed-tool-sha256.txt         installed standalone tool checksums
  INSTALLATION.txt                  original installation notes
  TREE_SITTER_BUILD.txt             source/build and StyLua compatibility notes
  verification/                    test logs, health report, and test scripts
  old-lazy-plugins/                 archived obsolete Lazy-managed plugins
  old-lazy-state/                   archived Lazy state
```

The manifest's `/tmp/...` paths identify staging locations used during installation. They no longer exist; the active locations are in the directory map above. Verification scripts are historical records and some refer to deleted test fixtures; they are not a ready-to-run permanent test suite.

Old Lazy directories were **archived, not erased**. They are outside Neovim's active plugin path and are retained only for rollback. You can remove those two archived directories later if you no longer want the old installation. Conda's directory was removed. The temporary native build directory and temporary Rust environment were removed.

For a bad future Neovim upgrade, restore the launcher to a previously retained versioned Neovim directory. For a plugin regression, restore the desired Git-tracked lockfile and use `vim.pack.update(nil, { target = 'lockfile' })`, review, and restart. For a bad config change, restore the selected config revision while preserving your edits.

The pre-migration config backup uses the old Lazy setup and is not a full backup of every old external dependency. Conda was intentionally deleted, so restoring that config archive alone does not restore the old Conda-based editor. Extract the archive into a separate directory for inspection before deciding what to restore.

## Where to keep this guide

The local Mac copy is `~/.config/nvim/VM-INSTALLATION.md`, alongside your config so you can choose to commit it. The VM copy is `~/.local/share/doc/nvim/VM-INSTALLATION.md`, outside its Git checkout. Neither copy was committed or pushed automatically. After future changes, update this guide and copy it to the VM again so the inventory stays current.

## Codex CLI — added 2026-10-15

Codex CLI **0.163.0** was installed using the official standalone installer, after a successful disposable installation under `/tmp`. This addition was verified on `ece-lnx-10`, also RHEL 8.10, x86_64, glibc 2.28. The login hostname can route to different hosts; they share your NFS home directory.

Codex is separate from Neovim, Mason, and your configuration Git repository. It does not require the Node runtime installed for Neovim, npm, Conda, or sudo. The installed Linux executables are statically linked musl builds. The existing shell startup files were checked and remained unchanged.

### Codex directory map

| VM path | Purpose |
| --- | --- |
| `~/.local/bin/codex` | Command symlink created by the official installer |
| `~/.codex/packages/standalone/current` | Symlink selecting the active installed release |
| `~/.codex/packages/standalone/releases/0.163.0-x86_64-unknown-linux-musl/` | Complete installed package, including `bin/codex`, its code-mode host, bundled search tool, and Linux sandbox helper |
| `~/.codex/packages/standalone/auto-update-version` | Installer's record for the release following the latest channel |
| `~/.codex/` | Default Codex home for settings, account credentials after login, sessions, and runtime state |
| `~/.codex/config.toml` | User settings, if you create them; no custom settings were added during installation |
| `~/.codex/tmp/` | Symlink to `/run/user/753042448`, the user's private local runtime directory; avoids the NFS helper cleanup problem |
| `/run/user/753042448/arg0-linux/` | Codex temporary helper aliases and lock files on local tmpfs |
| `~/.local/state/codex-install-2026-10-15/` | Saved installer, its checksum, installation log, shell-file checksums, and diagnostic/sandbox logs |

Do not move just the main executable out of the release directory: the standalone package includes resources and helper programs. Let the installer manage the command and `current` symlinks.

### First login and use

In your SSH terminal:

```bash
hash -r
codex login --device-auth
```

Complete the displayed link/code flow in a browser on your Mac. Device-code login may need enabling in your ChatGPT security settings or by your workspace administrator. It avoids requiring a browser on the VM. See the official [headless authentication instructions](https://learn.chatgpt.com/docs/auth#login-on-headless-devices).

Then:

```bash
codex login status
cd /path/to/your/project
codex
```

Installation did not copy credentials from your Mac or sign you in. Codex account settings and cached credentials belong under `~/.codex`, outside the Neovim config repository. Treat any `auth.json` there as a password and do not commit it.

### Updating Codex

Use the installed CLI's update command:

```bash
codex update
codex --version
```

The official installation/update fallback is:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

That installer selects the appropriate standalone platform package, verifies its archive, installs a versioned release, and updates its symlinks. It does not update Neovim or Mason. During our installation we downloaded and inspected the installer before executing it; its saved copy is in the installation records. See the official [Codex CLI installation guide](https://learn.chatgpt.com/docs/codex/cli).

### Verification and current limits

These checks passed before account login:

- `codex --version` reported `codex-cli 0.163.0`.
- The built-in doctor found a consistent standalone installation and valid runtime resources.
- `codex sandbox -- /bin/echo CODEX_SANDBOX_PASSED` exited successfully using the default Linux sandbox. Sandboxing was not disabled.
- The authentication service and provider HTTP endpoints were reachable.
- Your `.bash_profile` and `.bashrc` matched their pre-installation checksums.

`codex doctor --summary --no-color --ascii` still reported missing credentials and a Responses WebSocket warning. No authenticated model request was made during installation. After signing in, rerun `codex doctor` and try a task to check actual account access and connectivity; HTTP reachability alone does not establish that every transport works. Diagnostic reports are saved in the installation-record directory.

### NFS temporary-directory fix — 2026-10-15

The original installation printed `failed to clean up stale arg0 temp dirs: Directory not empty (os error 39)` at startup. The cause was reproduced on the VM: deleting an open/locked `.lock` file on NFS leaves a temporary `.nfs...` file until the handle closes, so removing the containing directory fails with `ENOTEMPTY`. The same lock/unlink/removal test succeeded on the user's local runtime filesystem. Removing old empty directories alone suppressed the warning for only one startup.

The applied fix is a filesystem symlink:

```text
~/.codex/tmp -> /run/user/753042448
```

`/run/user/753042448` is the existing system-created runtime directory for your VM user. It is user-owned, mode `0700`, and stored on local tmpfs. Codex creates `arg0-linux/` beneath it. Only temporary helper files move there; configuration, authentication, installed releases, sessions, and other durable state stay under `~/.codex` on NFS. No wrapper, shell initialization change, binary patch, or sandbox relaxation was added.

The runtime directory is available during normal SSH login sessions and is recreated by the system after reboot/login. Its contents are disposable. This symlink uses your school account's numeric UID and is specific to these Linux hosts; it is not a symlink to add to the Mac configuration repository. A batch environment without the normal system-created runtime directory would need separate handling.

Three consecutive version checks, the default sandbox echo test, a normal login-shell startup, and your existing ChatGPT login status passed without the cleanup warning. The old temporary directory is retained at `~/.local/state/codex-install-2026-10-15/tmp-nfs-before-fix/`; test output and details are in `local-tmp-check.log` and `NFS-TEMP-FIX.txt` alongside it.

To undo this workaround with Codex stopped, remove only the `~/.codex/tmp` symlink and move the saved `tmp-nfs-before-fix` directory back to `~/.codex/tmp`. Do not delete the symlink's target. The original NFS cleanup warning may return after rollback.

### Reconnecting this chat to SSH

When a shared connection has expired, run this **in a terminal on your Mac**, log in normally, and leave it open:

```bash
ssh -M -S "$HOME/.ssh/ece-codex.sock" -o ControlPersist=10m nohgoering@linux.ece.ufl.edu
```

That creates a local SSH control socket so authorized commands in this chat can reuse your authenticated connection. It is a connection mechanism, not part of the Codex CLI installation. You do not need it just to run Codex yourself inside an ordinary SSH session.
