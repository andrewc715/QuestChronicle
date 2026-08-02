local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
function P.LoadItemMetadata(source)
    if not source or not source.itemID then return nil end
    local genericName = not source.name or tostring(source.name):match("^Appearance %d+$")
    if source.expansionID ~= nil and not genericName then
        return source.expansionID
    end

    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) == "function" then
        local ok, name, link, quality, _, _, itemType, itemSubType, _, equipLocation, _, _, _, _, _, expansionID = pcall(getter, source.itemID)
        if ok and name then
            source.styleName = name
            if genericName then source.name = name end
            source.styleItemLink = link or source.styleItemLink
            source.quality = source.quality or quality
            source.styleItemType = itemType
            source.styleItemSubType = itemSubType
            source.styleEquipLocation = equipLocation
            if expansionID ~= nil then source.expansionID = tonumber(expansionID) end
            return source.expansionID
        end
    end

    if C_Item and C_Item.RequestLoadItemDataByID then
        P.SafeCall(C_Item.RequestLoadItemDataByID, source.itemID)
    end
    return source.expansionID
end

function P.SourceMetadata(source)
    if not source then return "" end
    P.LoadItemMetadata(source)
    local parts = {}
    local function AddPart(value)
        if value ~= nil and tostring(value) ~= "" then
            table.insert(parts, tostring(value))
        end
    end

    AddPart(source.name)
    AddPart(source.styleName)
    AddPart(source.styleItemLink)
    AddPart(source.styleItemType)
    AddPart(source.styleItemSubType)
    AddPart(source.styleEquipLocation)
    return P.Normalize(table.concat(parts, " "))
end

-- C_Item.GetItemInfo's expansionID is useful but is not authoritative for
-- every legacy quest reward. The Wandering Isle's low-quality starter gear is
-- a known example: several sources are catalogued like older generic items.
-- Keep the fallback exact and reviewable so similarly named gear elsewhere is
-- not swept into Pandaria by a broad keyword rule.
P.wanderingIsleSourceIDs = {
    [38062] = true, -- Unmarred Cord
    [38063] = true, -- Unmarred Waistband
    [38064] = true, -- Unmarred Belt
    [38091] = true, -- Cord of Grieving
    [38092] = true, -- Ropes of Grieving
    [38093] = true, -- Cinch of Grieving
}

P.wanderingIsleItemIDs = {
    [74597] = true, -- Cord of Grieving
}

P.wanderingIsleStarterNames = {}
for _, name in ipairs({
    "Initiate's Robes", "Initiate's Wristwraps", "Initiate's Gloves", "Initiate's Rope Belt", "Initiate's Leggings", "Initiate's Slippers",
    "Initiate's Vest", "Initiate's Bracers", "Initiate's Handguards", "Initiate's Belt", "Initiate's Britches", "Initiate's Footgear",
    "Initiate's Chestpiece", "Initiate's Cuffs", "Initiate's Grips", "Initiate's Braided Belt", "Initiate's Greaves", "Initiate's Boots",
    "Initiate's Breastplate", "Initiate's Armguards", "Initiate's Gauntlets", "Initiate's Plate Belt", "Initiate's Legguards", "Initiate's Sabatons",
    "Robes of the Water Spirit", "Playful Wristbands", "Sun Pearl Gloves", "Unmarred Cord", "Homespun Leggings", "Silk Shoes",
    "Sun Pearl Vest", "Bindings of the Earth Spirit", "Gloves of Splashing Water", "Unmarred Waistband", "Soft Britches", "Summer Shoes",
    "Sun Pearl Chainmail", "Bracers of the Earth Spirit", "Gauntlets of Splashing Water", "Unmarred Chain", "Padded Greaves", "Ringing Boots",
    "Glistening Breastplate", "Sun Pearl Bracers", "Gauntlets of Earth and Water", "Unmarred Belt", "Comfortable Greaves", "Dancing Boots",
    "Protector's Robes", "Healer's Wristwraps", "Gloves of Wisdom", "Cord of Grieving", "Survival Leggings",
    "Vest of Compassion", "Gloves of Verity", "Ropes of Grieving", "Ceremonial Leggings", "Boots of Courage",
    "Empathetic Mail", "Handgrips of Verity", "Links of Grieving", "Service Greaves", "Waders of Bravery",
    "Ritual Breastplate", "Unvarnished Vambraces", "Gauntlets of Mercy", "Cinch of Grieving", "Legguards of the Brave",
    "Flameheart Crossbow", "Jade Crossbow", "Dagger of the Master", "Dagger of Silent Flame", "Dagger of the Hozen", "Jade Hilted Dagger",
    "Mace of the Master", "Humble Cudgel", "Sword of the Hozen", "Shield of Blazing Will", "Jade Shield", "Staff of the Master",
    "Staff of the Hozen", "Sword of the Burning Spirit", "Jade Hilted Sword",
}) do
    P.wanderingIsleStarterNames[P.Normalize(name)] = true
end

function P.GetCuratedSourceOrigin(source, nativeExpansionID)
    if not source then return nil end
    if P.wanderingIsleSourceIDs[tonumber(source.sourceID)] or P.wanderingIsleItemIDs[tonumber(source.itemID)] then
        return { provenanceKey = "wanderingisle", label = "The Wandering Isle", expansionID = 4, method = "curated source" }
    end

    local name = P.Normalize(source.styleName or source.name)
    if tonumber(source.sourceType) == 2 and tonumber(nativeExpansionID) and tonumber(nativeExpansionID) <= 1 and P.wanderingIsleStarterNames[name] then
        return { provenanceKey = "wanderingisle", label = "The Wandering Isle", expansionID = 4, method = "curated starter family" }
    end
    return nil
end

P.trackedOriginCache = {}

function P.GetAppearanceTrackingType()
    return Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Appearance
end

function P.GetTrackedSourceOrigin(source)
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or tonumber(source.sourceType) ~= 2 then return nil end
    if P.trackedOriginCache[sourceID] ~= nil then return P.trackedOriginCache[sourceID] or nil end

    local trackingType = P.GetAppearanceTrackingType()
    local getter = C_ContentTracking and C_ContentTracking.GetBestMapForTrackable
    if trackingType == nil or type(getter) ~= "function" then return nil end

    local identifiers = { sourceID }
    local visualID = tonumber(source.visualID)
    if visualID and visualID ~= sourceID then table.insert(identifiers, visualID) end

    local lastResult
    for _, trackableID in ipairs(identifiers) do
        local result, mapID = P.SafeCall(getter, trackingType, trackableID, true)
        lastResult = result
        if mapID then
            local mapInfo = P.SafeCall(C_Map and C_Map.GetMapInfo, mapID)
            local mapName = mapInfo and mapInfo.name or "Tracked appearance source"
            local originContext = {
                mapID = mapID,
                mapName = mapName,
                zone = mapName,
                subzone = "",
                mapTrail = P.BuildMapTrail(mapID),
            }
            local provenance, provenanceKey = ZoneStyle.ResolveProvenance(originContext)
            local origin = {
                provenanceKey = provenanceKey,
                label = provenance and provenance.label or mapName,
                mapID = mapID,
                result = result,
                method = "WoW appearance tracking",
            }
            P.trackedOriginCache[sourceID] = origin
            return origin
        end
    end

    -- A hard failure is stable for the session. DataPending is intentionally
    -- retried because Blizzard may finish loading the trackable later.
    local failure = Enum and Enum.ContentTrackingResult and Enum.ContentTrackingResult.Failure
    if failure == nil then failure = 2 end
    if lastResult == failure then P.trackedOriginCache[sourceID] = false end
    return nil
end

function P.GetSourceTypeLabel(source)
    local sourceType = tonumber(source and source.sourceType)
    local label = sourceType and _G and _G["TRANSMOG_SOURCE_" .. tostring(sourceType)]
    return P.Normalize(label)
end

P.promotionalSetCache = {}

function P.GetPromotionReason(source)
    if not source then return nil end
    if tonumber(source.sourceType) == P.TRADING_POST_SOURCE_TYPE then
        return "Trading Post appearances are excluded from generated outfits."
    end

    local sourceLabel = P.GetSourceTypeLabel(source)
    if sourceLabel ~= "" and P.TextMatchesAny(sourceLabel, P.promotionalSourceFragments) then
        return "Promotional and shop appearances are excluded from generated outfits."
    end
    if P.promotionalItemIDs[tonumber(source.itemID)] then
        return "This known promotional reward is excluded from generated outfits."
    end

    local metadata = P.SourceMetadata(source)
    if P.TextMatchesAny(metadata, P.promotionalNameFragments) then
        return "This known subscription, shop, or Recruit-a-Friend appearance is excluded from generated outfits."
    end
    return nil
end

P.styleSignalCache = setmetatable({}, { __mode = "k" })
function P.GetSourceStyleSignals(source)
    if not source then return { families = {}, intensity = 0 } end
    local text = P.SourceMetadata(source)
    local cached = P.styleSignalCache[source]
    if cached and cached.text == text then return cached end

    local families = {}
    local intensity = 0
    for family, keywords in pairs(P.styleFamilies) do
        local score = 0
        local padded = " " .. text .. " "
        for token, value in pairs(keywords) do
            local normalizedToken = P.Normalize(token)
            if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
                score = score + value
            end
        end
        if score > 0 then
            families[family] = score
            if P.dramaticFamilies[family] then intensity = math.max(intensity, score) end
        end
    end

    cached = { text = text, families = families, intensity = intensity }
    P.styleSignalCache[source] = cached
    return cached
end

P.sourceSetCache = {}
function P.GetSourceSetIDs(source)
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or not C_TransmogSets or type(C_TransmogSets.GetSetsContainingSourceID) ~= "function" then
        return {}
    end
    if P.sourceSetCache[sourceID] then return P.sourceSetCache[sourceID] end
    local setIDs = P.SafeCall(C_TransmogSets.GetSetsContainingSourceID, sourceID)
    if type(setIDs) ~= "table" then return {} end
    P.sourceSetCache[sourceID] = setIDs
    return setIDs
end

function P.GetPromotionalSetReason(source)
    if not C_TransmogSets or type(C_TransmogSets.GetSetInfo) ~= "function" then return nil end
    for _, setID in ipairs(P.GetSourceSetIDs(source)) do
        local cached = P.promotionalSetCache[setID]
        if cached == nil then
            local setInfo = P.SafeCall(C_TransmogSets.GetSetInfo, setID)
            if type(setInfo) == "table" then
                local setText = table.concat({ setInfo.name or "", setInfo.label or "", setInfo.description or "" }, " ")
                local namedPromotion = P.TextMatchesAny(setText, P.promotionalNameFragments)
                local sourcedPromotion = P.TextMatchesAny(setText, P.promotionalSourceFragments)
                cached = (namedPromotion or sourcedPromotion) and (setInfo.name or "Promotional set") or false
                P.promotionalSetCache[setID] = cached
            end
        end
        if cached then
            return string.format("%s is a promotional set and is excluded from generated outfits.", cached)
        end
    end
    return nil
end

function ZoneStyle.GetSourcePromotionReason(source)
    return P.GetPromotionReason(source) or P.GetPromotionalSetReason(source)
end

function ZoneStyle.GetPromotionReason(source)
    return ZoneStyle.GetSourcePromotionReason(source)
end

P.AddKeywordScore = nil
P.chronicleEventWeights = {
    QUEST_TURNED_IN = 7,
    QUEST_ACCEPTED = 5,
    QUEST_BECAME_ACTIVE = 4,
    QUEST_OBJECTIVE_UPDATED = 3,
    QUEST_STATE_CHANGED = 2,
}

function P.AppendQuestText(parts, value)
    if value ~= nil and tostring(value) ~= "" then
        table.insert(parts, tostring(value))
    end
end

function P.BuildQuestEvidenceText(quest)
    local parts = {}
    P.AppendQuestText(parts, quest and quest.questName)
    P.AppendQuestText(parts, quest and quest.objectiveText)
    P.AppendQuestText(parts, quest and quest.changeReason)
    P.AppendQuestText(parts, quest and quest.zone)
    P.AppendQuestText(parts, quest and quest.subZone)
    for _, objective in ipairs(quest and quest.objectives or {}) do
        P.AppendQuestText(parts, objective.text or objective.objectiveText)
    end
    return P.Normalize(table.concat(parts, " "))
end

function P.ChronicleCacheKey()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    local events = QC.GetEvents and QC.GetEvents() or {}
    local active = QC.GetActiveQuests and QC.GetActiveQuests() or {}
    local activeStamp = 0
    for _, quest in ipairs(active) do
        activeStamp = activeStamp + (tonumber(quest.updatedAt or quest.lastSeenAt) or 0)
    end
    return table.concat({ tostring(character.key or "UNKNOWN"), tostring(character.lastEventAt or 0), tostring(#events), tostring(#active), tostring(activeStamp) }, ":")
end

P.chronicleProfileCache = {}

function ZoneStyle.BuildChronicleProfile(context)
    local records = {}
    local seen = {}
    local events = QC.GetEvents and QC.GetEvents() or {}

    -- Events are append-only, so walk from newest to oldest and merge each
    -- quest into one record. This prevents objective spam from overpowering
    -- the actual sequence of adventures while retaining its useful text.
    local oldestEventIndex = math.max(1, #events - 199)
    for index = #events, oldestEventIndex, -1 do
        local event = events[index]
        local eventWeight = event and P.chronicleEventWeights[event.eventType]
        local identity = event and (event.questID or event.questName)
        local key = identity and tostring(identity)
        if eventWeight and key then
            local record = seen[key]
            if record then
                record.weight = math.max(record.weight, eventWeight)
                record.text = P.Normalize(record.text .. " " .. P.BuildQuestEvidenceText(event))
            elseif #records < 12 then
                record = {
                    key = key,
                    weight = eventWeight,
                    text = P.BuildQuestEvidenceText(event),
                    questName = event.questName,
                    eventType = event.eventType,
                }
                seen[key] = record
                table.insert(records, record)
            end
        end
    end

    local active = QC.GetActiveQuests and QC.GetActiveQuests() or {}
    table.sort(active, function(left, right)
        return (tonumber(left.updatedAt or left.lastSeenAt) or 0) > (tonumber(right.updatedAt or right.lastSeenAt) or 0)
    end)
    for _, quest in ipairs(active) do
        if #records >= 12 then break end
        local identity = quest.questID or quest.questName
        local key = identity and tostring(identity)
        if key and not seen[key] then
            local record = {
                key = key,
                weight = 4,
                text = P.BuildQuestEvidenceText(quest),
                questName = quest.questName,
                eventType = "ACTIVE",
            }
            seen[key] = record
            table.insert(records, record)
        end
    end

    local profile = {
        questCount = #records,
        records = records,
        themeScores = {},
        appearanceKeywords = {},
        topThemes = {},
    }

    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    local playerFaction = P.Normalize(character.faction or (type(UnitFactionGroup) == "function" and UnitFactionGroup("player")))
    if playerFaction == "alliance" or playerFaction == "horde" then
        profile.themeScores[playerFaction] = 1.5
    end

    for rank, record in ipairs(records) do
        local recency = math.max(0.42, 1.12 - ((rank - 1) * 0.065))
        for _, theme in ipairs(P.chronicleThemes) do
            local matches = P.TextMatchesAny(record.text, theme.evidence)
            if matches then
                profile.themeScores[theme.key] = (profile.themeScores[theme.key] or 0) + (record.weight * recency)
            end
        end
    end

    local ranked = {}
    for _, theme in ipairs(P.chronicleThemes) do
        local score = profile.themeScores[theme.key] or 0
        if score > 0 then
            local entry = { theme = theme, score = score }
            table.insert(ranked, entry)
            if not profile.dominantTheme or score > profile.dominantTheme.score then
                profile.dominantTheme = entry
            end
            if theme.kind == "faction" and (not profile.dominantFaction or score > profile.dominantFaction.score) then
                profile.dominantFaction = entry
            elseif theme.kind == "enemy" and (not profile.dominantEnemy or score > profile.dominantEnemy.score) then
                profile.dominantEnemy = entry
            end
            local keywordScale = math.min(1.35, score / 12)
            for token, value in pairs(theme.appearance or {}) do
                profile.appearanceKeywords[token] = (profile.appearanceKeywords[token] or 0) + (value * keywordScale)
            end
        end
    end
    table.sort(ranked, function(left, right)
        if left.score == right.score then return left.theme.key < right.theme.key end
        return left.score > right.score
    end)
    for index = 1, math.min(3, #ranked) do profile.topThemes[index] = ranked[index] end
    return profile
end

function ZoneStyle.GetChronicleProfile(context)
    local key = P.ChronicleCacheKey()
    if not P.chronicleProfileCache[key] then
        P.chronicleProfileCache = { [key] = ZoneStyle.BuildChronicleProfile(context) }
    end
    return P.chronicleProfileCache[key]
end

function ZoneStyle.GetChronicleSummary(context)
    local profile = ZoneStyle.GetChronicleProfile(context)
    if not profile or profile.questCount == 0 then
        return "Echo: no recent quest signal"
    end
    local labels = {}
    if profile.dominantEnemy then table.insert(labels, profile.dominantEnemy.theme.label) end
    if profile.dominantFaction and (not profile.dominantEnemy or profile.dominantFaction.theme.key ~= profile.dominantEnemy.theme.key) then
        table.insert(labels, profile.dominantFaction.theme.label)
    end
    if #labels == 0 and profile.dominantTheme then table.insert(labels, profile.dominantTheme.theme.label) end
    local signal = #labels > 0 and table.concat(labels, " + ") or "adventuring memory"
    return string.format("Echo: %s • %d recent quest%s", signal, profile.questCount, profile.questCount == 1 and "" or "s")
end

function ZoneStyle.GetSourcePreference(source, context)
    if QC.Wardrobe and QC.Wardrobe.GetSourceZonePreference then
        return QC.Wardrobe.GetSourceZonePreference(source, context)
    end
end

function P.ChronicleScore(source, context, multiplier, reasons)
    local chronicle = context and context.chronicleProfile or ZoneStyle.GetChronicleProfile(context)
    if not chronicle or chronicle.questCount == 0 then return 0 end
    return P.AddKeywordScore(P.SourceMetadata(source), chronicle.appearanceKeywords, multiplier, reasons, "Echo: ")
end

P.modeNameParts = {
    [ZoneStyle.MODE_ZONE_NATIVE] = { adjectives = { "Native", "Local", "Homeland", "Wayfarer's" }, nouns = { "Regalia", "Vanguard", "Attire", "Guard" } },
    [ZoneStyle.MODE_TRAVELER] = { adjectives = { "Trailworn", "Wayfarer's", "Far-Roaming", "Expedition" }, nouns = { "Kit", "Road", "Venture", "Attire" } },
    [ZoneStyle.MODE_CLASS_FANTASY] = { adjectives = { "Heroic", "Classforged", "Champion's", "Battleworn" }, nouns = { "Regalia", "Legacy", "Arsenal", "Oath" } },
    [ZoneStyle.MODE_CHRONICLE_ECHO] = { adjectives = { "Echoed", "Remembered", "Chronicle", "Quest-Bound" }, nouns = { "Echo", "Memory", "Legacy", "Tale" } },
}
