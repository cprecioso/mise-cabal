--- Platform-aware shell quoting (paths can contain spaces).
--- @param s string
--- @return string
local function shquote(s)
    s = tostring(s)
    if RUNTIME.osType == "windows" then
        return '"' .. s .. '"'
    end
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

--- Create a directory (and parents) cross-platform; no-op if it already exists.
--- @param path string
local function ensure_dir(path)
    local file = require("file")
    local cmd = require("cmd")
    if file.exists(path) then
        return
    end
    if RUNTIME.osType == "windows" then
        cmd.exec("mkdir " .. shquote(path)) -- cmd.exe md creates intermediate dirs
    else
        cmd.exec("mkdir -p " .. shquote(path))
    end
end

--- Prefix a shell command so cabal treats `dir` as its entire home (CABAL_DIR:
--- store, package index, config, and bins all go there). Setting it through the
--- shell keeps the rest of the environment (PATH, HOME, ...), unlike replacing
--- the process env. (env.setenv does not propagate to the cmd.exec subprocess.)
--- @param dir string
--- @param command string
--- @return string
local function with_cabal_dir(dir, command)
    if RUNTIME.osType == "windows" then
        return 'set "CABAL_DIR=' .. dir .. '" && ' .. command
    end
    return "CABAL_DIR=" .. shquote(dir) .. " " .. command
end

--- Whether an executable is available on PATH. Never raises, so we can report a
--- friendly message. mise's cmd.exec yields and therefore cannot be wrapped in
--- pcall; instead the probe always exits 0 and we inspect its output.
--- @param name string
--- @return boolean
local function have_tool(name)
    local cmd = require("cmd")
    local probe
    if RUNTIME.osType == "windows" then
        probe = "where " .. name .. " >NUL 2>NUL && echo HAVE || echo MISSING"
    else
        probe = "command -v " .. name .. " >/dev/null 2>&1 && echo HAVE || echo MISSING"
    end
    local out = cmd.exec(probe)
    return type(out) == "string" and out:find("HAVE", 1, true) ~= nil
end

--- Installs a Hackage executable package via `cabal install`.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx  (also has ctx.download_path, ctx.options at runtime)
--- @return BackendInstallResult
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local file = require("file")

    local tool, version, install_path = ctx.tool, ctx.version, ctx.install_path
    if not tool or tool == "" then
        error("cabal: package name cannot be empty")
    end
    if not version or version == "" then
        error("cabal: version cannot be empty")
    end
    if not install_path or install_path == "" then
        error("cabal: install_path cannot be empty")
    end

    -- Toolchain must be present: cabal compiles Hackage packages from source.
    if not have_tool("cabal") then
        error(
            "cabal: 'cabal' not found on PATH. This backend compiles tools from source and needs GHC + cabal.\n"
                .. "Easiest via mise, add to your config:\n"
                .. '  [plugins]\n  "vfox:mise-ghcup" = "https://github.com/wasp-lang/mise-ghcup.git"\n'
                .. '  [tools]\n  "aqua:ghcup" = "latest"\n  "mise-ghcup:ghc" = "latest"\n  "aqua:haskell/cabal/cabal-install" = "latest"\n'
                .. "Or install GHCup: https://www.haskell.org/ghcup/"
        )
    end
    if not have_tool("ghc") then
        error(
            "cabal: 'ghc' not found on PATH. A GHC compiler is required "
                .. "(e.g. mise-ghcup:ghc or https://www.haskell.org/ghcup/)."
        )
    end

    -- Self-contained install: point cabal's whole home (store, index, bins, and
    -- each package's data files) at THIS version's dir, so data files resolve from
    -- the store beside the binary. No --install-method=copy, no embed flag.
    local bin_dir = file.join_path(install_path, "bin")
    ensure_dir(bin_dir)

    -- A fresh per-tool CABAL_DIR has no package index yet, so cabal update is required.
    -- cwd = install_path keeps cabal out of any cabal.project in the user's shell cwd.
    -- (cmd.exec yields, so it cannot be pcall'd; a failure raises and mise reports it.)
    cmd.exec(with_cabal_dir(install_path, "cabal update"), { cwd = install_path })

    -- Default install method (symlink on unix, copy on Windows). --installdir pins the
    -- bin dir we put on PATH; data files come from the store under CABAL_DIR.
    local install_cmd = "cabal install "
        .. tool
        .. "-"
        .. version
        .. " --overwrite-policy=always --installdir="
        .. shquote(bin_dir)
    cmd.exec(with_cabal_dir(install_path, install_cmd), { cwd = install_path })

    -- Safety net: a successful install must place at least one executable here.
    -- Catches library-only packages if cabal did not already error out.
    local listing
    if RUNTIME.osType == "windows" then
        listing = cmd.exec("dir /b " .. shquote(bin_dir) .. " 2>NUL || echo.")
    else
        listing = cmd.exec("ls -1 " .. shquote(bin_dir) .. " 2>/dev/null || echo")
    end
    if type(listing) ~= "string" or listing:gsub("%s", "") == "" then
        error(
            "cabal: no executable was produced for "
                .. tool
                .. "-"
                .. version
                .. " (is it a library-only package, or did the build fail?)"
        )
    end

    return {}
end
