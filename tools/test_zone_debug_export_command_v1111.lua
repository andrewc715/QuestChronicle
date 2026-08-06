local printed, shown
QuestChronicle = {
    _Core = {},
    ZoneStyle = {
        PrintZoneDiagnostics = function() printed = "diagnostics" return true end,
        Zone = {
            BuildZoneDebugExport = function()
                return "# export", { evidenceEntries = 9, selectedPieces = 4 }
            end,
        },
    },
    ShowZoneDebugExport = function(text) shown = text return true end,
}
local QC = QuestChronicle
QC._Core.Print = function(text) printed = text end
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_debug_export_command_v1111.lua$", "")
assert(loadfile(root .. "Core/Chronicle/ZoneDebugCommands.lua"))()
assert(QC._Core.HandleZoneDebugCommand("debug") == true and printed == "diagnostics", "plain Zone debug routing changed")
printed = nil
assert(QC._Core.HandleZoneDebugCommand("debug export") == true, "Zone debug export command failed")
assert(shown == "# export", "Zone debug export did not open the copy surface")
assert(printed and printed:find("9 evidence entries", 1, true) and printed:find("4 selected pieces", 1, true), "Zone export confirmation is incomplete")
print("PASS v1.11.1 Zone debug command: chat diagnostics preserved and copy export routed")
