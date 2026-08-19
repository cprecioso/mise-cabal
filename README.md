# mise-cabal

A [mise](https://mise.jdx.dev) backend plugin that installs Haskell command-line tools from [Hackage](https://hackage.haskell.org) using `cabal-install`, the same way the built-in `npm:`, `gem:`, and `cargo:` backends install tools from their ecosystems.

```bash
mise use mise-cabal:pandoc-cli@latest
mise use mise-cabal:hlint@3.8
mise x mise-cabal:shellcheck -- --version
```

Each tool is referenced as `mise-cabal:<hackage-package>@<version>`.

> Note: `mise-cabal:` here is the backend prefix provided by this plugin. It is not the same as the `cabal` binary tool (which you install separately, see below).

## Requirements

- mise `2026.7.3` or newer

We compile tools from source, so a working Haskell toolchain is needed:

- Cabal
- GHC

The easiest way is to let mise manage everything, in conjunction with the `mise-ghcup` plugin. Add to your `mise.toml`:

```toml
min_version = "2026.7.3"

[tools]
"cabal" = "latest"
"ghcup" = "latest"
"mise-ghcup:ghc" = "latest"

[plugins]
"vfox-backend:mise-ghcup" = "https://github.com/wasp-lang/mise-ghcup.git"

[settings]
experimental = true # Needed for using backend plugins like mise-ghcup and mise-cabal
```

## Install the plugin

```bash
mise plugin install https://github.com/wasp-lang/mise-cabal
```

## Usage

In your `mise.toml` file:

```toml
[plugins]
"vfox-backend:mise-cabal" = "https://github.com/wasp-lang/mise-cabal.git"

[settings]
experimental = true # Needed for using backend plugins like mise-cabal
```

Then you can use it freely:

```bash
# List the versions available on Hackage
mise ls-remote mise-cabal:hlint

# Install a specific version
mise install mise-cabal:hlint@3.8

# Use it (in the current dir, or globally with -g)
mise use mise-cabal:hlint@latest

# Run it
mise x mise-cabal:hlint@latest -- --version
```

You can also add tools directly to a `mise.toml`:

```toml
[tools]
"mise-cabal:pandoc-cli" = "latest"
"mise-cabal:hlint" = "3.8"
```

## How it works

- **Listing** (`ls-remote`) queries the Hackage JSON API and returns the published versions of the package.
- **Installing** sets `CABAL_DIR` to the tool version's own mise install directory and runs `cabal install <package>-<version>`. Because `CABAL_DIR` relocates cabal's whole home, the build store, package index, and binaries all live inside that directory.
- **Data files** (used by tools like `pandoc` and `hlint`) live in the store right next to the binary, so they resolve automatically. There is no copying out of the store and no need for `embed_data_files`.
- **Running** simply puts the tool's `bin` directory on `PATH`.

## Limitations

- **Compiles from source.** First installs can be slow and require the Haskell toolchain. Each tool keeps its own `CABAL_DIR`, so the package index and build store are not shared across tools (more time and disk than a shared store, in exchange for fully self-contained, relocation-safe installs).
- **Executables only.** Library-only Hackage packages (no executable component) are not supported.

## Development

This repo is itself a mise project. `mise install` provisions the dev tooling and the Haskell toolchain.

```bash
# Link this checkout as the `mise-cabal` backend for local testing
mise plugin link --force mise-cabal .

# Lint and format (stylua + lua-language-server + actionlint via hk)
mise run lint
mise run lint-fix
```

Enable pre-commit hooks (optional):

```bash
hk install
```

Debug a single operation:

```bash
mise --debug install mise-cabal:hello@latest
```

### Files

- `metadata.lua` - plugin metadata (`name`, `depends`, notes)
- `hooks/backend_list_versions.lua` - lists Hackage versions
- `hooks/backend_install.lua` - builds and installs a package
- `hooks/backend_exec_env.lua` - puts the tool's bin dir on `PATH`
- `lib/cabal.lua` - runs a command with the tool's isolated `CABAL_DIR`
- `mise.toml` - dev tooling, Haskell toolchain, and tasks
- `mise-tasks/test` - end-to-end test task
- `.github/workflows/ci.yml` - CI on Linux, macOS, and Windows

## Documentation

- [Backend Plugin Development](https://mise.jdx.dev/backend-plugin-development.html)
- [Lua modules reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Cabal user guide](https://cabal.readthedocs.io/en/stable/)

## License

MIT
