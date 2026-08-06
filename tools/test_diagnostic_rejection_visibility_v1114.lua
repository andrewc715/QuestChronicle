local printed, notified = {}, {}
QuestChronicle = { Diagnostics = nil, _Core = {} }
QuestChronicleDB = { ui = {} }
QuestChronicle.Print = function(message) printed[#printed + 1] = tostring(message) end
QuestChronicle.Notify = function(eventName, ...) notified[#notified + 1] = { eventName, ... } end
QuestChronicle.GetCurrentCharacter = function() return { key = "Tester-Realm", name = "Tester", realm = "Realm" } end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")

local D = QuestChronicle.Diagnostics
local report, message = D.AddReport({
    formatVersion = D.FORMAT_VERSION, id = "QCDBG-REJECT-1", sequence = 1,
    timestamp = 1785981100, action = "GENERATE_OUTFIT", result = "COMPLETED",
    generationToken = "QCGEN-REJECT-1", lineageID = "Tester-Realm",
    character = { key = "Tester-Realm" }, message = string.rep("Uncompactable diagnostic text ", 1800),
    warnings = {},
})

assert(report == nil, "uncompactable report should still be rejected")
assert(message == "Diagnostic report remained above the persistence limit after compaction.", "unexpected rejection reason")
assert(#printed == 1 and printed[1]:find("Debug report could not be saved", 1, true), "report rejection was not printed visibly")
assert(#notified == 1 and notified[1][1] == "DIAGNOSTIC_REPORT_REJECTED", "report rejection event was not emitted")
assert(D.GetHistoryCounters().malformedReportsDiscarded == 1, "discard counter did not record the failure")

print("PASS v1.11.4 diagnostic persistence rejection is visible in chat and callback events")
