QuestChronicleDB = { ui = {} }
QuestChronicle = {
    version = "1.9.0.15a1",
    _Core = { JsonEncode = function() return "{}" end },
    Wardrobe = { _Private = {} },
    ZoneStyle = { MODE_TRAVELER = "TRAVELER", Traveler = {} },
}
local QC = QuestChronicle
local WP = QC.Wardrobe._Private
local T = QC.ZoneStyle.Traveler
QC.Notify = function() end
QC.GetCurrentCharacter = function() return { key = "Tester-Realm", name = "Tester", realm = "Realm" } end
QC.Wardrobe.GetSlotDefinition = function(key) return { key = key, label = key } end
WP.GetSourceByID = function(slotKey, sourceID)
    if slotKey == "CHEST" and sourceID == 10 then
        return { slotKey = "CHEST", sourceID = 10, visualID = 20, itemID = 30, styleName = "Field Plate Armor" }
    end
end
WP.FindSourceByVisualID = function(slotKey, visualID)
    if slotKey == "CHEST" and visualID == 20 then return WP.GetSourceByID(slotKey, 10) end
end
T.CONFIG = { thresholds = { severe = .72, loudImpact = .55 } }
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1 }
T.GetDescriptor = function()
    return { dominantPalette = "steel", dominantFinish = "plain", confidence = { palette = .7, finish = .66 }, loudness = .1 }
end

dofile("Core/ZoneStyle/Traveler/TuningAudit.lua")
dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")

T.StartTuningAudit()
local D = QC.Diagnostics
local report = {
    formatVersion = D.FORMAT_VERSION,
    id = "QCDBG-TUNING-HOOK-1",
    sequence = 1,
    timestamp = 100,
    version = QC.version,
    action = "GENERATE_OUTFIT",
    mode = "TRAVELER",
    result = "COMPLETED",
    generationToken = "QCGEN-TUNING-HOOK-1",
    lineageID = "Tester-Realm",
    character = { key = "Tester-Realm", name = "Tester", realm = "Realm" },
    skeleton = { components = { { slotKey = "CHEST", sourceID = 10, visualID = 20, itemID = 30, name = "Field Plate Armor" } } },
    support = { decisions = {}, repairs = {} },
    performance = {}, cache = {}, warnings = {},
}
local stored, message = D.AddReport(report)
assert(stored, message or "report should be stored")
local status, audit = T.GetTuningAuditStatus()
assert(status.actionsObserved == 1, "accepted report was not observed")
assert(audit.entries["V:20"] and audit.entries["V:20"].selectedCount == 1, "appearance was not aggregated")
assert(stored.travelerTuningAudit == nil, "audit data must not be embedded in normal reports")
local duplicate = D.AddReport(report)
assert(duplicate and duplicate.id == report.id, "duplicate report should resolve to existing report")
assert(T.GetTuningAuditStatus().actionsObserved == 1, "duplicate report was observed twice")

local originalObserver = T.ObserveTuningReport
T.ObserveTuningReport = function() error("synthetic observer failure") end
local second = {}
for key, value in pairs(report) do second[key] = value end
second.id = "QCDBG-TUNING-HOOK-2"
second.sequence = 2
second.timestamp = 101
second.generationToken = "QCGEN-TUNING-HOOK-2"
local storedSecond, secondMessage = D.AddReport(second)
assert(storedSecond, secondMessage or "observer failure must not block report persistence")
assert(#D.GetReports() == 2, "observer failure removed a valid report")
assert((QuestChronicleDB.travelerTuningAudit.collectionErrors or 0) == 1, "observer failure was not counted")
T.ObserveTuningReport = originalObserver

print("PASS Phase E diagnostic-history observation hook, duplicate isolation, and failure containment")
