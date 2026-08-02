local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

P.heritageSetCache = P.heritageSetCache or {}

local function ContainsHeritageArmor(text)
    text = P.Normalize(text)
    if text == "" then return false end
    if text:find("heritage armor", 1, true) then return true end
    if text:find("heritage armour", 1, true) then return true end
    if text:match("^heritage of ") then return true end
    return false
end

function P.GetReachableMaxPlayerLevel()
    local maxLevel = P.SafeCall(GetMaxLevelForPlayerExpansion)
    if type(maxLevel) ~= "number" or maxLevel <= 0 then
        maxLevel = P.SafeCall(GetMaxPlayerLevel)
    end
    if type(maxLevel) ~= "number" or maxLevel <= 0 then
        maxLevel = P.SafeCall(GetMaxLevelForLatestExpansion)
    end
    if type(maxLevel) ~= "number" or maxLevel <= 0 then
        maxLevel = tonumber(MAX_PLAYER_LEVEL)
    end
    return type(maxLevel) == "number" and maxLevel > 0 and maxLevel or nil
end

function P.GetHeritageSetName(source)
    if not C_TransmogSets or type(C_TransmogSets.GetSetInfo) ~= "function" then
        return nil
    end

    for _, setID in ipairs(P.GetSourceSetIDs(source)) do
        local cached = P.heritageSetCache[setID]
        if cached == nil then
            local setInfo = P.SafeCall(C_TransmogSets.GetSetInfo, setID)
            if type(setInfo) == "table" then
                local isHeritage = ContainsHeritageArmor(setInfo.label)
                    or ContainsHeritageArmor(setInfo.description)
                    or ContainsHeritageArmor(setInfo.name)
                cached = isHeritage and (setInfo.name or setInfo.label or "Heritage Armor") or false
                P.heritageSetCache[setID] = cached
            end
        end
        if cached then return cached end
    end
    return nil
end

function P.GetProgressionRestrictionReason(source)
    local heritageSetName = P.GetHeritageSetName(source)
    if not heritageSetName then return nil end

    local currentLevel = tonumber(UnitLevel and UnitLevel("player")) or 0
    local maxLevel = P.GetReachableMaxPlayerLevel()
    if not maxLevel or currentLevel >= maxLevel then return nil end

    return string.format(
        "%s is race Heritage Armor and is excluded from generated outfits below max level (%d/%d). Manual browsing and preview remain available.",
        heritageSetName,
        currentLevel,
        maxLevel
    )
end

function ZoneStyle.GetSourceProgressionRestrictionReason(source)
    return P.GetProgressionRestrictionReason(source)
end
