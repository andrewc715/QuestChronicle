local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function CopyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function RestoreAnchorBase(job)
    job.draft = P.CopyAnchorDraftState(job.anchorBaseDraft)
    job.selectedArmor = tonumber(job.anchorBaseSelectedArmor) or 0
    job.weaponCount, job.weaponNotice = 0, nil
    job.supportWork, job.supportStats, job.supportDiagnostics = nil, nil, nil
end

local function SelectionOptions(job)
    return {
        action = job.action,
        noveltyContext = job.currentAnchorNovelty
            or (P.BuildAnchorNoveltyContext and P.BuildAnchorNoveltyContext(job.liveState or job.draft)),
        previousSignature = job.anchorBaseDraft and job.anchorBaseDraft.lastAnchorSkeletonSignature
            or job.draft.lastAnchorSkeletonSignature,
    }
end

local function ApplySelectedSkeleton(job, work, selected, chosenRank, shortlistSize, selectionDetails, alternate)
    if not selected or selected.activeComponents < 2 then
        work.fallbackReason = work.lastWeaponFailure or "fewer than two legal anchor components"
        return false
    end
    if alternate then RestoreAnchorBase(job) end
    job.selectedArmor = job.selectedArmor + P.ApplyArmorNodeToDraft(job.draft, selected.armorNode, job.reroll)
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if slotKey == selected.mainSlotKey then P.SetSelectedSource(job.draft, slotKey, selected.mainSource)
        elseif not job.draft.locks[slotKey] then P.SetSelectedSource(job.draft, slotKey, nil) end
    end
    if selected.offSource then P.SetSelectedSource(job.draft, "OFF_HAND", selected.offSource)
    elseif not job.draft.locks.OFF_HAND then P.SetSelectedSource(job.draft, "OFF_HAND", nil) end
    job.draft.lastWeaponRoute = selected.draft.lastWeaponRoute
    job.draft.lastAnchorSkeletonSignature = selected.signature
    job.weaponCount, job.weaponNotice = selected.weaponCount, selected.weaponNotice
    P.RebuildSelectedStyleContext(job, selected)
    local pairSnapshot = P.GetAnchorPairCacheSnapshot()
    local selectedDiagnostics = P.BuildSelectedAnchorDiagnostics(selected, selectionDetails)
    job.anchorStats = {
        poolSizes = work.poolSizes, expansions = work.beamWork.expansions, retained = work.beamWork.retained,
        weaponBundles = #work.finalists, chosenRank = chosenRank, shortlistSize = shortlistSize,
        chosenScore = selected.score, baseSkeletonScore = selectionDetails and selectionDetails.baseScore or selected.score,
        adjustedSelectionScore = selectionDetails and selectionDetails.adjustedScore or selected.score,
        repeatPenalty = selectionDetails and selectionDetails.repeatPenalty or 0,
        noveltyClass = selectionDetails and selectionDetails.class or nil,
        comparedComponents = selectionDetails and selectionDetails.comparedComponents or {},
        changedComponents = selectionDetails and selectionDetails.changedComponents or {},
        repeatedComponents = selectionDetails and selectionDetails.repeatedComponents or {},
        exactRepeatAccepted = selectionDetails and selectionDetails.exactRepeatAccepted == true or false,
        exactRepeatReason = selectionDetails and selectionDetails.exactRepeatReason or nil,
        meanPairCohesion = selected.meanPairCohesion, hardClashes = selected.hardClashes,
        pairCacheHits = pairSnapshot.hits - (work.pairCacheStarted.hits or 0),
        pairCacheMisses = pairSnapshot.misses - (work.pairCacheStarted.misses or 0),
        fallbackReason = nil, alternateSkeleton = alternate == true,
        initialChosenRank = alternate and job.initialAnchorRank or nil,
        initialSignature = alternate and job.initialAnchorSignature or nil,
    }
    local sources = {}
    for slotKey, candidate in pairs(selected.armorNode.sourceBySlot or {}) do sources[slotKey] = candidate.source end
    P.lastAnchorSkeletonDiagnostics = {
        sources = sources, mainSource = selected.mainSource, offSource = selected.offSource,
        score = selected.score, baseSkeletonScore = selectionDetails and selectionDetails.baseScore or selected.score,
        adjustedSelectionScore = selectionDetails and selectionDetails.adjustedScore or selected.score,
        repeatPenalty = selectionDetails and selectionDetails.repeatPenalty or 0,
        noveltyClass = selectionDetails and selectionDetails.class or nil,
        comparedComponents = selectionDetails and selectionDetails.comparedComponents or {},
        changedComponents = selectionDetails and selectionDetails.changedComponents or {},
        repeatedComponents = selectionDetails and selectionDetails.repeatedComponents or {},
        exactRepeatAccepted = selectionDetails and selectionDetails.exactRepeatAccepted == true or false,
        exactRepeatReason = selectionDetails and selectionDetails.exactRepeatReason or nil,
        meanPairCohesion = selected.meanPairCohesion, hardClashes = selected.hardClashes,
        chosenRank = chosenRank, shortlistSize = shortlistSize,
        expansions = work.beamWork.expansions, retained = work.beamWork.retained,
        weaponBundles = #work.finalists, pairCacheHits = job.anchorStats.pairCacheHits,
        pairCacheMisses = job.anchorStats.pairCacheMisses, signature = selected.signature,
        candidates = selectedDiagnostics.candidates, cohesionComponents = selectedDiagnostics.cohesionComponents,
        strongestBridge = selectedDiagnostics.strongestBridge,
        weakestRelationship = selectedDiagnostics.weakestRelationship,
        scoreBreakdown = selectedDiagnostics.scoreBreakdown, poolSizes = work.poolSizes,
        alternateSkeleton = alternate == true, initialChosenRank = alternate and job.initialAnchorRank or nil,
        initialSignature = alternate and job.initialAnchorSignature or nil,
        generatedAt = time and time() or 0,
    }
    job.anchorDiagnostics = P.lastAnchorSkeletonDiagnostics
    job.anchorUsedSignatures = job.anchorUsedSignatures or {}
    job.anchorUsedSignatures[selected.signature] = true
    if not alternate then
        job.initialAnchorRank, job.initialAnchorSignature = chosenRank, selected.signature
    else
        job.phaseDAlternateInfo = {
            initialRank = job.initialAnchorRank, finalRank = chosenRank,
            initialSignature = job.initialAnchorSignature, finalSignature = selected.signature,
        }
    end
    return true
end

function P.CommitInitialAnchorSkeleton(job, work)
    job.anchorBaseDraft = job.anchorBaseDraft or P.CopyAnchorDraftState(job.draft)
    job.anchorBaseSelectedArmor = job.anchorBaseSelectedArmor or job.selectedArmor
    job.anchorSelectionOptions = job.anchorSelectionOptions or SelectionOptions(job)
    job.anchorFinalists = work.finalists
    local selected, chosenRank, shortlistSize, details = P.ChooseAnchorSkeleton(work.finalists, job.anchorSelectionOptions)
    return ApplySelectedSkeleton(job, work, selected, chosenRank, shortlistSize, details, false)
end

function P.ApplyNextAnchorSkeleton(job)
    local work = job.anchorWork
    if not work or not job.anchorFinalists then return false, "The original anchor finalist set is unavailable." end
    local selected, chosenRank, shortlistSize, details = P.GetNextAnchorSkeleton(
        job.anchorFinalists, job.anchorSelectionOptions or SelectionOptions(job), job.anchorUsedSignatures
    )
    if not selected then return false, "No unused valid anchor skeleton remained after support repair." end
    if not ApplySelectedSkeleton(job, work, selected, chosenRank, shortlistSize, details, true) then
        return false, work.fallbackReason or "The alternate anchor skeleton could not be applied."
    end
    return true
end
