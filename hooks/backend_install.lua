--- Installs a Hackage executable package via `cabal install`.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx
--- @return BackendInstallResult
function PLUGIN:BackendInstall(ctx)
    local cabal = require("cabal")

    cabal.call(ctx.install_path, "update") -- A fresh per-tool CABAL_DIR has no package index yet.
    cabal.call(ctx.install_path, "install " .. ctx.tool .. "-" .. ctx.version)

    return {}
end
