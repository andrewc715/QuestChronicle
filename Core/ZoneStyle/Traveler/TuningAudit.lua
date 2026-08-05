local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local T = ZoneStyle.Traveler
local Wardrobe = QC.Wardrobe
local WP = Wardrobe and Wardrobe._Private

T.TUNING_AUDIT_FORMAT = 1
T.TUNING_MAX_IDENTITIES = 300
T.TUNING_MAX_SAMPLE_REPORTS = 3
T.TUNING_MAX_CONTEXTS = 3
T.TUNING_MAX_NAMES = 4
T.TUNING_MAX_IDS = 8
T.TUNING_MAX_SLOTS = 12

local function Now()
    return type(time) == "function" and time() or 0
end

local function SafeText(value)
    if value == nil then return "" end
    local ok, text = pcall(tostring, value)
    return ok and text or ""
end

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function AddUnique(values, value, limit)
    value = value ~= nil and value or nil
    if value == nil or value == "" then return false end
    for _, existing in ipairs(values) do
        if existing == value then return false end
    end
    if #values >= (limit or 8) then return false end
    values[#values + 1] = value
    return true
end

local function Increment(values, key, amount)
    if key == nil or key == "" then return end
    values[key] = (tonumber(values[key]) or 0) + (tonumber(amount) or 1)
end

local function CountMap(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

local function IdentityKey(visualID, sourceID, itemID)
    visualID = tonumber(visualID)
    sourceID = tonumber(sourceID)
    itemID = tonumber(itemID)
    if visualID and visualID > 0 then return "V:" .. tostring(visualID), "visualID", visualID end
    if sourceID and sourceID > 0 then return "S:" .. tostring(sourceID), "sourceID", sourceID end
    if itemID and itemID > 0 then return "I:" .. tostring(itemID), "itemID", itemID end
    return nil
end

local function NewAudit()
    return {
        formatVersion = T.TUNING_AUDIT_FORMAT,
        enabled = false,
        startedAt = nil,
        stoppedAt = nil,
        actionsObserved = 0,
        entries = {},
        lastObservedReportID = nil,
        lastExportAt = nil,
        collectionErrors = 0,
        lastError = nil,
    }
end

function T.EnsureTuningAudit()
    QuestChronicleDB = QuestChronicleDB or {}
    local audit = QuestChronicleDB.travelerTuningAudit
    if type(audit) ~= "table" or tonumber(audit.formatVersion) ~= T.TUNING_AUDIT_FORMAT then
        audit = NewAudit()
        QuestChronicleDB.travelerTuningAudit = audit
    end
    audit.enabled = audit.enabled == true
    audit.actionsObserved = math.max(0, math.floor(tonumber(audit.actionsObserved) or 0))
    audit.entries = type(audit.entries) == "table" and audit.entries or {}
    audit.collectionErrors = math.max(0, math.floor(tonumber(audit.collectionErrors) or 0))
    return audit
end

local function NewEntry(key, identityType, identityValue)
    return {
        key = key,
        identityType = identityType,
        identityValue = identityValue,
        visualID = identityType == "visualID" and identityValue or nil,
        sourceIDs = {},
        itemIDs = {},
        names = {},
        slots = {},
        selectedCount = 0,
        anchorCount = 0,
        supportCount = 0,
        repairTargetCount = 0,
        replacementCount = 0,
        paletteOverflowTargetCount = 0,
        zeroEchoCount = 0,
        severeOutlierCount = 0,
        worstOutlierCount = 0,
        worstOutlierContexts = {},
        maximumSeverity = 0,
        maximumMismatch = 0,
        maximumProminence = 0,
        dominantPaletteCounts = {},
        dominantFinishCounts = {},
        echoFamiliesRequested = {},
        paletteConfidenceMin = nil,
        paletteConfidenceMax = nil,
        finishConfidenceMin = nil,
        finishConfidenceMax = nil,
        contexts = {},
        sampleReportIDs = {},
        firstObservedAt = nil,
        lastObservedAt = nil,
        overrideExisting = false,
    }
end

local function EnsureEntry(audit, visualID, sourceID, itemID)
    local key, identityType, identityValue = IdentityKey(visualID, sourceID, itemID)
    if not key then return nil end
    local entry = audit.entries[key]
    if type(entry) ~= "table" then
        entry = NewEntry(key, identityType, identityValue)
        audit.entries[key] = entry
    end
    if tonumber(visualID) and tonumber(visualID) > 0 then entry.visualID = tonumber(visualID) end
    AddUnique(entry.sourceIDs, tonumber(sourceID), T.TUNING_MAX_IDS)
    AddUnique(entry.itemIDs, tonumber(itemID), T.TUNING_MAX_IDS)
    return entry
end

local function EntryPriority(entry)
    return (tonumber(entry.repairTargetCount) or 0) * 100
        + (tonumber(entry.paletteOverflowTargetCount) or 0) * 60
        + (tonumber(entry.zeroEchoCount) or 0) * 55
        + (tonumber(entry.severeOutlierCount) or 0) * 55
        + (tonumber(entry.worstOutlierCount) or 0) * 45
        + (tonumber(entry.replacementCount) or 0) * 10
        + math.min(9, tonumber(entry.selectedCount) or 0)
end

local function PruneAudit(audit)
    while CountMap(audit.entries) > T.TUNING_MAX_IDENTITIES do
        local worstKey, worstEntry
        for key, entry in pairs(audit.entries) do
            if not worstEntry then
                worstKey, worstEntry = key, entry
            else
                local priority, worstPriority = EntryPriority(entry), EntryPriority(worstEntry)
                local last, worstLast = tonumber(entry.lastObservedAt) or 0, tonumber(worstEntry.lastObservedAt) or 0
                if priority < worstPriority
                    or (priority == worstPriority and last < worstLast)
                    or (priority == worstPriority and last == worstLast and key > worstKey)
                then
                    worstKey, worstEntry = key, entry
                end
            end
        end
        if not worstKey then break end
        audit.entries[worstKey] = nil
    end
end

local function ContextLabel(report)
    local context = report and report.context or {}
    local zone = SafeText(context.zone)
    local profile = SafeText(context.profileLabel)
    local era = SafeText(context.eraShortLabel or context.eraLabel)
    local parts = {}
    if zone ~= "" then parts[#parts + 1] = zone end
    if profile ~= "" and profile ~= zone then parts[#parts + 1] = profile end
    if era ~= "" then parts[#parts + 1] = era end
    return #parts > 0 and table.concat(parts, " • ") or "Unknown context"
end

local function ResolveSource(snapshot)
    if not snapshot or not WP then return nil end
    local slotKey = snapshot.slotKey
    local sourceID = tonumber(snapshot.sourceID)
    local visualID = tonumber(snapshot.visualID)
    if sourceID and WP.GetSourceByID then
        local source = WP.GetSourceByID(slotKey, sourceID)
        if source then return source end
    end
    if visualID and WP.FindSourceByVisualID then return WP.FindSourceByVisualID(slotKey, visualID) end
    return nil
end

local function ResolveDescriptor(snapshot)
    local source = ResolveSource(snapshot)
    if not source or not T.GetDescriptor then return nil, source end
    local definition = Wardrobe and Wardrobe.GetSlotDefinition and Wardrobe.GetSlotDefinition(snapshot.slotKey)
    return T.GetDescriptor(source, definition), source
end

local function UpdateConfidence(entry, prefix, value)
    value = tonumber(value)
    if value == nil then return end
    local minKey, maxKey = prefix .. "ConfidenceMin", prefix .. "ConfidenceMax"
    entry[minKey] = entry[minKey] == nil and value or math.min(entry[minKey], value)
    entry[maxKey] = entry[maxKey] == nil and value or math.max(entry[maxKey], value)
end

local function TouchEntry(entry, snapshot, report, descriptor, source)
    local observedAt = tonumber(report and report.timestamp) or Now()
    entry.firstObservedAt = entry.firstObservedAt or observedAt
    entry.lastObservedAt = math.max(tonumber(entry.lastObservedAt) or 0, observedAt)
    AddUnique(entry.names, SafeText(snapshot and snapshot.name ~= "" and snapshot.name or source and (source.styleName or source.name)), T.TUNING_MAX_NAMES)
    AddUnique(entry.slots, SafeText(snapshot and snapshot.slotKey), T.TUNING_MAX_SLOTS)
    AddUnique(entry.sourceIDs, tonumber(snapshot and snapshot.sourceID or source and source.sourceID), T.TUNING_MAX_IDS)
    AddUnique(entry.itemIDs, tonumber(snapshot and snapshot.itemID or source and source.itemID), T.TUNING_MAX_IDS)
    AddUnique(entry.contexts, ContextLabel(report), T.TUNING_MAX_CONTEXTS)
    AddUnique(entry.sampleReportIDs, report and report.id, T.TUNING_MAX_SAMPLE_REPORTS)
    if descriptor then
        Increment(entry.dominantPaletteCounts, descriptor.dominantPalette)
        Increment(entry.dominantFinishCounts, descriptor.dominantFinish)
        UpdateConfidence(entry, "palette", descriptor.confidence and descriptor.confidence.palette)
        UpdateConfidence(entry, "finish", descriptor.confidence and descriptor.confidence.finish)
    end
end

local function ObserveSelected(audit, snapshot, role, report, seen)
    if not snapshot or snapshot.hidden or not (snapshot.sourceID or snapshot.visualID or snapshot.itemID) then return end
    local descriptor, source = ResolveDescriptor(snapshot)
    local visualID = snapshot.visualID or (source and source.visualID)
    local sourceID = snapshot.sourceID or (source and source.sourceID)
    local itemID = snapshot.itemID or (source and source.itemID)
    local entry = EnsureEntry(audit, visualID, sourceID, itemID)
    if not entry then return end
    TouchEntry(entry, snapshot, report, descriptor, source)

    if not seen.selected[entry.key] then
        seen.selected[entry.key] = true
        entry.selectedCount = entry.selectedCount + 1
    end
    if role == "anchor" and not seen.anchor[entry.key] then
        seen.anchor[entry.key] = true
        entry.anchorCount = entry.anchorCount + 1
    elseif role == "support" and not seen.support[entry.key] then
        seen.support[entry.key] = true
        entry.supportCount = entry.supportCount + 1
    end

    local severity = tonumber(snapshot.outlierSeverity) or 0
    local mismatch = tonumber(snapshot.mismatchSpent) or 0
    entry.maximumSeverity = math.max(entry.maximumSeverity, severity)
    entry.maximumMismatch = math.max(entry.maximumMismatch, mismatch)
    local prominence = tonumber(T.SLOT_VISIBILITY_WEIGHTS and T.SLOT_VISIBILITY_WEIGHTS[snapshot.slotKey]) or 0
    entry.maximumProminence = math.max(entry.maximumProminence, prominence)
    if severity > (T.CONFIG and T.CONFIG.thresholds and T.CONFIG.thresholds.severe or 0.72)
        and not seen.severe[entry.key]
    then
        seen.severe[entry.key] = true
        entry.severeOutlierCount = entry.severeOutlierCount + 1
    end

    local echo = tonumber(snapshot.echoSupport)
    local impact = descriptor and (tonumber(descriptor.loudness) or 0) * prominence or 0
    local loudThreshold = T.CONFIG and T.CONFIG.thresholds and T.CONFIG.thresholds.loudImpact or 0.55
    if echo ~= nil and echo <= 0.0001 and impact >= loudThreshold and not seen.zeroEcho[entry.key] then
        seen.zeroEcho[entry.key] = true
        entry.zeroEchoCount = entry.zeroEchoCount + 1
        Increment(entry.echoFamiliesRequested, descriptor and descriptor.dominantPalette or "unknown")
    end
end

local function TouchRepairEntry(audit, visualID, name, slotKey, report)
    local snapshot = { visualID = visualID, name = name, slotKey = slotKey }
    local descriptor, source = ResolveDescriptor(snapshot)
    local entry = EnsureEntry(audit, visualID, source and source.sourceID, source and source.itemID)
    if not entry then return nil end
    TouchEntry(entry, snapshot, report, descriptor, source)
    return entry
end

local function ObserveWorstOutlier(audit, report)
    local worst
    for _, decision in ipairs(report and report.support and report.support.decisions or {}) do
        local severity = tonumber(decision.outlierSeverity) or 0
        if not decision.locked and not decision.protectedByLock
            and (not worst or severity > (tonumber(worst.outlierSeverity) or 0))
        then
            worst = decision
        end
    end
    if not worst or (tonumber(worst.outlierSeverity) or 0) <= 0 then return end
    local descriptor, source = ResolveDescriptor(worst)
    local entry = EnsureEntry(
        audit,
        worst.visualID or (source and source.visualID),
        worst.sourceID or (source and source.sourceID),
        worst.itemID or (source and source.itemID)
    )
    if not entry then return end
    TouchEntry(entry, worst, report, descriptor, source)
    entry.worstOutlierCount = (tonumber(entry.worstOutlierCount) or 0) + 1
    AddUnique(entry.worstOutlierContexts, ContextLabel(report), T.TUNING_MAX_CONTEXTS)
end

local function ObserveRepairs(audit, report)
    for _, repair in ipairs(report and report.support and report.support.repairs or {}) do
        local previous = TouchRepairEntry(audit, repair.previousVisualID, repair.previousName, repair.slotKey, report)
        if previous then
            previous.repairTargetCount = previous.repairTargetCount + 1
            local trigger = string.lower(SafeText(repair.trigger))
            if trigger:find("palette", 1, true) then previous.paletteOverflowTargetCount = previous.paletteOverflowTargetCount + 1 end
            if trigger:find("echo", 1, true) then previous.zeroEchoCount = previous.zeroEchoCount + 1 end
            if trigger:find("sever", 1, true) or trigger:find("outlier", 1, true) then
                previous.severeOutlierCount = previous.severeOutlierCount + 1
            end
            previous.maximumSeverity = math.max(previous.maximumSeverity, tonumber(repair.severityBefore) or 0)
            previous.maximumMismatch = math.max(previous.maximumMismatch, tonumber(repair.mismatchBefore) or 0)
        end
        local replacement = TouchRepairEntry(audit, repair.replacementVisualID, repair.replacementName, repair.slotKey, report)
        if replacement then replacement.replacementCount = replacement.replacementCount + 1 end
    end
end

local function IsObservableReport(report)
    if type(report) ~= "table" then return false end
    local result = string.upper(SafeText(report.result))
    if result ~= "COMPLETED" and result ~= "FALLBACK" then return false end
    if string.upper(SafeText(report.mode)) ~= string.upper(SafeText(ZoneStyle.MODE_TRAVELER or "TRAVELER")) then return false end
    return type(report.support) == "table"
end

function T.ObserveTuningReport(report)
    local audit = T.EnsureTuningAudit()
    if not audit.enabled or not IsObservableReport(report) then return false end
    if report.id and audit.lastObservedReportID == report.id then return false end

    audit.actionsObserved = audit.actionsObserved + 1
    audit.lastObservedReportID = report.id
    local seen = { selected = {}, anchor = {}, support = {}, severe = {}, zeroEcho = {} }
    for _, component in ipairs(report.skeleton and report.skeleton.components or {}) do
        ObserveSelected(audit, component, "anchor", report, seen)
    end
    for _, decision in ipairs(report.support and report.support.decisions or {}) do
        ObserveSelected(audit, decision, "support", report, seen)
    end
    ObserveWorstOutlier(audit, report)
    ObserveRepairs(audit, report)
    PruneAudit(audit)
    return true
end

function T.StartTuningAudit()
    local audit = T.EnsureTuningAudit()
    audit.enabled = true
    audit.startedAt = audit.startedAt or Now()
    audit.stoppedAt = nil
    return audit, "Traveler tuning audit started. Generate or reroll Traveler outfits normally."
end

function T.StopTuningAudit()
    local audit = T.EnsureTuningAudit()
    audit.enabled = false
    audit.stoppedAt = Now()
    return audit, "Traveler tuning audit stopped; the collected batch was preserved."
end

function T.ClearTuningAudit(confirmed)
    if confirmed ~= true then return nil, "Use /qc traveler tuning clear confirm to remove the local tuning batch." end
    local audit = NewAudit()
    QuestChronicleDB = QuestChronicleDB or {}
    QuestChronicleDB.travelerTuningAudit = audit
    return audit, "Traveler tuning audit cleared."
end

function T.GetTuningAuditStatus()
    local audit = T.EnsureTuningAudit()
    local status = {
        enabled = audit.enabled,
        actionsObserved = audit.actionsObserved,
        uniqueVisuals = CountMap(audit.entries),
        repairedAppearances = 0,
        zeroEchoSuspects = 0,
        paletteOverflowSuspects = 0,
        repeatOffenders = 0,
        approximateBytes = 0,
        collectionErrors = audit.collectionErrors or 0,
    }
    for _, entry in pairs(audit.entries) do
        if (entry.repairTargetCount or 0) > 0 then status.repairedAppearances = status.repairedAppearances + 1 end
        if (entry.zeroEchoCount or 0) > 0 then status.zeroEchoSuspects = status.zeroEchoSuspects + 1 end
        if (entry.paletteOverflowTargetCount or 0) > 0 then status.paletteOverflowSuspects = status.paletteOverflowSuspects + 1 end
        if (entry.repairTargetCount or 0) >= 2
            or (entry.paletteOverflowTargetCount or 0) >= 2
            or (entry.zeroEchoCount or 0) >= 2
            or ((entry.worstOutlierCount or 0) >= 2 and #(entry.worstOutlierContexts or {}) >= 2)
            or ((entry.selectedCount or 0) >= 3 and (entry.repairTargetCount or 0) >= 2)
        then
            status.repeatOffenders = status.repeatOffenders + 1
        end
    end
    if QC._Core and QC._Core.JsonEncode then
        local ok, encoded = pcall(QC._Core.JsonEncode, audit)
        if ok and type(encoded) == "string" then status.approximateBytes = #encoded end
    end
    return status, audit
end
