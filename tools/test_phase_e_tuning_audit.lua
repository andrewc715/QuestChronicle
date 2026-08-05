QuestChronicleDB = {}
QuestChronicle = {
    version = "1.9.0.15a1",
    _Core = {},
    Wardrobe = { _Private = {} },
    ZoneStyle = { MODE_TRAVELER = "TRAVELER", Traveler = {} },
}
local QC = QuestChronicle
local T = QC.ZoneStyle.Traveler
local WP = QC.Wardrobe._Private

T.CONFIG = { thresholds = { severe = 0.72, loudImpact = 0.55 } }
T.SLOT_VISIBILITY_WEIGHTS = {
    CHEST = 1.0, TWO_HAND = 0.9, OFF_HAND = 0.65, SHIRT = 0.2, HANDS = 0.65,
}

local sources = {
    CHEST = {
        [1] = { sourceID = 1, visualID = 101, itemID = 1001, styleName = "Steel Chest", slotKey = "CHEST" },
    },
    TWO_HAND = {
        [2] = { sourceID = 2, visualID = 202, itemID = 1002, styleName = "Red Greatsword", slotKey = "TWO_HAND" },
    },
    OFF_HAND = {
        [2] = { sourceID = 2, visualID = 202, itemID = 1002, styleName = "Red Greatsword", slotKey = "OFF_HAND" },
    },
    SHIRT = {
        [3] = { sourceID = 3, visualID = 303, itemID = 1003, styleName = "Gray Woolen Shirt", slotKey = "SHIRT" },
        [4] = { sourceID = 4, visualID = 304, itemID = 1004, styleName = "Brown Linen Shirt", slotKey = "SHIRT" },
    },
    HANDS = {
        [5] = { sourceID = 5, visualID = 505, itemID = 1005, styleName = "Crimson Gauntlets", slotKey = "HANDS" },
    },
}

QC.Wardrobe.GetSlotDefinition = function(slotKey) return { key = slotKey, label = slotKey } end
WP.GetSourceByID = function(slotKey, sourceID) return sources[slotKey] and sources[slotKey][sourceID] end
WP.FindSourceByVisualID = function(slotKey, visualID)
    for _, source in pairs(sources[slotKey] or {}) do if source.visualID == visualID then return source end end
end

local descriptors = {
    [101] = { dominantPalette = "steel", dominantFinish = "plain", confidence = { palette = .7, finish = .66 }, loudness = .1 },
    [202] = { dominantPalette = "red", dominantFinish = "polished", confidence = { palette = .7, finish = .66 }, loudness = .8 },
    [303] = { dominantPalette = "neutral", dominantFinish = nil, confidence = { palette = .7, finish = 0 }, loudness = .08 },
    [304] = { dominantPalette = "earth", dominantFinish = nil, confidence = { palette = .7, finish = 0 }, loudness = .08 },
    [505] = { dominantPalette = "red", dominantFinish = "military", confidence = { palette = .7, finish = .66 }, loudness = .95 },
}
T.GetDescriptor = function(source) return descriptors[source.visualID] end
QC._Core.JsonEncode = function(value)
    local count = 0
    local function walk(node)
        if type(node) ~= "table" then count = count + #tostring(node or "") return end
        for key, child in pairs(node) do count = count + #tostring(key); walk(child) end
    end
    walk(value)
    return string.rep("x", count)
end

dofile("Core/ZoneStyle/Traveler/TuningAudit.lua")
dofile("Core/ZoneStyle/Traveler/TuningExport.lua")

local function Report(id, repaired)
    return {
        id = id,
        timestamp = 1000 + tonumber(id:match("%d+")),
        result = "COMPLETED",
        mode = "TRAVELER",
        action = "GENERATE_OUTFIT",
        context = { zone = "Netherstorm", eraShortLabel = "Through TBC" },
        skeleton = { components = {
            { slotKey = "CHEST", name = "Steel Chest", sourceID = 1, visualID = 101, itemID = 1001 },
            { slotKey = "TWO_HAND", name = "Red Greatsword", sourceID = 2, visualID = 202, itemID = 1002 },
            { slotKey = "OFF_HAND", name = "Red Greatsword", sourceID = 2, visualID = 202, itemID = 1002 },
        } },
        support = {
            decisions = {
                { slotKey = "SHIRT", name = repaired and "Brown Linen Shirt" or "Gray Woolen Shirt", sourceID = repaired and 4 or 3, visualID = repaired and 304 or 303, itemID = repaired and 1004 or 1003, mismatchSpent = .2, outlierSeverity = .38, echoSupport = 0 },
                { slotKey = "HANDS", name = "Crimson Gauntlets", sourceID = 5, visualID = 505, itemID = 1005, mismatchSpent = .5, outlierSeverity = .73, echoSupport = 0 },
            },
            repairs = repaired and {
                { slotKey = "SHIRT", previousVisualID = 303, previousName = "Gray Woolen Shirt", replacementVisualID = 304, replacementName = "Brown Linen Shirt", trigger = "palette-family overflow", severityBefore = .38, mismatchBefore = .7 },
            } or {},
        },
    }
end

assert(T.ObserveTuningReport(Report("1", true)) == false, "disabled audit must not collect")
local audit, startMessage = T.StartTuningAudit()
assert(audit.enabled and startMessage:find("started", 1, true), "audit did not start")
assert(T.ObserveTuningReport(Report("1", true)) == true, "first report not observed")
assert(audit.actionsObserved == 1, "action count wrong")
assert(audit.entries["V:202"].selectedCount == 1, "linked weapon visual must be deduplicated")
assert(#audit.entries["V:202"].slots == 2, "linked weapon slots should both be recorded")
assert(audit.entries["V:303"].repairTargetCount == 1, "repair target not counted")
assert(audit.entries["V:303"].paletteOverflowTargetCount == 1, "palette repair target not counted")
assert(audit.entries["V:304"].replacementCount == 1, "replacement not counted")
assert(audit.entries["V:505"].zeroEchoCount == 1, "loud zero-echo support not counted")
assert(audit.entries["V:505"].severeOutlierCount == 1, "severe support not counted")

assert(T.ObserveTuningReport(Report("2", true)) == true, "second report not observed")
local status = T.GetTuningAuditStatus()
assert(status.actionsObserved == 2 and status.repeatOffenders >= 1, "repeat offender threshold not reached")
assert(audit.entries["V:303"].repairTargetCount == 2, "repeat repair target count wrong")

local markdown = T.BuildTuningAuditExport()
assert(markdown:find("# Quest Chronicle Traveler Tuning Audit", 1, true), "export header missing")
assert(markdown:find("## Palette Suspects", 1, true), "palette section missing")
assert(markdown:find("## Missing Echo Suspects", 1, true), "echo section missing")
assert(markdown:find("## Repeat Offenders", 1, true), "repeat section missing")
assert(markdown:find("V:303", 1, true), "repair target stable key missing")
assert(markdown:find("V:505", 1, true), "zero-echo stable key missing")

T.StopTuningAudit()
assert(T.ObserveTuningReport(Report("3", false)) == false, "stopped audit must not collect")
assert(audit.actionsObserved == 2, "stopped audit changed action count")
local _, warning = T.ClearTuningAudit(false)
assert(warning:find("clear confirm", 1, true), "clear confirmation missing")
local cleared = T.ClearTuningAudit(true)
assert(cleared.actionsObserved == 0 and next(cleared.entries) == nil, "confirmed clear failed")

print("PASS Phase E local tuning audit aggregation, thresholds, export, and controls")
