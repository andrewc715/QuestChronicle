QuestChronicle = { Diagnostics = nil }
local QC = QuestChronicle
QuestChronicleDB = { marker = "keep", ui = {} }
QC.Notify = function() end
QC._Core = {}

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")
local D = QC.Diagnostics

for index = 1, 12 do
    local report = D.AddReport({
        formatVersion = 1,
        timestamp = 1000 + index,
        action = "GENERATE_OUTFIT",
        result = "COMPLETED",
        message = "report " .. index,
        performance = { elapsedMs = index * 10 },
    })
    assert(report, "report should be accepted")
end

local reports = D.GetReports()
assert(#reports == 10, "history must retain exactly ten reports")
assert(reports[1].message == "report 12", "newest report must appear first")
assert(reports[10].message == "report 3", "oldest retained report should be report 3")
assert(QuestChronicleDB.marker == "keep", "diagnostic history must not replace unrelated database fields")

QuestChronicleDB.debug.reports[#QuestChronicleDB.debug.reports + 1] = { broken = true }
reports = D.GetReports()
assert(#reports == 10, "malformed reports must be discarded softly")

D.ClearReports()
assert(#D.GetReports() == 0, "clear history must remove diagnostics")
assert(QuestChronicleDB.marker == "keep", "clear history must preserve unrelated data")
print("PASS diagnostics history: newest ten retained, malformed data discarded, isolated clear preserved database")
