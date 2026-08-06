QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = {
        MODE_ZONE_NATIVE = "ZONE_NATIVE", MODE_TRAVELER = "TRAVELER",
        MODE_CLASS_FANTASY = "CLASS_FANTASY", MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO",
        Traveler = {},
    },
}
local QC = QuestChronicle
local P = QC.Wardrobe._Private
local activeJob
P.GetSharedGenerationRuntime = function() return {} end
P.StepGenerationSetup = function() return true end
P.AdvanceAnchorGenerationPhase = function() end
P.StepSupportGenerationJob = function() return "READY" end
P.ApplyNextAnchorSkeleton = function() return true end
P.ProcessLegacyArmorGeneration = function() return true end
P.GenerateWeapons = function() return true, 0 end
P.CommitSharedGenerationDraft = function() return {} end
P.BuildGenerationStateSignature = function() return "" end
P.IsSupportSlotKey = function() return false end
P.generationJob = nil
QC.Wardrobe.StartGenerateOutfit = function(_, modeID, policy, action)
    activeJob = { modeID = modeID, policy = policy, action = action }
    return true, "started"
end
QC.Wardrobe.RerollSlot = function() return true, "rerolled" end
QC.Wardrobe.CancelGeneration = function() return true end
QC.Wardrobe.IsGenerating = function() return activeJob ~= nil end
QC.Wardrobe.GetLastGenerationPerformance = function() return { steps = 4 } end
QC.ZoneStyle.GetMode = function() return "TRAVELER" end

local files = {
    "Core/Generation/ModePolicy.lua", "Core/Generation/ModeRegistry.lua",
    "Core/Generation/GenerationLifecycle.lua", "Core/Generation/SchedulerEngine.lua",
    "Core/Generation/ContextProvider.lua", "Core/Generation/AnchorEngine.lua",
    "Core/Generation/ValidationEngine.lua", "Core/Generation/RepairEngine.lua",
    "Core/Generation/SupportEngine.lua", "Core/Generation/CandidateEngine.lua",
    "Core/Generation/WeaponEngine.lua", "Core/Generation/CommitEngine.lua",
    "Core/Generation/DiagnosticsEngine.lua", "Core/Generation/RerollEngine.lua",
    "Core/Generation/VisualLanguage.lua", "Core/Generation/GenerationJob.lua",
    "Core/Generation/Modes/Traveler/Context.lua",
    "Core/Generation/Modes/Traveler/AnchorPolicy.lua",
    "Core/Generation/Modes/Traveler/SupportPolicy.lua",
    "Core/Generation/Modes/Traveler/ValidationPolicy.lua",
    "Core/Generation/Modes/Traveler/Diagnostics.lua",
    "Core/Generation/Modes/Traveler/Policy.lua",
    "Core/Generation/Modes/ZoneLegacyAdapter.lua",
    "Core/Generation/Modes/ClassLegacyAdapter.lua",
    "Core/Generation/Modes/EchoLegacyAdapter.lua",
}
for _, file in ipairs(files) do dofile(file) end

local G = QC.Generation
local modes = G.GetRegisteredGenerationModes()
assert(#modes == 4, "expected four registered modes")
assert(modes[1].modeID == "TRAVELER" and modes[1].implementation == "SHARED_FRAMEWORK", "Traveler must own shared framework")
for index = 2, 4 do assert(modes[index].implementation == "LEGACY", "non-Traveler modes must remain legacy") end
assert(G.SupportsSharedFramework("TRAVELER") == true, "Traveler shared capability missing")
assert(G.SupportsSharedFramework("ZONE_NATIVE") == false, "Zone must remain legacy")
local duplicateOK, duplicateReason = G.RegisterGenerationMode("TRAVELER", G.GetGenerationMode("TRAVELER"))
assert(duplicateOK == false and duplicateReason:find("already registered", 1, true), "duplicate guard missing")
local missing, reason = G.GetGenerationMode("UNKNOWN")
assert(missing == nil and reason:find("Unsupported generation mode", 1, true), "unknown mode must fail clearly")
print("PASS v1.10.0 mode registry: Traveler shared framework and three explicit legacy adapters")
