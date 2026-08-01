local QC = QuestChronicle

QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe

Wardrobe.CACHE_VERSION = 5
Wardrobe.PAGE_SIZE = 7

local AUTO_REFRESH_DELAY = 3.0
local AUTO_REFRESH_RETRY_DELAY = 2.0
local AUTO_REFRESH_MAX_ATTEMPTS = 15
local autoRefreshToken = 0
local internalUsabilityUpdateUntil
local pendingNativeOutfitSync
local NATIVE_OUTFIT_SYNC_TIMEOUT = 5.0

-- Resolve collection enum values when the scan runs instead of when this file loads.
-- Some Blizzard enum tables are not ready during early addon loading.
Wardrobe.slotDefinitions = {
    { key = "HEAD", label = "Head", slotName = "HEADSLOT", hideable = true, categoryNames = { "Head" }, fallbackCategoryIDs = { 1 } },
    { key = "SHOULDER", label = "Shoulders", slotName = "SHOULDERSLOT", categoryNames = { "Shoulder" }, fallbackCategoryIDs = { 2 } },
    { key = "BACK", label = "Back", slotName = "BACKSLOT", hideable = true, categoryNames = { "Back" }, fallbackCategoryIDs = { 3 } },
    { key = "CHEST", label = "Chest", slotName = "CHESTSLOT", categoryNames = { "Chest" }, fallbackCategoryIDs = { 4 } },
    { key = "SHIRT", label = "Shirt", slotName = "SHIRTSLOT", hideable = true, categoryNames = { "Shirt" }, fallbackCategoryIDs = { 5 } },
    { key = "TABARD", label = "Tabard", slotName = "TABARDSLOT", hideable = true, categoryNames = { "Tabard" }, fallbackCategoryIDs = { 6 } },
    { key = "WRIST", label = "Wrists", slotName = "WRISTSLOT", categoryNames = { "Wrist" }, fallbackCategoryIDs = { 7 } },
    { key = "HANDS", label = "Hands", slotName = "HANDSSLOT", categoryNames = { "Hands" }, fallbackCategoryIDs = { 8 } },
    { key = "WAIST", label = "Waist", slotName = "WAISTSLOT", categoryNames = { "Waist" }, fallbackCategoryIDs = { 9 } },
    { key = "LEGS", label = "Legs", slotName = "LEGSSLOT", categoryNames = { "Legs" }, fallbackCategoryIDs = { 10 } },
    { key = "FEET", label = "Feet", slotName = "FEETSLOT", categoryNames = { "Feet" }, fallbackCategoryIDs = { 11 } },
    {
        key = "ONE_HAND", label = "One-Hand", slotName = "MAINHANDSLOT", weaponRole = "ONE_HAND",
        categoryNames = { "Wand", "OneHAxe", "OneHSword", "OneHMace", "Dagger", "Fist", "Warglaives", "Paired" },
        fallbackCategoryIDs = { 12, 13, 14, 15, 16, 17, 28, 29 },
    },
    {
        key = "TWO_HAND", label = "Two-Hand", slotName = "MAINHANDSLOT", weaponRole = "TWO_HAND",
        categoryNames = { "TwoHAxe", "TwoHSword", "TwoHMace", "Staff", "Polearm" },
        fallbackCategoryIDs = { 20, 21, 22, 23, 24 },
    },
    {
        key = "RANGED", label = "Ranged", slotName = "MAINHANDSLOT", weaponRole = "RANGED",
        categoryNames = { "Bow", "Gun", "Crossbow" },
        fallbackCategoryIDs = { 25, 26, 27 },
    },
    {
        key = "OFF_HAND", label = "Off-Hand", slotName = "SECONDARYHANDSLOT", weaponRole = "OFF_HAND",
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

local function TryCall(func, ...)
    if type(func) ~= "function" then
        return false, "That Blizzard outfit function is unavailable."
    end
    local ok, a, b, c = pcall(func, ...)
    if not ok then
        return false, tostring(a or "Blizzard rejected the outfit request.")
    end
    return true, a, b, c
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
    cache.autoRefreshPending = false
end

local function EnsureCache()
    local database = QC.GetDatabase()
    database.wardrobe = database.wardrobe or {}
    local cache = database.wardrobe
    if cache.cacheVersion ~= Wardrobe.CACHE_VERSION then
        local previousCacheVersion = cache.cacheVersion
        ResetCache(cache, "STALE")
        cache.migratedFromCacheVersion = previousCacheVersion
        cache.dirtyReason = "VISUAL_IDENTITY_UPGRADE"
    end
    cache.bySlot = cache.bySlot or {}
    cache.slotDiagnostics = cache.slotDiagnostics or {}
    cache.scanState = cache.scanState or "NEVER"
    cache.totalSources = cache.totalSources or 0
    cache.totalVisuals = cache.totalVisuals or 0
    cache.expectedCollectedVisuals = cache.expectedCollectedVisuals or 0
    cache.autoRefreshPending = cache.autoRefreshPending == true
    return cache
end

local function EnsurePreviewState()
    local state = QC.GetUIState()
    state.outfits = state.outfits or {}
    state.outfits.selections = state.outfits.selections or {}
    state.outfits.selectionVisuals = state.outfits.selectionVisuals or {}
    state.outfits.selectedSlot = state.outfits.selectedSlot or "HEAD"
    state.outfits.pages = state.outfits.pages or {}
    state.outfits.locks = state.outfits.locks or {}
    state.outfits.hidden = state.outfits.hidden or {}
    return state.outfits
end

local function CopyPrimitiveMap(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
            copy[key] = value
        end
    end
    return copy
end

local function EnsureConceptStore()
    local cache = EnsureCache()
    cache.conceptsByCharacter = cache.conceptsByCharacter or {}
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
    local characterKey = character and character.key or "UNKNOWN"
    cache.conceptsByCharacter[characterKey] = cache.conceptsByCharacter[characterKey] or {}
    local store = cache.conceptsByCharacter[characterKey]
    for _, concept in pairs(store) do
        if concept.blizzardOutfitID ~= nil then
            concept.blizzardOutfitID = tonumber(concept.blizzardOutfitID)
        end
        if concept.blizzardSyncPendingAt and (not pendingNativeOutfitSync or pendingNativeOutfitSync.conceptID ~= concept.id) then
            concept.blizzardSyncPendingAt = nil
        end
    end
    return store, characterKey
end

local function NormalizePreferenceKey(value)
    local text = string.lower(tostring(value or "unknown-zone"))
    text = text:gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
    return text ~= "" and text or "unknown-zone"
end

local function GetZonePreferenceKey(context)
    context = context or (QC.ZoneStyle and QC.ZoneStyle.GetCurrentContext and QC.ZoneStyle.GetCurrentContext()) or {}
    return NormalizePreferenceKey(context.provenanceKey or context.zoneKey or context.profileKey or context.zone),
        tostring(context.provenanceLabel or context.zone or context.profileLabel or "Unknown Zone")
end

local function GetZonePreferenceStore(context, create)
    local cache = EnsureCache()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
    local characterKey = character and character.key or "UNKNOWN"
    local zoneKey, zoneLabel = GetZonePreferenceKey(context)
    if not cache.zonePreferencesByCharacter then
        if not create then return nil, zoneKey, zoneLabel end
        cache.zonePreferencesByCharacter = {}
    end
    if not cache.zonePreferencesByCharacter[characterKey] then
        if not create then return nil, zoneKey, zoneLabel end
        cache.zonePreferencesByCharacter[characterKey] = {}
    end
    local store = cache.zonePreferencesByCharacter[characterKey]
    if not store[zoneKey] then
        if not create then return nil, zoneKey, zoneLabel end
        store[zoneKey] = { favorites = {}, exclusions = {}, label = zoneLabel }
    end
    store[zoneKey].favorites = store[zoneKey].favorites or {}
    store[zoneKey].exclusions = store[zoneKey].exclusions or {}
    store[zoneKey].label = zoneLabel
    return store[zoneKey], zoneKey, zoneLabel
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
    if C_TransmogCollection and C_TransmogCollection.GetSourceItemID then
        local itemID = SafeCall(C_TransmogCollection.GetSourceItemID, sourceID)
        if itemID then
            return itemID
        end
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

    local function ExpandSourceIDs(candidateSources)
        if type(candidateSources) ~= "table" then
            return candidateSources
        end
        local expanded = {}
        for _, candidate in ipairs(candidateSources) do
            if type(candidate) == "number" then
                local source = GetSourceInfo(candidate)
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
    sources = ExpandSourceIDs(SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, transmogLocation))
    if (not sources or #sources == 0) and locationData then
        sources = ExpandSourceIDs(SafeCall(C_TransmogCollection.GetAppearanceSources, visualID, categoryID, locationData))
    end
    if (not sources or #sources == 0) and CollectionWardrobeUtil and type(CollectionWardrobeUtil.GetSortedAppearanceSources) == "function" then
        sources = ExpandSourceIDs(SafeCall(CollectionWardrobeUtil.GetSortedAppearanceSources, visualID, categoryID, transmogLocation))
    end

    if (not sources or #sources == 0) and C_TransmogCollection.GetValidAppearanceSourcesForClass then
        local classID = GetCurrentClassID()
        if classID then
            sources = ExpandSourceIDs(SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, transmogLocation))
            if (not sources or #sources == 0) and locationData then
                sources = ExpandSourceIDs(SafeCall(C_TransmogCollection.GetValidAppearanceSourcesForClass, visualID, classID, categoryID, locationData))
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

function Wardrobe.IsSlotLocked(slotKey)
    return EnsurePreviewState().locks[slotKey] == true
end

function Wardrobe.IsSlotHideable(slotKey)
    local definition = slotByKey[slotKey]
    return definition and definition.hideable == true or false
end

function Wardrobe.IsSlotHidden(slotKey)
    return Wardrobe.IsSlotHideable(slotKey) and EnsurePreviewState().hidden[slotKey] == true
end

function Wardrobe.SetSlotLocked(slotKey, locked)
    if not slotByKey[slotKey] then
        return false, "Unknown equipment slot."
    end
    local state = EnsurePreviewState()
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
    local state = EnsurePreviewState()
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

local function CopySourceForSlot(source, slotKey)
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

local function GetSourceByID(slotKey, sourceID)
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
        for _, source in ipairs(Wardrobe.GetSlotSources("ONE_HAND")) do
            if source.sourceID == sourceID then
                return CopySourceForSlot(source, "OFF_HAND")
            end
        end
    end
    return nil
end

local function FindSourceByVisualID(slotKey, visualID)
    if visualID == nil then return nil end
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        if source.visualID == visualID then return source end
    end
    if slotKey == "OFF_HAND" then
        for _, source in ipairs(Wardrobe.GetSlotSources("ONE_HAND")) do
            if source.visualID == visualID then return CopySourceForSlot(source, "OFF_HAND") end
        end
    end
    return nil
end

local function SetSelectedSource(state, slotKey, source)
    state.selectionVisuals = state.selectionVisuals or {}
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end

local function SnapshotSelectionVisuals(selections, previousVisuals)
    local visuals = {}
    for slotKey, sourceID in pairs(selections or {}) do
        local source = GetSourceByID(slotKey, sourceID)
        local visualID = source and source.visualID or (previousVisuals and previousVisuals[slotKey])
        if visualID ~= nil then visuals[slotKey] = visualID end
    end
    return visuals
end

local function CaptureRecoveryIdentities()
    local state = EnsurePreviewState()
    state.selectionVisuals = SnapshotSelectionVisuals(state.selections, state.selectionVisuals)
    local concepts = EnsureConceptStore()
    for _, concept in pairs(concepts) do
        concept.visuals = SnapshotSelectionVisuals(concept.selections, concept.visuals)
    end
end

local function RebindSelectionMap(selections, visuals, preserveMissing)
    local rebound, reboundVisuals = {}, {}
    local recovered, missing = 0, 0
    for slotKey, sourceID in pairs(selections or {}) do
        local source = GetSourceByID(slotKey, sourceID)
        local valid = source and Wardrobe.ValidateSource(source, slotKey)
        local visualID = source and source.visualID or (visuals and visuals[slotKey])
        if not valid and visualID ~= nil then
            local replacement = FindSourceByVisualID(slotKey, visualID)
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

local function RecoverAppearanceReferences(cache)
    local settings = QC.GetSettings and QC.GetSettings() or {}
    if settings.recoverMissingAppearances == false then
        return 0, 0, 0
    end

    local state = EnsurePreviewState()
    local selections, visuals, previewRecovered, previewMissing = RebindSelectionMap(state.selections, state.selectionVisuals, false)
    state.selections = selections
    state.selectionVisuals = visuals

    local concepts = EnsureConceptStore()
    local conceptRecovered, conceptMissing = 0, 0
    for _, concept in pairs(concepts) do
        local rebound, reboundVisuals, recovered, missing = RebindSelectionMap(concept.selections, concept.visuals, true)
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

local function GetSourcePreferenceIdentity(source)
    if not source then return nil end
    if source.visualID then return "visual:" .. tostring(source.visualID) end
    if source.sourceID then return "source:" .. tostring(source.sourceID) end
    if source.itemID then return "item:" .. tostring(source.itemID) end
end

function Wardrobe.GetZonePreferenceKey(context)
    return GetZonePreferenceKey(context)
end

function Wardrobe.GetSourceZonePreference(source, context)
    local identity = GetSourcePreferenceIdentity(source)
    if not identity then return nil end
    local preferences = GetZonePreferenceStore(context, false)
    if not preferences then return nil end
    if preferences.exclusions[identity] then return "excluded" end
    if preferences.favorites[identity] then return "favorite" end
end

function Wardrobe.SetSourceZonePreference(source, preference, context)
    local identity = GetSourcePreferenceIdentity(source)
    if not identity then return false, "That appearance has no stable visual identity." end
    if preference ~= nil and preference ~= "favorite" and preference ~= "excluded" then
        return false, "Unknown zone preference."
    end

    local preferences, _, zoneLabel = GetZonePreferenceStore(context, true)
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
    local source = GetSourceByID(slotKey, sourceID)
    if not source then return false, "Select a cached appearance first." end
    local current = Wardrobe.GetSourceZonePreference(source, context)
    if current == "favorite" then
        return Wardrobe.SetSourceZonePreference(source, nil, context)
    end
    return Wardrobe.SetSourceZonePreference(source, "favorite", context)
end

function Wardrobe.ToggleZoneExclusion(slotKey, sourceID, context)
    local source = GetSourceByID(slotKey, sourceID)
    if not source then return false, "Select a cached appearance first." end
    local current = Wardrobe.GetSourceZonePreference(source, context)
    if current == "excluded" then
        return Wardrobe.SetSourceZonePreference(source, nil, context)
    end
    return Wardrobe.SetSourceZonePreference(source, "excluded", context)
end

function Wardrobe.GetZonePreferenceSummary(context)
    local preferences, _, zoneLabel = GetZonePreferenceStore(context, false)
    if not preferences then return 0, 0, zoneLabel end
    local favorites, exclusions = 0, 0
    for _, value in pairs(preferences.favorites) do if value then favorites = favorites + 1 end end
    for _, value in pairs(preferences.exclusions) do if value then exclusions = exclusions + 1 end end
    return favorites, exclusions, zoneLabel
end

local function GetSelectedSources(state)
    local sources = {}
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        if state.selections[definition.key] and not state.hidden[definition.key] then
            local source = GetSourceByID(definition.key, state.selections[definition.key])
            if source then table.insert(sources, source) end
        end
    end
    return sources
end

local function RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if not styleEngine or not styleEngine.GenerateOutfitName then return nil end
    state.generatedName = styleEngine.GenerateOutfitName(styleMode, styleContext, GetSelectedSources(state))
    state.generatedAt = time and time() or 0
    return state.generatedName
end

function Wardrobe.GetGeneratedOutfitName()
    return EnsurePreviewState().generatedName
end

local function ClearWeaponSlot(state, slotKey)
    SetSelectedSource(state, slotKey, nil)
    state.locks[slotKey] = nil
    state.hidden[slotKey] = nil
end

local function ApplyWeaponSelectionRules(state, slotKey)
    if slotKey == "ONE_HAND" then
        ClearWeaponSlot(state, "TWO_HAND")
        ClearWeaponSlot(state, "RANGED")
    elseif slotKey == "TWO_HAND" then
        ClearWeaponSlot(state, "ONE_HAND")
        ClearWeaponSlot(state, "RANGED")
        ClearWeaponSlot(state, "OFF_HAND")
    elseif slotKey == "RANGED" then
        ClearWeaponSlot(state, "ONE_HAND")
        ClearWeaponSlot(state, "TWO_HAND")
        ClearWeaponSlot(state, "OFF_HAND")
    elseif slotKey == "OFF_HAND" then
        ClearWeaponSlot(state, "TWO_HAND")
        ClearWeaponSlot(state, "RANGED")
    end
end

local function ChooseRandomSource(slotKey, excludeSourceID, styleMode, styleContext)
    local candidates = {}
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        local valid = Wardrobe.ValidateSource(source, slotKey)
        if valid then
            table.insert(candidates, source)
        end
    end
    if #candidates == 0 then
        return nil
    end

    local styleEngine = QC.ZoneStyle
    if styleEngine and styleEngine.ChooseWeightedSource then
        return styleEngine.ChooseWeightedSource(candidates, slotByKey[slotKey], styleMode, styleContext, excludeSourceID)
    end

    local available = {}
    local fallback
    for _, source in ipairs(candidates) do
        if source.sourceID == excludeSourceID then
            fallback = source
        else
            table.insert(available, source)
        end
    end
    if #available == 0 then return fallback end
    return available[math.random(1, #available)]
end

local function SetRandomSelection(state, slotKey, reroll, styleMode, styleContext)
    local current = reroll and state.selections[slotKey] or nil
    local source = ChooseRandomSource(slotKey, current, styleMode, styleContext)
    if not source then
        if not reroll then SetSelectedSource(state, slotKey, nil) end
        return false
    end
    SetSelectedSource(state, slotKey, source)
    if not state.hidden[slotKey] and QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then
        QC.ZoneStyle.AddSourceToGenerationContext(styleContext, source)
    end
    return true
end

local MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }
local ARMOR_GENERATION_ORDER = { "CHEST", "SHOULDER", "LEGS", "WAIST", "HEAD", "HANDS", "FEET", "WRIST", "BACK", "SHIRT", "TABARD" }

local function CreateStyleGenerationContext(state, styleEngine, baseContext, excludedSlotKey, lockedOnly)
    if not styleEngine then return baseContext end
    local context = styleEngine.CreateGenerationContext and styleEngine.CreateGenerationContext(baseContext) or baseContext
    if not context or not styleEngine.AddSourceToGenerationContext then return context end

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local slotKey = definition.key
        local shouldSeed = slotKey ~= excludedSlotKey
            and state.selections[slotKey] ~= nil
            and state.hidden[slotKey] ~= true
            and (not lockedOnly or state.locks[slotKey] == true)
        if shouldSeed then
            styleEngine.AddSourceToGenerationContext(context, GetSourceByID(slotKey, state.selections[slotKey]))
        end
    end
    return context
end

local function GetEquippedItemInfo(slotName)
    local slotID = SafeCall(GetInventorySlotInfo, slotName)
    if not slotID then
        return nil
    end
    local itemLink = SafeCall(GetInventoryItemLink, "player", slotID)
    if itemLink then
        return itemLink
    end
    return SafeCall(GetInventoryItemID, "player", slotID)
end

local function CreateWeaponGenerationContext()
    local now = GetTime and GetTime()
    internalUsabilityUpdateUntil = now and (now + 1.0) or nil
    SafeCall(C_TransmogCollection and C_TransmogCollection.UpdateUsableAppearances)
    return {
        mainItem = GetEquippedItemInfo("MAINHANDSLOT"),
        offItem = GetEquippedItemInfo("SECONDARYHANDSLOT"),
        appearancesByCategory = {},
        locationsBySlot = {},
        validation = {},
    }
end

local function GetGenerationLocation(definition, context)
    local slotName = definition.slotName
    if context.locationsBySlot[slotName] == nil then
        context.locationsBySlot[slotName] = GetTransmogLocation(definition) or false
    end
    local location = context.locationsBySlot[slotName]
    return location ~= false and location or nil
end

local function GetGenerationAppearance(source, definition, context)
    local categoryID = source and source.categoryID
    if not categoryID then
        return nil
    end
    local key = tostring(definition.slotName) .. ":" .. tostring(categoryID)
    local indexed = context.appearancesByCategory[key]
    if not indexed then
        indexed = {}
        local location = GetGenerationLocation(definition, context)
        local appearances = GetCategoryAppearancesRobust(categoryID, location)
        for _, appearance in ipairs(appearances or {}) do
            if appearance.visualID then
                indexed[appearance.visualID] = appearance
            end
        end
        context.appearancesByCategory[key] = indexed
    end
    return indexed[source.visualID]
end

local function ValidateGeneratedWeaponSource(source, slotKey, equippedItem, context)
    local definition = slotByKey[slotKey]
    local cacheKey = table.concat({ tostring(slotKey), tostring(source and source.sourceID), tostring(equippedItem) }, ":")
    local cached = context.validation[cacheKey]
    if cached then
        return cached.valid, cached.reason
    end

    local function Finish(valid, reason)
        context.validation[cacheKey] = { valid = valid, reason = reason }
        return valid, reason
    end

    local basicValid, basicReason = Wardrobe.ValidateSource(source, slotKey)
    if not basicValid then
        return Finish(false, basicReason)
    end
    if not equippedItem then
        return Finish(false, slotKey == "OFF_HAND" and "No off-hand item is equipped." or "No main-hand item is equipped.")
    end
    if not source.categoryID then
        return Finish(false, "This cached weapon appearance has no collection category. Rescan the collection.")
    end
    if not C_TransmogCollection or type(C_TransmogCollection.IsCategoryValidForItem) ~= "function" then
        return Finish(false, "WoW's equipped-item transmog compatibility check is unavailable.")
    end
    if SafeCall(C_TransmogCollection.IsCategoryValidForItem, source.categoryID, equippedItem) ~= true then
        return Finish(false, "That appearance category cannot transmogrify the currently equipped item.")
    end

    -- Requery the collapsed visual with the equipped hand's transmog location.
    -- The scanner intentionally keeps a broad preview catalog; generation is
    -- stricter and requires Blizzard to mark the visual collected, displayable,
    -- and usable for the character right now.
    local appearance = GetGenerationAppearance(source, definition, context)
    if not appearance or appearance.isCollected ~= true then
        return Finish(false, "WoW no longer reports this weapon visual as collected.")
    end
    if appearance.canDisplayOnPlayer ~= true then
        return Finish(false, "This character cannot display that weapon visual.")
    end
    if appearance.isUsable ~= true then
        return Finish(false, "WoW does not currently mark that weapon visual as usable.")
    end

    -- Source detail is an additional guard. isAnySourceValidForPlayer avoids
    -- rejecting an account-unlocked visual merely because the cache's chosen
    -- preview representative is not the source this character would use.
    local appearanceInfo = SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, source.sourceID)
    if appearanceInfo then
        if appearanceInfo.appearanceIsCollected ~= true or appearanceInfo.appearanceIsUsable ~= true then
            return Finish(false, "The collected appearance is not currently usable for transmogrification.")
        end
        if appearanceInfo.canDisplayOnPlayer ~= true or appearanceInfo.isAnySourceValidForPlayer ~= true then
            return Finish(false, "No source for this visual is valid for the current character.")
        end
    elseif type(C_TransmogCollection.GetValidAppearanceSourcesForClass) == "function" then
        local classID = GetCurrentClassID()
        local location = GetGenerationLocation(definition, context)
        local validSources = classID and SafeCall(
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

    return Finish(true, "Compatible with the equipped item")
end

local function Shuffle(values)
    for index = #values, 2, -1 do
        local other = math.random(1, index)
        values[index], values[other] = values[other], values[index]
    end
end

local function ChooseGeneratedWeaponSource(slotKeys, equippedItem, context, excludedBySlot, targetSlotKey, styleMode, styleContext)
    local candidates = {}
    for _, slotKey in ipairs(slotKeys) do
        for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
            local validationSlotKey = targetSlotKey or slotKey
            local candidateSource = CopySourceForSlot(source, validationSlotKey)
            local basicValid = Wardrobe.ValidateSource(candidateSource, validationSlotKey)
            local categoryValid = equippedItem and candidateSource.categoryID and SafeCall(
                C_TransmogCollection and C_TransmogCollection.IsCategoryValidForItem,
                candidateSource.categoryID,
                equippedItem
            ) == true
            if basicValid and categoryValid then
                table.insert(candidates, { source = candidateSource, slotKey = validationSlotKey })
            end
        end
    end
    if QC.ZoneStyle and QC.ZoneStyle.OrderWeaponCandidates then
        QC.ZoneStyle.OrderWeaponCandidates(candidates, styleMode, styleContext)
    else
        Shuffle(candidates)
    end

    local fallback
    for _, candidate in ipairs(candidates) do
        local valid = ValidateGeneratedWeaponSource(candidate.source, candidate.slotKey, equippedItem, context)
        if valid then
            if excludedBySlot and excludedBySlot[candidate.slotKey] == candidate.source.sourceID then
                fallback = fallback or candidate
            else
                return candidate.source, candidate.slotKey
            end
        end
    end
    if fallback then
        return fallback.source, fallback.slotKey
    end
    return nil
end

local function GetLockedWeaponMode(state)
    local lockedMode
    for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
        if state.locks[slotKey] and state.selections[slotKey] then
            if lockedMode then
                return nil, "Unlock one of the conflicting main-hand weapon slots first."
            end
            lockedMode = slotKey
        end
    end
    if state.locks.OFF_HAND and state.selections.OFF_HAND then
        if lockedMode and lockedMode ~= "ONE_HAND" then
            return nil, "The locked off-hand conflicts with the locked two-hand or ranged weapon."
        end
        lockedMode = "ONE_HAND"
    end
    return lockedMode
end

local function GenerateWeapons(state, reroll, styleMode, styleContext)
    local mode, errorMessage = GetLockedWeaponMode(state)
    if errorMessage then
        return false, errorMessage
    end
    local context = CreateWeaponGenerationContext()
    local lockedMainSource

    if not context.mainItem then
        for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
            if state.locks[slotKey] and state.selections[slotKey] then
                return false, "A main-hand weapon appearance is locked, but no main-hand item is equipped. Equip a weapon or unlock that slot."
            end
            SetSelectedSource(state, slotKey, nil)
        end
        if state.locks.OFF_HAND and state.selections.OFF_HAND then
            return false, "An off-hand appearance is locked, but no main-hand item is equipped. Equip your weapons or unlock the slot."
        end
        SetSelectedSource(state, "OFF_HAND", nil)
        return true, 0, "No main-hand item is equipped, so Quest Chronicle generated armor only."
    end

    if mode and state.locks[mode] and state.selections[mode] then
        lockedMainSource = GetSourceByID(mode, state.selections[mode])
        local valid, reason = ValidateGeneratedWeaponSource(lockedMainSource, mode, context.mainItem, context)
        if not valid then
            return false, string.format("The locked %s appearance is not valid for the equipped main-hand item: %s Unlock it or equip a compatible weapon.", slotByKey[mode].label, reason or "incompatible")
        end
    end
    if state.locks.OFF_HAND and state.selections.OFF_HAND then
        local lockedOffHand = GetSourceByID("OFF_HAND", state.selections.OFF_HAND)
        local valid, reason = ValidateGeneratedWeaponSource(lockedOffHand, "OFF_HAND", context.offItem, context)
        if not valid then
            return false, string.format("The locked Off-Hand appearance is not valid for the equipped off-hand item: %s Unlock it or equip a compatible item.", reason or "incompatible")
        end
    end

    local selectedMain
    if lockedMainSource then
        selectedMain = lockedMainSource
    else
        local allowedSlots = mode and { mode } or MAIN_WEAPON_SLOT_KEYS
        local excluded = {}
        if reroll then
            for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
                excluded[slotKey] = state.selections[slotKey]
            end
        end
        selectedMain, mode = ChooseGeneratedWeaponSource(allowedSlots, context.mainItem, context, excluded, nil, styleMode, styleContext)
        if selectedMain then
            SetSelectedSource(state, mode, selectedMain)
        end
    end

    for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
        if slotKey ~= mode and not state.locks[slotKey] then
            SetSelectedSource(state, slotKey, nil)
        end
    end
    if not selectedMain then
        for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
            if not state.locks[slotKey] then
                SetSelectedSource(state, slotKey, nil)
            end
        end
        if not state.locks.OFF_HAND then
            SetSelectedSource(state, "OFF_HAND", nil)
        end
        return true, 0, "WoW found no cached weapon visual valid for the equipped main-hand item; armor was generated and the equipped weapon was left unchanged."
    end

    if QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then
        QC.ZoneStyle.AddSourceToGenerationContext(styleContext, selectedMain)
    end

    local selectedWeapons = 1
    local notice
    if mode == "ONE_HAND" and context.offItem then
        if state.locks.OFF_HAND and state.selections.OFF_HAND then
            selectedWeapons = selectedWeapons + 1
        elseif not state.locks.OFF_HAND then
            local excluded = reroll and { OFF_HAND = state.selections.OFF_HAND } or nil
            local offHand = ChooseGeneratedWeaponSource({ "OFF_HAND", "ONE_HAND" }, context.offItem, context, excluded, "OFF_HAND", styleMode, styleContext)
            SetSelectedSource(state, "OFF_HAND", offHand)
            if offHand then
                if QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then
                    QC.ZoneStyle.AddSourceToGenerationContext(styleContext, offHand)
                end
                selectedWeapons = selectedWeapons + 1
            else
                notice = "No cached Off-Hand visual matched the equipped off-hand item, so its current appearance was left unchanged."
            end
        end
    elseif not state.locks.OFF_HAND then
        SetSelectedSource(state, "OFF_HAND", nil)
    end

    return true, selectedWeapons, notice
end

function Wardrobe.GenerateOutfit(reroll, requestedStyleMode)
    local cache = EnsureCache()
    if cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS" then
        return false, "Scan the wardrobe collection before generating an outfit."
    end

    local state = EnsurePreviewState()
    local styleEngine = QC.ZoneStyle
    local styleMode = requestedStyleMode or state.styleMode
    local styleContext
    if styleEngine then
        styleMode = styleEngine.NormalizeMode(styleMode)
        state.styleMode = styleMode
        styleContext = CreateStyleGenerationContext(state, styleEngine, styleEngine.GetCurrentContext(), nil, true)
    end

    local originalSelections = CopyPrimitiveMap(state.selections)
    local originalVisuals = CopyPrimitiveMap(state.selectionVisuals)
    local selected = 0
    for _, slotKey in ipairs(ARMOR_GENERATION_ORDER) do
        local definition = slotByKey[slotKey]
        if definition and not state.locks[slotKey] then
            if SetRandomSelection(state, slotKey, reroll == true, styleMode, styleContext) then
                selected = selected + 1
            end
        end
    end

    -- Build around the large armor silhouettes first, then let weapons reinforce
    -- that established set/motif. If a locked weapon is invalid, restore the
    -- previous preview rather than leaving a partially regenerated outfit.
    local weaponsOK, weaponCount, weaponNotice = GenerateWeapons(state, reroll == true, styleMode, styleContext)
    if not weaponsOK then
        state.selections = originalSelections
        state.selectionVisuals = originalVisuals
        return false, weaponCount
    end

    state.selectedConceptID = nil
    local generatedName = RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
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
    local definition = slotByKey[slotKey]
    if not definition then
        return false, "Unknown equipment slot."
    end
    if Wardrobe.IsSlotLocked(slotKey) then
        return false, "Unlock this slot before rerolling it."
    end

    local state = EnsurePreviewState()
    local styleEngine = QC.ZoneStyle
    local styleMode = styleEngine and styleEngine.NormalizeMode(state.styleMode) or state.styleMode
    local styleContext = styleEngine and CreateStyleGenerationContext(state, styleEngine, styleEngine.GetCurrentContext(), slotKey, false) or nil
    if definition.weaponRole then
        local context = CreateWeaponGenerationContext()
        local equippedItem = slotKey == "OFF_HAND" and context.offItem or context.mainItem
        local sourceSlots = slotKey == "OFF_HAND" and { "OFF_HAND", "ONE_HAND" } or { slotKey }
        local source = ChooseGeneratedWeaponSource(sourceSlots, equippedItem, context, { [slotKey] = state.selections[slotKey] }, slotKey, styleMode, styleContext)
        if not source then
            return false, "No cached appearance in this weapon category is valid for the currently equipped item."
        end
        SetSelectedSource(state, slotKey, source)
        if styleEngine and styleEngine.AddSourceToGenerationContext then
            styleEngine.AddSourceToGenerationContext(styleContext, source)
        end
        ApplyWeaponSelectionRules(state, slotKey)
        if slotKey == "OFF_HAND" and not state.selections.ONE_HAND then
            local mainHand = ChooseGeneratedWeaponSource({ "ONE_HAND" }, context.mainItem, context, nil, nil, styleMode, styleContext)
            if mainHand then
                SetSelectedSource(state, "ONE_HAND", mainHand)
                if styleEngine and styleEngine.AddSourceToGenerationContext then
                    styleEngine.AddSourceToGenerationContext(styleContext, mainHand)
                end
            end
        end
    elseif not SetRandomSelection(state, slotKey, true, styleMode, styleContext) then
        return false, "No compatible appearance is cached for this slot."
    end
    state.selectedConceptID = nil
    local generatedName = RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if QC.Notify then
        QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey)
    end
    return true, string.format("%s rerolled%s.", definition.label, generatedName and ("; the current look is now " .. generatedName) or "")
end

function Wardrobe.GetConcepts()
    local store = EnsureConceptStore()
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
    local state = EnsurePreviewState()
    if not state.selectedConceptID then
        return nil
    end
    local store = EnsureConceptStore()
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

    local store, characterKey = EnsureConceptStore()
    local state = EnsurePreviewState()
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
    concept.selections = CopyPrimitiveMap(state.selections)
    state.selectionVisuals = SnapshotSelectionVisuals(state.selections, state.selectionVisuals)
    concept.visuals = CopyPrimitiveMap(state.selectionVisuals)
    concept.locks = CopyPrimitiveMap(state.locks)
    concept.hidden = CopyPrimitiveMap(state.hidden)
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
    local store = EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then
        return false, "That outfit concept is no longer available."
    end

    local state = EnsurePreviewState()
    local selections, visuals, recovered, missing = RebindSelectionMap(concept.selections, concept.visuals, false)
    state.selections = selections
    state.selectionVisuals = visuals
    state.locks = CopyPrimitiveMap(concept.locks)
    state.hidden = CopyPrimitiveMap(concept.hidden)
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

function Wardrobe.DeleteConcept(conceptID)
    local store = EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then
        return false, "That outfit concept is no longer available."
    end
    store[conceptID] = nil
    local state = EnsurePreviewState()
    if state.selectedConceptID == conceptID then
        state.selectedConceptID = nil
    end
    if QC.Notify then
        QC.Notify("WARDROBE_CONCEPTS_CHANGED")
    end
    return true, "Deleted outfit concept: " .. tostring(concept.name or "Unnamed")
end

local NATIVE_SLOT_FALLBACKS = {
    HEAD = 0,
    SHOULDER = 1,
    BACK = 3,
    CHEST = 4,
    TABARD = 5,
    SHIRT = 6,
    WRIST = 7,
    HANDS = 8,
    WAIST = 9,
    LEGS = 10,
    FEET = 11,
    MAIN_HAND = 12,
    OFF_HAND = 13,
}

local function NativeEnum(groupName, valueName, fallback)
    local group = Enum and Enum[groupName]
    local value = group and group[valueName]
    if value == nil then return fallback end
    return value
end

local function GetNativeOutfitSlot(definition)
    if definition and definition.slotName and C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot then
        local inventorySlot = SafeCall(GetInventorySlotInfo, definition.slotName)
        local nativeSlot = inventorySlot and SafeCall(C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot, inventorySlot)
        if nativeSlot ~= nil then return nativeSlot end
    end
    return definition and NATIVE_SLOT_FALLBACKS[definition.key]
end

local function GetConceptSource(concept, slotKey)
    return concept and GetSourceByID(slotKey, concept.selections and concept.selections[slotKey]) or nil
end

local function GetConceptVisualID(concept, slotKey)
    local visualID = concept and concept.visuals and concept.visuals[slotKey]
    if visualID then return tonumber(visualID) end
    local source = GetConceptSource(concept, slotKey)
    return source and tonumber(source.visualID) or nil
end

local function GetConceptOutfitIcon(concept)
    for _, slotKey in ipairs({ "HEAD", "CHEST", "SHOULDER", "TWO_HAND", "ONE_HAND", "RANGED", "BACK" }) do
        local source = GetConceptSource(concept, slotKey)
        if source and tonumber(source.icon) then return tonumber(source.icon) end
    end
    return 134938 -- INV_Misc_Book_09
end

local function GetNativeOutfitInfo(outfitID)
    if not outfitID or not C_TransmogOutfitInfo then return nil end
    return SafeCall(C_TransmogOutfitInfo.GetOutfitInfo, tonumber(outfitID))
end

local function ResolveWeaponOption(slotKey, source)
    if slotKey == "TWO_HAND" then
        return NativeEnum("TransmogOutfitSlotOption", "TwoHandedWeapon", 2)
    elseif slotKey == "RANGED" then
        return NativeEnum("TransmogOutfitSlotOption", "RangedWeapon", 3)
    elseif slotKey == "OFF_HAND" then
        if source and tonumber(source.categoryID) == 18 then
            return NativeEnum("TransmogOutfitSlotOption", "Shield", 5)
        elseif source and tonumber(source.categoryID) == 19 then
            return NativeEnum("TransmogOutfitSlotOption", "OffHand", 4)
        end
        return NativeEnum("TransmogOutfitSlotOption", "OneHandedWeapon", 1)
    elseif source and tonumber(source.categoryID) == 16 then
        return NativeEnum("TransmogOutfitSlotOption", "DeprecatedReuseMe", 6)
    end
    return NativeEnum("TransmogOutfitSlotOption", "OneHandedWeapon", 1)
end

local function FinishNativeOutfitSync(success, message, outfitID)
    local request = pendingNativeOutfitSync
    if not request then return end
    local store = EnsureConceptStore()
    local concept = store[request.conceptID]
    if concept then
        concept.blizzardSyncPendingAt = nil
        if success and outfitID then
            concept.blizzardOutfitID = tonumber(outfitID)
            concept.blizzardOutfitName = request.name
            concept.blizzardOutfitIcon = request.icon
            concept.blizzardSyncedAt = time()
            concept.blizzardSyncError = nil
        elseif not success then
            concept.blizzardSyncError = message
        end
    end
    pendingNativeOutfitSync = nil
    if QC.Notify then
        QC.Notify("WARDROBE_NATIVE_OUTFIT_SYNCED", concept, success, message)
        QC.Notify("WARDROBE_CONCEPTS_CHANGED", concept)
    end
end

local function FindNativeOutfitByName(name)
    local info = SafeCall(C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetOutfitInfoByName, name)
    if info and info.outfitID then return info end
    for _, candidate in ipairs(SafeCall(C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetOutfitsInfo) or {}) do
        if string.lower(candidate.name or "") == string.lower(name or "") then return candidate end
    end
    return nil
end

local function SetNativePending(slot, option, transmogID, displayType)
    local appearanceType = NativeEnum("TransmogType", "Appearance", 0)
    return TryCall(
        C_TransmogOutfitInfo and C_TransmogOutfitInfo.SetPendingTransmog,
        slot,
        appearanceType,
        option,
        tonumber(transmogID) or 0,
        displayType
    )
end

local function StageNativeOutfitSync()
    local request = pendingNativeOutfitSync
    if not request or request.phase ~= "WAITING_VIEW" then return end
    if request.outfitID and C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID then
        local viewedOutfitID = SafeCall(C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID)
        if viewedOutfitID and tonumber(viewedOutfitID) ~= tonumber(request.outfitID) then return end
    end
    local store = EnsureConceptStore()
    local concept = store[request.conceptID]
    if not concept then
        FinishNativeOutfitSync(false, "That outfit concept is no longer available.")
        return
    end

    request.phase = "STAGING"
    local equippedDisplay = NativeEnum("TransmogOutfitDisplayType", "Equipped", 2)
    local assignedDisplay = NativeEnum("TransmogOutfitDisplayType", "Assigned", 1)
    local hiddenDisplay = NativeEnum("TransmogOutfitDisplayType", "Hidden", 3)
    local noOption = NativeEnum("TransmogOutfitSlotOption", "None", 0)
    local ok, failure = TryCall(C_TransmogOutfitInfo and C_TransmogOutfitInfo.ClearAllPendingTransmogs)
    if not ok then
        FinishNativeOutfitSync(false, "Blizzard could not clear the outfit editor: " .. tostring(failure))
        return
    end

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        if not definition.weaponRole then
            local nativeSlot = GetNativeOutfitSlot(definition)
            if nativeSlot ~= nil then
                local visualID = GetConceptVisualID(concept, definition.key)
                local hidden = concept.hidden and concept.hidden[definition.key] and definition.hideable
                local displayType = hidden and hiddenDisplay or (visualID and assignedDisplay or equippedDisplay)
                ok, failure = SetNativePending(nativeSlot, noOption, visualID or 0, displayType)
                if not ok then
                    FinishNativeOutfitSync(false, string.format("Blizzard rejected the %s slot: %s", definition.label, tostring(failure)))
                    return
                end
                if definition.key == "SHOULDER" and C_TransmogOutfitInfo.SetSecondarySlotState then
                    TryCall(C_TransmogOutfitInfo.SetSecondarySlotState, nativeSlot, false)
                end
            end
        end
    end

    local mainKey = concept.selections and (concept.selections.TWO_HAND and "TWO_HAND" or (concept.selections.RANGED and "RANGED" or (concept.selections.ONE_HAND and "ONE_HAND")))
    if mainKey then
        local source = GetConceptSource(concept, mainKey)
        local visualID = GetConceptVisualID(concept, mainKey)
        local definition = slotByKey[mainKey]
        local nativeSlot = GetNativeOutfitSlot(definition) or NATIVE_SLOT_FALLBACKS.MAIN_HAND
        local option = ResolveWeaponOption(mainKey, source)
        if C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot then
            ok, failure = TryCall(C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot, nativeSlot, option)
            if not ok then
                FinishNativeOutfitSync(false, "Blizzard rejected the main-hand weapon mode: " .. tostring(failure))
                return
            end
        end
        ok, failure = SetNativePending(nativeSlot, option, visualID or 0, visualID and assignedDisplay or equippedDisplay)
        if not ok then
            FinishNativeOutfitSync(false, "Blizzard rejected the main-hand appearance: " .. tostring(failure))
            return
        end
    end

    if concept.selections and concept.selections.OFF_HAND then
        local source = GetConceptSource(concept, "OFF_HAND")
        local visualID = GetConceptVisualID(concept, "OFF_HAND")
        local definition = slotByKey.OFF_HAND
        local nativeSlot = GetNativeOutfitSlot(definition) or NATIVE_SLOT_FALLBACKS.OFF_HAND
        local option = ResolveWeaponOption("OFF_HAND", source)
        if C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot then
            ok, failure = TryCall(C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot, nativeSlot, option)
            if not ok then
                FinishNativeOutfitSync(false, "Blizzard rejected the off-hand weapon mode: " .. tostring(failure))
                return
            end
        end
        ok, failure = SetNativePending(nativeSlot, option, visualID or 0, visualID and assignedDisplay or equippedDisplay)
        if not ok then
            FinishNativeOutfitSync(false, "Blizzard rejected the off-hand appearance: " .. tostring(failure))
            return
        end
    end

    request.phase = "WAITING_CONFIRM"
    if request.outfitID then
        ok, failure = TryCall(C_TransmogOutfitInfo.CommitOutfitInfo, request.outfitID, request.name, request.icon)
    else
        ok, failure = TryCall(C_TransmogOutfitInfo.AddNewOutfit, request.name, request.icon)
    end
    if not ok then
        FinishNativeOutfitSync(false, "Blizzard could not save the outfit: " .. tostring(failure))
        return
    end

    if pendingNativeOutfitSync and C_Timer and C_Timer.After then
        local requestToken = request.token
        C_Timer.After(NATIVE_OUTFIT_SYNC_TIMEOUT, function()
            if pendingNativeOutfitSync and pendingNativeOutfitSync.token == requestToken then
                local info = FindNativeOutfitByName(request.name)
                if info and info.outfitID then
                    FinishNativeOutfitSync(true, "Saved to a World of Warcraft outfit slot.", info.outfitID)
                else
                    FinishNativeOutfitSync(false, "World of Warcraft did not confirm the outfit save. Check the native outfit limit and try again.")
                end
            end
        end)
    end
end

function Wardrobe.IsNativeOutfitSavingSupported()
    return C_TransmogOutfitInfo
        and type(C_TransmogOutfitInfo.SetPendingTransmog) == "function"
        and type(C_TransmogOutfitInfo.AddNewOutfit) == "function"
        and type(C_TransmogOutfitInfo.CommitOutfitInfo) == "function"
end

function Wardrobe.GetConceptNativeOutfitStatus(concept)
    if not concept then return "local", "Quest Chronicle only" end
    if pendingNativeOutfitSync and pendingNativeOutfitSync.conceptID == concept.id then
        return "pending", "Saving to WoW..."
    end
    if concept.blizzardOutfitID then
        local info = GetNativeOutfitInfo(concept.blizzardOutfitID)
        if info then
            return "synced", "WoW Outfit " .. tostring(info.playerFacingOutfitIndex or info.outfitID)
        end
        return "missing", "WoW outfit missing"
    end
    if concept.blizzardSyncError then return "error", "WoW save failed" end
    return "local", "Quest Chronicle only"
end

function Wardrobe.SaveConceptToBlizzard(conceptID)
    LoadTransmogSupport()
    if not Wardrobe.IsNativeOutfitSavingSupported() then
        return false, "World of Warcraft's native outfit-saving API is unavailable on this client."
    end
    if pendingNativeOutfitSync then
        return false, "Another outfit is still being saved. Wait for World of Warcraft to confirm it."
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Native outfits cannot be changed during combat."
    end

    local store = EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then return false, "That outfit concept is no longer available." end
    local name = tostring(concept.name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return false, "Give the concept a name before saving it to WoW." end
    if C_TransmogOutfitInfo.IsValidTransmogOutfitName and SafeCall(C_TransmogOutfitInfo.IsValidTransmogOutfitName, name) ~= true then
        return false, "World of Warcraft does not allow that outfit name. Rename the concept and try again."
    end

    local outfitID = tonumber(concept.blizzardOutfitID)
    if outfitID and not GetNativeOutfitInfo(outfitID) then
        concept.blizzardOutfitID = nil
        outfitID = nil
    end
    local now = time()
    pendingNativeOutfitSync = {
        conceptID = concept.id,
        outfitID = outfitID,
        name = name,
        icon = GetConceptOutfitIcon(concept),
        phase = "WAITING_VIEW",
        token = string.format("%s:%d", concept.id, now),
    }
    concept.blizzardSyncPendingAt = now
    concept.blizzardSyncError = nil

    if C_Timer and C_Timer.After then
        local requestToken = pendingNativeOutfitSync.token
        C_Timer.After(NATIVE_OUTFIT_SYNC_TIMEOUT, function()
            if pendingNativeOutfitSync and pendingNativeOutfitSync.token == requestToken
                and pendingNativeOutfitSync.phase ~= "WAITING_CONFIRM"
            then
                FinishNativeOutfitSync(false, "World of Warcraft did not make the native outfit editor ready. Open the Transmog interface and try again.")
            end
        end)
    end

    local ok, failure
    if outfitID then
        ok, failure = TryCall(C_TransmogOutfitInfo.ChangeViewedOutfit, outfitID)
    else
        ok, failure = TryCall(C_TransmogOutfitInfo.ClearOutfit)
    end
    if not ok then
        FinishNativeOutfitSync(false, "Blizzard could not open the outfit editor: " .. tostring(failure))
        return false, "Blizzard could not prepare the native outfit slot."
    end

    if pendingNativeOutfitSync and pendingNativeOutfitSync.phase == "WAITING_VIEW" then
        if C_Timer and C_Timer.After then
            local requestToken = pendingNativeOutfitSync.token
            C_Timer.After(0, function()
                if pendingNativeOutfitSync and pendingNativeOutfitSync.token == requestToken then StageNativeOutfitSync() end
            end)
        else
            StageNativeOutfitSync()
        end
    end
    return true, outfitID and "Updating the linked World of Warcraft outfit..." or "Saving to a new World of Warcraft outfit slot..."
end

function Wardrobe.GetSelectedSource(slotKey)
    local state = EnsurePreviewState()
    local sourceID = state.selections[slotKey]
    if not sourceID then
        return nil
    end
    return GetSourceByID(slotKey, sourceID)
end

local function GetEquippedManifestDetails(definition)
    local slotID = definition and SafeCall(GetInventorySlotInfo, definition.slotName)
    if not slotID then return nil end
    local itemID = SafeCall(GetInventoryItemID, "player", slotID)
    local itemLink = SafeCall(GetInventoryItemLink, "player", slotID)
    if not itemID and not itemLink then return nil end
    local name = itemID and SafeCall(C_Item and C_Item.GetItemNameByID, itemID)
    if not name and itemID then name = SafeCall(C_Item and C_Item.GetItemInfo, itemID) end
    if not name and itemLink then name = SafeCall(C_Item and C_Item.GetItemInfo, itemLink) end
    local icon = SafeCall(GetInventoryItemTexture, "player", slotID) or GetItemIcon(itemID)
    return {
        itemID = itemID,
        itemLink = itemLink,
        name = name or itemLink or "Equipped gear",
        icon = icon,
    }
end

function Wardrobe.GetPreviewManifest()
    local state = EnsurePreviewState()
    local manifest = {}
    local selectedWeaponMode
    for _, slotKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
        if state.selections[slotKey] then
            selectedWeaponMode = slotKey
            break
        end
    end

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local include = not definition.weaponRole
        local displayLabel = definition.label
        if definition.weaponRole then
            if selectedWeaponMode then
                include = definition.key == selectedWeaponMode or (definition.key == "OFF_HAND" and selectedWeaponMode == "ONE_HAND")
            else
                include = definition.key == "ONE_HAND" or definition.key == "OFF_HAND"
                if definition.key == "ONE_HAND" then displayLabel = "Main Hand" end
            end
        end

        if include then
            local source = GetSourceByID(definition.key, state.selections[definition.key])
            local equipped = not source and GetEquippedManifestDetails(definition) or nil
            if not definition.weaponRole or source or equipped then
                local hidden = state.hidden[definition.key] == true
                local kind = source and "Selected" or (equipped and "Equipped" or "Empty")
                table.insert(manifest, {
                    slotKey = definition.key,
                    label = displayLabel,
                    name = source and (source.name or ("Appearance " .. tostring(source.sourceID))) or (equipped and equipped.name or "Empty"),
                    icon = source and source.icon or equipped and equipped.icon,
                    sourceID = source and source.sourceID,
                    source = source,
                    itemID = source and source.itemID or equipped and equipped.itemID,
                    itemLink = source and source.styleItemLink or equipped and equipped.itemLink,
                    kind = kind,
                    hidden = hidden,
                    locked = state.locks[definition.key] == true,
                })
            end
        end
    end
    return manifest
end

function Wardrobe.ValidateSource(source, slotKey)
    if type(source) ~= "table" then
        return false, "Appearance data is unavailable."
    end
    if not source.isCollected and not source.appearanceIsCollected then
        return false, "This appearance is not collected."
    end
    if source.appearanceCanDisplayOnPlayer == false then
        return false, "This character cannot display the appearance."
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
    local sourceIsCollected = IsSourceCollected(sourceID, source, appearance)
    local appearanceIsCollected = appearance and appearance.isCollected == true
    local normalized = {
        sourceID = sourceID,
        -- GetCategoryAppearances is already Blizzard's collapsed visual catalog.
        -- Its visualID is the identity of this row. Source-level appearance IDs
        -- are a different namespace and must never be used to key the catalog.
        visualID = appearance and appearance.visualID or nil,
        itemID = itemID,
        name = source and source.name or nil,
        quality = source and source.quality or nil,
        sourceType = source and source.sourceType or nil,
        inventoryType = source and source.invType or nil,
        categoryID = source and source.categoryID or categoryID,
        slotKey = slotKey,
        -- Collection and display eligibility belong to Blizzard's collapsed
        -- appearance row. A source can be individually unknown or unusable
        -- while another source has already unlocked the same visual.
        isCollected = appearanceIsCollected,
        appearanceIsCollected = appearanceIsCollected,
        sourceIsCollected = sourceIsCollected,
        isHideVisual = source and source.isHideVisual == true or appearance and appearance.isHideVisual == true,
        isUsable = appearance and appearance.isUsable,
        appearanceCanDisplayOnPlayer = appearance and appearance.canDisplayOnPlayer,
        playerCanCollect = source and source.playerCanCollect,
        isValidSourceForPlayer = source and source.isValidSourceForPlayer,
        canDisplayOnPlayer = source and source.canDisplayOnPlayer,
        meetsTransmogPlayerCondition = source and source.meetsTransmogPlayerCondition,
        useError = source and source.useError,
        icon = GetItemIcon(itemID) or appearance and appearance.icon,
    }

    normalized.visualID = normalized.visualID or sourceID
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
    if candidate.sourceIsCollected ~= current.sourceIsCollected then
        return candidate.sourceIsCollected == true
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
                local bestSource
                local sources = GetKnownSources(appearance, categoryID, transmogLocation)
                categoryDiagnostic.returnedSources = categoryDiagnostic.returnedSources + #sources
                diagnostics.returnedSources = diagnostics.returnedSources + #sources

                for _, source in ipairs(sources) do
                    local normalized = NormalizeSource(source, appearance, definition.key, categoryID)
                    if normalized then
                        local valid = Wardrobe.ValidateSource(normalized, definition.key)
                        if valid then
                            acceptedForAppearance = true
                            if BetterSource(normalized, bestSource) then
                                bestSource = normalized
                            end
                        end
                    end
                end

                if acceptedForAppearance and bestSource then
                    -- One entry per Blizzard appearance row. Resolving a source
                    -- chooses how to preview that row; it does not define or
                    -- deduplicate the catalog itself.
                    local visualKey = appearance.visualID
                    if visualKey and BetterSource(bestSource, visuals[visualKey]) then
                        visuals[visualKey] = bestSource
                    end
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

local function ScheduleAutomaticRefresh(reason)
    local cache = EnsureCache()
    local settings = QC.GetSettings and QC.GetSettings() or {}
    cache.lastCollectionChangeAt = time and time() or 0
    if settings.autoRefreshWardrobe == false
        or (cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS")
        or (cache.totalVisuals or 0) == 0
        or not C_Timer or type(C_Timer.After) ~= "function"
    then
        cache.autoRefreshPending = false
        return
    end

    autoRefreshToken = autoRefreshToken + 1
    local token = autoRefreshToken
    local attempts = 0
    cache.autoRefreshPending = true
    cache.autoRefreshReason = reason or "COLLECTION_CHANGED"
    cache.autoRefreshDeferredReason = nil
    if QC.Notify then QC.Notify("WARDROBE_AUTO_REFRESH_SCHEDULED", cache.autoRefreshReason) end

    local function TryRefresh()
        if token ~= autoRefreshToken then return end
        if settings.autoRefreshWardrobe == false then
            cache.autoRefreshPending = false
            return
        end
        attempts = attempts + 1
        local blockedByCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
        local blockedByWardrobe = IsBlizzardWardrobeVisible()
        if Wardrobe.scanning or blockedByCombat or blockedByWardrobe then
            if attempts < AUTO_REFRESH_MAX_ATTEMPTS then
                C_Timer.After(AUTO_REFRESH_RETRY_DELAY, TryRefresh)
                return
            end
            cache.autoRefreshPending = false
            cache.autoRefreshDeferredReason = blockedByCombat and "COMBAT" or (blockedByWardrobe and "BLIZZARD_WARDROBE_OPEN" or "SCAN_BUSY")
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print("Wardrobe refresh deferred. Close Blizzard's Wardrobe and leave combat, then use Rescan Collection.")
            end
            if QC.Notify then QC.Notify("WARDROBE_AUTO_REFRESH_DEFERRED", cache.autoRefreshDeferredReason) end
            return
        end

        cache.autoRefreshPending = false
        local started, message = Wardrobe.Scan(true, "AUTO_COLLECTION_CHANGE")
        if not started then
            cache.autoRefreshDeferredReason = message or "SCAN_UNAVAILABLE"
            if QC.Notify then QC.Notify("WARDROBE_AUTO_REFRESH_DEFERRED", cache.autoRefreshDeferredReason) end
        end
    end

    C_Timer.After(AUTO_REFRESH_DELAY, TryRefresh)
end

function Wardrobe.MarkDirty(reason)
    local cache = EnsureCache()
    cache.dirty = true
    cache.dirtyReason = reason or "COLLECTION_CHANGED"
    if QC.Notify then
        QC.Notify("WARDROBE_CACHE_DIRTY", cache.dirtyReason)
    end
    if not Wardrobe.scanning then
        ScheduleAutomaticRefresh(cache.dirtyReason)
    end
end

function Wardrobe.Scan(force, trigger)
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

    autoRefreshToken = autoRefreshToken + 1
    cache.autoRefreshPending = false
    CaptureRecoveryIdentities()
    Wardrobe.scanning = true
    Wardrobe.scanCollectionState = CaptureCollectionState()
    ApplyScanCollectionState()
    SafeCall(C_TransmogCollection.UpdateUsableAppearances)

    cache.scanState = "PREPARING"
    cache.scanStartedAt = time()
    cache.scanTrigger = trigger or "MANUAL"
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
    local scanStartedPrecise = GetTime and GetTime() or nil

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
        if scanStartedPrecise and GetTime then cache.scanDurationMS = math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) end
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
            if scanStartedPrecise and GetTime then cache.scanDurationMS = math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) end
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
        cache.scanDurationMS = scanStartedPrecise and GetTime and math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) or nil
        RecoverAppearanceReferences(cache)
        if cache.scanTrigger == "AUTO_COLLECTION_CHANGE" then
            cache.lastAutoRefreshAt = cache.scanCompletedAt
            cache.lastAutoRefreshReason = cache.autoRefreshReason
            cache.autoRefreshReason = nil
            cache.autoRefreshDeferredReason = nil
            local settings = QC.GetSettings and QC.GetSettings() or {}
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print(string.format("Wardrobe refreshed automatically: %d previewable appearances in %.1f seconds.", cache.totalVisuals or 0, (cache.scanDurationMS or 0) / 1000))
            end
        end

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
            local state = EnsurePreviewState()
            SetSelectedSource(state, slotKey, source)
            state.hidden[slotKey] = nil
            state.selectedConceptID = nil
            state.generatedName = nil
            state.generatedAt = nil
            ApplyWeaponSelectionRules(state, slotKey)
            if slotKey == "OFF_HAND" and not state.selections.ONE_HAND then
                SetRandomSelection(state, "ONE_HAND", false)
            end
            if QC.Notify then
                QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, source)
            end
            return true, reason
        end
    end
    return false, "The selected appearance is not present in the current cache."
end

function Wardrobe.ClearSelection(slotKey)
    local state = EnsurePreviewState()
    SetSelectedSource(state, slotKey, nil)
    state.locks[slotKey] = nil
    state.hidden[slotKey] = nil
    state.selectedConceptID = nil
    state.generatedName = nil
    state.generatedAt = nil
    if QC.Notify then
        QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, nil)
    end
end

function Wardrobe.ClearAllSelections()
    local state = EnsurePreviewState()
    state.selections = {}
    state.selectionVisuals = {}
    state.locks = {}
    state.hidden = {}
    state.selectedConceptID = nil
    state.generatedName = nil
    state.generatedAt = nil
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
    local failed = 0
    local state = EnsurePreviewState()
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local source = Wardrobe.GetSelectedSource(definition.key)
        if state.hidden[definition.key] and definition.hideable and model.UndressSlot then
            local slotID = SafeCall(GetInventorySlotInfo, definition.slotName)
            if slotID then
                SafeCall(model.UndressSlot, model, slotID)
            end
        elseif source then
            local valid = Wardrobe.ValidateSource(source, definition.key)
            if valid and source.sourceID and model.TryOn then
                -- TryOn accepts an item link or item-modified appearance ID.
                -- A transmog sourceID is the latter; itemID is a different
                -- namespace and can silently leave the equipped visual intact.
                local handSlotName
                if definition.slotName == "MAINHANDSLOT" or definition.slotName == "SECONDARYHANDSLOT" then
                    handSlotName = definition.slotName
                end
                local ok, result = pcall(model.TryOn, model, source.sourceID, handSlotName)
                local successValue = Enum and Enum.ItemTryOnReason and Enum.ItemTryOnReason.Success
                if ok and (result == nil or successValue == nil or result == successValue) then
                    applied = applied + 1
                else
                    failed = failed + 1
                end
            end
        end
    end
    if failed > 0 then
        return false, string.format("Previewed %d selected appearances; %d could not be applied by WoW.", applied, failed)
    end
    return true, string.format("Previewed %d selected appearances.", applied)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
eventFrame:RegisterEvent("TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED")
eventFrame:RegisterEvent("TRANSMOG_OUTFITS_CHANGED")
eventFrame:RegisterEvent("VIEWED_TRANSMOG_OUTFIT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local cache = EnsureCache()
        cache.autoRefreshPending = false
        cache.autoRefreshReason = nil
        EnsurePreviewState()
        local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
        if character and cache.characterKey and cache.characterKey ~= character.key then
            ResetCache(cache, "STALE")
            cache.dirtyReason = "CHARACTER_CHANGED"
        end
        if cache.dirty then
            ScheduleAutomaticRefresh(cache.dirtyReason or "COLLECTION_CHANGED")
        end
    elseif event == "VIEWED_TRANSMOG_OUTFIT_CHANGED" then
        StageNativeOutfitSync()
    elseif event == "TRANSMOG_OUTFITS_CHANGED" then
        if pendingNativeOutfitSync and pendingNativeOutfitSync.phase == "WAITING_CONFIRM" then
            local newOutfitID = ...
            local outfitID = tonumber(newOutfitID) or pendingNativeOutfitSync.outfitID
            if not outfitID then
                local info = FindNativeOutfitByName(pendingNativeOutfitSync.name)
                outfitID = info and info.outfitID
            end
            if outfitID then
                FinishNativeOutfitSync(true, "Saved to a World of Warcraft outfit slot.", outfitID)
            end
        end
    elseif event == "TRANSMOG_COLLECTION_UPDATED"
        and internalUsabilityUpdateUntil
        and GetTime
        and GetTime() <= internalUsabilityUpdateUntil
    then
        -- Weapon generation asks Blizzard to refresh current-character
        -- usability before validating the equipped hands. Blizzard reports
        -- that calculation through the generic collection-updated event even
        -- though no appearance was learned or removed. Do not turn our own
        -- validation refresh into a full wardrobe rescan.
        local cache = EnsureCache()
        cache.lastInternalUsabilityUpdateAt = time and time() or 0
    else
        Wardrobe.MarkDirty(event)
    end
end)
