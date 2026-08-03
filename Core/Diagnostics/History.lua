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
                if report.approximateBytes <= D.MAX_REPORT_BYTES then
                    valid[#valid + 1] = report
                    totalBytes = totalBytes + report.approximateBytes
                    seenIDs[report.id], seenFingerprints[fingerprint] = true, true
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

function D.InitializeHistory() return PruneStore(P.EnsureStore()) end
function D.GetReports() return PruneStore(P.EnsureStore()) end
function D.GetLatestReport() return D.GetReports()[1] end
function D.GetReportByID(reportID)
    for _, report in ipairs(D.GetReports()) do if report.id == reportID then return report end end
end

function D.GetLatestEligibleCompletedReport(lineageID)
    lineageID = lineageID or CurrentLineage()
    for _, report in ipairs(D.GetReports()) do
        local completed = report.result == "COMPLETED" or report.result == "FALLBACK"
        local reportLineage = report.lineageID or (report.character and (report.character.key or (tostring(report.character.name or "") .. "-" .. tostring(report.character.realm or ""))))
        if completed and (not lineageID or reportLineage == lineageID) then return report end
    end
end

function D.BeginGenerationAttempt(action)
    local store = P.EnsureStore()
    local sequence = store.nextSequence
    store.nextSequence = sequence + 1
    local startedAt = type(time) == "function" and time() or 0
    local lineageID = CurrentLineage()
    local pending = P.latestEligiblePendingReport
    local parent = pending and pending.lineageID == lineageID and pending or D.GetLatestEligibleCompletedReport(lineageID)
    return {
        reportID = string.format("QCDBG-%d-%d", startedAt, sequence), sequence = sequence,
        startedAt = startedAt, lineageID = lineageID,
        generationToken = string.format("QCGEN-%d-%d-%s", startedAt, sequence, tostring(action or "UNKNOWN")),
        parentCompletedReportID = parent and parent.id or nil,
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
    report.approximateBytes = ApproximateBytes(report)
    if report.approximateBytes > D.MAX_REPORT_BYTES then
        report.warnings = report.warnings or {}
        report.warnings[#report.warnings + 1] = { key = "REPORT_TRIMMED", severity = "WARNING", text = "Diagnostic details exceeded the persistence limit and were compacted." }
        report.performance = report.performance or {}
        report.performance.phaseStats = report.performance.phaseStats or {}
        report.cache = report.cache or {}
        report.approximateBytes = ApproximateBytes(report)
    end
    table.insert(store.reports, 1, report)
    store.counters.reportsRecorded = store.counters.reportsRecorded + 1
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
