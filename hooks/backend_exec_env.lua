--- Sets up environment variables so the installed executables are found.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
---
--- We only add the bin dir to PATH. We deliberately do NOT export CABAL_DIR at
--- runtime: that would hijack the user's own `cabal` usage while this tool is
--- active. Data files resolve via the absolute store paths baked into the binary.
--- @param ctx BackendExecEnvCtx
--- @return BackendExecEnvResult
function PLUGIN:BackendExecEnv(ctx)
    local file = require("file")
    return {
        env_vars = {
            { key = "PATH", value = file.join_path(ctx.install_path, "bin") },
        },
    }
end
