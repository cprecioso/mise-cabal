-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    name = "mise-cabal",

    version = "1.0.0",

    description = "A mise backend plugin to install Haskell command-line tools from Hackage with cabal-install.",

    author = "Wasp",

    homepage = "https://github.com/wasp-lang/mise-cabal",

    license = "MIT",

    depends = { "ghc", "mise-ghcup:ghc", "cabal", "aqua:cabal", "mise-ghcup:cabal" },

    systemDependencies = {
        {
            bin = "curl",
            packages = { brew = "curl", apt = "curl", dnf = "curl", pacman = "curl", apk = "curl" },
        },
        {
            bin = "ghc",
            packages = { brew = "ghc", apt = "ghc", dnf = "ghc", pacman = "ghc", apk = "ghc" },
        },
        {
            bin = "cabal",
            packages = {
                brew = "cabal-install",
                apt = "cabal-install",
                dnf = "cabal-install",
                pacman = "cabal-install",
                apk = "cabal",
            },
        },
    },

    notes = {
        "Installs executable packages from Hackage, e.g. `mise use mise-cabal:pandoc-cli@latest`.",
        "Tools are compiled from source: installs can be slow and need a Haskell toolchain.",
        "Requires GHC and cabal on PATH.",
        "Each tool installs self-contained under its own CABAL_DIR.",
        "Library-only packages (no executable) are not supported.",
    },
}
