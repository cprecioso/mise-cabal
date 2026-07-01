--- Sets up environment variables so the installed executables are found.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
---
--- @param ctx BackendExecEnvCtx
--- @return BackendExecEnvResult
function PLUGIN:BackendExecEnv(ctx)
    local cabal = require("cabal")

    local installdir = cabal.call(ctx.install_path, "path -v0 --installdir")

    return {
        env_vars = {
            -- We only add the bin dir to PATH. We deliberately do NOT export
            -- CABAL_DIR at runtime: that would hijack the user's own `cabal`
            -- usage while this tool is active.
            { key = "PATH", value = installdir },
        },
    }
end
