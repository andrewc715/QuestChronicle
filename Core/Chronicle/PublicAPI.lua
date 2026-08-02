local QC = QuestChronicle
local P = QC._Core
function QC.SetSetting(settingName, value)
    P.EnsureDatabase()
    QuestChronicleDB.settings[settingName] = value
    if QC.Notify then
        QC.Notify("SETTINGS_CHANGED", settingName, value)
    end
end

function QC.GetEvents()
    local character = QC.GetCurrentCharacter()
    return character.events or {}
end

function QC.GetActiveQuests()
    local character = QC.GetCurrentCharacter()
    local quests = {}
    for _, quest in pairs(character.activeQuests or {}) do
        table.insert(quests, quest)
    end
    table.sort(quests, function(left, right)
        local leftName = P.SafeText(left.questName):lower()
        local rightName = P.SafeText(right.questName):lower()
        if leftName == rightName then
            return (left.questID or 0) < (right.questID or 0)
        end
        return leftName < rightName
    end)
    return quests
end

function QC.RecordNote(text)
    return P.RecordNote(text)
end

function QC.SynchronizeQuestLog(sourceEvent)
    P.SyncQuestLog(sourceEvent or "UI_MANUAL_SYNC", false)
    P.RefreshCourierExport()
    return P.CountActiveQuests(QC.GetCurrentCharacter())
end

function QC.RefreshCourierSnapshot(syncFirst)
    if syncFirst then
        P.SyncQuestLog("UI_MANUAL_EXPORT", false)
    end
    return P.RefreshCourierExport()
end

function QC.GetCourierSnapshotSize()
    return type(QuestChronicleCourierExport) == "string" and #QuestChronicleCourierExport or 0
end

function QC.GetStatus()
    local character = QC.GetCurrentCharacter()
    return {
        characterKey = character.key,
        eventCount = P.CountEvents(character),
        activeQuestCount = P.CountActiveQuests(character),
        acceptedCount = P.CountEvents(character, "QUEST_ACCEPTED"),
        completedCount = P.CountEvents(character, "QUEST_TURNED_IN"),
        abandonedCount = P.CountEvents(character, "QUEST_ABANDONED"),
        removedCount = P.CountEvents(character, "QUEST_REMOVED"),
        noteCount = P.CountEvents(character, "RP_NOTE"),
        objectiveUpdateCount = P.CountEvents(character, "QUEST_OBJECTIVE_UPDATED"),
        stateChangeCount = P.CountEvents(character, "QUEST_STATE_CHANGED"),
        lastEventAt = character.lastEventAt,
        lastEventAtText = character.lastEventAtText,
        lastQuestSyncAt = character.lastQuestSyncAt,
        lastQuestSyncAtText = character.lastQuestSyncAtText,
        courierSnapshotSize = QC.GetCourierSnapshotSize(),
    }
end

QC.GetLocation = P.GetLocation
QC.TimestampText = P.TimestampText
QC.EventSummary = P.EventSummary
QC.CountEvents = P.CountEvents
QC.CountActiveQuests = P.CountActiveQuests
QC.Print = P.Print

function P.InstallAbandonHooks()
    if not hooksecurefunc or not C_QuestLog then
        return
    end

    if C_QuestLog.SetAbandonQuest and C_QuestLog.GetAbandonQuest then
        hooksecurefunc(C_QuestLog, "SetAbandonQuest", function()
            local ok, questID = pcall(C_QuestLog.GetAbandonQuest)
            if ok and questID then
                P.abandonCandidateQuestID = questID
            end
        end)
    end

    if C_QuestLog.AbandonQuest then
        hooksecurefunc(C_QuestLog, "AbandonQuest", function()
            local questID = P.abandonCandidateQuestID
            if C_QuestLog.GetAbandonQuest then
                local ok, currentQuestID = pcall(C_QuestLog.GetAbandonQuest)
                if ok and currentQuestID then
                    questID = currentQuestID
                end
            end

            if questID then
                P.confirmedAbandons[questID] = GetTime()
            end
        end)
    end
end

P.frame:RegisterEvent("ADDON_LOADED")
P.frame:RegisterEvent("PLAYER_LOGIN")
P.frame:RegisterEvent("PLAYER_LOGOUT")
P.frame:RegisterEvent("QUEST_ACCEPTED")
P.frame:RegisterEvent("QUEST_TURNED_IN")
P.frame:RegisterEvent("QUEST_REMOVED")
P.frame:RegisterEvent("QUEST_LOG_UPDATE")
P.frame:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE")
P.frame:RegisterEvent("QUEST_WATCH_UPDATE")
P.frame:RegisterEvent("TASK_PROGRESS_UPDATE")
P.frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")

P.frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= P.ADDON_NAME then
            return
        end

        P.EnsureDatabase()
        QuestChronicleCourierExport = QuestChronicleCourierExport or ""
        SLASH_QUESTCHRONICLE1 = "/questchronicle"
        SLASH_QUESTCHRONICLE2 = "/qc"
        SlashCmdList.QUESTCHRONICLE = P.HandleSlashCommand
        P.InstallAbandonHooks()

        if QC.RegisterSettings then
            QC.RegisterSettings()
        end
        if QC.InitializeMinimapButton then
            QC.InitializeMinimapButton()
        end

    elseif event == "PLAYER_LOGIN" then
        P.EnsureCharacter()
        P.StartSession()
        P.SyncQuestLog("PLAYER_LOGIN_BASELINE", true)
        P.RefreshCourierExport()
        if QC.InitializeUI then
            QC.InitializeUI()
        end
        if QC.InitializeMinimapButton then
            QC.InitializeMinimapButton()
        end
        if QC.Notify then
            QC.Notify("PLAYER_READY")
        end
        P.Print("v" .. P.ADDON_VERSION .. " loaded. Type /qc to open the Chronicle.")

    elseif event == "PLAYER_LOGOUT" then
        P.SyncQuestLog("PLAYER_LOGOUT", false)
        P.EndSession()
        P.RefreshCourierExport()

    elseif event == "QUEST_ACCEPTED" then
        local questID = ...
        P.RecordQuestAccepted(questID, "QUEST_ACCEPTED")

    elseif event == "QUEST_TURNED_IN" then
        local questID, xpReward, moneyReward = ...
        P.RecordQuestTurnIn(questID, xpReward, moneyReward)

    elseif event == "QUEST_REMOVED" then
        local questID = ...
        local character = P.currentCharacter or P.EnsureCharacter()
        local previous = character.activeQuests[tostring(questID)]
        if previous then
            P.QueueQuestRemoval(questID, previous, "QUEST_REMOVED")
        end
        P.ScheduleQuestSync("QUEST_REMOVED", 0.20)

    elseif event == "QUEST_LOG_UPDATE" then
        P.ScheduleQuestSync("QUEST_LOG_UPDATE", P.OBJECTIVE_SYNC_DELAY)

    elseif event == "QUEST_LOG_CRITERIA_UPDATE" then
        P.ScheduleQuestSync("QUEST_LOG_CRITERIA_UPDATE", 0.20)

    elseif event == "QUEST_WATCH_UPDATE" then
        P.ScheduleQuestSync("QUEST_WATCH_UPDATE", P.OBJECTIVE_SYNC_DELAY)

    elseif event == "TASK_PROGRESS_UPDATE" then
        P.ScheduleQuestSync("TASK_PROGRESS_UPDATE", 0.20)

    elseif event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        if success then
            P.UpdatePendingQuestTitles(questID)
            P.ScheduleQuestSync("QUEST_DATA_LOAD_RESULT", 0.10)
        end
    end
end)
