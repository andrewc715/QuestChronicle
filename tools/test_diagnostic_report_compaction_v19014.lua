QuestChronicle = { Diagnostics = nil, _Core = {} }
QuestChronicleDB = { ui = {} }
QuestChronicle.Notify = function() end
QuestChronicle.GetCurrentCharacter = function()
    return { key = "Tester-Realm", name = "Tester", realm = "Realm" }
end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/History.lua")

local D = QuestChronicle.Diagnostics
local oversizedSlots = {}
for index = 1, 80 do
    oversizedSlots[index] = {
        slotKey = "SLOT_" .. index,
        slotLabel = "Diagnostic Duplicate Slot " .. index,
        name = string.rep("Oversized duplicate appearance metadata ", 10),
        sourceID = 1000 + index,
        visualID = 2000 + index,
        itemID = 3000 + index,
    }
end

local report, message = D.AddReport({
    formatVersion = D.FORMAT_VERSION,
    id = "QCDBG-COMPACTION-1",
    sequence = 1,
    timestamp = 1785890000,
    timestampText = "2026-08-04 20:00:00",
    version = "1.9.0.14",
    action = "GENERATE_OUTFIT",
    result = "COMPLETED",
    generationToken = "QCGEN-COMPACTION-1",
    lineageID = "Tester-Realm",
    character = { key = "Tester-Realm", name = "Tester", realm = "Realm" },
    outfit = { generatedName = "Compacted Outfit", slots = oversizedSlots },
    skeleton = { components = {}, scoreBreakdown = { total = 100 } },
    support = {
        profile = {
            profileID = "QCPROFILE-COMPACTION",
            activeAnchors = { { slotKey = "CHEST", label = "Chest" } },
            entries = { { slotKey = "CHEST", label = "Chest", sourceID = 1, visualID = 2 } },
            descriptor = { palette = { steel = 1 }, material = { plate = 1 }, setIDs = { 1, 2, 3 } },
        },
        decisions = {}, repairs = {}, finalValidationStatus = "CLEAN",
    },
    performance = { elapsedMs = 100, maxStepMs = 5, phaseStats = {} },
    cache = { invalidationReasons = { NONE = 0, LOGIN_SESSION_RESET = 0 } },
    warnings = {},
})

assert(report, message or "oversized report should be compacted and accepted")
local reports = D.GetReports()
assert(#reports == 1, "compacted report must remain visible in Debug History")
assert(reports[1].id == "QCDBG-COMPACTION-1", "wrong report survived compaction")
assert((reports[1].approximateBytes or math.huge) <= D.MAX_REPORT_BYTES, "compacted report still exceeds the persistence ceiling")
assert(reports[1].outfit and reports[1].outfit.generatedName == "Compacted Outfit", "headline outfit data was lost")
assert(reports[1].outfit.slots == nil, "duplicate outfit slot payload should be removed first")
assert(reports[1].support and reports[1].support.profile and reports[1].support.profile.entries, "reusable support profile entries must survive")
local foundWarning = false
for _, warning in ipairs(reports[1].warnings or {}) do
    if warning.key == "REPORT_TRIMMED" then foundWarning = true break end
end
assert(foundWarning, "compacted report must explain that trimming occurred")

print(string.format("PASS oversized diagnostic report retained after compaction: %d bytes", reports[1].approximateBytes or 0))
