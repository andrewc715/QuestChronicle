local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function RecordPhase(job, phaseKey, startedAt)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, NowMilliseconds() - startedAt) end
end

local function CopyDraftState(state)
    local draft = {}
    for key, value in pairs(state or {}) do if type(value) ~= "table" then draft[key] = value end end
    draft.selections = P.CopyPrimitiveMap(state and state.selections)
    draft.selectionVisuals = P.CopyPrimitiveMap(state and state.selectionVisuals)
    draft.locks = P.CopyPrimitiveMap(state and state.locks)
    draft.hidden = P.CopyPrimitiveMap(state and state.hidden)
    draft.weaponFamilies = P.CopyPrimitiveMap(state and state.weaponFamilies)
    draft.weaponSubtypes = P.CopyPrimitiveMap(state and state.weaponSubtypes)
    draft.lastWeaponRoute = state and state.lastWeaponRoute
    return draft
end

local function CreatePoolWork(job, slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition then return { slotKey = slotKey, done = true, pool = {}, reason = "unknown slot" } end
    if job.draft.hidden[slotKey] then return { slotKey = slotKey, done = true, pool = {}, hidden = true } end

    local sources
    local requiredMissing = false
    local missingReason
    if job.draft.locks[slotKey] then
        local selectedID = job.draft.selections[slotKey]
        local selected = selectedID and P.GetSourceByID(slotKey, selectedID)
        sources = selected and { selected } or {}
        if not selected then
            requiredMissing = true
            missingReason = string.format("locked %s source is unavailable", definition.label or slotKey)
        end
    else
        sources = Wardrobe.GetSlotSources(slotKey)
    end
    return {
        slotKey = slotKey,
        definition = definition,
        sources = sources or {},
        sourceIndex = 1,
        candidateWork = nil,
        pool = {},
        fallback = nil,
        poolLimit = P.ANCHOR_POOL_LIMITS[slotKey] or 32,
        excludeSourceID = job.reroll and not job.draft.locks[slotKey] and job.draft.selections[slotKey] or nil,
        locked = job.draft.locks[slotKey] == true,
        requiredMissing = requiredMissing,
        missingReason = missingReason,
        done = false,
    }
end

local function ContinuePoolCandidate(job, work)
    local candidate = work.candidateWork
    if not candidate then
        local source = work.sources[work.sourceIndex]
        candidate = { source = source }
        work.candidateWork = candidate

        local validationStarted = NowMilliseconds()
        candidate.valid = Wardrobe.ValidateSource(source, work.slotKey) == true
        RecordPhase(job, "validation", validationStarted)
        if not candidate.valid then return true end
        if work.locked then
            local scoringStarted = NowMilliseconds()
            local fixedCandidate = P.BuildAnchorCandidate(source, work.definition, job.styleMode, job.styleContext, true)
            RecordPhase(job, "anchorCandidateScoring", scoringStarted)
            if fixedCandidate then fixedCandidate.locked = true P.AddAnchorPoolCandidate(work, fixedCandidate) end
            return true
        end

        if job.styleEngine and job.styleEngine.GetSourcePreEraEligibility then
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

        if job.styleEngine then
            local eraStarted = NowMilliseconds()
            if job.styleEngine.CreateSourceEraEvidenceWork then
                candidate.eraWork = job.styleEngine.CreateSourceEraEvidenceWork(source)
                if candidate.eraWork.done then candidate.eraEvidence = candidate.eraWork.result end
            elseif job.styleEngine.GetSourceEraEvidence then
                candidate.eraEvidence = job.styleEngine.GetSourceEraEvidence(source)
            end
            RecordPhase(job, "eraEvidence", eraStarted)
        end
    end

    if candidate.eraWork and not candidate.eraWork.done then
        local eraStarted = NowMilliseconds()
        local done, evidence, processed = job.styleEngine.StepSourceEraEvidenceWork(candidate.eraWork, P.GENERATION_ERA_CANDIDATES_PER_OPERATION)
        job.eraCandidatesProcessed = job.eraCandidatesProcessed + (tonumber(processed) or 0)
        RecordPhase(job, "eraEvidence", eraStarted)
        if not done then return false end
        candidate.eraEvidence = evidence
    end

    if job.styleEngine then
        local eligibilityStarted = NowMilliseconds()
        local eligible
        if job.styleEngine.GetSourceEligibilityCached then
            eligible = job.styleEngine.GetSourceEligibilityCached(candidate.source, job.styleMode, job.styleContext, candidate.eraEvidence, candidate.prechecked)
        else
            eligible = job.styleEngine.GetSourceEligibility(candidate.source, job.styleMode, job.styleContext, candidate.eraEvidence, candidate.prechecked)
        end
        RecordPhase(job, "eligibility", eligibilityStarted)
        if not eligible then return true end
    end

    local scoringStarted = NowMilliseconds()
    local anchorCandidate = P.BuildAnchorCandidate(candidate.source, work.definition, job.styleMode, job.styleContext)
    RecordPhase(job, "anchorCandidateScoring", scoringStarted)
    if anchorCandidate then
        anchorCandidate.locked = work.locked
        P.AddAnchorPoolCandidate(work, anchorCandidate)
    end
    return true
end

local function StepPoolWork(job, work)
    if work.done then return true end
    if work.sourceIndex > #work.sources then
        P.FinalizeAnchorPool(work)
        if work.locked and #work.pool == 0 then
            work.requiredMissing = true
            work.missingReason = work.missingReason or string.format("locked %s source is not generation-eligible", work.definition.label or work.slotKey)
        end
        work.done = true
        return true
    end
    local complete = ContinuePoolCandidate(job, work)
    if complete then
        work.candidateWork = nil
        work.sourceIndex = work.sourceIndex + 1
        job.candidatesProcessed = job.candidatesProcessed + 1
    end
    return false
end

local function ApplyArmorNodeToDraft(draft, node, reroll)
    local generated = 0
    for _, slotKey in ipairs(P.ANCHOR_SLOT_ORDER) do
        local candidate = node.sourceBySlot[slotKey]
        if candidate and not draft.locks[slotKey] then
            P.SetSelectedSource(draft, slotKey, candidate.source)
            generated = generated + 1
        elseif not candidate and not draft.locks[slotKey] and not draft.hidden[slotKey] and not reroll then
            P.SetSelectedSource(draft, slotKey, nil)
        end
    end
    return generated
end

local function BuildNodeStyleContext(job, draft, node)
    local context = P.CreateStyleGenerationContext(draft, job.styleEngine, job.styleEngine.GetCurrentContext(), nil, true)
    if job.styleEngine.AddSourceToGenerationContext then
        for _, candidate in ipairs(node.sources or {}) do
            if not draft.locks[candidate.slotKey] then job.styleEngine.AddSourceToGenerationContext(context, candidate.source) end
        end
    end
    return context
end

local function BeginWeaponExpansion(job, work, node)
    local draft = CopyDraftState(job.draft)
    ApplyArmorNodeToDraft(draft, node, job.reroll)
    local styleContext = BuildNodeStyleContext(job, draft, node)
    local weaponWork = P.CreateWeaponGenerationWork and P.CreateWeaponGenerationWork(draft, job.reroll, job.styleMode, styleContext)
    return {
        node = node,
        draft = draft,
        styleContext = styleContext,
        weaponWork = weaponWork,
    }
end

local function FinishWeaponExpansion(job, work, expansion, ok, value, notice)
    if not ok then
        work.lastWeaponFailure = value
        return
    end
    local finalist = P.ScoreWeaponBundleForAnchor(expansion.node, expansion.draft, job.styleMode, expansion.styleContext)
    if finalist then
        finalist.weaponNotice = notice
        work.finalists[#work.finalists + 1] = finalist
    end
end

local function StepWeaponExpansions(job, work)
    local limit = math.min(P.ANCHOR_WEAPON_EXPANSION_LIMIT, #(work.beam or {}))
    if work.weaponNodeIndex > limit then return true end
    if not work.weaponExpansion then
        work.weaponExpansion = BeginWeaponExpansion(job, work, work.beam[work.weaponNodeIndex])
    end
    local expansion = work.weaponExpansion
    local weaponStarted = NowMilliseconds()
    local done, ok, value, notice
    if expansion.weaponWork and P.StepWeaponGenerationWork then
        done, ok, value, notice = P.StepWeaponGenerationWork(expansion.weaponWork)
    else
        done = true
        ok, value, notice = P.GenerateWeapons(expansion.draft, job.reroll, job.styleMode, expansion.styleContext)
    end
    RecordPhase(job, "anchorWeaponExpansion", weaponStarted)
    if expansion.weaponWork and (tonumber(expansion.weaponWork.maxResumeMs) or 0) > (tonumber(job.anchorWeaponSlowYieldMs) or 0) then
        job.anchorWeaponSlowYieldMs = expansion.weaponWork.maxResumeMs
        job.anchorWeaponSlowYieldPhase = expansion.weaponWork.slowestYieldPhase
    end
    if not done then
        job.weaponYields = job.weaponYields + 1
        return false
    end
    FinishWeaponExpansion(job, work, expansion, ok, value, notice)
    work.weaponNodeIndex = work.weaponNodeIndex + 1
    work.weaponExpansion = nil
    return work.weaponNodeIndex > limit
end

local function RebuildSelectedStyleContext(job, selected)
    local context = P.CreateStyleGenerationContext(job.draft, job.styleEngine, job.styleEngine.GetCurrentContext(), nil, true)
    if job.styleEngine.AddSourceToGenerationContext then
        for _, candidate in ipairs(selected.armorNode.sources or {}) do
            if not job.draft.locks[candidate.slotKey] then job.styleEngine.AddSourceToGenerationContext(context, candidate.source) end
        end
        if selected.mainSource and not job.draft.locks[selected.mainSlotKey] then
            job.styleEngine.AddSourceToGenerationContext(context, selected.mainSource)
        end
        if selected.offSource and not job.draft.locks.OFF_HAND then
            job.styleEngine.AddSourceToGenerationContext(context, selected.offSource)
        end
    end
    if job.styleEngine.PrepareGenerationEligibilityContext then job.styleEngine.PrepareGenerationEligibilityContext(context) end
    job.styleContext = context
end

local function CommitSelectedSkeleton(job, work)
    local selected, chosenRank, shortlistSize = P.ChooseAnchorSkeleton(work.finalists, job.draft.lastAnchorSkeletonSignature)
    if not selected or selected.activeComponents < 2 then
        work.fallbackReason = work.lastWeaponFailure or "fewer than two legal anchor components"
        return false
    end

    job.selectedArmor = job.selectedArmor + ApplyArmorNodeToDraft(job.draft, selected.armorNode, job.reroll)
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if slotKey == selected.mainSlotKey then
            P.SetSelectedSource(job.draft, slotKey, selected.mainSource)
        elseif not job.draft.locks[slotKey] then
            P.SetSelectedSource(job.draft, slotKey, nil)
        end
    end
    if selected.offSource then
        P.SetSelectedSource(job.draft, "OFF_HAND", selected.offSource)
    elseif not job.draft.locks.OFF_HAND then
        P.SetSelectedSource(job.draft, "OFF_HAND", nil)
    end
    job.draft.lastWeaponRoute = selected.draft.lastWeaponRoute
    job.draft.lastAnchorSkeletonSignature = selected.signature
    job.weaponCount = selected.weaponCount
    job.weaponNotice = selected.weaponNotice
    RebuildSelectedStyleContext(job, selected)

    local pairSnapshot = P.GetAnchorPairCacheSnapshot()
    job.anchorStats = {
        poolSizes = work.poolSizes,
        expansions = work.beamWork.expansions,
        retained = work.beamWork.retained,
        weaponBundles = #work.finalists,
        chosenRank = chosenRank,
        shortlistSize = shortlistSize,
        chosenScore = selected.score,
        meanPairCohesion = selected.meanPairCohesion,
        hardClashes = selected.hardClashes,
        pairCacheHits = pairSnapshot.hits - (work.pairCacheStarted.hits or 0),
        pairCacheMisses = pairSnapshot.misses - (work.pairCacheStarted.misses or 0),
        fallbackReason = nil,
    }
    local sources = {}
    for slotKey, candidate in pairs(selected.armorNode.sourceBySlot or {}) do sources[slotKey] = candidate.source end
    P.lastAnchorSkeletonDiagnostics = {
        sources = sources,
        mainSource = selected.mainSource,
        offSource = selected.offSource,
        score = selected.score,
        meanPairCohesion = selected.meanPairCohesion,
        hardClashes = selected.hardClashes,
        chosenRank = chosenRank,
        shortlistSize = shortlistSize,
        expansions = work.beamWork.expansions,
        retained = work.beamWork.retained,
        weaponBundles = #work.finalists,
        pairCacheHits = job.anchorStats.pairCacheHits,
        pairCacheMisses = job.anchorStats.pairCacheMisses,
        signature = selected.signature,
        generatedAt = time and time() or 0,
    }
    return true
end

function P.CreateAnchorSkeletonWork(job)
    return {
        stage = "POOLS",
        poolSlotIndex = 1,
        poolWork = nil,
        candidatePools = {},
        poolSizes = {},
        beamWork = nil,
        beam = nil,
        weaponNodeIndex = 1,
        weaponExpansion = nil,
        finalists = {},
        pairCacheStarted = P.GetAnchorPairCacheSnapshot(),
    }
end

function P.StepAnchorSkeletonJob(job, stepStarted)
    local work = job.anchorWork
    if not work then work = P.CreateAnchorSkeletonWork(job) job.anchorWork = work end
    local operations = 0

    while operations < P.GENERATION_OPERATION_SAFETY_CAP do
        if work.stage == "POOLS" then
            if work.poolSlotIndex > #P.ANCHOR_SLOT_ORDER then
                work.beamWork = P.CreateAnchorBeamWork(work.candidatePools)
                work.stage = "BEAM"
            else
                local slotKey = P.ANCHOR_SLOT_ORDER[work.poolSlotIndex]
                if not work.poolWork then work.poolWork = CreatePoolWork(job, slotKey) end
                if StepPoolWork(job, work.poolWork) then
                    if work.poolWork.requiredMissing then
                        work.fallbackReason = work.poolWork.missingReason or "a locked anchor source is unavailable"
                        return "FALLBACK", work.fallbackReason
                    end
                    work.candidatePools[slotKey] = work.poolWork.pool
                    work.poolSizes[slotKey] = #work.poolWork.pool
                    work.poolSlotIndex = work.poolSlotIndex + 1
                    work.poolWork = nil
                end
            end
        elseif work.stage == "BEAM" then
            local beamStarted = NowMilliseconds()
            local done = P.StepAnchorBeamWork(work.beamWork)
            RecordPhase(job, "anchorBeamSearch", beamStarted)
            if done then
                work.beam = work.beamWork.beam
                if not work.beam or #work.beam == 0 or (work.beam[1].activeComponents or 0) == 0 then
                    work.fallbackReason = "no legal armor anchor candidates"
                    return "FALLBACK", work.fallbackReason
                end
                work.stage = "WEAPONS"
            end
        elseif work.stage == "WEAPONS" then
            if StepWeaponExpansions(job, work) then work.stage = "SELECT" end
        elseif work.stage == "SELECT" then
            local selectionStarted = NowMilliseconds()
            local committed = CommitSelectedSkeleton(job, work)
            RecordPhase(job, "anchorSelection", selectionStarted)
            if not committed then return "FALLBACK", work.fallbackReason end
            return "READY"
        end

        operations = operations + 1
        if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then return "RUNNING" end
    end
    return "RUNNING"
end

function P.AdvanceAnchorGenerationPhase(job, stepStarted)
    local status, reason = P.StepAnchorSkeletonJob(job, stepStarted)
    if status == "READY" then
        job.phase = "ARMOR"
        job.armorOrder = P.SUPPORTING_ARMOR_GENERATION_ORDER
        job.armorIndex, job.armorWork = 1, nil
        job.weaponsPrepared = true
    elseif status == "FALLBACK" then
        job.anchorFallbackReason = reason or "anchor search produced no complete skeleton"
        job.anchorStats = nil
        P.lastAnchorSkeletonDiagnostics = {
            fallbackReason = job.anchorFallbackReason,
            generatedAt = time and time() or 0,
        }
        job.phase = "ARMOR"
        job.armorOrder = P.ARMOR_GENERATION_ORDER
        job.armorIndex, job.armorWork = 1, nil
        job.weaponsPrepared = false
        if job.styleEngine then
            job.styleContext = P.CreateStyleGenerationContext(job.draft, job.styleEngine, job.styleEngine.GetCurrentContext(), nil, true)
        end
    end
    return status
end
