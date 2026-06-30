-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: backend name users reference as `cabal:<package>`
    name = "cabal",

    -- Required: plugin version (not the tool versions)
    version = "1.0.0",

    -- Required: what this backend manages
    description = "A mise backend plugin to install Haskell command-line tools from Hackage with cabal-install.",

    -- Required: maintainer
    author = "cprecioso",

    -- Optional: plugin repository
    homepage = "https://github.com/cprecioso/mise-cabal",

    -- Optional: license
    license = "MIT",

    -- Tools whose bin paths are put on PATH during install hooks when configured.
    -- cabal compiles from source, so both the compiler and cabal-install are needed.
    -- Full backend specs are used because the bare name `ghc` resolves to the
    -- registry entry (conda/asdf), not the mise-ghcup tool used here.
    depends = { "mise-ghcup:ghc", "cabal" },

    -- Optional: user-facing notes
    notes = {
        "Installs executable packages from Hackage, e.g. `mise use cabal:pandoc-cli@latest`.",
        "Tools are compiled from source: installs can be slow and need a Haskell toolchain.",
        "Requires GHC and cabal on PATH. Easiest via mise: the mise-ghcup plugin with tools `mise-ghcup:ghc` + `cabal`.",
        "Each tool installs self-contained under its own CABAL_DIR, so data-file tools (pandoc, hlint) work without extra steps.",
        "Library-only packages (no executable) are not supported.",
    },
}
