local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
local Workers = QC._Core and QC._Core.Workers

P.ERA_EXECUTION_GENERATION_COOPERATIVE = "GENERATION_COOPERATIVE"
P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE = "SUPPORT_REROLL_COOPERATIVE"
P.ERA_EXECUTION_BACKGROUND_TICK = "BACKGROUND_TICK"
P.ERA_EXECUTION_SYNCHRONOUS = "SYNCHRONOUS"

P.ERA_ADMISSION_LOCAL = "LOCAL"
P.ERA_ADMISSION_API_HEADROOM = "API_HEADROOM"
P.ERA_ADMISSION_FRESH_ONLY = "FRESH_ONLY"
P.ERA_ADMISSION_COMPLETE = "COMPLETE"
P.ERA_API_RESERVE_MS = 3.0

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
    if not wardrobePrivate then return nil end
    if work and work.executionMode == P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE then
        return wardrobePrivate.supportRerollJob
    elseif work and work.executionMode == P.ERA_EXECUTION_GENERATION_COOPERATIVE then
        return wardrobePrivate.generationJob
    end
    return nil
end

function P.GetEraSchedulerOwner(work)
    return ResolveSchedulerOwner(work, QC.Wardrobe and QC.Wardrobe._Private)
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

local function NormalizeAdmission(admission, reserveMs)
    if type(admission) == "table" then
        return admission.admission or P.ERA_ADMISSION_LOCAL,
            tonumber(admission.reserveMs) or tonumber(reserveMs) or P.ERA_API_RESERVE_MS,
            admission.willInvokeAPI == true
    end
    if admission == true then return P.ERA_ADMISSION_FRESH_ONLY, tonumber(reserveMs) or 0.25, true end
    if admission == false or admission == nil then return P.ERA_ADMISSION_LOCAL, tonumber(reserveMs) or 0, false end
    return tostring(admission), tonumber(reserveMs) or P.ERA_API_RESERVE_MS,
        admission == P.ERA_ADMISSION_API_HEADROOM or admission == P.ERA_ADMISSION_FRESH_ONLY
end

local function CanStartAPIHeadroom(job, slice, reserveMs)
    if not slice or slice.forceYield then return false end
    reserveMs = math.max(0, tonumber(reserveMs) or P.ERA_API_RESERVE_MS)
    if Workers and Workers.CanStartPhase then return Workers.CanStartPhase(slice, reserveMs) end
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    if wardrobePrivate and wardrobePrivate.CanStartGenerationPhase then
        return wardrobePrivate.CanStartGenerationPhase(job, reserveMs)
    end
    return true
end

local function CanStartFresh(work, job, slice)
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    if work.executionMode == P.ERA_EXECUTION_SUPPORT_REROLL_COOPERATIVE
        and wardrobePrivate and wardrobePrivate.CanStartFreshSupportRerollPhase
    then
        return wardrobePrivate.CanStartFreshSupportRerollPhase(slice, 0.25)
    elseif wardrobePrivate and wardrobePrivate.CanStartFreshGenerationPhase then
        return wardrobePrivate.CanStartFreshGenerationPhase(job, 0.25)
    end
    return (tonumber(slice and slice.operationCount) or 0) == 0 and not (slice and slice.forceYield)
end

function P.AdmitEraEvidenceOperation(work, operation, admission, reserveMs)
    if not work then return true end
    local admissionClass, reserve, willInvokeAPI = NormalizeAdmission(admission, reserveMs)
    if admissionClass == P.ERA_ADMISSION_COMPLETE or admissionClass == P.ERA_ADMISSION_LOCAL then return true end

    local mode = work.executionMode or P.ERA_EXECUTION_SYNCHRONOUS
    if mode == P.ERA_EXECUTION_SYNCHRONOUS or mode == P.ERA_EXECUTION_BACKGROUND_TICK then return true end
    if not cooperativeModes[mode] then return true end

    local job = P.GetEraSchedulerOwner(work)
    if not job or not job.currentSlice then return true end
    local slice = job.currentSlice
    local admitted = admissionClass == P.ERA_ADMISSION_FRESH_ONLY
        and CanStartFresh(work, job, slice)
        or CanStartAPIHeadroom(job, slice, reserve)

    if admitted then
        if willInvokeAPI then
            work.apiAdmissions = (tonumber(work.apiAdmissions) or 0) + 1
            job.eraApiAdmissions = (tonumber(job.eraApiAdmissions) or 0) + 1
        end
        return true
    end

    RecordDeferredRetry(work, job, slice)
    work.deferredReturns = (tonumber(work.deferredReturns) or 0) + 1
    job.eraDeferredReturns = (tonumber(job.eraDeferredReturns) or 0) + 1
    if admissionClass == P.ERA_ADMISSION_API_HEADROOM then
        work.apiHeadroomDeferrals = (tonumber(work.apiHeadroomDeferrals) or 0) + 1
        job.eraApiHeadroomDeferrals = (tonumber(job.eraApiHeadroomDeferrals) or 0) + 1
    elseif admissionClass == P.ERA_ADMISSION_FRESH_ONLY then
        work.freshOnlyDeferrals = (tonumber(work.freshOnlyDeferrals) or 0) + 1
        work.freshSliceDeferrals = (tonumber(work.freshSliceDeferrals) or 0) + 1
        job.eraFreshOnlyDeferrals = (tonumber(job.eraFreshOnlyDeferrals) or 0) + 1
        job.eraFreshSliceDeferrals = (tonumber(job.eraFreshSliceDeferrals) or 0) + 1
    end
    work.pendingDeferredOperation = operation
    work.pendingDeferredAdmission = admissionClass
    slice.forceYield = true
    work.lastStepDiagnostics = {
        operation = operation, deferred = true, admission = admissionClass,
        reserveMs = reserve, willInvokeAPI = willInvokeAPI,
    }
    return false
end

function P.ResolveEraDeferredAdmission(work, operation, apiInvoked)
    if not work or not work.pendingDeferredOperation then return false end
    if tostring(work.pendingDeferredOperation) ~= tostring(operation) then return false end
    local job = P.GetEraSchedulerOwner(work)
    if not apiInvoked then
        work.phantomDeferrals = (tonumber(work.phantomDeferrals) or 0) + 1
        if job then job.eraPhantomDeferrals = (tonumber(job.eraPhantomDeferrals) or 0) + 1 end
    end
    work.pendingDeferredOperation, work.pendingDeferredAdmission = nil, nil
    return true
end

function P.AbortSynchronousEraWork(work, reason)
    if not work then return { pending = true, reason = reason or "Synchronous era evidence made no progress." } end
    P.eraSynchronousProgressGuardTrips = (tonumber(P.eraSynchronousProgressGuardTrips) or 0) + 1
    local result = {
        pending = true, unknown = false, candidateCount = #(work.sourceIDs or {}),
        reason = reason or "Synchronous era evidence made no progress and was stopped safely.",
        synchronousGuard = true,
    }
    work.done, work.result, work.synchronousGuardTripped = true, result, true
    return result
end
