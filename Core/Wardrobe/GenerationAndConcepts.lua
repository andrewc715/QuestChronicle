local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.GenerateWeapons(state, reroll, styleMode, styleContext)
    local lockedMode, errorMessage = P.GetLockedWeaponMode(state)
    if errorMessage then return false, errorMessage end

    local context = P.CreateWeaponGenerationContext()
    local capabilities = P.NormalizeWeaponFamilyChoices(state, context.capabilities)
    local topology = capabilities.topology

    local lockedMainSource, lockedSubtype
    if lockedMode and state.selections[lockedMode] then
        lockedMainSource = P.GetSourceByID(lockedMode, state.selections[lockedMode])
        lockedSubtype = lockedMainSource and P.GetWeaponSubtypeKeyForCategoryID(lockedMainSource.categoryID)
        if not lockedSubtype then return false, "The locked main-hand appearance has no recognized weapon subtype." end
    end

    local candidateRoutes = P.GetEnabledMainRoutes(state, capabilities, lockedMode, lockedSubtype)
    if #candidateRoutes == 0 then
        return false, "No complete Blizzard weapon appearance route matches the selected families and subtypes."
    end

    -- A locked source may be valid in more than one artifact route. Shuffle the
    -- route candidates, then accept the first route that validates the complete
    -- main/secondary bundle. Nothing is committed until the bundle is complete.
    P.Shuffle(candidateRoutes)
    local selectedRoute, selectedMain, selectedOff, mainFamily, mainSubtype, notice
    local lastFailure

    for _, route in ipairs(candidateRoutes) do
        context.activeRoute = route
        local routeMainCapability = P.BuildRouteHandCapability(route, "PRIMARY", capabilities.main)
        local mainSource = lockedMainSource
        local chosenFamily = lockedMode or route.familyKey
        local chosenSubtype = lockedSubtype

        if mainSource then
            local valid, reason = P.ValidateLockedSourceForRoute(mainSource, route, "PRIMARY", context.mainItem, context)
            if not valid then
                lastFailure = reason
                mainSource = nil
            end
        else
            local excluded = reroll and { [route.familyKey] = state.selections[route.familyKey] } or nil
            mainSource, chosenFamily, chosenSubtype = P.ChooseGeneratedWeaponSource(
                { route.familyKey },
                context.mainItem,
                context,
                excluded,
                nil,
                styleMode,
                styleContext,
                routeMainCapability
            )
            if not mainSource then lastFailure = "No collected appearance matched the route's primary-hand types." end
        end

        if mainSource then
            local offSource
            local routeNotice
            local routeValid = true

            if route.targetsSecondary then
                local routeOffCapability = P.BuildRouteHandCapability(route, "SECONDARY", capabilities.off)
                if state.locks.OFF_HAND and state.selections.OFF_HAND then
                    offSource = P.GetSourceByID("OFF_HAND", state.selections.OFF_HAND)
                    local valid, reason = P.ValidateLockedSourceForRoute(offSource, route, "SECONDARY", context.offItem, context)
                    if not valid then routeValid = false lastFailure = reason end
                elseif state.linkWeaponHands then
                    offSource, _, routeNotice = P.ChooseLinkedWeaponSource(
                        mainSource,
                        context.offItem,
                        context,
                        reroll and { OFF_HAND = state.selections.OFF_HAND } or nil,
                        "OFF_HAND",
                        styleMode,
                        styleContext,
                        routeOffCapability
                    )
                    if not offSource then
                        routeValid = false
                        lastFailure = routeNotice or "The linked route could not produce a compatible secondary appearance."
                    end
                else
                    offSource = P.ChooseGeneratedWeaponSource(
                        { route.familyKey },
                        context.offItem,
                        context,
                        reroll and { OFF_HAND = state.selections.OFF_HAND } or nil,
                        "OFF_HAND",
                        styleMode,
                        styleContext,
                        routeOffCapability
                    )
                    if not offSource then
                        routeValid = false
                        lastFailure = "The route could not produce a compatible secondary-hand appearance."
                    end
                end
            elseif topology.offHandKind == "OFF_HAND" and route.familyKey == "ONE_HAND" then
                local companionRoutes = P.GetEnabledCompanionRoutes(state, capabilities)
                if state.locks.OFF_HAND and state.selections.OFF_HAND then
                    offSource = P.GetSourceByID("OFF_HAND", state.selections.OFF_HAND)
                    local companionValid = false
                    for _, companionRoute in ipairs(companionRoutes) do
                        context.activeRoute = companionRoute
                        local valid = P.ValidateLockedSourceForRoute(offSource, companionRoute, "SECONDARY", context.offItem, context)
                        if valid then companionValid = true break end
                    end
                    if not companionValid then
                        routeValid = false
                        lastFailure = "The locked shield or focus does not match an enabled companion route."
                    end
                elseif #companionRoutes > 0 then
                    local companionRoute = P.ChooseRoute(companionRoutes)
                    context.activeRoute = companionRoute
                    local companionCapability = P.BuildRouteHandCapability(companionRoute, "SECONDARY", capabilities.off)
                    offSource = P.ChooseGeneratedWeaponSource(
                        { "OFF_HAND" },
                        context.offItem,
                        context,
                        reroll and { OFF_HAND = state.selections.OFF_HAND } or nil,
                        "OFF_HAND",
                        styleMode,
                        styleContext,
                        companionCapability
                    )
                    if not offSource then
                        routeValid = false
                        lastFailure = "The enabled shield/focus companion route had no valid collected appearance."
                    end
                end
            elseif topology.offHandKind == "OFF_HAND" and route.familyKey ~= "ONE_HAND" then
                if state.locks.OFF_HAND and state.selections.OFF_HAND then
                    routeValid = false
                    lastFailure = "A locked shield or focus cannot accompany the selected non-one-hand route."
                else
                    offSource = nil
                end
            elseif state.locks.OFF_HAND and state.selections.OFF_HAND then
                routeValid = false
                lastFailure = "The locked off-hand appearance does not belong to the selected weapon route."
            end

            if routeValid then
                selectedRoute = route
                selectedMain = mainSource
                selectedOff = offSource
                mainFamily = chosenFamily or route.familyKey
                mainSubtype = chosenSubtype or P.GetWeaponSubtypeKeyForCategoryID(mainSource.categoryID)
                notice = routeNotice
                break
            end
        end
    end

    if not selectedRoute or not selectedMain then
        return false, lastFailure or "No complete weapon route could be generated."
    end

    -- Atomic commit: clear stale families and write the complete route bundle in
    -- one step only after every required hand has validated.
    for _, familyKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if familyKey == mainFamily then
            P.SetSelectedSource(state, familyKey, selectedMain)
        elseif not state.locks[familyKey] then
            P.SetSelectedSource(state, familyKey, nil)
        end
    end
    if selectedOff then
        P.SetSelectedSource(state, "OFF_HAND", selectedOff)
    elseif not state.locks.OFF_HAND then
        P.SetSelectedSource(state, "OFF_HAND", nil)
    end

    state.lastWeaponRoute = {
        routeID = selectedRoute.id,
        routeKind = selectedRoute.routeKind,
        familyKey = selectedRoute.familyKey,
        weaponOption = selectedRoute.weaponOption,
        weaponOptionName = selectedRoute.weaponOptionName,
        primaryWeaponOption = selectedRoute.primaryWeaponOption or selectedRoute.weaponOption,
        primaryWeaponOptionName = selectedRoute.primaryWeaponOptionName or selectedRoute.weaponOptionName,
        secondaryWeaponOption = selectedRoute.secondaryWeaponOption,
        secondaryWeaponOptionName = selectedRoute.secondaryWeaponOptionName,
        mainSubtype = mainSubtype,
        mainSourceID = selectedMain.sourceID,
        offSourceID = selectedOff and selectedOff.sourceID or nil,
        linked = state.linkWeaponHands ~= false,
        committedAt = time and time() or 0,
    }

    if QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then
        QC.ZoneStyle.AddSourceToGenerationContext(styleContext, selectedMain)
        if selectedOff then QC.ZoneStyle.AddSourceToGenerationContext(styleContext, selectedOff) end
    end

    return true, selectedOff and 2 or 1, notice
end

function Wardrobe.GenerateOutfit(reroll, requestedStyleMode)
    local cache = P.EnsureCache()
    if cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS" then
        return false, "Scan the wardrobe collection before generating an outfit."
    end

    local state = P.EnsurePreviewState()
    local styleEngine = QC.ZoneStyle
    local styleMode = requestedStyleMode or state.styleMode
    local styleContext
    if styleEngine then
        styleMode = styleEngine.NormalizeMode(styleMode)
        state.styleMode = styleMode
        styleContext = P.CreateStyleGenerationContext(state, styleEngine, styleEngine.GetCurrentContext(), nil, true)
    end

    local originalSelections = P.CopyPrimitiveMap(state.selections)
    local originalVisuals = P.CopyPrimitiveMap(state.selectionVisuals)
    local selected = 0
    for _, slotKey in ipairs(P.ARMOR_GENERATION_ORDER) do
        local definition = P.slotByKey[slotKey]
        if definition and not state.locks[slotKey] then
            if P.SetRandomSelection(state, slotKey, reroll == true, styleMode, styleContext) then
                selected = selected + 1
            end
        end
    end

    -- Build around the large armor silhouettes first, then let weapons reinforce
    -- that established set/motif. If a locked weapon is invalid, restore the
    -- previous preview rather than leaving a partially regenerated outfit.
    local weaponsOK, weaponCount, weaponNotice = P.GenerateWeapons(state, reroll == true, styleMode, styleContext)
    if not weaponsOK then
        state.selections = originalSelections
        state.selectionVisuals = originalVisuals
        return false, weaponCount
    end

    state.selectedConceptID = nil
    local generatedName = P.RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if QC.Notify then
        QC.Notify("WARDROBE_WORKBENCH_CHANGED")
    end
    local styleLabel = "Random"
    local profileLabel
    local restrictionLabel
    if styleEngine then
        local modeInfo = styleEngine.GetModeInfo(styleMode)
        styleLabel = modeInfo and modeInfo.label or styleLabel
        profileLabel = styleContext and styleContext.profileLabel
        restrictionLabel = styleEngine.GetContextRestrictionLabel and styleEngine.GetContextRestrictionLabel(styleContext)
        if styleMode == styleEngine.MODE_ZONE_NATIVE then
            styleEngine.ConsumeSuggestion()
        end
    end
    local message = string.format(
        "Generated %s, a %s outfit%s with %d armor slots and %d equipped-weapon-safe appearance%s%s; locked and hidden choices were preserved.",
        generatedName or "a new outfit",
        styleLabel,
        profileLabel and (" for " .. profileLabel) or "",
        selected,
        weaponCount or 0,
        weaponCount == 1 and "" or "s",
        restrictionLabel and (" under " .. restrictionLabel) or ""
    )
    if weaponNotice then
        message = message .. " " .. weaponNotice
    end
    if styleEngine then
        message = message .. " Promotional rewards were excluded, and native-set or shared-motif matches were favored."
    end
    return true, message
end

function Wardrobe.RerollSlot(slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition then return false, "Unknown equipment slot." end
    if Wardrobe.IsSlotLocked(slotKey) then return false, "Unlock this slot before rerolling it." end

    local state = P.EnsurePreviewState()
    local styleEngine = QC.ZoneStyle
    local styleMode = styleEngine and styleEngine.NormalizeMode(state.styleMode) or state.styleMode
    local styleContext = styleEngine and P.CreateStyleGenerationContext(state, styleEngine, styleEngine.GetCurrentContext(), slotKey, false) or nil
    if definition.weaponRole then
        local context = P.CreateWeaponGenerationContext()
        local capabilities = P.NormalizeWeaponFamilyChoices(state, context.capabilities)
        local sourceFamilies = {}
        local equippedItem
        local handCapability
        local preferredSubtype
        if slotKey == "OFF_HAND" then
            if not context.topology.offItem then return false, "No off-hand item is equipped." end
            equippedItem = context.offItem
            handCapability = capabilities.off
            if context.topology.offHandKind == "OFF_HAND" then
                if not state.weaponFamilies.OFF_HAND then return false, "Enable Off-Hand generation before rerolling this slot." end
                sourceFamilies = { "OFF_HAND" }
                local companionRoutes = P.GetEnabledCompanionRoutes(state, capabilities)
                context.activeRoute = P.ChooseRoute(companionRoutes)
                if not context.activeRoute then return false, "No enabled shield/focus companion route is available." end
                handCapability = P.BuildRouteHandCapability(context.activeRoute, "SECONDARY", capabilities.off)
            else
                local selectedMain
                for _, familyKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
                    selectedMain = state.selections[familyKey] and P.GetSourceByID(familyKey, state.selections[familyKey]) or selectedMain
                end
                if not selectedMain then return false, "Select or generate a main-hand appearance before rerolling the linked second hand." end
                local routes = P.FindPrimaryRoutesForSource(selectedMain, capabilities, state.linkWeaponHands == true)
                if #routes == 0 then return false, "The current main-hand appearance has no complete linked route." end
                context.activeRoute = P.ChooseRoute(routes)
                handCapability = P.BuildRouteHandCapability(context.activeRoute, "SECONDARY", capabilities.off)
                sourceFamilies = { context.activeRoute.familyKey }
                preferredSubtype = state.linkWeaponHands and P.GetWeaponSubtypeKeyForCategoryID(selectedMain.categoryID) or nil
                if state.linkWeaponHands then
                    local source, _, notice = P.ChooseLinkedWeaponSource(
                        selectedMain,
                        equippedItem,
                        context,
                        { OFF_HAND = state.selections.OFF_HAND },
                        "OFF_HAND",
                        styleMode,
                        styleContext,
                        handCapability
                    )
                    if not source then return false, notice or "No linked secondary appearance is available." end
                    P.SetSelectedSource(state, "OFF_HAND", source)
                    if styleEngine and styleEngine.AddSourceToGenerationContext then styleEngine.AddSourceToGenerationContext(styleContext, source) end
                    state.selectedConceptID = nil
                    local generatedName = P.RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
                    if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
                    return true, string.format("%s rerolled%s.", definition.label, generatedName and ("; the current look is now " .. generatedName) or "")
                end
            end
        else
            equippedItem = context.mainItem
            handCapability = capabilities.main
            if not capabilities.availableFamilies[slotKey] then return false, capabilities.reasons[slotKey] or "That weapon family is unavailable." end
            if not state.weaponFamilies[slotKey] then return false, string.format("Enable %s before rerolling this slot.", definition.label) end
            sourceFamilies = { slotKey }
        end
        local source = P.ChooseGeneratedWeaponSource(sourceFamilies, equippedItem, context, { [slotKey] = state.selections[slotKey] }, slotKey, styleMode, styleContext, handCapability, preferredSubtype, false)
        if not source then return false, "No cached appearance in the selected Blizzard-compatible weapon types is valid for this hand." end
        P.SetSelectedSource(state, slotKey, source)
        if styleEngine and styleEngine.AddSourceToGenerationContext then styleEngine.AddSourceToGenerationContext(styleContext, source) end
        P.ApplyWeaponSelectionRules(state, slotKey)
        if slotKey ~= "OFF_HAND" and state.linkWeaponHands then
            P.SynchronizeLinkedOffHand(state, source, styleMode, styleContext, state.selections.OFF_HAND)
        end
    elseif not P.SetRandomSelection(state, slotKey, true, styleMode, styleContext) then
        return false, "No compatible appearance is cached for this slot."
    end
    state.selectedConceptID = nil
    local generatedName = P.RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
    return true, string.format("%s rerolled%s.", definition.label, generatedName and ("; the current look is now " .. generatedName) or "")
end

function Wardrobe.GetConcepts()
    local store = P.EnsureConceptStore()
    local concepts = {}
    for _, concept in pairs(store) do
        table.insert(concepts, concept)
    end
    table.sort(concepts, function(left, right)
        if (left.updatedAt or 0) == (right.updatedAt or 0) then
            return string.lower(left.name or "") < string.lower(right.name or "")
        end
        return (left.updatedAt or 0) > (right.updatedAt or 0)
    end)
    return concepts
end

function Wardrobe.GetCurrentConcept()
    local state = P.EnsurePreviewState()
    if not state.selectedConceptID then
        return nil
    end
    local store = P.EnsureConceptStore()
    return store[state.selectedConceptID]
end

function Wardrobe.SaveConcept(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then
        return false, "Enter a name for this outfit concept."
    end
    if #name > 48 then
        return false, "Concept names are limited to 48 characters."
    end

    local store, characterKey = P.EnsureConceptStore()
    local state = P.EnsurePreviewState()
    local concept
    local loweredName = string.lower(name)
    for _, candidate in pairs(store) do
        if string.lower(candidate.name or "") == loweredName then
            concept = candidate
            break
        end
    end

    local now = time()
    if not concept then
        local sequence = #Wardrobe.GetConcepts() + 1
        local identifier = string.format("%s:%d:%d", characterKey, now, sequence)
        while store[identifier] do
            sequence = sequence + 1
            identifier = string.format("%s:%d:%d", characterKey, now, sequence)
        end
        concept = { id = identifier, createdAt = now, characterKey = characterKey }
        store[identifier] = concept
    end
    concept.name = name
    concept.updatedAt = now
    concept.selections = P.CopyPrimitiveMap(state.selections)
    state.selectionVisuals = P.SnapshotSelectionVisuals(state.selections, state.selectionVisuals)
    concept.visuals = P.CopyPrimitiveMap(state.selectionVisuals)
    concept.locks = P.CopyPrimitiveMap(state.locks)
    concept.hidden = P.CopyPrimitiveMap(state.hidden)
    concept.weaponFamilies = P.CopyPrimitiveMap(state.weaponFamilies)
    concept.weaponSubtypes = P.CopyPrimitiveMap(state.weaponSubtypes)
    concept.linkWeaponHands = state.linkWeaponHands ~= false
    concept.styleMode = QC.ZoneStyle and QC.ZoneStyle.NormalizeMode(state.styleMode) or state.styleMode
    concept.generatedName = state.generatedName
    concept.generatedAt = state.generatedAt
    state.selectedConceptID = concept.id
    if QC.Notify then
        QC.Notify("WARDROBE_CONCEPTS_CHANGED", concept)
    end
    return true, "Saved outfit concept: " .. name, concept
end

function Wardrobe.LoadConcept(conceptID)
    local store = P.EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then
        return false, "That outfit concept is no longer available."
    end

    local state = P.EnsurePreviewState()
    local selections, visuals, recovered, missing = P.RebindSelectionMap(concept.selections, concept.visuals, false)
    state.selections = selections
    state.selectionVisuals = visuals
    state.locks = P.CopyPrimitiveMap(concept.locks)
    state.hidden = P.CopyPrimitiveMap(concept.hidden)
    state.weaponFamilies = P.CopyPrimitiveMap(concept.weaponFamilies or { ONE_HAND = true, TWO_HAND = true, RANGED = true, OFF_HAND = true })
    state.weaponSubtypes = P.CopyPrimitiveMap(concept.weaponSubtypes or {})
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        if state.weaponSubtypes[subtypeKey] == nil then state.weaponSubtypes[subtypeKey] = true end
    end
    state.linkWeaponHands = concept.linkWeaponHands ~= false
    P.NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    state.generatedName = concept.generatedName
    state.generatedAt = concept.generatedAt
    if QC.ZoneStyle then
        state.styleMode = QC.ZoneStyle.NormalizeMode(concept.styleMode or state.styleMode)
    elseif concept.styleMode then
        state.styleMode = concept.styleMode
    end
    state.selectedConceptID = concept.id
    if QC.Notify then
        QC.Notify("WARDROBE_WORKBENCH_CHANGED")
    end
    if recovered > 0 or missing > 0 then
        local details = {}
        if recovered > 0 then table.insert(details, string.format("%d changed appearance source%s recovered", recovered, recovered == 1 and "" or "s")) end
        if missing > 0 then table.insert(details, string.format("%d unavailable appearance%s skipped", missing, missing == 1 and "" or "s")) end
        return true, string.format("Loaded %s; %s.", concept.name or "concept", table.concat(details, ", ")), concept
    end
    return true, "Loaded outfit concept: " .. tostring(concept.name or "Unnamed"), concept
end
