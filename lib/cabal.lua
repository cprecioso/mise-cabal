local M = {}

--- Prefix a shell command so cabal treats `dir` as its entire home (CABAL_DIR:
--- store, package index, config, and bins all go there). Setting it through the
--- shell keeps the rest of the environment (PATH, HOME, ...), unlike replacing
--- the process env. (env.setenv does not propagate to the cmd.exec subprocess.)
--- On Windows, `set VAR=value&& cmd` avoids quotes (which would nest under mise's
--- `cmd /c "..."`) and the trailing space that would otherwise enter the value.
--- @param dir string
--- @param args string
--- @return string
function M.call(dir, args)
    local cmd = require("cmd")

    return cmd.exec("cabal " .. args, {
        env = {
            CABAL_DIR = dir,
        }
    })
end

return M
