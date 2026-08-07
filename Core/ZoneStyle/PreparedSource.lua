local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

local function normalizePrepared(value)
    return P.Normalize and P.Normalize(value) or tostring(value or ""):lower()
end

function P.IsSourceItemMetadataTrusted(source)
    if not source or not source.itemID then return true end
    local itemID = tonumber(source.itemID)
    local genericName = not source.name or tostring(source.name):match("^Appearance %d+$")
    return source.itemMetadataVerified == true
        and tonumber(source.itemMetadataItemID) == itemID
        and source.expansionID ~= nil
        and not genericName
end

function P.BuildSourceMetadataSnapshot(source)
    if not source then return "" end
    local parts = {}
    local function AddPart(value)
        if value ~= nil and tostring(value) ~= "" then parts[#parts + 1] = tostring(value) end
    end
    AddPart(source.name)
    AddPart(source.styleName)
    AddPart(source.styleItemLink)
    AddPart(source.styleItemType)
    AddPart(source.styleItemSubType)
    AddPart(source.styleEquipLocation)
    local text = normalizePrepared(table.concat(parts, " "))
    if P.sourceMetadataTextCache then
        P.sourceMetadataTextCache[source] = {
            itemID = source.itemID,
            name = source.name,
            styleName = source.styleName,
            styleItemLink = source.styleItemLink,
            styleItemType = source.styleItemType,
            styleItemSubType = source.styleItemSubType,
            styleEquipLocation = source.styleEquipLocation,
            itemMetadataVerified = source.itemMetadataVerified,
            metadataRevision = source.metadataRevision,
            text = text,
        }
    end
    return text
end

function P.GetSourceStyleSignalsPrepared(source, metadataText)
    if not source then return { families = {}, intensity = 0 } end
    local text = metadataText ~= nil and metadataText or (P.SourceMetadata and P.SourceMetadata(source) or "")
    local cached = P.styleSignalCache and P.styleSignalCache[source]
    if cached and cached.text == text then return cached end

    local families, intensity = {}, 0
    for family, keywords in pairs(P.styleFamilies or {}) do
        local score = 0
        local padded = " " .. text .. " "
        for token, value in pairs(keywords or {}) do
            local normalizedToken = normalizePrepared(token)
            if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
                score = score + value
            end
        end
        if score > 0 then
            families[family] = score
            if P.dramaticFamilies and P.dramaticFamilies[family] then intensity = math.max(intensity, score) end
        end
    end
    cached = { text = text, families = families, intensity = intensity }
    if P.styleSignalCache then P.styleSignalCache[source] = cached end
    return cached
end

function P.GetPreparedSourceSetIDs(source, prepared)
    if prepared and prepared.setIDsKnown then return prepared.setIDs or {} end
    return P.GetSourceSetIDs and P.GetSourceSetIDs(source) or {}
end

function P.GetPreparedTrackedOrigin(source, prepared)
    if prepared and prepared.trackedOriginKnown then return prepared.trackedOrigin end
    return P.GetTrackedSourceOrigin and P.GetTrackedSourceOrigin(source) or nil
end

function P.GetPreparedExpansionID(source, prepared)
    if prepared and prepared.expansionIDKnown then return prepared.expansionID end
    if prepared and prepared.expansionID ~= nil then return prepared.expansionID end
    return ZoneStyle.GetSourceExpansionID and ZoneStyle.GetSourceExpansionID(source) or source and source.expansionID
end

function P.NewPreparedSourceInputs(source, eraEvidence)
    local expansionID = eraEvidence and tonumber(eraEvidence.expansionID) or nil
    return {
        source = source,
        metadataText = nil,
        itemMetadataVerified = false,
        setIDs = nil,
        setIDsKnown = false,
        styleSignals = nil,
        expansionID = expansionID,
        expansionIDKnown = eraEvidence ~= nil,
        trackedOrigin = nil,
        trackedOriginKnown = false,
        descriptor = nil,
    }
end

function ZoneStyle.GetSourceCoherencePrepared(source, context, prepared)
    local profile = context and context.outfitProfile
    if not profile or profile.sourceCount == 0 then return 0, true, nil end
    local setIDs = prepared and prepared.setIDsKnown and (prepared.setIDs or {}) or (P.GetSourceSetIDs and P.GetSourceSetIDs(source) or {})
    for _, setID in ipairs(setIDs) do
        if profile.setIDs[setID] then return 24, true, "same Blizzard transmog set" end
    end
    local signals = prepared and prepared.styleSignals or (P.GetSourceStyleSignals and P.GetSourceStyleSignals(source)) or { families = {}, intensity = 0 }
    local overlap, conflictingFamily = 0, nil
    for family, score in pairs(signals.families or {}) do
        if profile.families[family] then overlap = overlap + math.min(score, profile.families[family]) end
        for profileFamily, profileScore in pairs(profile.families) do
            if profileScore >= 2 and P.conflictingFamilies[family] and P.conflictingFamilies[family][profileFamily] then
                conflictingFamily = profileFamily
            end
        end
    end
    local dominantFamily = P.GetDominantFamily(profile.families)
    if overlap > 0 then return math.min(16, 3 + overlap * 1.5), true, "matching " .. tostring(dominantFamily or "outfit") .. " motif" end
    if conflictingFamily and signals.intensity >= 3 then
        return -20, false, string.format("dramatic %s conflicts with the outfit's %s motif", P.GetDominantFamily(signals.families) or "accent", conflictingFamily)
    end
    if profile.sourceCount >= 2 and signals.intensity >= 4 then
        return -18, false, profile.themedSources > 0
            and "dramatic accent does not match the established outfit motif"
            or "dramatic accent would overpower the established neutral outfit"
    end
    return 0, true, nil
end

local function chronicleScorePrepared(context, multiplier, reasons, text)
    local chronicle = context and context.chronicleProfile or (ZoneStyle.GetChronicleProfile and ZoneStyle.GetChronicleProfile(context))
    if not chronicle or chronicle.questCount == 0 then return 0 end
    return P.AddKeywordScore(text, chronicle.appearanceKeywords, multiplier, reasons, "Echo: ")
end

function ZoneStyle.ScoreSourcePrepared(source, definition, modeKey, context, coherenceScore, coherent, coherenceReason, prepared)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    context = context or ZoneStyle.GetCurrentContext()
    local profile = ZoneStyle.profiles[context.profileKey] or ZoneStyle.profiles.azeroth
    local classID
    if type(UnitClass) == "function" then
        local _, _, resolvedClassID = UnitClass("player")
        classID = resolvedClassID
    end
    local classProfile = P.classKeywords[classID] or {}
    local text = prepared and prepared.metadataText or (P.SourceMetadata and P.SourceMetadata(source) or "")
    local reasons, score = {}, 10
    if modeKey == ZoneStyle.MODE_ZONE_NATIVE then
        score = score + P.AddKeywordScore(text, profile.keywords, 1.35, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, profile.avoid, 1.0, reasons)
        score = score + P.AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.12, reasons, "Travel: ")
        score = score + chronicleScorePrepared(context, 0.22, reasons, text)
        if definition and (definition.key == "BACK" or definition.key == "TABARD") then score = score + 1.2 end
    elseif modeKey == ZoneStyle.MODE_TRAVELER then
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 1.25, reasons, "Travel: ")
        score = score + P.AddKeywordScore(text, P.travelerAvoid, 1.0, reasons)
        score = score + P.AddKeywordScore(text, profile.keywords, 0.28, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, classProfile, 0.16, reasons, "Class: ")
        score = score + chronicleScorePrepared(context, 0.18, reasons, text)
        if definition and (definition.key == "BACK" or definition.key == "WAIST" or definition.key == "FEET" or definition.key == "SHIRT") then score = score + 2.0 end
    elseif modeKey == ZoneStyle.MODE_CLASS_FANTASY then
        score = score + P.AddKeywordScore(text, classProfile, 1.35, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, profile.keywords, 0.24, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.10, reasons, "Travel: ")
        score = score + chronicleScorePrepared(context, 0.15, reasons, text)
        if definition and (definition.weaponRole or definition.key == "HEAD" or definition.key == "SHOULDER" or definition.key == "CHEST") then score = score + 2.0 end
        score = score + math.min(2.0, tonumber(source.quality or 0) * 0.35)
    else
        score = score + chronicleScorePrepared(context, 1.35, reasons, text)
        score = score + P.AddKeywordScore(text, profile.keywords, 0.30, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.12, reasons, "Travel: ")
        if definition and (definition.key == "BACK" or definition.key == "CHEST" or definition.weaponRole) then score = score + 1.2 end
    end
    if context.outfitProfile then
        if coherenceScore == nil then
            coherenceScore, coherent, coherenceReason = ZoneStyle.GetSourceCoherencePrepared(source, context, prepared)
        end
        score = score + (coherenceScore or 0)
        if #reasons < 4 and coherenceReason and ((coherenceScore or 0) > 0 or coherent == false) then
            reasons[#reasons + 1] = ((coherent == false) and "Clash: " or "Match: ") .. coherenceReason
        end
    end
    if ZoneStyle.GetSourcePreference(source, context) == "favorite" then
        score = score + 24
        if #reasons < 4 then reasons[#reasons + 1] = "Zone favorite" end
    end
    score = score + P.StableAffinity(source, profile, modeKey, classID)
    return score, reasons
end
