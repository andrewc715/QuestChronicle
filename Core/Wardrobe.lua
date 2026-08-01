local QC = QuestChronicle

QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe

Wardrobe.CACHE_VERSION = 6
Wardrobe.PAGE_SIZE = 7

Wardrobe.WEAPON_FAMILY_ORDER = { "ONE_HAND", "TWO_HAND", "RANGED", "OFF_HAND" }
Wardrobe.weaponFamilyDefinitions = {
    ONE_HAND = { key = "ONE_HAND", label = "One-Hand", shortLabel = "1H" },
    TWO_HAND = { key = "TWO_HAND", label = "Two-Hand", shortLabel = "2H" },
    RANGED = { key = "RANGED", label = "Ranged", shortLabel = "Ranged" },
    OFF_HAND = { key = "OFF_HAND", label = "Off-Hand", shortLabel = "Off-Hand" },
}

Wardrobe.WEAPON_SUBTYPE_ORDER = {
    "ONE_HAND_WAND", "ONE_HAND_AXE", "ONE_HAND_SWORD", "ONE_HAND_MACE", "ONE_HAND_DAGGER", "ONE_HAND_FIST", "ONE_HAND_WARGLAIVE", "ONE_HAND_PAIRED",
    "TWO_HAND_AXE", "TWO_HAND_SWORD", "TWO_HAND_MACE", "TWO_HAND_STAFF", "TWO_HAND_POLEARM",
    "RANGED_BOW", "RANGED_GUN", "RANGED_CROSSBOW",
    "OFF_HAND_SHIELD", "OFF_HAND_HOLDABLE",
}
Wardrobe.weaponSubtypeDefinitions = {
    ONE_HAND_WAND = { key = "ONE_HAND_WAND", familyKey = "ONE_HAND", label = "Wand", shortLabel = "Wand", categoryName = "Wand", fallbackCategoryID = 12 },
    ONE_HAND_AXE = { key = "ONE_HAND_AXE", familyKey = "ONE_HAND", label = "One-Handed Axe", shortLabel = "1H Axe", categoryName = "OneHAxe", fallbackCategoryID = 13 },
    ONE_HAND_SWORD = { key = "ONE_HAND_SWORD", familyKey = "ONE_HAND", label = "One-Handed Sword", shortLabel = "1H Sword", categoryName = "OneHSword", fallbackCategoryID = 14 },
    ONE_HAND_MACE = { key = "ONE_HAND_MACE", familyKey = "ONE_HAND", label = "One-Handed Mace", shortLabel = "1H Mace", categoryName = "OneHMace", fallbackCategoryID = 15 },
    ONE_HAND_DAGGER = { key = "ONE_HAND_DAGGER", familyKey = "ONE_HAND", label = "Dagger", shortLabel = "Dagger", categoryName = "Dagger", fallbackCategoryID = 16 },
    ONE_HAND_FIST = { key = "ONE_HAND_FIST", familyKey = "ONE_HAND", label = "Fist Weapon", shortLabel = "Fist", categoryName = "Fist", fallbackCategoryID = 17 },
    ONE_HAND_WARGLAIVE = { key = "ONE_HAND_WARGLAIVE", familyKey = "ONE_HAND", label = "Warglaive", shortLabel = "Warglaive", categoryName = "Warglaives", fallbackCategoryID = 28 },
    ONE_HAND_PAIRED = { key = "ONE_HAND_PAIRED", familyKey = "ONE_HAND", label = "Paired Artifact", shortLabel = "Paired", categoryName = "Paired", fallbackCategoryID = 29 },
    TWO_HAND_AXE = { key = "TWO_HAND_AXE", familyKey = "TWO_HAND", label = "Two-Handed Axe", shortLabel = "2H Axe", categoryName = "TwoHAxe", fallbackCategoryID = 20 },
    TWO_HAND_SWORD = { key = "TWO_HAND_SWORD", familyKey = "TWO_HAND", label = "Two-Handed Sword", shortLabel = "2H Sword", categoryName = "TwoHSword", fallbackCategoryID = 21 },
    TWO_HAND_MACE = { key = "TWO_HAND_MACE", familyKey = "TWO_HAND", label = "Two-Handed Mace", shortLabel = "2H Mace", categoryName = "TwoHMace", fallbackCategoryID = 22 },
    TWO_HAND_STAFF = { key = "TWO_HAND_STAFF", familyKey = "TWO_HAND", label = "Staff", shortLabel = "Staff", categoryName = "Staff", fallbackCategoryID = 23 },
    TWO_HAND_POLEARM = { key = "TWO_HAND_POLEARM", familyKey = "TWO_HAND", label = "Polearm", shortLabel = "Polearm", categoryName = "Polearm", fallbackCategoryID = 24 },
    RANGED_BOW = { key = "RANGED_BOW", familyKey = "RANGED", label = "Bow", shortLabel = "Bow", categoryName = "Bow", fallbackCategoryID = 25 },
    RANGED_GUN = { key = "RANGED_GUN", familyKey = "RANGED", label = "Gun", shortLabel = "Gun", categoryName = "Gun", fallbackCategoryID = 26 },
    RANGED_CROSSBOW = { key = "RANGED_CROSSBOW", familyKey = "RANGED", label = "Crossbow", shortLabel = "Crossbow", categoryName = "Crossbow", fallbackCategoryID = 27 },
    OFF_HAND_SHIELD = { key = "OFF_HAND_SHIELD", familyKey = "OFF_HAND", label = "Shield", shortLabel = "Shield", categoryName = "Shield", fallbackCategoryID = 18 },
    OFF_HAND_HOLDABLE = { key = "OFF_HAND_HOLDABLE", familyKey = "OFF_HAND", label = "Holdable / Focus", shortLabel = "Focus", categoryName = "Holdable", fallbackCategoryID = 19 },
}

local LOGIN_REFRESH_DELAY = 3.0
local LOGIN_REFRESH_RETRY_DELAY = 2.0
local LOGIN_REFRESH_MAX_ATTEMPTS = 15
local loginRefreshToken = 0
local loginRefreshScheduled = false
local internalUsabilityUpdateUntil
local pendingCustomSetSync
local CUSTOM_SET_SYNC_TIMEOUT = 5.0

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
        return false, "That Blizzard Custom Set function is unavailable."
    end
    local ok, a, b, c = pcall(func, ...)
    if not ok then
        return false, tostring(a or "Blizzard rejected the Custom Set request.")
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
    cache.loginRefreshPending = false
    cache.autoRefreshPending = nil
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
    cache.loginRefreshPending = cache.loginRefreshPending == true
    cache.autoRefreshPending = nil
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
    state.outfits.weaponFamilies = state.outfits.weaponFamilies or {
        ONE_HAND = true, TWO_HAND = true, RANGED = true, OFF_HAND = true,
    }
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if state.outfits.weaponFamilies[familyKey] == nil then
            state.outfits.weaponFamilies[familyKey] = true
        end
    end
    state.outfits.weaponSubtypes = state.outfits.weaponSubtypes or {}
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        if state.outfits.weaponSubtypes[subtypeKey] == nil then
            state.outfits.weaponSubtypes[subtypeKey] = true
        end
    end
    state.outfits.linkWeaponHands = state.outfits.linkWeaponHands ~= false
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
        -- v1.0.1 retires the protected native Outfit-slot pipeline. Existing
        -- concepts remain authoritative; only obsolete synchronization fields
        -- are discarded during migration.
        concept.blizzardOutfitID = nil
        concept.blizzardOutfitName = nil
        concept.blizzardOutfitIcon = nil
        concept.blizzardSyncedAt = nil
        concept.blizzardSyncPendingAt = nil
        concept.blizzardSyncError = nil
        if concept.blizzardCustomSetID ~= nil then
            concept.blizzardCustomSetID = tonumber(concept.blizzardCustomSetID)
        end
        if concept.customSetSyncPendingAt and (not pendingCustomSetSync or pendingCustomSetSync.conceptID ~= concept.id) then
            concept.customSetSyncPendingAt = nil
        end
        concept.weaponFamilies = concept.weaponFamilies or {
            ONE_HAND = true, TWO_HAND = true, RANGED = true, OFF_HAND = true,
        }
        concept.weaponSubtypes = concept.weaponSubtypes or {}
        for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
            if concept.weaponSubtypes[subtypeKey] == nil then concept.weaponSubtypes[subtypeKey] = true end
        end
        if concept.linkWeaponHands == nil then concept.linkWeaponHands = true end
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

local weaponSubtypeByCategoryID = {}

local function ResolveWeaponSubtypeCategoryID(definition)
    if not definition then return nil end
    local categoryID
    if Enum and Enum.TransmogCollectionType then
        categoryID = Enum.TransmogCollectionType[definition.categoryName]
    end
    categoryID = categoryID or definition.fallbackCategoryID
    definition.categoryID = categoryID
    if categoryID then weaponSubtypeByCategoryID[tonumber(categoryID)] = definition.key end
    return categoryID
end

local function RefreshWeaponSubtypeCategoryMap()
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        ResolveWeaponSubtypeCategoryID(Wardrobe.weaponSubtypeDefinitions[subtypeKey])
    end
end

local function GetWeaponSubtypeKeyForCategoryID(categoryID)
    categoryID = tonumber(categoryID)
    if not categoryID then return nil end
    if not weaponSubtypeByCategoryID[categoryID] then RefreshWeaponSubtypeCategoryMap() end
    return weaponSubtypeByCategoryID[categoryID]
end

local function GetWeaponSubtypeKeysForFamily(familyKey)
    local keys = {}
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        if definition and definition.familyKey == familyKey then table.insert(keys, subtypeKey) end
    end
    return keys
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

local function IsSourceCollected(sourceID, source)
    -- A collected visual can contain several sibling item sources. Custom Sets
    -- require an actually owned source, not merely a source whose visual is
    -- unlocked through another item. Keep this test deliberately source-strict.
    if source and source.isCollected == true then
        return true
    end
    if C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource then
        local info = SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID)
        if info and info.sourceIsCollected == true then
            return true
        end
    end
    if C_TransmogCollection and C_TransmogCollection.PlayerKnowsSource then
        local known = SafeCall(C_TransmogCollection.PlayerKnowsSource, sourceID)
        if known == true then
            return true
        end
    end
    return false
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
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, source in ipairs(Wardrobe.GetSlotSources(familyKey)) do
                if source.sourceID == sourceID then
                    return CopySourceForSlot(source, "OFF_HAND")
                end
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
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, source in ipairs(Wardrobe.GetSlotSources(familyKey)) do
                if source.visualID == visualID then return CopySourceForSlot(source, "OFF_HAND") end
            end
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
    if slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            if familyKey ~= slotKey then ClearWeaponSlot(state, familyKey) end
        end
        local topology = Wardrobe.GetWeaponTopology()
        if not topology.offItem then ClearWeaponSlot(state, "OFF_HAND") end
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

local function GetItemEquipLocation(itemInfo)
    if not itemInfo then return nil end

    -- GetItemInfoInstant is synchronous and its fourth return value is the
    -- authoritative itemEquipLoc (for example INVTYPE_2HWEAPON). Prefer it to
    -- broad transmog categories, because a two-handed sword can still be valid
    -- for a generic sword appearance category.
    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if type(getInstant) == "function" then
        local _, _, _, equipLoc = SafeCall(getInstant, itemInfo)
        if equipLoc and equipLoc ~= "" then
            return equipLoc
        end
    end

    -- Fall back to the cached item-info API when instant data is unavailable.
    local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getInfo) == "function" then
        local _, _, _, _, _, _, _, _, equipLoc = SafeCall(getInfo, itemInfo)
        if equipLoc and equipLoc ~= "" then
            return equipLoc
        end
    end

    return nil
end

local function EquipLocationSupportsWeaponFamily(equipLoc, familyKey)
    if not equipLoc or equipLoc == "" then return nil end

    if familyKey == "TWO_HAND" then
        return equipLoc == "INVTYPE_2HWEAPON"
    elseif familyKey == "RANGED" then
        return equipLoc == "INVTYPE_RANGED"
            or equipLoc == "INVTYPE_RANGEDRIGHT"
            or equipLoc == "INVTYPE_THROWN"
    elseif familyKey == "OFF_HAND" then
        return equipLoc == "INVTYPE_SHIELD"
            or equipLoc == "INVTYPE_HOLDABLE"
            or equipLoc == "INVTYPE_WEAPONOFFHAND"
    elseif familyKey == "ONE_HAND" then
        return equipLoc == "INVTYPE_WEAPON"
            or equipLoc == "INVTYPE_WEAPONMAINHAND"
            or equipLoc == "INVTYPE_WEAPONOFFHAND"
    end

    return false
end

local function ItemSupportsWeaponFamily(itemInfo, familyKey)
    if not itemInfo then return false end

    -- The equipped item's inventory location defines its hand topology. Do not
    -- let IsCategoryValidForItem blur a two-handed sword into the one-hand sword
    -- collection simply because both are swords.
    local equipLoc = GetItemEquipLocation(itemInfo)
    local equipResult = EquipLocationSupportsWeaponFamily(equipLoc, familyKey)
    if equipResult ~= nil then
        return equipResult
    end

    -- Category compatibility is only a last-resort fallback for unusual items
    -- whose equipment location is not available yet.
    local definition = slotByKey[familyKey]
    if definition and C_TransmogCollection and type(C_TransmogCollection.IsCategoryValidForItem) == "function" then
        for _, categoryID in ipairs(ResolveCategoryIDs(definition)) do
            if SafeCall(C_TransmogCollection.IsCategoryValidForItem, categoryID, itemInfo) == true then
                return true
            end
        end
    end

    return false
end

local function CountCachedWeaponSubtype(subtypeKey)
    local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not subtype then return 0 end
    local categoryID = ResolveWeaponSubtypeCategoryID(subtype)
    local count = 0
    for _, source in ipairs(Wardrobe.GetSlotSources(subtype.familyKey)) do
        if tonumber(source.categoryID) == tonumber(categoryID) then count = count + 1 end
    end
    return count
end

local function HasCachedWeaponFamily(familyKey)
    for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
        if CountCachedWeaponSubtype(subtypeKey) > 0 then return true end
    end
    return false
end

local function GetPhysicalWeaponKind(equipLoc)
    if equipLoc == "INVTYPE_2HWEAPON" then return "TWO_HAND" end
    if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" then return "RANGED" end
    if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND" then return "ONE_HAND" end
    if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return "OFF_HAND" end
    return equipLoc and "UNKNOWN" or "NONE"
end

local function GetEquippedWeaponSubtype(itemInfo)
    if not itemInfo or not C_TransmogCollection then return nil end
    local _, sourceID = SafeCall(C_TransmogCollection.GetItemInfo, itemInfo)
    if sourceID and C_TransmogCollection.GetCategoryForItem then
        local categoryID = SafeCall(C_TransmogCollection.GetCategoryForItem, sourceID)
        local subtypeKey = GetWeaponSubtypeKeyForCategoryID(categoryID)
        if subtypeKey then return subtypeKey end
    end
    return nil
end

function Wardrobe.GetWeaponTopology()
    local mainItem = GetEquippedItemInfo("MAINHANDSLOT")
    local offItem = GetEquippedItemInfo("SECONDARYHANDSLOT")
    local mainEquipLoc = GetItemEquipLocation(mainItem)
    local offEquipLoc = GetItemEquipLocation(offItem)
    local mainKind = GetPhysicalWeaponKind(mainEquipLoc)
    local offKind = GetPhysicalWeaponKind(offEquipLoc)
    local topology = {
        mainItem = mainItem,
        offItem = offItem,
        mainEquipLoc = mainEquipLoc,
        offEquipLoc = offEquipLoc,
        mainHandKind = mainKind,
        offHandKind = offKind,
        mainPhysicalSubtype = GetEquippedWeaponSubtype(mainItem),
        offPhysicalSubtype = GetEquippedWeaponSubtype(offItem),
        mode = "NONE",
        label = "No weapon equipped",
        offHandPolicy = "NONE",
        hasWeaponOffHand = offKind == "ONE_HAND" or offKind == "TWO_HAND" or offKind == "RANGED",
    }

    if not mainItem then
        topology.mode = "UNARMED"
        topology.label = "No main-hand weapon equipped"
        topology.offHandPolicy = offKind == "OFF_HAND" and "OPTIONAL" or "NONE"
        return topology
    end

    if topology.hasWeaponOffHand then
        topology.offHandPolicy = "WEAPON"
        if mainKind == "TWO_HAND" and offKind == "TWO_HAND" then
            topology.mode = "DUAL_TWO_HAND"
            topology.label = "Dual two-handed weapons equipped"
        elseif mainKind == "ONE_HAND" and offKind == "ONE_HAND" then
            topology.mode = "DUAL_ONE_HAND"
            topology.label = "Dual one-handed weapons equipped"
        else
            topology.mode = "DUAL_WEAPON"
            topology.label = "Two weapon hands equipped"
        end
    elseif offKind == "OFF_HAND" then
        topology.mode = "ONE_HAND_OFF_HAND"
        topology.label = "Weapon and shield/focus equipped"
        topology.offHandPolicy = "OPTIONAL"
    elseif mainKind == "RANGED" then
        topology.mode = "RANGED"
        topology.label = "Ranged weapon equipped"
    elseif mainKind == "TWO_HAND" then
        topology.mode = "TWO_HAND"
        topology.label = "Two-handed weapon equipped"
    elseif mainKind == "ONE_HAND" then
        topology.mode = "ONE_HAND"
        topology.label = "One-handed weapon equipped"
    else
        topology.mode = "UNKNOWN"
        topology.label = "Unusual weapon layout"
    end
    return topology
end

local function GetTransmogOutfitSlotForInventorySlotName(slotName)
    if not slotName or not GetInventorySlotInfo then return nil end
    if not C_TransmogOutfitInfo or type(C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot) ~= "function" then
        return nil
    end
    local inventorySlotID = SafeCall(GetInventorySlotInfo, slotName)
    if inventorySlotID == nil then return nil end
    return SafeCall(C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot, inventorySlotID)
end

local function GetEquippedWeaponOptionForOutfitSlot(outfitSlot)
    if outfitSlot == nil or not C_TransmogOutfitInfo then return nil end

    if type(C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot) == "function" then
        local option = SafeCall(C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot, outfitSlot)
        if option ~= nil then return option end
    end

    -- The equipped-option API can briefly return nil while the transmog system
    -- initializes. Prefer the first enabled standard option before falling back
    -- to None, mirroring Blizzard's slot-option model without changing it.
    if type(C_TransmogOutfitInfo.GetWeaponOptionsForSlot) == "function" then
        local options = SafeCall(C_TransmogOutfitInfo.GetWeaponOptionsForSlot, outfitSlot)
        for _, optionInfo in ipairs(options or {}) do
            if optionInfo and optionInfo.enabled and optionInfo.weaponOption ~= nil then
                return optionInfo.weaponOption
            end
        end
    end

    return Enum and Enum.TransmogOutfitSlotOption and Enum.TransmogOutfitSlotOption.None or 0
end

local function GetBlizzardWeaponCategoryPermission(slotName, categoryID)
    if not categoryID or not C_TransmogOutfitInfo
        or type(C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption) ~= "function"
    then
        return nil, nil
    end

    local outfitSlot = GetTransmogOutfitSlotForInventorySlotName(slotName)
    if outfitSlot == nil then return nil, nil end

    local weaponOption = GetEquippedWeaponOptionForOutfitSlot(outfitSlot)
    if weaponOption == nil then return nil, nil end

    local collectionInfo = SafeCall(
        C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption,
        outfitSlot,
        weaponOption,
        categoryID
    )

    -- Blizzard's native weapon-category dropdown uses this exact test.
    -- A nil result means the category is not available for the slot/option.
    return collectionInfo ~= nil and collectionInfo.isWeapon == true, {
        outfitSlot = outfitSlot,
        weaponOption = weaponOption,
        collectionName = collectionInfo and collectionInfo.name or nil,
        method = "OUTFIT_SLOT_OPTION",
    }
end

local function IsWeaponCategoryPermitted(slotName, categoryID, itemInfo)
    local nativeAllowed, details = GetBlizzardWeaponCategoryPermission(slotName, categoryID)
    if nativeAllowed ~= nil then
        return nativeAllowed, details
    end

    -- Compatibility fallback for clients that do not expose the Midnight
    -- outfit-slot API. This older check does not understand every specialization
    -- exception, so it is intentionally secondary.
    if itemInfo and C_TransmogCollection and type(C_TransmogCollection.IsCategoryValidForItem) == "function" then
        local allowed = SafeCall(C_TransmogCollection.IsCategoryValidForItem, categoryID, itemInfo) == true
        return allowed, { method = "ITEM_CATEGORY_FALLBACK" }
    end

    return nil, { method = "UNAVAILABLE" }
end

local function BuildWeaponHandCapability(handKey, itemInfo, slotName, allowWithoutItem)
    local capability = {
        handKey = handKey,
        itemInfo = itemInfo,
        slotName = slotName,
        physicalSubtype = GetEquippedWeaponSubtype(itemInfo),
        subtypes = {},
        families = {},
    }
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        local categoryID = ResolveWeaponSubtypeCategoryID(subtype)
        local count = CountCachedWeaponSubtype(subtypeKey)
        local blizzardAllowed = false
        local permissionDetails
        if itemInfo then
            local permitted
            permitted, permissionDetails = IsWeaponCategoryPermitted(slotName, categoryID, itemInfo)
            blizzardAllowed = permitted == true
        elseif allowWithoutItem then
            blizzardAllowed = true
            permissionDetails = { method = "UNARMED_PREVIEW" }
        end
        local available = blizzardAllowed and count > 0
        capability.subtypes[subtypeKey] = {
            key = subtypeKey,
            familyKey = subtype.familyKey,
            label = subtype.label,
            shortLabel = subtype.shortLabel,
            categoryID = categoryID,
            count = count,
            blizzardAllowed = blizzardAllowed,
            available = available,
            permissionMethod = permissionDetails and permissionDetails.method or nil,
            outfitSlot = permissionDetails and permissionDetails.outfitSlot or nil,
            weaponOption = permissionDetails and permissionDetails.weaponOption or nil,
            reason = available and (permissionDetails and permissionDetails.method == "OUTFIT_SLOT_OPTION"
                    and "Blizzard's native outfit-slot rules permit this appearance category for the equipped hand."
                    or "Blizzard permits this appearance category for the equipped hand.")
                or (count == 0 and "No collected previewable appearances are cached for this type."
                or (itemInfo and "Blizzard does not permit this appearance category for the equipped hand."
                or "No equipped item is available for Blizzard compatibility validation.")),
        }
        capability.families[subtype.familyKey] = capability.families[subtype.familyKey] or { available = false, count = 0 }
        capability.families[subtype.familyKey].count = capability.families[subtype.familyKey].count + (available and count or 0)
        capability.families[subtype.familyKey].available = capability.families[subtype.familyKey].available or available
    end
    return capability
end

function Wardrobe.GetWeaponAppearanceCapabilities()
    local topology = Wardrobe.GetWeaponTopology()
    local unarmed = topology.mode == "UNARMED"
    local main = BuildWeaponHandCapability("MAIN", topology.mainItem, "MAINHANDSLOT", unarmed)
    local off = BuildWeaponHandCapability("OFF", topology.offItem, "SECONDARYHANDSLOT", unarmed)
    local capabilities = {
        topology = topology,
        main = main,
        off = off,
        availableFamilies = {},
        reasons = {},
    }
    for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
        local available = main.families[familyKey] and main.families[familyKey].available == true
        capabilities.availableFamilies[familyKey] = available
        capabilities.reasons[familyKey] = available
            and "Blizzard permits at least one selected appearance type in this family for the equipped main hand."
            or "No collected appearance type in this family is permitted for the equipped main hand."
    end
    local offAvailable = off.families.OFF_HAND and off.families.OFF_HAND.available == true
    capabilities.availableFamilies.OFF_HAND = offAvailable
    capabilities.reasons.OFF_HAND = offAvailable
        and "Blizzard permits a shield or holdable appearance for the equipped off hand."
        or (topology.hasWeaponOffHand and "The equipped off hand is a weapon; use One-Hand or Two-Hand appearance families instead."
        or "No collected shield or holdable appearance is permitted for the equipped off hand.")
    return capabilities
end

local function NormalizeWeaponFamilyChoices(state, capabilities)
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
    local state = EnsurePreviewState()
    local capabilities = NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
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
    local state = EnsurePreviewState()
    local capabilities = NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
    local options = {}
    for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
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
    local state = EnsurePreviewState()
    local capabilities = NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
    if not capabilities.availableFamilies[familyKey] then
        return false, capabilities.reasons[familyKey] or (definition.label .. " is unavailable.")
    end
    enabled = enabled == true
    local previous = state.weaponFamilies[familyKey]
    state.weaponFamilies[familyKey] = enabled
    if enabled then
        local anySubtype = false
        for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
            local hand = familyKey == "OFF_HAND" and capabilities.off or capabilities.main
            if hand.subtypes[subtypeKey] and hand.subtypes[subtypeKey].available and state.weaponSubtypes[subtypeKey] then anySubtype = true break end
        end
        if not anySubtype then
            for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
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
    local state = EnsurePreviewState()
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
    local state = EnsurePreviewState()
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
    local state = EnsurePreviewState()
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
    local state = EnsurePreviewState()
    state.linkWeaponHands = enabled ~= false
    state.selectedConceptID = nil
    if QC.Notify then QC.Notify("WARDROBE_WEAPON_OPTIONS_CHANGED", "LINK_HANDS", state.linkWeaponHands) end
    return true, state.linkWeaponHands and "Weapon hands will match the same visual when possible and otherwise remain within the same exact weapon type." or "Weapon hands may generate independently."
end

function Wardrobe.GetLinkWeaponHands()
    return EnsurePreviewState().linkWeaponHands ~= false
end

function Wardrobe.GetWeaponFamilySummary(families)
    families = families or EnsurePreviewState().weaponFamilies
    local labels = {}
    for _, familyKey in ipairs(Wardrobe.WEAPON_FAMILY_ORDER) do
        if families and families[familyKey] then table.insert(labels, Wardrobe.weaponFamilyDefinitions[familyKey].shortLabel) end
    end
    return #labels > 0 and table.concat(labels, ", ") or "None"
end

function Wardrobe.GetWeaponSubtypeSummary(familyKey, subtypeChoices, onlyEffective)
    subtypeChoices = subtypeChoices or EnsurePreviewState().weaponSubtypes
    local options = Wardrobe.GetWeaponSubtypeOptions(familyKey)
    local labels = {}
    for _, option in ipairs(options) do
        if subtypeChoices[option.key] and (not onlyEffective or option.available) then table.insert(labels, option.shortLabel) end
    end
    return #labels > 0 and table.concat(labels, ", ") or "None"
end

function Wardrobe.GetWeaponFilterSummary()
    local state = EnsurePreviewState()
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
            for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
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
    local state = EnsurePreviewState()
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
    local definition = slotByKey[slotKey]
    if not definition or not definition.weaponRole then return sources end
    local state = EnsurePreviewState()
    local capabilities = Wardrobe.GetWeaponAppearanceCapabilities()
    local hand = slotKey == "OFF_HAND" and capabilities.off or capabilities.main
    local filtered = {}
    for _, source in ipairs(sources) do
        local subtypeKey = GetWeaponSubtypeKeyForCategoryID(source.categoryID)
        local subtype = subtypeKey and hand.subtypes[subtypeKey]
        if subtypeKey and state.weaponSubtypes[subtypeKey] and subtype and subtype.available then
            table.insert(filtered, source)
        end
    end
    return filtered
end

local function CreateWeaponGenerationContext()
    local now = GetTime and GetTime()
    internalUsabilityUpdateUntil = now and (now + 1.0) or nil
    SafeCall(C_TransmogCollection and C_TransmogCollection.UpdateUsableAppearances)
    local capabilities = Wardrobe.GetWeaponAppearanceCapabilities()
    return {
        mainItem = capabilities.topology.mainItem,
        offItem = capabilities.topology.offItem,
        appearancesByCategory = {},
        locationsBySlot = {},
        validation = {},
        topology = capabilities.topology,
        capabilities = capabilities,
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
    if not source.categoryID then
        return Finish(false, "This cached weapon appearance has no collection category. Rescan the collection.")
    end
    local permitted = true
    local permissionDetails
    if equippedItem then
        permitted, permissionDetails = IsWeaponCategoryPermitted(definition and definition.slotName, source.categoryID, equippedItem)
        if permitted == nil then
            return Finish(false, "WoW's equipped-slot transmog compatibility check is unavailable.")
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
    local appearance = GetGenerationAppearance(source, definition, context)
    local nativeSlotRule = permissionDetails and permissionDetails.method == "OUTFIT_SLOT_OPTION"

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
    local appearanceInfo = SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, source.sourceID)
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

    return Finish(true, permissionDetails and permissionDetails.method == "OUTFIT_SLOT_OPTION"
        and "Compatible with Blizzard's equipped slot and weapon option"
        or "Compatible with the equipped item")
end

local function Shuffle(values)
    for index = #values, 2, -1 do
        local other = math.random(1, index)
        values[index], values[other] = values[other], values[index]
    end
end

local function GetEnabledSubtypeKeys(state, familyKeys, handCapability, preferredSubtypeKey)
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
            for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
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
        Shuffle(tail)
        keys = {}
        if first then table.insert(keys, first) end
        for _, value in ipairs(tail) do table.insert(keys, value) end
    end
    return keys
end

local function ChooseGeneratedWeaponSource(familyKeys, equippedItem, context, excludedBySlot, targetSlotKey, styleMode, styleContext, handCapability, preferredSubtypeKey, requirePreferred)
    local state = EnsurePreviewState()
    handCapability = handCapability or context.capabilities.main
    local subtypeKeys = GetEnabledSubtypeKeys(state, familyKeys, handCapability, preferredSubtypeKey)
    if requirePreferred and preferredSubtypeKey then subtypeKeys = subtypeKeys[1] == preferredSubtypeKey and { preferredSubtypeKey } or {} end

    local fallback
    for _, subtypeKey in ipairs(subtypeKeys) do
        local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        local categoryID = ResolveWeaponSubtypeCategoryID(subtype)
        local candidates = {}
        for _, source in ipairs(Wardrobe.GetSlotSources(subtype.familyKey)) do
            if tonumber(source.categoryID) == tonumber(categoryID) then
                local validationSlotKey = targetSlotKey or subtype.familyKey
                local candidateSource = CopySourceForSlot(source, validationSlotKey)
                local basicValid = Wardrobe.ValidateSource(candidateSource, validationSlotKey)
                if basicValid then table.insert(candidates, { source = candidateSource, slotKey = validationSlotKey, familyKey = subtype.familyKey, subtypeKey = subtypeKey }) end
            end
        end
        if QC.ZoneStyle and QC.ZoneStyle.OrderWeaponCandidates then
            QC.ZoneStyle.OrderWeaponCandidates(candidates, styleMode, styleContext)
        else
            Shuffle(candidates)
        end
        for _, candidate in ipairs(candidates) do
            local valid = ValidateGeneratedWeaponSource(candidate.source, candidate.slotKey, equippedItem, context)
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

local function ChooseLinkedWeaponSource(primarySource, equippedItem, context, excludedBySlot, targetSlotKey, styleMode, styleContext, handCapability)
    if not primarySource then return nil, nil, "No primary weapon appearance is selected." end

    local state = EnsurePreviewState()
    local subtypeKey = GetWeaponSubtypeKeyForCategoryID(primarySource.categoryID)
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
    local byVisual = FindSourceByVisualID(targetSlotKey, primarySource.visualID)
    if byVisual then
        table.insert(exactCandidates, byVisual)
        seen[byVisual.sourceID] = true
    end
    local copied = CopySourceForSlot(primarySource, targetSlotKey)
    if copied and not seen[copied.sourceID] then
        table.insert(exactCandidates, copied)
    end

    for _, candidate in ipairs(exactCandidates) do
        local valid = ValidateGeneratedWeaponSource(candidate, targetSlotKey, equippedItem, context)
        if valid then
            return candidate, "EXACT_VISUAL", nil
        end
    end

    -- Secondary link: stay inside the exact same Blizzard weapon subtype.
    -- Never fall through to an unrelated family or type while linking is on.
    local source = ChooseGeneratedWeaponSource(
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

local function SynchronizeLinkedOffHand(state, primarySource, styleMode, styleContext, excludedSourceID)
    if state.linkWeaponHands == false or not primarySource then return nil, nil end
    local styleEngine = QC.ZoneStyle
    if styleEngine and not styleContext then
        styleMode = styleEngine.NormalizeMode and styleEngine.NormalizeMode(styleMode or state.styleMode) or (styleMode or state.styleMode)
        local baseContext = styleEngine.GetCurrentContext and styleEngine.GetCurrentContext() or nil
        styleContext = CreateStyleGenerationContext(state, styleEngine, baseContext, nil, false)
    end
    local context = CreateWeaponGenerationContext()
    local topology = context.topology
    if not topology.offItem or topology.offHandKind == "OFF_HAND" then return nil, nil end

    local excluded = excludedSourceID and { OFF_HAND = excludedSourceID } or nil
    local source, linkKind, notice = ChooseLinkedWeaponSource(
        primarySource,
        context.offItem,
        context,
        excluded,
        "OFF_HAND",
        styleMode,
        styleContext,
        context.capabilities.off
    )
    SetSelectedSource(state, "OFF_HAND", source)
    return linkKind, notice
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
    -- A locked off-hand no longer dictates the main-hand appearance family.
    -- Fury and other Blizzard exceptions may permit two-handed or one-handed
    -- visuals independently in each occupied weapon hand.
    return lockedMode
end

local function GenerateWeapons(state, reroll, styleMode, styleContext)
    local lockedMode, errorMessage = GetLockedWeaponMode(state)
    if errorMessage then return false, errorMessage end

    local context = CreateWeaponGenerationContext()
    local capabilities = NormalizeWeaponFamilyChoices(state, context.capabilities)
    local topology = capabilities.topology
    local enabledMain = {}
    for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
        if capabilities.availableFamilies[familyKey] and state.weaponFamilies[familyKey] then
            local hasSubtype = false
            for _, subtypeKey in ipairs(GetWeaponSubtypeKeysForFamily(familyKey)) do
                local subtype = capabilities.main.subtypes[subtypeKey]
                if subtype and subtype.available and state.weaponSubtypes[subtypeKey] then hasSubtype = true break end
            end
            if hasSubtype then table.insert(enabledMain, familyKey) end
        end
    end
    if #enabledMain == 0 then
        return false, "Select at least one Blizzard-compatible main weapon type before generating."
    end

    if lockedMode and not state.weaponFamilies[lockedMode] then
        return false, string.format("The locked %s appearance is excluded by the weapon-family checkboxes. Enable it or unlock the slot.", slotByKey[lockedMode].label)
    end

    local lockedMainSource, lockedSubtype
    if lockedMode and state.locks[lockedMode] and state.selections[lockedMode] then
        lockedMainSource = GetSourceByID(lockedMode, state.selections[lockedMode])
        lockedSubtype = lockedMainSource and GetWeaponSubtypeKeyForCategoryID(lockedMainSource.categoryID)
        if not lockedSubtype or not state.weaponSubtypes[lockedSubtype] then
            return false, "The locked weapon appearance type is excluded by the current type filters."
        end
        local capability = capabilities.main.subtypes[lockedSubtype]
        if not capability or not capability.available then
            return false, "The locked weapon appearance type is not permitted for the equipped main hand."
        end
        local valid, reason = ValidateGeneratedWeaponSource(lockedMainSource, lockedMode, context.mainItem, context)
        if not valid then
            return false, string.format("The locked %s appearance is not valid for the equipped main-hand item: %s", slotByKey[lockedMode].label, reason or "incompatible")
        end
    end

    local mode = lockedMode
    local selectedMain = lockedMainSource
    local mainSubtype = lockedSubtype
    if not selectedMain then
        local excluded = {}
        if reroll then
            for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do excluded[familyKey] = state.selections[familyKey] end
        end
        selectedMain, mode, mainSubtype = ChooseGeneratedWeaponSource(enabledMain, context.mainItem, context, excluded, nil, styleMode, styleContext, capabilities.main)
        if selectedMain then SetSelectedSource(state, mode, selectedMain) end
    end

    for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
        if familyKey ~= mode and not state.locks[familyKey] then SetSelectedSource(state, familyKey, nil) end
    end
    if not selectedMain then
        if not state.locks.OFF_HAND then SetSelectedSource(state, "OFF_HAND", nil) end
        return true, 0, "No cached weapon visual matched the selected Blizzard-compatible types; armor was generated and equipped weapons were left unchanged."
    end

    if QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then QC.ZoneStyle.AddSourceToGenerationContext(styleContext, selectedMain) end

    local selectedWeapons = 1
    local notice
    local generateOffHand = topology.offItem ~= nil
    if generateOffHand then
        if state.locks.OFF_HAND and state.selections.OFF_HAND then
            local lockedOff = GetSourceByID("OFF_HAND", state.selections.OFF_HAND)
            local offSubtype = lockedOff and GetWeaponSubtypeKeyForCategoryID(lockedOff.categoryID)
            local capability = offSubtype and capabilities.off.subtypes[offSubtype]
            if not capability or not capability.available or not state.weaponSubtypes[offSubtype] then
                return false, "The locked off-hand appearance conflicts with the current Blizzard weapon rules or type filters."
            end
            local valid, reason = ValidateGeneratedWeaponSource(lockedOff, "OFF_HAND", context.offItem, context)
            if not valid then return false, "The locked off-hand appearance is not valid: " .. tostring(reason or "incompatible") end
            selectedWeapons = selectedWeapons + 1
        else
            local offFamilies = {}
            if topology.offHandKind == "OFF_HAND" then
                if state.weaponFamilies.OFF_HAND and capabilities.availableFamilies.OFF_HAND then table.insert(offFamilies, "OFF_HAND") end
            else
                if state.linkWeaponHands and mode and capabilities.off.families[mode] and capabilities.off.families[mode].available then
                    table.insert(offFamilies, mode)
                else
                    for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
                        if state.weaponFamilies[familyKey] and capabilities.off.families[familyKey] and capabilities.off.families[familyKey].available then
                            table.insert(offFamilies, familyKey)
                        end
                    end
                end
            end
            if #offFamilies > 0 then
                local excluded = reroll and { OFF_HAND = state.selections.OFF_HAND } or nil
                local offHand
                if state.linkWeaponHands and topology.offHandKind ~= "OFF_HAND" then
                    local linkKind, linkNotice
                    offHand, linkKind, linkNotice = ChooseLinkedWeaponSource(
                        selectedMain,
                        context.offItem,
                        context,
                        excluded,
                        "OFF_HAND",
                        styleMode,
                        styleContext,
                        capabilities.off
                    )
                    notice = linkNotice
                else
                    offHand = ChooseGeneratedWeaponSource(offFamilies, context.offItem, context, excluded, "OFF_HAND", styleMode, styleContext, capabilities.off)
                end
                SetSelectedSource(state, "OFF_HAND", offHand)
                if offHand then
                    if QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then QC.ZoneStyle.AddSourceToGenerationContext(styleContext, offHand) end
                    selectedWeapons = selectedWeapons + 1
                else
                    notice = notice or (state.linkWeaponHands
                        and "Linked hands remained strict, so Quest Chronicle left the second hand on its equipped appearance rather than choose an unrelated weapon type."
                        or "No valid appearance matched the equipped off-hand and selected type filters.")
                end
            elseif not state.locks.OFF_HAND then
                SetSelectedSource(state, "OFF_HAND", nil)
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
    if not definition then return false, "Unknown equipment slot." end
    if Wardrobe.IsSlotLocked(slotKey) then return false, "Unlock this slot before rerolling it." end

    local state = EnsurePreviewState()
    local styleEngine = QC.ZoneStyle
    local styleMode = styleEngine and styleEngine.NormalizeMode(state.styleMode) or state.styleMode
    local styleContext = styleEngine and CreateStyleGenerationContext(state, styleEngine, styleEngine.GetCurrentContext(), slotKey, false) or nil
    if definition.weaponRole then
        local context = CreateWeaponGenerationContext()
        local capabilities = NormalizeWeaponFamilyChoices(state, context.capabilities)
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
            else
                for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
                    if state.weaponFamilies[familyKey] and handCapability.families[familyKey] and handCapability.families[familyKey].available then
                        table.insert(sourceFamilies, familyKey)
                    end
                end
                if state.linkWeaponHands then
                    for _, familyKey in ipairs(MAIN_WEAPON_SLOT_KEYS) do
                        local selected = state.selections[familyKey] and GetSourceByID(familyKey, state.selections[familyKey])
                        if selected then preferredSubtype = GetWeaponSubtypeKeyForCategoryID(selected.categoryID) break end
                    end
                end
            end
        else
            equippedItem = context.mainItem
            handCapability = capabilities.main
            if not capabilities.availableFamilies[slotKey] then return false, capabilities.reasons[slotKey] or "That weapon family is unavailable." end
            if not state.weaponFamilies[slotKey] then return false, string.format("Enable %s before rerolling this slot.", definition.label) end
            sourceFamilies = { slotKey }
        end
        local source = ChooseGeneratedWeaponSource(sourceFamilies, equippedItem, context, { [slotKey] = state.selections[slotKey] }, slotKey, styleMode, styleContext, handCapability, preferredSubtype, false)
        if not source then return false, "No cached appearance in the selected Blizzard-compatible weapon types is valid for this hand." end
        SetSelectedSource(state, slotKey, source)
        if styleEngine and styleEngine.AddSourceToGenerationContext then styleEngine.AddSourceToGenerationContext(styleContext, source) end
        ApplyWeaponSelectionRules(state, slotKey)
        if slotKey ~= "OFF_HAND" and state.linkWeaponHands then
            SynchronizeLinkedOffHand(state, source, styleMode, styleContext, state.selections.OFF_HAND)
        end
    elseif not SetRandomSelection(state, slotKey, true, styleMode, styleContext) then
        return false, "No compatible appearance is cached for this slot."
    end
    state.selectedConceptID = nil
    local generatedName = RefreshGeneratedOutfitName(state, styleEngine, styleMode, styleContext)
    if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
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
    concept.weaponFamilies = CopyPrimitiveMap(state.weaponFamilies)
    concept.weaponSubtypes = CopyPrimitiveMap(state.weaponSubtypes)
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
    state.weaponFamilies = CopyPrimitiveMap(concept.weaponFamilies or { ONE_HAND = true, TWO_HAND = true, RANGED = true, OFF_HAND = true })
    state.weaponSubtypes = CopyPrimitiveMap(concept.weaponSubtypes or {})
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        if state.weaponSubtypes[subtypeKey] == nil then state.weaponSubtypes[subtypeKey] = true end
    end
    state.linkWeaponHands = concept.linkWeaponHands ~= false
    NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
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

local CUSTOM_SET_SLOT_FALLBACK = {
    HEAD = 1,
    SHOULDER = 3,
    BACK = 15,
    CHEST = 5,
    SHIRT = 4,
    TABARD = 19,
    WRIST = 9,
    HANDS = 10,
    WAIST = 6,
    LEGS = 7,
    FEET = 8,
    ONE_HAND = 16,
    TWO_HAND = 16,
    RANGED = 16,
    OFF_HAND = 17,
}

local CUSTOM_SET_LIST_SIZE = tonumber(INVSLOT_LAST_EQUIPPED) or 19

local function GetConceptSource(concept, slotKey)
    return concept and GetSourceByID(slotKey, concept.selections and concept.selections[slotKey]) or nil
end

local function GetConceptOutfitIcon(concept)
    for _, slotKey in ipairs({ "HEAD", "CHEST", "SHOULDER", "TWO_HAND", "ONE_HAND", "RANGED", "BACK" }) do
        local source = GetConceptSource(concept, slotKey)
        if source and tonumber(source.icon) then return tonumber(source.icon) end
    end
    return 134938 -- INV_Misc_Book_09
end

local function EmptyItemTransmogInfo()
    if ItemUtil and type(ItemUtil.CreateItemTransmogInfo) == "function" then
        return ItemUtil.CreateItemTransmogInfo(0, 0, 0)
    end
    return { appearanceID = 0, secondaryAppearanceID = 0, illusionID = 0 }
end

local function CreateItemTransmogInfo(sourceID)
    sourceID = tonumber(sourceID) or 0
    if ItemUtil and type(ItemUtil.CreateItemTransmogInfo) == "function" then
        return ItemUtil.CreateItemTransmogInfo(sourceID, 0, 0)
    end
    return { appearanceID = sourceID, secondaryAppearanceID = 0, illusionID = 0 }
end

local function CreateEmptyCustomSetList()
    local list
    if TransmogUtil and type(TransmogUtil.GetEmptyItemTransmogInfoList) == "function" then
        list = SafeCall(TransmogUtil.GetEmptyItemTransmogInfoList)
    end
    if type(list) ~= "table" then
        list = {}
    end
    -- Blizzard indexes Custom Set data by the actual inventory slot ID. Keep a
    -- complete array through INVSLOT_LAST_EQUIPPED, including non-transmog slots,
    -- so the native API receives the same structure its own UI creates.
    for slotID = 1, CUSTOM_SET_LIST_SIZE do
        if type(list[slotID]) ~= "table" then
            list[slotID] = EmptyItemTransmogInfo()
        end
    end
    return list
end

local function GetCustomSetSlotID(definition)
    if not definition then return nil end
    local slotID = SafeCall(GetInventorySlotInfo, definition.slotName)
    return tonumber(slotID) or CUSTOM_SET_SLOT_FALLBACK[definition.key]
end

local function CategoryAllowedForDefinition(definition, categoryID)
    if not definition or not categoryID then return true end
    local allowed = {}
    for _, value in ipairs(ResolveCategoryIDs(definition)) do allowed[tonumber(value)] = true end
    -- Blizzard may allow one-hand or two-hand weapon appearances in the
    -- secondary weapon slot (for example Fury). Accept every weapon family here;
    -- the concept was already validated against the equipped hand before saving.
    if definition.key == "OFF_HAND" then
        for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
            for _, value in ipairs(ResolveCategoryIDs(slotByKey[familyKey])) do allowed[tonumber(value)] = true end
        end
    end
    return allowed[tonumber(categoryID)] == true
end

local function GetActualSourceFacts(sourceID, source)
    sourceID = tonumber(sourceID)
    if not sourceID then return nil end
    source = source or GetSourceInfo(sourceID) or { sourceID = sourceID }
    local appearanceInfo = C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource
        and SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID) or nil
    return {
        sourceID = sourceID,
        source = source,
        appearanceInfo = appearanceInfo,
        visualID = appearanceInfo and (appearanceInfo.appearanceID or appearanceInfo.visualID)
            or source.visualID or source.appearanceID or source.itemAppearanceID,
        categoryID = source.categoryID,
        collected = IsSourceCollected(sourceID, source),
        hideVisual = source.isHideVisual == true,
        displayable = not (source.canDisplayOnPlayer == false
            or source.isValidSourceForPlayer == false
            or source.meetsTransmogPlayerCondition == false
            or source.useError
            or (appearanceInfo and appearanceInfo.canDisplayOnPlayer == false)
            or (appearanceInfo and appearanceInfo.meetsTransmogPlayerCondition == false)),
    }
end

local function SourceCanEnterCustomSet(sourceID, definition, allowHide, source)
    local facts = GetActualSourceFacts(sourceID, source)
    if not facts then return false, nil end
    if not CategoryAllowedForDefinition(definition, facts.categoryID) then return false, facts end
    if allowHide and facts.hideVisual then return true, facts end
    return facts.collected == true and facts.displayable == true and not facts.hideVisual, facts
end

local function AddCandidateID(candidates, seen, sourceID)
    sourceID = tonumber(sourceID)
    if sourceID and sourceID > 0 and not seen[sourceID] then
        seen[sourceID] = true
        table.insert(candidates, sourceID)
    end
end

local function ResolveCollectedConceptSource(concept, definition)
    local selectedSourceID = concept.selections and tonumber(concept.selections[definition.key])
    local selectedSource = selectedSourceID and GetSourceByID(definition.key, selectedSourceID) or nil
    local visualID = concept.visuals and concept.visuals[definition.key]
        or selectedSource and selectedSource.visualID

    local candidates, seen = {}, {}
    AddCandidateID(candidates, seen, selectedSourceID)

    if visualID and C_TransmogCollection and C_TransmogCollection.GetAllAppearanceSources then
        for _, sourceID in ipairs(SafeCall(C_TransmogCollection.GetAllAppearanceSources, visualID) or {}) do
            AddCandidateID(candidates, seen, sourceID)
        end
    end

    if visualID then
        local transmogLocation = GetTransmogLocation(definition)
        local categories = {}
        for _, categoryID in ipairs(ResolveCategoryIDs(definition)) do table.insert(categories, categoryID) end
        if definition.key == "OFF_HAND" then
            for _, familyKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED" }) do
                for _, categoryID in ipairs(ResolveCategoryIDs(slotByKey[familyKey])) do table.insert(categories, categoryID) end
            end
        end
        for _, categoryID in ipairs(categories) do
            local appearance = { visualID = visualID, isCollected = true }
            for _, source in ipairs(GetKnownSources(appearance, categoryID, transmogLocation)) do
                AddCandidateID(candidates, seen, type(source) == "table" and source.sourceID or source)
            end
        end
    end

    local bestFacts
    for _, sourceID in ipairs(candidates) do
        local valid, facts = SourceCanEnterCustomSet(sourceID, definition, false)
        if valid then
            if not bestFacts
                or sourceID == selectedSourceID
                or (facts.visualID == visualID and bestFacts.visualID ~= visualID)
                or sourceID < bestFacts.sourceID then
                bestFacts = facts
            end
            if sourceID == selectedSourceID and facts.collected then break end
        end
    end
    return bestFacts, visualID
end

local function ResolveHiddenConceptSource(definition)
    local transmogLocation = GetTransmogLocation(definition)
    for _, categoryID in ipairs(ResolveCategoryIDs(definition)) do
        local appearances = GetCategoryAppearancesRobust(categoryID, transmogLocation)
        for _, appearance in ipairs(appearances or {}) do
            if appearance.isHideVisual == true then
                local candidates = GetKnownSources(appearance, categoryID, transmogLocation)
                if appearance.sourceID then table.insert(candidates, 1, appearance.sourceID) end
                for _, candidate in ipairs(candidates) do
                    local sourceID = type(candidate) == "table" and candidate.sourceID or candidate
                    local valid, facts = SourceCanEnterCustomSet(sourceID, definition, true, type(candidate) == "table" and candidate or nil)
                    if valid and facts.hideVisual then return facts end
                end
            end
        end
    end
    return nil
end

local function BuildConceptCustomSetList(concept)
    local list = CreateEmptyCustomSetList()
    local expectedSlots = {}
    local resolvedSources = {}
    local unresolved = {}
    local populated = 0

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local selectedSourceID = concept.selections and tonumber(concept.selections[definition.key])
        local hidden = concept.hidden and concept.hidden[definition.key] == true
        if selectedSourceID or hidden then
            local slotID = GetCustomSetSlotID(definition)
            if not slotID then
                table.insert(unresolved, tostring(definition.label or definition.key) .. " (inventory slot unavailable)")
            else
                local facts, visualID
                if hidden then
                    facts = ResolveHiddenConceptSource(definition)
                else
                    facts, visualID = ResolveCollectedConceptSource(concept, definition)
                end

                if not facts then
                    table.insert(unresolved, tostring(definition.label or definition.key))
                else
                    local previous = expectedSlots[slotID]
                    if previous and previous.sourceID ~= facts.sourceID then
                        return nil, 0, nil, nil, string.format(
                            "The concept contains conflicting %s and %s appearances for inventory slot %d. Load the concept, reset the weapon selections, and save it again.",
                            tostring(previous.label or previous.slotKey),
                            tostring(definition.label or definition.key),
                            slotID
                        )
                    end

                    list[slotID] = CreateItemTransmogInfo(facts.sourceID)
                    expectedSlots[slotID] = {
                        slotID = slotID,
                        slotKey = definition.key,
                        slotName = definition.slotName,
                        label = definition.label or definition.key,
                        sourceID = facts.sourceID,
                        visualID = facts.visualID or visualID,
                        hidden = hidden,
                    }
                    resolvedSources[definition.key] = {
                        requestedSourceID = selectedSourceID,
                        resolvedSourceID = facts.sourceID,
                        visualID = facts.visualID or visualID,
                        hidden = hidden,
                        resolvedAt = time(),
                    }
                    if not previous then populated = populated + 1 end
                end
            end
        end
    end

    if #unresolved > 0 then
        return nil, 0, nil, nil,
            "Quest Chronicle could not resolve collected Custom Set sources for: " .. table.concat(unresolved, ", ") .. ". Rescan the wardrobe and save the concept again. Nothing was sent to WoW."
    end

    return list, populated, expectedSlots, resolvedSources
end

local function GetCustomSetInfo(customSetID)
    if not customSetID or not C_TransmogCollection then return nil end
    local name, icon = SafeCall(C_TransmogCollection.GetCustomSetInfo, tonumber(customSetID))
    if not name then return nil end
    return { customSetID = tonumber(customSetID), name = name, icon = icon }
end

function Wardrobe.GetCustomSets()
    local sets = {}
    if not C_TransmogCollection or type(C_TransmogCollection.GetCustomSets) ~= "function" then
        return sets
    end
    for _, customSetID in ipairs(SafeCall(C_TransmogCollection.GetCustomSets) or {}) do
        local info = GetCustomSetInfo(customSetID)
        if info then table.insert(sets, info) end
    end
    table.sort(sets, function(left, right)
        local leftName = string.lower(left.name or "")
        local rightName = string.lower(right.name or "")
        if leftName == rightName then return (left.customSetID or 0) < (right.customSetID or 0) end
        return leftName < rightName
    end)
    return sets
end

local function FindCustomSetByName(name)
    for _, info in ipairs(Wardrobe.GetCustomSets()) do
        if string.lower(info.name or "") == string.lower(name or "") then return info end
    end
    return nil
end

local function GetAppearanceID(info)
    if type(info) ~= "table" then return 0 end
    return tonumber(info.appearanceID or info.sourceID) or 0
end

local function GetVisualIDForSource(sourceID)
    sourceID = tonumber(sourceID)
    if not sourceID or sourceID == 0 then return nil end
    if C_TransmogCollection and C_TransmogCollection.GetAppearanceInfoBySource then
        local info = SafeCall(C_TransmogCollection.GetAppearanceInfoBySource, sourceID)
        if info then return tonumber(info.appearanceID or info.visualID) end
    end
    local source = GetSourceInfo(sourceID)
    return source and tonumber(source.visualID or source.appearanceID or source.itemAppearanceID) or nil
end

local function SortVerificationEntries(entries)
    table.sort(entries, function(left, right)
        if (left.slotID or 0) == (right.slotID or 0) then
            return tostring(left.label or "") < tostring(right.label or "")
        end
        return (left.slotID or 0) < (right.slotID or 0)
    end)
end

local function CompareCustomSetSlots(actualList, expectedSlots)
    local report = {
        expected = 0,
        matched = 0,
        missing = {},
        altered = {},
        verifiedAt = time(),
    }

    for slotID, expected in pairs(expectedSlots or {}) do
        report.expected = report.expected + 1
        local actualSourceID = GetAppearanceID(actualList and actualList[slotID])
        local actualVisualID = GetVisualIDForSource(actualSourceID)
        local sameVisual = expected.visualID and actualVisualID and tonumber(expected.visualID) == tonumber(actualVisualID)
        if actualSourceID == expected.sourceID or sameVisual then
            report.matched = report.matched + 1
        elseif actualSourceID == 0 then
            table.insert(report.missing, {
                slotID = slotID,
                slotKey = expected.slotKey,
                label = expected.label,
                expectedSourceID = expected.sourceID,
                actualSourceID = 0,
            })
        else
            table.insert(report.altered, {
                slotID = slotID,
                slotKey = expected.slotKey,
                label = expected.label,
                expectedSourceID = expected.sourceID,
                actualSourceID = actualSourceID,
                expectedVisualID = expected.visualID,
                actualVisualID = actualVisualID,
            })
        end
    end

    SortVerificationEntries(report.missing)
    SortVerificationEntries(report.altered)
    report.success = report.expected > 0 and report.matched == report.expected
    return report
end

local function JoinVerificationLabels(entries, includeIDs)
    local labels = {}
    for _, entry in ipairs(entries or {}) do
        if includeIDs then
            table.insert(labels, string.format(
                "%s (expected %d, received %d)",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0,
                tonumber(entry.actualSourceID) or 0
            ))
        else
            table.insert(labels, tostring(entry.label or entry.slotKey or entry.slotID))
        end
    end
    return table.concat(labels, ", ")
end

local function FormatVerificationMessage(report)
    if not report then
        return "World of Warcraft did not return Custom Set data for verification."
    end
    if report.success then
        return string.format("Custom Set saved and verified: %d/%d selected slots matched.", report.matched or 0, report.expected or 0)
    end

    local details = {
        string.format("Custom Set verification failed: %d/%d selected slots matched.", report.matched or 0, report.expected or 0),
    }
    if #(report.missing or {}) > 0 then
        table.insert(details, "Missing: " .. JoinVerificationLabels(report.missing, false) .. ".")
    end
    if #(report.altered or {}) > 0 then
        table.insert(details, "Altered: " .. JoinVerificationLabels(report.altered, true) .. ".")
    end
    return table.concat(details, " ")
end

local function PrintVerificationReport(report)
    if not report or report.success then return end
    if QC.Print then
        QC.Print(string.format("Custom Set verification: %d/%d selected slots matched.", report.matched or 0, report.expected or 0))
    end
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        for _, entry in ipairs(report.missing or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "  |cffff5555Missing|r %s: expected source %d, received an empty slot.",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0
            ))
        end
        for _, entry in ipairs(report.altered or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "  |cffffaa33Altered|r %s: expected source %d, received source %d.",
                tostring(entry.label or entry.slotKey or entry.slotID),
                tonumber(entry.expectedSourceID) or 0,
                tonumber(entry.actualSourceID) or 0
            ))
        end
    end
end

local function FinishCustomSetSync(success, message, customSetID, report)
    local request = pendingCustomSetSync
    if not request then return end
    local store = EnsureConceptStore()
    local concept = store[request.conceptID]
    if concept then
        concept.customSetSyncPendingAt = nil
        if customSetID then
            -- Keep the link even when verification finds missing slots. The set
            -- exists and the Update Custom Set action is the repair path.
            concept.blizzardCustomSetID = tonumber(customSetID)
            concept.blizzardCustomSetName = request.name
            concept.blizzardCustomSetIcon = request.icon
        end
        concept.customSetVerification = report
        concept.customSetVerifiedAt = report and report.verifiedAt or time()
        if request.resolvedSources then
            concept.customSetResolvedSources = request.resolvedSources
        end
        if success and customSetID then
            concept.customSetSyncedAt = time()
            concept.customSetSyncError = nil
        else
            concept.customSetSyncError = message
        end
    end
    pendingCustomSetSync = nil
    if not success then PrintVerificationReport(report) end
    if QC.Notify then
        QC.Notify("WARDROBE_CUSTOM_SET_SYNCED", concept, success, message, report)
        QC.Notify("WARDROBE_CONCEPTS_CHANGED", concept)
    end
end

local function TryVerifyPendingCustomSet(finalAttempt)
    local request = pendingCustomSetSync
    if not request then return false, false end
    local customSetID = request.customSetID
    if not customSetID then
        local info = FindCustomSetByName(request.name)
        customSetID = info and info.customSetID
    end
    if not customSetID then
        return false, false
    end

    local actual = SafeCall(C_TransmogCollection.GetCustomSetItemTransmogInfoList, tonumber(customSetID))
    if type(actual) ~= "table" then
        return false, false
    end

    local report = CompareCustomSetSlots(actual, request.expectedSlots)
    local message = FormatVerificationMessage(report)
    if report.success then
        FinishCustomSetSync(true, message, customSetID, report)
        return true, true, message
    elseif finalAttempt then
        FinishCustomSetSync(false, message, customSetID, report)
        return true, false, message
    end
    return false, false, message
end

function Wardrobe.IsCustomSetSavingSupported()
    return C_TransmogCollection
        and type(C_TransmogCollection.GetCustomSets) == "function"
        and type(C_TransmogCollection.NewCustomSet) == "function"
        and type(C_TransmogCollection.ModifyCustomSet) == "function"
        and type(C_TransmogCollection.GetCustomSetItemTransmogInfoList) == "function"
end

function Wardrobe.GetConceptCustomSetStatus(concept)
    if not concept then return "local", "Quest Chronicle only" end
    if pendingCustomSetSync and pendingCustomSetSync.conceptID == concept.id then
        return "pending", "Saving Custom Set..."
    end
    if concept.blizzardCustomSetID then
        local info = GetCustomSetInfo(concept.blizzardCustomSetID)
        if not info then return "missing", "Linked Custom Set missing" end
        local report = concept.customSetVerification
        if concept.customSetSyncError and report then
            return "error", string.format("Custom Set mismatch: %d/%d slots", report.matched or 0, report.expected or 0)
        end
        return "synced", "Custom Set: " .. tostring(info.name)
    end
    if concept.customSetSyncError then return "error", "Custom Set save failed" end
    return "local", "Quest Chronicle only"
end

function Wardrobe.SaveConceptToCustomSet(conceptID, mode, targetCustomSetID)
    LoadTransmogSupport()
    if not Wardrobe.IsCustomSetSavingSupported() then
        return false, "World of Warcraft's Custom Sets API is unavailable on this client."
    end
    if pendingCustomSetSync then
        return false, "Another Custom Set save is still awaiting confirmation."
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Custom Sets cannot be changed during combat."
    end

    local store = EnsureConceptStore()
    local concept = store[conceptID]
    if not concept then return false, "That outfit concept is no longer available." end
    local name = tostring(concept.name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return false, "Give the concept a name before saving it to Custom Sets." end
    if C_TransmogCollection.IsValidCustomSetName and SafeCall(C_TransmogCollection.IsValidCustomSetName, name) ~= true then
        return false, "World of Warcraft does not allow that Custom Set name. Rename the concept and try again."
    end

    mode = mode or "auto"
    local customSetID = tonumber(targetCustomSetID)
    if mode == "auto" then
        customSetID = tonumber(concept.blizzardCustomSetID)
        if customSetID and GetCustomSetInfo(customSetID) then
            mode = "update"
        else
            local sameName = FindCustomSetByName(name)
            if sameName then
                customSetID = sameName.customSetID
                mode = "replace"
            else
                customSetID = nil
                mode = "new"
            end
        end
    elseif mode == "replace" then
        if not customSetID or not GetCustomSetInfo(customSetID) then
            return false, "Choose an existing Custom Set to replace."
        end
    elseif mode == "update" then
        customSetID = tonumber(concept.blizzardCustomSetID)
        if not customSetID or not GetCustomSetInfo(customSetID) then
            return false, "The linked Custom Set is missing. Use Save as New or Replace Existing."
        end
    elseif mode ~= "new" then
        return false, "Unknown Custom Set save mode."
    end

    if mode == "new" then
        local count = #Wardrobe.GetCustomSets()
        local maximum = tonumber(SafeCall(C_TransmogCollection.GetNumMaxCustomSets)) or 0
        if maximum > 0 and count >= maximum then
            return false, "All WoW Custom Set slots are full. Choose Replace Existing instead."
        end
    end

    local list, populated, expectedSlots, resolvedSources, buildError = BuildConceptCustomSetList(concept)
    if not list then return false, buildError or "Unable to build the Custom Set slot list." end
    if populated == 0 then return false, "This concept has no selected appearances to save." end
    local icon = GetConceptOutfitIcon(concept)

    if mode == "replace" then
        local previousInfo = GetCustomSetInfo(customSetID)
        local previousList = SafeCall(C_TransmogCollection.GetCustomSetItemTransmogInfoList, customSetID)
        if previousInfo and type(previousList) == "table" then
            concept.customSetReplacementBackups = concept.customSetReplacementBackups or {}
            table.insert(concept.customSetReplacementBackups, {
                customSetID = customSetID,
                name = previousInfo.name,
                icon = previousInfo.icon,
                itemTransmogInfoList = previousList,
                backedUpAt = time(),
            })
            while #concept.customSetReplacementBackups > 5 do table.remove(concept.customSetReplacementBackups, 1) end
        end
    end

    local ok, result
    if mode == "new" then
        ok, result = TryCall(C_TransmogCollection.NewCustomSet, name, icon, list)
        if ok then customSetID = tonumber(result) end
    else
        ok, result = TryCall(C_TransmogCollection.ModifyCustomSet, customSetID, list)
        if ok and C_TransmogCollection.RenameCustomSet then
            local renameOK, renameError = TryCall(C_TransmogCollection.RenameCustomSet, customSetID, name)
            if not renameOK then return false, "The appearances were saved, but WoW rejected the Custom Set name: " .. tostring(renameError) end
        end
    end
    if not ok then return false, "World of Warcraft rejected the Custom Set save: " .. tostring(result) end

    pendingCustomSetSync = {
        conceptID = concept.id,
        customSetID = customSetID,
        name = name,
        icon = icon,
        mode = mode,
        itemTransmogInfoList = list,
        expectedSlots = expectedSlots,
        resolvedSources = resolvedSources,
        startedAt = time(),
    }
    concept.customSetSyncPendingAt = time()
    concept.customSetSyncError = nil
    concept.customSetVerification = nil

    local resolved, verified, verificationMessage = TryVerifyPendingCustomSet(false)
    if resolved then
        return verified, verificationMessage
    end

    if C_Timer and C_Timer.After then
        local request = pendingCustomSetSync
        C_Timer.After(CUSTOM_SET_SYNC_TIMEOUT, function()
            if pendingCustomSetSync == request then
                local finished = TryVerifyPendingCustomSet(true)
                if not finished and pendingCustomSetSync == request then
                    FinishCustomSetSync(false, "World of Warcraft did not return the saved Custom Set for verification.", customSetID)
                end
            end
        end)
    end
    return true, mode == "update" and "Updating linked Custom Set and verifying every selected slot..." or "Saving to WoW Custom Sets and verifying every selected slot..."
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
    if source.sourceIsCollected ~= true then
        return false, "The visual is unlocked, but this particular preview source is not collected. Rescan the wardrobe to bind a collected source."
    end
    if not source.isCollected and not source.appearanceIsCollected then
        return false, "This appearance is not collected."
    end
    if source.appearanceCanDisplayOnPlayer == false then
        return false, "This character cannot display the appearance."
    end
    if source.isHideVisual then
        return false, "Hidden-slot visuals are not included in the appearance browser."
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
    local sourceIsCollected = IsSourceCollected(sourceID, source)
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

local function ScheduleLoginRefresh()
    if loginRefreshScheduled then
        return
    end
    loginRefreshScheduled = true

    local cache = EnsureCache()
    if not C_Timer or type(C_Timer.After) ~= "function" then
        cache.loginRefreshPending = false
        cache.loginRefreshDeferredReason = "TIMER_UNAVAILABLE"
        return
    end

    loginRefreshToken = loginRefreshToken + 1
    local token = loginRefreshToken
    local attempts = 0
    cache.loginRefreshPending = true
    cache.loginRefreshDeferredReason = nil
    if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_SCHEDULED") end

    local function TryRefresh()
        if token ~= loginRefreshToken then
            cache.loginRefreshPending = false
            return
        end

        attempts = attempts + 1
        local blockedByCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
        local blockedByWardrobe = IsBlizzardWardrobeVisible()
        if Wardrobe.scanning or blockedByCombat or blockedByWardrobe then
            if attempts < LOGIN_REFRESH_MAX_ATTEMPTS then
                C_Timer.After(LOGIN_REFRESH_RETRY_DELAY, TryRefresh)
                return
            end

            cache.loginRefreshPending = false
            cache.loginRefreshDeferredReason = blockedByCombat and "COMBAT" or (blockedByWardrobe and "BLIZZARD_WARDROBE_OPEN" or "SCAN_BUSY")
            local settings = QC.GetSettings and QC.GetSettings() or {}
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print("Login wardrobe refresh deferred. Use Scan Collection when ready.")
            end
            if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_DEFERRED", cache.loginRefreshDeferredReason) end
            return
        end

        cache.loginRefreshPending = false
        local started, message = Wardrobe.Scan(true, "AUTO_LOGIN")
        if not started then
            cache.loginRefreshDeferredReason = message or "SCAN_UNAVAILABLE"
            if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_DEFERRED", cache.loginRefreshDeferredReason) end
        end
    end

    C_Timer.After(LOGIN_REFRESH_DELAY, TryRefresh)
end

function Wardrobe.MarkDirty(reason)
    local cache = EnsureCache()
    cache.dirty = true
    cache.dirtyReason = reason or "COLLECTION_CHANGED"
    cache.lastCollectionChangeAt = time and time() or 0
    if QC.Notify then
        QC.Notify("WARDROBE_CACHE_DIRTY", cache.dirtyReason)
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

    loginRefreshToken = loginRefreshToken + 1
    cache.loginRefreshPending = false
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
        if cache.scanTrigger == "AUTO_LOGIN" then
            cache.lastLoginRefreshAt = cache.scanCompletedAt
            cache.loginRefreshDeferredReason = nil
            local settings = QC.GetSettings and QC.GetSettings() or {}
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print(string.format("Wardrobe refreshed for this login: %d previewable appearances in %.1f seconds.", cache.totalVisuals or 0, (cache.scanDurationMS or 0) / 1000))
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
            if slotKey ~= "OFF_HAND" and state.linkWeaponHands then
                SynchronizeLinkedOffHand(state, source, state.styleMode, nil, state.selections.OFF_HAND)
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

    -- v1.6.5 deliberately restores the synchronous player-model baseline used
    -- before the v1.6.3/v1.6.4 preview experiments. SetUnit establishes the
    -- equipped actor, then TryOn overlays the selected appearances without
    -- replacing the actor or scheduling competing model-load callbacks.
    SafeCall(model.SetUnit, model, "player")
    local applied = 0
    local failedSlots = {}
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
            if valid and source.sourceID and type(model.TryOn) == "function" then
                local targetHand
                if definition.slotName == "MAINHANDSLOT" or definition.slotName == "SECONDARYHANDSLOT" then
                    targetHand = definition.slotName
                end
                local ok, result = pcall(model.TryOn, model, source.sourceID, targetHand)
                local successValue = Enum and Enum.ItemTryOnReason and Enum.ItemTryOnReason.Success
                if ok and (result == nil or successValue == nil or result == successValue) then
                    applied = applied + 1
                else
                    table.insert(failedSlots, definition.label)
                end
            end
        end
    end

    model.qcPreviewLastApplied = applied
    model.qcPreviewFailedSlots = failedSlots
    if QC.Notify then
        QC.Notify("WARDROBE_PREVIEW_APPLIED", applied, failedSlots)
    end

    if #failedSlots > 0 then
        return false, string.format(
            "Previewed %d selected appearances; WoW rejected: %s.",
            applied,
            table.concat(failedSlots, ", ")
        )
    end
    return true, string.format("Previewed %d selected appearances.", applied)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
eventFrame:RegisterEvent("TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED")
pcall(eventFrame.RegisterEvent, eventFrame, "TRANSMOG_CUSTOM_SETS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_EQUIPMENT_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_SPECIALIZATION_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "TRAIT_CONFIG_UPDATED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local cache = EnsureCache()
        if not loginRefreshScheduled then
            cache.loginRefreshPending = false
        end
        EnsurePreviewState()
        local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
        if character and cache.characterKey and cache.characterKey ~= character.key then
            ResetCache(cache, "STALE")
            cache.dirtyReason = "CHARACTER_CHANGED"
        end
        ScheduleLoginRefresh()
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "TRAIT_CONFIG_UPDATED"
    then
        local eventArg1 = select(1, ...)
        local now = GetTime and GetTime()
        internalUsabilityUpdateUntil = now and (now + 1.0) or nil
        SafeCall(C_TransmogCollection and C_TransmogCollection.UpdateUsableAppearances)
        local function NotifyCapabilities()
            local state = EnsurePreviewState()
            local capabilities = NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
            if QC.Notify then
                QC.Notify("WARDROBE_WEAPON_TOPOLOGY_CHANGED", capabilities.topology, eventArg1)
                QC.Notify("WARDROBE_WEAPON_CAPABILITIES_CHANGED", capabilities, event)
            end
        end
        NotifyCapabilities()
        if C_Timer and C_Timer.After then C_Timer.After(0.25, NotifyCapabilities) end
    elseif event == "TRANSMOG_CUSTOM_SETS_CHANGED" then
        local request = pendingCustomSetSync
        local resolved = TryVerifyPendingCustomSet(false)
        if request and not resolved and C_Timer and C_Timer.After then
            C_Timer.After(0.20, function()
                if pendingCustomSetSync == request then
                    TryVerifyPendingCustomSet(true)
                end
            end)
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
