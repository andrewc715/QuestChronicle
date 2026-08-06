local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle

Generation.ZoneContextPolicy = {
    BuildModeContext = function()
        return ZoneStyle.GetZoneContextSnapshot and ZoneStyle.GetZoneContextSnapshot() or nil
    end,
    BuildContextSeed = function(snapshot)
        return snapshot and snapshot.fingerprint or nil
    end,
    DescribeContext = function(snapshot)
        if not snapshot then return "Zone context unavailable" end
        return string.format("%s • Through %s • %s", tostring(snapshot.identity and snapshot.identity.label), tostring(snapshot.era and snapshot.era.shortLabel), tostring(snapshot.provenance and snapshot.provenance.label))
    end,
    ValidateContext = function(snapshot)
        return type(snapshot) == "table" and tonumber(snapshot.format) == 1 and type(snapshot.fingerprint) == "string"
    end,
}
