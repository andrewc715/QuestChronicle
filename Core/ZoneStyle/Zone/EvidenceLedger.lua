local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

local VALID_CHANNELS = {
    MAP_ID = true, MAP_NAME = true, SUBZONE_NAME = true, ZONE_NAME = true, MAP_TRAIL = true,
    PROFILE_ALIAS = true, ERA_RULE = true, PROVENANCE_ALIAS = true, STARTING_ZONE_RULE = true,
    PARENT_PROFILE = true, REGION_FALLBACK = true, AZEROTH_FALLBACK = true,
    PROFILE_DEFINITION = true, VISUAL_DESCRIPTOR = true, SOURCE_PROVENANCE = true,
    SOURCE_METADATA = true, TRANSMOG_SET = true, CURATED_ZONE_TAG = true,
}

function Zone.NewEvidenceLedger()
    return { entries = {}, warnings = {} }
end

function Zone.AddEvidence(ledger, entry)
    if type(ledger) ~= "table" then return nil end
    entry = type(entry) == "table" and entry or {}
    local channel = tostring(entry.channel or "")
    if not VALID_CHANNELS[channel] then
        ledger.warnings[#ledger.warnings + 1] = "Unknown evidence channel: " .. channel
        return nil
    end
    local normalized = {
        channel = channel,
        subject = entry.subject,
        value = entry.value,
        matchedText = entry.matchedText,
        matchedAlias = entry.matchedAlias,
        sourceLevel = entry.sourceLevel,
        confidence = math.max(0, math.min(1, tonumber(entry.confidence) or 0)),
        registryKey = entry.registryKey,
        index = #ledger.entries + 1,
    }
    ledger.entries[#ledger.entries + 1] = normalized
    return normalized
end

function Zone.CopyEvidence(ledger)
    return Zone.CopyPrimitive(ledger or { entries = {}, warnings = {} })
end

function Zone.GetEvidenceEntries(snapshot)
    return Zone.CopyPrimitive(snapshot and snapshot.evidence or {}) or {}
end

function ZoneStyle.GetZoneEvidence(snapshot)
    snapshot = snapshot or (ZoneStyle.GetZoneContextSnapshot and ZoneStyle.GetZoneContextSnapshot())
    return Zone.GetEvidenceEntries(snapshot)
end
