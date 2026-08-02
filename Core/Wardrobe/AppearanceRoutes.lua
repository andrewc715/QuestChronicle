local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.GetWeaponRouteCacheKey(topology, mainOutfitSlot, offOutfitSlot)
    local specID
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = P.SafeCall(GetSpecialization)
        specID = specIndex and P.SafeCall(GetSpecializationInfo, specIndex) or nil
    end
    return table.concat({
        tostring(topology.mainItem or "NONE"),
        tostring(topology.offItem or "NONE"),
        tostring(topology.mainEquipLoc or "NONE"),
        tostring(topology.offEquipLoc or "NONE"),
        tostring(mainOutfitSlot or "NONE"),
        tostring(offOutfitSlot or "NONE"),
        tostring(specID or "NONE"),
    }, "|")
end

function P.RouteHasCachedSubtype(route, targetKey)
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    for subtypeKey in pairs(permissions or {}) do
        if P.CountCachedWeaponSubtype(subtypeKey) > 0 then return true end
    end
    return false
end

function P.DecorateOptionCandidates(options, ownerSlot, borrowed)
    local result = {}
    for _, optionInfo in ipairs(options or {}) do
        table.insert(result, {
            weaponOption = optionInfo.weaponOption,
            name = optionInfo.name,
            enabled = optionInfo.enabled ~= false,
            sourceKind = borrowed and "PRIMARY_OPTION_PROBE" or optionInfo.sourceKind,
            isArtifact = optionInfo.isArtifact == true,
            isEquipped = optionInfo.isEquipped == true,
            optionOwnerSlot = ownerSlot,
            borrowedFromPrimary = borrowed == true,
        })
    end
    return result
end

function P.MergeSecondaryOptionCandidates(secondaryOptions, primaryOptions, secondarySlot, primarySlot)
    local merged = {}
    local seen = {}
    local function Add(optionInfo, ownerSlot, borrowed)
        if not optionInfo or optionInfo.weaponOption == nil then return end
        local key = tostring(optionInfo.weaponOption)
        if seen[key] then return end
        seen[key] = true
        table.insert(merged, {
            weaponOption = optionInfo.weaponOption,
            name = optionInfo.name,
            enabled = optionInfo.enabled ~= false,
            sourceKind = borrowed and "PRIMARY_OPTION_PROBE" or optionInfo.sourceKind,
            isArtifact = optionInfo.isArtifact == true,
            isEquipped = optionInfo.isEquipped == true,
            optionOwnerSlot = ownerSlot,
            borrowedFromPrimary = borrowed == true,
        })
    end
    for _, optionInfo in ipairs(secondaryOptions or {}) do Add(optionInfo, secondarySlot, false) end
    -- A physical secondary weapon hand may accept a primary-slot option even
    -- when Blizzard does not list that option independently for the secondary
    -- slot. Probe the same native option against the actual secondary slot while
    -- preserving the primary owner as provenance.
    for _, optionInfo in ipairs(primaryOptions or {}) do Add(optionInfo, primarySlot, true) end
    return merged
end

function P.BuildFamilyOptionParts(outfitSlot, options, allowedFamilies, model, targetLabel)
    local partsByFamily = { ONE_HAND = {}, TWO_HAND = {}, RANGED = {} }
    for _, optionInfo in ipairs(options or {}) do
        local queryResult = P.QueryWeaponOptionSubtypes(outfitSlot, optionInfo)
        local recognized = 0
        local accepted = 0
        for _, familyKey in ipairs(P.MAIN_ROUTE_FAMILIES) do
            local familyCount = queryResult.families[familyKey] or 0
            if familyCount > 0 then
                recognized = recognized + 1
                if allowedFamilies[familyKey] then
                    local subtypes = P.CopySubtypePermissionMap(queryResult.subtypes, familyKey, false)
                    if P.CountMapEntries(subtypes) > 0 then
                        table.insert(partsByFamily[familyKey], {
                            familyKey = familyKey,
                            outfitSlot = outfitSlot,
                            optionOwnerSlot = optionInfo.optionOwnerSlot or outfitSlot,
                            optionInfo = optionInfo,
                            subtypes = subtypes,
                            targetLabel = targetLabel,
                        })
                        accepted = accepted + 1
                    end
                else
                    table.insert(model.suppressedOptions, {
                        target = targetLabel,
                        outfitSlot = outfitSlot,
                        optionOwnerSlot = optionInfo.optionOwnerSlot or outfitSlot,
                        weaponOption = optionInfo.weaponOption,
                        weaponOptionName = optionInfo.name,
                        familyKey = familyKey,
                        reason = string.format(
                            "%s appearances are incompatible with the current physical topology (%s).",
                            Wardrobe.weaponFamilyDefinitions[familyKey].label,
                            tostring(model.topology.label)
                        ),
                    })
                end
            end
        end
        if recognized == 0 then
            table.insert(model.unsupportedOptions, {
                target = targetLabel,
                optionOwnerSlot = optionInfo.optionOwnerSlot or outfitSlot,
                weaponOption = optionInfo.weaponOption,
                weaponOptionName = optionInfo.name,
                sourceKind = optionInfo.sourceKind,
                reason = "The option exposes no recognized main-weapon appearance family.",
                families = queryResult.families,
            })
        elseif accepted == 0 then
            -- Every family exposed by this option was deliberately topology-
            -- gated. The individual suppressed records above carry the reason.
        end
    end
    return partsByFamily
end

function P.CreateSingleWeaponRoute(model, mainPart, familyKey)
    local optionInfo = mainPart.optionInfo
    local route = {
        id = P.MakeWeaponRouteID(mainPart.optionOwnerSlot, optionInfo, familyKey, "SINGLE"),
        familyKey = familyKey,
        routeKind = familyKey .. "_SINGLE",
        optionOwnerSlot = mainPart.optionOwnerSlot,
        primaryOptionOwnerSlot = mainPart.optionOwnerSlot,
        secondaryOptionOwnerSlot = nil,
        primarySlot = mainPart.outfitSlot,
        secondarySlot = nil,
        weaponOption = optionInfo.weaponOption,
        weaponOptionName = optionInfo.name,
        primaryWeaponOption = optionInfo.weaponOption,
        primaryWeaponOptionName = optionInfo.name,
        secondaryWeaponOption = nil,
        secondaryWeaponOptionName = nil,
        optionSourceKind = optionInfo.sourceKind,
        isArtifact = optionInfo.isArtifact == true,
        isEquippedOption = optionInfo.isEquipped == true,
        primarySubtypes = P.CopySubtypePermissionMap(mainPart.subtypes, familyKey, false),
        secondarySubtypes = {},
        targetsSecondary = false,
        permissionMethod = "PHYSICAL_TOPOLOGY_SINGLE_ROUTE",
        physicalWeaponPair = false,
    }
    route.available = P.RouteHasCachedSubtype(route, "PRIMARY")
    table.insert(model.routes, route)
    table.insert(model.routesByFamily[familyKey], route)
end

function P.CreatePairedWeaponRoute(model, mainPart, offPart, familyKey, inheritedSecondary)
    local mainOption = mainPart.optionInfo
    local offOption = offPart and offPart.optionInfo or mainOption
    local offOptionID = offOption and offOption.weaponOption or "INHERITED"
    local route = {
        id = P.MakeWeaponRouteID(
            mainPart.optionOwnerSlot,
            mainOption,
            familyKey,
            "PAIR:" .. tostring(offOptionID)
        ),
        familyKey = familyKey,
        routeKind = familyKey .. "_PAIR",
        optionOwnerSlot = mainPart.optionOwnerSlot,
        primaryOptionOwnerSlot = mainPart.optionOwnerSlot,
        secondaryOptionOwnerSlot = offPart and offPart.optionOwnerSlot or mainPart.optionOwnerSlot,
        primarySlot = mainPart.outfitSlot,
        secondarySlot = model.offOutfitSlot,
        weaponOption = mainOption.weaponOption,
        weaponOptionName = mainOption.name,
        primaryWeaponOption = mainOption.weaponOption,
        primaryWeaponOptionName = mainOption.name,
        secondaryWeaponOption = offOption and offOption.weaponOption or mainOption.weaponOption,
        secondaryWeaponOptionName = offOption and offOption.name or mainOption.name,
        optionSourceKind = mainOption.sourceKind,
        secondaryOptionSourceKind = offOption and offOption.sourceKind or mainOption.sourceKind,
        isArtifact = mainOption.isArtifact == true or (offOption and offOption.isArtifact == true),
        isEquippedOption = mainOption.isEquipped == true,
        primarySubtypes = P.CopySubtypePermissionMap(mainPart.subtypes, familyKey, false),
        secondarySubtypes = P.CopySubtypePermissionMap(
            offPart and offPart.subtypes or mainPart.subtypes,
            familyKey,
            inheritedSecondary == true
        ),
        targetsSecondary = true,
        permissionMethod = "PHYSICAL_WEAPON_PAIR_ROUTE",
        physicalWeaponPair = true,
        nativeLinkedPair = model.nativeLinkedPair == true,
        secondaryPermissionInherited = inheritedSecondary == true,
    }
    route.available = P.RouteHasCachedSubtype(route, "PRIMARY") and P.RouteHasCachedSubtype(route, "SECONDARY")
    table.insert(model.routes, route)
    table.insert(model.routesByFamily[familyKey], route)
end

function Wardrobe.GetWeaponAppearanceRoutes(forceRefresh)
    local topology = Wardrobe.GetWeaponTopology()
    local mainOutfitSlot = P.GetTransmogOutfitSlotForInventorySlotName("MAINHANDSLOT")
    local offOutfitSlot = P.GetTransmogOutfitSlotForInventorySlotName("SECONDARYHANDSLOT")
    local cacheKey = P.GetWeaponRouteCacheKey(topology, mainOutfitSlot, offOutfitSlot)
    local now = GetTime and GetTime() or 0
    if not forceRefresh and P.weaponRouteCache and P.weaponRouteCacheKey == cacheKey and now < P.weaponRouteCacheExpiresAt then
        return P.weaponRouteCache
    end

    local model = {
        topology = topology,
        mainOutfitSlot = mainOutfitSlot,
        offOutfitSlot = offOutfitSlot,
        routes = {},
        routesByFamily = { ONE_HAND = {}, TWO_HAND = {}, RANGED = {}, OFF_HAND = {} },
        companionRoutes = {},
        unsupportedOptions = {},
        suppressedOptions = {},
        linkedPair = false,
        physicalWeaponPair = false,
        nativeLinkedPair = false,
        linkedContext = nil,
    }

    local linkedContext = P.GetLinkedWeaponSlotContext(mainOutfitSlot)
    local nativeLinkedPair = topology.hasWeaponOffHand
        and linkedContext
        and linkedContext.isLinked == true
        and linkedContext.secondarySlot ~= nil
        and offOutfitSlot == linkedContext.secondarySlot
    local physicalWeaponPair = P.IsPhysicalMeleeWeaponPair(topology)
    model.nativeLinkedPair = nativeLinkedPair
    model.physicalWeaponPair = physicalWeaponPair
    -- Keep linkedPair as the generation-facing pair flag for compatibility with
    -- existing UI and route consumers. Native linkage is tracked separately.
    model.linkedPair = physicalWeaponPair
    model.linkedContext = linkedContext

    local allowedFamilies = P.GetTopologyMainFamilyGate(topology)
    model.allowedTopologyFamilies = allowedFamilies

    local rawMainOptions = P.GetWeaponOptionCandidatesForOutfitSlot(mainOutfitSlot)
    local mainOptions = P.DecorateOptionCandidates(rawMainOptions, mainOutfitSlot, false)
    local mainParts = P.BuildFamilyOptionParts(mainOutfitSlot, mainOptions, allowedFamilies, model, "MAIN")

    if physicalWeaponPair then
        local rawOffOptions = P.GetWeaponOptionCandidatesForOutfitSlot(offOutfitSlot)
        local offOptions = P.MergeSecondaryOptionCandidates(rawOffOptions, mainOptions, offOutfitSlot, mainOutfitSlot)
        local offParts = P.BuildFamilyOptionParts(offOutfitSlot, offOptions, allowedFamilies, model, "SECONDARY")

        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND" }) do
            local primaryParts = mainParts[familyKey] or {}
            local secondaryParts = offParts[familyKey] or {}
            for _, mainPart in ipairs(primaryParts) do
                local created = false
                -- Prefer the same native weapon option when both hands expose it,
                -- then retain other valid per-hand option combinations as separate
                -- provenance-bearing routes.
                for _, offPart in ipairs(secondaryParts) do
                    if offPart.optionInfo.weaponOption == mainPart.optionInfo.weaponOption then
                        P.CreatePairedWeaponRoute(model, mainPart, offPart, familyKey, false)
                        created = true
                    end
                end
                -- Only cross-pair different native options when the secondary
                -- hand does not accept the primary option. This preserves every
                -- valid route without multiplying equivalent combinations and
                -- biasing generation toward families with more option aliases.
                if not created then
                    for _, offPart in ipairs(secondaryParts) do
                        P.CreatePairedWeaponRoute(model, mainPart, offPart, familyKey, false)
                        created = true
                    end
                end
                -- Native linked secondary appearances can be represented solely
                -- through the primary slot. Inherit only the already classified
                -- family when the physical pair has no independent secondary rows.
                if not created and nativeLinkedPair and P.CountMapEntries(mainPart.subtypes) > 0 then
                    P.CreatePairedWeaponRoute(model, mainPart, nil, familyKey, true)
                end
            end
        end
    else
        for _, familyKey in ipairs(P.MAIN_ROUTE_FAMILIES) do
            for _, mainPart in ipairs(mainParts[familyKey] or {}) do
                P.CreateSingleWeaponRoute(model, mainPart, familyKey)
            end
        end
    end

    -- Shields and holdables are a true companion route only when the physical
    -- secondary slot is an independent shield/focus item. A second weapon hand
    -- remains part of ONE_HAND_PAIR or TWO_HAND_PAIR and never activates this.
    if topology.offHandKind == "OFF_HAND" and offOutfitSlot ~= nil then
        local rawOffOptions = P.GetWeaponOptionCandidatesForOutfitSlot(offOutfitSlot)
        local offOptions = P.DecorateOptionCandidates(rawOffOptions, offOutfitSlot, false)
        for _, optionInfo in ipairs(offOptions or {}) do
            local result = P.QueryWeaponOptionSubtypes(offOutfitSlot, optionInfo)
            local subtypes = P.CopySubtypePermissionMap(result.subtypes, "OFF_HAND", false)
            if P.CountMapEntries(subtypes) > 0 then
                local route = {
                    id = P.MakeWeaponRouteID(offOutfitSlot, optionInfo, "OFF_HAND", "COMPANION"),
                    familyKey = "OFF_HAND",
                    routeKind = "OFF_HAND_COMPANION",
                    optionOwnerSlot = offOutfitSlot,
                    primaryOptionOwnerSlot = nil,
                    secondaryOptionOwnerSlot = offOutfitSlot,
                    primarySlot = nil,
                    secondarySlot = offOutfitSlot,
                    weaponOption = optionInfo.weaponOption,
                    weaponOptionName = optionInfo.name,
                    primaryWeaponOption = nil,
                    primaryWeaponOptionName = nil,
                    secondaryWeaponOption = optionInfo.weaponOption,
                    secondaryWeaponOptionName = optionInfo.name,
                    optionSourceKind = optionInfo.sourceKind,
                    isArtifact = optionInfo.isArtifact == true,
                    isEquippedOption = optionInfo.isEquipped == true,
                    primarySubtypes = {},
                    secondarySubtypes = subtypes,
                    targetsSecondary = true,
                    permissionMethod = "INDEPENDENT_COMPANION_ROUTE",
                    physicalWeaponPair = false,
                }
                route.available = P.RouteHasCachedSubtype(route, "SECONDARY")
                table.insert(model.routes, route)
                table.insert(model.routesByFamily.OFF_HAND, route)
                table.insert(model.companionRoutes, route)
            end
        end
    end

    -- Conservative compatibility fallback for old clients without weapon-option
    -- data. It mirrors physical topology and never invents Ranged or companion
    -- permissions for a melee pair.
    if #model.routes == 0 and topology.mainItem then
        local physicalFamily = topology.mainHandKind
        if P.MAIN_ROUTE_FAMILY_SET[physicalFamily] and allowedFamilies[physicalFamily] then
            local primarySubtypes = {}
            local secondarySubtypes = {}
            for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(physicalFamily)) do
                local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
                local categoryID = P.ResolveWeaponSubtypeCategoryID(definition)
                if P.SafeCall(C_TransmogCollection and C_TransmogCollection.IsCategoryValidForItem, categoryID, topology.mainItem) == true then
                    primarySubtypes[subtypeKey] = { key = subtypeKey, familyKey = physicalFamily, categoryID = categoryID }
                end
                if physicalWeaponPair and P.SafeCall(C_TransmogCollection and C_TransmogCollection.IsCategoryValidForItem, categoryID, topology.offItem) == true then
                    secondarySubtypes[subtypeKey] = { key = subtypeKey, familyKey = physicalFamily, categoryID = categoryID }
                end
            end
            if P.CountMapEntries(primarySubtypes) > 0
                and (not physicalWeaponPair or P.CountMapEntries(secondarySubtypes) > 0)
            then
                local route = {
                    id = "FALLBACK:" .. physicalFamily .. (physicalWeaponPair and ":PAIR" or ":SINGLE"),
                    familyKey = physicalFamily,
                    routeKind = physicalFamily .. (physicalWeaponPair and "_FALLBACK_PAIR" or "_FALLBACK"),
                    optionOwnerSlot = mainOutfitSlot,
                    primaryOptionOwnerSlot = mainOutfitSlot,
                    secondaryOptionOwnerSlot = physicalWeaponPair and offOutfitSlot or nil,
                    primarySlot = mainOutfitSlot,
                    secondarySlot = physicalWeaponPair and offOutfitSlot or nil,
                    weaponOption = nil,
                    weaponOptionName = "Legacy item-category fallback",
                    primaryWeaponOption = nil,
                    primaryWeaponOptionName = "Legacy item-category fallback",
                    secondaryWeaponOption = nil,
                    secondaryWeaponOptionName = physicalWeaponPair and "Legacy item-category fallback" or nil,
                    primarySubtypes = primarySubtypes,
                    secondarySubtypes = physicalWeaponPair and secondarySubtypes or {},
                    targetsSecondary = physicalWeaponPair,
                    permissionMethod = "ITEM_CATEGORY_FALLBACK_ROUTE",
                    physicalWeaponPair = physicalWeaponPair,
                    available = true,
                }
                table.insert(model.routes, route)
                table.insert(model.routesByFamily[physicalFamily], route)
            end
        end
    end

    P.weaponRouteCache = model
    P.weaponRouteCacheKey = cacheKey
    P.weaponRouteCacheExpiresAt = now + 0.20
    return model
end

function P.FindRouteCategoryPermission(route, targetKey, categoryID)
    if not route or not categoryID then return false, nil end
    local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(categoryID)
    if not subtypeKey then return false, nil end
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    local permission = permissions and permissions[subtypeKey]
    if not permission then return false, nil end
    local secondary = targetKey == "SECONDARY"
    return true, {
        method = route.permissionMethod,
        routeID = route.id,
        routeKind = route.routeKind,
        routeFamily = route.familyKey,
        weaponOption = secondary and (route.secondaryWeaponOption or route.weaponOption) or (route.primaryWeaponOption or route.weaponOption),
        weaponOptionName = secondary and (route.secondaryWeaponOptionName or route.weaponOptionName) or (route.primaryWeaponOptionName or route.weaponOptionName),
        optionOwnerSlot = secondary and (route.secondaryOptionOwnerSlot or route.optionOwnerSlot) or (route.primaryOptionOwnerSlot or route.optionOwnerSlot),
        outfitSlot = secondary and route.secondarySlot or route.primarySlot,
        permissionSlot = secondary and route.secondarySlot or route.primarySlot,
        linkedPrimarySlot = route.primarySlot,
        linkedSecondarySlot = route.secondarySlot,
        linkedSecondary = secondary and route.targetsSecondary == true,
        inheritedFromPrimary = permission.inheritedFromPrimary == true,
    }
end

function P.IsWeaponCategoryPermitted(slotName, categoryID, itemInfo, requiredRoute)
    local targetKey = slotName == "SECONDARYHANDSLOT" and "SECONDARY" or "PRIMARY"
    if requiredRoute then
        return P.FindRouteCategoryPermission(requiredRoute, targetKey, categoryID)
    end

    local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(categoryID)
    local subtype = subtypeKey and Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not subtype then return false, { method = "UNKNOWN_CATEGORY" } end
    local model = Wardrobe.GetWeaponAppearanceRoutes()
    for _, route in ipairs(model.routesByFamily[subtype.familyKey] or {}) do
        local allowed, details = P.FindRouteCategoryPermission(route, targetKey, categoryID)
        if allowed then return true, details end
    end
    return false, {
        method = "NO_PROVENANCE_ROUTE",
        routeFamily = subtype.familyKey,
        target = targetKey,
    }
end

function P.CreateEmptyWeaponHandCapability(handKey, itemInfo, slotName)
    local capability = {
        handKey = handKey,
        itemInfo = itemInfo,
        slotName = slotName,
        physicalSubtype = P.GetEquippedWeaponSubtype(itemInfo),
        subtypes = {},
        families = {},
    }
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        capability.families[familyKey] = { available = false, count = 0, routes = {} }
    end
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        capability.subtypes[subtypeKey] = {
            key = subtypeKey,
            familyKey = definition.familyKey,
            label = definition.label,
            shortLabel = definition.shortLabel,
            categoryID = P.ResolveWeaponSubtypeCategoryID(definition),
            count = P.CountCachedWeaponSubtype(subtypeKey),
            blizzardAllowed = false,
            available = false,
            routes = {},
            reason = "No Blizzard weapon appearance route permits this type for the hand.",
        }
    end
    return capability
end
