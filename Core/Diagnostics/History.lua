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

local function PruneStore(store)
    local valid = {}
    local totalBytes = 0
    for _, report in ipairs(store.reports or {}) do
        if IsValidReport(report) then
            report.approximateBytes = math.floor(tonumber(report.approximateBytes) or ApproximateBytes(report))
            if report.approximateBytes <= D.MAX_REPORT_BYTES then
                valid[#valid + 1] = report
                totalBytes = totalBytes + report.approximateBytes
            end
        end
    end
    table.sort(valid, function(left, right)
        if (left.timestamp or 0) == (right.timestamp or 0) then
            return (left.sequence or 0) > (right.sequence or 0)
        end
        return (left.timestamp or 0) > (right.timestamp or 0)
    end)
    while #valid > D.MAX_REPORTS or totalBytes > D.MAX_HISTORY_BYTES do
        local removed = table.remove(valid)
        totalBytes = totalBytes - (removed and removed.approximateBytes or 0)
    end
    store.reports = valid
    return valid
end

function D.InitializeHistory()
    local store = P.EnsureStore()
    return PruneStore(store)
end

function D.GetReports()
    return PruneStore(P.EnsureStore())
end

function D.GetLatestReport()
    return D.GetReports()[1]
end

function D.GetReportByID(reportID)
    for _, report in ipairs(D.GetReports()) do
        if report.id == reportID then return report end
    end
    return nil
end

function D.AddReport(report)
    if type(report) ~= "table" then return nil, "Diagnostic report was empty." end
    local store = P.EnsureStore()
    report.formatVersion = D.FORMAT_VERSION
    report.sequence = store.nextSequence
    store.nextSequence = store.nextSequence + 1
    report.id = report.id or string.format("QCDBG-%d-%d", tonumber(report.timestamp) or 0, report.sequence)
    report.approximateBytes = ApproximateBytes(report)
    if report.approximateBytes > D.MAX_REPORT_BYTES then
        report.warnings = report.warnings or {}
        report.warnings[#report.warnings + 1] = {
            key = "REPORT_TRIMMED",
            severity = "WARNING",
            text = "Diagnostic details exceeded the persistence limit and were compacted.",
        }
        report.performance = report.performance or {}
        report.performance.phaseStats = report.performance.phaseStats or {}
        report.cache = report.cache or {}
        report.approximateBytes = ApproximateBytes(report)
    end
    table.insert(store.reports, 1, report)
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
