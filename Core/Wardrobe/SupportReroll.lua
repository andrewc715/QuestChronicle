local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local originalRerollSlot = Wardrobe.RerollSlot

local function CountSelectedArmor(state)
    local count = 0
    for _, definition in ipairs(Wardrobe.slotDefinitions or {}) do
        if not definition.weaponRole and state.selections[definition.key] and not state.hidden[definition.key] then count = count + 1 end
    end
    return count
end

local function StartSupportReroll(slotKey, styleMode, sharedPolicy, sharedAction)
    if Wardrobe.IsGenerating and Wardrobe.IsGenerating() then return false, "Quest Chronicle is already preparing an outfit." end
    if Wardrobe.IsScanning and Wardrobe.IsScanning() then return false, "Wait for the wardrobe scan to finish before rerolling an appearance." end
    if not C_Timer or type(C_Timer.After) ~= "function" then return false, "Quest Chronicle could not schedule the cooperative support-slot reroll. Try /reload." end

    local launchStarted = P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
    local liveState = P.EnsurePreviewState()
    local style = QC.ZoneStyle
    styleMode = style and style.NormalizeMode(styleMode or liveState.styleMode) or (styleMode or liveState.styleMode)
    P.supportRerollToken = P.supportRerollToken + 1
    local token = P.supportRerollToken
    local manifest = P.CreateSupportRerollManifest(liveState, slotKey, styleMode, token)
    local job = {
        token = token, manifest = manifest, liveState = liveState,
        sharedFrameworkPolicy = sharedPolicy, sharedAction = sharedAction,
        generationImplementation = sharedPolicy and "SHARED_FRAMEWORK" or "LEGACY",
        action = "REROLL_SLOT", actionSlotKey = slotKey, performedAnchorSelection = false,
        supportReroll = true, reuseAnchorSnapshot = true, styleMode = styleMode,
        slotLabel = P.slotByKey[slotKey] and P.slotByKey[slotKey].label or slotKey,
        phase = "IDENTITY", steps = 0, maxStepMs = 0, phaseStats = {},
        candidatesProcessed = 0, eraCandidatesProcessed = 0, eraCacheHits = 0,
        eraSynchronousProgressGuardStart = tonumber(style and style._Private and style._Private.eraSynchronousProgressGuardTrips) or 0,
        eligibilityCacheHits = 0, weaponYields = 0, startedAtMs = launchStarted,
    }
    local launchElapsed = (P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or launchStarted) - launchStarted
    job.synchronousLaunchPreparationMs = launchElapsed
    job.preWorkerPreparationMs = launchElapsed
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, "rerollLaunchManifest", launchElapsed) end
    P.supportRerollJob = job
    if QC.Notify then QC.Notify("WARDROBE_GENERATION_STARTED", true, styleMode) end
    C_Timer.After(0, function() if P.supportRerollJob == job then P.StepSupportRerollJob(job.token) end end)
    return true, "Rerolling " .. tostring(job.slotLabel) .. " contextually...", true
end

Wardrobe.RerollSlot = function(slotKey, sharedPolicy, sharedAction)
    local definition = P.slotByKey[slotKey]
    if not definition then return false, "Unknown equipment slot." end
    if Wardrobe.IsSlotLocked(slotKey) then return false, "Unlock this slot before rerolling it." end
    local state = P.EnsurePreviewState()
    local style = QC.ZoneStyle
    local styleMode = style and style.NormalizeMode(state.styleMode) or state.styleMode
    if P.IsSupportSlotKey(slotKey) then return StartSupportReroll(slotKey, styleMode, sharedPolicy, sharedAction) end

    local ok, message = originalRerollSlot(slotKey)
    if ok then
        P.RebuildContextualSupport(state, styleMode)
        state.selectedConceptID = nil
        local context = style and P.CreateStyleGenerationContext(state, style, style.GetCurrentContext(), nil, false) or nil
        local name = P.RefreshGeneratedOutfitName(state, style, styleMode, context)
        if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
        if name then message = message .. " Contextual support rebuilt around the new anchor; the current look is now " .. name .. "." end
    end
    return ok, message, false
end

function P.RebuildContextualSupport(state, styleMode)
    -- Anchor-slot rerolls retain the established v1.9.0.7 behavior. The
    -- cooperative worker in this release is deliberately isolated to support
    -- slots so full-generation and anchor-reroll selection stay unchanged.
    state.activeAnchorMask = nil
    for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do
        if not state.hidden[slotKey] and not state.locks[slotKey] then
            local ok = P.SelectContextualSupportSlot and P.SelectContextualSupportSlot(state, slotKey, styleMode, false)
            if not ok then break end
        end
    end
    state.activeAnchorMask = P.BuildActiveAnchorMask(state)
    local profile = P.BuildContextualSupportProfile(state, { activeAnchorMask = state.activeAnchorMask })
    state.contextualSupportProfile = P.ExportContextualSupportProfile(profile)
    return true
end
