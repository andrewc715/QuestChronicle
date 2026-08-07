local function JsonString(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\"):gsub('"', '\\"')
    value = value:gsub("\b", "\\b"):gsub("\f", "\\f"):gsub("\n", "\\n")
    value = value:gsub("\r", "\\r"):gsub("\t", "\\t")
    return '"' .. value .. '"'
end
local function IsArray(value)
    local count, highest = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        count = count + 1
        highest = math.max(highest, key)
    end
    return highest == count
end
local function JsonEncode(value, seen)
    local valueType = type(value)
    if value == nil then return "null" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then return tostring(value) end
    if valueType == "string" then return JsonString(value) end
    if valueType ~= "table" then return JsonString(tostring(value)) end
    seen = seen or {}
    if seen[value] then return "null" end
    seen[value] = true
    local parts = {}
    if IsArray(value) then
        for index = 1, #value do parts[index] = JsonEncode(value[index], seen) end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local child = value[key]
        if child == nil then child = value[tonumber(key)] end
        parts[#parts + 1] = JsonString(key) .. ":" .. JsonEncode(child, seen)
    end
    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

local printed, notified = {}, {}
QuestChronicle = { Diagnostics = nil, _Core = { JsonEncode = JsonEncode } }
QuestChronicleDB = { ui = {} }
QuestChronicle.Print = function(message) printed[#printed + 1] = tostring(message) end
QuestChronicle.Notify = function(eventName, ...) notified[#notified + 1] = { eventName, ... } end
QuestChronicle.GetCurrentCharacter = function()
    return { key = "Tester-Realm", name = "Tester", realm = "Realm" }
end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/ReportEmergencyStub.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")

local D = QuestChronicle.Diagnostics
local long = string.rep("adaptive-retail-payload-", 80)
local components, selected = {}, {}
for index, slotKey in ipairs({ "CHEST", "LEGS", "SHOULDER", "TWO_HAND", "OFF_HAND" }) do
    components[#components + 1] = {
        slotKey = slotKey, slotLabel = slotKey, name = "Anchor " .. slotKey,
        sourceID = 1000 + index, visualID = 2000 + index, itemID = 3000 + index,
        baseScore = 10 + index, scoreReasons = { long, long },
        anchorPolicy = { policyID = "ZONE_ANCHOR_POLICY_V1", legacyRelevance = 10 + index,
            affinity = 0.55, confidence = 0.62, adjustment = 3.2, finalRelevance = 13.2 + index,
            reasons = { long, long }, rawAdjustment = 3.2, boundedAdjustment = 3.2 },
    }
    selected[#selected + 1] = {
        slotKey = slotKey, name = "Anchor " .. slotKey, sourceID = 1000 + index,
        visualID = 2000 + index, legacyRelevance = 10 + index, affinity = 0.55,
        confidence = 0.62, classification = "SUPPORTED_LOCAL_VARIATION",
        adjustment = 3.2, finalRelevance = 13.2 + index,
    }
end
local decisions = {}
for index = 1, 10 do
    decisions[index] = {
        slotKey = "SUPPORT_" .. index, slotLabel = "Support " .. index, name = "Decision " .. index,
        sourceID = 4000 + index, visualID = 5000 + index, role = long, profileFit = 0.7,
        neighborCohesion = 0.68, bridgeBonus = 2.5, mismatchSpent = 0.1,
        finalMismatchClass = "COHESIVE", echoSupport = 1, outlierSeverity = 0.12,
        scoreReasons = { long, long, long }, curatedMetadata = { explanation = long },
    }
end
local entries = {}
for index = 1, 140 do
    entries[index] = { slotKey = "ENTRY_" .. index, visualID = 6000 + index, descriptor = long,
        palette = { steel = 1, purple = 0.8 }, evidence = { long, long } }
end
local phaseStats = {}
for index = 1, 180 do
    phaseStats["phase_" .. index] = { calls = index * 4, totalMs = index / 3, maxMs = index / 20, detail = long }
end
local affinityPieces = {}
for index = 1, 12 do
    affinityPieces[index] = { slotKey = "SLOT_" .. index, sourceID = 7000 + index,
        visualID = 8000 + index, score = 0.4, confidence = 0.5,
        classification = "WEAK_LOCAL_SIGNAL", descriptor = long,
        evidence = { long, long }, missingChannels = { "finish", "motif", "provenance" } }
end
local warnings = {}
for index = 1, 20 do warnings[index] = { key = "WARNING_" .. index, severity = "WARNING", text = long } end

local report, message = D.AddReport({
    formatVersion = D.FORMAT_VERSION, id = "QCDBG-ADAPTIVE-1", sequence = 1,
    timestamp = 1786038000, timestampText = "2026-08-06 13:20:00", version = "1.11.6",
    action = "GENERATE_OUTFIT", result = "COMPLETED", success = true,
    generationToken = "QCGEN-ADAPTIVE-1", lineageID = "Tester-Realm",
    generationImplementation = "LEGACY",
    character = { key = "Tester-Realm", name = "Tester", realm = "Realm", className = "WARRIOR" },
    context = { mode = "ZONE_NATIVE", profileKey = "outland", profileLabel = "Outland",
        provenanceLabel = "Shadowmoon Valley", zone = "Shadowmoon Valley", subZone = "Wildhammer Stronghold",
        mapID = 104, eraMax = 1, eraLabel = "Through TBC" },
    outfit = { generatedName = "Adaptive Budget Fixture", slots = components },
    skeleton = { chosenRank = 2, shortlistSize = 4, score = 125.2, baseSkeletonScore = 125.2,
        adjustedSelectionScore = 125.2, meanPairCohesion = 0.54, hardClashes = 0,
        components = components, excludedComponents = { "TABARD" },
        scoreBreakdown = { armorRelevance = 44, weaponRelevance = 12, armorCohesion = 52,
            weaponCohesion = 17, hardClashPenalty = 0, total = 125 },
        cohesionComponents = { raw = long }, strongestBridge = { detail = long }, weakestRelationship = { detail = long } },
    support = { version = 1, startingBudget = 9.25, generatedSpend = 0.8, remainingBudget = 8.45,
        configurationScore = 355, wholeOutfitCohesion = 0.69, finalValidationStatus = "CLEAN",
        profileID = "QCPROFILE-ADAPTIVE", profileSourceReportID = "QCDBG-ADAPTIVE-1",
        profile = { profileID = "QCPROFILE-ADAPTIVE", profileSourceReportID = "QCDBG-ADAPTIVE-1",
            activeAnchorCount = 4, activeAnchorMaskSignature = "CHEST|LEGS|SHOULDER|WEAPON",
            meanAnchorCohesion = 0.65, centers = { palette = "steel", material = "plate", finish = "magical" },
            tolerance = { palette = 0.3, material = 0.3 }, confidence = { palette = 0.5, material = 0.7 },
            entries = entries, activeAnchors = components, descriptor = { raw = long } },
        decisions = decisions, repairs = { { pass = 1, slotKey = "BACK", reason = long } },
        phaseDInitial = { status = "REPAIR", mismatchBudget = 2, mismatchUsed = 1.2,
            maximumSeverity = 0.8, paletteFamilies = 4, repairableOutliers = 1 },
        phaseDFinal = { status = "CLEAN", mismatchBudget = 2, mismatchUsed = 0.2,
            maximumSeverity = 0.4, paletteFamilies = 2, repairableOutliers = 0 },
        poolSizes = entries, expansions = entries, retained = entries },
    zoneFoundation = { foundation = "CONTEXT_EVIDENCE_V1", contextFormat = 1,
        profileRegistryVersion = 1, provenanceRegistryVersion = 1, affinityFormat = 2,
        fingerprint = "ZCTX-ADAPTIVE", evidenceCount = 12, compatibility = "PASS",
        identity = { label = "Outland", profileKey = "outland", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
        era = { label = "Through TBC", maxExpansionID = 1, resolutionLevel = "MAP_TRAIL", confidence = 0.8 },
        provenance = { label = "Shadowmoon Valley", key = "shadowmoon_outland", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
        affinity = { selected = 12, score = 0.33, confidence = 0.46,
            classifications = { WEAK_LOCAL_SIGNAL = 7, UNKNOWN = 2, OFF_ZONE_SIGNAL = 3 }, pieces = affinityPieces },
        anchorPolicy = { policyID = "ZONE_ANCHOR_POLICY_V1", policyFormat = 1, authority = "ACTIVE",
            supportPolicy = "LEGACY", snapshotFingerprint = "ZCTX-ADAPTIVE", contextStaleAtCommit = false,
            selected = selected, pools = {
                CHEST = { prepared = 330, eligible = 42, retained = 42, unknown = 0, meanAffinity = 0.35, meanAdjustment = 0.2 },
                LEGS = { prepared = 312, eligible = 30, retained = 30, unknown = 0, meanAffinity = 0.38, meanAdjustment = 0.65 },
                SHOULDER = { prepared = 286, eligible = 32, retained = 32, unknown = 0, meanAffinity = 0.39, meanAdjustment = 0.66 },
            }, armorPairSupport = 4, weaponPairSupport = 0, visualArmorRelationshipBonus = 48,
            visualWeaponRelationshipBonus = 16, linkedVisualDeduplicated = true,
            routeFamily = "TWO_HAND", logicalWeaponCount = 1, logicalWeapons = components },
    },
    performance = { elapsedMs = 6300, steps = 433, maxStepMs = 9.4, longestWorkerSliceMs = 9.4,
        largestInstrumentedCallPhase = "weaponStyleEligibilityStep", largestInstrumentedCallMs = 1.7,
        phaseStats = phaseStats,
        schedulerDiagnostics = { expensiveCallYields = 17, phaseTransitionYields = 184,
            preventedTransitions = 184, postExpensiveCallContinuations = 0, maximumSliceDebtMs = 0.8 },
        supportScheduling = { eligibilitySteps = 928, eligibilityYields = 140,
            eligibilityCacheCompletions = 512, eligibilityComputedCompletions = 416,
            eligibilityMarkerBatch = 4, beamCandidateSteps = 5408, beamFallbackSteps = 6,
            beamFallbackYields = 5, beamStageFinalizations = 7, beamFreshSliceDeferrals = 7,
            beamStageFinalizeMaxMs = 6.8, largestSubphase = "supportBeamStageFinalize", largestSubphaseMs = 6.8 },
        scoringPotholes = {
            anchor = { substeps = 440, completions = 32, apiOperations = 12, admissionDeferrals = 4,
                metadataAPICalls = 4, setAPICalls = 4, trackingAPICalls = 4, preparedMetadataHits = 28,
                preparedSetHits = 28, preparedTrackingHits = 28, largestSubphase = "anchorCandidateDescriptor", largestSubphaseMs = 1.7 },
            supportBridge = { targetResolutions = 900, descriptorHits = 900, descriptorFallbacks = 0, candidatePairs = 720,
                baselinePairs = 180, admissionDeferrals = 9, largestSubphase = "supportCandidateBridgePair", largestSubphaseMs = 1.5 },
        },
        weaponCapabilities = { status = "REUSED", generation = 4, buildsThisAction = 1,
            reusesThisAction = 4, staleAtCommit = false, currentGeneration = 4,
            invalidationReason = "LOGIN_SESSION_RESET", eligibilitySteps = 110,
            eligibilityYields = 27, coherenceCalls = 4, scoringCalls = 4 },
        weaponIndex = { stateBefore = "STALE", stateAfter = "PARTIAL", use = "COLD_BUILD",
            bucketsBuilt = 2, examinedThisAction = 1878, yieldsThisAction = 234 },
        cacheDiagnostics = { raw = long }, anchorStats = entries, supportStats = entries },
    cache = { persistentEvidence = 4500, persistentPrechecks = 13000, persistentEligibility = 16000,
        invalidationReasons = { PRECHECK_LRU = 3500, ELIGIBILITY_LRU = 3400 }, raw = entries },
    beam = { raw = entries }, comparison = { raw = entries }, warnings = warnings,
    message = string.rep("Generated a very large but valid Zone Native diagnostic report. ", 80),
})

assert(report, message or "adaptive report must be persisted")
assert(#D.GetReports() == 1 and D.GetReports()[1].id == "QCDBG-ADAPTIVE-1", "adaptive report missing from history")
assert(report.compaction and report.compaction.originalBytes > D.MAX_REPORT_BYTES, "fixture did not exceed the ceiling")
assert(report.compaction.finalBytes <= D.MAX_REPORT_BYTES, "adaptive compaction did not fit the report")
assert(report.approximateBytes == #JsonEncode(report), "recorded bytes must match exact serialized bytes")
assert(report.zoneFoundation and report.zoneFoundation.anchorPolicy, "Zone policy core was lost")
assert(report.zoneFoundation.anchorPolicy.policyID == "ZONE_ANCHOR_POLICY_V1", "Zone policy identity was lost")
assert(#(report.zoneFoundation.anchorPolicy.selected or {}) == 5, "selected Zone anchors were lost")
assert(report.performance and report.performance.weaponCapabilities, "weapon capability summary was lost")
assert(report.performance.weaponCapabilities.eligibilitySteps == 110, "weapon capability counters were lost")
assert(report.performance.schedulerDiagnostics.postExpensiveCallContinuations == 0, "scheduler integrity was lost")
assert(report.performance.supportScheduling and report.performance.supportScheduling.eligibilityMarkerBatch == 4, "support scheduling core was lost")
assert(report.performance.supportScheduling.largestSubphase == "supportBeamStageFinalize", "support subphase identity was lost")
assert(report.performance.scoringPotholes and report.performance.scoringPotholes.anchor.substeps == 440, "anchor pothole counters were lost")
assert(report.performance.scoringPotholes.supportBridge.descriptorFallbacks == 0, "support bridge pothole counters were lost")
assert(report.performance.scoringPotholes.supportBridge.largestSubphase == "supportCandidateBridgePair", "support bridge subphase identity was lost")
assert(report.support and report.support.finalValidationStatus == "CLEAN", "support validation outcome was lost")
assert(report.support.phaseDFinal and report.support.phaseDFinal.status == "CLEAN", "Phase D outcome was lost")
assert(#(report.skeleton and report.skeleton.components or {}) == 5, "selected skeleton was lost")
assert(#printed == 0, "valid oversized report should not print a rejection")
for _, event in ipairs(notified) do assert(event[1] ~= "DIAGNOSTIC_REPORT_REJECTED", "valid report emitted rejection event") end

local emergencySeen, trimSeen = false, false
for _, warning in ipairs(report.warnings or {}) do
    if warning.key == "REPORT_EMERGENCY_STUB" then emergencySeen = true end
    if warning.key == "REPORT_TRIMMED" then trimSeen = true end
end
assert(trimSeen, "adaptive report must record its compaction")

local pathological, pathologicalMessage = D.AddReport({
    formatVersion = D.FORMAT_VERSION, id = "QCDBG-ADAPTIVE-2", sequence = 2,
    timestamp = 1786038001, timestampText = "2026-08-06 13:20:01", version = "1.11.6",
    action = "GENERATE_OUTFIT", result = "COMPLETED", success = true,
    generationToken = "QCGEN-ADAPTIVE-2", lineageID = "Tester-Realm",
    character = { key = "Tester-Realm", name = "Tester", realm = "Realm" },
    message = string.rep("pathological diagnostic payload ", 15000),
    warnings = { { key = "PATHOLOGICAL", severity = "SEVERE", text = string.rep("warning ", 20000) } },
    zoneFoundation = { foundation = "CONTEXT_EVIDENCE_V1", fingerprint = "ZCTX-PATH",
        anchorPolicy = { policyID = "ZONE_ANCHOR_POLICY_V1", authority = "ACTIVE",
            selected = selected, pools = { huge = { detail = string.rep("pool ", 20000) } } } },
    support = { finalValidationStatus = "CLEAN", profile = { entries = entries }, decisions = decisions },
    skeleton = { components = components }, performance = { phaseStats = phaseStats,
        scoringPotholes = { anchor = { substeps = 999, largestSubphase = "anchorCandidateAffinity", largestSubphaseMs = 2.2 },
            supportBridge = { descriptorFallbacks = 1, largestSubphase = "supportCandidateBridgeDescriptor", largestSubphaseMs = 2.4 } } },
})
assert(pathological, pathologicalMessage or "pathological valid report must persist as a stub")
assert(pathological.approximateBytes <= D.MAX_REPORT_BYTES, "pathological stub exceeded the ceiling")
assert(pathological.compaction and pathological.compaction.emergencyStub == true, "pathological report did not use emergency fallback")
assert(pathological.compaction.tier == 5 or pathological.compaction.tier == 6, "unexpected emergency tier")
assert(pathological.performance and pathological.performance.scoringPotholes and pathological.performance.scoringPotholes.anchor.substeps == 999, "emergency stub lost anchor pothole diagnostics")
assert(pathological.performance.scoringPotholes.supportBridge.descriptorFallbacks == 1, "emergency stub lost support bridge diagnostics")
assert(#printed == 0, "emergency persistence should not print a rejection")
for _, event in ipairs(notified) do assert(event[1] ~= "DIAGNOSTIC_REPORT_REJECTED", "emergency stub emitted rejection event") end

print(string.format(
    "PASS v1.11.6 adaptive report budget: worst-case retained at tier %s (%d -> %d bytes); pathological tier %s retained",
    tostring(report.compaction.tierLabel), report.compaction.originalBytes, report.compaction.finalBytes,
    tostring(pathological.compaction.tierLabel)
))
