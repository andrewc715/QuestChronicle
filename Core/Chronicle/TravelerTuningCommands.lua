local QC = QuestChronicle
local P = QC._Core

function P.HandleTravelerTuningCommand(remainder)
    local traveler = QC.ZoneStyle and QC.ZoneStyle.Traveler
    if not traveler then
        P.Print("Traveler tuning tools are not available yet.")
        return false
    end

    local tuningCommand, tuningRest = tostring(remainder or ""):match("^(%S*)%s*(.-)$")
    tuningCommand = string.lower(tuningCommand or "")
    tuningRest = string.lower(tuningRest or "")

    if tuningCommand == "start" and traveler.StartTuningAudit then
        local _, message = traveler.StartTuningAudit()
        P.Print(message)
    elseif tuningCommand == "status" and traveler.PrintTuningAuditStatus then
        traveler.PrintTuningAuditStatus()
    elseif tuningCommand == "stop" and traveler.StopTuningAudit then
        local _, message = traveler.StopTuningAudit()
        P.Print(message)
    elseif tuningCommand == "export" and traveler.BuildTuningAuditExport then
        local text, status = traveler.BuildTuningAuditExport()
        if QC.ShowTravelerTuningExport then
            QC.ShowTravelerTuningExport(text)
            P.Print(string.format(
                "Traveler tuning export opened (%d actions, %d visuals).",
                status.actionsObserved or 0,
                status.uniqueVisuals or 0
            ))
        else
            P.Print("The tuning export is ready, but the copy window is not available yet.")
        end
    elseif tuningCommand == "clear" and traveler.ClearTuningAudit then
        local _, message = traveler.ClearTuningAudit(tuningRest == "confirm")
        P.Print(message)
    else
        P.Print("Usage: /qc traveler tuning start|status|stop|export|clear confirm")
        return false
    end
    return true
end
