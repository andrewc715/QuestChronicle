local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function RecordPhase(job, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
    return elapsed
end

local ANCHOR_CANDIDATE_PHASES = {
    ERA_INIT = "anchorCandidateEra",
    ERA_STEP = "anchorCandidateEra",
    METADATA_SNAPSHOT = "anchorCandidateMetadata",
    SET_IDS_SNAPSHOT = "anchorCandidateSetIDs",
    STYLE_SIGNALS = "anchorCandidateStyleSignals",
    COHERENCE = "anchorCandidateCoherence",
    LEGACY_SCORE = "anchorCandidateLegacyScore",
    DESCRIPTOR = "anchorCandidateDescriptor",
    POOL_RANDOM = "anchorCandidateRandom",
    TRACKING = "anchorCandidateTracking",
    ZONE_AFFINITY = "anchorCandidateAffinity",
    ZONE_POLICY_APPLY = "anchorCandidatePolicy",
    PREFERENCE = "anchorCandidateFinalize",
}

function P.IsCooperativeZoneAnchorJob(job)
    return job and job.modePolicy and job.modePolicy.capabilities
        and job.modePolicy.capabilities.zoneAnchorPolicy == true
        and P.CreateAnchorCandidateWork and P.StepAnchorCandidateWork
end

function P.StepPreparedAnchorCandidateForWorker(job, candidate, definition, fixed)
    if not candidate.anchorCandidateWork then
        candidate.anchorCandidateWork = P.CreateAnchorCandidateWork(
            job, candidate.source, definition, job.styleContext, fixed == true, candidate.eraEvidence
        )
    end
    local candidateWork = candidate.anchorCandidateWork
    local operation = P.DescribeNextAnchorCandidateOperation
        and P.DescribeNextAnchorCandidateOperation(candidateWork)
        or { class = "LOCAL", phase = candidateWork.stage, reserveMs = 1.0 }
    if operation.class == "API_HEADROOM" and P.CanStartGenerationPhase
        and not P.CanStartGenerationPhase(job, operation.reserveMs or 3.0)
    then
        job.anchorCandidateAdmissionDeferrals = (tonumber(job.anchorCandidateAdmissionDeferrals) or 0) + 1
        job.anchorCandidateYieldRequested = true
        return false, nil
    elseif operation.class == "LOCAL" and P.CanStartGenerationPhase
        and not P.CanStartGenerationPhase(job, 0.5)
    then
        job.anchorCandidateYieldRequested = true
        return false, nil
    end

    local stage = candidateWork.stage
    local started = NowMilliseconds()
    local done, result = P.StepAnchorCandidateWork(candidateWork)
    local elapsed = RecordPhase(job, ANCHOR_CANDIDATE_PHASES[stage] or "anchorCandidateFinalize", started)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, "anchorCandidateScoring", elapsed) end
    job.anchorCandidateSubsteps = (tonumber(job.anchorCandidateSubsteps) or 0) + 1
    if candidateWork.lastInvokedAPI then
        job.anchorCandidateAPIOperations = (tonumber(job.anchorCandidateAPIOperations) or 0) + 1
        if candidateWork.lastAPIKind == "metadata" then job.anchorCandidateMetadataAPICalls = (tonumber(job.anchorCandidateMetadataAPICalls) or 0) + 1
        elseif candidateWork.lastAPIKind == "set" then job.anchorCandidateSetAPICalls = (tonumber(job.anchorCandidateSetAPICalls) or 0) + 1
        elseif candidateWork.lastAPIKind == "tracking" then job.anchorCandidateTrackingAPICalls = (tonumber(job.anchorCandidateTrackingAPICalls) or 0) + 1 end
    elseif candidateWork.lastPreparedHit == "metadata" then job.anchorCandidatePreparedMetadataHits = (tonumber(job.anchorCandidatePreparedMetadataHits) or 0) + 1
    elseif candidateWork.lastPreparedHit == "set" then job.anchorCandidatePreparedSetHits = (tonumber(job.anchorCandidatePreparedSetHits) or 0) + 1
    elseif candidateWork.lastPreparedHit == "tracking" then job.anchorCandidatePreparedTrackingHits = (tonumber(job.anchorCandidatePreparedTrackingHits) or 0) + 1 end
    if done then
        job.anchorCandidateCompletions = (tonumber(job.anchorCandidateCompletions) or 0) + 1
        return true, result
    end
    return false, nil
end

function P.ConsumeAnchorCandidateYieldRequest(job)
    if not job or not job.anchorCandidateYieldRequested then return false end
    job.anchorCandidateYieldRequested = nil
    return true
end

function P.StepWeaponAnchorScoringForWorker(job, work, expansion)
    if not expansion.scoreWork then
        expansion.scoreWork = P.CreateWeaponAnchorScoringWork(job, expansion.node, expansion.draft, expansion.styleContext)
    end
    local scoreWork = expansion.scoreWork
    local operation = P.DescribeNextWeaponAnchorScoringOperation
        and P.DescribeNextWeaponAnchorScoringOperation(scoreWork)
        or { class = "LOCAL", phase = scoreWork.stage, reserveMs = 0.75 }
    if operation.class == "API_HEADROOM" and P.CanStartGenerationPhase
        and not P.CanStartGenerationPhase(job, operation.reserveMs or 3.0)
    then
        job.anchorCandidateAdmissionDeferrals = (tonumber(job.anchorCandidateAdmissionDeferrals) or 0) + 1
        job.anchorCandidateYieldRequested = true
        return false
    elseif P.CanStartGenerationPhase and not P.CanStartGenerationPhase(job, operation.reserveMs or 0.75) then
        job.anchorCandidateYieldRequested = true
        return false
    end

    local stage = scoreWork.stage
    local started = NowMilliseconds()
    local done, finalist = P.StepWeaponAnchorScoringWork(scoreWork)
    local elapsed = RecordPhase(job, (stage == "RELATIONSHIP" or stage == "WEAPON_PAIR")
        and "anchorWeaponRelationship" or "anchorWeaponCandidateScoring", started)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, "weaponBundleCohesion", elapsed) end
    if not done then return false end
    if finalist then
        finalist.weaponNotice = expansion.notice
        work.finalists[#work.finalists + 1] = finalist
    end
    return true
end
