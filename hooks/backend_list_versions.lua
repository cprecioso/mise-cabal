--- Lists available Hackage versions for a package (ascending order).
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx
--- @return BackendListVersionsResult
function PLUGIN:BackendListVersions(ctx)
    local http = require("http")
    local json = require("json")
    local cabal = require("cabal")

    local tool = ctx.tool
    if not tool or tool == "" then
        error("mise-cabal: package name cannot be empty")
    end

    -- The Hackage "preferred" endpoint returns JSON with two arrays:
    --   "normal-version"     : usable versions
    --   "deprecated-version" : versions the maintainer discourages (still installable)
    -- NOTE: http yields internally, so it must NOT be wrapped in pcall. Use the
    -- try_ variant, which returns (response, err) instead of raising on transport
    -- failures (timeout, DNS, connection refused).
    local url = "https://hackage.haskell.org/package/" .. tool .. "/preferred"
    local resp, err = http.try_get({ url = url, headers = { ["Accept"] = "application/json" } })
    if err ~= nil then
        error("mise-cabal: failed to reach Hackage for '" .. tool .. "': " .. tostring(err))
    end
    if resp.status_code == 404 then
        error("mise-cabal: package '" .. tool .. "' not found on Hackage")
    end
    if resp.status_code ~= 200 then
        error("mise-cabal: Hackage returned HTTP " .. tostring(resp.status_code) .. " for '" .. tool .. "'")
    end

    local data = json.decode(resp.body)
    if type(data) ~= "table" then
        error("mise-cabal: could not parse Hackage response for '" .. tool .. "'")
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
        error("mise-cabal: no versions found for '" .. tool .. "'")
    end

    -- Sort ascending (oldest -> newest), as mise expects. We use our own Cabal
    -- version comparison because the built-in semver.sort assumes 3-component
    -- versions and mis-orders Cabal's 1-to-4-component (PVP) versions.
    return { versions = cabal.sort_versions(versions) }
end
