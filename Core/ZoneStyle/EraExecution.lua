local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

P.ERA_EXECUTION_GENERATION_COOPERATIVE = "GENERATION_COOPERATIVE"
P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE = "SUPPORT_REROLL_COOPERATIVE"
P.ERA_EXECUTION_BACKGROUND_TICK = "BACKGROUND_TICK"
P.ERA_EXECUTION_SYNCHRONOUS = "SYNCHRONOUS"

local cooperativeModes = {
    [P.ERA_EXECUTION_GENERATION_COOPERATIVE] = true,
    [P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE] = true,
}

function P.NormalizeEraExecutionOptions(options, defaultMode)
    options = type(options) == "table" and options or {}
    local mode = options.executionMode or defaultMode or P.ERA_EXECUTION_SYNCHRONOUS
    return mode, options.schedulerOwner
end

function P.MarkEraEvidenceProgress(work)
    if not work then return 0 end
    work.progressSerial = (tonumber(work.progressSerial) or 0) + 1
    work.lastDeferredSlice = nil
    work.lastDeferredProgressSerial = nil
    return work.progressSerial
end

function P.GetEraEvidenceProgressFingerprint(work)
    if not work then return "none" end
    local candidate = work.candidateWork
    return table.concat({
        tostring(work.progressSerial or 0), tostring(work.sourceIndex or 0),
        tostring(candidate and candidate.stage or ""), tostring(candidate and candidate.setIndex or 0),
        tostring(candidate and candidate.dropIndex or 0), tostring(candidate and candidate.tierIndex or 0),
        tostring(work.done == true),
    }, "|")
end

local function ResolveSchedulerOwner(work, wardrobePrivate)
    if work and work.schedulerOwner then return work.schedulerOwner end
    -- Compatibility only. Production cooperative callers pass an explicit owner.
    if not wardrobePrivate then return nil end
    if work and work.executionMode == P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE then
        return wardrobePrivate.supportRerollJob
    elseif work and work.executionMode == P.ERA_EXECUTION_GENERATION_COOPERATIVE then
        return wardrobePrivate.generationJob
    end
    return nil
end

local function RecordDeferredRetry(work, job, slice)
    local serial = tonumber(work.progressSerial) or 0
    if work.lastDeferredSlice == slice and work.lastDeferredProgressSerial == serial then
        work.sameSliceDeferredRetries = (tonumber(work.sameSliceDeferredRetries) or 0) + 1
        if job then job.eraSameSliceDeferredRetries = (tonumber(job.eraSameSliceDeferredRetries) or 0) + 1 end
    end
    work.lastDeferredSlice = slice
    work.lastDeferredProgressSerial = serial
end

function P.AdmitEraEvidenceOperation(work, operation, fresh)
    if not work then return true end
    local mode = work.executionMode or P.ERA_EXECUTION_SYNCHRONOUS
    if mode == P.ERA_EXECUTION_SYNCHRONOUS or mode == P.ERA_EXECUTION_BACKGROUND_TICK then
        return true
    end
    if not cooperativeModes[mode] then return true end

    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    local job = ResolveSchedulerOwner(work, wardrobePrivate)
    if not job or not job.currentSlice then return true end

    local supportReroll = mode == P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE
    local admitted = true
    if fresh then
        if supportReroll and wardrobePrivate and wardrobePrivate.CanStartFreshSupportRerollPhase then
            admitted = wardrobePrivate.CanStartFreshSupportRerollPhase(job.currentSlice, 0.25)
        elseif wardrobePrivate and wardrobePrivate.CanStartFreshGenerationPhase then
            admitted = wardrobePrivate.CanStartFreshGenerationPhase(job, 0.25)
        end
    elseif supportReroll and wardrobePrivate and wardrobePrivate.CanStartSupportRerollPhase then
        admitted = wardrobePrivate.CanStartSupportRerollPhase(job, job.currentSlice)
    elseif wardrobePrivate and wardrobePrivate.CanStartGenerationPhase then
        admitted = wardrobePrivate.CanStartGenerationPhase(job, 0.5)
    end
    if admitted then return true end

    local slice = job.currentSlice
    RecordDeferredRetry(work, job, slice)
    work.deferredReturns = (tonumber(work.deferredReturns) or 0) + 1
    job.eraDeferredReturns = (tonumber(job.eraDeferredReturns) or 0) + 1
    if fresh then
        work.freshSliceDeferrals = (tonumber(work.freshSliceDeferrals) or 0) + 1
        job.eraFreshSliceDeferrals = (tonumber(job.eraFreshSliceDeferrals) or 0) + 1
    end
    slice.forceYield = true
    work.lastStepDiagnostics = { operation = operation, deferred = true, fresh = fresh == true }
    return false
end

function P.AbortSynchronousEraWork(work, reason)
    if not work then return { pending = true, reason = reason or "Synchronous era evidence made no progress." } end
    P.eraSynchronousProgressGuardTrips = (tonumber(P.eraSynchronousProgressGuardTrips) or 0) + 1
    local result = {
        pending = true,
        unknown = false,
        candidateCount = #(work.sourceIDs or {}),
        reason = reason or "Synchronous era evidence made no progress and was stopped safely.",
        synchronousGuard = true,
    }
    work.done = true
    work.result = result
    work.synchronousGuardTripped = true
    return result
end
