local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
P.GENERATION_TIME_BUDGET_MS = 2.5
P.GENERATION_OPERATION_SAFETY_CAP = 2000
P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
P.generationToken = P.generationToken or 0
P.generationJob = nil
P.lastGenerationPerformance = nil
local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end
local function RecordPhase(job, phaseKey, startedAt)
    if P.RecordGenerationPhase then
        P.RecordGenerationPhase(job, phaseKey, NowMilliseconds() - startedAt)
    end
end
local function CopyDraftState(state)
    local draft = {}
    for key, value in pairs(state or {}) do
        if type(value) ~= "table" then draft[key] = value end
    end
    draft.selections = P.CopyPrimitiveMap(state and state.selections)
    draft.selectionVisuals = P.CopyPrimitiveMap(state and state.selectionVisuals)
    draft.locks = P.CopyPrimitiveMap(state and state.locks)
    draft.hidden = P.CopyPrimitiveMap(state and state.hidden)
    draft.weaponFamilies = P.CopyPrimitiveMap(state and state.weaponFamilies)
    draft.weaponSubtypes = P.CopyPrimitiveMap(state and state.weaponSubtypes)
    draft.lastWeaponRoute = state and state.lastWeaponRoute
    return draft
end
local function AppendMapSignature(parts, label, values)
    local keys = {}
    for key in pairs(values or {}) do table.insert(keys, tostring(key)) end
    table.sort(keys)
    table.insert(parts, label)
    for _, key in ipairs(keys) do
        local value = values[key]
        if value == nil then value = values[tonumber(key)] end
        table.insert(parts, key .. "=" .. tostring(value))
    end
end
local function GenerationStateSignature(state)
    local parts = {
        "link=" .. tostring(state and state.linkWeaponHands ~= false),
        "mode=" .. tostring(state and state.styleMode or ""),
    }
    AppendMapSignature(parts, "selections", state and state.selections)
    AppendMapSignature(parts, "locks", state and state.locks)
    AppendMapSignature(parts, "hidden", state and state.hidden)
    AppendMapSignature(parts, "families", state and state.weaponFamilies)
    AppendMapSignature(parts, "subtypes", state and state.weaponSubtypes)
    return table.concat(parts, "|")
end
local function ScheduleNextStep(token)
    if not C_Timer or type(C_Timer.After) ~= "function" then return false end
    C_Timer.After(0, function()
        if P.generationJob and P.generationJob.token == token then
            P.StepGenerationJob(token)
        end
    end)
    return true
end
local function Notify(event, ...)
    if QC.Notify then QC.Notify(event, ...) end
end
local function FinishJob(job, success, message)
    if not job or P.generationJob ~= job then return end
    local finishedAt = NowMilliseconds()
    local performance = P.BuildGenerationPerformance
        and P.BuildGenerationPerformance(job, finishedAt)
        or {
            elapsedMs = math.max(0, finishedAt - job.startedAtMs),
            steps = job.steps or 0,
            maxStepMs = job.maxStepMs or 0,
            candidates = job.candidatesProcessed or 0,
            selectedArmor = job.selectedArmor or 0,
        }
    P.lastGenerationPerformance = performance
    P.generationJob = nil
    local notifyStarted = NowMilliseconds()
    Notify("WARDROBE_GENERATION_COMPLETE", success == true, message, performance)
    if Wardrobe.RecordGenerationPostPhase then
        Wardrobe.RecordGenerationPostPhase(performance, "completionNotify", NowMilliseconds() - notifyStarted)
    end
    if QC.Diagnostics and QC.Diagnostics.QueueGenerationAttempt then QC.Diagnostics.QueueGenerationAttempt(job, success == true, message, performance) end
    return performance
end
local function BuildGenerationMessage(job, generatedName, weaponCount, weaponNotice)
    local styleLabel = "Random"
    local profileLabel
    local restrictionLabel
    local styleEngine = job.styleEngine
    if styleEngine then
        local modeInfo = styleEngine.GetModeInfo(job.styleMode)
        styleLabel = modeInfo and modeInfo.label or styleLabel
        profileLabel = job.styleContext and job.styleContext.profileLabel
        restrictionLabel = styleEngine.GetContextRestrictionLabel and styleEngine.GetContextRestrictionLabel(job.styleContext)
        if job.styleMode == styleEngine.MODE_ZONE_NATIVE then styleEngine.ConsumeSuggestion() end
    end
    local message = string.format(
        "Generated %s, a %s outfit%s with %d armor slots and %d equipped-weapon-safe appearance%s%s; locked and hidden choices were preserved.",
        generatedName or "a new outfit",
        styleLabel,
        profileLabel and (" for " .. profileLabel) or "",
        job.selectedArmor or 0,
        weaponCount or 0,
        weaponCount == 1 and "" or "s",
        restrictionLabel and (" under " .. restrictionLabel) or ""
    )
    if job.anchorStats then
        message = message .. string.format(" Anchor skeleton rank %d/%d scored %.1f.", job.anchorStats.chosenRank or 0, job.anchorStats.shortlistSize or 0, job.anchorStats.chosenScore or 0)
        if job.anchorStats.noveltyClass and P.GetAnchorNoveltyClassLabel then
            message = message .. " Novelty: " .. P.GetAnchorNoveltyClassLabel(job.anchorStats.noveltyClass) .. "."
        end
    elseif job.anchorFallbackReason then
        message = message .. " Anchor search used the legacy fallback: " .. tostring(job.anchorFallbackReason) .. "."
    end
    if job.supportStats then
        message = message .. string.format(" Contextual support cohesion %.3f used %.2f of %.2f mismatch points.", job.supportStats.wholeOutfitCohesion or 0, (job.supportStats.lockedCommitment or 0) + (job.supportStats.generatedSpend or 0), job.supportStats.startingBudget or 0)
    elseif job.supportFallbackReason then message = message .. " Contextual support used the legacy fallback: " .. tostring(job.supportFallbackReason) .. "." end
    if weaponNotice then message = message .. " " .. weaponNotice end
    if styleEngine then
        message = message .. " Promotional rewards were excluded, and native-set or shared-motif matches were favored."
    end
    return message
end
local function CommitDraft(job, weaponCount, weaponNotice)
    if GenerationStateSignature(job.liveState) ~= job.startSignature then
        return FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
    end
    local commitStarted = NowMilliseconds()
    local generatedName = P.RefreshGeneratedOutfitName(job.draft, job.styleEngine, job.styleMode, job.styleContext)
    job.liveState.selections = job.draft.selections
    job.liveState.selectionVisuals = job.draft.selectionVisuals
    job.liveState.lastWeaponRoute = job.draft.lastWeaponRoute
    job.liveState.lastAnchorSkeletonSignature = job.draft.lastAnchorSkeletonSignature
    job.liveState.generatedName = generatedName
    job.liveState.styleMode = job.styleMode
    job.liveState.selectedConceptID = nil
    RecordPhase(job, "stateCommit", commitStarted)
    return FinishJob(job, true, BuildGenerationMessage(job, generatedName, weaponCount, weaponNotice))
end
local function FinalizeArmorSlot(job, work)
    local chosen
    if job.styleEngine then
        if #work.pool == 0 then
            chosen = work.fallback and work.fallback.source
        else
            local roll = math.random() * work.totalWeight
            for _, entry in ipairs(work.pool) do
                roll = roll - entry.weight
                if roll <= 0 then chosen = entry.source break end
            end
            chosen = chosen or work.pool[#work.pool].source
        end
    elseif #work.pool == 0 then
        chosen = work.fallback
    else
        chosen = work.pool[math.random(1, #work.pool)]
    end
    if chosen then
        P.SetSelectedSource(job.draft, work.slotKey, chosen)
        if not job.draft.hidden[work.slotKey] and job.styleEngine and job.styleEngine.AddSourceToGenerationContext then
            job.styleEngine.AddSourceToGenerationContext(job.styleContext, chosen)
        end
        job.selectedArmor = job.selectedArmor + 1
    elseif not job.reroll then
        P.SetSelectedSource(job.draft, work.slotKey, nil)
    end
end
local function BeginArmorSlot(job, slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition or job.draft.locks[slotKey] then return nil end
    return {
        slotKey = slotKey,
        definition = definition,
        sources = Wardrobe.GetSlotSources(slotKey),
        sourceIndex = 1,
        excludeSourceID = job.reroll and job.draft.selections[slotKey] or nil,
        pool = {},
        totalWeight = 0,
        fallback = nil,
        candidateWork = nil,
    }
end
local function AddCandidateToPool(job, work, source, coherenceScore, coherent, coherenceReason)
    if job.styleEngine and job.styleEngine.ChooseWeightedSource then
        local scoringStarted = NowMilliseconds()
        local weight, score = job.styleEngine.WeightForSource(
            source,
            work.definition,
            job.styleMode,
            job.styleContext,
            coherenceScore,
            coherent,
            coherenceReason
        )
        RecordPhase(job, "scoring", scoringStarted)
        local entry = { source = source, weight = weight, score = score }
        if source.sourceID == work.excludeSourceID then
            work.fallback = entry
        else
            work.totalWeight = work.totalWeight + weight
            table.insert(work.pool, entry)
        end
    elseif source.sourceID == work.excludeSourceID then
        work.fallback = source
    else
        table.insert(work.pool, source)
    end
end
local function ContinueArmorCandidate(job, work)
    local candidate = work.candidateWork
    if not candidate then
        local source = work.sources[work.sourceIndex]
        candidate = { source = source }
        work.candidateWork = candidate
        local validationStarted = NowMilliseconds()
        candidate.valid = Wardrobe.ValidateSource(source, work.slotKey) == true
        RecordPhase(job, "validation", validationStarted)
        if not candidate.valid then return true end
        if not job.styleEngine or not job.styleEngine.ChooseWeightedSource then
            AddCandidateToPool(job, work, source)
            return true
        end
        if job.styleEngine.GetSourcePreEraEligibility then
            local eligibilityStarted = NowMilliseconds()
            local eligible
            if job.styleEngine.GetSourcePreEraEligibilityCached then
                eligible = job.styleEngine.GetSourcePreEraEligibilityCached(source, job.styleContext)
            else
                eligible = job.styleEngine.GetSourcePreEraEligibility(source, job.styleContext)
            end
            RecordPhase(job, "eligibility", eligibilityStarted)
            if not eligible then return true end
            candidate.prechecked = true
        end
        local eraStarted = NowMilliseconds()
        if job.styleEngine.CreateSourceEraEvidenceWork then
            candidate.eraWork = job.styleEngine.CreateSourceEraEvidenceWork(source)
            if candidate.eraWork.done then candidate.eraEvidence = candidate.eraWork.result end
        else
            candidate.eraEvidence = job.styleEngine.GetSourceEraEvidence(source)
        end
        RecordPhase(job, "eraEvidence", eraStarted)
    end
    if candidate.eraWork and not candidate.eraWork.done then
        local eraStarted = NowMilliseconds()
        local done, evidence, processed = job.styleEngine.StepSourceEraEvidenceWork(
            candidate.eraWork,
            P.GENERATION_ERA_CANDIDATES_PER_OPERATION
        )
        job.eraCandidatesProcessed = job.eraCandidatesProcessed + (tonumber(processed) or 0)
        RecordPhase(job, "eraEvidence", eraStarted)
        if not done then return false end
        candidate.eraEvidence = evidence
    end
    local eligibilityStarted = NowMilliseconds()
    local eligible
    if job.styleEngine.GetSourceEligibilityCached then
        eligible = job.styleEngine.GetSourceEligibilityCached(
            candidate.source,
            job.styleMode,
            job.styleContext,
            candidate.eraEvidence,
            candidate.prechecked
        )
    else
        eligible = job.styleEngine.GetSourceEligibility(
            candidate.source,
            job.styleMode,
            job.styleContext,
            candidate.eraEvidence,
            candidate.prechecked
        )
    end
    RecordPhase(job, "eligibility", eligibilityStarted)
    if not eligible then return true end
    local coherenceStarted = NowMilliseconds()
    local coherenceScore, coherent, coherenceReason = job.styleEngine.GetSourceCoherence(candidate.source, job.styleContext)
    RecordPhase(job, "coherence", coherenceStarted)
    if not coherent then return true end
    AddCandidateToPool(job, work, candidate.source, coherenceScore, coherent, coherenceReason)
    return true
end
local function ProcessArmor(job, stepStarted)
    local operations = 0
    local armorOrder = job.armorOrder or P.ARMOR_GENERATION_ORDER
    while job.armorIndex <= #armorOrder do
        if not job.armorWork then
            local setupStarted = NowMilliseconds()
            local slotKey = armorOrder[job.armorIndex]
            job.armorWork = BeginArmorSlot(job, slotKey)
            RecordPhase(job, "slotSetup", setupStarted)
            if not job.armorWork then job.armorIndex = job.armorIndex + 1 end
        end
        local work = job.armorWork
        if work then
            while work.sourceIndex <= #work.sources do
                local complete = ContinueArmorCandidate(job, work)
                operations = operations + 1
                if complete then
                    work.candidateWork = nil
                    work.sourceIndex = work.sourceIndex + 1
                    job.candidatesProcessed = job.candidatesProcessed + 1
                end
                if operations >= P.GENERATION_OPERATION_SAFETY_CAP then return false end
                if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then return false end
            end
            local finalizationStarted = NowMilliseconds()
            FinalizeArmorSlot(job, work)
            RecordPhase(job, "slotFinalization", finalizationStarted)
            local progressStarted = NowMilliseconds()
            Notify("WARDROBE_GENERATION_PROGRESS", job.armorIndex, #armorOrder, work.slotKey)
            RecordPhase(job, "progressUpdate", progressStarted)
            job.armorWork = nil
            job.armorIndex = job.armorIndex + 1
        end
        if operations >= P.GENERATION_OPERATION_SAFETY_CAP then return false end
        if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then return false end
    end
    return true
end
function P.StepGenerationJob(token)
    local job = P.generationJob
    if not job or job.token ~= token then return end
    job.steps = job.steps + 1
    local stepStarted = NowMilliseconds()
    if GenerationStateSignature(job.liveState) ~= job.startSignature then
        FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
        return
    end
    if job.phase == "ANCHORS" then
        P.AdvanceAnchorGenerationPhase(job, stepStarted)
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
        return
    end
    if job.phase == "SUPPORT" then
        local status, reason = P.StepSupportGenerationJob(job, stepStarted)
        if status == "READY" then job.phase = "COMMIT"
        elseif status == "FALLBACK" then job.supportFallbackReason = reason job.phase = "ARMOR" job.armorOrder = P.SUPPORTING_ARMOR_GENERATION_ORDER job.armorIndex, job.armorWork = 1, nil end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
        return
    end
    if job.phase == "ARMOR" then
        if ProcessArmor(job, stepStarted) then job.phase = job.weaponsPrepared and "COMMIT" or "WEAPONS" end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end
    if job.phase == "WEAPONS" then
        if not job.weaponWork and P.CreateWeaponGenerationWork then
            job.weaponWork = P.CreateWeaponGenerationWork(job.draft, job.reroll, job.styleMode, job.styleContext)
        end
        local operations = 0
        while operations < P.GENERATION_OPERATION_SAFETY_CAP do
            local weaponStarted = NowMilliseconds()
            local done, ok, countOrMessage, notice
            if job.weaponWork and P.StepWeaponGenerationWork then
                done, ok, countOrMessage, notice = P.StepWeaponGenerationWork(job.weaponWork)
            else
                done = true
                ok, countOrMessage, notice = P.GenerateWeapons(job.draft, job.reroll, job.styleMode, job.styleContext)
            end
            RecordPhase(job, "weaponRouting", weaponStarted)
            operations = operations + 1
            if done then
                if not ok then
                    FinishJob(job, false, countOrMessage)
                    return
                end
                job.weaponCount = countOrMessage
                job.weaponNotice = notice
                job.phase = "COMMIT"
                break
            end
            job.weaponYields = job.weaponYields + 1
            if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then break end
        end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end
    if job.phase == "COMMIT" then
        local performance = CommitDraft(job, job.weaponCount, job.weaponNotice)
        if performance then
            performance.maxStepMs = math.max(tonumber(performance.maxStepMs) or 0, NowMilliseconds() - stepStarted)
        end
    end
end
function Wardrobe.IsGenerating()
    return P.generationJob ~= nil
end
function Wardrobe.GetLastGenerationPerformance()
    return P.lastGenerationPerformance
end
function Wardrobe.CancelGeneration(reason)
    local job = P.generationJob
    if not job then return false end
    P.generationToken = P.generationToken + 1
    FinishJob(job, false, reason or "Outfit generation was cancelled.")
    return true
end
function Wardrobe.StartGenerateOutfit(reroll, requestedStyleMode)
    if Wardrobe.IsGenerating() then return false, "Quest Chronicle is already generating an outfit." end
    if Wardrobe.IsScanning() then return false, "Wait for the wardrobe scan to finish before generating an outfit." end
    local cache = P.EnsureCache()
    if cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS" then
        return false, "Scan the wardrobe collection before generating an outfit."
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then
        local diagnosticIdentity = QC.Diagnostics and QC.Diagnostics.BeginGenerationAttempt and QC.Diagnostics.BeginGenerationAttempt(reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT") or nil
        local startedAt = NowMilliseconds()
        local ok, message = Wardrobe.GenerateOutfit(reroll, requestedStyleMode)
        local elapsed = math.max(0, NowMilliseconds() - startedAt)
        local performance = {
            elapsedMs = elapsed, steps = 1, maxStepMs = elapsed, candidates = 0, phaseStats = {},
            cacheDiagnostics = P.BuildGenerationCachePerformance
                and P.BuildGenerationCachePerformance(nil) or nil,
        }
        P.lastGenerationPerformance = performance
        Notify("WARDROBE_GENERATION_COMPLETE", ok == true, message, performance)
        if QC.Diagnostics and QC.Diagnostics.RecordImmediateAttempt then QC.Diagnostics.RecordImmediateAttempt({ action = reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT", reroll = reroll == true, liveState = P.EnsurePreviewState(), draft = P.EnsurePreviewState(), styleMode = requestedStyleMode, diagnosticIdentity = diagnosticIdentity }, ok == true, message, performance) end
        return ok, message
    end
    local startedAtMs = NowMilliseconds()
    local setupStarted = startedAtMs
    local liveState = P.EnsurePreviewState()
    local draft = CopyDraftState(liveState)
    local styleEngine = QC.ZoneStyle
    local styleMode = requestedStyleMode or draft.styleMode
    local styleContext
    if styleEngine then
        styleMode = styleEngine.NormalizeMode(styleMode)
        draft.styleMode = styleMode
        styleContext = P.CreateStyleGenerationContext(draft, styleEngine, styleEngine.GetCurrentContext(), nil, true)
    end
    P.generationToken = P.generationToken + 1
    local diagnosticIdentity = QC.Diagnostics and QC.Diagnostics.BeginGenerationAttempt and QC.Diagnostics.BeginGenerationAttempt(reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT") or nil; local job = {
        token = P.generationToken,
        diagnosticIdentity = diagnosticIdentity,
        action = reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT",
        reroll = reroll == true,
        liveState = liveState,
        draft = draft,
        currentAnchorNovelty = P.BuildAnchorNoveltyContext and P.BuildAnchorNoveltyContext(liveState) or nil,
        styleEngine = styleEngine,
        styleMode = styleMode,
        styleContext = styleContext,
        startSignature = GenerationStateSignature(liveState),
        phase = P.AdvanceAnchorGenerationPhase and "ANCHORS" or "ARMOR", armorIndex = 1, armorOrder = nil,
        anchorWork = nil, anchorStats = nil, anchorFallbackReason = nil, weaponsPrepared = false,
        supportWork = nil, supportStats = nil, supportFallbackReason = nil, armorWork = nil,
        selectedArmor = 0,
        candidatesProcessed = 0,
        eraCandidatesProcessed = 0,
        eraCacheHits = 0,
        eligibilityCacheHits = 0,
        weaponYields = 0,
        steps = 0,
        maxStepMs = 0,
        phaseStats = {},
        cacheCountersStarted = P.GetGenerationCacheCounterSnapshot
            and P.GetGenerationCacheCounterSnapshot() or nil,
        startedAtMs = startedAtMs,
    }
    RecordPhase(job, "setup", setupStarted)
    P.generationJob = job
    Notify("WARDROBE_GENERATION_STARTED", job.reroll, styleMode)
    if not ScheduleNextStep(job.token) then
        P.generationJob = nil
        return false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload."
    end
    return true, job.reroll and "Rerolling unlocked outfit pieces..." or "Generating outfit..."
end
