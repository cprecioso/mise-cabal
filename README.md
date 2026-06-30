# mise-cabal

A [mise](https://mise.jdx.dev) **backend plugin** that installs Haskell
command-line tools from [Hackage](https://hackage.haskell.org) using
`cabal-install`, the same way the built-in `npm:`, `gem:`, and `cargo:` backends
install tools from their ecosystems.

```bash
mise use cabal:pandoc-cli@latest
mise use cabal:hlint@3.8
mise x cabal:shellcheck -- --version
```

Each tool is referenced as `cabal:<hackage-package>@<version>`.

> Note: `cabal:` here is the backend prefix provided by this plugin. It is not
> the same as the `cabal` binary tool (which you install separately, see below).

## Requirements

This backend compiles tools from source, so it needs a working Haskell
toolchain (GHC + cabal-install) on `PATH`. The easiest way is to let mise manage
them. Add to your `mise.toml`:

```toml
[plugins]
"vfox:mise-ghcup" = "https://github.com/wasp-lang/mise-ghcup.git"

[tools]
"aqua:ghcup" = "latest"
"mise-ghcup:ghc" = "latest"
"aqua:haskell/cabal/cabal-install" = "latest"
```

`aqua:ghcup` is required because the mise-ghcup plugin declares
`depends = { "aqua:ghcup" }`; configuring that exact spec lets mise put ghcup on
the plugin's PATH. The cabal binary is referenced by its full
`aqua:haskell/cabal/cabal-install` spec rather than the bare `cabal`, because this
plugin registers the `cabal` backend name, which shadows the bare tool.
Alternatively, install GHC and cabal directly via
[GHCup](https://www.haskell.org/ghcup/).

## Install the plugin

```bash
mise plugin install cabal https://github.com/cprecioso/mise-cabal
```

## Usage

```bash
# List the versions available on Hackage
mise ls-remote cabal:hlint

# Install a specific version
mise install cabal:hlint@3.8

# Use it (in the current dir, or globally with -g)
mise use cabal:hlint@latest

# Run it
mise x cabal:hlint@latest -- --version
```

You can also add tools directly to a `mise.toml`:

```toml
[tools]
"cabal:pandoc-cli" = "latest"
"cabal:hlint" = "3.8"
```

## How it works

- **Listing** (`ls-remote`) queries the Hackage JSON API and returns the
  published versions of the package.
- **Installing** sets `CABAL_DIR` to the tool version's own mise install
  directory and runs `cabal install <package>-<version>`. Because `CABAL_DIR`
  relocates cabal's whole home, the build store, package index, and binaries all
  live inside that directory.
- **Data files** (used by tools like `pandoc` and `hlint`) live in the store
  right next to the binary, so they resolve automatically. There is no copying
  out of the store and no need for `embed_data_files`.
- **Running** simply puts the tool's `bin` directory on `PATH`.

## Limitations

- **Compiles from source.** First installs can be slow and require the Haskell
  toolchain. Each tool keeps its own `CABAL_DIR`, so the package index and build
  store are not shared across tools (more time and disk than a shared store, in
  exchange for fully self-contained, relocation-safe installs).
- **Executables only.** Library-only Hackage packages (no executable component)
  are not supported.

## Development

This repo is itself a mise project. `mise install` provisions the dev tooling
and the Haskell toolchain.

```bash
# Link this checkout as the `cabal` backend for local testing
mise plugin link --force cabal .

# Exercise the backend end to end (list + install + run `hello`)
mise run test

# Lint and format (stylua + luacheck + actionlint via hk)
mise run lint
mise run lint-fix

# Everything CI runs
mise run ci
```

Enable pre-commit hooks (optional):

```bash
hk install
```

Debug a single operation:

```bash
mise --debug install cabal:hello@latest
```

### Files

- `metadata.lua` - plugin metadata (`name`, `depends`, notes)
- `hooks/backend_list_versions.lua` - lists Hackage versions
- `hooks/backend_install.lua` - builds and installs a package
- `hooks/backend_exec_env.lua` - puts the tool's bin dir on `PATH`
- `mise.toml` - dev tooling, Haskell toolchain, and tasks
- `mise-tasks/test` - end-to-end test task
- `.github/workflows/ci.yml` - CI on Linux, macOS, and Windows

## Documentation

- [Backend Plugin Development](https://mise.jdx.dev/backend-plugin-development.html)
- [Lua modules reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Cabal user guide](https://cabal.readthedocs.io/en/stable/)

## License

MIT
