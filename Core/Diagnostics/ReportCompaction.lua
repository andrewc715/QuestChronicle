local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private
local COMPACTION_FORMAT = 1
local TIER_LABELS = {
    [0] = "NONE",
    [1] = "DUPLICATE_FIELDS",
    [2] = "RECONSTRUCTIBLE_DETAIL",
    [3] = "SUMMARY_TABLES",
    [4] = "MANDATORY_CORE",
    [5] = "EMERGENCY_STUB",
    [6] = "MINIMAL_STUB",
}
local function ApproximateBytes(report)
    if type(report) ~= "table" then return 0 end
    if QC._Core and QC._Core.JsonEncode then
        local ok, encoded = pcall(QC._Core.JsonEncode, report)
        if ok and type(encoded) == "string" then return #encoded end
    end
    local total = 0
    local function Count(value, depth, seen)
        if depth <= 0 then return end
        local valueType = type(value)
        if valueType == "string" then total = total + #value + 4
        elseif valueType == "number" or valueType == "boolean" then total = total + 16
        elseif valueType == "table" then
            if seen[value] then return end
            seen[value] = true
            for key, child in pairs(value) do
                total = total + #tostring(key) + 4
                Count(child, depth - 1, seen)
            end
            seen[value] = nil
        end
    end
    Count(report, 12, {})
    return total
end
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
        if valueType == "string" or valueType == "number" or valueType == "boolean" then result[key] = value end
    end
    return result
end
local function ClearAndCopy(target, source)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(source or {}) do target[key] = value end
end
local function FindWarning(report, key)
    for _, warning in ipairs(type(report.warnings) == "table" and report.warnings or {}) do
        if warning.key == key then return warning end
    end
end
local function EnsureTrimWarning(report, originalBytes, finalBytes, tier)
    report.warnings = type(report.warnings) == "table" and report.warnings or {}
    local warning = FindWarning(report, "REPORT_TRIMMED")
    if not warning then
        warning = { key = "REPORT_TRIMMED", severity = "WARNING" }
        report.warnings[#report.warnings + 1] = warning
    end
    warning.text = string.format(
        "Diagnostic details exceeded the %d-byte persistence limit and were compacted at tier %s (%d → %d bytes).",
        tonumber(D.MAX_REPORT_BYTES) or 0, tostring(TIER_LABELS[tier] or tier),
        tonumber(originalBytes) or 0, tonumber(finalBytes) or 0
    )
end
local function EnsureEmergencyWarning(report, originalBytes)
    report.warnings = type(report.warnings) == "table" and report.warnings or {}
    report.warnings[#report.warnings + 1] = {
        key = "REPORT_EMERGENCY_STUB", severity = "SEVERE",
        text = string.format(
            "Diagnostic detail required the emergency persistence stub; mandatory action, Zone policy, support outcome, and performance summaries were retained (originally about %d bytes).",
            tonumber(originalBytes) or 0
        ),
    }
end
local function RemoveZeroEntries(values)
    if type(values) ~= "table" then return end
    for key, value in pairs(values) do if tonumber(value) == 0 then values[key] = nil end end
end
local function CompactComponent(component)
    if type(component) ~= "table" then return end
    component.itemID = nil
    component.categoryID = nil
    component.quality = nil
    component.itemSubtype = nil
    component.weaponFamily = nil
    component.scoreReasons = nil
    if type(component.anchorPolicy) == "table" then
        component.anchorPolicy.reasons = nil
        component.anchorPolicy.rawAdjustment = nil
        component.anchorPolicy.boundedAdjustment = nil
        component.anchorPolicy.confidenceFactor = nil
    end
end
local function CompactPolicySelected(selected)
    for _, entry in ipairs(type(selected) == "table" and selected or {}) do
        if type(entry) == "table" then
            entry.reasons = nil
            entry.rawAdjustment = nil
            entry.boundedAdjustment = nil
            entry.confidenceFactor = nil
            entry.descriptor = nil
        end
    end
end
local function CompactZoneDuplicates(report)
    local foundation = type(report.zoneFoundation) == "table" and report.zoneFoundation or nil
    if not foundation then return end
    if type(foundation.affinity) == "table" then foundation.affinity.pieces = nil end
    if type(foundation.compatibilityDifferences) == "table" and #foundation.compatibilityDifferences == 0 then
        foundation.compatibilityDifferences = nil
    end
    if type(foundation.anchorPolicy) == "table" and type(report.skeleton) == "table" then
        for _, component in ipairs(report.skeleton.components or {}) do component.anchorPolicy = nil end
    end
end
local function ApplyTier1(report)
    if type(report.outfit) == "table" then report.outfit.slots = nil end
    local support = type(report.support) == "table" and report.support or nil
    local profile = support and type(support.profile) == "table" and support.profile or nil
    if profile then
        profile.activeAnchors = nil
        profile.strongestRelationship = nil
        if type(profile.descriptor) == "table" then profile.descriptor.setIDs = nil end
    end
    if support then
        for _, decision in ipairs(support.decisions or {}) do decision.itemID = nil end
    end
    if type(report.cache) == "table" then RemoveZeroEntries(report.cache.invalidationReasons) end
    CompactZoneDuplicates(report)
end
local function ApplyTier2(report)
    if type(report.skeleton) == "table" then
        report.skeleton.cohesionComponents = nil
        report.skeleton.strongestBridge = nil
        report.skeleton.weakestRelationship = nil
        for _, component in ipairs(report.skeleton.components or {}) do CompactComponent(component) end
    end
    local support = type(report.support) == "table" and report.support or nil
    if support then
        for _, decision in ipairs(support.decisions or {}) do
            decision.curatedTuningVersion = nil
            decision.curatedKeyType = nil
            decision.curatedKey = nil
            decision.replacedVisualID = nil
        end
        if type(support.profile) == "table" then
            support.profile.cohesionComponents = nil
            support.profile.strongestRelationship = nil
        end
    end
    local policy = report.zoneFoundation and report.zoneFoundation.anchorPolicy
    if type(policy) == "table" then
        CompactPolicySelected(policy.selected)
        for _, weapon in ipairs(policy.logicalWeapons or {}) do CompactComponent(weapon) end
    end
end
local function CompactWeaponIndex(index)
    if type(index) ~= "table" then return nil end
    return PrimitiveMap(index, {
        "state", "use", "stateBefore", "stateAfter", "invalidationReason",
        "bucketsReused", "bucketsBuilt", "bucketsRepaired", "examinedThisAction", "yieldsThisAction",
        "lifetimeBuckets", "lifetimeExamined", "lifetimeYields",
    })
end
local function ApplyTier3(report)
    if type(report.performance) == "table" then
        report.performance.phaseStats = nil
        report.performance.weaponIndex = CompactWeaponIndex(report.performance.weaponIndex)
        report.performance.cacheDiagnostics = nil
        report.performance.anchorStats = nil
        report.performance.supportStats = nil
    end
    report.beam = nil
    local support = type(report.support) == "table" and report.support or nil
    if support then
        support.poolSizes = nil
        support.expansions = nil
        support.retained = nil
    end
    if type(report.cache) == "table" then
        report.cache.invalidationReasons = nil
        report.cache = PrimitiveMap(report.cache, {
            "persistentEvidence", "persistentPrechecks", "persistentEligibility",
            "loadedEvidence", "loadedPrechecks", "loadedEligibility", "migratedEvidence",
            "retainedEvidenceAfterScan", "addedDuringGeneration", "invalidatedDuringGeneration",
            "itemCallbacksReceivedDuringGeneration", "itemEventsCoalescedDuringGeneration",
            "dependencyRecordsExaminedDuringGeneration", "dependenciesStillPendingDuringGeneration",
            "dependenciesSatisfiedDuringGeneration", "evidenceOutcomesUnchangedDuringGeneration",
            "evidenceOutcomesChangedDuringGeneration", "pendingRecordsCreatedDuringGeneration",
            "downstreamRecordsInvalidatedDuringGeneration", "metadataIdentityChangesDuringGeneration",
        })
    end
end
local function CompactSkeletonCore(skeleton)
    if type(skeleton) ~= "table" then return nil end
    local core = PrimitiveMap(skeleton, {
        "fallbackReason", "chosenRank", "shortlistSize", "score", "baseSkeletonScore", "repeatPenalty",
        "adjustedSelectionScore", "noveltyClass", "exactRepeatAccepted", "exactRepeatReason",
        "meanPairCohesion", "hardClashes", "signature", "reusedFromParent",
    })
    core.components = {}
    for _, component in ipairs(skeleton.components or {}) do
        core.components[#core.components + 1] = PrimitiveMap(component, {
            "slotKey", "slotLabel", "name", "sourceID", "visualID", "locked", "hidden", "baseScore",
            "curatedFields", "curatedTuningVersion",
        })
    end
    core.excludedComponents = skeleton.excludedComponents
    core.scoreBreakdown = type(skeleton.scoreBreakdown) == "table" and PrimitiveMap(skeleton.scoreBreakdown, {
        "armorRelevance", "weaponRelevance", "armorCohesion", "weaponCohesion", "hardClashPenalty", "total",
    }) or nil
    return core
end
local function CompactSupportCore(support)
    if type(support) ~= "table" then return nil end
    local core = PrimitiveMap(support, {
        "version", "startingBudget", "lockedCommitment", "generatedSpend", "borrowed", "overrun",
        "remainingBudget", "configurationScore", "wholeOutfitCohesion", "controlledAccents", "outliers",
        "fallbackSlots", "chosenRank", "shortlistSize", "deduplicated", "budgetRejections", "emptySlots",
        "targetSlotKey", "previousTargetName", "previousTargetSourceID", "previousTargetVisualID",
        "previousTargetCost", "replacementCost", "budgetBefore", "budgetAfter", "fixedContextCount",
        "noAlternative", "profileID", "profileSourceReportID", "profileReused", "profileRepaired",
        "profileMigrated", "profileRepairReason", "profileBasisConsistent", "fixedContextCost",
        "profileAdjustment", "expectedBudgetAfter", "budgetReconciled", "finalValidationStatus",
        "repairPasses", "alternateSkeleton",
    })
    core.profile = support.profile
    core.phaseDInitial = support.phaseDInitial
    core.phaseDFinal = support.phaseDFinal
    core.repairs = support.repairs
    core.excluded = support.excluded
    core.decisions = {}
    for _, decision in ipairs(support.decisions or {}) do
        core.decisions[#core.decisions + 1] = PrimitiveMap(decision, {
            "slotKey", "slotLabel", "name", "sourceID", "visualID", "role", "profileFit",
            "neighborCohesion", "bridgeBonus", "bridgeTarget", "bridgeBefore", "bridgeAfter",
            "mismatchSpent", "budgetState", "outlierState", "repeatPenalty", "locked", "fixed",
            "contextFixed", "targetRerolled", "noAlternative", "bridgeImprovement", "fallback", "score",
            "finalMismatchClass", "echoSupport", "outlierSeverity", "repairPass", "repaired",
            "protectedByLock", "curatedFields",
        })
    end
    return core
end
local function CompactPolicyCore(policy)
    if type(policy) ~= "table" then return nil end
    local core = PrimitiveMap(policy, {
        "policyID", "policyFormat", "authority", "supportPolicy", "snapshotFingerprint", "fallback",
        "fallbackReason", "contextStaleAtCommit", "armorPairSupport", "weaponPairSupport",
        "visualArmorRelationshipBonus", "visualWeaponRelationshipBonus", "linkedVisualDeduplicated",
        "routeFamily", "logicalWeaponCount",
    })
    core.selected = {}
    for _, entry in ipairs(policy.selected or {}) do
        core.selected[#core.selected + 1] = PrimitiveMap(entry, {
            "slotKey", "name", "sourceID", "visualID", "legacyRelevance", "affinity", "confidence",
            "classification", "adjustment", "zoneAdjustment", "finalRelevance", "flags",
        })
    end
    core.pools = policy.pools
    core.logicalWeapons = policy.logicalWeapons
    return core
end
local function CompactZoneCore(foundation)
    if type(foundation) ~= "table" then return nil end
    local core = PrimitiveMap(foundation, {
        "foundation", "contextFormat", "profileRegistryVersion", "provenanceRegistryVersion",
        "affinityFormat", "fingerprint", "evidenceCount", "compatibility",
    })
    core.identity = foundation.identity
    core.era = foundation.era
    core.provenance = foundation.provenance
    core.fallback = foundation.fallback
    core.affinity = type(foundation.affinity) == "table" and {
        selected = foundation.affinity.selected,
        score = foundation.affinity.score,
        confidence = foundation.affinity.confidence,
        classifications = foundation.affinity.classifications,
    } or nil
    core.anchorPolicy = CompactPolicyCore(foundation.anchorPolicy)
    return core
end
local function CompactPerformanceCore(performance)
    if type(performance) ~= "table" then return nil end
    local core = PrimitiveMap(performance, {
        "elapsedMs", "steps", "maxStepMs", "longestWorkerSliceMs", "candidates", "eraCandidates",
        "eraCacheHits", "eligibilityCacheHits", "weaponYields", "weaponSlowYieldPhase", "weaponSlowYieldMs",
        "selectedArmor", "anchorFallbackReason", "supportFallbackReason", "slowestPhase", "slowestPhaseMs",
        "largestInstrumentedCallPhase", "largestInstrumentedCallMs", "supportRerollTiming",
        "synchronousLaunchPreparationMs", "preWorkerPreparationMs",
    })
    core.schedulerDiagnostics = performance.schedulerDiagnostics
    core.eraScheduling = performance.eraScheduling
    core.supportScheduling = performance.supportScheduling
    core.scoringPotholes = performance.scoringPotholes
    core.weaponCapabilities = performance.weaponCapabilities
    core.weaponIndex = CompactWeaponIndex(performance.weaponIndex)
    return core
end
local function ApplyTier4(report)
    if type(report.outfit) == "table" then report.outfit = { generatedName = report.outfit.generatedName } end
    report.skeleton = CompactSkeletonCore(report.skeleton)
    report.support = CompactSupportCore(report.support)
    report.zoneFoundation = CompactZoneCore(report.zoneFoundation)
    report.performance = CompactPerformanceCore(report.performance)
    report.cache = nil
    report.beam = nil
    report.comparison = nil
end
local function ExistingWarnings(report, limit)
    local result = {}
    for _, warning in ipairs(type(report.warnings) == "table" and report.warnings or {}) do
        if warning.key ~= "REPORT_TRIMMED" and warning.key ~= "REPORT_EMERGENCY_STUB" then
            result[#result + 1] = {
                key = Truncate(warning.key, 64), severity = Truncate(warning.severity, 16),
                text = Truncate(warning.text, 320),
            }
            if #result >= limit then break end
        end
    end
    return result
end
local function BuildEmergencyStub(report, originalBytes)
    local stub
    if P.BuildAdaptiveEmergencyStub then
        stub = P.BuildAdaptiveEmergencyStub(report, originalBytes)
    else
        stub = {
            formatVersion = report.formatVersion, id = report.id, sequence = report.sequence,
            timestamp = report.timestamp, timestampText = report.timestampText, version = report.version,
            lineageID = report.lineageID, generationToken = report.generationToken,
            action = report.action, actionSlotKey = report.actionSlotKey, mode = report.mode,
            generationImplementation = report.generationImplementation, result = report.result,
            success = report.success, message = Truncate(report.message, 640),
            character = PrimitiveMap(report.character, { "key", "name", "realm" }),
            warnings = ExistingWarnings(report, 6),
        }
        EnsureEmergencyWarning(stub, originalBytes)
    end
    ClearAndCopy(report, stub)
end
local function BuildMinimalStub(report, originalBytes)
    local stub = {
        formatVersion = report.formatVersion,
        id = report.id, sequence = report.sequence, timestamp = report.timestamp,
        timestampText = Truncate(report.timestampText, 32), version = report.version,
        lineageID = Truncate(report.lineageID, 96), generationToken = Truncate(report.generationToken, 128),
        action = Truncate(report.action, 48), actionSlotKey = Truncate(report.actionSlotKey, 32),
        mode = Truncate(report.mode, 48), generationImplementation = Truncate(report.generationImplementation, 48),
        result = Truncate(report.result, 32), success = report.success == true,
        message = Truncate(report.message, 256),
        character = PrimitiveMap(report.character, { "key", "name", "realm" }),
        warnings = {
            {
                key = "REPORT_MINIMAL_STUB", severity = "SEVERE",
                text = string.format("Diagnostic report required the minimal persistence stub after exceeding the %d-byte limit (originally about %d bytes).", tonumber(D.MAX_REPORT_BYTES) or 0, tonumber(originalBytes) or 0),
            },
        },
    }
    ClearAndCopy(report, stub)
end
local function StabilizeMeasuredBytes(report, includeCompaction)
    local bytes = tonumber(report.approximateBytes) or 0
    for _ = 1, 8 do
        report.approximateBytes = bytes
        if includeCompaction and type(report.compaction) == "table" then
            report.compaction.finalBytes = bytes
        end
        local measured = ApproximateBytes(report)
        if measured == bytes then return bytes end
        bytes = measured
    end
    report.approximateBytes = bytes
    if includeCompaction and type(report.compaction) == "table" then
        report.compaction.finalBytes = bytes
    end
    return ApproximateBytes(report)
end
local function StableBytes(report, originalBytes, tier, emergency)
    report.compaction = {
        format = COMPACTION_FORMAT, tier = tier, tierLabel = TIER_LABELS[tier],
        originalBytes = originalBytes, finalBytes = 0, emergencyStub = emergency == true,
    }
    report.approximateBytes = 0
    local bytes = StabilizeMeasuredBytes(report, true)
    if tier > 0 then
        EnsureTrimWarning(report, originalBytes, bytes, tier)
        bytes = StabilizeMeasuredBytes(report, true)
        EnsureTrimWarning(report, originalBytes, bytes, tier)
        bytes = StabilizeMeasuredBytes(report, true)
    end
    report.approximateBytes = bytes
    report.compaction.finalBytes = bytes
    return bytes
end
local function StableUncompactedBytes(report)
    report.compaction = nil
    report.approximateBytes = 0
    return StabilizeMeasuredBytes(report, false)
end
function P.ApproximateReportBytes(report)
    return ApproximateBytes(report)
end
function P.BuildEmergencyReportStub(report, originalBytes)
    originalBytes = tonumber(originalBytes) or ApproximateBytes(report)
    BuildEmergencyStub(report, originalBytes)
    local bytes = StableBytes(report, originalBytes, 5, true)
    if bytes <= D.MAX_REPORT_BYTES then return bytes end
    BuildMinimalStub(report, originalBytes)
    return StableBytes(report, originalBytes, 6, true)
end
function P.CompactReportToLimit(report)
    local measuredBytes = ApproximateBytes(report)
    if measuredBytes <= D.MAX_REPORT_BYTES then
        local existing = type(report.compaction) == "table" and report.compaction or nil
        local existingTier = existing and (tonumber(existing.tier) or 0) or 0
        if existingTier > 0 then
            local originalBytes = tonumber(existing.originalBytes) or measuredBytes
            local bytes = StableBytes(report, originalBytes, existingTier, existing.emergencyStub == true)
            return bytes, true, existingTier
        end
        local bytes = StableUncompactedBytes(report)
        return bytes, false, 0
    end
    local originalBytes = type(report.compaction) == "table" and tonumber(report.compaction.originalBytes) or nil
    originalBytes = originalBytes or measuredBytes
    ApplyTier1(report)
    local bytes = StableBytes(report, originalBytes, 1, false)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true, 1 end
    ApplyTier2(report)
    bytes = StableBytes(report, originalBytes, 2, false)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true, 2 end
    ApplyTier3(report)
    bytes = StableBytes(report, originalBytes, 3, false)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true, 3 end
    ApplyTier4(report)
    bytes = StableBytes(report, originalBytes, 4, false)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true, 4 end
    bytes = P.BuildEmergencyReportStub(report, originalBytes)
    return bytes, true, report.compaction and report.compaction.tier or 6
end
