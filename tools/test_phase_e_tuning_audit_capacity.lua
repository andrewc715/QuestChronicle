QuestChronicleDB = {}
QuestChronicle = {
    version = "1.9.0.15a1",
    _Core = { JsonEncode = function() return "{}" end },
    Wardrobe = { _Private = {} },
    ZoneStyle = { MODE_TRAVELER = "TRAVELER", Traveler = {} },
}
local QC = QuestChronicle
local T = QC.ZoneStyle.Traveler
local WP = QC.Wardrobe._Private
T.CONFIG = { thresholds = { severe = .72, loudImpact = .55 } }
T.SLOT_VISIBILITY_WEIGHTS = { HEAD = .9 }
QC.Wardrobe.GetSlotDefinition = function(key) return { key = key, label = key } end
WP.FindSourceByVisualID = function(slotKey, visualID)
    return { slotKey = slotKey, sourceID = visualID + 1000, visualID = visualID, itemID = visualID + 2000, styleName = "Appearance " .. visualID }
end
WP.GetSourceByID = function() return nil end
T.GetDescriptor = function(source)
    return {
        dominantPalette = source.visualID % 2 == 0 and "steel" or "earth",
        dominantFinish = source.visualID % 3 == 0 and "plain" or nil,
        confidence = { palette = .7, finish = source.visualID % 3 == 0 and .66 or 0 },
        loudness = .1,
    }
end

dofile("Core/ZoneStyle/Traveler/TuningAudit.lua")
dofile("Core/ZoneStyle/Traveler/TuningExport.lua")
T.StartTuningAudit()

local function report(index, visualID, repair)
    return {
        id = "QCDBG-CAP-" .. index,
        timestamp = 1000 + index,
        result = "COMPLETED",
        mode = "TRAVELER",
        action = "GENERATE_OUTFIT",
        context = { zone = "Zone " .. ((index - 1) % 5 + 1) },
        skeleton = { components = {} },
        support = {
            decisions = { {
                slotKey = "HEAD", name = "Appearance " .. visualID,
                visualID = visualID, outlierSeverity = .2, mismatchSpent = .1, echoSupport = 1,
            } },
            repairs = repair and { {
                slotKey = "HEAD", previousVisualID = visualID, previousName = "Appearance " .. visualID,
                replacementVisualID = visualID + 10000, replacementName = "Replacement " .. visualID,
                trigger = "palette-family overflow", severityBefore = .4, mismatchBefore = .8,
            } } or {},
        },
    }
end

-- Give the oldest visual high priority so deterministic pruning must retain it.
assert(T.ObserveTuningReport(report(1, 1, true)))
for index = 2, 310 do assert(T.ObserveTuningReport(report(index, index, false))) end
local status, audit = T.GetTuningAuditStatus()
assert(status.uniqueVisuals == T.TUNING_MAX_IDENTITIES, "identity cap was not enforced")
assert(audit.entries["V:1"], "high-priority repair target was pruned")
assert(not audit.entries["V:2"], "oldest low-priority identity should be pruned first")

-- Repeated observations must remain compact.
for index = 311, 316 do assert(T.ObserveTuningReport(report(index, 310, false))) end
local entry = audit.entries["V:310"]
assert(#entry.sampleReportIDs == T.TUNING_MAX_SAMPLE_REPORTS, "sample report cap failed")
assert(#entry.contexts == T.TUNING_MAX_CONTEXTS, "context cap failed")
local markdown = T.BuildTuningAuditExport()
assert(#markdown < 150000, "bounded tuning export grew unexpectedly large")

print(string.format("PASS Phase E tuning audit capacity: %d identities, %d-byte export", status.uniqueVisuals, #markdown))
