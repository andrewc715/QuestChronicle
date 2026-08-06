local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.AddRouteToHandCapability(capability, route, targetKey)
    local permissions = targetKey == "SECONDARY" and route.secondarySubtypes or route.primarySubtypes
    for subtypeKey, permission in pairs(permissions or {}) do
        local subtype = capability.subtypes[subtypeKey]
        if subtype then
            subtype.blizzardAllowed = true
            subtype.available = subtype.count > 0
            subtype.routeID = subtype.routeID or route.id
            subtype.routeKind = subtype.routeKind or route.routeKind
            local secondary = targetKey == "SECONDARY"
            subtype.weaponOption = subtype.weaponOption or (secondary and (route.secondaryWeaponOption or route.weaponOption) or (route.primaryWeaponOption or route.weaponOption))
            subtype.weaponOptionName = subtype.weaponOptionName or (secondary and (route.secondaryWeaponOptionName or route.weaponOptionName) or (route.primaryWeaponOptionName or route.weaponOptionName))
            subtype.optionOwnerSlot = subtype.optionOwnerSlot or (secondary and (route.secondaryOptionOwnerSlot or route.optionOwnerSlot) or (route.primaryOptionOwnerSlot or route.optionOwnerSlot))
            subtype.outfitSlot = subtype.outfitSlot or (targetKey == "SECONDARY" and route.secondarySlot or route.primarySlot)
            subtype.permissionSlot = subtype.outfitSlot
            subtype.permissionMethod = route.permissionMethod
            subtype.inheritedFromPrimary = permission.inheritedFromPrimary == true
            table.insert(subtype.routes, route)
            subtype.reason = subtype.available
                and (permission.inheritedFromPrimary
                    and ("Blizzard permits this through the linked primary route " .. tostring(route.weaponOptionName or route.id) .. ".")
                    or ("Blizzard permits this through the " .. tostring(route.weaponOptionName or route.routeKind) .. " route."))
                or "The route is valid, but no collected previewable appearances are cached for this type."

            local family = capability.families[subtype.familyKey]
            if family then
                family.available = family.available or subtype.available
                if subtype.available then family.count = family.count + subtype.count end
                table.insert(family.routes, route)
            end
        end
    end
end

function Wardrobe.GetWeaponRuleDiagnostics()
    local routeModel = Wardrobe.GetWeaponAppearanceRoutes(true)
    local topology = routeModel.topology
    local state = P.EnsurePreviewState()
    local routeLines = {}
    for _, route in ipairs(routeModel.routes) do
        table.insert(routeLines, string.format(
            "%s [%s] MH option=%s OH option=%s primary=%d secondary=%d available=%s",
            tostring(route.id),
            tostring(route.routeKind),
            tostring(route.primaryWeaponOptionName or route.weaponOptionName or route.primaryWeaponOption or route.weaponOption),
            tostring(route.secondaryWeaponOptionName or route.secondaryWeaponOption or "none"),
            P.CountMapEntries(route.primarySubtypes),
            P.CountMapEntries(route.secondarySubtypes),
            tostring(route.available == true)
        ))
    end
    for _, suppressed in ipairs(routeModel.suppressedOptions or {}) do
        table.insert(routeLines, string.format(
            "SUPPRESSED %s target=%s option=%s reason=%s",
            tostring(suppressed.familyKey),
            tostring(suppressed.target),
            tostring(suppressed.weaponOptionName or suppressed.weaponOption),
            tostring(suppressed.reason)
        ))
    end
    for _, unsupported in ipairs(routeModel.unsupportedOptions) do
        table.insert(routeLines, string.format(
            "UNSUPPORTED target=%s option=%s reason=%s",
            tostring(unsupported.target),
            tostring(unsupported.weaponOptionName or unsupported.weaponOption),
            tostring(unsupported.reason)
        ))
    end
    return {
        topology = topology.label,
        mainInventorySlotID = P.SafeCall(GetInventorySlotInfo, "MAINHANDSLOT"),
        offInventorySlotID = P.SafeCall(GetInventorySlotInfo, "SECONDARYHANDSLOT"),
        mainOutfitSlot = routeModel.mainOutfitSlot,
        offOutfitSlot = routeModel.offOutfitSlot,
        linkedPair = routeModel.linkedPair,
        physicalWeaponPair = routeModel.physicalWeaponPair,
        nativeLinkedPair = routeModel.nativeLinkedPair,
        routeLines = routeLines,
        lastRouteID = state.lastWeaponRoute and state.lastWeaponRoute.routeID or nil,
        lastRouteKind = state.lastWeaponRoute and state.lastWeaponRoute.routeKind or nil,
        mainSelection = state.selections and (state.selections.ONE_HAND or state.selections.TWO_HAND or state.selections.RANGED) or nil,
        offSelection = state.selections and state.selections.OFF_HAND or nil,
        linked = state.linkWeaponHands ~= false,
    }
end

function Wardrobe.PrintWeaponRuleDiagnostics()
    local d = Wardrobe.GetWeaponRuleDiagnostics()
    local printLine = QC.Print or print
    printLine("Weapon appearance route diagnostics:")
    printLine(string.format("Topology: %s", tostring(d.topology)))
    printLine(string.format("Inventory slots: MH %s | OH %s", tostring(d.mainInventorySlotID), tostring(d.offInventorySlotID)))
    printLine(string.format("Outfit slots: MH %s | OH %s | physical pair %s | native linked pair %s", tostring(d.mainOutfitSlot), tostring(d.offOutfitSlot), tostring(d.physicalWeaponPair), tostring(d.nativeLinkedPair)))
    for _, line in ipairs(d.routeLines or {}) do printLine(line) end
    printLine(string.format("Last route: %s [%s]", tostring(d.lastRouteID), tostring(d.lastRouteKind)))
    printLine(string.format("Selections: MH %s | OH %s | linked %s", tostring(d.mainSelection), tostring(d.offSelection), tostring(d.linked)))
    return d
end

function Wardrobe.GetWeaponAppearanceCapabilities()
    local routeModel = Wardrobe.GetWeaponAppearanceRoutes()
    local topology = routeModel.topology
    local main = P.CreateEmptyWeaponHandCapability("MAIN", topology.mainItem, "MAINHANDSLOT")
    local off = P.CreateEmptyWeaponHandCapability("OFF", topology.offItem, "SECONDARYHANDSLOT")

    for _, route in ipairs(routeModel.routes) do
        if route.familyKey == "OFF_HAND" then
            P.AddRouteToHandCapability(off, route, "SECONDARY")
        else
            P.AddRouteToHandCapability(main, route, "PRIMARY")
            if route.targetsSecondary then P.AddRouteToHandCapability(off, route, "SECONDARY") end
        end
    end

    local capabilities = {
        topology = topology,
        main = main,
        off = off,
        routes = routeModel,
        routesByFamily = routeModel.routesByFamily,
        companionRoutes = routeModel.companionRoutes,
        availableFamilies = {},
        reasons = {},
    }
    for _, familyKey in ipairs(P.MAIN_ROUTE_FAMILIES) do
        local available = main.families[familyKey] and main.families[familyKey].available == true
        capabilities.availableFamilies[familyKey] = available
        capabilities.reasons[familyKey] = available
            and ("A complete Blizzard " .. Wardrobe.weaponFamilyDefinitions[familyKey].label .. " route is available for this layout.")
            or ("No complete Blizzard " .. Wardrobe.weaponFamilyDefinitions[familyKey].label .. " route is available for this layout.")
    end

    local offAvailable = #routeModel.companionRoutes > 0 and off.families.OFF_HAND.available == true
    capabilities.availableFamilies.OFF_HAND = offAvailable
    if routeModel.physicalWeaponPair then
        capabilities.reasons.OFF_HAND = "The secondary slot is a physical weapon hand. Shields and holdables require an independent companion slot."
    else
        capabilities.reasons.OFF_HAND = offAvailable
            and "Blizzard exposes an independent shield or holdable companion route."
            or "No independent shield or holdable companion route is available."
    end
    return capabilities
end

function P.NormalizeWeaponFamilyChoices(state, capabilities)
    capabilities = capabilities or Wardrobe.GetWeaponAppearanceCapabilities()
    state.weaponFamilies = state.weaponFamilies or {}
    state.weaponSubtypes = state.weaponSubtypes or {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if state.weaponFamilies[familyKey] == nil then state.weaponFamilies[familyKey] = true end
    end
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        if state.weaponSubtypes[subtypeKey] == nil then state.weaponSubtypes[subtypeKey] = true end
    end
    if capabilities.availableFamilies.OFF_HAND and state.weaponFamilies.OFF_HAND and not state.weaponFamilies.ONE_HAND then
        state.weaponFamilies.ONE_HAND = true
    end
    local anyMain = false
    for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
        if capabilities.availableFamilies[familyKey] and state.weaponFamilies[familyKey] then anyMain = true break end
    end
    if not anyMain then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            if capabilities.availableFamilies[familyKey] then
                state.weaponFamilies[familyKey] = true
                break
            end
        end
    end
    return capabilities
end

function Wardrobe.GetWeaponGenerationOptions()
    local state = P.EnsurePreviewState()
    local capabilities = P.NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    local options = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        local available = capabilities.availableFamilies[familyKey] == true
        table.insert(options, {
            key = familyKey,
            label = Wardrobe.weaponFamilyDefinitions[familyKey].label,
            available = available,
            checked = available and state.weaponFamilies[familyKey] == true,
            reason = capabilities.reasons[familyKey],
        })
    end
    return options, capabilities.topology, capabilities
end

function Wardrobe.GetWeaponSubtypeOptions(familyKey)
    local state = P.EnsurePreviewState()
    local capabilities = P.NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
    local options = {}
    for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
        local capability = hand.subtypes[subtypeKey]
        table.insert(options, {
            key = subtypeKey,
            familyKey = familyKey,
            label = Wardrobe.weaponSubtypeDefinitions[subtypeKey].label,
            shortLabel = Wardrobe.weaponSubtypeDefinitions[subtypeKey].shortLabel,
            count = capability and capability.count or 0,
            available = capability and capability.available == true,
            checked = capability and capability.available == true and state.weaponSubtypes[subtypeKey] == true,
            reason = capability and capability.reason or "Weapon appearance capability is unavailable.",
            physical = subtypeKey == hand.physicalSubtype,
        })
    end
    return options, capabilities
end

function Wardrobe.SetWeaponFamilyEnabled(familyKey, enabled)
    local definition = Wardrobe.weaponFamilyDefinitions[familyKey]
    if not definition then return false, "Unknown weapon family." end
    local state = P.EnsurePreviewState()
    local capabilities = P.NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    if not capabilities.availableFamilies[familyKey] then
        return false, capabilities.reasons[familyKey] or (definition.label .. " is unavailable.")
    end
    enabled = enabled == true
    local previous = state.weaponFamilies[familyKey]
    state.weaponFamilies[familyKey] = enabled
    if enabled then
        local anySubtype = false
        for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
            local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
            if hand.subtypes[subtypeKey] and hand.subtypes[subtypeKey].available and state.weaponSubtypes[subtypeKey] then anySubtype = true break end
        end
        if not anySubtype then
            for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
                local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
                if hand.subtypes[subtypeKey] and hand.subtypes[subtypeKey].available then state.weaponSubtypes[subtypeKey] = true end
            end
        end
    end
    if familyKey == "OFF_HAND" and enabled then state.weaponFamilies.ONE_HAND = true end
    if familyKey == "ONE_HAND" and not enabled then state.weaponFamilies.OFF_HAND = false end
    local anyMain = false
    for _, key in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
        if capabilities.availableFamilies[key] and state.weaponFamilies[key] then anyMain = true break end
    end
    if not anyMain then
        state.weaponFamilies[familyKey] = previous
        return false, "At least one Blizzard-compatible main weapon family must remain selected."
    end
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_OPTIONS_CHANGED", familyKey, enabled, capabilities) end
    return true, string.format("%s generation %s.", definition.label, enabled and "enabled" or "disabled")
end

function Wardrobe.SetWeaponSubtypeEnabled(subtypeKey, enabled)
    local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not subtype then return false, "Unknown weapon appearance type." end
    local state = P.EnsurePreviewState()
    local options = Wardrobe.GetWeaponSubtypeOptions(subtype.familyKey)
    local option
    for _, candidate in ipairs(options) do if candidate.key == subtypeKey then option = candidate break end end
    if enabled and (not option or not option.available) then
        return false, option and option.reason or "That weapon appearance type is unavailable."
    end
    state.weaponSubtypes[subtypeKey] = enabled == true
    if enabled then state.weaponFamilies[subtype.familyKey] = true end
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_SUBTYPES_CHANGED", subtypeKey, enabled == true) end
    return true, string.format("%s generation %s.", subtype.label, enabled and "enabled" or "disabled")
end

function Wardrobe.SetAllCompatibleWeaponSubtypes(familyKey, enabled)
    local state = P.EnsurePreviewState()
    local options = Wardrobe.GetWeaponSubtypeOptions(familyKey)
    local changed = 0
    for _, option in ipairs(options) do
        if option.available then
            state.weaponSubtypes[option.key] = enabled ~= false
            changed = changed + 1
        end
    end
    if enabled ~= false and changed > 0 then state.weaponFamilies[familyKey] = true end
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_SUBTYPES_CHANGED", familyKey, enabled ~= false) end
    return changed > 0, changed > 0 and string.format("Updated %d compatible %s type%s.", changed, Wardrobe.weaponFamilyDefinitions[familyKey].label, changed == 1 and "" or "s") or "No compatible types are available."
end

function Wardrobe.SetEquippedWeaponSubtypeOnly(familyKey)
    local state = P.EnsurePreviewState()
    local options, capabilities = Wardrobe.GetWeaponSubtypeOptions(familyKey)
    local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
    local physicalSubtype = hand.physicalSubtype
    if not physicalSubtype or not Wardrobe.weaponSubtypeDefinitions[physicalSubtype] or Wardrobe.weaponSubtypeDefinitions[physicalSubtype].familyKey ~= familyKey then
        return false, "The physically equipped item is not a " .. Wardrobe.weaponFamilyDefinitions[familyKey].label .. " type."
    end
    local available = hand.subtypes[physicalSubtype] and hand.subtypes[physicalSubtype].available
    if not available then return false, "The equipped physical type is not currently available for generation." end
    for _, option in ipairs(options) do state.weaponSubtypes[option.key] = option.key == physicalSubtype end
    state.weaponFamilies[familyKey] = true
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_SUBTYPES_CHANGED", physicalSubtype, true) end
    return true, "Selected the equipped physical weapon type: " .. Wardrobe.weaponSubtypeDefinitions[physicalSubtype].label .. "."
end

function Wardrobe.SetLinkWeaponHands(enabled)
    local state = P.EnsurePreviewState()
    state.linkWeaponHands = enabled ~= false
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_OPTIONS_CHANGED", "LINK_HANDS", state.linkWeaponHands) end
    return true, state.linkWeaponHands and "Weapon hands will match the same visual when possible and otherwise remain within the same exact weapon type." or "Weapon hands may generate independently."
end

function Wardrobe.GetLinkWeaponHands()
    return P.EnsurePreviewState().linkWeaponHands ~= false
end

function Wardrobe.GetWeaponFamilySummary(families)
    families = families or P.EnsurePreviewState().weaponFamilies
    local labels = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if families and families[familyKey] then table.insert(labels, Wardrobe.weaponFamilyDefinitions[familyKey].shortLabel) end
    end
    return #labels > 0 and table.concat(labels, ", ") or "None"
end

function Wardrobe.GetWeaponSubtypeSummary(familyKey, subtypeChoices, onlyEffective)
    subtypeChoices = subtypeChoices or P.EnsurePreviewState().weaponSubtypes
    local options = Wardrobe.GetWeaponSubtypeOptions(familyKey)
    local labels = {}
    for _, option in ipairs(options) do
        if subtypeChoices[option.key] and (not onlyEffective or option.available) then table.insert(labels, option.shortLabel) end
    end
    return #labels > 0 and table.concat(labels, ", ") or "None"
end

function Wardrobe.GetWeaponFilterSummary()
    local state = P.EnsurePreviewState()
    local pieces = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if state.weaponFamilies[familyKey] then
            local summary = Wardrobe.GetWeaponSubtypeSummary(familyKey, state.weaponSubtypes, true)
            if summary ~= "None" then table.insert(pieces, summary) end
        end
    end
    return #pieces > 0 and table.concat(pieces, ", ") or "No compatible weapon types selected"
end

function Wardrobe.GetWeaponConceptSummary(families, subtypes, linked)
    families = families or {}
    subtypes = subtypes or {}
    local labels = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if families[familyKey] then
            local count = 0
            for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
                if subtypes[subtypeKey] then count = count + 1 end
            end
            if count > 0 then table.insert(labels, string.format("%s %d", Wardrobe.weaponFamilyDefinitions[familyKey].shortLabel, count)) end
        end
    end
    local summary = #labels > 0 and table.concat(labels, ", ") or Wardrobe.GetWeaponFamilySummary(families)
    if linked == true then summary = summary .. " • linked" end
    return summary
end

function Wardrobe.GetWeaponFilterCountSummary()
    local state = P.EnsurePreviewState()
    local labels = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if state.weaponFamilies[familyKey] then
            local options = Wardrobe.GetWeaponSubtypeOptions(familyKey)
            local selected, available = 0, 0
            for _, option in ipairs(options) do
                if option.available then available = available + 1 end
                if option.checked then selected = selected + 1 end
            end
            if available > 0 then table.insert(labels, string.format("%s %d/%d", Wardrobe.weaponFamilyDefinitions[familyKey].shortLabel, selected, available)) end
        end
    end
    local summary = #labels > 0 and table.concat(labels, " • ") or "No weapon types selected"
    if state.linkWeaponHands ~= false then summary = summary .. " • linked" end
    return summary
end

function Wardrobe.GetFilteredSlotSources(slotKey)
    local sources = Wardrobe.GetSlotSources(slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition or not definition.weaponRole then return sources end
    local state = P.EnsurePreviewState()
    local capabilities = Wardrobe.GetWeaponAppearanceCapabilities()
    local hand = slotKey == "OFF_HAND" and capabilities.off or capabilities.main
    local filtered = {}
    for _, source in ipairs(sources) do
        local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(source.categoryID)
        local subtype = subtypeKey and hand.subtypes[subtypeKey]
        if subtypeKey and state.weaponSubtypes[subtypeKey] and subtype and subtype.available then
            table.insert(filtered, source)
        end
    end
    return filtered
end


P.weaponGenerationAppearanceIndex = P.weaponGenerationAppearanceIndex or {}
P.weaponSourceInfoCache = P.weaponSourceInfoCache or {}
P.weaponSourceInfoOrder = P.weaponSourceInfoOrder or {}
P.WEAPON_SOURCE_INFO_CACHE_LIMIT = 8192
P.weaponValidationSessionCache = P.weaponValidationSessionCache or {}

function P.ClearWeaponGenerationMetadataCaches()
    P.weaponGenerationAppearanceIndex = {}
    P.weaponSourceInfoCache = {}
    P.weaponSourceInfoOrder = {}
    P.weaponValidationSessionCache = {}
end

function P.StoreWeaponGenerationAppearanceIndex(definition, categoryID, appearances)
    if not definition or not categoryID then return nil end
    local key = tostring(definition.slotName) .. ":" .. tostring(categoryID)
    local indexed = {}
    for _, appearance in ipairs(appearances or {}) do if appearance.visualID then indexed[appearance.visualID] = appearance end end
    P.weaponGenerationAppearanceIndex[key] = indexed
    return indexed
end

function P.StoreWeaponSourceInfo(sourceID, info)
    if not sourceID or type(info) ~= "table" or info.sourceIsCollected ~= true then return info end
    local key = tonumber(sourceID) or sourceID
    if not P.weaponSourceInfoCache[key] then P.weaponSourceInfoOrder[#P.weaponSourceInfoOrder + 1] = key end
    P.weaponSourceInfoCache[key] = {
        sourceIsCollected = info.sourceIsCollected, appearanceIsCollected = info.appearanceIsCollected,
        appearanceIsUsable = info.appearanceIsUsable, canDisplayOnPlayer = info.canDisplayOnPlayer,
        isAnySourceValidForPlayer = info.isAnySourceValidForPlayer,
    }
    while #P.weaponSourceInfoOrder > P.WEAPON_SOURCE_INFO_CACHE_LIMIT do
        local removed = table.remove(P.weaponSourceInfoOrder, 1)
        P.weaponSourceInfoCache[removed] = nil
    end
    return info
end

function P.GetCachedWeaponSourceInfo(sourceID)
    return sourceID and P.weaponSourceInfoCache[tonumber(sourceID) or sourceID] or nil
end

function P.GetGenerationLocation(definition, context)
    local slotName = definition.slotName
    if context.locationsBySlot[slotName] == nil then
        context.locationsBySlot[slotName] = P.GetTransmogLocation(definition) or false
    end
    local location = context.locationsBySlot[slotName]
    return location ~= false and location or nil
end

function P.GetGenerationAppearance(source, definition, context)
    local categoryID = source and source.categoryID
    if not categoryID then
        return nil
    end
    local key = tostring(definition.slotName) .. ":" .. tostring(categoryID)
    local indexed = context.appearancesByCategory[key] or P.weaponGenerationAppearanceIndex[key]
    if not indexed then
        local location = P.GetGenerationLocation(definition, context)
        local appearances = P.GetCategoryAppearancesRobust(categoryID, location)
        indexed = P.StoreWeaponGenerationAppearanceIndex(definition, categoryID, appearances)
    end
    context.appearancesByCategory[key] = indexed
    return indexed[source.visualID]
end
