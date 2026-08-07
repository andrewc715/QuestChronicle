local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.pendingEraReevaluationQueue = P.pendingEraReevaluationQueue or {}
P.pendingEraReevaluationByVisual = P.pendingEraReevaluationByVisual or {}
P.PENDING_ERA_RESOLVER_BUDGET_MS = 2.5

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

local function VisualKey(source)
    return P.GetGenerationCacheVisualKey and P.GetGenerationCacheVisualKey(source) or
        tostring(source and source.visualID or "")
end

local function Schedule(delay)
    if P.pendingEraResolverScheduled then return end
    P.pendingEraResolverScheduled = true
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay or 0, function()
            P.pendingEraResolverScheduled = false
            P.StepPendingEraEvidenceReevaluations()
        end)
    else
        P.pendingEraResolverScheduled = false
        P.StepPendingEraEvidenceReevaluations()
    end
end

local function ApplyResolvedResult(job, result)
    local newFingerprint = P.BuildEraEvidenceOutcomeFingerprint(result)
    local changed = newFingerprint ~= job.outcomeFingerprint
    if changed then
        P.InvalidatePersistentGenerationEligibilityForSource(
            job.source, "EVIDENCE_OUTCOME_CHANGED"
        )
        P.NoteGenerationItemEvent("changed", 1)
    else
        P.NoteGenerationItemEvent("unchanged", 1)
    end

    local zonePrivate = QC.ZoneStyle and QC.ZoneStyle._Private
    local evidenceVersion = zonePrivate and zonePrivate.ERA_EVIDENCE_VERSION or
        job.evidenceVersion or 0
    P.StorePersistentEraEvidence(
        job.source, result, result.candidateCount or job.candidateCount,
        evidenceVersion
    )
    if P.ClearSourceEraDependentFields then P.ClearSourceEraDependentFields(job.source) end
    P.RestorePersistentGenerationFields(job.source, evidenceVersion)
    if changed and QC.Notify and job.source.sourceID then
        QC.Notify("WARDROBE_SOURCE_METADATA_UPDATED", {
            sourceIDs = { [job.source.sourceID] = true },
            reason = "EVIDENCE_OUTCOME_CHANGED",
            changedCount = 1,
        })
    end
end

local function FinishJob(job, result)
    ApplyResolvedResult(job, result or {
        pending = true,
        reason = "Era evidence remained unavailable after item-data resolution.",
    })
    local key = VisualKey(job.source)
    P.pendingEraReevaluationByVisual[key] = nil
    table.remove(P.pendingEraReevaluationQueue, 1)
end

function P.QueuePendingEraEvidenceReevaluation(source, record)
    if not source or not record then return false end
    local key = VisualKey(source)
    if not key or P.pendingEraReevaluationByVisual[key] then
        if key then P.NoteGenerationItemEvent("coalesced", 1) end
        return false
    end
    local job = {
        source = source,
        outcomeFingerprint = record.outcomeFingerprint or
            P.BuildEraEvidenceOutcomeFingerprint(record),
        candidateCount = record.candidateCount,
        evidenceVersion = record.evidenceVersion,
    }
    P.pendingEraReevaluationByVisual[key] = job
    P.pendingEraReevaluationQueue[#P.pendingEraReevaluationQueue + 1] = job
    Schedule(0)
    return true
end

function P.StepPendingEraEvidenceReevaluations(force)
    if not force and (P.generationJob or Wardrobe.scanning == true) then
        Schedule(0.05)
        return false
    end
    local started = NowMilliseconds()
    while #P.pendingEraReevaluationQueue > 0 do
        local job = P.pendingEraReevaluationQueue[1]
        if not job.work then
            local zoneStyle = QC.ZoneStyle
            if not zoneStyle or type(zoneStyle.CreateSourceEraEvidenceWork) ~= "function" then
                Schedule(0.05)
                return false
            end
            job.work = zoneStyle.CreateSourceEraEvidenceWork(job.source, {
                forceRefresh = true, suppressCache = true,
                executionMode = zoneStyle._Private and zoneStyle._Private.ERA_EXECUTION_BACKGROUND_TICK,
                schedulerOwner = job,
            })
        end

        local done, result = QC.ZoneStyle.StepSourceEraEvidenceWork(job.work, 1)
        if done then FinishJob(job, result)
        elseif not force then
            -- One nested era operation per background tick keeps pending
            -- reevaluation from recreating a monolithic candidate bundle.
            Schedule(0)
            return false
        end
        if not force and NowMilliseconds() - started >= P.PENDING_ERA_RESOLVER_BUDGET_MS then
            Schedule(0)
            return false
        end
    end
    return true
end

function P.FlushPendingEraEvidenceReevaluations()
    local guard = 0
    while #P.pendingEraReevaluationQueue > 0 and guard < 100000 do
        P.StepPendingEraEvidenceReevaluations(true)
        guard = guard + 1
    end
    return #P.pendingEraReevaluationQueue == 0
end
