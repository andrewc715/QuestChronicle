local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

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
                if total > D.MAX_REPORT_BYTES * 2 then break end
            end
            seen[value] = nil
        end
    end
    Count(report, 10, {})
    return total
end


local function AddTrimWarning(report, originalBytes)
    report.warnings = type(report.warnings) == "table" and report.warnings or {}
    for _, warning in ipairs(report.warnings) do
        if warning.key == "REPORT_TRIMMED" then return end
    end
    report.warnings[#report.warnings + 1] = {
        key = "REPORT_TRIMMED", severity = "WARNING",
        text = string.format(
            "Diagnostic details exceeded the %d-byte persistence limit and duplicate raw fields were compacted (originally about %d bytes).",
            tonumber(D.MAX_REPORT_BYTES) or 0, tonumber(originalBytes) or 0
        ),
    }
end

local function RemoveZeroEntries(values)
    if type(values) ~= "table" then return end
    for key, value in pairs(values) do
        if tonumber(value) == 0 then values[key] = nil end
    end
end

local function CompactReportToLimit(report)
    local originalBytes = ApproximateBytes(report)
    if originalBytes <= D.MAX_REPORT_BYTES then return originalBytes, false end

    AddTrimWarning(report, originalBytes)

    -- The outfit slot list duplicates the anchor components and contextual-support
    -- decisions that power formatting, comparisons, and reroll ancestry.
    if type(report.outfit) == "table" then report.outfit.slots = nil end

    local support = type(report.support) == "table" and report.support or nil
    local profile = support and type(support.profile) == "table" and support.profile or nil
    if profile then
        -- `entries` is the canonical reusable anchor profile. `activeAnchors` is a
        -- display-only duplicate and can be reconstructed by the formatter.
        profile.activeAnchors = nil
        profile.strongestRelationship = nil
        if type(profile.descriptor) == "table" then
            -- Set identifiers are not used to restore or score the aggregate profile.
            profile.descriptor.setIDs = nil
        end
    end

    if support then
        for _, decision in ipairs(support.decisions or {}) do
            -- Item IDs are optional raw-detail metadata; source and visual IDs remain.
            decision.itemID = nil
        end
    end

    if type(report.cache) == "table" then RemoveZeroEntries(report.cache.invalidationReasons) end

    local bytes = ApproximateBytes(report)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true end

    -- Preserve the user-facing score ledger and Phase D result before trimming
    -- lower-value duplicated/raw diagnostic payloads.
    if type(report.skeleton) == "table" then
        for _, component in ipairs(report.skeleton.components or {}) do
            component.scoreReasons = nil
            if type(component.anchorPolicy) == "table" then
                component.anchorPolicy.reasons = nil
                component.anchorPolicy.rawAdjustment = nil
                component.anchorPolicy.boundedAdjustment = nil
                component.anchorPolicy.confidenceFactor = nil
            end
        end
    end
    bytes = ApproximateBytes(report)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true end

    -- Last-resort compaction keeps the complete report summary, selected sources,
    -- Phase D validation, warnings, and headline performance instead of silently
    -- deleting the report from Debug History.
    if type(report.performance) == "table" then report.performance.phaseStats = nil end
    bytes = ApproximateBytes(report)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true end

    if type(report.cache) == "table" then
        report.cache.invalidationReasons = nil
    end
    bytes = ApproximateBytes(report)
    return bytes, true
end

local function IsValidReport(report)
    return type(report) == "table"
        and tonumber(report.formatVersion) == D.FORMAT_VERSION
        and type(report.id) == "string"
        and type(report.timestamp) == "number"
        and type(report.action) == "string"
        and type(report.result) == "string"
end

local function SkeletonIdentity(report)
    local values = {}
    for _, component in ipairs(report and report.skeleton and report.skeleton.components or {}) do
        values[#values + 1] = table.concat({
            tostring(component.slotKey or ""), tostring(component.visualID or component.sourceID or ""),
            component.hidden and "H" or "", component.locked and "L" or "",
        }, ":")
    end
    table.sort(values)
    return table.concat(values, "|")
end

function P.ReportFingerprint(report)
    local generationToken = report and report.generationToken
    if generationToken == nil or generationToken == "" then return "LEGACY#" .. tostring(report and report.id or report) end
    local character = report and report.character or {}
    return table.concat({
        tostring(report and report.lineageID or character.key or (tostring(character.name or "") .. "-" .. tostring(character.realm or ""))),
        tostring(report and report.action or ""), tostring(generationToken),
        tostring(report and report.timestamp or ""), SkeletonIdentity(report),
    }, "#")
end

local function PruneStore(store)
    local valid, totalBytes, seenIDs, seenFingerprints = {}, 0, {}, {}
    for _, report in ipairs(store.reports or {}) do
        if IsValidReport(report) then
            local fingerprint = P.ReportFingerprint(report)
            if not seenIDs[report.id] and not seenFingerprints[fingerprint] then
                report.approximateBytes = math.floor(tonumber(report.approximateBytes) or ApproximateBytes(report))
                if report.approximateBytes > D.MAX_REPORT_BYTES then
                    report.approximateBytes = CompactReportToLimit(report)
                end
                if report.approximateBytes <= D.MAX_REPORT_BYTES then
                    valid[#valid + 1] = report
                    totalBytes = totalBytes + report.approximateBytes
                    seenIDs[report.id], seenFingerprints[fingerprint] = true, true
                else
                    store.counters.malformedReportsDiscarded = store.counters.malformedReportsDiscarded + 1
                end
            else
                store.counters.duplicateInsertionsIgnored = store.counters.duplicateInsertionsIgnored + 1
            end
        else
            store.counters.malformedReportsDiscarded = store.counters.malformedReportsDiscarded + 1
        end
    end
    table.sort(valid, function(left, right)
        if (left.sequence or 0) == (right.sequence or 0) then return (left.timestamp or 0) > (right.timestamp or 0) end
        return (left.sequence or 0) > (right.sequence or 0)
    end)
    while #valid > D.MAX_REPORTS or totalBytes > D.MAX_HISTORY_BYTES do
        local removed = table.remove(valid)
        totalBytes = totalBytes - (removed and removed.approximateBytes or 0)
    end
    store.reports = valid
    return valid
end

local function CurrentLineage()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    return character.key or (tostring(character.name or "Unknown") .. "-" .. tostring(character.realm or "Unknown"))
end

P.reportPins = P.reportPins or {}

function D.PinReport(reportID)
    if not reportID then return nil end
    local pinned = P.reportPins[reportID]
    if pinned then pinned.count = pinned.count + 1 return pinned.report end
    local report
    for _, candidate in ipairs(P.EnsureStore().reports) do if candidate.id == reportID then report = candidate break end end
    if report then P.reportPins[reportID] = { report = report, count = 1 } end
    return report
end

function D.ReleaseReport(reportID)
    local pinned = reportID and P.reportPins[reportID]
    if not pinned then return false end
    pinned.count = pinned.count - 1
    if pinned.count <= 0 then P.reportPins[reportID] = nil end
    return true
end

function D.InitializeHistory() return PruneStore(P.EnsureStore()) end
function D.GetReports() return PruneStore(P.EnsureStore()) end
function D.PeekReports() return P.EnsureStore().reports end
function D.GetLatestReport() return D.GetReports()[1] end
function D.PeekLatestReport() return D.PeekReports()[1] end
function D.PeekReportByID(reportID)
    local pinned = reportID and P.reportPins[reportID]
    if pinned then return pinned.report end
    for _, report in ipairs(D.PeekReports()) do if report.id == reportID then return report end end
end

function D.GetReportByID(reportID)
    return D.PeekReportByID(reportID)
end

function D.GetLatestEligibleCompletedReport(lineageID)
    lineageID = lineageID or CurrentLineage()
    for _, report in ipairs(D.PeekReports()) do
        local completed = report.result == "COMPLETED" or report.result == "FALLBACK"
        local reportLineage = report.lineageID or (report.character and (report.character.key or (tostring(report.character.name or "") .. "-" .. tostring(report.character.realm or ""))))
        if completed and (not lineageID or reportLineage == lineageID) then return report end
    end
end

function D.BeginGenerationAttempt(action, actionSlotKey)
    local store = P.EnsureStore()
    local sequence = store.nextSequence
    store.nextSequence = sequence + 1
    local startedAt = type(time) == "function" and time() or 0
    local lineageID = CurrentLineage()
    local pending = P.latestEligiblePendingReport
    local parent = pending and pending.lineageID == lineageID and pending or D.GetLatestEligibleCompletedReport(lineageID)
    local anchorSource
    if pending and pending.lineageID == lineageID then
        if P.ReportPerformsAnchorSelection and P.ReportPerformsAnchorSelection(pending) then anchorSource = pending
        elseif pending.anchorSourceReportID and D.GetReportByID then anchorSource = D.GetReportByID(pending.anchorSourceReportID) end
    end
    if not anchorSource then anchorSource = D.GetLatestAnchorSourceReport and D.GetLatestAnchorSourceReport(lineageID) or nil end
    local performsAnchor = P.ActionPerformsAnchorSelection and P.ActionPerformsAnchorSelection(action, actionSlotKey) or action ~= "REROLL_SLOT"
    return {
        reportID = string.format("QCDBG-%d-%d", startedAt, sequence), sequence = sequence,
        startedAt = startedAt, lineageID = lineageID,
        generationToken = string.format("QCGEN-%d-%d-%s", startedAt, sequence, tostring(action or "UNKNOWN")),
        parentCompletedReportID = parent and parent.id or nil,
        anchorSourceReportID = anchorSource and anchorSource.id or nil,
        performedAnchorSelection = performsAnchor,
    }
end

function D.GetHistoryCounters()
    local counters = P.EnsureStore().counters
    return { reportsRecorded = counters.reportsRecorded, duplicateInsertionsIgnored = counters.duplicateInsertionsIgnored, malformedReportsDiscarded = counters.malformedReportsDiscarded }
end

function D.AddReport(report)
    local store = P.EnsureStore()
    if type(report) ~= "table" then
        store.counters.malformedReportsDiscarded = store.counters.malformedReportsDiscarded + 1
        return nil, "Diagnostic report was empty."
    end
    report.formatVersion = D.FORMAT_VERSION
    if not report.sequence then
        report.sequence = store.nextSequence
        store.nextSequence = store.nextSequence + 1
    else
        store.nextSequence = math.max(store.nextSequence, report.sequence + 1)
    end
    report.id = report.id or string.format("QCDBG-%d-%d", tonumber(report.timestamp) or 0, report.sequence)
    local fingerprint = P.ReportFingerprint(report)
    for _, existing in ipairs(store.reports) do
        if existing.id == report.id or P.ReportFingerprint(existing) == fingerprint then
            store.counters.duplicateInsertionsIgnored = store.counters.duplicateInsertionsIgnored + 1
            return existing, "Duplicate diagnostic report ignored."
        end
    end
    report.approximateBytes = CompactReportToLimit(report)
    if report.approximateBytes > D.MAX_REPORT_BYTES then
        store.counters.malformedReportsDiscarded = store.counters.malformedReportsDiscarded + 1
        return nil, "Diagnostic report remained above the persistence limit after compaction."
    end
    table.insert(store.reports, 1, report)
    store.counters.reportsRecorded = store.counters.reportsRecorded + 1
    local traveler = QC.ZoneStyle and QC.ZoneStyle.Traveler
    if traveler and traveler.ObserveTuningReport then
        local ok, errorMessage = pcall(traveler.ObserveTuningReport, report)
        if not ok then
            local audit = QuestChronicleDB and QuestChronicleDB.travelerTuningAudit
            if type(audit) == "table" then
                audit.collectionErrors = (tonumber(audit.collectionErrors) or 0) + 1
                audit.lastError = tostring(errorMessage or "unknown tuning-audit error"):sub(1, 160)
            end
        end
    end
    PruneStore(store)
    local uiState = P.GetUIState()
    uiState.debugSelectedReportID = report.id
    P.Notify("DIAGNOSTIC_REPORT_ADDED", report)
    return report
end

function D.ClearReports()
    local store = P.EnsureStore()
    store.reports = {}
    P.GetUIState().debugSelectedReportID = nil
    P.Notify("DIAGNOSTIC_REPORTS_CLEARED")
    return true
end
