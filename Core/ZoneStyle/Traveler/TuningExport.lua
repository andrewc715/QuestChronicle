local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local T = ZoneStyle.Traveler

local function SafeText(value)
    if value == nil then return "" end
    local ok, text = pcall(tostring, value)
    return ok and text or ""
end

local function Join(values, fallback)
    local parts = {}
    for _, value in ipairs(values or {}) do
        if value ~= nil and value ~= "" then parts[#parts + 1] = tostring(value) end
    end
    return #parts > 0 and table.concat(parts, ", ") or (fallback or "None")
end

local function CountMap(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

local function TopMap(values, limit)
    local entries = {}
    for key, value in pairs(values or {}) do entries[#entries + 1] = { key = key, value = tonumber(value) or 0 } end
    table.sort(entries, function(left, right)
        if left.value == right.value then return tostring(left.key) < tostring(right.key) end
        return left.value > right.value
    end)
    local parts = {}
    for index = 1, math.min(limit or 3, #entries) do
        parts[#parts + 1] = string.format("%s (%d)", tostring(entries[index].key), entries[index].value)
    end
    return #parts > 0 and table.concat(parts, ", ") or "unknown"
end

local function ConfidenceRange(entry, prefix)
    local low = tonumber(entry[prefix .. "ConfidenceMin"])
    local high = tonumber(entry[prefix .. "ConfidenceMax"])
    if low == nil and high == nil then return "unknown" end
    low, high = low or high or 0, high or low or 0
    if math.abs(low - high) < 0.0005 then return string.format("%.2f", low) end
    return string.format("%.2f–%.2f", low, high)
end

local function EntryName(entry)
    return entry.names and entry.names[1] or entry.key or "Unknown appearance"
end

local function EntrySort(left, right)
    local leftScore = (left.repairTargetCount or 0) * 100 + (left.paletteOverflowTargetCount or 0) * 60
        + (left.zeroEchoCount or 0) * 55 + (left.severeOutlierCount or 0) * 55
        + (left.worstOutlierCount or 0) * 45 + (left.selectedCount or 0)
    local rightScore = (right.repairTargetCount or 0) * 100 + (right.paletteOverflowTargetCount or 0) * 60
        + (right.zeroEchoCount or 0) * 55 + (right.severeOutlierCount or 0) * 55
        + (right.worstOutlierCount or 0) * 45 + (right.selectedCount or 0)
    if leftScore == rightScore then return tostring(left.key) < tostring(right.key) end
    return leftScore > rightScore
end

local function EntriesWhere(audit, predicate)
    local result = {}
    for _, entry in pairs(audit.entries or {}) do if predicate(entry) then result[#result + 1] = entry end end
    table.sort(result, EntrySort)
    while #result > 50 do table.remove(result) end
    return result
end

local function Add(lines, text)
    lines[#lines + 1] = text or ""
end

local function AddEntry(lines, entry, extra)
    Add(lines, string.format("### %s", EntryName(entry)))
    Add(lines, "")
    Add(lines, string.format("- Stable key: `%s`", tostring(entry.key or "unknown")))
    Add(lines, string.format("- Visual ID: `%s`", tostring(entry.visualID or "unknown")))
    Add(lines, string.format("- Source IDs: %s", Join(entry.sourceIDs, "None recorded")))
    Add(lines, string.format("- Item IDs: %s", Join(entry.itemIDs, "None recorded")))
    Add(lines, string.format("- Slots: %s", Join(entry.slots, "Unknown")))
    Add(lines, string.format("- Observed: %d selected • %d anchor • %d support", entry.selectedCount or 0, entry.anchorCount or 0, entry.supportCount or 0))
    Add(lines, string.format("- Phase D: %d repair targets • %d replacements • %d palette-overflow targets", entry.repairTargetCount or 0, entry.replacementCount or 0, entry.paletteOverflowTargetCount or 0))
    Add(lines, string.format("- Outlier evidence: %d zero-echo • %d severe • %d worst-slot observations across %d contexts • max severity %.3f • max mismatch %.2f", entry.zeroEchoCount or 0, entry.severeOutlierCount or 0, entry.worstOutlierCount or 0, #(entry.worstOutlierContexts or {}), entry.maximumSeverity or 0, entry.maximumMismatch or 0))
    Add(lines, string.format("- Palette: %s • confidence %s", TopMap(entry.dominantPaletteCounts), ConfidenceRange(entry, "palette")))
    Add(lines, string.format("- Finish: %s • confidence %s", TopMap(entry.dominantFinishCounts), ConfidenceRange(entry, "finish")))
    local curated = T.GetCuratedFieldsLabel and T.GetCuratedFieldsLabel({ curatedFields = entry.curatedFields }) or nil
    if curated then
        Add(lines, string.format("- Curated: %s • tuning version %s • %s %s", curated, tostring(entry.curatedTuningVersion or T.CURATED_TUNING_VERSION or 0), tostring(entry.curatedKeyType or "identity"), tostring(entry.curatedKey or entry.identityValue or "unknown")))
    end
    if CountMap(entry.echoFamiliesRequested) > 0 then Add(lines, "- Echo families requested: " .. TopMap(entry.echoFamiliesRequested)) end
    Add(lines, "- Contexts: " .. Join(entry.contexts, "Unknown"))
    Add(lines, "- Sample reports: " .. Join(entry.sampleReportIDs, "None"))
    if extra then Add(lines, "- Review note: " .. extra(entry)) end
    Add(lines, "")
end

local function AddSection(lines, title, entries, note)
    Add(lines, "## " .. title)
    Add(lines, "")
    Add(lines, note)
    Add(lines, "")
    if #entries == 0 then
        Add(lines, "No suspects met this observation threshold.")
        Add(lines, "")
        return
    end
    for _, entry in ipairs(entries) do AddEntry(lines, entry) end
end

local function IsRepeatOffender(entry)
    return (entry.repairTargetCount or 0) >= 2
        or (entry.paletteOverflowTargetCount or 0) >= 2
        or (entry.zeroEchoCount or 0) >= 2
        or ((entry.worstOutlierCount or 0) >= 2 and #(entry.worstOutlierContexts or {}) >= 2)
        or ((entry.selectedCount or 0) >= 3 and (entry.repairTargetCount or 0) >= 2)
end

function T.BuildTuningAuditExport()
    local status, audit = T.GetTuningAuditStatus()
    local lines = {}
    Add(lines, "# Quest Chronicle Traveler Tuning Audit")
    Add(lines, "")
    Add(lines, string.format("- Addon version: `%s`", tostring(QC.version or "unknown")))
    Add(lines, string.format("- Audit format: `%d`", tonumber(audit.formatVersion) or 0))
    Add(lines, string.format("- State: **%s**", audit.enabled and "COLLECTING" or "STOPPED"))
    Add(lines, string.format("- Completed Traveler actions: **%d**", status.actionsObserved or 0))
    Add(lines, string.format("- Unique visual identities: **%d**", status.uniqueVisuals or 0))
    Add(lines, string.format("- Approximate local storage: **%d bytes**", status.approximateBytes or 0))
    Add(lines, string.format("- Collection errors: **%d**", status.collectionErrors or 0))
    Add(lines, "")
    Add(lines, "> Frequency raises an appearance for human review. It does not prove the descriptor is wrong.")
    Add(lines, "")

    local palette = EntriesWhere(audit, function(entry)
        return (entry.paletteOverflowTargetCount or 0) > 0
            or CountMap(entry.dominantPaletteCounts) > 1
            or ((entry.paletteConfidenceMin == nil or entry.paletteConfidenceMin == 0) and (entry.maximumProminence or 0) >= 0.55)
    end)
    local finish = EntriesWhere(audit, function(entry)
        return CountMap(entry.dominantFinishCounts) > 1
            or ((entry.finishConfidenceMin == nil or entry.finishConfidenceMin == 0) and (entry.maximumProminence or 0) >= 0.55 and (entry.selectedCount or 0) >= 2)
    end)
    local echo = EntriesWhere(audit, function(entry) return (entry.zeroEchoCount or 0) > 0 end)
    local repeaters = EntriesWhere(audit, IsRepeatOffender)

    AddSection(lines, "Palette Suspects", palette,
        "Review screenshots before changing tags. Palette-overflow frequency alone may represent a legitimate contextual mismatch.")
    AddSection(lines, "Finish Suspects", finish,
        "Review whether the visible surface contradicts the lexicon result; a correct ornate or magical item may still be inappropriate for one outfit.")
    AddSection(lines, "Missing Echo Suspects", echo,
        "Check whether another visible appearance genuinely repeats the accent family while lacking a secondary echo tag.")
    AddSection(lines, "Repeat Offenders", repeaters,
        "Resolve in order: palette, finish, missing echo, loudness or weight, then confirm whether the appearance is simply a legitimate outlier.")

    audit.lastExportAt = type(time) == "function" and time() or 0
    return table.concat(lines, "\n"), status
end

function T.PrintTuningAuditStatus()
    local status = T.GetTuningAuditStatus()
    local printFn = QC._Core and QC._Core.Print
    if not printFn then return status end
    printFn(string.format(
        "Traveler tuning audit %s: %d actions • %d visuals • %d repaired • %d palette suspects • %d zero-echo suspects • %d repeat offenders • %d bytes.",
        status.enabled and "collecting" or "stopped",
        status.actionsObserved, status.uniqueVisuals, status.repairedAppearances,
        status.paletteOverflowSuspects, status.zeroEchoSuspects, status.repeatOffenders,
        status.approximateBytes
    ))
    return status
end
