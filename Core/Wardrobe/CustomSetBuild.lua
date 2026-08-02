local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function Wardrobe.DeleteConcept(conceptID)
    local store = P.EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then
        return false, "That outfit concept is no longer available."
    end
    store[conceptID] = nil
    local state = P.EnsurePreviewState()
    if state.selectedConceptID == conceptID then
        state.selectedConceptID = nil
    end
    if QC.Notify then
        QC.Notify("WARDROBE_CONCEPTS_CHANGED")
    end
    return true, "Deleted outfit concept: " .. tostring(concept.name or "Unnamed")
end

P.CUSTOM_SET_SLOT_FALLBACK = {
    HEAD = 1,
    SHOULDER = 3,
    BACK = 15,
    CHEST = 5,
    SHIRT = 4,
    TABARD = 19,
    WRIST = 9,
    HANDS = 10,
    WAIST = 6,
    LEGS = 7,
    FEET = 8,
    ONE_HAND = 16,
    TWO_HAND = 16,
    RANGED = 16,
    OFF_HAND = 17,
}

P.CUSTOM_SET_LIST_SIZE = tonumber(INVSLOT_LAST_EQUIPPED) or 19

function P.GetConceptSource(concept, slotKey)
    return concept and P.GetSourceByID(slotKey, concept.selections and concept.selections[slotKey]) or nil
end

function P.GetConceptOutfitIcon(concept)
    for _, slotKey in ipairs({ "HEAD", "CHEST", "SHOULDER", "TWO_HAND", "ONE_HAND", "RANGED", "BACK" }) do
        local source = P.GetConceptSource(concept, slotKey)
        if source and tonumber(source.icon) then return tonumber(source.icon) end
    end
    return 134938 -- INV_Misc_Book_09
end

function P.EmptyItemTransmogInfo()
    if ItemUtil and type(ItemUtil.CreateItemTransmogInfo) == "function" then
        return ItemUtil.CreateItemTransmogInfo(0, 0, 0)
    end
    return { appearanceID = 0, secondaryAppearanceID = 0, illusionID = 0 }
end

function P.CreateItemTransmogInfo(sourceID)
    sourceID = tonumber(sourceID) or 0
    if ItemUtil and type(ItemUtil.CreateItemTransmogInfo) == "function" then
        return ItemUtil.CreateItemTransmogInfo(sourceID, 0, 0)
    end
    return { appearanceID = sourceID, secondaryAppearanceID = 0, illusionID = 0 }
end

function P.CreateEmptyCustomSetList()
    local list
    if TransmogUtil and type(TransmogUtil.GetEmptyItemTransmogInfoList) == "function" then
        list = P.SafeCall(TransmogUtil.GetEmptyItemTransmogInfoList)
    end
    if type(list) ~= "table" then
        list = {}
    end
    -- Blizzard indexes Custom Set data by the actual inventory slot ID. Keep a
    -- complete array through INVSLOT_LAST_EQUIPPED, including non-transmog slots,
    -- so the native API receives the same structure its own UI creates.
    for slotID = 1, P.CUSTOM_SET_LIST_SIZE do
        if type(list[slotID]) ~= "table" then
            list[slotID] = P.EmptyItemTransmogInfo()
        end
    end
    return list
end

function P.GetCustomSetSlotID(definition)
    if not definition then return nil end
    local slotID = P.SafeCall(GetInventorySlotInfo, definition.slotName)
    return tonumber(slotID) or P.CUSTOM_SET_SLOT_FALLBACK[definition.key]
end

function P.CategoryAllowedForDefinition(definition, categoryID)
    if not definition or not categoryID then return true end
    local allowed = {}
    for _, value in ipairs(P.ResolveCategoryIDs(definition)) do allowed[tonumber(value)] = true end
    -- Blizzard may allow one-hand or two-hand weapon appearances in the
    -- secondary weapon slot (for example Fury). Accept every weapon family here;
    -- the concept was already validated against the equipped hand before saving.
    if definition.key == "OFF_HAND" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, value in ipairs(P.ResolveCategoryIDs(P.slotByKey[familyKey])) do allowed[tonumber(value)] = true end
        end
    end
    return allowed[tonumber(categoryID)] == true
end

function P.GetActualSourceFacts(sourceID, source)
    sourceID = tonumber(sourceID)
    if not sourceID then return nil end
    source = source or P.GetSourceInfo(sourceID) or { sourceID = sourceID }
    local appearanceInfo = C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource
        and P.SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID) or nil
    return {
        sourceID = sourceID,
        source = source,
        appearanceInfo = appearanceInfo,
        visualID = appearanceInfo and (appearanceInfo.appearanceID or appearanceInfo.visualID)
            or source.visualID or source.appearanceID or source.itemAppearanceID,
        categoryID = source.categoryID,
        collected = P.IsSourceCollected(sourceID, source),
        hideVisual = source.isHideVisual == true,
        displayable = not (source.canDisplayOnPlayer == false
            or source.isValidSourceForPlayer == false
            or source.meetsTransmogPlayerCondition == false
            or source.useError
            or (appearanceInfo and appearanceInfo.canDisplayOnPlayer == false)
            or (appearanceInfo and appearanceInfo.meetsTransmogPlayerCondition == false)),
    }
end

function P.SourceCanEnterCustomSet(sourceID, definition, allowHide, source)
    local facts = P.GetActualSourceFacts(sourceID, source)
    if not facts then return false, nil end
    if not P.CategoryAllowedForDefinition(definition, facts.categoryID) then return false, facts end
    if allowHide and facts.hideVisual then return true, facts end
    return facts.collected == true and facts.displayable == true and not facts.hideVisual, facts
end

function P.AddCandidateID(candidates, seen, sourceID)
    sourceID = tonumber(sourceID)
    if sourceID and sourceID > 0 and not seen[sourceID] then
        seen[sourceID] = true
        table.insert(candidates, sourceID)
    end
end

function P.ResolveCollectedConceptSource(concept, definition)
    local selectedSourceID = concept.selections and tonumber(concept.selections[definition.key])
    local selectedSource = selectedSourceID and P.GetSourceByID(definition.key, selectedSourceID) or nil
    local visualID = concept.visuals and concept.visuals[definition.key]
        or selectedSource and selectedSource.visualID

    local candidates, seen = {}, {}
    P.AddCandidateID(candidates, seen, selectedSourceID)

    if visualID and C_TransmogCollection and C_TransmogCollection.GetAllAppearanceSources then
        for _, sourceID in ipairs(P.SafeCall(C_TransmogCollection.GetAllAppearanceSources, visualID) or {}) do
            P.AddCandidateID(candidates, seen, sourceID)
        end
    end

    if visualID then
        local transmogLocation = P.GetTransmogLocation(definition)
        local categories = {}
        for _, categoryID in ipairs(P.ResolveCategoryIDs(definition)) do table.insert(categories, categoryID) end
        if definition.key == "OFF_HAND" then
            for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
                for _, categoryID in ipairs(P.ResolveCategoryIDs(P.slotByKey[familyKey])) do table.insert(categories, categoryID) end
            end
        end
        for _, categoryID in ipairs(categories) do
            local appearance = { visualID = visualID, isCollected = true }
            for _, source in ipairs(P.GetKnownSources(appearance, categoryID, transmogLocation)) do
                P.AddCandidateID(candidates, seen, type(source) == "table" and source.sourceID or source)
            end
        end
    end

    local bestFacts
    for _, sourceID in ipairs(candidates) do
        local valid, facts = P.SourceCanEnterCustomSet(sourceID, definition, false)
        if valid then
            if not bestFacts
                or sourceID == selectedSourceID
                or (facts.visualID == visualID and bestFacts.visualID ~= visualID)
                or sourceID < bestFacts.sourceID then
                bestFacts = facts
            end
            if sourceID == selectedSourceID and facts.collected then break end
        end
    end
    return bestFacts, visualID
end

function P.ResolveHiddenConceptSource(definition)
    local transmogLocation = P.GetTransmogLocation(definition)
    for _, categoryID in ipairs(P.ResolveCategoryIDs(definition)) do
        local appearances = P.GetCategoryAppearancesRobust(categoryID, transmogLocation)
        for _, appearance in ipairs(appearances or {}) do
            if appearance.isHideVisual == true then
                local candidates = P.GetKnownSources(appearance, categoryID, transmogLocation)
                if appearance.sourceID then table.insert(candidates, 1, appearance.sourceID) end
                for _, candidate in ipairs(candidates) do
                    local sourceID = type(candidate) == "table" and candidate.sourceID or candidate
                    local valid, facts = P.SourceCanEnterCustomSet(sourceID, definition, true, type(candidate) == "table" and candidate or nil)
                    if valid and facts.hideVisual then return facts end
                end
            end
        end
    end
    return nil
end

function P.BuildConceptCustomSetList(concept)
    local list = P.CreateEmptyCustomSetList()
    local expectedSlots = {}
    local resolvedSources = {}
    local unresolved = {}
    local populated = 0

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local selectedSourceID = concept.selections and tonumber(concept.selections[definition.key])
        local hidden = concept.hidden and concept.hidden[definition.key] == true
        if selectedSourceID or hidden then
            local slotID = P.GetCustomSetSlotID(definition)
            if not slotID then
                table.insert(unresolved, tostring(definition.label or definition.key) .. " (inventory slot unavailable)")
            else
                local facts, visualID
                if hidden then
                    facts = P.ResolveHiddenConceptSource(definition)
                else
                    facts, visualID = P.ResolveCollectedConceptSource(concept, definition)
                end

                if not facts then
                    table.insert(unresolved, tostring(definition.label or definition.key))
                else
                    local previous = expectedSlots[slotID]
                    if previous and previous.sourceID ~= facts.sourceID then
                        return nil, 0, nil, nil, string.format(
                            "The concept contains conflicting %s and %s appearances for inventory slot %d. Load the concept, reset the weapon selections, and save it again.",
                            tostring(previous.label or previous.slotKey),
                            tostring(definition.label or definition.key),
                            slotID
                        )
                    end

                    list[slotID] = P.CreateItemTransmogInfo(facts.sourceID)
                    expectedSlots[slotID] = {
                        slotID = slotID,
                        slotKey = definition.key,
                        slotName = definition.slotName,
                        label = definition.label or definition.key,
                        sourceID = facts.sourceID,
                        visualID = facts.visualID or visualID,
                        hidden = hidden,
                    }
                    resolvedSources[definition.key] = {
                        requestedSourceID = selectedSourceID,
                        resolvedSourceID = facts.sourceID,
                        visualID = facts.visualID or visualID,
                        hidden = hidden,
                        resolvedAt = time(),
                    }
                    if not previous then populated = populated + 1 end
                end
            end
        end
    end

    if #unresolved > 0 then
        return nil, 0, nil, nil,
            "Quest Chronicle could not resolve collected Custom Set sources for: " .. table.concat(unresolved, ", ") .. ". Rescan the wardrobe and save the concept again. Nothing was sent to WoW."
    end

    return list, populated, expectedSlots, resolvedSources
end

function P.GetCustomSetInfo(customSetID)
    if not customSetID or not C_TransmogCollection then return nil end
    local name, icon = P.SafeCall(C_TransmogCollection.GetCustomSetInfo, tonumber(customSetID))
    if not name then return nil end
    return { customSetID = tonumber(customSetID), name = name, icon = icon }
end

function Wardrobe.GetCustomSets()
    local sets = {}
    if not C_TransmogCollection or type(C_TransmogCollection.GetCustomSets) ~= "function" then
        return sets
    end
    for _, customSetID in ipairs(P.SafeCall(C_TransmogCollection.GetCustomSets) or {}) do
        local info = P.GetCustomSetInfo(customSetID)
        if info then table.insert(sets, info) end
    end
    table.sort(sets, function(left, right)
        local leftName = string.lower(left.name or "")
        local rightName = string.lower(right.name or "")
        if leftName == rightName then return (left.customSetID or 0) < (right.customSetID or 0) end
        return leftName < rightName
    end)
    return sets
end

function P.FindCustomSetByName(name)
    for _, info in ipairs(Wardrobe.GetCustomSets()) do
        if string.lower(info.name or "") == string.lower(name or "") then return info end
    end
    return nil
end

function P.GetAppearanceID(info)
    if type(info) ~= "table" then return 0 end
    return tonumber(info.appearanceID or info.sourceID) or 0
end

function P.GetVisualIDForSource(sourceID)
    sourceID = tonumber(sourceID)
    if not sourceID or sourceID == 0 then return nil end
    if C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource then
        local info = P.SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID)
        if info then return tonumber(info.appearanceID or info.visualID) end
    end
    local source = P.GetSourceInfo(sourceID)
    return source and tonumber(source.visualID or source.appearanceID or source.itemAppearanceID) or nil
end

function P.SortVerificationEntries(entries)
    table.sort(entries, function(left, right)
        if (left.slotID or 0) == (right.slotID or 0) then
            return tostring(left.label or "") < tostring(right.label or "")
        end
        return (left.slotID or 0) < (right.slotID or 0)
    end)
end

function P.CompareCustomSetSlots(actualList, expectedSlots)
    local report = {
        expected = 0,
        matched = 0,
        missing = {},
        altered = {},
        verifiedAt = time(),
    }

    for slotID, expected in pairs(expectedSlots or {}) do
        report.expected = report.expected + 1
        local actualSourceID = P.GetAppearanceID(actualList and actualList[slotID])
        local actualVisualID = P.GetVisualIDForSource(actualSourceID)
        local sameVisual = expected.visualID and actualVisualID and tonumber(expected.visualID) == tonumber(actualVisualID)
        if actualSourceID == expected.sourceID or sameVisual then
            report.matched = report.matched + 1
        elseif actualSourceID == 0 then
            table.insert(report.missing, {
                slotID = slotID,
                slotKey = expected.slotKey,
                label = expected.label,
                expectedSourceID = expected.sourceID,
                actualSourceID = 0,
            })
        else
            table.insert(report.altered, {
                slotID = slotID,
                slotKey = expected.slotKey,
                label = expected.label,
                expectedSourceID = expected.sourceID,
                actualSourceID = actualSourceID,
                expectedVisualID = expected.visualID,
                actualVisualID = actualVisualID,
            })
        end
    end

    P.SortVerificationEntries(report.missing)
    P.SortVerificationEntries(report.altered)
    report.success = report.expected > 0 and report.matched == report.expected
    return report
end

function P.JoinVerificationLabels(entries, includeIDs)
    local labels = {}
    for _, entry in ipairs(entries or {}) do
        if includeIDs then
            table.insert(labels, string.format(
                "%s (expected %d, received %d)",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0,
                tonumber(entry.actualSourceID) or 0
            ))
        else
            table.insert(labels, tostring(entry.label or entry.slotKey or entry.slotID))
        end
    end
    return table.concat(labels, ", ")
end

function P.FormatVerificationMessage(report)
    if not report then
        return "World of Warcraft did not return Custom Set data for verification."
    end
    if report.success then
        return string.format("Custom Set saved and verified: %d/%d selected slots matched.", report.matched or 0, report.expected or 0)
    end

    local details = {
        string.format("Custom Set verification failed: %d/%d selected slots matched.", report.matched or 0, report.expected or 0),
    }
    if #(report.missing or {}) > 0 then
        table.insert(details, "Missing: " .. P.JoinVerificationLabels(report.missing, false) .. ".")
    end
    if #(report.altered or {}) > 0 then
        table.insert(details, "Altered: " .. P.JoinVerificationLabels(report.altered, true) .. ".")
    end
    return table.concat(details, " ")
end

function P.PrintVerificationReport(report)
    if not report or report.success then return end
    if QC.Print then
        QC.Print(string.format("Custom Set verification: %d/%d selected slots matched.", report.matched or 0, report.expected or 0))
    end
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        for _, entry in ipairs(report.missing or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "  |cffff5555Missing|r %s: expected source %d, received an empty slot.",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0
            ))
        end
        for _, entry in ipairs(report.altered or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "  |cffffaa33Altered|r %s: expected source %d, received source %d.",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0,
                tonumber(entry.actualSourceID) or 0
            ))
        end
    end
end
