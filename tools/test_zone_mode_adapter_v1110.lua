QuestChronicle = {
    Generation = {},
    ZoneStyle = {
        MODE_ZONE_NATIVE = "ZONE_NATIVE",
        Traveler = {
            GetDescriptor = function() return {} end,
            GetPairCohesion = function() return 1 end,
            GetCuratedDescriptorMetadata = function() return nil end,
        },
    },
    Wardrobe = {
        StartGenerateOutfit = function() return true end,
        RerollSlot = function() return true end,
        CancelGeneration = function() return true end,
        IsGenerating = function() return false end,
        GetLastGenerationPerformance = function() return {} end,
    },
}
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_mode_adapter_v1110.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/Generation/ModePolicy.lua")
Load("Core/Generation/ModeRegistry.lua")
Load("Core/Generation/Modes/Zone/Context.lua")
Load("Core/Generation/Modes/Zone/Affinity.lua")
Load("Core/Generation/Modes/Zone/Diagnostics.lua")
Load("Core/Generation/Modes/ZoneLegacyAdapter.lua")
local G = QuestChronicle.Generation
local policy = assert(G.GetGenerationMode("ZONE_NATIVE"))
local caps = G.GetModeCapabilities("ZONE_NATIVE")
assert(policy.implementation == "LEGACY", "Zone falsely claimed shared generation")
assert(caps.zoneFoundation == "CONTEXT_EVIDENCE_V1", "Zone foundation capability missing")
assert(caps.zoneContextFormat == 1 and caps.zoneEvidence and caps.zoneAffinityDiagnostics, "Zone evidence capabilities missing")
assert(caps.zoneAnchorPolicy == false and caps.zoneSupportPolicy == false and caps.zoneFinalValidation == false, "future Zone policies were falsely enabled")
assert(type(policy.contextPolicy) == "table" and type(policy.diagnosticsPolicy) == "table" and type(policy.affinityPolicy) == "table", "read-only Zone providers missing")
print("PASS v1.11.0 Zone adapter: LEGACY generation with CONTEXT_EVIDENCE_V1 read-only providers")
