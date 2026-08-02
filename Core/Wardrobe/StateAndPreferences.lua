local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.IsSourceCollected(sourceID, source)
    -- A collected visual can contain several sibling item sources. Custom Sets
    -- require an actually owned source, not merely a source whose visual is
    -- unlocked through another item. Keep this test deliberately source-strict.
    if source and source.isCollected == true then
        return true
    end
    if C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource then
        local info = P.SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID)
        if info and info.sourceIsCollected == true then
            return true
        end
    end
    if C_TransmogCollection and C_TransmogCollection.PlayerKnowsSource then
        local known = P.SafeCall(C_TransmogCollection.PlayerKnowsSource, sourceID)
        if known == true then
            return true
        end
    end
    return false
end

function P.GetSourceInfo(sourceID)
    if C_TransmogCollection and C_TransmogCollection.GetSourceInfo then
        return P.SafeCall(C_TransmogCollection.GetSourceInfo, sourceID)
    end
end

function P.GetKnownSources(appearance, categoryID, transmogLocation)
    local visualID = appearance and appearance.visualID
    if not visualID then
        return {}
    end

    local locationData = P.GetLocationData(transmogLocation)
    local sources

    local function ExpandSourceIDs(candidateSources)
        if type(candidateSources) ~= "table" then
            return candidateSources
        end
        local expanded = {}
        for _, candidate in ipairs(candidateSources) do
            if type(candidate) == "number" then
                local source = P.GetSourceInfo(candidate)
                if source then
                    table.insert(expanded, source)
                end
            elseif type(candidate) == "table" then
                table.insert(expanded, candidate)
            end
        end
        return expanded
    end

    -- The generated API documentation accepts a TransmogLocationMixin while
    -- Blizzard's own wardrobe helper also accepts that object. Try the direct,
    -- least stateful path first, then tolerate clients that prefer GetData().
    sources = ExpandSourceIDs(P.SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, transmogLocation))
    if (not sources or #sources == 0) and locationData then
        sources = ExpandSourceIDs(P.SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, locationData))
    end
    if (not sources or #sources == 0) and CollectionWardrobeUtil and type(CollectionWardrobeUtil.GetSortedAppearanceSources) == "function" then
        sources = ExpandSourceIDs(P.SafeCall(CollectionWardrobeUtil.GetSortedAppearanceSources, visualID, categoryID, transmogLocation))
    end

    if (not sources or #sources == 0) and C_TransmogCollection.GetValidAppearanceSourcesForClass then
        local classID = P.GetCurrentClassID()
        if classID then
            sources = ExpandSourceIDs(P.SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, transmogLocation))
            if (not sources or #sources == 0) and locationData then
                sources = ExpandSourceIDs(P.SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, locationData))
            end
        end
    end

    if (not sources or #sources == 0) and C_TransmogCollection.GetAllAppearanceSources then
        sources = {}
        local sourceIDs = P.SafeCall(C_TransmogCollection.GetAllAppearanceSources, visualID) or {}
        for _, sourceID in ipairs(sourceIDs) do
            local source = P.GetSourceInfo(sourceID)
            if source then
                table.insert(sources, source)
            end
        end
    end

    if (not sources or #sources == 0) and appearance.sourceID then
        local source = P.GetSourceInfo(appearance.sourceID)
        if source then
            sources = { source }
        end
    end

    return sources or {}
end

function P.CountCollectedAppearances(appearances)
    local count = 0
    for _, appearance in ipairs(appearances or {}) do
        if appearance.isCollected == true and appearance.isHideVisual ~= true then
            count = count + 1
        end
    end
    return count
end

function P.GetCategoryAppearancesRobust(categoryID, transmogLocation)
    local locationData = P.GetLocationData(transmogLocation)
    local best = {}
    local bestMode = "none"
    local bestCollected = -1

    local function Consider(appearances, mode)
        if type(appearances) ~= "table" then
            return
        end
        local collected = P.CountCollectedAppearances(appearances)
        if collected > bestCollected or (collected == bestCollected and #appearances > #best) then
            best = appearances
            bestMode = mode
            bestCollected = collected
        end
    end

    -- Current generated API docs describe a TransmogLocationMixin. Blizzard's
    -- collection frame currently passes GetData(). Supporting both keeps the
    -- scanner insulated from that implementation seam.
    Consider(P.SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID, transmogLocation), "location")
    if locationData then
        Consider(P.SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID, locationData), "location-data")
    end
    Consider(P.SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID), "category-only")

    return best or {}, bestMode
end

function Wardrobe.GetCache()
    return P.EnsureCache()
end

function Wardrobe.GetPreviewState()
    return P.EnsurePreviewState()
end

function Wardrobe.GetSlotDefinition(slotKey)
    return P.slotByKey[slotKey]
end

function Wardrobe.GetSlotSources(slotKey)
    local cache = P.EnsureCache()
    return cache.bySlot[slotKey] or {}
end

function Wardrobe.GetSlotDiagnostics(slotKey)
    local cache = P.EnsureCache()
    return cache.slotDiagnostics[slotKey]
end

function Wardrobe.IsSlotLocked(slotKey)
    return P.EnsurePreviewState().locks[slotKey] == true
end

function Wardrobe.IsSlotHideable(slotKey)
    local definition = P.slotByKey[slotKey]
    return definition and definition.hideable == true or false
end

function Wardrobe.IsSlotHidden(slotKey)
    return Wardrobe.IsSlotHideable(slotKey) and P.EnsurePreviewState().hidden[slotKey] == true
end

function Wardrobe.SetSlotLocked(slotKey, locked)
    if not P.slotByKey[slotKey] then
        return false, "Unknown equipment slot."
    end
    local state = P.EnsurePreviewState()
    state.locks[slotKey] = locked == true or nil
    state.selectedConceptID = nil
    if QC.Notify then
        QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey)
    end
    return true, state.locks[slotKey] and "Slot locked." or "Slot unlocked."
end

function Wardrobe.ToggleSlotLocked(slotKey)
    return Wardrobe.SetSlotLocked(slotKey, not Wardrobe.IsSlotLocked(slotKey))
end

function Wardrobe.SetSlotHidden(slotKey, hidden)
    if not Wardrobe.IsSlotHideable(slotKey) then
        return false, "Only helm, cloak, shirt, and tabard can be hidden."
    end
    local state = P.EnsurePreviewState()
    state.hidden[slotKey] = hidden == true or nil
    state.selectedConceptID = nil
    if QC.Notify then
        QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey)
    end
    return true, state.hidden[slotKey] and "Slot hidden in the preview." or "Slot shown in the preview."
end

function Wardrobe.ToggleSlotHidden(slotKey)
    return Wardrobe.SetSlotHidden(slotKey, not Wardrobe.IsSlotHidden(slotKey))
end

function P.CopySourceForSlot(source, slotKey)
    if not source or source.slotKey == slotKey then
        return source
    end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    copy.slotKey = slotKey
    return copy
end

function P.GetSourceByID(slotKey, sourceID)
    if not sourceID then
        return nil
    end
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        if source.sourceID == sourceID then
            return source
        end
    end
    -- Dual-wield off hands use the same one-hand visual categories as the main
    -- hand. Reuse that cache without duplicating or invalidating format 5, then
    -- validate it against SECONDARYHANDSLOT before generation or preview.
    if slotKey == "OFF_HAND" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, source in ipairs(Wardrobe.GetSlotSources(familyKey)) do
                if source.sourceID == sourceID then
                    return P.CopySourceForSlot(source, "OFF_HAND")
                end
            end
        end
    end
    return nil
end

function P.FindSourceByVisualID(slotKey, visualID)
    if visualID == nil then return nil end
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        if source.visualID == visualID then return source end
    end
    if slotKey == "OFF_HAND" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, source in ipairs(Wardrobe.GetSlotSources(familyKey)) do
                if source.visualID == visualID then return P.CopySourceForSlot(source, "OFF_HAND") end
            end
        end
    end
    return nil
end

function P.SetSelectedSource(state, slotKey, source)
    state.selectionVisuals = state.selectionVisuals or {}
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end

function P.SnapshotSelectionVisuals(selections, previousVisuals)
    local visuals = {}
    for slotKey, sourceID in pairs(selections or {}) do
        local source = P.GetSourceByID(slotKey, sourceID)
        local visualID = source and source.visualID or (previousVisuals and previousVisuals[slotKey])
        if visualID ~= nil then visuals[slotKey] = visualID end
    end
    return visuals
end

function P.CaptureRecoveryIdentities()
    local state = P.EnsurePreviewState()
    state.selectionVisuals = P.SnapshotSelectionVisuals(state.selections, state.selectionVisuals)
    local concepts = P.EnsureConceptStore()
    for _, concept in pairs(concepts) do
        concept.visuals = P.SnapshotSelectionVisuals(concept.selections, concept.visuals)
    end
end

function P.RebindSelectionMap(selections, visuals, preserveMissing)
    local rebound, reboundVisuals = {}, {}
    local recovered, missing = 0, 0
    for slotKey, sourceID in pairs(selections or {}) do
        local source = P.GetSourceByID(slotKey, sourceID)
        local valid = source and Wardrobe.ValidateSource(source, slotKey)
        local visualID = source and source.visualID or (visuals and visuals[slotKey])
        if not valid and visualID ~= nil then
            local replacement = P.FindSourceByVisualID(slotKey, visualID)
            local replacementValid = replacement and Wardrobe.ValidateSource(replacement, slotKey)
            if replacementValid then
                source = replacement
                valid = true
                if replacement.sourceID ~= sourceID then recovered = recovered + 1 end
            end
        end
        if valid and source then
            rebound[slotKey] = source.sourceID
            reboundVisuals[slotKey] = source.visualID or visualID
        else
            missing = missing + 1
            if preserveMissing then
                rebound[slotKey] = sourceID
                if visualID ~= nil then reboundVisuals[slotKey] = visualID end
            end
        end
    end
    return rebound, reboundVisuals, recovered, missing
end

function P.RecoverAppearanceReferences(cache)
    local settings = QC.GetSettings and QC.GetSettings() or {}
    if settings.recoverMissingAppearances == false then
        return 0, 0, 0
    end

    local state = P.EnsurePreviewState()
    local selections, visuals, previewRecovered, previewMissing = P.RebindSelectionMap(state.selections, state.selectionVisuals, false)
    state.selections = selections
    state.selectionVisuals = visuals

    local concepts = P.EnsureConceptStore()
    local conceptRecovered, conceptMissing = 0, 0
    for _, concept in pairs(concepts) do
        local rebound, reboundVisuals, recovered, missing = P.RebindSelectionMap(concept.selections, concept.visuals, true)
        concept.selections = rebound
        concept.visuals = reboundVisuals
        conceptRecovered = conceptRecovered + recovered
        conceptMissing = conceptMissing + missing
    end

    cache.lastRecovery = {
        at = time and time() or 0,
        previewRecovered = previewRecovered,
        conceptRecovered = conceptRecovered,
        missing = previewMissing + conceptMissing,
    }
    local totalRecovered = previewRecovered + conceptRecovered
    if totalRecovered > 0 and settings.announceWardrobeUpdates ~= false and QC.Print then
        QC.Print(string.format("Recovered %d outfit appearance%s after Blizzard changed the cached source.", totalRecovered, totalRecovered == 1 and "" or "s"))
    end
    if QC.Notify then
        QC.Notify("WARDROBE_APPEARANCES_RECOVERED", cache.lastRecovery)
    end
    return previewRecovered, conceptRecovered, previewMissing + conceptMissing
end

function P.GetSourcePreferenceIdentity(source)
    if not source then return nil end
    if source.visualID then return "visual:" .. tostring(source.visualID) end
    if source.sourceID then return "source:" .. tostring(source.sourceID) end
    if source.itemID then return "item:" .. tostring(source.itemID) end
end

function Wardrobe.GetZonePreferenceKey(context)
    return P.GetZonePreferenceKey(context)
end

function Wardrobe.GetSourceZonePreference(source, context)
    local identity = P.GetSourcePreferenceIdentity(source)
    if not identity then return nil end
    local preferences = P.GetZonePreferenceStore(context, false)
    if not preferences then return nil end
    if preferences.exclusions[identity] then return "excluded" end
    if preferences.favorites[identity] then return "favorite" end
end

function Wardrobe.SetSourceZonePreference(source, preference, context)
    local identity = P.GetSourcePreferenceIdentity(source)
    if not identity then return false, "That appearance has no stable visual identity." end
    if preference ~= nil and preference ~= "favorite" and preference ~= "excluded" then
        return false, "Unknown zone preference."
    end

    local preferences, _, zoneLabel = P.GetZonePreferenceStore(context, true)
    preferences.favorites[identity] = preference == "favorite" and true or nil
    preferences.exclusions[identity] = preference == "excluded" and true or nil
    preferences.updatedAt = time and time() or 0
    if QC.Notify then QC.Notify("WARDROBE_ZONE_PREFERENCES_CHANGED", source, preference, zoneLabel) end

    local sourceName = tostring(source.name or source.sourceID or "Appearance")
    if preference == "favorite" then
        return true, string.format("Favoring %s when generating outfits in %s.", sourceName, zoneLabel)
    elseif preference == "excluded" then
        return true, string.format("Excluding %s from generated outfits in %s. Manual preview is still available.", sourceName, zoneLabel)
    end
    return true, string.format("Cleared the %s preference for %s.", zoneLabel, sourceName)
end

function Wardrobe.ToggleZoneFavorite(slotKey, sourceID, context)
    local source = P.GetSourceByID(slotKey, sourceID)
    if not source then return false, "Select a cached appearance first." end
    local current = Wardrobe.GetSourceZonePreference(source, context)
    if current == "favorite" then
        return Wardrobe.SetSourceZonePreference(source, nil, context)
    end
    return Wardrobe.SetSourceZonePreference(source, "favorite", context)
end

function Wardrobe.ToggleZoneExclusion(slotKey, sourceID, context)
    local source = P.GetSourceByID(slotKey, sourceID)
    if not source then return false, "Select a cached appearance first." end
    local current = Wardrobe.GetSourceZonePreference(source, context)
    if current == "excluded" then
        return Wardrobe.SetSourceZonePreference(source, nil, context)
    end
    return Wardrobe.SetSourceZonePreference(source, "excluded", context)
end

function Wardrobe.GetZonePreferenceSummary(context)
    local preferences, _, zoneLabel = P.GetZonePreferenceStore(context, false)
    if not preferences then return 0, 0, zoneLabel end
    local favorites, exclusions = 0, 0
    for _, value in pairs(preferences.favorites) do if value then favorites = favorites + 1 end end
    for _, value in pairs(preferences.exclusions) do if value then exclusions = exclusions + 1 end end
    return favorites, exclusions, zoneLabel
end

function P.GetSelectedSources(state)
    local sources = {}
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        if state.selections[definition.key] and not state.hidden[definition.key] then
            local source = P.GetSourceByID(definition.key, state.selections[definition.key])
            if source then table.insert(sources, source) end
        end
    end
    return sources
end

function P.RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if not styleEngine or not styleEngine.GenerateOutfitName then return nil end
    state.generatedName = styleEngine.GenerateOutfitName(styleMode, styleContext, P.GetSelectedSources(state))
    state.generatedAt = time and time() or 0
    return state.generatedName
end

function Wardrobe.GetGeneratedOutfitName()
    return P.EnsurePreviewState().generatedName
end

function P.ClearWeaponSlot(state, slotKey)
    P.SetSelectedSource(state, slotKey, nil)
    state.locks[slotKey] = nil
    state.hidden[slotKey] = nil
end

function P.ApplyWeaponSelectionRules(state, slotKey)
    if slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            if familyKey ~= slotKey then P.ClearWeaponSlot(state, familyKey) end
        end
        local topology = Wardrobe.GetWeaponTopology()
        if not topology.offItem then P.ClearWeaponSlot(state, "OFF_HAND") end
    end
end
