local QC = QuestChronicle
QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe
Wardrobe._Private = Wardrobe._Private or {}
local P = Wardrobe._Private


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

P.LOGIN_REFRESH_DELAY = 3.0
P.LOGIN_REFRESH_RETRY_DELAY = 2.0
P.LOGIN_REFRESH_MAX_ATTEMPTS = 15
P.loginRefreshToken = 0
P.loginRefreshScheduled = false
P.internalUsabilityUpdateUntil = nil
P.pendingCustomSetSync = nil
P.CUSTOM_SET_SYNC_TIMEOUT = 5.0

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

P.slotByKey = {}
for _, definition in ipairs(Wardrobe.slotDefinitions) do
    P.slotByKey[definition.key] = definition
end

function P.SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end
    local ok, a, b, c, d, e, f = pcall(func, ...)
    if ok then
        return a, b, c, d, e, f
    end
    return nil
end

function P.TryCall(func, ...)
    if type(func) ~= "function" then
        return false, "That Blizzard Custom Set function is unavailable."
    end
    local ok, a, b, c = pcall(func, ...)
    if not ok then
        return false, tostring(a or "Blizzard rejected the Custom Set request.")
    end
    return true, a, b, c
end

function P.ResetCache(cache, state)
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

function P.EnsureCache()
    local database = QC.GetDatabase()
    database.wardrobe = database.wardrobe or {}
    local cache = database.wardrobe
    if cache.cacheVersion ~= Wardrobe.CACHE_VERSION then
        local previousCacheVersion = cache.cacheVersion
        P.ResetCache(cache, "STALE")
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

function P.EnsurePreviewState()
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

function P.CopyPrimitiveMap(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
            copy[key] = value
        end
    end
    return copy
end

function P.EnsureConceptStore()
    local cache = P.EnsureCache()
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
        if concept.customSetSyncPendingAt and (not P.pendingCustomSetSync or P.pendingCustomSetSync.conceptID ~= concept.id) then
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

function P.NormalizePreferenceKey(value)
    local text = string.lower(tostring(value or "unknown-zone"))
    text = text:gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
    return text ~= "" and text or "unknown-zone"
end

function P.GetZonePreferenceKey(context)
    context = context or (QC.ZoneStyle and QC.ZoneStyle.GetCurrentContext and QC.ZoneStyle.GetCurrentContext()) or {}
    return P.NormalizePreferenceKey(context.provenanceKey or context.zoneKey or context.profileKey or context.zone),
        tostring(context.provenanceLabel or context.zone or context.profileLabel or "Unknown Zone")
end

function P.GetZonePreferenceStore(context, create)
    local cache = P.EnsureCache()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
    local characterKey = character and character.key or "UNKNOWN"
    local zoneKey, zoneLabel = P.GetZonePreferenceKey(context)
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

function P.LoadTransmogSupport()
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

function P.ResolveCategoryIDs(definition)
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

P.weaponSubtypeByCategoryID = {}

function P.ResolveWeaponSubtypeCategoryID(definition)
    if not definition then return nil end
    local categoryID
    if Enum and Enum.TransmogCollectionType then
        categoryID = Enum.TransmogCollectionType[definition.categoryName]
    end
    categoryID = categoryID or definition.fallbackCategoryID
    definition.categoryID = categoryID
    if categoryID then P.weaponSubtypeByCategoryID[tonumber(categoryID)] = definition.key end
    return categoryID
end

function P.RefreshWeaponSubtypeCategoryMap()
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        P.ResolveWeaponSubtypeCategoryID(Wardrobe.weaponSubtypeDefinitions[subtypeKey])
    end
end

function P.GetWeaponSubtypeKeyForCategoryID(categoryID)
    categoryID = tonumber(categoryID)
    if not categoryID then return nil end
    if not P.weaponSubtypeByCategoryID[categoryID] then P.RefreshWeaponSubtypeCategoryMap() end
    return P.weaponSubtypeByCategoryID[categoryID]
end

function P.GetWeaponSubtypeKeysForFamily(familyKey)
    local keys = {}
    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        if definition and definition.familyKey == familyKey then table.insert(keys, subtypeKey) end
    end
    return keys
end

function P.GetTransmogLocation(definition)
    if not P.LoadTransmogSupport() then
        return nil
    end
    local appearanceType = Enum and Enum.TransmogType and Enum.TransmogType.Appearance or 0
    return P.SafeCall(TransmogUtil.GetTransmogLocation, definition.slotName, appearanceType, false)
end

function P.GetLocationData(transmogLocation)
    if transmogLocation and type(transmogLocation.GetData) == "function" then
        return P.SafeCall(transmogLocation.GetData, transmogLocation)
    end
    return nil
end

function P.GetItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return P.SafeCall(C_Item.GetItemIconByID, itemID)
    elseif _G and type(_G.GetItemIcon) == "function" then
        return P.SafeCall(_G.GetItemIcon, itemID)
    end
end

function P.GetSourceItemID(sourceID, source)
    if source and source.itemID then
        return source.itemID
    end
    if C_TransmogCollection and C_TransmogCollection.GetSourceItemID then
        local itemID = P.SafeCall(C_TransmogCollection.GetSourceItemID, sourceID)
        if itemID then
            return itemID
        end
    end
    if C_Transmog and C_Transmog.GetItemIDForSource then
        return P.SafeCall(C_Transmog.GetItemIDForSource, sourceID)
    end
end

function P.GetCurrentClassID()
    if UnitClass then
        local _, _, classID = UnitClass("player")
        return classID
    end
end

function P.IsBlizzardWardrobeVisible()
    if TransmogFrame and TransmogFrame.IsShown and TransmogFrame:IsShown() then
        return true
    end
    if WardrobeCollectionFrame and WardrobeCollectionFrame.IsShown and WardrobeCollectionFrame:IsShown() then
        return true
    end
    return false
end

function P.GetSearchType()
    return Enum and Enum.TransmogSearchType and Enum.TransmogSearchType.Items or 1
end

function P.GetSearchBoxText()
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
            local text = P.SafeCall(box.GetText, box)
            if text and text ~= "" then
                return text
            end
        end
    end
    return ""
end

function P.CaptureCollectionState()
    local state = {
        collectedShown = P.SafeCall(C_TransmogCollection.GetCollectedShown),
        uncollectedShown = P.SafeCall(C_TransmogCollection.GetUncollectedShown),
        allFactionsShown = P.SafeCall(C_TransmogCollection.GetAllFactionsShown),
        allRacesShown = P.SafeCall(C_TransmogCollection.GetAllRacesShown),
        classFilter = P.SafeCall(C_TransmogCollection.GetClassFilter),
        searchText = P.GetSearchBoxText(),
        sourceTypes = {},
    }

    local sourceCount = tonumber(P.SafeCall(C_TransmogCollection.GetNumTransmogSources)) or 0
    for index = 1, sourceCount do
        state.sourceTypes[index] = P.SafeCall(C_TransmogCollection.IsSourceTypeFilterChecked, index)
    end
    return state
end

function P.ApplyScanCollectionState()
    -- Ask WoW for the broadest possible collection view and filter collected
    -- appearances locally. This avoids an empty result when the native Wardrobe
    -- has a stale collected-only/search filter that has not finished rebuilding.
    SafeCall(C_TransmogCollection.SetCollectedShown, true)
    P.SafeCall(C_TransmogCollection.SetUncollectedShown, true)
    P.SafeCall(C_TransmogCollection.SetAllFactionsShown, true)
    P.SafeCall(C_TransmogCollection.SetAllRacesShown, true)
    local classID = P.GetCurrentClassID()
    if classID then
        P.SafeCall(C_TransmogCollection.SetClassFilter, classID)
    end
    P.SafeCall(C_TransmogCollection.SetAllSourceTypeFilters, true)
    P.SafeCall(C_TransmogCollection.ClearSearch, P.GetSearchType())
end

function P.RestoreCollectionState(state)
    if not state then
        return
    end
    if state.collectedShown ~= nil then
        P.SafeCall(C_TransmogCollection.SetCollectedShown, state.collectedShown)
    end
    if state.uncollectedShown ~= nil then
        P.SafeCall(C_TransmogCollection.SetUncollectedShown, state.uncollectedShown)
    end
    if state.allFactionsShown ~= nil then
        P.SafeCall(C_TransmogCollection.SetAllFactionsShown, state.allFactionsShown)
    end
    if state.allRacesShown ~= nil then
        P.SafeCall(C_TransmogCollection.SetAllRacesShown, state.allRacesShown)
    end
    if state.classFilter ~= nil then
        P.SafeCall(C_TransmogCollection.SetClassFilter, state.classFilter)
    end
    for index, checked in pairs(state.sourceTypes or {}) do
        if checked ~= nil then
            P.SafeCall(C_TransmogCollection.SetSourceTypeFilter, index, checked)
        end
    end
    if state.searchText and state.searchText ~= "" then
        P.SafeCall(C_TransmogCollection.SetSearch, P.GetSearchType(), state.searchText)
    else
        P.SafeCall(C_TransmogCollection.ClearSearch, P.GetSearchType())
    end
end
