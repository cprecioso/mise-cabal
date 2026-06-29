--- Lists available Hackage versions for a package (ascending order).
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local http = require("http")
    local json = require("json")
    local semver = require("semver")

    local tool = ctx.tool
    if not tool or tool == "" then
        error("cabal: package name cannot be empty")
    end

    -- The Hackage "preferred" endpoint returns JSON with two arrays:
    --   "normal-version"     : usable versions
    --   "deprecated-version" : versions the maintainer discourages (still installable)
    -- NOTE: http.get yields internally, so it must NOT be wrapped in pcall. It
    -- returns (response, err) instead of raising.
    local url = "https://hackage.haskell.org/package/" .. tool .. "/preferred"
    local resp, err = http.get({ url = url, headers = { ["Accept"] = "application/json" } })
    if err ~= nil then
        error("cabal: failed to reach Hackage for '" .. tool .. "': " .. tostring(err))
    end
    if resp.status_code == 404 then
        error("cabal: package '" .. tool .. "' not found on Hackage")
    end
    if resp.status_code ~= 200 then
        error("cabal: Hackage returned HTTP " .. tostring(resp.status_code) .. " for '" .. tool .. "'")
    end

    local data = json.decode(resp.body)
    if type(data) ~= "table" then
        error("cabal: could not parse Hackage response for '" .. tool .. "'")
    end

    -- Include deprecated versions too, so a previously pinned version stays resolvable.
    local versions = {}
    local function append(list)
        if type(list) == "table" then
            for _, v in ipairs(list) do
                versions[#versions + 1] = v
            end
        end
    end
    append(data["normal-version"])
    append(data["deprecated-version"])

    if #versions == 0 then
        error("cabal: no versions found for '" .. tool .. "'")
    end

    -- Built-in semver sort (ascending), as mise expects oldest -> newest.
    return { versions = semver.sort(versions) }
end
