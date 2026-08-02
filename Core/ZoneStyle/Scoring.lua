local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
function ZoneStyle.GenerateOutfitName(modeKey, context, sources)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    context = context or ZoneStyle.GetCurrentContext()
    local chronicle = context.chronicleProfile or ZoneStyle.GetChronicleProfile(context)
    local themeEntry = chronicle and (chronicle.dominantEnemy or chronicle.dominantFaction or chronicle.dominantTheme)
    local parts = themeEntry and themeEntry.theme or P.modeNameParts[modeKey]
    local adjectives = parts.adjectives or P.modeNameParts[modeKey].adjectives
    local nouns = parts.nouns or P.modeNameParts[modeKey].nouns
    local seed = tonumber((ZoneStyle.profiles[context.profileKey] or {}).seed) or 1
    for _, source in ipairs(sources or {}) do
        seed = seed + (tonumber(source.visualID or source.sourceID or source.itemID) or 0)
    end
    if themeEntry then seed = seed + math.floor(themeEntry.score * 10) end
    local adjective = adjectives[(seed % #adjectives) + 1]
    local noun = nouns[((math.floor(seed / 7)) % #nouns) + 1]
    local zoneLabel = context.provenanceLabel or context.profileLabel or context.zone or "Azeroth"
    local pattern = seed % 4
    local name
    if pattern == 0 then
        name = adjective .. " " .. noun
    elseif pattern == 1 then
        name = zoneLabel .. " " .. noun
    elseif pattern == 2 then
        name = noun .. " of " .. zoneLabel
    else
        name = (modeKey == ZoneStyle.MODE_CHRONICLE_ECHO and "Echo of " or adjective .. " ") .. (themeEntry and themeEntry.theme.label or zoneLabel)
    end
    if #name > 48 then name = string.sub(name, 1, 48) end
    return name
end

function ZoneStyle.CreateGenerationContext(baseContext)
    local context = {}
    for key, value in pairs(baseContext or ZoneStyle.GetCurrentContext()) do
        context[key] = value
    end
    context.outfitProfile = {
        sourceIDs = {},
        setIDs = {},
        families = {},
        sourceCount = 0,
        themedSources = 0,
    }
    context.chronicleProfile = ZoneStyle.GetChronicleProfile(context)
    return context
end

function ZoneStyle.AddSourceToGenerationContext(context, source)
    local profile = context and context.outfitProfile
    if not profile or not source then return end
    local identity = tonumber(source.sourceID) or tonumber(source.itemID)
    if identity and profile.sourceIDs[identity] then return end
    if identity then profile.sourceIDs[identity] = true end

    profile.sourceCount = profile.sourceCount + 1
    local signals = P.GetSourceStyleSignals(source)
    local hasTheme = false
    for family, score in pairs(signals.families) do
        profile.families[family] = (profile.families[family] or 0) + score
        hasTheme = true
    end
    if hasTheme then profile.themedSources = profile.themedSources + 1 end
    for _, setID in ipairs(P.GetSourceSetIDs(source)) do
        profile.setIDs[setID] = (profile.setIDs[setID] or 0) + 1
    end
end

function P.GetDominantFamily(families)
    local dominant, dominantScore
    for family, score in pairs(families or {}) do
        if not dominantScore or score > dominantScore then
            dominant, dominantScore = family, score
        end
    end
    return dominant, dominantScore or 0
end

function ZoneStyle.GetSourceCoherence(source, context)
    local profile = context and context.outfitProfile
    if not profile or profile.sourceCount == 0 then return 0, true, nil end

    for _, setID in ipairs(P.GetSourceSetIDs(source)) do
        if profile.setIDs[setID] then
            return 24, true, "same Blizzard transmog set"
        end
    end

    local signals = P.GetSourceStyleSignals(source)
    local overlap = 0
    local conflictingFamily
    for family, score in pairs(signals.families) do
        if profile.families[family] then
            overlap = overlap + math.min(score, profile.families[family])
        end
        for profileFamily, profileScore in pairs(profile.families) do
            if profileScore >= 2 and P.conflictingFamilies[family] and P.conflictingFamilies[family][profileFamily] then
                conflictingFamily = profileFamily
            end
        end
    end

    local dominantFamily = P.GetDominantFamily(profile.families)
    if overlap > 0 then
        return math.min(16, 3 + overlap * 1.5), true, "matching " .. tostring(dominantFamily or "outfit") .. " motif"
    end
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

P.dropOriginCache = {}

function P.GetDropOrigin(source)
    if not source or not source.sourceID then return "", nil end
    local cached = P.dropOriginCache[source.sourceID]
    if cached then return cached.text, cached.label end

    local parts = {}
    local label
    local bossDropType = TRANSMOG_SOURCE_BOSS_DROP
    if bossDropType ~= nil and source.sourceType == bossDropType and C_TransmogCollection and C_TransmogCollection.GetAppearanceSourceDrops then
        local drops = P.SafeCall(C_TransmogCollection.GetAppearanceSourceDrops, source.sourceID)
        for _, drop in ipairs(type(drops) == "table" and drops or {}) do
            if not label and drop.instance then label = drop.instance end
            if drop.instance then table.insert(parts, drop.instance) end
            if drop.encounter then table.insert(parts, drop.encounter) end
            if drop.tier then table.insert(parts, drop.tier) end
        end
    end

    cached = { text = P.Normalize(table.concat(parts, " ")), label = label }
    P.dropOriginCache[source.sourceID] = cached
    return cached.text, cached.label
end

function ZoneStyle.GetSourceExpansionID(source)
    local nativeExpansionID = P.LoadItemMetadata(source)
    local curatedOrigin = P.GetCuratedSourceOrigin(source, nativeExpansionID)
    return curatedOrigin and curatedOrigin.expansionID or nativeExpansionID
end

function ZoneStyle.GetSourceEligibility(source, modeKey, context)
    context = context or ZoneStyle.GetCurrentContext()
    local preference = ZoneStyle.GetSourcePreference(source, context)
    if preference == "excluded" then
        return false, "excluded", "Excluded from generated outfits in this zone. Manual preview remains available."
    end
    local promotionReason = P.GetPromotionReason(source) or P.GetPromotionalSetReason(source)
    if promotionReason then
        return false, "promotional", promotionReason
    end
    if context.eraMax == nil then
        context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    end
    local eraMax, eraLabel = context.eraMax, context.eraLabel

    local nativeExpansionID = P.LoadItemMetadata(source)
    local curatedOrigin = P.GetCuratedSourceOrigin(source, nativeExpansionID)
    local expansionID = curatedOrigin and curatedOrigin.expansionID or nativeExpansionID
    if expansionID == nil then
        return false, "pending", "Waiting for WoW to load this item's era."
    end
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local restrictToZoneEra = settings.restrictOutfitsToZoneEra ~= false
    local eraEligibilityText = restrictToZoneEra and ("through " .. tostring(eraLabel)) or "with the zone era limit disabled"
    if restrictToZoneEra and expansionID > eraMax then
        local expansion = ZoneStyle.expansions[expansionID]
        return false, "era", string.format(
            "%s item; this zone permits Classic through %s.",
            expansion and expansion.label or ("Expansion " .. tostring(expansionID)),
            eraLabel
        )
    end

    if not context.provenanceResolved then
        local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
        context.provenanceKey = resolvedKey
        context.provenanceLabel = resolved and resolved.label or context.zone
        context.provenanceResolved = true
    end
    local provenance = P.provenanceByKey[context.provenanceKey]
    if not provenance then
        return true, "eligible", "Eligible " .. eraEligibilityText .. "."
    end
    context.provenanceKey = provenance.key
    context.provenanceLabel = provenance.label

    if curatedOrigin then
        if curatedOrigin.provenanceKey == provenance.key then
            return true, "eligible", string.format("Curated %s origin; eligible for %s %s.", curatedOrigin.label, provenance.label, eraEligibilityText)
        end
        return false, "zone", string.format("%s starter reward; outside the %s source pool.", curatedOrigin.label, provenance.label)
    end

    local dropText, dropLabel = P.GetDropOrigin(source)
    if dropText ~= "" then
        if P.TextMatchesAny(dropText, provenance.origins) then
            return true, "eligible", string.format("Eligible for %s %s.", provenance.label, eraEligibilityText)
        end
        return false, "zone", string.format("%s is outside the %s source pool.", dropLabel or "This boss drop", provenance.label)
    end

    local trackedOrigin = P.GetTrackedSourceOrigin(source)
    if trackedOrigin and trackedOrigin.provenanceKey then
        if trackedOrigin.provenanceKey == provenance.key then
            return true, "eligible", string.format("WoW tracks this appearance to %s; eligible %s.", trackedOrigin.label, eraEligibilityText)
        end
        return false, "zone", string.format("WoW tracks this appearance to %s, outside the %s source pool.", trackedOrigin.label, provenance.label)
    end

    local metadata = P.SourceMetadata(source)
    if P.TextMatchesAny(metadata, provenance.origins) then
        return true, "eligible", string.format("Eligible for %s %s.", provenance.label, eraEligibilityText)
    end
    local paddedMetadata = " " .. metadata .. " "
    for _, marker in ipairs(P.provenanceOriginMarkers) do
        if not marker.profileKeys[provenance.key] and paddedMetadata:find(" " .. marker.text .. " ", 1, true) then
            return false, "zone", string.format("Associated with %s, not %s.", marker.profile.label, provenance.label)
        end
    end

    return true, "eligible", restrictToZoneEra
        and "Era eligible; no conflicting source zone is reported by WoW."
        or "Zone era limit disabled; no conflicting source zone is reported by WoW."
end

function ZoneStyle.GetContextRestrictionLabel(context)
    context = context or ZoneStyle.GetCurrentContext()
    if context.eraMax == nil then
        context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    end
    if not context.provenanceResolved then
        local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
        context.provenanceKey = resolvedKey
        context.provenanceLabel = resolved and resolved.label or context.zone
        context.provenanceResolved = true
    end
    local eraLabel, eraShortLabel = context.eraLabel, context.eraShortLabel
    local provenance = P.provenanceByKey[context.provenanceKey]
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local eraText = settings.restrictOutfitsToZoneEra ~= false and ("Through " .. tostring(eraShortLabel)) or "Zone era limit off"
    return string.format("%s%s", eraText, provenance and (" • " .. provenance.label .. " sources") or ""), eraLabel, provenance
end

P.AddKeywordScore = function(text, keywords, multiplier, reasons, reasonPrefix)
    local score = 0
    local padded = " " .. text .. " "
    for token, value in pairs(keywords or {}) do
        local normalizedToken = P.Normalize(token)
        if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
            local contribution = value * multiplier
            score = score + contribution
            if contribution > 0 and #reasons < 4 then
                table.insert(reasons, (reasonPrefix or "") .. token)
            end
        end
    end
    return score
end

function P.StableAffinity(source, profile, modeKey, classID)
    local identity = tonumber(source.visualID or source.sourceID or source.itemID) or 1
    local modeSeed = modeKey == ZoneStyle.MODE_TRAVELER and 37
        or (modeKey == ZoneStyle.MODE_CLASS_FANTASY and 73
        or (modeKey == ZoneStyle.MODE_CHRONICLE_ECHO and 109 or 11))
    local value = (identity * 1103515245 + (profile.seed or 1) * 12345 + (classID or 0) * 7919 + modeSeed) % 2147483647
    return (value / 2147483647) * 3.0
end

function ZoneStyle.ScoreSource(source, definition, modeKey, context)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    context = context or ZoneStyle.GetCurrentContext()
    local profile = ZoneStyle.profiles[context.profileKey] or ZoneStyle.profiles.azeroth
    local classID
    if type(UnitClass) == "function" then
        local _, _, resolvedClassID = UnitClass("player")
        classID = resolvedClassID
    end
    local classProfile = P.classKeywords[classID] or {}
    local text = P.SourceMetadata(source)
    local reasons = {}
    local score = 10

    if modeKey == ZoneStyle.MODE_ZONE_NATIVE then
        score = score + P.AddKeywordScore(text, profile.keywords, 1.35, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, profile.avoid, 1.0, reasons)
        score = score + P.AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.12, reasons, "Travel: ")
        score = score + P.ChronicleScore(source, context, 0.22, reasons)
        if definition and (definition.key == "BACK" or definition.key == "TABARD") then score = score + 1.2 end
    elseif modeKey == ZoneStyle.MODE_TRAVELER then
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 1.25, reasons, "Travel: ")
        score = score + P.AddKeywordScore(text, P.travelerAvoid, 1.0, reasons)
        score = score + P.AddKeywordScore(text, profile.keywords, 0.28, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, classProfile, 0.16, reasons, "Class: ")
        score = score + P.ChronicleScore(source, context, 0.18, reasons)
        if definition and (definition.key == "BACK" or definition.key == "WAIST" or definition.key == "FEET" or definition.key == "SHIRT") then score = score + 2.0 end
    elseif modeKey == ZoneStyle.MODE_CLASS_FANTASY then
        score = score + P.AddKeywordScore(text, classProfile, 1.35, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, profile.keywords, 0.24, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.10, reasons, "Travel: ")
        score = score + P.ChronicleScore(source, context, 0.15, reasons)
        if definition and (definition.weaponRole or definition.key == "HEAD" or definition.key == "SHOULDER" or definition.key == "CHEST") then score = score + 2.0 end
        score = score + math.min(2.0, tonumber(source.quality or 0) * 0.35)
    else
        score = score + P.ChronicleScore(source, context, 1.35, reasons)
        score = score + P.AddKeywordScore(text, profile.keywords, 0.30, reasons, "Local: ")
        score = score + P.AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + P.AddKeywordScore(text, P.travelerKeywords, 0.12, reasons, "Travel: ")
        if definition and (definition.key == "BACK" or definition.key == "CHEST" or definition.weaponRole) then score = score + 1.2 end
    end

    if context.outfitProfile then
        local coherenceScore, coherent, coherenceReason = ZoneStyle.GetSourceCoherence(source, context)
        score = score + coherenceScore
        if #reasons < 4 and coherenceReason and (coherenceScore > 0 or not coherent) then
            table.insert(reasons, (coherent and "Match: " or "Clash: ") .. coherenceReason)
        end
    end

    if ZoneStyle.GetSourcePreference(source, context) == "favorite" then
        score = score + 24
        if #reasons < 4 then table.insert(reasons, "Zone favorite") end
    end

    score = score + P.StableAffinity(source, profile, modeKey, classID)
    return score, reasons
end

function ZoneStyle.WeightForSource(source, definition, modeKey, context)
    local score = ZoneStyle.ScoreSource(source, definition, modeKey, context)
    return math.max(1, score + 4) ^ 2, score
end

function ZoneStyle.ChooseWeightedSource(candidates, definition, modeKey, context, excludeSourceID)
    local pool = {}
    local total = 0
    local fallback
    for _, source in ipairs(candidates or {}) do
        local eligible = ZoneStyle.GetSourceEligibility(source, modeKey, context)
        local _, coherent = ZoneStyle.GetSourceCoherence(source, context)
        if eligible and coherent then
            local weight, score = ZoneStyle.WeightForSource(source, definition, modeKey, context)
            local entry = { source = source, weight = weight, score = score }
            if source.sourceID == excludeSourceID then
                fallback = entry
            else
                total = total + weight
                table.insert(pool, entry)
            end
        end
    end
    if #pool == 0 then
        return fallback and fallback.source, fallback and fallback.score
    end
    local roll = math.random() * total
    for _, entry in ipairs(pool) do
        roll = roll - entry.weight
        if roll <= 0 then return entry.source, entry.score end
    end
    local entry = pool[#pool]
    return entry.source, entry.score
end

function ZoneStyle.OrderWeaponCandidates(candidates, modeKey, context)
    for index = #(candidates or {}), 1, -1 do
        local candidate = candidates[index]
        local eligible = ZoneStyle.GetSourceEligibility(candidate.source, modeKey, context)
        local _, coherent = ZoneStyle.GetSourceCoherence(candidate.source, context)
        if not eligible or not coherent then table.remove(candidates, index) end
    end
    for _, candidate in ipairs(candidates or {}) do
        local definition = QC.Wardrobe and QC.Wardrobe.GetSlotDefinition and QC.Wardrobe.GetSlotDefinition(candidate.slotKey)
        local weight = ZoneStyle.WeightForSource(candidate.source, definition, modeKey, context)
        local roll = math.max(0.000001, math.random())
        candidate.stylePriority = math.log(roll) / weight
    end
    table.sort(candidates, function(left, right)
        return (left.stylePriority or -math.huge) > (right.stylePriority or -math.huge)
    end)
    return candidates
end

function ZoneStyle.GetScoreSummary(source, definition, modeKey, context)
    local score, reasons = ZoneStyle.ScoreSource(source, definition, modeKey, context)
    local mode = ZoneStyle.GetModeInfo(modeKey)
    local reasonText = #reasons > 0 and table.concat(reasons, ", ") or "profile affinity"
    return string.format("%s score %.1f • %s", mode.label, score, reasonText)
end

function ZoneStyle.GetEligibilitySummary(source, modeKey, context)
    local eligible, kind, reason = ZoneStyle.GetSourceEligibility(source, modeKey, context)
    return eligible, kind, reason
end

P.eventFrame = CreateFrame("Frame")
P.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
P.eventFrame:RegisterEvent("PLAYER_MAP_CHANGED")
P.eventFrame:RegisterEvent("ZONE_CHANGED")
P.eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
P.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

P.refreshToken = 0
P.eventFrame:SetScript("OnEvent", function()
    P.refreshToken = P.refreshToken + 1
    local token = P.refreshToken
    local function Refresh()
        if token == P.refreshToken then ZoneStyle.RefreshZone(false, false) end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.35, Refresh) else Refresh() end
end)
