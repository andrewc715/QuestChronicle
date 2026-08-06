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

local function CompactZoneDuplicates(report)
    local foundation = type(report.zoneFoundation) == "table" and report.zoneFoundation or nil
    if not foundation then return end

    -- The Debug report formats only the aggregate selected-look affinity. The live
    -- Zone export reconstructs complete per-piece evidence independently, so the
    -- persisted piece ledger is expendable when a report crosses the size ceiling.
    if type(foundation.affinity) == "table" then foundation.affinity.pieces = nil end
    if type(foundation.compatibilityDifferences) == "table" and #foundation.compatibilityDifferences == 0 then
        foundation.compatibilityDifferences = nil
    end

    -- v1.11.3 copied the full policy calculation into every selected component and
    -- also stored one authoritative policy summary on `zoneFoundation`. Keep the
    -- summary and remove the component-level duplicate payload.
    if type(foundation.anchorPolicy) == "table" and type(report.skeleton) == "table" then
        for _, component in ipairs(report.skeleton.components or {}) do
            component.anchorPolicy = nil
        end
    end
end

function P.ApproximateReportBytes(report)
    return ApproximateBytes(report)
end

function P.CompactReportToLimit(report)
    local originalBytes = ApproximateBytes(report)
    if originalBytes <= D.MAX_REPORT_BYTES then return originalBytes, false end

    AddTrimWarning(report, originalBytes)

    -- The outfit slot list duplicates the selected skeleton and contextual-support
    -- decisions that power formatting, comparison, and reroll ancestry.
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

    local bytes = ApproximateBytes(report)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true end

    -- Preserve selected sources and the authoritative Zone policy summary while
    -- trimming duplicated score prose and raw calculations.
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

    -- Last-resort compaction keeps report identity, ancestry, selected sources,
    -- Zone policy results, Phase D, warnings, and headline performance.
    if type(report.performance) == "table" then report.performance.phaseStats = nil end
    bytes = ApproximateBytes(report)
    if bytes <= D.MAX_REPORT_BYTES then return bytes, true end

    if type(report.cache) == "table" then report.cache.invalidationReasons = nil end
    bytes = ApproximateBytes(report)
    return bytes, true
end
