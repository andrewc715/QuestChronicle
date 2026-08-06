local QC = QuestChronicle
QC.Generation = QC.Generation or {}
local Generation = QC.Generation
Generation._Private = Generation._Private or {}
local P = Generation._Private

Generation.POLICY_CONTRACT_VERSION = 1
Generation.IMPLEMENTATION_SHARED_FRAMEWORK = "SHARED_FRAMEWORK"
Generation.IMPLEMENTATION_LEGACY = "LEGACY"

local VALID_IMPLEMENTATIONS = {
    [Generation.IMPLEMENTATION_SHARED_FRAMEWORK] = true,
    [Generation.IMPLEMENTATION_LEGACY] = true,
}

local SHARED_RUNTIME_CALLBACKS = {
    "GetWorkerRuntime", "StepSetup", "StepAnchor", "StepSupport",
    "ApplyNextAnchor", "ProcessArmor", "CreateWeaponWork",
    "StepWeaponWork", "GenerateWeapons", "CommitDraft",
    "BuildStateSignature", "GetActiveJob", "SetActiveJob",
}


local ZONE_ANCHOR_CALLBACKS = {
    "GetAnchorSlots", "GetAnchorSearchConfiguration", "EvaluateAnchorCandidate",
    "ScoreAnchorPair", "ScoreAnchorSkeleton", "BuildNoveltyReference", "ClassifyNovelty",
}

local function ValidateZoneAnchorPolicy(policy)
    if not (policy.capabilities and policy.capabilities.zoneAnchorPolicy == true) then return true end
    if type(policy.anchorPolicy) ~= "table" then
        return false, "Zone anchor policy " .. tostring(policy.modeID) .. " is missing its policy table."
    end
    for _, callback in ipairs(ZONE_ANCHOR_CALLBACKS) do
        if type(policy.anchorPolicy[callback]) ~= "function" then
            return false, "Zone anchor policy " .. tostring(policy.modeID)
                .. " is missing callback " .. callback .. "."
        end
    end
    return true
end

local function CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            result[key] = value
        end
    end
    return result
end

function P.NormalizeModeID(modeID)
    if type(modeID) ~= "string" then return nil end
    modeID = modeID:match("^%s*(.-)%s*$")
    return modeID ~= "" and modeID or nil
end

local function ValidateSharedRuntime(policy)
    if type(policy.runtime) ~= "table" then
        return false, "Shared-framework policy " .. tostring(policy.modeID) .. " has no runtime contract."
    end
    for _, callback in ipairs(SHARED_RUNTIME_CALLBACKS) do
        if type(policy.runtime[callback]) ~= "function" then
            return false, "Shared-framework policy " .. tostring(policy.modeID)
                .. " is missing runtime callback " .. callback .. "."
        end
    end
    return true
end

function P.ValidateModePolicy(policy)
    if type(policy) ~= "table" then return false, "Generation mode policy must be a table." end
    local modeID = P.NormalizeModeID(policy.modeID)
    if not modeID then return false, "Generation mode policy has no mode ID." end
    if type(policy.displayLabel) ~= "string" or policy.displayLabel == "" then
        return false, "Generation mode policy " .. modeID .. " has no display label."
    end
    if not VALID_IMPLEMENTATIONS[policy.implementation] then
        return false, "Generation mode policy " .. modeID .. " has an unknown implementation marker."
    end
    for _, callback in ipairs({ "StartGenerate", "RerollSlot", "Cancel" }) do
        if type(policy[callback]) ~= "function" then
            return false, "Generation mode policy " .. modeID .. " has no " .. callback .. " callback."
        end
    end
    local zoneOK, zoneReason = ValidateZoneAnchorPolicy(policy)
    if not zoneOK then return false, zoneReason end
    if policy.implementation == Generation.IMPLEMENTATION_SHARED_FRAMEWORK then
        return ValidateSharedRuntime(policy)
    end
    return true
end

function Generation.CreateModePolicy(definition)
    definition = type(definition) == "table" and definition or {}
    local policy = {
        contractVersion = Generation.POLICY_CONTRACT_VERSION,
        modeID = P.NormalizeModeID(definition.modeID),
        displayLabel = definition.displayLabel,
        diagnosticLabel = definition.diagnosticLabel or definition.displayLabel,
        implementation = definition.implementation,
        implementationGeneration = math.max(1, math.floor(tonumber(definition.implementationGeneration) or 1)),
        capabilities = CopyPrimitiveMap(definition.capabilities),
        runtime = definition.runtime,
        visualLanguage = definition.visualLanguage,
        contextPolicy = definition.contextPolicy,
        anchorPolicy = definition.anchorPolicy,
        supportPolicy = definition.supportPolicy,
        validationPolicy = definition.validationPolicy,
        diagnosticsPolicy = definition.diagnosticsPolicy,
        StartGenerate = definition.StartGenerate,
        RerollSlot = definition.RerollSlot,
        Cancel = definition.Cancel,
        IsGenerating = definition.IsGenerating,
        GetLastPerformance = definition.GetLastPerformance,
    }
    local ok, reason = P.ValidateModePolicy(policy)
    assert(ok, reason)
    return policy
end

function P.CreateLegacyWardrobePolicy(definition)
    definition = type(definition) == "table" and definition or {}
    local modeID = P.NormalizeModeID(definition.modeID)
    local Wardrobe = QC.Wardrobe
    assert(Wardrobe, "Quest Chronicle legacy generation adapter requires the Wardrobe subsystem.")
    definition.implementation = Generation.IMPLEMENTATION_LEGACY
    definition.capabilities = definition.capabilities or {
        generate = true, rerollUnlocked = true, rerollSlot = true,
        rerollSupportSlot = true, cancel = true, sharedFramework = false, legacy = true,
    }
    definition.StartGenerate = function(reroll)
        local starter = Wardrobe.StartGenerateOutfit or Wardrobe.GenerateOutfit
        if type(starter) ~= "function" then
            return false, "Quest Chronicle has no legacy outfit worker for " .. tostring(modeID) .. "."
        end
        local deferred = Wardrobe.StartGenerateOutfit ~= nil
        local ok, message = starter(reroll == true, modeID)
        return ok, message, ok == true and deferred == true
    end
    definition.RerollSlot = function(slotKey)
        if type(Wardrobe.RerollSlot) ~= "function" then return false, "Quest Chronicle has no slot-reroll worker." end
        return Wardrobe.RerollSlot(slotKey)
    end
    definition.Cancel = function(reason)
        if type(Wardrobe.CancelGeneration) ~= "function" then return false end
        return Wardrobe.CancelGeneration(reason)
    end
    definition.IsGenerating = function()
        return type(Wardrobe.IsGenerating) == "function" and Wardrobe.IsGenerating() == true
    end
    definition.GetLastPerformance = function()
        return type(Wardrobe.GetLastGenerationPerformance) == "function"
            and Wardrobe.GetLastGenerationPerformance() or nil
    end
    return Generation.CreateModePolicy(definition)
end
