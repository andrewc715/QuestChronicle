local QC = QuestChronicle
if type(QC) ~= "table" then return end
QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe
Wardrobe._Private = Wardrobe._Private or {}
local P = Wardrobe._Private

function P.CreateWardrobeGenerationJob(options)
    options = type(options) == "table" and options or {}
    return {
        token = options.token,
        action = options.reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT",
        sharedFrameworkPolicy = options.sharedPolicy,
        sharedAction = options.sharedAction,
        generationImplementation = options.sharedPolicy and "SHARED_FRAMEWORK" or "LEGACY",
        reroll = options.reroll == true,
        requestedStyleMode = options.requestedStyleMode,
        liveState = options.liveState,
        phase = "SETUP",
        setupPhase = "IDENTITY",
        anchorWork = nil,
        anchorStats = nil,
        anchorFallbackReason = nil,
        weaponsPrepared = false,
        supportWork = nil,
        supportStats = nil,
        supportFallbackReason = nil,
        armorWork = nil,
        phaseDAlternateNoRepair = false,
        phaseDAlternateInfo = nil,
        selectedArmor = 0,
        candidatesProcessed = 0,
        eraCandidatesProcessed = 0,
        eraCacheHits = 0,
        eligibilityCacheHits = 0,
        weaponYields = 0,
        steps = 0,
        maxStepMs = 0,
        phaseStats = {},
        startedAtMs = options.startedAtMs,
    }
end
