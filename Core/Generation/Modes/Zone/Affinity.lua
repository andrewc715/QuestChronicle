local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle

Generation.ZoneAffinityPolicy = {
    AnalyzeAppearance = function(source, definition, snapshot, prepared)
        return ZoneStyle.GetZoneAffinity and ZoneStyle.GetZoneAffinity(source, definition, snapshot, prepared) or nil
    end,
    AnalyzeCurrentOutfit = function(state, snapshot)
        local Zone = ZoneStyle and ZoneStyle.Zone
        return Zone and Zone.BuildSelectedOutfitAffinity and Zone.BuildSelectedOutfitAffinity(state, snapshot) or nil
    end,
}
