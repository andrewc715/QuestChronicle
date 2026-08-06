local QC = QuestChronicle
local Generation = QC.Generation
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local ZoneStyle = QC.ZoneStyle
local Traveler = ZoneStyle and ZoneStyle.Traveler

local modeID = ZoneStyle and ZoneStyle.MODE_TRAVELER or "TRAVELER"
local policy

local runtime = {
    GetWorkerRuntime = function() return P.GetSharedGenerationRuntime() end,
    StepSetup = function(job) return P.StepGenerationSetup(job) end,
    StepAnchor = function(job, stepStarted) return P.AdvanceAnchorGenerationPhase(job, stepStarted) end,
    StepSupport = function(job, stepStarted) return P.StepSupportGenerationJob(job, stepStarted) end,
    ApplyNextAnchor = function(job) return P.ApplyNextAnchorSkeleton(job) end,
    ProcessArmor = function(job, stepStarted, slice) return P.ProcessLegacyArmorGeneration(job, stepStarted, slice) end,
    CreateWeaponWork = function(...) return P.CreateWeaponGenerationWork and P.CreateWeaponGenerationWork(...) end,
    StepWeaponWork = function(...) return P.StepWeaponGenerationWork and P.StepWeaponGenerationWork(...) end,
    GenerateWeapons = function(...) return P.GenerateWeapons(...) end,
    CommitDraft = function(...) return P.CommitSharedGenerationDraft(...) end,
    BuildStateSignature = function(...) return P.BuildGenerationStateSignature(...) end,
    GetActiveJob = function() return P.generationJob end,
    SetActiveJob = function(job) P.generationJob = job end,
    GetSupportingArmorOrder = function() return P.SUPPORTING_ARMOR_GENERATION_ORDER end,
    GetOperationSafetyCap = function() return P.GENERATION_OPERATION_SAFETY_CAP or 2000 end,
    IsSupportSlot = function(slotKey) return P.IsSupportSlotKey and P.IsSupportSlotKey(slotKey) == true end,
}

setmetatable(runtime, {
    __index = function(_, key)
        local worker = P.GetSharedGenerationRuntime and P.GetSharedGenerationRuntime() or nil
        return worker and worker[key] or nil
    end,
})

policy = Generation.CreateModePolicy({
    modeID = modeID,
    displayLabel = "Traveler",
    diagnosticLabel = "Traveler",
    implementation = Generation.IMPLEMENTATION_SHARED_FRAMEWORK,
    implementationGeneration = 1,
    capabilities = {
        generate = true, rerollUnlocked = true, rerollSlot = true,
        rerollSupportSlot = true, cancel = true, sharedFramework = true,
        legacy = false, tuningAudit = true,
    },
    runtime = runtime,
    visualLanguage = {
        GetDescriptor = function(...) return Traveler and Traveler.GetDescriptor and Traveler.GetDescriptor(...) end,
        GetPairCohesion = function(...) return Traveler and Traveler.GetPairCohesion and Traveler.GetPairCohesion(...) end,
        GetCuratedMetadata = function(...) return Traveler and Traveler.GetCuratedDescriptorMetadata and Traveler.GetCuratedDescriptorMetadata(...) end,
    },
    contextPolicy = Generation.TravelerContextPolicy,
    anchorPolicy = Generation.TravelerAnchorPolicy,
    supportPolicy = Generation.TravelerSupportPolicy,
    validationPolicy = Generation.TravelerValidationPolicy,
    diagnosticsPolicy = Generation.TravelerDiagnosticsPolicy,
    StartGenerate = function(reroll, options, action)
        local starter = Wardrobe.StartGenerateOutfit or Wardrobe.GenerateOutfit
        if type(starter) ~= "function" then return false, "Quest Chronicle has no Traveler generation worker." end
        local deferred = Wardrobe.StartGenerateOutfit ~= nil
        local ok, message = starter(reroll == true, modeID, policy, action)
        return ok, message, ok == true and deferred == true
    end,
    RerollSlot = function(slotKey, options, action)
        if type(Wardrobe.RerollSlot) ~= "function" then return false, "Quest Chronicle has no slot-reroll worker." end
        return Wardrobe.RerollSlot(slotKey, policy, action)
    end,
    Cancel = function(reason)
        if type(Wardrobe.CancelGeneration) ~= "function" then return false end
        return Wardrobe.CancelGeneration(reason)
    end,
    IsGenerating = function()
        return type(Wardrobe.IsGenerating) == "function" and Wardrobe.IsGenerating() == true
    end,
    GetLastPerformance = function()
        return type(Wardrobe.GetLastGenerationPerformance) == "function"
            and Wardrobe.GetLastGenerationPerformance() or nil
    end,
})

local ok, reason = Generation.RegisterGenerationMode(modeID, policy)
assert(ok, reason)
