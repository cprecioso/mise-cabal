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

    -- Prerequisites mise checks before installing, so a missing one is installed
    -- or reported up front instead of blowing up halfway through a build.
    systemDependencies = {
        -- GHC links against gmp at runtime, and a missing libgmp is the classic
        -- "ghc: error while loading shared libraries" on minimal Linux images.
        -- `sharedlib` checks only run on Linux (auto-satisfied elsewhere), which
        -- is what we want: this is a Linux packaging problem.
        {
            sharedlib = "libgmp.so.10",
            packages = { apt = "libgmp-dev", dnf = "gmp-devel", pacman = "gmp", apk = "gmp-dev" },
        },

        -- Building any Hackage package shells out to a C compiler to link, so
        -- this is required and mise will install it when missing. No `brew`
        -- entry: on macOS the compiler comes from the Xcode command line tools,
        -- not from a package, so brew has nothing right to offer. The other
        -- platform to know about is Windows, where the Haskell toolchain brings
        -- its own MSYS2 and mise's `bin` lookup ignores PATHEXT, so this is
        -- reported as missing with no package manager to fix it. That is a
        -- warning only, it never fails the install.
        {
            bin = "gcc",
            packages = { apt = "build-essential", dnf = "gcc", pacman = "gcc", apk = "gcc" },
        },

        -- Only packages that bind to system C libraries need pkg-config, so this
        -- stays optional: mise mentions it when missing rather than installing
        -- it, which keeps `mise use mise-cabal:hlint` from pulling in a package
        -- that build will never touch.
        {
            bin = "pkg-config",
            optional = "Hackage packages that bind to system C libraries",
            packages = {
                brew = "pkgconf",
                apt = "pkg-config",
                dnf = "pkgconf-pkg-config",
                pacman = "pkgconf",
                apk = "pkgconf",
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
