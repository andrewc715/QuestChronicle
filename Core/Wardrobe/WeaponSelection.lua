local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function YieldWeapon(phaseKey)
    if P.MaybeYieldWeaponGeneration then P.MaybeYieldWeaponGeneration(phaseKey) end
end
function P.ValidateGeneratedWeaponSource(source, slotKey, equippedItem, context)
    local definition = P.slotByKey[slotKey]
    local route = context and context.activeRoute
    local routeKey = route and route.id or "NO_ROUTE"
    local cacheKey = table.concat({ tostring(slotKey), tostring(source and source.sourceID), tostring(equippedItem), tostring(routeKey) }, ":")
    local cached = context.validation[cacheKey] or (P.weaponValidationSessionCache and P.weaponValidationSessionCache[cacheKey])
    if cached then
        return cached.valid, cached.reason
    end

    local function Finish(valid, reason)
        context.validation[cacheKey] = { valid = valid, reason = reason }
        P.weaponValidationSessionCache = P.weaponValidationSessionCache or {}
        P.weaponValidationSessionCache[cacheKey] = context.validation[cacheKey]
        return valid, reason
    end

    local basicValid, basicReason = Wardrobe.ValidateSource(source, slotKey)
    YieldWeapon("weaponValidation")
    if not basicValid then
        return Finish(false, basicReason)
    end
    if not source.categoryID then
        return Finish(false, "This cached weapon appearance has no collection category. Rescan the collection.")
    end
    local permitted = true
    local permissionDetails
    if equippedItem then
        permitted, permissionDetails = P.IsWeaponCategoryPermitted(
            definition and definition.slotName,
            source.categoryID,
            equippedItem,
            context and context.activeRoute or nil
        )
        YieldWeapon("weaponPermission")
        if permitted == nil then
            return Finish(false, "WoW's slot weapon-option compatibility check is unavailable.")
        end
        if permitted ~= true then
            return Finish(false, "That appearance category is not permitted for the equipped weapon slot and option.")
        end
    end

    -- Requery the collapsed visual with the equipped hand's transmog location.
    -- For ordinary weapon rules, the collection row's isUsable flag is useful.
    -- For Midnight slot-option exceptions (notably Fury using one-hand visuals
    -- over equipped two-handers), Blizzard's native slot-and-option permission
    -- is the authoritative answer. The older appearance usability flags can
    -- remain false even while the native Transmog UI permits the category.
    local appearance = P.GetGenerationAppearance(source, definition, context)
    YieldWeapon("weaponAppearance")
    local nativeSlotRule = permissionDetails and (
        permissionDetails.method == "PROVENANCE_ROUTE"
        or permissionDetails.method == "PHYSICAL_TOPOLOGY_SINGLE_ROUTE"
        or permissionDetails.method == "PHYSICAL_WEAPON_PAIR_ROUTE"
        or permissionDetails.method == "INDEPENDENT_COMPANION_ROUTE"
        or permissionDetails.method == "ITEM_CATEGORY_FALLBACK_ROUTE"
    )

    if appearance and appearance.isCollected == false then
        return Finish(false, "WoW no longer reports this weapon visual as collected.")
    end
    if not appearance and not nativeSlotRule then
        return Finish(false, "WoW no longer reports this weapon visual for the equipped hand.")
    end
    if appearance and appearance.canDisplayOnPlayer == false then
        return Finish(false, "This character cannot display that weapon visual.")
    end
    if not nativeSlotRule and appearance and appearance.isUsable ~= true then
        return Finish(false, "WoW does not currently mark that weapon visual as usable.")
    end

    -- Source detail remains a collection/display guard. Under a native
    -- slot-option exception, do not let legacy appearanceIsUsable or
    -- isAnySourceValidForPlayer fields overrule the exact API Blizzard uses to
    -- populate its own weapon-category picker.
    local appearanceInfo = P.GetCachedWeaponSourceInfo and P.GetCachedWeaponSourceInfo(source.sourceID) or nil
    if not appearanceInfo then
        appearanceInfo = P.SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, source.sourceID)
        if P.StoreWeaponSourceInfo then P.StoreWeaponSourceInfo(source.sourceID, appearanceInfo) end
    end
    YieldWeapon("weaponSourceInfo")
    if appearanceInfo then
        if appearanceInfo.appearanceIsCollected == false then
            return Finish(false, "The weapon appearance is no longer collected.")
        end
        if appearanceInfo.canDisplayOnPlayer == false then
            return Finish(false, "This character cannot display that weapon visual.")
        end
        if not nativeSlotRule then
            if appearanceInfo.appearanceIsCollected ~= true or appearanceInfo.appearanceIsUsable ~= true then
                return Finish(false, "The collected appearance is not currently usable for transmogrification.")
            end
            if appearanceInfo.canDisplayOnPlayer ~= true or appearanceInfo.isAnySourceValidForPlayer ~= true then
                return Finish(false, "No source for this visual is valid for the current character.")
            end
        end
    elseif not nativeSlotRule and type(C_TransmogCollection.GetValidAppearanceSourcesForClass) == "function" then
        local classID = P.GetCurrentClassID()
        local location = P.GetGenerationLocation(definition, context)
        local validSources = classID and P.SafeCall(
            C_TransmogCollection.GetValidAppearanceSourcesForClass,
            source.visualID,
            classID,
            source.categoryID,
            location
        )
        if type(validSources) ~= "table" or #validSources == 0 then
            return Finish(false, "WoW found no valid source for this character and weapon visual.")
        end
    end

    return Finish(true, nativeSlotRule
        and (permissionDetails.linkedSecondary
            and "Compatible with the selected linked weapon appearance route"
            or "Compatible with the selected Blizzard weapon appearance route")
        or "Compatible with the equipped item")
end

function P.Shuffle(values)
    for index = #values, 2, -1 do
        local other = math.random(1, index)
        values[index], values[other] = values[other], values[index]
    end
end

function P.GetEnabledSubtypeKeys(state, familyKeys, handCapability, preferredSubtypeKey)
    local keys = {}
    local seen = {}
    if preferredSubtypeKey then
        local preferred = Wardrobe.weaponSubtypeDefinitions[preferredSubtypeKey]
        if preferred and handCapability.subtypes[preferredSubtypeKey] and handCapability.subtypes[preferredSubtypeKey].available
            and state.weaponSubtypes[preferredSubtypeKey] and state.weaponFamilies[preferred.familyKey]
        then
            table.insert(keys, preferredSubtypeKey)
            seen[preferredSubtypeKey] = true
        end
    end
    for _, familyKey in ipairs(familyKeys or {}) do
        if state.weaponFamilies[familyKey] then
            for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
                local capability = handCapability.subtypes[subtypeKey]
                if not seen[subtypeKey] and state.weaponSubtypes[subtypeKey] and capability and capability.available then
                    table.insert(keys, subtypeKey)
                    seen[subtypeKey] = true
                end
            end
        end
    end
    if #keys > 1 then
        local first = preferredSubtypeKey and keys[1] or nil
        local tail = {}
        for index = first and 2 or 1, #keys do table.insert(tail, keys[index]) end
        P.Shuffle(tail)
        keys = {}
        if first then table.insert(keys, first) end
        for _, value in ipairs(tail) do table.insert(keys, value) end
    end
    return keys
end

function P.ChooseGeneratedWeaponSource(familyKeys, equippedItem, context, excludedBySlot, targetSlotKey, styleMode, styleContext, handCapability, preferredSubtypeKey, requirePreferred)
    local state = P.EnsurePreviewState()
    handCapability = handCapability or context.capabilities.main
    local subtypeKeys = P.GetEnabledSubtypeKeys(state, familyKeys, handCapability, preferredSubtypeKey)
    if requirePreferred and preferredSubtypeKey then subtypeKeys = subtypeKeys[1] == preferredSubtypeKey and { preferredSubtypeKey } or {} end

    local fallback
    for _, subtypeKey in ipairs(subtypeKeys) do
        local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        local categoryID = P.ResolveWeaponSubtypeCategoryID(subtype)
        local candidates = {}
        local indexedSources = P.GetIndexedWeaponSources and P.GetIndexedWeaponSources(subtypeKey)
            or Wardrobe.GetSlotSources(subtype.familyKey)
        for _, source in ipairs(indexedSources) do
            if tonumber(source.categoryID) == tonumber(categoryID) then
                local validationSlotKey = targetSlotKey or subtype.familyKey
                local candidateSource = P.CopySourceForSlot(source, validationSlotKey)
                local basicValid = Wardrobe.ValidateSource(candidateSource, validationSlotKey)
                if basicValid then table.insert(candidates, { source = candidateSource, slotKey = validationSlotKey, familyKey = subtype.familyKey, subtypeKey = subtypeKey }) end
                YieldWeapon("weaponCandidateBuild")
            end
        end
        if QC.ZoneStyle and QC.ZoneStyle.OrderWeaponCandidates then
            QC.ZoneStyle.OrderWeaponCandidates(candidates, styleMode, styleContext)
        else
            P.Shuffle(candidates)
        end
        for _, candidate in ipairs(candidates) do
            local valid = P.ValidateGeneratedWeaponSource(candidate.source, candidate.slotKey, equippedItem, context)
            YieldWeapon("weaponCandidateValidate")
            if valid then
                local excludedID = excludedBySlot and (excludedBySlot[candidate.slotKey] or excludedBySlot[candidate.familyKey])
                if excludedID == candidate.source.sourceID then
                    fallback = fallback or candidate
                else
                    return candidate.source, candidate.familyKey, candidate.subtypeKey
                end
            end
        end
    end
    if fallback then return fallback.source, fallback.familyKey, fallback.subtypeKey end
    return nil
end

function P.ChooseLinkedWeaponSource(primarySource, equippedItem, context, excludedBySlot, targetSlotKey, styleMode, styleContext, handCapability)
    if not primarySource then return nil, nil, "No primary weapon appearance is selected." end

    local state = P.EnsurePreviewState()
    local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(primarySource.categoryID)
    local subtype = subtypeKey and Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    local capability = subtypeKey and handCapability and handCapability.subtypes[subtypeKey]
    if not subtype or not capability or not capability.available or not state.weaponSubtypes[subtypeKey] then
        return nil, nil, "The linked weapon type is not permitted for the second hand."
    end

    -- Strongest link: use the exact same collapsed visual in the second hand.
    -- Prefer the slot-specific cached representative, then try the selected
    -- source itself copied to the target hand. Blizzard validates the result.
    local exactCandidates = {}
    local seen = {}
    local byVisual = P.FindSourceByVisualID(targetSlotKey, primarySource.visualID)
    if byVisual then
        table.insert(exactCandidates, byVisual)
        seen[byVisual.sourceID] = true
    end
    local copied = P.CopySourceForSlot(primarySource, targetSlotKey)
    if copied and not seen[copied.sourceID] then
        table.insert(exactCandidates, copied)
    end

    for _, candidate in ipairs(exactCandidates) do
        local valid = P.ValidateGeneratedWeaponSource(candidate, targetSlotKey, equippedItem, context)
        YieldWeapon("weaponLinkedValidate")
        if valid then
            return candidate, "EXACT_VISUAL", nil
        end
    end

    -- Secondary link: stay inside the exact same Blizzard weapon subtype.
    -- Never fall through to an unrelated family or type while linking is on.
    local source = P.ChooseGeneratedWeaponSource(
        { subtype.familyKey },
        equippedItem,
        context,
        excludedBySlot,
        targetSlotKey,
        styleMode,
        styleContext,
        handCapability,
        subtypeKey,
        true
    )
    if source then
        return source, "SAME_SUBTYPE", "The exact visual was unavailable for the second hand, so Quest Chronicle matched the same weapon type instead."
    end

    return nil, nil, "No valid second-hand appearance matched the linked visual or weapon type."
end

P.BuildRouteHandCapability = nil
function P.FindPrimaryRoutesForSource(source, capabilities, requireSameSubtype)
    local routes = {}
    if not source then return routes end
    local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(source.categoryID)
    local definition = subtypeKey and Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not definition then return routes end
    for _, route in ipairs(capabilities.routesByFamily[definition.familyKey] or {}) do
        YieldWeapon("weaponRouteFilter")
        local secondaryCompatible = route.targetsSecondary
            and (requireSameSubtype ~= true or route.secondarySubtypes[subtypeKey] ~= nil)
        if route.primarySubtypes[subtypeKey] and secondaryCompatible then
            table.insert(routes, route)
        end
    end
    return routes, subtypeKey
end

function P.SynchronizeLinkedOffHand(state, primarySource, styleMode, styleContext, excludedSourceID)
    if state.linkWeaponHands == false or not primarySource then return nil, nil end
    local styleEngine = QC.ZoneStyle
    if styleEngine and not styleContext then
        styleMode = styleEngine.NormalizeMode and styleEngine.NormalizeMode(styleMode or state.styleMode) or (styleMode or state.styleMode)
        local baseContext = styleEngine.GetCurrentContext and styleEngine.GetCurrentContext() or nil
        styleContext = P.CreateStyleGenerationContext(state, styleEngine, baseContext, nil, false)
    end
    local context = P.CreateWeaponGenerationContext()
    local topology = context.topology
    if not topology.offItem or topology.offHandKind == "OFF_HAND" then return nil, nil end

    local routes = P.FindPrimaryRoutesForSource(primarySource, context.capabilities, true)
    if #routes == 0 then
        P.SetSelectedSource(state, "OFF_HAND", nil)
        return nil, "The selected main-hand appearance has no complete linked weapon route."
    end
    P.Shuffle(routes)
    local excluded = excludedSourceID and { OFF_HAND = excludedSourceID } or nil
    for _, route in ipairs(routes) do
        context.activeRoute = route
        local routeCapability = P.BuildRouteHandCapability(route, "SECONDARY", context.capabilities.off)
        local source, linkKind, notice = P.ChooseLinkedWeaponSource(
            primarySource,
            context.offItem,
            context,
            excluded,
            "OFF_HAND",
            styleMode,
            styleContext,
            routeCapability
        )
        if source then
            P.SetSelectedSource(state, "OFF_HAND", source)
            state.lastWeaponRoute = {
                routeID = route.id,
                routeKind = route.routeKind,
                familyKey = route.familyKey,
                weaponOption = route.weaponOption,
                weaponOptionName = route.weaponOptionName,
                primaryWeaponOption = route.primaryWeaponOption or route.weaponOption,
                primaryWeaponOptionName = route.primaryWeaponOptionName or route.weaponOptionName,
                secondaryWeaponOption = route.secondaryWeaponOption,
                secondaryWeaponOptionName = route.secondaryWeaponOptionName,
                mainSubtype = P.GetWeaponSubtypeKeyForCategoryID(primarySource.categoryID),
                mainSourceID = primarySource.sourceID,
                offSourceID = source.sourceID,
                linked = true,
                committedAt = time and time() or 0,
            }
            return linkKind, notice
        end
    end

    P.SetSelectedSource(state, "OFF_HAND", nil)
    return nil, "No complete linked weapon route could populate the secondary hand."
end

function P.GetLockedWeaponMode(state)
    local lockedMode
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if state.locks[slotKey] and state.selections[slotKey] then
            if lockedMode then
                return nil, "Unlock one of the conflicting main-hand weapon slots first."
            end
            lockedMode = slotKey
        end
    end
    return lockedMode
end

P.BuildRouteHandCapability = function(route, targetKey, baseCapability)
    local result = {
        handKey = targetKey,
        itemInfo = baseCapability and baseCapability.itemInfo or nil,
        slotName = targetKey == "SECONDARY" and "SECONDARYHANDSLOT" or "MAINHANDSLOT",
        physicalSubtype = baseCapability and baseCapability.physicalSubtype or nil,
        subtypes = {},
        families = {},
    }
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        result.families[familyKey] = { available = false, count = 0 }
    end
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local base = baseCapability and baseCapability.subtypes and baseCapability.subtypes[subtypeKey]
        local permission = permissions and permissions[subtypeKey]
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        local available = permission ~= nil and base and base.count > 0
        result.subtypes[subtypeKey] = {
            key = subtypeKey,
            familyKey = definition.familyKey,
            label = definition.label,
            shortLabel = definition.shortLabel,
            categoryID = P.ResolveWeaponSubtypeCategoryID(definition),
            count = base and base.count or P.CountCachedWeaponSubtype(subtypeKey),
            blizzardAllowed = permission ~= nil,
            available = available == true,
            routeID = route.id,
            routeKind = route.routeKind,
            weaponOption = targetKey == "SECONDARY" and (route.secondaryWeaponOption or route.weaponOption) or (route.primaryWeaponOption or route.weaponOption),
            weaponOptionName = targetKey == "SECONDARY" and (route.secondaryWeaponOptionName or route.weaponOptionName) or (route.primaryWeaponOptionName or route.weaponOptionName),
            reason = permission and ("Available through " .. tostring(targetKey == "SECONDARY" and (route.secondaryWeaponOptionName or route.weaponOptionName or route.routeKind) or (route.primaryWeaponOptionName or route.weaponOptionName or route.routeKind)))
                or "This type is outside the selected weapon route.",
        }
        if available then
            local family = result.families[definition.familyKey]
            family.available = true
            family.count = family.count + result.subtypes[subtypeKey].count
        end
    end
    return result
end

function P.RouteHasEnabledSubtype(state, route, targetKey, requiredSubtype)
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    if requiredSubtype then
        return permissions and permissions[requiredSubtype] ~= nil and state.weaponSubtypes[requiredSubtype] == true
    end
    for subtypeKey in pairs(permissions or {}) do
        if state.weaponSubtypes[subtypeKey] == true and P.CountCachedWeaponSubtype(subtypeKey) > 0 then return true end
    end
    return false
end

function P.GetEnabledMainRoutes(state, capabilities, lockedMode, lockedSubtype)
    local routes = {}
    for _, route in ipairs(capabilities.routes.routes or {}) do
        YieldWeapon("weaponRouteFilter")
        if route.familyKey ~= "OFF_HAND"
            and route.available == true
            and state.weaponFamilies[route.familyKey] == true
            and (not lockedMode or route.familyKey == lockedMode)
            and P.RouteHasEnabledSubtype(state, route, "PRIMARY", lockedSubtype)
        then
            local secondaryOK = true
            if route.targetsSecondary then
                if state.linkWeaponHands and lockedSubtype then
                    secondaryOK = P.RouteHasEnabledSubtype(state, route, "SECONDARY", lockedSubtype)
                elseif state.linkWeaponHands then
                    secondaryOK = false
                    for subtypeKey in pairs(route.primarySubtypes or {}) do
                        if state.weaponSubtypes[subtypeKey] == true
                            and route.secondarySubtypes[subtypeKey]
                            and P.CountCachedWeaponSubtype(subtypeKey) > 0
                        then
                            secondaryOK = true
                            break
                        end
                    end
                else
                    secondaryOK = P.RouteHasEnabledSubtype(state, route, "SECONDARY")
                end
            end
            if secondaryOK then table.insert(routes, route) end
        end
    end
    return routes
end

function P.GetEnabledCompanionRoutes(state, capabilities)
    local routes = {}
    if state.weaponFamilies.OFF_HAND ~= true then return routes end
    for _, route in ipairs(capabilities.companionRoutes or {}) do
        YieldWeapon("weaponRouteFilter")
        if route.available and P.RouteHasEnabledSubtype(state, route, "SECONDARY") then table.insert(routes, route) end
    end
    return routes
end

function P.ChooseRoute(routes)
    if not routes or #routes == 0 then return nil end
    local choices = {}
    for _, route in ipairs(routes) do table.insert(choices, route) end
    P.Shuffle(choices)
    return choices[1]
end

function P.ValidateLockedSourceForRoute(source, route, targetKey, equippedItem, context)
    if not source then return false, "The locked weapon source is missing from the cache." end
    local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(source.categoryID)
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    if not subtypeKey or not permissions[subtypeKey] then
        return false, "The locked weapon type is outside the selected Blizzard appearance route."
    end
    if not P.EnsurePreviewState().weaponSubtypes[subtypeKey] then
        return false, "The locked weapon type is excluded by the current subtype filters."
    end
    context.activeRoute = route
    local slotKey = targetKey == "SECONDARY" and "OFF_HAND" or route.familyKey
    local valid, reason = P.ValidateGeneratedWeaponSource(source, slotKey, equippedItem, context)
    return valid, reason, subtypeKey
end
