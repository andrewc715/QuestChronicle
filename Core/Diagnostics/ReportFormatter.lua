local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local ACTION_LABELS = {
    GENERATE_OUTFIT = "Generate Outfit",
    REROLL_UNLOCKED = "Reroll Unlocked",
    REROLL_SLOT = "Reroll Slot",
}
local RESULT_LABELS = {
    COMPLETED = "Completed",
    FALLBACK = "Fallback",
    CANCELLED = "Cancelled",
    FAILED = "Failed",
    NO_ALTERNATIVE = "No Alternative",
}
local PHASE_ORDER = {
    "generationActionIdentity", "generationStateSnapshot", "generationModeContext", "generationContextSeed",
    "generationEligibilityContext", "generationNoveltyReference", "generationCacheScalarSnapshot",
    "generationWeaponIndexSnapshot", "setup", "validation", "eraEvidence", "eligibility", "coherence", "scoring",
    "anchorCandidateScoring", "anchorBeamSearch", "anchorWeaponExpansion", "anchorSelection",
    "supportProfile", "supportLockedCommitments", "supportValidation", "supportEraEvidence", "supportEligibility",
    "supportCandidateScoring", "supportBeamExpansion", "supportSelection", "slotSetup", "slotFinalization", "progressUpdate", "weaponRouting", "stateCommit",
    "previewApply", "uiRefresh", "completionNotify", "rerollLaunchManifest", "rerollStateCapture",
    "rerollAnchorSnapshotReuse", "rerollStateMaterialization", "rerollDiagnosticIdentity", "rerollAnchorSummary",
    "rerollStyleContextInit", "rerollStyleContextSeed", "rerollEligibilityContext",
    "rerollSupportSummaryFoundation", "rerollCacheScalarSnapshot", "rerollCacheSummaryFoundation", "rerollProfileReuse",
    "rerollFixedContextCommitments", "rerollLedgerReconstruction", "rerollCandidatePreparation",
    "rerollSourceValidation", "rerollEraEvidence", "rerollEligibility", "rerollCandidateScoring",
    "rerollNeighborScoring", "rerollBridgeScoring", "rerollBudgetEvaluation", "rerollShortlistSelection",
    "rerollStateCommit", "rerollSlot",
}
local PHASE_LABELS = {
    setup = "Setup (legacy)",
    generationActionIdentity = "Generation action identity", generationStateSnapshot = "Generation state snapshot",
    generationModeContext = "Generation mode context", generationContextSeed = "Generation context seed",
    generationEligibilityContext = "Generation eligibility context", generationNoveltyReference = "Generation novelty reference",
    generationCacheScalarSnapshot = "Generation cache scalar snapshot", generationWeaponIndexSnapshot = "Generation weapon-index snapshot",
    validation = "Source validation", eraEvidence = "Era evidence",
    eligibility = "Eligibility", coherence = "Outfit coherence", scoring = "Candidate scoring",
    anchorCandidateScoring = "Anchor candidate scoring", anchorBeamSearch = "Anchor beam search",
    anchorWeaponExpansion = "Anchor weapon expansion", anchorSelection = "Anchor selection",
    supportProfile = "Support profile", supportLockedCommitments = "Locked support commitments",
    supportValidation = "Support validation", supportEraEvidence = "Support era evidence",
    supportEligibility = "Support eligibility", supportCandidateScoring = "Support candidate scoring",
    supportBeamExpansion = "Support beam expansion", supportSelection = "Support selection",
    slotSetup = "Slot setup", slotFinalization = "Slot finalization", progressUpdate = "Progress update",
    weaponRouting = "Weapon routing", stateCommit = "State commit", previewApply = "Preview application",
    uiRefresh = "UI refresh", completionNotify = "Completion callback", rerollSlot = "Reroll slot",
    rerollLaunchManifest = "Reroll launch manifest", rerollStateCapture = "Reroll state capture (legacy)",
    rerollAnchorSnapshotReuse = "Reroll anchor snapshot reuse", rerollStateMaterialization = "Reroll state materialization",
    rerollDiagnosticIdentity = "Reroll diagnostic identity", rerollAnchorSummary = "Reroll anchor summary",
    rerollStyleContextInit = "Reroll style-context initialization", rerollStyleContextSeed = "Reroll style-context seed",
    rerollEligibilityContext = "Reroll eligibility context",
    rerollSupportSummaryFoundation = "Reroll support summary foundation",
    rerollCacheScalarSnapshot = "Reroll cache scalar snapshot", rerollCacheSummaryFoundation = "Reroll cache summary foundation (legacy)",
    rerollProfileReuse = "Reroll profile reuse",
    rerollFixedContextCommitments = "Reroll fixed-context commitments", rerollLedgerReconstruction = "Reroll ledger reconstruction",
    rerollCandidatePreparation = "Reroll candidate preparation", rerollSourceValidation = "Reroll source validation",
    rerollEraEvidence = "Reroll era evidence", rerollEligibility = "Reroll eligibility",
    rerollCandidateScoring = "Reroll candidate scoring", rerollNeighborScoring = "Reroll neighbor scoring",
    rerollBridgeScoring = "Reroll bridge scoring", rerollBudgetEvaluation = "Reroll budget evaluation",
    rerollShortlistSelection = "Reroll shortlist selection", rerollStateCommit = "Reroll state commit",
    weaponContext = "Weapon context", weaponCapabilities = "Weapon capabilities", weaponRoute = "Weapon route",
    weaponCandidateBuild = "Weapon candidate build", weaponCandidateValidate = "Weapon candidate validation",
    weaponValidation = "Weapon source validation", weaponPermission = "Weapon permission",
    weaponAppearance = "Weapon appearance lookup", weaponSourceInfo = "Weapon source metadata",
    weaponIndexBuild = "Weapon index build", weaponIndexRepair = "Weapon index repair", weaponIndexLookup = "Weapon index lookup",
    weaponLinkedValidate = "Linked-weapon validation", weaponRouteFilter = "Weapon route filtering",
    weaponCompanionRoute = "Weapon companion route", weaponBundleCohesion = "Weapon bundle cohesion",
}
local MODE_LABELS = {
    ZONE_NATIVE = "Zone Native", TRAVELER = "Traveler",
    CLASS_FANTASY = "Class Fantasy", CHRONICLE_ECHO = "Chronicle Echo",
}

local function F(value, decimals)
    value = tonumber(value) or 0
    return string.format("%." .. tostring(decimals or 1) .. "f", value)
end

local function N(value)
    local number = math.floor(tonumber(value) or 0)
    local text = tostring(number)
    local sign, digits = text:match("^([%-]?)(%d+)$")
    if not digits then return text end
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (sign or "") .. formatted
end

local function YesNo(value)
    return value and "Yes" or "No"
end

local function Add(lines, text)
    lines[#lines + 1] = text or ""
end

local function AddHeading(lines, title, rich)
    if #lines > 0 then Add(lines, "") end
    Add(lines, rich and ("|cffd9b36c" .. title .. "|r") or ("== " .. title .. " =="))
end

local function FindComponent(report, slotKey)
    for _, component in ipairs(report and report.skeleton and report.skeleton.components or {}) do
        if component.slotKey == slotKey then return component end
    end
    return nil
end

local function FormatSource(component, rawIDs)
    if not component then return "None" end
    local markers = {}
    if component.locked then markers[#markers + 1] = "Locked" end
    if component.hidden then markers[#markers + 1] = "Hidden" end
    local text = component.hidden and "Hidden" or tostring(component.name or "None")
    if not component.hidden and (component.slotKey == "ONE_HAND" or component.slotKey == "TWO_HAND" or component.slotKey == "RANGED" or component.slotKey == "OFF_HAND") and component.itemSubtype then
        text = text .. " • " .. tostring(component.itemSubtype)
    end
    if #markers > 0 and not component.hidden then text = text .. " [" .. table.concat(markers, ", ") .. "]" end
    if rawIDs then
        local ids = {}
        if component.visualID then ids[#ids + 1] = "visual " .. tostring(component.visualID) end
        if component.sourceID then ids[#ids + 1] = "source " .. tostring(component.sourceID) end
        if component.itemID then ids[#ids + 1] = "item " .. tostring(component.itemID) end
        if component.categoryID then ids[#ids + 1] = "category " .. tostring(component.categoryID) end
        if #ids > 0 then text = text .. " {" .. table.concat(ids, ", ") .. "}" end
    end
    return text
end

local function PhaseRows(report)
    local stats = report and report.performance and report.performance.phaseStats or {}
    local rows, seen = {}, {}
    for _, key in ipairs(PHASE_ORDER) do
        local phase = stats[key]
        if phase then
            rows[#rows + 1] = { key = key, phase = phase }
            seen[key] = true
        end
    end
    local extras = {}
    for key, phase in pairs(stats) do
        if not seen[key] then extras[#extras + 1] = { key = key, phase = phase } end
    end
    table.sort(extras, function(left, right) return tostring(left.key) < tostring(right.key) end)
    for _, entry in ipairs(extras) do rows[#rows + 1] = entry end
    return rows
end

local function AddOverview(lines, report, rich)
    AddHeading(lines, "Overview", rich)
    Add(lines, "Version: " .. tostring(report.version or "Unknown"))
    Add(lines, "Time: " .. tostring(report.timestampText or report.timestamp or "Unknown"))
    local character = report.character or {}
    Add(lines, string.format("Character: %s - %s%s", tostring(character.name or "Unknown"), tostring(character.realm or "Unknown"), character.className and (" • " .. tostring(character.className)) or ""))
    local action = ACTION_LABELS[report.action] or tostring(report.action or "Unknown")
    if report.actionSlotKey then action = action .. " • " .. tostring(report.actionSlotKey) end
    Add(lines, "Action: " .. action)
    Add(lines, "Mode: " .. tostring(MODE_LABELS[report.mode] or report.mode or "Unknown"))
    Add(lines, "Result: " .. tostring(RESULT_LABELS[report.result] or report.result or "Unknown"))
    if report.anchorPhase == "REUSED" then
        Add(lines, "Anchor phase: Reused from parent report")
        Add(lines, "Anchor source report: " .. tostring(report.anchorSourceReportID or "Unknown"))
    end
    if report.support and report.support.targetSlotKey then
        Add(lines, "Profile phase: " .. (report.support.profileRepaired and "Repaired" or (report.support.profileReused and "Reused" or "Derived")))
        Add(lines, "Profile ID: " .. tostring(report.support.profileID or (report.support.profile and report.support.profile.profileID) or "Unknown"))
    end
    if report.outfit and report.outfit.generatedName then Add(lines, "Outfit: " .. tostring(report.outfit.generatedName)) end
    local context = report.context or {}
    local location = context.profileLabel or context.provenanceLabel or context.zone
    if location then Add(lines, "Context: " .. tostring(location) .. (context.eraLabel and (" • through " .. tostring(context.eraLabel)) or "")) end
    local performance = report.performance or {}
    Add(lines, string.format("Prepared: %s frames • %.1f sec", N(performance.steps), (tonumber(performance.elapsedMs) or 0) / 1000))
    if performance.supportRerollTiming then
        Add(lines, string.format("Synchronous launch preparation: %.1f ms", tonumber(performance.synchronousLaunchPreparationMs or performance.preWorkerPreparationMs) or 0))
        Add(lines, string.format("Longest cooperative worker slice: %.1f ms", tonumber(performance.longestWorkerSliceMs) or tonumber(performance.maxStepMs) or 0))
        Add(lines, string.format("Largest cooperative call: %s %.1f ms", PHASE_LABELS[performance.largestCooperativeCallPhase] or tostring(performance.largestCooperativeCallPhase or "Unknown"), tonumber(performance.largestCooperativeCallMs) or 0))
    else
        Add(lines, string.format("Longest worker slice: %.1f ms", tonumber(performance.longestWorkerSliceMs) or tonumber(performance.maxStepMs) or 0))
        Add(lines, string.format("Largest instrumented call: %s %.1f ms", PHASE_LABELS[performance.largestInstrumentedCallPhase or performance.slowestPhase] or tostring(performance.largestInstrumentedCallPhase or performance.slowestPhase or "Unknown"), tonumber(performance.largestInstrumentedCallMs) or tonumber(performance.slowestPhaseMs) or 0))
    end
    Add(lines, "Fallback: " .. tostring((report.skeleton and report.skeleton.fallbackReason) or report.supportFallbackReason or "None"))
end

local function AddSkeleton(lines, report, rawIDs, rich)
    AddHeading(lines, "Anchor Skeleton", rich)
    local skeleton = report.skeleton or {}
    Add(lines, string.format("Chosen: rank %d/%d • score %.1f • cohesion %.3f • hard clashes %d", tonumber(skeleton.chosenRank) or 0, tonumber(skeleton.shortlistSize) or 0, tonumber(skeleton.baseSkeletonScore or skeleton.score) or 0, tonumber(skeleton.meanPairCohesion) or 0, tonumber(skeleton.hardClashes) or 0))
    if report.anchorPhase == "REUSED" then
        Add(lines, "Anchor phase: Reused from parent report")
        Add(lines, "Anchor selection changed: No")
        Add(lines, "Novelty data: Not applicable to a support-only reroll")
    elseif skeleton.noveltyClass then
        local noveltyLabel = ({ INITIAL = "Initial Generation", MEANINGFULLY_NEW = "Meaningfully New", PARTIAL_CHANGE = "Partial Change", EXACT_REPEAT = "Exact Repeat" })[skeleton.noveltyClass] or tostring(skeleton.noveltyClass)
        Add(lines, "Novelty: " .. noveltyLabel)
        Add(lines, "Compared: " .. (#(skeleton.comparedComponents or {}) > 0 and table.concat(skeleton.comparedComponents, ", ") or "Not applicable"))
        Add(lines, "Changed: " .. (#(skeleton.changedComponents or {}) > 0 and table.concat(skeleton.changedComponents, ", ") or "None"))
        Add(lines, "Repeated: " .. (#(skeleton.repeatedComponents or {}) > 0 and table.concat(skeleton.repeatedComponents, ", ") or "None"))
        Add(lines, "Excluded: " .. (#(skeleton.excludedComponents or {}) > 0 and table.concat(skeleton.excludedComponents, ", ") or "None"))
        Add(lines, string.format("Selection score: %.2f base %+0.2f repeat penalty = %.2f adjusted", tonumber(skeleton.baseSkeletonScore or skeleton.score) or 0, tonumber(skeleton.repeatPenalty) or 0, tonumber(skeleton.adjustedSelectionScore or skeleton.score) or 0))
        if skeleton.exactRepeatAccepted then Add(lines, "Exact repeat accepted: " .. tostring(skeleton.exactRepeatReason or "No suitable alternative remained.")) end
    elseif report.version == "1.9.0.3" then
        Add(lines, "Novelty data: Not recorded by this version")
    elseif not skeleton.fallbackReason then
        Add(lines, "Novelty data: Not applicable")
    end
    for _, slotKey in ipairs({ "CHEST", "LEGS", "SHOULDER", "ONE_HAND", "TWO_HAND", "RANGED", "OFF_HAND" }) do
        local component = FindComponent(report, slotKey)
        if component and (component.sourceID or component.visualID or component.locked or component.hidden) then
            Add(lines, string.format("%-11s %s", tostring(component.slotLabel or slotKey) .. ":", FormatSource(component, rawIDs)))
        end
    end
    if skeleton.strongestBridge and skeleton.strongestBridge.label then
        Add(lines, "Strongest bridge: " .. tostring(skeleton.strongestBridge.label) .. string.format(" (%.3f)", tonumber(skeleton.strongestBridge.score) or 0))
    end
    if skeleton.weakestRelationship and skeleton.weakestRelationship.label then
        Add(lines, "Weakest relationship: " .. tostring(skeleton.weakestRelationship.label) .. string.format(" (%.3f)", tonumber(skeleton.weakestRelationship.score) or 0))
    end
end

local function AddBeam(lines, report, verbose, rich)
    AddHeading(lines, "Beam Search", rich)
    local beam = report.beam or {}
    local pools, expansions, retained = beam.poolSizes or {}, beam.expansions or {}, beam.retained or {}
    Add(lines, "Stage         Prepared   Expanded   Retained")
    for _, entry in ipairs({ { "CHEST", "Chest" }, { "LEGS", "Legs" }, { "SHOULDER", "Shoulders" } }) do
        Add(lines, string.format("%-13s %8s   %8s   %8s", entry[2], N(pools[entry[1]]), N(expansions[entry[1]]), N(retained[entry[1]])))
    end
    Add(lines, string.format("Weapons: %s legal bundles • %s complete skeletons", N(beam.weaponBundles), N(beam.completeSkeletons)))
    Add(lines, string.format("Pair cache: %s hits • %s misses", N(beam.pairCacheHits), N(beam.pairCacheMisses)))
    Add(lines, string.format("Final shortlist: %s • chosen rank %s • score window %.1f", N(beam.finalShortlist), N(beam.chosenRank), tonumber(beam.weightedWindow) or 0))
    if beam.fallbackReason then Add(lines, "Fallback reason: " .. tostring(beam.fallbackReason)) end
    if verbose then
        Add(lines, string.format("Deduplicated: %s • hard-constraint rejects: %s • hard-clash rejects: %s", N(beam.deduplicated), N(beam.hardConstraintRejections), N(beam.hardClashRejections)))
    end
end

local function AddScore(lines, report, rich)
    AddHeading(lines, "Score Breakdown", rich)
    local skeleton = report.skeleton or {}
    local breakdown = skeleton.scoreBreakdown or {}
    local any = false
    for _, entry in ipairs({
        { "armorBase", "Armor relevance" }, { "weaponBase", "Weapon relevance" },
        { "armorRelationships", "Armor cohesion bonus" }, { "weaponRelationships", "Weapon/body cohesion bonus" },
        { "hardClashPenalty", "Hard-clash penalty" },
    }) do
        local value = breakdown[entry[1]]
        if value ~= nil then Add(lines, string.format("%-36s %+8.2f", entry[2], tonumber(value) or 0)) any = true end
    end
    if any then
        Add(lines, string.format("%-36s %8.2f", "Base skeleton total", tonumber(skeleton.baseSkeletonScore or skeleton.score) or 0))
        Add(lines, string.format("%-36s %+8.2f", "Current-skeleton repeat penalty", tonumber(skeleton.repeatPenalty or breakdown.repeatPenalty) or 0))
        Add(lines, string.format("%-36s %8.2f", "Adjusted selection score", tonumber(skeleton.adjustedSelectionScore or skeleton.score) or 0))
    end
    local components = skeleton.cohesionComponents or {}
    if next(components) then
        Add(lines, "")
        Add(lines, "Mean pair cohesion dimensions:")
        for _, entry in ipairs({ { "palette", "Palette" }, { "material", "Material" }, { "finish", "Finish" }, { "visualWeight", "Visual weight" }, { "motif", "Motif" }, { "provenance", "Provenance" } }) do
            if components[entry[1]] ~= nil then Add(lines, string.format("  %-15s %.3f", entry[2], tonumber(components[entry[1]]) or 0)) end
        end
    end
    if not any and not next(components) then Add(lines, "No anchor score ledger was recorded for this attempt.") end
end

local function AddPerformance(lines, report, rich)
    AddHeading(lines, "Performance", rich)
    Add(lines, "Phase                              Max       Total      Calls")
    for _, entry in ipairs(PhaseRows(report)) do
        local phase = entry.phase or {}
        local severity = (tonumber(phase.maxMs) or 0) > 16 and " !!" or ((tonumber(phase.maxMs) or 0) > 8 and " !" or "")
        Add(lines, string.format("%-31s %7.1f ms %8.1f ms %7s%s", PHASE_LABELS[entry.key] or tostring(entry.key), tonumber(phase.maxMs) or 0, tonumber(phase.totalMs) or 0, N(phase.calls), severity))
    end
    local scheduler = report.performance and report.performance.schedulerDiagnostics
    if scheduler then
        Add(lines, string.format("Scheduler: %s expensive-call yields • %s phase-transition yields • %s prevented transitions", N(scheduler.expensiveCallYields), N(scheduler.phaseTransitionYields), N(scheduler.preventedPhaseTransitions)))
        Add(lines, string.format("Scheduler integrity: %s post-expensive continuations • %.2f ms maximum slice debt", N(scheduler.postExpensiveCallContinuations), tonumber(scheduler.maximumSliceDebtMs) or 0))
    end
end

local function AddCache(lines, report, verbose, rich)
    AddHeading(lines, "Cache and Metadata", rich)
    local perf, cache = report.performance or {}, report.cache or {}
    Add(lines, string.format("Candidates: %s • era-source checks: %s • selected armor: %s", N(perf.candidates), N(perf.eraCandidates), N(perf.selectedArmor)))
    Add(lines, string.format("Cache hits: %s era • %s eligibility • %s weapon yields", N(perf.eraCacheHits), N(perf.eligibilityCacheHits), N(perf.weaponYields)))
    local weaponIndex = perf.weaponIndex or report.weaponIndex
    if weaponIndex then
        if weaponIndex.stateBefore or weaponIndex.stateAfter then
            Add(lines, string.format("Weapon index: %s → %s • %s", tostring(weaponIndex.stateBefore or "Unknown"), tostring(weaponIndex.stateAfter or "Unknown"), tostring(weaponIndex.use or "NONE")))
            Add(lines, string.format("Weapon index action: %s reused • %s built • %s repaired • %s examined • %s yields", N(weaponIndex.bucketsReused), N(weaponIndex.bucketsBuilt), N(weaponIndex.bucketsRepaired), N(weaponIndex.examinedThisAction), N(weaponIndex.yieldsThisAction)))
            Add(lines, string.format("Weapon index lifetime: %s buckets • %s examined • %s yields", N(weaponIndex.lifetimeBuckets), N(weaponIndex.lifetimeExamined), N(weaponIndex.lifetimeYields)))
        else
            Add(lines, string.format("Weapon index: %s • %s • %s buckets • %s examined • %s cooperative yields", tostring(weaponIndex.state or "Unknown"), tostring(weaponIndex.use or "None"), N(weaponIndex.buckets), N(weaponIndex.examined), N(weaponIndex.yields)))
        end
        if weaponIndex.invalidationReason then Add(lines, "Weapon index invalidation: " .. tostring(weaponIndex.invalidationReason)) end
    end
    local history = D.GetHistoryCounters and D.GetHistoryCounters() or nil
    if history then Add(lines, string.format("Reports: %s recorded • %s duplicates ignored • %s malformed discarded", N(history.reportsRecorded), N(history.duplicateInsertionsIgnored), N(history.malformedReportsDiscarded))) end
    if next(cache) then
        Add(lines, string.format("Persistent: %s evidence • %s prechecks • %s eligibility", N(cache.persistentEvidence), N(cache.persistentPrechecks), N(cache.persistentEligibility)))
        Add(lines, string.format("Loaded: %s evidence • %s prechecks • %s eligibility • %s migrated", N(cache.loadedEvidence), N(cache.loadedPrechecks), N(cache.loadedEligibility), N(cache.migratedEvidence)))
        Add(lines, string.format("After scan: %s retained • this generation: %s added • %s invalidated", N(cache.retainedEvidenceAfterScan), N(cache.addedDuringGeneration), N(cache.invalidatedDuringGeneration)))
        Add(lines, string.format("Item callbacks: %s received • %s coalesced • %s dependencies examined", N(cache.itemCallbacksReceivedDuringGeneration), N(cache.itemEventsCoalescedDuringGeneration), N(cache.dependencyRecordsExaminedDuringGeneration)))
        Add(lines, string.format("Dependencies: %s pending • %s satisfied • %s unchanged • %s changed", N(cache.dependenciesStillPendingDuringGeneration), N(cache.dependenciesSatisfiedDuringGeneration), N(cache.evidenceOutcomesUnchangedDuringGeneration), N(cache.evidenceOutcomesChangedDuringGeneration)))
        Add(lines, string.format("Churn: %s pending created • %s downstream invalidated • %s identity changes", N(cache.pendingRecordsCreatedDuringGeneration), N(cache.downstreamRecordsInvalidatedDuringGeneration), N(cache.metadataIdentityChangesDuringGeneration)))
        local reasons = {}
        for reason, count in pairs(cache.invalidationReasons or {}) do
            if verbose or (tonumber(count) or 0) ~= 0 then reasons[#reasons + 1] = { reason = reason, count = count } end
        end
        table.sort(reasons, function(left, right) return (tonumber(left.count) or 0) > (tonumber(right.count) or 0) end)
        for _, entry in ipairs(reasons) do Add(lines, "Invalidated " .. tostring(entry.reason) .. ": " .. N(entry.count)) end
    end
end

local function AddComparison(lines, report, rich)
    local comparison = report.comparison
    if not comparison then return end
    AddHeading(lines, "Compared with Previous Completed Run", rich)
    Add(lines, "Changed: " .. (#comparison.changed > 0 and table.concat(comparison.changed, ", ") or "None"))
    Add(lines, "Unchanged: " .. (#comparison.unchanged > 0 and table.concat(comparison.unchanged, ", ") or "None"))
    Add(lines, "Excluded: " .. (#(comparison.excluded or {}) > 0 and table.concat(comparison.excluded, ", ") or "None"))
    if comparison.previousScore ~= nil or comparison.score ~= nil then Add(lines, string.format("Base skeleton score: %.1f → %.1f", tonumber(comparison.previousScore) or 0, tonumber(comparison.score) or 0)) end
    if comparison.previousAdjustedScore ~= nil or comparison.adjustedScore ~= nil then Add(lines, string.format("Adjusted selection score: %.1f → %.1f", tonumber(comparison.previousAdjustedScore) or tonumber(comparison.previousScore) or 0, tonumber(comparison.adjustedScore) or tonumber(comparison.score) or 0)) end
    if comparison.previousCohesion ~= nil or comparison.cohesion ~= nil then Add(lines, string.format("Cohesion: %.3f → %.3f", tonumber(comparison.previousCohesion) or 0, tonumber(comparison.cohesion) or 0)) end
    if P.AddSupportComparisonLines then P.AddSupportComparisonLines(lines, comparison) end
end

local function AddWarnings(lines, report, rich)
    AddHeading(lines, "Warnings and Fallback", rich)
    if #(report.warnings or {}) == 0 then Add(lines, "None") return end
    for _, warning in ipairs(report.warnings or {}) do
        Add(lines, string.format("[%s] %s", tostring(warning.severity or "INFO"), tostring(warning.text or warning.key or "Warning")))
    end
end

local function Format(report, options)
    if not report then return "No diagnostic report is selected." end
    options = options or {}
    local lines = {}
    AddOverview(lines, report, options.rich)
    AddSkeleton(lines, report, options.rawIDs, options.rich)
    if P.AddSupportSection then P.AddSupportSection(lines, report, options.rawIDs, options.rich) end
    AddBeam(lines, report, options.verbose, options.rich)
    AddScore(lines, report, options.rich)
    AddPerformance(lines, report, options.rich)
    AddCache(lines, report, options.verbose, options.rich)
    AddComparison(lines, report, options.rich)
    AddWarnings(lines, report, options.rich)
    if not options.rich then
        Add(lines, "")
        Add(lines, "Message: " .. tostring(report.message or ""))
    end
    return table.concat(lines, "\n")
end

function D.FormatDisplayReport(report, rawIDs, verbose)
    return Format(report, { rich = true, rawIDs = rawIDs == true, verbose = verbose == true })
end

function D.FormatCopyReport(report, rawIDs, verbose)
    return Format(report, { rich = false, rawIDs = rawIDs == true, verbose = verbose == true })
end

function D.GetActionLabel(action)
    return ACTION_LABELS[action] or tostring(action or "Unknown")
end

function D.GetResultLabel(result)
    return RESULT_LABELS[result] or tostring(result or "Unknown")
end

function D.GetModeLabel(mode)
    return MODE_LABELS[mode] or tostring(mode or "Unknown")
end
