local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

local Registry = { byKey = {}, order = {}, list = {}, bootstrapped = false }
Zone.ProvenanceRegistry = Registry

function Zone.ValidateZoneProvenance(definition)
    if type(definition) ~= "table" then return false, "Zone provenance definition must be a table." end
    local ok, reason = Zone.ValidateKey(definition.key, "Zone provenance")
    if not ok then return false, reason end
    if type(definition.label) ~= "string" or definition.label == "" then return false, "Zone provenance " .. definition.key .. " has no label." end
    ok, reason = Zone.ValidateAliasList(definition.match or definition.locationAliases, "Zone provenance " .. definition.key)
    if not ok then return false, reason end
    ok, reason = Zone.ValidateAliasList(definition.origins or definition.originVocabulary, "Zone provenance " .. definition.key .. " origins")
    if not ok then return false, reason end
    local minimum = definition.minExpansionID
    local maximum = definition.maxExpansionID
    if minimum ~= nil and (type(minimum) ~= "number" or minimum < 0) then return false, "Zone provenance " .. definition.key .. " has invalid minimum expansion." end
    if maximum ~= nil and (type(maximum) ~= "number" or maximum < 0) then return false, "Zone provenance " .. definition.key .. " has invalid maximum expansion." end
    if minimum ~= nil and maximum ~= nil and minimum > maximum then return false, "Zone provenance " .. definition.key .. " has reversed expansion bounds." end
    return true
end

function Zone.RegisterZoneProvenance(profileKey, definition)
    profileKey = profileKey or (type(definition) == "table" and definition.key)
    if Registry.byKey[profileKey] then return false, "Zone provenance " .. tostring(profileKey) .. " is already registered." end
    definition = Zone.Copy(definition or {})
    definition.key = profileKey
    definition.match = definition.match or definition.locationAliases or {}
    definition.locationAliases = definition.match
    definition.origins = definition.origins or definition.originVocabulary or {}
    definition.originVocabulary = definition.origins
    definition.registrationOrder = #Registry.order + 1
    local ok, reason = Zone.ValidateZoneProvenance(definition)
    if not ok then return false, reason end
    Registry.byKey[profileKey] = definition
    Registry.order[#Registry.order + 1] = profileKey
    Registry.list[#Registry.list + 1] = definition
    return true, definition
end

function Zone.GetZoneProvenance(profileKey) return Registry.byKey[profileKey] end
function Zone.GetZoneProvenanceProfiles() return Zone.Copy(Registry.list) end
function Zone.GetZoneProvenanceRegistryVersion() return Zone.PROVENANCE_REGISTRY_VERSION end

function Zone.ResolveZoneProvenance(locationFacts, eraMax)
    local text = P.BuildContextText(locationFacts)
    eraMax = tonumber(eraMax)
    if eraMax == nil then eraMax = select(1, ZoneStyle.ResolveEra(locationFacts)) end
    for _, profile in ipairs(Registry.list) do
        local inBounds = (profile.minExpansionID == nil or eraMax >= profile.minExpansionID)
            and (profile.maxExpansionID == nil or eraMax <= profile.maxExpansionID)
        if inBounds then
            local matched, alias = P.TextMatchesAny(text, profile.match)
            if matched then return profile, profile.key, alias end
        end
    end
    return nil
end

local function RebuildOriginMarkers()
    P.provenanceByKey = Registry.byKey
    P.provenanceOriginMarkers = {}
    P.provenanceOriginMarkerByText = {}
    for _, profile in ipairs(Registry.list) do
        for _, phrase in ipairs(profile.origins or {}) do
            local normalized = P.Normalize(phrase)
            if normalized ~= "" then
                local marker = P.provenanceOriginMarkerByText[normalized]
                if not marker then
                    marker = { text = normalized, profile = profile, profileKeys = {} }
                    P.provenanceOriginMarkerByText[normalized] = marker
                    P.provenanceOriginMarkers[#P.provenanceOriginMarkers + 1] = marker
                end
                marker.profileKeys[profile.key] = true
            end
        end
    end
end

function Zone.BootstrapProvenanceRegistry()
    if Registry.bootstrapped then return true end
    for _, definition in ipairs(ZoneStyle.provenanceProfiles or {}) do
        local ok, reason = Zone.RegisterZoneProvenance(definition.key, definition)
        if not ok then return false, reason end
    end
    ZoneStyle.provenanceProfiles = Registry.list
    RebuildOriginMarkers()
    Registry.bootstrapped = true
    return true
end

assert(Zone.BootstrapProvenanceRegistry())
