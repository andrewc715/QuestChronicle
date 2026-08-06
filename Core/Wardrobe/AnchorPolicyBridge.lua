local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local REQUIRED_CALLBACKS = {
    "GetAnchorSlots",
    "GetAnchorSearchConfiguration",
    "EvaluateAnchorCandidate",
    "ScoreAnchorPair",
    "ScoreAnchorSkeleton",
    "BuildNoveltyReference",
    "ClassifyNovelty",
}

local function GetGeneration()
    return QC.Generation
end

local function ResolveModePolicy(modeID, sharedPolicy)
    if sharedPolicy then return sharedPolicy end
    local Generation = GetGeneration()
    if not Generation or type(Generation.GetGenerationMode) ~= "function" then return nil end
    local policy = Generation.GetGenerationMode(modeID)
    return policy
end

function P.AttachGenerationModePolicy(job)
    if not job then return nil end
    local modeID = job.requestedStyleMode or (job.liveState and job.liveState.styleMode)
    job.modePolicy = job.modePolicy or ResolveModePolicy(modeID, job.sharedFrameworkPolicy)
    job.anchorPolicy = job.anchorPolicy or (job.modePolicy and job.modePolicy.anchorPolicy)
    return job.modePolicy
end

local function MarkPolicyFailure(job, callbackName, reason)
    if not job then return end
    job.anchorPolicyFatalError = string.format(
        "Zone anchor policy callback %s failed: %s",
        tostring(callbackName), tostring(reason or "unknown error")
    )
end

local function CallPolicy(job, callbackName, ...)
    local policy = job and job.anchorPolicy
    local callback = policy and policy[callbackName]
    if type(callback) ~= "function" then return false, nil end
    local started = P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or nil
    local ok, a, b, c, d, e = pcall(callback, ...)
    if started and job and job.modePolicy and job.modePolicy.capabilities
        and job.modePolicy.capabilities.zoneAnchorPolicy == true and P.RecordGenerationPhase
    then
        local elapsed = math.max(0, (P.GenerationNowMilliseconds() or started) - started)
        P.RecordGenerationPhase(job, "zoneAnchorPolicy", elapsed)
        if P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
    end
    if not ok then
        MarkPolicyFailure(job, callbackName, a)
        return true, nil
    end
    return true, a, b, c, d, e
end

function P.ValidateAttachedAnchorPolicy(job)
    local policy = job and job.anchorPolicy
    local capabilities = job and job.modePolicy and job.modePolicy.capabilities or {}
    if capabilities.zoneAnchorPolicy ~= true then return true end
    if type(policy) ~= "table" then return false, "Zone Native registered no anchor policy." end
    for _, callbackName in ipairs(REQUIRED_CALLBACKS) do
        if type(policy[callbackName]) ~= "function" then
            return false, "Zone anchor policy is missing callback " .. callbackName .. "."
        end
    end
    return true
end

function P.GetAnchorSlotsForJob(job)
    local called, slots = CallPolicy(job, "GetAnchorSlots", job)
    if not called or type(slots) ~= "table" then slots = P.ANCHOR_SLOT_ORDER end
    local armor = {}
    for _, slotKey in ipairs(slots or {}) do
        if slotKey ~= "WEAPON_BUNDLE" then armor[#armor + 1] = slotKey end
    end
    return armor
end

function P.GetAnchorSearchConfigurationForJob(job)
    local called, config = CallPolicy(job, "GetAnchorSearchConfiguration", job)
    if not called or type(config) ~= "table" then config = {} end
    return {
        beamWidth = math.max(1, math.floor(tonumber(config.beamWidth) or P.ANCHOR_BEAM_WIDTH or 32)),
        finalShortlist = math.max(1, math.floor(tonumber(config.finalShortlist) or P.ANCHOR_FINAL_SHORTLIST or 6)),
        scoreWindow = math.max(0, tonumber(config.scoreWindow) or P.ANCHOR_FINAL_SCORE_WINDOW or 28),
    }
end

function P.EvaluateAnchorCandidateForJob(job, source, definition, styleContext, fixed)
    local called, candidate = CallPolicy(
        job,
        "EvaluateAnchorCandidate",
        source,
        definition,
        job and job.styleMode,
        styleContext or (job and job.styleContext),
        fixed == true,
        job
    )
    if called then return candidate end
    return P.BuildAnchorCandidate(source, definition, job and job.styleMode, styleContext or (job and job.styleContext), fixed)
end

function P.ScoreAnchorRelationshipForJob(job, left, right)
    local called, bonus, pairScore, components, hardClash, details = CallPolicy(
        job, "ScoreAnchorPair", left, right, job
    )
    if called then
        if bonus == nil then return 0, 0.50, nil, false, nil end
        return bonus, pairScore, components, hardClash, details
    end
    return P.ScoreAnchorRelationship(left, right)
end

function P.ScoreAnchorSkeletonForJob(job, node, draft, styleContext)
    local called, result = CallPolicy(
        job,
        "ScoreAnchorSkeleton",
        node,
        draft,
        job and job.styleMode,
        styleContext or (job and job.styleContext),
        job
    )
    if called then return result end
    return P.ScoreWeaponBundleForAnchor(node, draft, job and job.styleMode, styleContext or (job and job.styleContext), job)
end

function P.BuildAnchorNoveltyReferenceForJob(job, state)
    local called, reference = CallPolicy(job, "BuildNoveltyReference", state, job)
    if called then return reference end
    return P.BuildAnchorNoveltyContext and P.BuildAnchorNoveltyContext(state) or nil
end

function P.ClassifyAnchorNoveltyForOptions(entry, context, options)
    local job = options and options.job
    local called, novelty = CallPolicy(job, "ClassifyNovelty", entry, context, job)
    if called and novelty then return novelty end
    if called then
        return {
            class = nil, classPriority = 0, baseScore = tonumber(entry and entry.score) or 0,
            adjustedScore = tonumber(entry and entry.score) or 0, repeatPenalty = 0,
            comparedComponents = {}, changedComponents = {}, repeatedComponents = {},
            comparedCount = 0, changedCount = 0, repeatedCount = 0,
        }
    end
    return P.EvaluateAnchorNovelty and P.EvaluateAnchorNovelty(entry, context) or nil
end

function P.CaptureAnchorPolicyContext(job)
    if not job or not job.modePolicy then return true end
    local capabilities = job.modePolicy.capabilities or {}
    if capabilities.zoneAnchorPolicy ~= true then return true end
    local contextPolicy = job.modePolicy.contextPolicy
    local builder = contextPolicy and contextPolicy.BuildModeContext
    local validator = contextPolicy and contextPolicy.ValidateContext
    if type(builder) ~= "function" or type(validator) ~= "function" then
        job.zoneAnchorPolicyFallback = "LEGACY_SCORE"
        job.zoneAnchorPolicyFallbackReason = "Zone context policy is unavailable."
        return true
    end
    local ok, snapshot = pcall(builder)
    if not ok or not validator(snapshot) then
        job.zoneAnchorPolicyFallback = "LEGACY_SCORE"
        job.zoneAnchorPolicyFallbackReason = ok and "Zone context snapshot validation failed." or tostring(snapshot)
        return true
    end
    job.modeContext = snapshot
    job.modeContextFingerprint = snapshot.fingerprint
    job.zoneContextStaleAtCommit = false
    return true
end

function P.ValidateAnchorPolicyContextAtCommit(job)
    if not job or not job.modePolicy then return true end
    local capabilities = job.modePolicy.capabilities or {}
    if capabilities.zoneAnchorPolicy ~= true or job.zoneAnchorPolicyFallback then return true end
    local contextPolicy = job.modePolicy.contextPolicy
    local builder = contextPolicy and contextPolicy.BuildModeContext
    local validator = contextPolicy and contextPolicy.ValidateContext
    if type(builder) ~= "function" or type(validator) ~= "function" then return true end
    local ok, current = pcall(builder)
    if not ok or not validator(current) then
        job.zoneContextStaleAtCommit = true
        job.zoneContextCurrentFingerprint = nil
        return false, "Zone context became unavailable while Quest Chronicle was preparing the outfit; the previous preview was preserved."
    end
    job.zoneContextCurrentFingerprint = current.fingerprint
    if tostring(current.fingerprint) ~= tostring(job.modeContextFingerprint) then
        job.zoneContextStaleAtCommit = true
        return false, "Zone context changed while Quest Chronicle was preparing the outfit; the previous preview was preserved."
    end
    job.zoneContextStaleAtCommit = false
    return true
end

function P.NewAnchorPolicyPoolStats(slotKey)
    return {
        slotKey = slotKey,
        evaluated = 0,
        unknown = 0,
        offZone = 0,
        weakLocal = 0,
        supportedLocal = 0,
        strongLocal = 0,
        affinityTotal = 0,
        confidenceTotal = 0,
        adjustmentTotal = 0,
        minimumAdjustment = nil,
        maximumAdjustment = nil,
    }
end

function P.RecordAnchorPolicyCandidate(work, candidate)
    local details = candidate and candidate.anchorPolicy
    if not work or not details then return end
    local stats = work.policyStats or P.NewAnchorPolicyPoolStats(work.slotKey)
    work.policyStats = stats
    stats.evaluated = stats.evaluated + 1
    stats.affinityTotal = stats.affinityTotal + (tonumber(details.zoneAffinity) or 0)
    stats.confidenceTotal = stats.confidenceTotal + (tonumber(details.zoneConfidence) or 0)
    local adjustment = tonumber(details.zoneAdjustment) or 0
    stats.adjustmentTotal = stats.adjustmentTotal + adjustment
    stats.minimumAdjustment = stats.minimumAdjustment == nil and adjustment or math.min(stats.minimumAdjustment, adjustment)
    stats.maximumAdjustment = stats.maximumAdjustment == nil and adjustment or math.max(stats.maximumAdjustment, adjustment)
    local class = tostring(details.zoneClassification or "UNKNOWN")
    if class == "UNKNOWN" or class == "PARTIAL_EVIDENCE" then stats.unknown = stats.unknown + 1
    elseif class == "OFF_ZONE_SIGNAL" then stats.offZone = stats.offZone + 1
    elseif class == "WEAK_LOCAL_SIGNAL" then stats.weakLocal = stats.weakLocal + 1
    elseif class == "SUPPORTED_LOCAL_VARIATION" or class == "LOCALLY_COHERENT" then stats.supportedLocal = stats.supportedLocal + 1
    elseif class == "STRONGLY_NATIVE" then stats.strongLocal = stats.strongLocal + 1 end
end

function P.FinalizeAnchorPolicyPoolStats(work)
    local stats = work and work.policyStats
    if not stats then return nil end
    local count = math.max(1, tonumber(stats.evaluated) or 0)
    return {
        slotKey = stats.slotKey,
        prepared = #(work.sources or {}),
        eligible = tonumber(stats.evaluated) or 0,
        retained = #(work.pool or {}),
        unknown = tonumber(stats.unknown) or 0,
        offZone = tonumber(stats.offZone) or 0,
        weakLocal = tonumber(stats.weakLocal) or 0,
        supportedLocal = tonumber(stats.supportedLocal) or 0,
        strongLocal = tonumber(stats.strongLocal) or 0,
        meanAffinity = stats.affinityTotal / count,
        meanConfidence = stats.confidenceTotal / count,
        meanAdjustment = stats.adjustmentTotal / count,
        minimumAdjustment = tonumber(stats.minimumAdjustment) or 0,
        maximumAdjustment = tonumber(stats.maximumAdjustment) or 0,
    }
end
