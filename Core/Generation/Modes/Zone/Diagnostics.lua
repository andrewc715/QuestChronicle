local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle

Generation.ZoneDiagnosticsPolicy = {
    GetFoundationStatus = function()
        return ZoneStyle.GetZoneFoundationStatus and ZoneStyle.GetZoneFoundationStatus() or nil
    end,
    GetContextSnapshot = function()
        return ZoneStyle.GetZoneContextSnapshot and ZoneStyle.GetZoneContextSnapshot() or nil
    end,
    GetCompatibilityStatus = function()
        return ZoneStyle.GetZoneCompatibilityStatus and ZoneStyle.GetZoneCompatibilityStatus() or nil
    end,
    GetAnchorPolicyStatus = function()
        local Zone = ZoneStyle and ZoneStyle.Zone
        return Zone and Zone.GetAnchorPolicyStatus and Zone.GetAnchorPolicyStatus() or nil
    end,
    BuildDebugLines = function(snapshot, affinity)
        local Zone = ZoneStyle and ZoneStyle.Zone
        return Zone and Zone.BuildZoneDebugLines and Zone.BuildZoneDebugLines(snapshot, affinity) or {}
    end,
}
