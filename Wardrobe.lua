local QC = QuestChronicle

QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe

Wardrobe.CACHE_VERSION = 3
Wardrobe.PAGE_SIZE = 8

-- Resolve collection enum values when the scan runs instead of when this file loads.
-- Some Blizzard enum tables are not ready during early addon loading.
Wardrobe.slotDefinitions = {
    { key = "HEAD", label = "Head", slotName = "HEADSLOT", categoryNames = { "Head" }, fallbackCategoryIDs = { 1 } },
    { key = "SHOULDER", label = "Shoulders", slotName = "SHOULDERSLOT", categoryNames = { "Shoulder" }, fallbackCategoryIDs = { 2 } },
    { key = "BACK", label = "Back", slotName = "BACKSLOT", categoryNames = { "Back" }, fallbackCategoryIDs = { 3 } },
    { key = "CHEST", label = "Chest", slotName = "CHESTSLOT", categoryNames = { "Chest" }, fallbackCategoryIDs = { 4 } },
    { key = "SHIRT", label = "Shirt", slotName = "SHIRTSLOT", categoryNames = { "Shirt" }, fallbackCategoryIDs = { 5 } },
    { key = "TABARD", label = "Tabard", slotName = "TABARDSLOT", categoryNames = { "Tabard" }, fallbackCategoryIDs = { 6 } },
    { key = "WRIST", label = "Wrists", slotName = "WRISTSLOT", categoryNames = { "Wrist" }, fallbackCategoryIDs = { 7 } },
    { key = "HANDS", label = "Hands", slotName = "HANDSSLOT", categoryNames = { "Hands" }, fallbackCategoryIDs = { 8 } },
    { key = "WAIST", label = "Waist", slotName = "WAISTSLOT", categoryNames = { "Waist" }, fallbackCategoryIDs = { 9 } },
    { key = "LEGS", label = "Legs", slotName = "LEGSSLOT", categoryNames = { "Legs" }, fallbackCategoryIDs = { 10 } },
    { key = "FEET", label = "Feet", slotName = "FEETSLOT", categoryNames = { "Feet" }, fallbackCategoryIDs = { 11 } },
    {
        key = "ONE_HAND", label = "One-Hand", slotName = "MAINHANDSLOT",
        categoryNames = { "Wand", "OneHAxe", "OneHSword", "OneHMace", "Dagger", "Fist", "Warglaives", "Paired" },
        fallbackCategoryIDs = { 12, 13, 14, 15, 16, 17, 28, 29 },
    },
    {
        key = "TWO_HAND", label = "Two-Hand", slotName = "MAINHANDSLOT",
        categoryNames = { "TwoHAxe", "TwoHSword", "TwoHMace", "Staff", "Polearm" },
        fallbackCategoryIDs = { 20, 21, 22, 23, 24 },
    },
    {
        key = "RANGED", label = "Ranged", slotName = "MAINHANDSLOT",
        categoryNames = { "Bow", "Gun", "Crossbow" },
        fallbackCategoryIDs = { 25, 26, 27 },
    },
    {
        key = "OFF_HAND", label = "Off-Hand", slotName = "SECONDARYHANDSLOT",
        categoryNames = { "Shield", "Holdable" },
        fallbackCategoryIDs = { 18, 19 },
    },
}

local slotByKey = {}
for _, definition in ipairs(Wardrobe.slotDefinitions) do
    slotByKey[definition.key] = definition
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end
    local ok, a, b, c, d, e, f = pcall(func, ...)
    if ok then
        return a, b, c, d, e, f
    end
    return nil
end

local function ResetCache(cache, state)
    cache.cacheVersion = Wardrobe.CACHE_VERSION
    cache.bySlot = {}
    cache.slotDiagnostics = {}
    cache.scanState = state or "NEVER"
    cache.totalSources = 0
    cache.totalVisuals = 0
    cache.expectedCollectedVisuals = 0
    cache.scanError = nil
    cache.scanWarning = nil
    cache.dirty = true
    cache.dirtyReason = "CACHE_UPGRADE"
end

local function EnsureCache()
    local database = QC.GetDatabase()
    database.wardrobe = database.wardrobe or {}
    local cache = database.wardrobe
    if cache.cacheVersion ~= Wardrobe.CACHE_VERSION then
        ResetCache(cache, "STALE")
    end
    cache.bySlot = cache.bySlot or {}
    cache.slotDiagnostics = cache.slotDiagnostics or {}
    cache.scanState = cache.scanState or "NEVER"
    cache.totalSources = cache.totalSources or 0
    cache.totalVisuals = cache.totalVisuals or 0
    cache.expectedCollectedVisuals = cache.expectedCollectedVisuals or 0
    return cache
end

local function EnsurePreviewState()
    local state = QC.GetUIState()
    state.outfits = state.outfits or {}
    state.outfits.selections = state.outfits.selections or {}
    state.outfits.selectedSlot = state.outfits.selectedSlot or "HEAD"
    state.outfits.pages = state.outfits.pages or {}
    return state.outfits
end

local function LoadTransmogSupport()
    if TransmogUtil and type(TransmogUtil.GetTransmogLocation) == "function" then
        return true
    end

    local loader = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if type(loader) == "function" then
        pcall(loader, "Blizzard_TransmogShared")
        pcall(loader, "Blizzard_Collections")
        pcall(loader, "Blizzard_Transmog")
    end

    return TransmogUtil and type(TransmogUtil.GetTransmogLocation) == "function"
end

local function ResolveCategoryIDs(definition)
    local categoryIDs = {}
    for index, categoryName in ipairs(definition.categoryNames or {}) do
        local categoryID
        if Enum and Enum.TransmogCollectionType then
            categoryID = Enum.TransmogCollectionType[categoryName]
        end
        categoryID = categoryID or (definition.fallbackCategoryIDs and definition.fallbackCategoryIDs[index])
        if categoryID then
            table.insert(categoryIDs, categoryID)
        end
    end
    definition.categoryIDs = categoryIDs
    return categoryIDs
end

local function GetTransmogLocation(definition)
    if not LoadTransmogSupport() then
        return nil
    end
    local appearanceType = Enum and Enum.TransmogType and Enum.TransmogType.Appearance or 0
    return SafeCall(TransmogUtil.GetTransmogLocation, definition.slotName, appearanceType, false)
end

local function GetLocationData(transmogLocation)
    if transmogLocation and type(transmogLocation.GetData) == "function" then
        return SafeCall(transmogLocation.GetData, transmogLocation)
    end
    return nil
end

local function GetItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return SafeCall(C_Item.GetItemIconByID, itemID)
    elseif _G and type(_G.GetItemIcon) == "function" then
        return SafeCall(_G.GetItemIcon, itemID)
    end
end

local function GetSourceItemID(sourceID, source)
    if source and source.itemID then
        return source.itemID
    end
    if C_Transmog and C_Transmog.GetItemIDForSource then
        return SafeCall(C_Transmog.GetItemIDForSource, sourceID)
    end
end

local function GetCurrentClassID()
    if UnitClass then
        local _, _, classID = UnitClass("player")
        return classID
    end
end

local function IsBlizzardWardrobeVisible()
    if TransmogFrame and TransmogFrame.IsShown and TransmogFrame:IsShown() then
        return true
    end
    if WardrobeCollectionFrame and WardrobeCollectionFrame.IsShown and WardrobeCollectionFrame:IsShown() then
        return true
    end
    return false
end

local function GetSearchType()
    return Enum and Enum.TransmogSearchType and Enum.TransmogSearchType.Items or 1
end

local function GetSearchBoxText()
    local boxes = {}
    if WardrobeCollectionFrame and WardrobeCollectionFrame.SearchBox then
        table.insert(boxes, WardrobeCollectionFrame.SearchBox)
    end
    if TransmogFrame and TransmogFrame.WardrobeCollection and TransmogFrame.WardrobeCollection.TabContent then
        local itemsFrame = TransmogFrame.WardrobeCollection.TabContent.ItemsFrame
        if itemsFrame and itemsFrame.SearchBox then
            table.insert(boxes, itemsFrame.SearchBox)
        end
    end
    for _, box in ipairs(boxes) do
        if box.GetText then
            local text = SafeCall(box.GetText, box)
            if text and text ~= "" then
                return text
            end
        end
    end
    return ""
end

local function CaptureCollectionState()
    local state = {
        collectedShown = SafeCall(C_TransmogCollection.GetCollectedShown),
        uncollectedShown = SafeCall(C_TransmogCollection.GetUncollectedShown),
        allFactionsShown = SafeCall(C_TransmogCollection.GetAllFactionsShown),
        allRacesShown = SafeCall(C_TransmogCollection.GetAllRacesShown),
        classFilter = SafeCall(C_TransmogCollection.GetClassFilter),
        searchText = GetSearchBoxText(),
        sourceTypes = {},
    }

    local sourceCount = tonumber(SafeCall(C_TransmogCollection.GetNumTransmogSources)) or 0
    for index = 1, sourceCount do
        state.sourceTypes[index] = SafeCall(C_TransmogCollection.IsSourceTypeFilterChecked, index)
    end
    return state
end

local function ApplyScanCollectionState()
    -- Ask WoW for the broadest possible collection view and filter collected
    -- appearances locally. This avoids an empty result when the native Wardrobe
    -- has a stale collected-only/search filter that has not finished rebuilding.
    SafeCall(C_TransmogCollection.SetCollectedShown, true)
    SafeCall(C_TransmogCollection.SetUncollectedShown, true)
    SafeCall(C_TransmogCollection.SetAllFactionsShown, true)
    SafeCall(C_TransmogCollection.SetAllRacesShown, true)
    local classID = GetCurrentClassID()
    if classID then
        SafeCall(C_TransmogCollection.SetClassFilter, classID)
    end
    SafeCall(C_TransmogCollection.SetAllSourceTypeFilters, true)
    SafeCall(C_TransmogCollection.ClearSearch, GetSearchType())
end

local function RestoreCollectionState(state)
    if not state then
        return
    end
    if state.collectedShown ~= nil then
        SafeCall(C_TransmogCollection.SetCollectedShown, state.collectedShown)
    end
    if state.uncollectedShown ~= nil then
        SafeCall(C_TransmogCollection.SetUncollectedShown, state.uncollectedShown)
    end
    if state.allFactionsShown ~= nil then
        SafeCall(C_TransmogCollection.SetAllFactionsShown, state.allFactionsShown)
    end
    if state.allRacesShown ~= nil then
        SafeCall(C_TransmogCollection.SetAllRacesShown, state.allRacesShown)
    end
    if state.classFilter ~= nil then
        SafeCall(C_TransmogCollection.SetClassFilter, state.classFilter)
    end
    for index, checked in pairs(state.sourceTypes or {}) do
        if checked ~= nil then
            SafeCall(C_TransmogCollection.SetSourceTypeFilter, index, checked)
        end
    end
    if state.searchText and state.searchText ~= "" then
        SafeCall(C_TransmogCollection.SetSearch, GetSearchType(), state.searchText)
    else
        SafeCall(C_TransmogCollection.ClearSearch, GetSearchType())
    end
end

local function IsSourceCollected(sourceID, source, appearance)
    if source and source.isCollected == true then
        return true
    end
    if C_TransmogCollection and C_TransmogCollection.PlayerKnowsSource then
        local known = SafeCall(C_TransmogCollection.PlayerKnowsSource, sourceID)
        if known == true then
            return true
        end
    end
    if C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource then
        local info = SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID)
        if info and (info.sourceIsCollected or info.sourceIsKnown) then
            return true
        end
    end
    -- GetAppearanceSources returns known sources. This fallback handles clients
    -- that omit the per-source collected flag while the visual is collected.
    return appearance and appearance.isCollected == true and source and source.isCollected ~= false
end

local function GetSourceInfo(sourceID)
    if C_TransmogCollection and C_TransmogCollection.GetSourceInfo then
        return SafeCall(C_TransmogCollection.GetSourceInfo, sourceID)
    end
end

local function GetKnownSources(appearance, categoryID, transmogLocation)
    local visualID = appearance and appearance.visualID
    if not visualID then
        return {}
    end

    local locationData = GetLocationData(transmogLocation)
    local sources

    -- The generated API documentation accepts a TransmogLocationMixin while
    -- Blizzard's own wardrobe helper also accepts that object. Try the direct,
    -- least stateful path first, then tolerate clients that prefer GetData().
    sources = SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, transmogLocation)
    if (not sources or #sources == 0) and locationData then
        sources = SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, locationData)
    end
    if (not sources or #sources == 0) and CollectionWardrobeUtil and type(CollectionWardrobeUtil.GetSortedAppearanceSources) == "function" then
        sources = SafeCall(CollectionWardrobeUtil.GetSortedAppearanceSources, visualID, categoryID, transmogLocation)
    end

    if (not sources or #sources == 0) and C_TransmogCollection.GetValidAppearanceSourcesForClass then
        local classID = GetCurrentClassID()
        if classID then
            sources = SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, transmogLocation)
            if (not sources or #sources == 0) and locationData then
                sources = SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, locationData)
            end
        end
    end

    if (not sources or #sources == 0) and C_TransmogCollection.GetAllAppearanceSources then
        sources = {}
        local sourceIDs = SafeCall(C_TransmogCollection.GetAllAppearanceSources, visualID) or {}
        for _, sourceID in ipairs(sourceIDs) do
            local source = GetSourceInfo(sourceID)
            if source then
                table.insert(sources, source)
            end
        end
    end

    if (not sources or #sources == 0) and appearance.sourceID then
        local source = GetSourceInfo(appearance.sourceID)
        if source then
            sources = { source }
        end
    end

    return sources or {}
end

local function CountCollectedAppearances(appearances)
    local count = 0
    for _, appearance in ipairs(appearances or {}) do
        if appearance.isCollected == true and appearance.isHideVisual ~= true then
            count = count + 1
        end
    end
    return count
end

local function GetCategoryAppearancesRobust(categoryID, transmogLocation)
    local locationData = GetLocationData(transmogLocation)
    local best = {}
    local bestMode = "none"
    local bestCollected = -1

    local function Consider(appearances, mode)
        if type(appearances) ~= "table" then
            return
        end
        local collected = CountCollectedAppearances(appearances)
        if collected > bestCollected or (collected == bestCollected and #appearances > #best) then
            best = appearances
            bestMode = mode
            bestCollected = collected
        end
    end

    -- Current generated API docs describe a TransmogLocationMixin. Blizzard's
    -- collection frame currently passes GetData(). Supporting both keeps the
    -- scanner insulated from that implementation seam.
    Consider(SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID, transmogLocation), "location")
    if locationData then
        Consider(SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID, locationData), "location-data")
    end
    Consider(SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID), "category-only")

    return best or {}, bestMode
end

function Wardrobe.GetCache()
    return EnsureCache()
end

function Wardrobe.GetPreviewState()
    return EnsurePreviewState()
end

function Wardrobe.GetSlotDefinition(slotKey)
    return slotByKey[slotKey]
end

function Wardrobe.GetSlotSources(slotKey)
    local cache = EnsureCache()
    return cache.bySlot[slotKey] or {}
end

function Wardrobe.GetSlotDiagnostics(slotKey)
    local cache = EnsureCache()
    return cache.slotDiagnostics[slotKey]
end

function Wardrobe.GetSelectedSource(slotKey)
    local state = EnsurePreviewState()
    local sourceID = state.selections[slotKey]
    if not sourceID then
        return nil
    end
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        if source.sourceID == sourceID then
            return source
        end
    end
    return nil
end

function Wardrobe.ValidateSource(source, slotKey)
    if type(source) ~= "table" then
        return false, "Appearance data is unavailable."
    end
    if not source.isCollected then
        return false, "This appearance is not collected."
    end
    if source.isUsable == false then
        return false, "This appearance is not usable by this character."
    end
    if source.canDisplayOnPlayer == false then
        return false, "This character cannot display the appearance."
    end
    if source.isValidSourceForPlayer == false then
        return false, "The appearance is not valid for this character."
    end
    if source.meetsTransmogPlayerCondition == false then
        return false, source.useError or "A player condition is not met."
    end
    if source.useError then
        return false, source.useError
    end
    if source.isHideVisual then
        return false, "Hidden-slot visuals are not included in the foundation preview."
    end
    if not source.itemID then
        return false, "WoW did not provide an item for this appearance."
    end
    if slotKey and source.slotKey and source.slotKey ~= slotKey then
        return false, "The appearance belongs to another preview slot."
    end
    return true, "Compatible"
end

local function NormalizeSource(source, appearance, slotKey, categoryID)
    local sourceID = source and source.sourceID or appearance and appearance.sourceID
    if not sourceID then
        return nil
    end

    local itemID = GetSourceItemID(sourceID, source)
    local normalized = {
        sourceID = sourceID,
        visualID = source and (source.visualID or source.appearanceID or source.itemAppearanceID) or nil,
        itemID = itemID,
        name = source and source.name or nil,
        quality = source and source.quality or nil,
        sourceType = source and source.sourceType or nil,
        inventoryType = source and source.invType or nil,
        categoryID = source and source.categoryID or categoryID,
        slotKey = slotKey,
        isCollected = IsSourceCollected(sourceID, source, appearance),
        isHideVisual = source and source.isHideVisual == true or appearance and appearance.isHideVisual == true,
        isUsable = appearance and appearance.isUsable,
        playerCanCollect = source and source.playerCanCollect,
        isValidSourceForPlayer = source and source.isValidSourceForPlayer,
        canDisplayOnPlayer = source and source.canDisplayOnPlayer,
        meetsTransmogPlayerCondition = source and source.meetsTransmogPlayerCondition,
        useError = source and source.useError,
        icon = GetItemIcon(itemID) or appearance and appearance.icon,
    }

    normalized.visualID = normalized.visualID or (appearance and appearance.visualID) or sourceID
    if normalized.canDisplayOnPlayer == nil and appearance then
        normalized.canDisplayOnPlayer = appearance.canDisplayOnPlayer
    end
    if normalized.isUsable == nil and appearance then
        normalized.isUsable = appearance.isUsable
    end
    if not normalized.name and appearance then
        normalized.name = appearance.name
    end
    if not normalized.name and itemID and C_Item and C_Item.GetItemNameByID then
        normalized.name = SafeCall(C_Item.GetItemNameByID, itemID)
    end
    normalized.name = normalized.name or ("Appearance " .. tostring(sourceID))
    return normalized
end

local function BetterSource(candidate, current)
    if not current then
        return true
    end
    if candidate.isCollected ~= current.isCollected then
        return candidate.isCollected
    end
    if (candidate.useError == nil) ~= (current.useError == nil) then
        return candidate.useError == nil
    end
    if candidate.canDisplayOnPlayer ~= current.canDisplayOnPlayer then
        return candidate.canDisplayOnPlayer ~= false
    end
    if candidate.isValidSourceForPlayer ~= current.isValidSourceForPlayer then
        return candidate.isValidSourceForPlayer ~= false
    end
    if candidate.meetsTransmogPlayerCondition ~= current.meetsTransmogPlayerCondition then
        return candidate.meetsTransmogPlayerCondition ~= false
    end
    if candidate.quality ~= current.quality then
        return (candidate.quality or 0) > (current.quality or 0)
    end
    return (candidate.sourceID or 0) < (current.sourceID or 0)
end

local function ScanSlot(definition)
    local visuals = {}
    local diagnostics = {
        expectedCollected = 0,
        returnedAppearances = 0,
        collectedAppearances = 0,
        returnedSources = 0,
        compatibleVisuals = 0,
        excludedVisuals = 0,
        categories = {},
    }

    local transmogLocation = GetTransmogLocation(definition)
    if not transmogLocation then
        error("WoW did not provide a transmog location for " .. tostring(definition.slotName))
    end

    for _, categoryID in ipairs(ResolveCategoryIDs(definition)) do
        -- Use the unfiltered collection count as the diagnostic baseline. The
        -- filtered count can temporarily be zero while WoW rebuilds a search.
        local expected = tonumber(SafeCall(C_TransmogCollection.GetCategoryCollectedCount, categoryID)) or 0
        local appearances, retrievalMode = GetCategoryAppearancesRobust(categoryID, transmogLocation)
        local categoryDiagnostic = {
            categoryID = categoryID,
            expectedCollected = expected,
            returnedAppearances = #appearances,
            collectedAppearances = 0,
            returnedSources = 0,
            compatibleVisuals = 0,
            retrievalMode = retrievalMode,
        }
        diagnostics.expectedCollected = diagnostics.expectedCollected + expected
        diagnostics.returnedAppearances = diagnostics.returnedAppearances + #appearances

        for _, appearance in ipairs(appearances) do
            if appearance.isCollected == true and appearance.isHideVisual ~= true then
                categoryDiagnostic.collectedAppearances = categoryDiagnostic.collectedAppearances + 1
                diagnostics.collectedAppearances = diagnostics.collectedAppearances + 1

                local acceptedForAppearance = false
                local sources = GetKnownSources(appearance, categoryID, transmogLocation)
                categoryDiagnostic.returnedSources = categoryDiagnostic.returnedSources + #sources
                diagnostics.returnedSources = diagnostics.returnedSources + #sources

                for _, source in ipairs(sources) do
                    local normalized = NormalizeSource(source, appearance, definition.key, categoryID)
                    if normalized then
                        local valid = Wardrobe.ValidateSource(normalized, definition.key)
                        if valid then
                            acceptedForAppearance = true
                            local visualKey = normalized.visualID or normalized.sourceID
                            if BetterSource(normalized, visuals[visualKey]) then
                                visuals[visualKey] = normalized
                            end
                        end
                    end
                end

                if acceptedForAppearance then
                    categoryDiagnostic.compatibleVisuals = categoryDiagnostic.compatibleVisuals + 1
                else
                    diagnostics.excludedVisuals = diagnostics.excludedVisuals + 1
                end
            end
        end

        table.insert(diagnostics.categories, categoryDiagnostic)
    end

    local results = {}
    for _, source in pairs(visuals) do
        table.insert(results, source)
    end
    table.sort(results, function(left, right)
        local leftName = string.lower(left.name or "")
        local rightName = string.lower(right.name or "")
        if leftName == rightName then
            return (left.sourceID or 0) < (right.sourceID or 0)
        end
        return leftName < rightName
    end)

    diagnostics.compatibleVisuals = #results
    return results, diagnostics
end

function Wardrobe.IsScanning()
    return Wardrobe.scanning == true
end

function Wardrobe.MarkDirty(reason)
    local cache = EnsureCache()
    cache.dirty = true
    cache.dirtyReason = reason or "COLLECTION_CHANGED"
    if QC.Notify then
        QC.Notify("WARDROBE_CACHE_DIRTY", cache.dirtyReason)
    end
end

function Wardrobe.Scan(force)
    if Wardrobe.scanning then
        return false, "A wardrobe scan is already running."
    end
    if not C_TransmogCollection or not C_TransmogCollection.GetCategoryAppearances then
        return false, "The transmog collection API is unavailable."
    end
    if IsBlizzardWardrobeVisible() then
        return false, "Close Blizzard's Transmogrify or Wardrobe window before scanning. Quest Chronicle temporarily uses the collection filters and then restores them."
    end
    if not LoadTransmogSupport() then
        return false, "Blizzard's transmog location helpers are unavailable. Try /reload and scan again."
    end

    local cache = EnsureCache()
    if not force and cache.scanState == "COMPLETE" and not cache.dirty then
        return false, "The wardrobe cache is current."
    end

    Wardrobe.scanning = true
    Wardrobe.scanCollectionState = CaptureCollectionState()
    ApplyScanCollectionState()
    SafeCall(C_TransmogCollection.UpdateUsableAppearances)

    cache.scanState = "PREPARING"
    cache.scanStartedAt = time()
    cache.scanCompletedAt = nil
    cache.scanError = nil
    cache.scanWarning = nil

    -- Build into a staging area. An empty or failed API response must never
    -- erase a previously healthy wardrobe cache.
    local pending = {
        bySlot = {},
        slotDiagnostics = {},
        totalSources = 0,
        totalVisuals = 0,
        expectedCollectedVisuals = 0,
        scanError = nil,
    }
    local index = 1

    local function RestoreFilters()
        RestoreCollectionState(Wardrobe.scanCollectionState)
        Wardrobe.scanCollectionState = nil
    end

    local function FinishFailure(message)
        RestoreFilters()
        Wardrobe.scanning = false
        cache.scanState = "FAILED"
        cache.scanCompletedAt = time()
        cache.scanError = message
        cache.scanWarning = nil
        cache.dirty = true
        cache.dirtyReason = "SCAN_FAILED"
        if QC.Notify then
            QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
        end
    end

    local function FinishScan()
        RestoreFilters()
        Wardrobe.scanning = false

        if pending.expectedCollectedVisuals > 0 and pending.totalVisuals == 0 then
            cache.scanState = "FAILED"
            cache.scanCompletedAt = time()
            cache.scanError = "WoW reports collected appearances, but every collection query returned an empty usable cache. The previous cache was preserved."
            cache.scanWarning = nil
            cache.dirty = true
            cache.dirtyReason = "EMPTY_COLLECTION_RESPONSE"
            if QC.Notify then
                QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
            end
            return
        end

        cache.bySlot = pending.bySlot
        cache.slotDiagnostics = pending.slotDiagnostics
        cache.totalSources = pending.totalSources
        cache.totalVisuals = pending.totalVisuals
        cache.expectedCollectedVisuals = pending.expectedCollectedVisuals
        cache.scanError = pending.scanError
        cache.scanState = pending.scanError and "COMPLETE_WITH_WARNINGS" or "COMPLETE"
        cache.scanCompletedAt = time()
        cache.dirty = false
        cache.dirtyReason = nil
        cache.characterKey = QC.GetCurrentCharacter().key

        -- Collected source counts and cached visual counts describe different things.
        -- Multiple item sources may share one visual, and character-incompatible
        -- sources are intentionally excluded. Do not flag a healthy non-empty
        -- cache merely because those totals differ.
        cache.scanWarning = nil

        if QC.Notify then
            QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
        end
    end

    local function ScanCurrentSlot(retryCount)
        local definition = Wardrobe.slotDefinitions[index]
        if not definition then
            FinishScan()
            return
        end

        local ok, sources, diagnostics = pcall(ScanSlot, definition)
        if ok and diagnostics and diagnostics.expectedCollected > 0 and diagnostics.returnedAppearances == 0 and (retryCount or 0) < 2 then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.25, function() ScanCurrentSlot((retryCount or 0) + 1) end)
                return
            end
        end

        if ok then
            pending.bySlot[definition.key] = sources or {}
            pending.slotDiagnostics[definition.key] = diagnostics or {}
            pending.totalSources = pending.totalSources + ((diagnostics and diagnostics.returnedSources) or 0)
            pending.totalVisuals = pending.totalVisuals + #(sources or {})
            pending.expectedCollectedVisuals = pending.expectedCollectedVisuals + ((diagnostics and diagnostics.expectedCollected) or 0)
        else
            pending.bySlot[definition.key] = {}
            pending.slotDiagnostics[definition.key] = { error = tostring(sources) }
            pending.scanError = tostring(sources)
        end

        if QC.Notify then
            QC.Notify(
                "WARDROBE_SCAN_PROGRESS",
                index,
                #Wardrobe.slotDefinitions,
                definition.key,
                #(pending.bySlot[definition.key] or {}),
                pending.slotDiagnostics[definition.key]
            )
        end

        index = index + 1
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() ScanCurrentSlot(0) end)
        else
            ScanCurrentSlot(0)
        end
    end

    local readyStarted = GetTime and GetTime() or 0
    local function WaitForCollectionReady()
        local searchType = GetSearchType()
        local dbLoading = SafeCall(C_TransmogCollection.IsSearchDBLoading) == true
        local searchRunning = SafeCall(C_TransmogCollection.IsSearchInProgress, searchType) == true
        if not dbLoading and not searchRunning then
            cache.scanState = "SCANNING"
            ScanCurrentSlot(0)
            return
        end

        local now = GetTime and GetTime() or readyStarted
        if now - readyStarted >= 12 then
            FinishFailure("WoW's wardrobe search database did not become ready within 12 seconds. Open the native Collections Wardrobe once, close it, and scan again.")
            return
        end

        if C_Timer and C_Timer.After then
            C_Timer.After(0.10, WaitForCollectionReady)
        else
            FinishFailure("WoW's wardrobe search database is still loading.")
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.10, WaitForCollectionReady)
    else
        WaitForCollectionReady()
    end
    return true, "Preparing WoW's wardrobe collection for scanning..."
end

function Wardrobe.SelectSource(slotKey, sourceID)
    local sources = Wardrobe.GetSlotSources(slotKey)
    for _, source in ipairs(sources) do
        if source.sourceID == sourceID then
            local valid, reason = Wardrobe.ValidateSource(source, slotKey)
            if not valid then
                return false, reason
            end
            EnsurePreviewState().selections[slotKey] = sourceID
            if QC.Notify then
                QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, source)
            end
            return true, reason
        end
    end
    return false, "The selected appearance is not present in the current cache."
end

function Wardrobe.ClearSelection(slotKey)
    EnsurePreviewState().selections[slotKey] = nil
    if QC.Notify then
        QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, nil)
    end
end

function Wardrobe.ClearAllSelections()
    EnsurePreviewState().selections = {}
    if QC.Notify then
        QC.Notify("WARDROBE_SELECTIONS_CLEARED")
    end
end

function Wardrobe.ApplyPreview(model)
    if not model then
        return false, "Preview model is unavailable."
    end

    SafeCall(model.SetUnit, model, "player")
    local applied = 0
    local state = EnsurePreviewState()
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local source = Wardrobe.GetSelectedSource(definition.key)
        if source then
            local valid = Wardrobe.ValidateSource(source, definition.key)
            if valid and source.itemID and model.TryOn then
                local ok = pcall(model.TryOn, model, source.itemID)
                if ok then
                    applied = applied + 1
                end
            end
        end
    end
    return true, string.format("Previewed %d selected appearances.", applied)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
eventFrame:RegisterEvent("TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        local cache = EnsureCache()
        EnsurePreviewState()
        local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
        if character and cache.characterKey and cache.characterKey ~= character.key then
            ResetCache(cache, "STALE")
            cache.dirtyReason = "CHARACTER_CHANGED"
        end
    else
        Wardrobe.MarkDirty(event)
    end
end)
