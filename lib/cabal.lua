local M = {}

--- Run `cabal <args>` with the tool's own CABAL_DIR so cabal treats `dir` as its
--- entire home: store, package index, config, and bins all live there, keeping
--- each tool's install self-contained. CABAL_DIR is passed through cmd.exec's
--- `env` option, which scopes it to this subprocess and leaves the rest of the
--- environment (PATH, HOME, ...) intact.
--- @param dir string
--- @param args string
--- @return string
function M.call(dir, args)
    local cmd = require("cmd")

    return cmd.exec("cabal " .. args, {
        env = {
            CABAL_DIR = dir,
        },
    })
end

return M
