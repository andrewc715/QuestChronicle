local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

local Registry = {
    byKey = {}, order = {}, aliases = {}, collisions = {}, bootstrapped = false,
}
Zone.ProfileRegistry = Registry

local function ValidateWeightMap(values, label)
    if values == nil then return true end
    if type(values) ~= "table" then return false, label .. " must be a table." end
    for key, value in pairs(values) do
        if type(key) ~= "string" or key == "" or type(value) ~= "number" or value < 0 or value > 1 then
            return false, label .. " contains an invalid weight for " .. tostring(key) .. "."
        end
    end
    return true
end

function Zone.ValidateZoneProfile(definition)
    if type(definition) ~= "table" then return false, "Zone profile must be a table." end
    local ok, reason = Zone.ValidateKey(definition.key, "Zone profile")
    if not ok then return false, reason end
    if type(definition.label) ~= "string" or definition.label == "" then return false, "Zone profile " .. definition.key .. " has no label." end
    if type(definition.description) ~= "string" or definition.description == "" then return false, "Zone profile " .. definition.key .. " has no description." end
    if type(definition.seed) ~= "number" then return false, "Zone profile " .. definition.key .. " has no numeric seed." end
    ok, reason = Zone.ValidateAliasList(definition.match or definition.locationAliases, "Zone profile " .. definition.key)
    if not ok then return false, reason end
    local seen = {}
    for _, alias in ipairs(definition.match or definition.locationAliases or {}) do
        local normalized = P.Normalize(alias)
        if seen[normalized] then return false, "Zone profile " .. definition.key .. " repeats alias " .. normalized .. "." end
        seen[normalized] = true
    end
    for _, field in ipairs({ "culture", "climate", "terrain", "palette", "material", "finish", "motif", "magic", "silhouette", "avoids" }) do
        ok, reason = ValidateWeightMap(definition.style and definition.style[field], "Zone profile " .. definition.key .. " style." .. field)
        if not ok then return false, reason end
    end
    if definition.parentProfileKey ~= nil and type(definition.parentProfileKey) ~= "string" then
        return false, "Zone profile " .. definition.key .. " has an invalid parent profile key."
    end
    return true
end

local function RegisterAlias(definition, alias)
    local normalized = P.Normalize(alias)
    if normalized == "" then return end
    local owners = Registry.aliases[normalized]
    if not owners then owners = {} Registry.aliases[normalized] = owners end
    if #owners > 0 then Registry.collisions[normalized] = Registry.collisions[normalized] or Zone.Copy(owners) end
    owners[#owners + 1] = definition.key
    if Registry.collisions[normalized] then Registry.collisions[normalized][#Registry.collisions[normalized] + 1] = definition.key end
end

function Zone.RegisterZoneProfile(profileKey, definition)
    profileKey = profileKey or (type(definition) == "table" and definition.key)
    if Registry.byKey[profileKey] then return false, "Zone profile " .. tostring(profileKey) .. " is already registered." end
    definition = Zone.Copy(definition or {})
    definition.key = profileKey
    definition.match = definition.match or definition.locationAliases or {}
    definition.locationAliases = definition.match
    definition.legacyKeywords = definition.legacyKeywords or definition.keywords or {}
    definition.legacyAvoid = definition.legacyAvoid or definition.avoid or {}
    definition.keywords = definition.legacyKeywords
    definition.avoid = definition.legacyAvoid
    local canonical = Zone.GetCanonicalStyle(profileKey)
    definition.style = {
        culture = canonical.cultures or {}, climate = canonical.climates or {}, terrain = canonical.terrain or {},
        palette = canonical.palette or {}, material = canonical.materials or {}, finish = canonical.finishes or {},
        motif = canonical.motifs or {}, magic = canonical.magic or {}, silhouette = canonical.silhouette or {},
        avoids = canonical.avoids or {},
    }
    local ok, reason = Zone.ValidateZoneProfile(definition)
    if not ok then return false, reason end
    Registry.byKey[profileKey] = definition
    Registry.order[#Registry.order + 1] = profileKey
    for _, alias in ipairs(definition.match) do RegisterAlias(definition, alias) end
    return true, definition
end

function Zone.GetZoneProfile(profileKey) return Registry.byKey[profileKey] end
function Zone.GetZoneProfiles()
    local result = {}
    for _, key in ipairs(Registry.order) do result[#result + 1] = Zone.Copy(Registry.byKey[key]) end
    return result
end
function Zone.GetZoneProfileRegistryVersion() return Zone.PROFILE_REGISTRY_VERSION end

function Zone.ResolveZoneProfile(locationFacts)
    local parts = { locationFacts and locationFacts.subzone, locationFacts and locationFacts.zone, locationFacts and locationFacts.mapName }
    for _, name in ipairs(locationFacts and locationFacts.mapTrail or {}) do parts[#parts + 1] = name end
    local haystack = " " .. P.Normalize(table.concat(parts, " ")) .. " "
    for _, profileKey in ipairs(Registry.order) do
        if profileKey ~= "azeroth" then
            local profile = Registry.byKey[profileKey]
            for _, alias in ipairs(profile.match or {}) do
                local needle = P.Normalize(alias)
                if needle ~= "" and haystack:find(" " .. needle .. " ", 1, true) then return profile, profileKey, alias end
            end
        end
    end
    return Registry.byKey.azeroth, "azeroth", nil
end

function Zone.BootstrapProfileRegistry()
    if Registry.bootstrapped then return true end
    local legacyProfiles = ZoneStyle.profiles or {}
    local legacyOrder = P.profileOrder or {}
    for _, profileKey in ipairs(legacyOrder) do
        local definition = legacyProfiles[profileKey]
        if not definition then return false, "Missing legacy Zone profile " .. tostring(profileKey) .. "." end
        local ok, reason = Zone.RegisterZoneProfile(profileKey, definition)
        if not ok then return false, reason end
    end
    if legacyProfiles.azeroth then
        local ok, reason = Zone.RegisterZoneProfile("azeroth", legacyProfiles.azeroth)
        if not ok then return false, reason end
    end
    for _, definition in pairs(Registry.byKey) do
        if definition.parentProfileKey and not Registry.byKey[definition.parentProfileKey] then
            return false, "Zone profile " .. definition.key .. " references unknown parent " .. definition.parentProfileKey .. "."
        end
    end
    ZoneStyle.profiles = Registry.byKey
    -- P.profileOrder remains the exact legacy selection order and deliberately
    -- excludes the explicit Azeroth fallback entry.
    Registry.bootstrapped = true
    return true
end

assert(Zone.BootstrapProfileRegistry())
