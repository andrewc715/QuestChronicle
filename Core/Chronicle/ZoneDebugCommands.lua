local QC = QuestChronicle
local P = QC._Core

function P.HandleZoneDebugCommand(remainder)
    local subcommand, rest = tostring(remainder or ""):match("^(%S*)%s*(.-)$")
    subcommand = string.lower(subcommand or "")
    rest = string.lower(rest or "")

    if subcommand ~= "debug" then
        P.Print("Usage: /qc zone debug [export]")
        return false
    end

    if rest == "" then
        if QC.ZoneStyle and QC.ZoneStyle.PrintZoneDiagnostics then
            return QC.ZoneStyle.PrintZoneDiagnostics()
        end
        P.Print("Zone diagnostics are not available yet.")
        return false
    end

    if rest == "export" then
        local Zone = QC.ZoneStyle and QC.ZoneStyle.Zone
        if not Zone or type(Zone.BuildZoneDebugExport) ~= "function" then
            P.Print("The Zone debug export is not available yet.")
            return false
        end
        local text, status = Zone.BuildZoneDebugExport()
        if QC.ShowZoneDebugExport then
            QC.ShowZoneDebugExport(text)
            status = status or {}
            P.Print(string.format(
                "Zone debug export opened (%d evidence entries, %d selected pieces).",
                tonumber(status.evidenceEntries) or 0,
                tonumber(status.selectedPieces) or 0
            ))
            return true
        end
        P.Print("The Zone debug export is ready, but the copy window is not available yet.")
        return false
    end

    P.Print("Usage: /qc zone debug [export]")
    return false
end
