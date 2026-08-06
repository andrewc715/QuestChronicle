local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

local Registry = { byID = {}, order = {}, list = {}, bootstrapped = false }
Zone.StartingZoneRegistry = Registry

function Zone.ValidateStartingZoneCase(definition)
    if type(definition) ~= "table" then return false, "Starting-zone case must be a table." end
    for _, field in ipairs({ "caseID", "race", "zone", "subzone", "provenanceKey" }) do
        if type(definition[field]) ~= "string" or definition[field] == "" then
            return false, "Starting-zone case has invalid " .. field .. "."
        end
    end
    if type(definition.maxExpansionID) ~= "number" or definition.maxExpansionID < 0 then
        return false, "Starting-zone case " .. definition.caseID .. " has invalid expansion ceiling."
    end
    if Zone.ProvenanceRegistry and not Zone.ProvenanceRegistry.byKey[definition.provenanceKey] then
        return false, "Starting-zone case " .. definition.caseID .. " references unknown provenance " .. definition.provenanceKey .. "."
    end
    return true
end

function Zone.RegisterStartingZoneCase(caseID, definition)
    if Registry.byID[caseID] then return false, "Starting-zone case " .. tostring(caseID) .. " is already registered." end
    definition = Zone.Copy(definition or {})
    definition.caseID = caseID
    definition.registrationOrder = #Registry.order + 1
    local ok, reason = Zone.ValidateStartingZoneCase(definition)
    if not ok then return false, reason end
    Registry.byID[caseID] = definition
    Registry.order[#Registry.order + 1] = caseID
    Registry.list[#Registry.list + 1] = definition
    return true, definition
end

function Zone.GetStartingZoneCases() return Zone.Copy(Registry.list) end

function Zone.ResolveStartingZoneOverride(locationFacts, characterFacts)
    local zone = P.Normalize(locationFacts and locationFacts.zone)
    local subzone = P.Normalize(locationFacts and locationFacts.subzone)
    local race = P.Normalize(characterFacts and (characterFacts.race or characterFacts.raceName))
    for _, definition in ipairs(Registry.list) do
        local raceMatches = race == "" or race == P.Normalize(definition.race)
        if raceMatches and zone == P.Normalize(definition.zone) and subzone == P.Normalize(definition.subzone) then
            return definition
        end
    end
    return nil
end

function Zone.BootstrapStartingZoneRegistry()
    if Registry.bootstrapped then return true end
    for index, definition in ipairs(ZoneStyle.startingZoneCases or {}) do
        local caseID = string.format("START-%02d-%s", index, P.Normalize(definition.race):gsub(" ", "_"))
        local ok, reason = Zone.RegisterStartingZoneCase(caseID, definition)
        if not ok then return false, reason end
    end
    ZoneStyle.startingZoneCases = Registry.list
    Registry.bootstrapped = true
    return true
end

assert(Zone.BootstrapStartingZoneRegistry())
