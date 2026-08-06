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
local calls, active = {}, false
P.GetSharedGenerationRuntime = function() return {} end
P.StepGenerationSetup = function() return true end
P.AdvanceAnchorGenerationPhase = function() end
P.StepSupportGenerationJob = function() return "READY" end
P.ApplyNextAnchorSkeleton = function() return true end
P.ProcessLegacyArmorGeneration = function() return true end
P.GenerateWeapons = function() return true, 0 end
P.CommitSharedGenerationDraft = function() return {} end
P.BuildGenerationStateSignature = function() return "" end
P.IsSupportSlotKey = function(slotKey) return slotKey == "WAIST" end
QC.Wardrobe.StartGenerateOutfit = function(reroll, modeID, policy, action)
    calls[#calls + 1] = { kind = "generate", reroll = reroll, modeID = modeID, policy = policy, action = action }
    active = true
    return true, reroll and "reroll" or "generate"
end
QC.Wardrobe.RerollSlot = function(slotKey, policy, action)
    calls[#calls + 1] = { kind = "slot", slotKey = slotKey, policy = policy, action = action }
    return true, "slot", slotKey == "WAIST"
end
QC.Wardrobe.CancelGeneration = function(reason)
    calls[#calls + 1] = { kind = "cancel", reason = reason }
    active = false
    if QC.Generation and QC.Generation.GetActiveAction and QC.Generation.GetActiveAction() then
        QC.Generation.CompleteAction(QC.Generation.GetActiveAction(), false, reason, {})
    end
    return true
end
QC.Wardrobe.IsGenerating = function() return active end
QC.Wardrobe.GetLastGenerationPerformance = function() return { maxStepMs = 3.1 } end
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
    "Core/Generation/Modes/Traveler/Context.lua", "Core/Generation/Modes/Traveler/AnchorPolicy.lua",
    "Core/Generation/Modes/Traveler/SupportPolicy.lua", "Core/Generation/Modes/Traveler/ValidationPolicy.lua",
    "Core/Generation/Modes/Traveler/Diagnostics.lua", "Core/Generation/Modes/Traveler/Policy.lua",
    "Core/Generation/Modes/ZoneLegacyAdapter.lua", "Core/Generation/Modes/ClassLegacyAdapter.lua",
    "Core/Generation/Modes/EchoLegacyAdapter.lua", "Core/Generation/GenerationAPI.lua",
}
for _, file in ipairs(files) do dofile(file) end
local G = QC.Generation

local ok, message, deferred = G.GenerateCurrentMode({ modeID = "TRAVELER" })
assert(ok and message == "generate" and deferred == true, "shared generate routing failed")
assert(calls[#calls].policy.implementation == "SHARED_FRAMEWORK" and calls[#calls].action.actionType == "GENERATE_OUTFIT", "shared action identity missing")
local state = assert(G.GetCurrentGenerationState({ modeID = "TRAVELER" }))
assert(state.active and state.actionType == "GENERATE_OUTFIT" and state.implementation == "SHARED_FRAMEWORK", "shared state mismatch")
G.CompleteAction(G.GetActiveAction(), true, "test completion", {})

ok, message, deferred = G.RerollSupportSlotCurrentMode("WAIST", { modeID = "TRAVELER" })
assert(ok and deferred == true and calls[#calls].action.actionType == "REROLL_SLOT", "support reroll lifecycle missing")

ok, message, deferred = G.RerollCurrentModeSlot("CHEST", { modeID = "TRAVELER" })
assert(ok and calls[#calls].action == nil, "legacy individual anchor reroll must remain outside shared action lifecycle")

ok, message, deferred = G.RerollUnlockedCurrentMode({ modeID = "CLASS_FANTASY" })
assert(ok and calls[#calls].modeID == "CLASS_FANTASY" and calls[#calls].policy == nil, "legacy mode must not receive shared policy")

assert(G.CancelCurrentGeneration("test", { modeID = "TRAVELER" }) == true, "shared cancellation failed")
assert(calls[#calls].kind == "cancel" and calls[#calls].reason == "test", "cancel reason mismatch")
print("PASS v1.10.0 generation API: shared Traveler lifecycle, support reroll, legacy individual reroll, and legacy modes")
