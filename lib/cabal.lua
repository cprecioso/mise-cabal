local M = {}

--- Split a Cabal version string into its numeric components.
--- Cabal follows the PVP, so a version is a dot-separated list of non-negative
--- integers with anywhere from 1 to 4 components, e.g. "1", "1.2", "1.2.3.4".
--- @param version string
--- @return integer[]
local function parse(version)
    local parts = {}
    for component in tostring(version):gmatch("%d+") do
        parts[#parts + 1] = tonumber(component)
    end
    return parts
end

--- Compare two Cabal version strings, returning -1, 0, or 1 (a < b, a == b,
--- a > b). The built-in semver.compare assumes the 3-component
--- MAJOR.MINOR.PATCH shape and mis-sorts Cabal's 1-to-4-component versions, so
--- we compare component by component ourselves, treating any missing trailing
--- component as 0 (so "1.2" == "1.2.0").
--- @param a string
--- @param b string
--- @return integer
function M.compare_versions(a, b)
    local pa = parse(a)
    local pb = parse(b)

    local n = math.max(#pa, #pb)
    for i = 1, n do
        local na = pa[i] or 0
        local nb = pb[i] or 0
        if na ~= nb then
            return na < nb and -1 or 1
        end
    end

    return 0
end

--- Sort Cabal version strings ascending (oldest -> newest), as mise expects.
--- Returns a new sorted list and leaves the input untouched.
--- @param versions string[]
--- @return string[]
function M.sort_versions(versions)
    local sorted = {}
    for i, v in ipairs(versions) do
        sorted[i] = v
    end
    table.sort(sorted, function(a, b)
        return M.compare_versions(a, b) < 0
    end)
    return sorted
end

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
