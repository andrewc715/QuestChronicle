local QC = QuestChronicle
local UI = QC.UI

local FILTERS = {
    { key = "ALL", label = "All Events" },
    { key = "LIFECYCLE", label = "Quest Lifecycle" },
    { key = "OBJECTIVES", label = "Objectives & State" },
    { key = "NOTES", label = "RP Notes" },
    { key = "REMOVALS", label = "Abandoned & Removed" },
}

local FILTER_INDEX = {}
for index, filter in ipairs(FILTERS) do
    FILTER_INDEX[filter.key] = index
end

function UI.CreateChronicleTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)
    pane.page = 1
    pane.pageSize = 25

    UI.CreatePaneTitle(
        pane,
        "Chronicle",
        "Browse the recorded journey. Search and filters apply to the current character."
    )

    local searchLabel = pane:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -58)
    searchLabel:SetText("Search")

    local searchBox = CreateFrame("EditBox", nil, pane, "InputBoxTemplate")
    searchBox:SetSize(205, 24)
    searchBox:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 4, -4)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(80)
    pane.searchBox = searchBox

    local clearSearchButton = UI.CreateButton(pane, "Clear", 55, 24)
    clearSearchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    pane.clearSearchButton = clearSearchButton

    local filterButton = UI.CreateButton(pane, "Filter: All Events", 170, 24)
    filterButton:SetPoint("LEFT", clearSearchButton, "RIGHT", 10, 0)
    pane.filterButton = filterButton

    local orderButton = UI.CreateButton(pane, "Newest First", 120, 24)
    orderButton:SetPoint("LEFT", filterButton, "RIGHT", 8, 0)
    pane.orderButton = orderButton

    local refreshButton = UI.CreateButton(pane, "Refresh", 75, 24)
    refreshButton:SetPoint("LEFT", orderButton, "RIGHT", 8, 0)

    local resultLabel = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    resultLabel:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -8)
    resultLabel:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    resultLabel:SetJustifyH("LEFT")
    pane.resultLabel = resultLabel

    local scroller = UI.CreateScrollableText(pane, -118, 48)
    pane.scroller = scroller

    local newerButton = UI.CreateButton(pane, "Newer", 90, 24)
    newerButton:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 12)
    pane.newerButton = newerButton

    local pageLabel = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageLabel:SetPoint("LEFT", newerButton, "RIGHT", 12, 0)
    pageLabel:SetWidth(245)
    pageLabel:SetJustifyH("CENTER")
    pane.pageLabel = pageLabel

    local olderButton = UI.CreateButton(pane, "Older", 90, 24)
    olderButton:SetPoint("LEFT", pageLabel, "RIGHT", 12, 0)
    pane.olderButton = olderButton

    UI.SetTooltip(searchBox, "Search Chronicle", "Search quest names, quest IDs, objective text, locations, RP notes, event types, and quest states.")
    UI.SetTooltip(clearSearchButton, "Clear Search", "Remove the current search text and return to all events allowed by the selected filter.")
    UI.SetTooltip(filterButton, "Event Filter", "Cycle through Chronicle event groups. Hold Shift while clicking to cycle backward.")
    UI.SetTooltip(orderButton, "Chronicle Order", "Switch between newest-first and oldest-first display.")
    UI.SetTooltip(refreshButton, "Refresh View", "Rebuild the current Chronicle page from the latest in-memory addon data.")

    local function GetFilter()
        local uiState = QC.GetUIState()
        return uiState.chronicleFilter or "ALL"
    end

    local function SetFilter(key)
        QC.GetUIState().chronicleFilter = key
        pane.page = 1
        pane:Refresh()
    end

    local function GetFilteredEvents()
        local events = QC.GetEvents()
        local results = {}
        local searchText = searchBox:GetText() or ""
        local filter = GetFilter()

        for _, event in ipairs(events) do
            if UI.EventMatchesFilter(event, filter) and UI.EventMatchesSearch(event, searchText) then
                table.insert(results, event)
            end
        end

        return results
    end

    local function AddEventWithSeparator(lines, event, previousDayKey)
        local settings = QC.GetSettings()
        local dayKey = UI.GetDayKey(event.timestamp)
        if settings.showDateSeparators ~= false and dayKey ~= previousDayKey then
            if #lines > 0 then
                table.insert(lines, "")
            end
            table.insert(lines, UI.FormatDaySeparator(event.timestamp))
            table.insert(lines, "")
        end
        table.insert(lines, UI.FormatEvent(event))
        return dayKey
    end

    function pane:Refresh()
        local results = GetFilteredEvents()
        local uiState = QC.GetUIState()
        local newestFirst = uiState.chronicleNewestFirst ~= false
        local pageCount = math.max(1, math.ceil(#results / self.pageSize))
        self.page = math.max(1, math.min(self.page, pageCount))

        local filterKey = GetFilter()
        local filter = FILTERS[FILTER_INDEX[filterKey] or 1]
        filterButton:SetText("Filter: " .. filter.label)
        orderButton:SetText(newestFirst and "Newest First" or "Oldest First")
        newerButton:SetText(newestFirst and "Newer" or "Older")
        olderButton:SetText(newestFirst and "Older" or "Newer")
        clearSearchButton:SetEnabled(UI.Trim(searchBox:GetText()) ~= "")

        local first = #results > 0 and ((self.page - 1) * self.pageSize + 1) or 0
        local last = #results > 0 and math.min(#results, first + self.pageSize - 1) or 0
        resultLabel:SetText(string.format("%s matching events", UI.FormatNumber(#results)))
        pageLabel:SetText(string.format("Page %d of %d  •  Events %s-%s", self.page, pageCount, UI.FormatNumber(first), UI.FormatNumber(last)))
        newerButton:SetEnabled(self.page > 1)
        olderButton:SetEnabled(self.page < pageCount)

        if #results == 0 then
            scroller:SetText(UI.muted .. "No Chronicle events match the current search and filter." .. UI.reset)
            return
        end

        local lines = {}
        local previousDayKey

        if newestFirst then
            for displayIndex = first, last do
                local eventIndex = #results - displayIndex + 1
                previousDayKey = AddEventWithSeparator(lines, results[eventIndex], previousDayKey)
                if displayIndex < last then
                    table.insert(lines, "")
                end
            end
        else
            for eventIndex = first, last do
                previousDayKey = AddEventWithSeparator(lines, results[eventIndex], previousDayKey)
                if eventIndex < last then
                    table.insert(lines, "")
                end
            end
        end

        scroller:SetText(table.concat(lines, "\n"))
    end

    searchBox:SetScript("OnTextChanged", function(self)
        QC.GetUIState().chronicleSearch = self:GetText() or ""
        pane.page = 1
        pane:Refresh()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    clearSearchButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:SetFocus()
    end)

    filterButton:SetScript("OnClick", function()
        local current = FILTER_INDEX[GetFilter()] or 1
        if IsShiftKeyDown and IsShiftKeyDown() then
            current = current - 1
            if current < 1 then
                current = #FILTERS
            end
        else
            current = current + 1
            if current > #FILTERS then
                current = 1
            end
        end
        SetFilter(FILTERS[current].key)
    end)

    orderButton:SetScript("OnClick", function()
        local uiState = QC.GetUIState()
        uiState.chronicleNewestFirst = not (uiState.chronicleNewestFirst ~= false)
        pane.page = 1
        pane:Refresh()
    end)

    refreshButton:SetScript("OnClick", function()
        pane:Refresh()
    end)

    newerButton:SetScript("OnClick", function()
        pane.page = math.max(1, pane.page - 1)
        pane:Refresh()
    end)

    olderButton:SetScript("OnClick", function()
        pane.page = pane.page + 1
        pane:Refresh()
    end)

    QC.RegisterCallback("EVENT_RECORDED", pane, function()
        if pane:IsShown() then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("DATA_UPDATED", pane, function()
        if pane:IsShown() then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", pane, function(settingName)
        if pane:IsShown() and (settingName == "showQuestIDs" or settingName == "showDateSeparators") then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        local savedSearch = QC.GetUIState().chronicleSearch or ""
        if searchBox:GetText() ~= savedSearch then
            searchBox:SetText(savedSearch)
        end
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        local savedSearch = QC.GetUIState().chronicleSearch or ""
        if searchBox:GetText() ~= savedSearch then
            searchBox:SetText(savedSearch)
        end
        pane:Refresh()
    end)

    return pane
end
