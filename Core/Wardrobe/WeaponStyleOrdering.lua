local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local ZoneStyle = QC.ZoneStyle

P.WEAPON_STYLE_MARKER_BATCH = 4

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

local function Record(work, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    local job = work.job
    if job and P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if job and P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
    return elapsed
end

local function Finish(work)
    if work.recorded then return end
    work.recorded = true
    local job = work.job
    if not job then return end
    job.weaponStyleEligibilitySteps = (tonumber(job.weaponStyleEligibilitySteps) or 0) + work.eligibilitySteps
    job.weaponStyleEligibilityYields = (tonumber(job.weaponStyleEligibilityYields) or 0) + work.eligibilityYields
    job.weaponStyleCoherenceCalls = (tonumber(job.weaponStyleCoherenceCalls) or 0) + work.coherenceCalls
    job.weaponStyleScoringCalls = (tonumber(job.weaponStyleScoringCalls) or 0) + work.scoringCalls
end

function P.CreateWeaponStyleOrderingWork(candidates, modeKey, context, job)
    return {
        candidates = candidates or {},
        modeKey = modeKey,
        context = context,
        job = job or P.activeWeaponGenerationJob,
        stage = "ELIGIBILITY_INIT",
        eligibilityIndex = #(candidates or {}),
        scoringIndex = 1,
        eligibilitySteps = 0,
        eligibilityYields = 0,
        coherenceCalls = 0,
        scoringCalls = 0,
        done = false,
    }
end

function P.StepWeaponStyleOrderingWork(work)
    if not work then return true, "weaponStyleScoring" end
    if work.done then return true, work.lastPhase end

    if work.stage == "ELIGIBILITY_INIT" then
        if work.eligibilityIndex < 1 then
            work.stage = "SCORING"
            work.scoringIndex = 1
            return false, "weaponStyleEligibilityStep"
        end
        local candidate = work.candidates[work.eligibilityIndex]
        work.currentCandidate = candidate
        if ZoneStyle.CreateCachedSourceEligibilityWork then
            work.eligibilityWork = ZoneStyle.CreateCachedSourceEligibilityWork(candidate.source, work.modeKey, work.context)
        else
            work.eligibilityWork = nil
        end
        work.stage = "ELIGIBILITY_STEP"
    end

    if work.stage == "ELIGIBILITY_STEP" then
        local started = NowMilliseconds()
        local done, eligible
        if work.eligibilityWork and ZoneStyle.StepCachedSourceEligibilityWork then
            done, eligible = ZoneStyle.StepCachedSourceEligibilityWork(work.eligibilityWork, P.WEAPON_STYLE_MARKER_BATCH)
        else
            eligible = ZoneStyle.GetSourceEligibilityCached and ZoneStyle.GetSourceEligibilityCached(
                work.currentCandidate.source, work.modeKey, work.context
            ) or ZoneStyle.GetSourceEligibility(work.currentCandidate.source, work.modeKey, work.context)
            done = true
        end
        work.eligibilitySteps = work.eligibilitySteps + 1
        Record(work, "weaponStyleEligibilityStep", started)
        if not done then
            work.eligibilityYields = work.eligibilityYields + 1
            return false, "weaponStyleEligibilityStep"
        end
        work.currentEligible = eligible == true
        work.stage = "COHERENCE"
        return false, "weaponStyleEligibilityStep"
    end

    if work.stage == "COHERENCE" then
        local started = NowMilliseconds()
        local candidate = work.currentCandidate
        local coherenceScore, coherent, coherenceReason = ZoneStyle.GetSourceCoherence(candidate.source, work.context)
        candidate.coherenceScore = coherenceScore
        candidate.coherent = coherent
        candidate.coherenceReason = coherenceReason
        work.coherenceCalls = work.coherenceCalls + 1
        if not work.currentEligible or not coherent then table.remove(work.candidates, work.eligibilityIndex) end
        work.eligibilityIndex = work.eligibilityIndex - 1
        work.currentCandidate, work.eligibilityWork, work.currentEligible = nil, nil, nil
        work.stage = "ELIGIBILITY_INIT"
        Record(work, "weaponStyleCoherence", started)
        return false, "weaponStyleCoherence"
    end

    if work.stage == "SCORING" then
        if work.scoringIndex > #work.candidates then
            work.stage = "SORT"
            return false, "weaponStyleScoring"
        end
        local started = NowMilliseconds()
        local candidate = work.candidates[work.scoringIndex]
        local definition = Wardrobe.GetSlotDefinition and Wardrobe.GetSlotDefinition(candidate.slotKey)
        local weight = ZoneStyle.WeightForSource(
            candidate.source, definition, work.modeKey, work.context,
            candidate.coherenceScore, candidate.coherent, candidate.coherenceReason
        )
        candidate.coherenceScore, candidate.coherent, candidate.coherenceReason = nil, nil, nil
        local roll = math.max(0.000001, math.random())
        candidate.stylePriority = math.log(roll) / weight
        work.scoringCalls = work.scoringCalls + 1
        work.scoringIndex = work.scoringIndex + 1
        Record(work, "weaponStyleScoring", started)
        return false, "weaponStyleScoring"
    end

    if work.stage == "SORT" then
        local started = NowMilliseconds()
        table.sort(work.candidates, function(left, right)
            return (left.stylePriority or -math.huge) > (right.stylePriority or -math.huge)
        end)
        Record(work, "weaponStyleScoring", started)
        work.done = true
        work.lastPhase = "weaponStyleScoring"
        Finish(work)
        return true, work.lastPhase
    end

    work.done = true
    Finish(work)
    return true, "weaponStyleScoring"
end
