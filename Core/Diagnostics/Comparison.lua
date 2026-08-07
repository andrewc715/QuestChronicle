local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local ARMOR_KEYS = { "CHEST", "LEGS", "SHOULDER" }
local MAIN_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }

local function AddWarning(report, key, severity, text, reportIDs)
    report.warnings[#report.warnings + 1] = { key = key, severity = severity, text = text, reportIDs = reportIDs }
end

local function ComponentsBySlot(report)
    local result = {}
    for _, component in ipairs(report and report.skeleton and report.skeleton.components or {}) do result[component.slotKey] = component end
    return result
end

local function Identity(component)
    return component and tostring(component.visualID or component.sourceID or "") or ""
end

local function MainComponent(bySlot)
    for _, key in ipairs(MAIN_KEYS) do if bySlot[key] then return bySlot[key] end end
end

local function AddState(comparison, component, old)
    if not component then return end
    local label = component.slotLabel or component.slotKey
    if component.hidden then comparison.excluded[#comparison.excluded + 1] = label .. " (Hidden)" return end
    if component.locked then comparison.excluded[#comparison.excluded + 1] = label .. " (Locked)" return end
    if Identity(component) == "" then comparison.excluded[#comparison.excluded + 1] = label .. " (Unavailable)" return end
    if old and not old.hidden and Identity(old) == Identity(component) then
        comparison.unchanged[#comparison.unchanged + 1] = label
    else
        comparison.changed[#comparison.changed + 1] = label
    end
end

local function BuildComparison(report, previous)
    local comparison = {
        previousReportID = previous.id, previousTimestamp = previous.timestamp,
        changed = {}, unchanged = {}, excluded = {},
        previousScore = previous.skeleton and (previous.skeleton.baseSkeletonScore or previous.skeleton.score),
        score = report.skeleton and (report.skeleton.baseSkeletonScore or report.skeleton.score),
        previousAdjustedScore = previous.skeleton and previous.skeleton.adjustedSelectionScore,
        adjustedScore = report.skeleton and report.skeleton.adjustedSelectionScore,
        previousCohesion = previous.skeleton and previous.skeleton.meanPairCohesion,
        cohesion = report.skeleton and report.skeleton.meanPairCohesion,
    }
    local current, old = ComponentsBySlot(report), ComponentsBySlot(previous)
    for _, key in ipairs(ARMOR_KEYS) do AddState(comparison, current[key], old[key]) end
    local currentMain, oldMain = MainComponent(current), MainComponent(old)
    if currentMain then AddState(comparison, currentMain, oldMain) end
    if current.OFF_HAND then AddState(comparison, current.OFF_HAND, old.OFF_HAND) end
    return comparison
end

local function Foundation(report)
    local bySlot = ComponentsBySlot(report)
    local chest, shoulder = bySlot.CHEST, bySlot.SHOULDER
    if not chest or not shoulder or chest.hidden or shoulder.hidden or chest.locked or shoulder.locked then return nil end
    if Identity(chest) == "" or Identity(shoulder) == "" then return nil end
    local main = MainComponent(bySlot)
    local topology = tostring(main and main.slotKey or "NONE") .. ":" .. tostring(bySlot.OFF_HAND and "PAIR" or "SINGLE")
    return table.concat({ tostring(report.mode or ""), topology, Identity(chest), Identity(shoulder) }, "|")
end

local function AddFoundationWarning(report)
    if P.ReportPerformsAnchorSelection and not P.ReportPerformsAnchorSelection(report) then return end
    local signature = Foundation(report)
    if not signature then return end
    local consecutive, ids, parentID = 1, { report.id }, report.previousAnchorSourceReportID
    while parentID do
        local previous = D.GetReportByID(parentID)
        if not previous or (P.ReportPerformsAnchorSelection and not P.ReportPerformsAnchorSelection(previous)) or Foundation(previous) ~= signature then break end
        consecutive = consecutive + 1
        ids[#ids + 1] = previous.id
        parentID = previous.previousAnchorSourceReportID
    end
    if consecutive >= 3 then
        AddWarning(report, "REPEATED_FOUNDATION", "WARNING", string.format("The same unlocked Chest and Shoulders appeared in %d consecutive completed skeletons.", consecutive), ids)
    end
end

function P.AttachWarningsAndComparison(report)
    local performance = report.performance or {}
    local workerSlice = tonumber(performance.longestWorkerSliceMs) or tonumber(performance.maxStepMs) or 0
    local supportRerollTiming = performance.supportRerollTiming == true
    local callMs = supportRerollTiming and (tonumber(performance.largestCooperativeCallMs) or 0)
        or (tonumber(performance.largestInstrumentedCallMs) or tonumber(performance.slowestPhaseMs) or 0)
    local callPhase = tostring(supportRerollTiming and performance.largestCooperativeCallPhase
        or performance.largestInstrumentedCallPhase or performance.slowestPhase or "an unknown phase")
    if supportRerollTiming then
        if workerSlice > 16 then
            AddWarning(report, "SEVERE_WORKER_SLICE", "SEVERE", string.format("Quest Chronicle reached a %.1f ms cooperative worker slice; the largest cooperative call was %s at %.1f ms.", workerSlice, callPhase, callMs))
        elseif workerSlice > 8 then
            AddWarning(report, "WORKER_SLICE", "WARNING", string.format("Quest Chronicle reached a %.1f ms cooperative worker slice; the largest cooperative call was %s at %.1f ms.", workerSlice, callPhase, callMs))
        end
        if callMs > 16 then AddWarning(report, "SEVERE_INSTRUMENTED_CALL", "SEVERE", string.format("%s contained a %.1f ms cooperative call.", callPhase, callMs))
        elseif callMs > 8 then AddWarning(report, "INSTRUMENTED_CALL", "WARNING", string.format("%s contained a %.1f ms cooperative call.", callPhase, callMs)) end
    else
        if workerSlice > 16 then
            AddWarning(report, "SEVERE_WORKER_SLICE", "SEVERE", string.format("Quest Chronicle reached a %.1f ms worker slice; the largest instrumented call was %s at %.1f ms.", workerSlice, callPhase, callMs))
        elseif workerSlice > 8 then
            AddWarning(report, "WORKER_SLICE", "WARNING", string.format("Quest Chronicle reached a %.1f ms worker slice; the largest instrumented call was %s at %.1f ms.", workerSlice, callPhase, callMs))
        end
        if callMs > 16 then AddWarning(report, "SEVERE_INSTRUMENTED_CALL", "SEVERE", string.format("%s contained a %.1f ms instrumented call.", callPhase, callMs))
        elseif callMs > 8 then AddWarning(report, "INSTRUMENTED_CALL", "WARNING", string.format("%s contained a %.1f ms instrumented call.", callPhase, callMs)) end
    end
    if supportRerollTiming then
        local launch = tonumber(performance.synchronousLaunchPreparationMs or performance.preWorkerPreparationMs) or 0
        if launch > 12 then AddWarning(report, "SYNC_LAUNCH_OVERRUN", "SEVERE", string.format("Synchronous support-reroll launch preparation reached %.1f ms.", launch))
        elseif launch >= 8 then AddWarning(report, "SYNC_LAUNCH_OVERRUN", "WARNING", string.format("Synchronous support-reroll launch preparation reached %.1f ms.", launch)) end
    end
    local eraScheduling = performance.eraScheduling
    if eraScheduling and (tonumber(eraScheduling.sameSliceDeferredRetries) or 0) > 0 then
        AddWarning(report, "ERA_SAME_SLICE_DEFERRED_RETRY", "SEVERE", "Era evidence retried a deferred operation before returning to a new scheduler slice.")
    end
    if eraScheduling and (tonumber(eraScheduling.synchronousProgressGuardTrips) or 0) > 0 then
        AddWarning(report, "ERA_SYNCHRONOUS_PROGRESS_GUARD", "SEVERE", "A synchronous era-evidence drain stopped because it failed its forward-progress contract.")
    end
    local weaponIndex = performance.weaponIndex or report.weaponIndex
    if weaponIndex and weaponIndex.invalidationReason == "UNKNOWN" then
        AddWarning(report, "UNKNOWN_WEAPON_INDEX_INVALIDATION", "WARNING", "The weapon candidate index was invalidated without a recognized lifecycle reason.")
    end
    local skeleton = report.skeleton or {}
    local zoneAnchorPolicy = report.zoneFoundation and report.zoneFoundation.anchorPolicy
    if zoneAnchorPolicy and zoneAnchorPolicy.fallback then
        AddWarning(report, "ZONE_ANCHOR_POLICY_FALLBACK", "WARNING", "Zone anchor policy used the legacy relevance score: " .. tostring(zoneAnchorPolicy.fallbackReason or zoneAnchorPolicy.fallback))
    end
    if zoneAnchorPolicy and zoneAnchorPolicy.contextStaleAtCommit then
        AddWarning(report, "ZONE_CONTEXT_STALE", "WARNING", "Zone context changed before commit; the previous preview was preserved.")
    end
    if skeleton.fallbackReason then AddWarning(report, "LEGACY_FALLBACK", "WARNING", "Anchor search used the legacy generator: " .. tostring(skeleton.fallbackReason)) end
    if report.supportFallbackReason then AddWarning(report, "SUPPORT_LEGACY_FALLBACK", "WARNING", "Contextual support used the legacy selector: " .. tostring(report.supportFallbackReason)) end
    if report.action == "GENERATE_OUTFIT" and skeleton.noveltyClass == "EXACT_REPEAT" then
        AddWarning(report, "EXACT_SKELETON_REPEATED", "WARNING", "Generate Outfit accepted an exact unlocked-skeleton repeat. " .. tostring(skeleton.exactRepeatReason or "No stronger novelty candidate was available."))
    elseif report.action == "GENERATE_OUTFIT" and skeleton.noveltyClass == "PARTIAL_CHANGE" then
        AddWarning(report, "PARTIAL_CHANGE_ONLY", "INFO", "Generate Outfit found only a partial anchor change inside the quality window.")
    end
    local repeated = {}
    for _, label in ipairs(skeleton.repeatedComponents or {}) do repeated[label] = true end
    if (not P.ReportPerformsAnchorSelection or P.ReportPerformsAnchorSelection(report)) and repeated.Chest and repeated.Shoulders then
        AddWarning(report, "REPEATED_CHEST_AND_SHOULDERS", "INFO", "Unlocked Chest and Shoulders were retained after novelty scoring.")
    end

    local previous = report.parentCompletedReportID and D.GetReportByID(report.parentCompletedReportID) or nil
    if previous then
        report.comparison = BuildComparison(report, previous)
        if P.AttachSupportComparison then P.AttachSupportComparison(report, previous, report.comparison) end
    end
    local support = report.support
    if support and (tonumber(support.overrun) or 0) > 0 then AddWarning(report, "SUPPORT_BUDGET_OVERRUN", "WARNING", string.format("Contextual support exceeded its mismatch budget by %.2f points.", tonumber(support.overrun) or 0)) end
    if support and support.finalValidationStatus == "REPAIRED" then
        AddWarning(report, "SUPPORT_REPAIR_APPLIED", "INFO", string.format("Final validation repaired %d contextual support outlier%s.", tonumber(support.repairPasses) or 0, tonumber(support.repairPasses) == 1 and "" or "s"))
    elseif support and support.finalValidationStatus == "LOCKED_OVERRIDE" then
        AddWarning(report, "SUPPORT_LOCKED_OVERRIDE", "INFO", "Final validation preserved user-locked visual mismatch.")
    elseif support and support.finalValidationStatus == "ALTERNATE_SKELETON" then
        AddWarning(report, "SUPPORT_ALTERNATE_SKELETON", "INFO", "Final validation used the next valid anchor skeleton after support repair was exhausted.")
    end
    if support and (tonumber(support.outliers) or 0) > 0 then AddWarning(report, "SUPPORT_OUTLIER", "WARNING", string.format("Contextual support retained %d unresolved visual outlier%s after final validation.", support.outliers, support.outliers == 1 and "" or "s")) end
    if support and (tonumber(support.fallbackSlots) or 0) > 0 then AddWarning(report, "SUPPORT_FALLBACK", "INFO", string.format("Contextual support used %d slot-local fallback%s.", support.fallbackSlots, support.fallbackSlots == 1 and "" or "s")) end
    if support and (tonumber(support.emptySlots) or 0) > 0 then AddWarning(report, "SUPPORT_EMPTY_SLOT", "INFO", string.format("Contextual support left %d active slot%s empty because no legal appearance was available.", support.emptySlots, support.emptySlots == 1 and "" or "s")) end
    if support and support.profileRepaired then AddWarning(report, "PROFILE_REPAIRED", "INFO", "Quest Chronicle repaired an inherited contextual profile before scoring this support reroll: " .. tostring(support.profileRepairReason or "profile mismatch")) end
    if support and support.budgetReconciled == false then AddWarning(report, "BUDGET_RECONCILIATION_FAILED", "SEVERE", "The contextual mismatch ledger did not reconcile on one profile basis.") end
    AddFoundationWarning(report)
end
