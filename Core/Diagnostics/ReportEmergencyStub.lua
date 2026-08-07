local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local function Truncate(value, limit)
    local text = value == nil and nil or tostring(value)
    if not text or #text <= limit then return text end
    return text:sub(1, math.max(0, limit - 3)) .. "..."
end

local function PrimitiveMap(source, keys)
    local result = {}
    for _, key in ipairs(keys or {}) do
        local value = type(source) == "table" and source[key] or nil
        local valueType = type(value)
        if valueType == "string" then
            result[key] = Truncate(value, 192)
        elseif valueType == "number" or valueType == "boolean" then
            result[key] = value
        end
    end
    return result
end

local function CompactWarnings(report, limit)
    local result = {}
    for _, warning in ipairs(type(report.warnings) == "table" and report.warnings or {}) do
        if warning.key ~= "REPORT_TRIMMED" and warning.key ~= "REPORT_EMERGENCY_STUB" then
            result[#result + 1] = {
                key = Truncate(warning.key, 64),
                severity = Truncate(warning.severity, 16),
                text = Truncate(warning.text, 320),
            }
            if #result >= limit then break end
        end
    end
    return result
end

local function CompactComponents(components)
    local result = {}
    for _, component in ipairs(type(components) == "table" and components or {}) do
        result[#result + 1] = PrimitiveMap(component, {
            "slotKey", "slotLabel", "name", "sourceID", "visualID", "locked", "hidden",
            "baseScore", "curatedFields", "curatedTuningVersion",
        })
    end
    return result
end

local function CompactSkeleton(skeleton)
    if type(skeleton) ~= "table" then return nil end
    local result = PrimitiveMap(skeleton, {
        "fallbackReason", "chosenRank", "shortlistSize", "score", "baseSkeletonScore",
        "repeatPenalty", "adjustedSelectionScore", "noveltyClass", "exactRepeatAccepted",
        "exactRepeatReason", "meanPairCohesion", "hardClashes", "signature", "reusedFromParent",
    })
    result.components = CompactComponents(skeleton.components)
    result.excludedComponents = {}
    for index, value in ipairs(type(skeleton.excludedComponents) == "table" and skeleton.excludedComponents or {}) do
        if index > 20 then break end
        result.excludedComponents[index] = Truncate(value, 96)
    end
    if type(skeleton.scoreBreakdown) == "table" then
        result.scoreBreakdown = PrimitiveMap(skeleton.scoreBreakdown, {
            "armorRelevance", "weaponRelevance", "armorCohesion", "weaponCohesion",
            "hardClashPenalty", "total",
        })
    end
    return result
end

local function CompactPolicySelected(selected)
    local result = {}
    for _, entry in ipairs(type(selected) == "table" and selected or {}) do
        result[#result + 1] = PrimitiveMap(entry, {
            "slotKey", "name", "sourceID", "visualID", "legacyRelevance", "affinity",
            "confidence", "classification", "adjustment", "zoneAdjustment", "finalRelevance",
            "flags",
        })
    end
    return result
end

local function CompactPolicyPools(pools)
    local result = {}
    local function AddPool(pool, slotKey)
        local entry = PrimitiveMap(pool, {
            "slotKey", "prepared", "eligible", "retained", "unknown", "meanAffinity",
            "meanConfidence", "meanAdjustment", "minimumAdjustment", "maximumAdjustment",
        })
        entry.slotKey = entry.slotKey or slotKey
        result[#result + 1] = entry
    end
    if type(pools) ~= "table" then return result end
    if #pools > 0 then
        for _, pool in ipairs(pools) do AddPool(pool) end
    else
        local keys = {}
        for key in pairs(pools) do keys[#keys + 1] = tostring(key) end
        table.sort(keys)
        for _, key in ipairs(keys) do AddPool(pools[key], key) end
    end
    return result
end

local function CompactPolicy(policy)
    if type(policy) ~= "table" then return nil end
    local result = PrimitiveMap(policy, {
        "policyID", "policyFormat", "authority", "supportPolicy", "snapshotFingerprint",
        "fallback", "fallbackReason", "contextStaleAtCommit", "armorPairSupport",
        "weaponPairSupport", "visualArmorRelationshipBonus", "visualWeaponRelationshipBonus",
        "linkedVisualDeduplicated", "routeFamily", "logicalWeaponCount",
    })
    result.selected = CompactPolicySelected(policy.selected)
    result.pools = CompactPolicyPools(policy.pools)
    return result
end

local function CompactFoundation(foundation)
    if type(foundation) ~= "table" then return nil end
    local result = PrimitiveMap(foundation, {
        "foundation", "contextFormat", "profileRegistryVersion", "provenanceRegistryVersion",
        "affinityFormat", "fingerprint", "evidenceCount", "compatibility",
    })
    result.identity = PrimitiveMap(foundation.identity, {
        "profileKey", "profileLabel", "label", "resolution", "resolutionLevel", "confidence", "description",
    })
    result.era = PrimitiveMap(foundation.era, {
        "eraMax", "maxExpansionID", "eraLabel", "label", "eraShortLabel", "shortLabel",
        "resolution", "resolutionLevel", "confidence",
    })
    result.provenance = PrimitiveMap(foundation.provenance, {
        "key", "label", "resolution", "resolutionLevel", "confidence", "restriction",
    })
    result.fallback = PrimitiveMap(foundation.fallback, { "used", "reason" })
    if type(foundation.affinity) == "table" then
        result.affinity = {
            selected = foundation.affinity.selected,
            score = foundation.affinity.score,
            confidence = foundation.affinity.confidence,
            classifications = foundation.affinity.classifications,
        }
    end
    result.anchorPolicy = CompactPolicy(foundation.anchorPolicy)
    return result
end

local function CompactProfile(profile)
    if type(profile) ~= "table" then return nil end
    local result = PrimitiveMap(profile, {
        "profileID", "profileSourceReportID", "version", "activeAnchorCount",
        "activeAnchorMaskSignature", "meanAnchorCohesion", "weakestRelationship",
    })
    result.centers = PrimitiveMap(profile.centers, {
        "palette", "material", "finish", "motif", "visualWeight", "weight",
    })
    result.tolerance = PrimitiveMap(profile.tolerance, {
        "palette", "material", "finish", "motif", "visualWeight", "weight", "provenance",
    })
    result.confidence = PrimitiveMap(profile.confidence, {
        "palette", "material", "finish", "motif", "visualWeight", "weight", "provenance",
    })
    return result
end

local function CompactPhaseD(phase)
    if type(phase) ~= "table" then return nil end
    return PrimitiveMap(phase, {
        "status", "mismatchBudget", "mismatchUsed", "mismatchOverflow", "severityThreshold",
        "maximumSeverity", "paletteLimit", "paletteFamilies", "paletteOverflow",
        "repairableOutliers", "protectedOutliers", "repairableZeroEcho", "protectedZeroEcho",
        "repairableSevere", "protectedSevere", "protectedLockedViolations", "weightedSeverity",
        "wholeOutfitCohesion",
    })
end

local function CompactRepairs(repairs)
    local result = {}
    for _, repair in ipairs(type(repairs) == "table" and repairs or {}) do
        result[#result + 1] = PrimitiveMap(repair, {
            "pass", "slotKey", "slotLabel", "fromName", "toName", "fromVisualID", "toVisualID",
            "reason", "mismatchBefore", "mismatchAfter", "severityBefore", "severityAfter",
        })
        if #result >= 12 then break end
    end
    return result
end

local function CompactDecisions(decisions)
    local result = {}
    for _, decision in ipairs(type(decisions) == "table" and decisions or {}) do
        result[#result + 1] = PrimitiveMap(decision, {
            "slotKey", "slotLabel", "name", "sourceID", "visualID", "role", "profileFit",
            "neighborCohesion", "bridgeBonus", "mismatchSpent", "budgetState", "outlierState",
            "repeatPenalty", "locked", "fixed", "contextFixed", "targetRerolled", "noAlternative",
            "fallback", "finalMismatchClass", "echoSupport", "outlierSeverity", "repairPass",
            "repaired", "protectedByLock",
        })
    end
    return result
end

local function CompactSupport(support)
    if type(support) ~= "table" then return nil end
    local result = PrimitiveMap(support, {
        "version", "startingBudget", "lockedCommitment", "generatedSpend", "borrowed", "overrun",
        "remainingBudget", "configurationScore", "wholeOutfitCohesion", "controlledAccents",
        "outliers", "fallbackSlots", "chosenRank", "shortlistSize", "emptySlots", "targetSlotKey",
        "previousTargetName", "previousTargetSourceID", "previousTargetVisualID", "previousTargetCost",
        "replacementCost", "budgetBefore", "budgetAfter", "fixedContextCount", "noAlternative",
        "profileID", "profileSourceReportID", "profileReused", "profileRepaired", "profileMigrated",
        "profileRepairReason", "profileBasisConsistent", "fixedContextCost", "profileAdjustment",
        "expectedBudgetAfter", "budgetReconciled", "finalValidationStatus", "repairPasses",
        "alternateSkeleton",
    })
    result.profile = CompactProfile(support.profile)
    result.phaseDInitial = CompactPhaseD(support.phaseDInitial)
    result.phaseDFinal = CompactPhaseD(support.phaseDFinal)
    result.repairs = CompactRepairs(support.repairs)
    result.decisions = CompactDecisions(support.decisions)
    result.excluded = {}
    for index, value in ipairs(type(support.excluded) == "table" and support.excluded or {}) do
        if index > 20 then break end
        result.excluded[index] = Truncate(value, 96)
    end
    return result
end

local function CompactScheduler(scheduler)
    if type(scheduler) ~= "table" then return nil end
    return PrimitiveMap(scheduler, {
        "expensiveCallYields", "phaseTransitionYields", "preventedTransitions",
        "postExpensiveCallContinuations", "maximumSliceDebtMs", "preferredBudgetMs", "softBudgetMs",
        "expensiveCallForceYieldMs",
    })
end

local function CompactEraScheduling(scheduling)
    if type(scheduling) ~= "table" then return nil end
    return PrimitiveMap(scheduling, {
        "operations", "siblingCompletions", "freshSliceDeferrals", "fragmentCacheHits",
        "fragmentCacheBuilds", "pendingCandidateCompletions", "aggregateFinalizations",
        "largestSubphase", "largestSubphaseMs",
    })
end

local function CompactSupportScheduling(scheduling)
    if type(scheduling) ~= "table" then return nil end
    return PrimitiveMap(scheduling, {
        "eligibilitySteps", "eligibilityYields", "eligibilityCacheCompletions",
        "eligibilityComputedCompletions", "eligibilityMarkerBatch", "beamCandidateSteps",
        "beamFallbackSteps", "beamFallbackYields", "beamStageFinalizations",
        "beamFreshSliceDeferrals", "beamStageFinalizeMaxMs", "largestSubphase", "largestSubphaseMs",
    })
end

local function CompactCapabilities(capabilities)
    if type(capabilities) ~= "table" then return nil end
    return PrimitiveMap(capabilities, {
        "status", "generation", "buildsThisAction", "reusesThisAction", "staleAtCommit",
        "currentGeneration", "invalidationReason", "eligibilitySteps", "eligibilityYields",
        "coherenceCalls", "scoringCalls", "routeFamily", "routeCount",
    })
end

local function CompactPerformance(performance)
    if type(performance) ~= "table" then return nil end
    local result = PrimitiveMap(performance, {
        "elapsedMs", "steps", "maxStepMs", "longestWorkerSliceMs", "candidates", "eraCandidates",
        "eraCacheHits", "eligibilityCacheHits", "weaponYields", "weaponSlowYieldPhase",
        "weaponSlowYieldMs", "selectedArmor", "anchorFallbackReason", "supportFallbackReason",
        "slowestPhase", "slowestPhaseMs", "largestInstrumentedCallPhase",
        "largestInstrumentedCallMs", "synchronousLaunchPreparationMs", "preWorkerPreparationMs",
    })
    result.schedulerDiagnostics = CompactScheduler(performance.schedulerDiagnostics)
    result.eraScheduling = CompactEraScheduling(performance.eraScheduling)
    result.supportScheduling = CompactSupportScheduling(performance.supportScheduling)
    result.weaponCapabilities = CompactCapabilities(performance.weaponCapabilities)
    return result
end

function P.BuildAdaptiveEmergencyStub(report, originalBytes)
    local stub = {
        formatVersion = report.formatVersion,
        id = report.id,
        sequence = report.sequence,
        startedAt = report.startedAt,
        lineageID = report.lineageID,
        generationToken = report.generationToken,
        parentCompletedReportID = report.parentCompletedReportID,
        anchorSourceReportID = report.anchorSourceReportID,
        performedAnchorSelection = report.performedAnchorSelection,
        timestamp = report.timestamp,
        timestampText = report.timestampText,
        version = report.version,
        action = report.action,
        actionSlotKey = report.actionSlotKey,
        mode = report.mode,
        generationImplementation = report.generationImplementation,
        result = report.result,
        success = report.success,
        message = Truncate(report.message, 640),
        character = PrimitiveMap(report.character, {
            "key", "name", "realm", "className", "classID", "raceName", "level",
        }),
        context = PrimitiveMap(report.context, {
            "mode", "profileKey", "profileLabel", "provenanceLabel", "zone", "subZone", "mapID",
            "eraMax", "eraLabel", "eraShortLabel",
        }),
        outfit = type(report.outfit) == "table" and {
            generatedName = Truncate(report.outfit.generatedName, 160),
        } or nil,
        skeleton = CompactSkeleton(report.skeleton),
        support = CompactSupport(report.support),
        zoneFoundation = CompactFoundation(report.zoneFoundation),
        performance = CompactPerformance(report.performance),
        warnings = CompactWarnings(report, 6),
    }
    stub.warnings[#stub.warnings + 1] = {
        key = "REPORT_EMERGENCY_STUB",
        severity = "SEVERE",
        text = string.format(
            "Diagnostic detail required the emergency persistence stub; mandatory action, Zone policy, support outcome, and performance summaries were retained (originally about %d bytes).",
            tonumber(originalBytes) or 0
        ),
    }
    return stub
end
