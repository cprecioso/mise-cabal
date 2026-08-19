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

    -- Prerequisites mise checks before installing, so a missing one is reported
    -- up front instead of halfway through a from-source build.
    systemDependencies = {
        -- GHC links against gmp at runtime, and a missing libgmp is the classic
        -- "ghc: error while loading shared libraries" on minimal Linux images.
        -- `sharedlib` checks only run on Linux (auto-satisfied elsewhere), which
        -- is what we want: this is a Linux packaging problem.
        {
            sharedlib = "libgmp.so.10",
            packages = { apt = "libgmp-dev", dnf = "gmp-devel", pacman = "gmp", apk = "gmp-dev" },
        },

        -- Building a Hackage package shells out to a C compiler to link, and
        -- packages that bind to C libraries look them up with pkg-config. These
        -- are marked optional on purpose: they are genuinely needed on Linux and
        -- macOS, but mise has no per-OS filter on these entries and resolves
        -- `bin` without PATHEXT, so a required check would false-alarm on
        -- Windows. Optional entries never prompt or fail, they just print a hint
        -- when missing.
        {
            bin = "gcc",
            optional = "the C toolchain GHC uses to compile and link",
            packages = { apt = "build-essential", dnf = "gcc", pacman = "gcc", apk = "gcc" },
        },
        {
            bin = "pkg-config",
            optional = "Hackage packages that bind to system C libraries",
            packages = { apt = "pkg-config", dnf = "pkgconf-pkg-config", pacman = "pkgconf", apk = "pkgconf" },
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
