local QC = QuestChronicle

QC.Wardrobe = QC.Wardrobe or {}
local Wardrobe = QC.Wardrobe

Wardrobe.CACHE_VERSION = 1
Wardrobe.PAGE_SIZE = 8

local function EnumValue(name, fallback)
    return Enum and Enum.TransmogCollectionType and Enum.TransmogCollectionType[name] or fallback
end

-- Several weapon collection categories are combined into practical preview slots.
-- Fallback values preserve compatibility with clients where enum tables load late.
Wardrobe.slotDefinitions = {
    { key = "HEAD", label = "Head", categoryIDs = { EnumValue("Head", 1) } },
    { key = "SHOULDER", label = "Shoulders", categoryIDs = { EnumValue("Shoulder", 3) } },
    { key = "BACK", label = "Back", categoryIDs = { EnumValue("Back", 2) } },
    { key = "CHEST", label = "Chest", categoryIDs = { EnumValue("Chest", 6) } },
    { key = "SHIRT", label = "Shirt", categoryIDs = { EnumValue("Shirt", 4) } },
    { key = "TABARD", label = "Tabard", categoryIDs = { EnumValue("Tabard", 5) } },
    { key = "WRIST", label = "Wrists", categoryIDs = { EnumValue("Wrist", 7) } },
    { key = "HANDS", label = "Hands", categoryIDs = { EnumValue("Hands", 8) } },
    { key = "WAIST", label = "Waist", categoryIDs = { EnumValue("Waist", 9) } },
    { key = "LEGS", label = "Legs", categoryIDs = { EnumValue("Legs", 10) } },
    { key = "FEET", label = "Feet", categoryIDs = { EnumValue("Feet", 11) } },
    {
        key = "ONE_HAND", label = "One-Hand",
        categoryIDs = {
            EnumValue("OneHAxe", 13), EnumValue("OneHSword", 14), EnumValue("OneHMace", 15),
            EnumValue("Dagger", 16), EnumValue("Fist", 17), EnumValue("Warglaives", 28), EnumValue("Wand", 12),
        },
    },
    {
        key = "TWO_HAND", label = "Two-Hand",
        categoryIDs = {
            EnumValue("TwoHAxe", 20), EnumValue("TwoHSword", 21), EnumValue("TwoHMace", 22),
            EnumValue("Staff", 23), EnumValue("Polearm", 24),
        },
    },
    {
        key = "RANGED", label = "Ranged",
        categoryIDs = { EnumValue("Bow", 25), EnumValue("Gun", 26), EnumValue("Crossbow", 27) },
    },
    {
        key = "OFF_HAND", label = "Off-Hand",
        categoryIDs = { EnumValue("Shield", 18), EnumValue("Holdable", 19) },
    },
}

local slotByKey = {}
for _, definition in ipairs(Wardrobe.slotDefinitions) do
    slotByKey[definition.key] = definition
end

local function EnsureCache()
    local database = QC.GetDatabase()
    database.wardrobe = database.wardrobe or {}
    local cache = database.wardrobe
    cache.cacheVersion = cache.cacheVersion or Wardrobe.CACHE_VERSION
    cache.bySlot = cache.bySlot or {}
    cache.scanState = cache.scanState or "NEVER"
    cache.totalSources = cache.totalSources or 0
    cache.totalVisuals = cache.totalVisuals or 0
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

local function GetItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return SafeCall(C_Item.GetItemIconByID, itemID)
    elseif GetItemIcon then
        return SafeCall(GetItemIcon, itemID)
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
    if source.canDisplayOnPlayer == false then
        return false, "This character cannot display the appearance."
    end
    if source.isValidSourceForPlayer == false then
        return false, "The appearance is not valid for this character."
    end
    if source.meetsTransmogPlayerCondition == false then
        return false, source.useError or "A player condition is not met."
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
    local sourceID = source and source.sourceID
    if not sourceID then
        return nil
    end
    local itemID = GetSourceItemID(sourceID, source)
    local normalized = {
        sourceID = sourceID,
        visualID = source.visualID or source.appearanceID or (appearance and appearance.visualID),
        itemID = itemID,
        name = source.name,
        quality = source.quality,
        sourceType = source.sourceType,
        inventoryType = source.invType,
        categoryID = source.categoryID or categoryID,
        slotKey = slotKey,
        isCollected = source.isCollected == true,
        isHideVisual = source.isHideVisual == true,
        playerCanCollect = source.playerCanCollect,
        isValidSourceForPlayer = source.isValidSourceForPlayer,
        canDisplayOnPlayer = source.canDisplayOnPlayer,
        meetsTransmogPlayerCondition = source.meetsTransmogPlayerCondition,
        useError = source.useError,
        icon = GetItemIcon(itemID),
    }
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
    local rawCount = 0

    for _, categoryID in ipairs(definition.categoryIDs or {}) do
        if categoryID and C_TransmogCollection and C_TransmogCollection.GetCategoryAppearances then
            local appearances = SafeCall(C_TransmogCollection.GetCategoryAppearances, categoryID) or {}
            for _, appearance in ipairs(appearances) do
                if appearance.isCollected then
                    local sources = SafeCall(C_TransmogCollection.GetAppearanceSources, appearance.visualID, categoryID) or {}
                    for _, source in ipairs(sources) do
                        rawCount = rawCount + 1
                        if source.isCollected then
                            local normalized = NormalizeSource(source, appearance, definition.key, categoryID)
                            if normalized then
                                local valid = Wardrobe.ValidateSource(normalized, definition.key)
                                if valid then
                                    local visualKey = normalized.visualID or normalized.sourceID
                                    if BetterSource(normalized, visuals[visualKey]) then
                                        visuals[visualKey] = normalized
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
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
    return results, rawCount
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

    local cache = EnsureCache()
    if not force and cache.scanState == "COMPLETE" and not cache.dirty then
        return false, "The wardrobe cache is current."
    end

    Wardrobe.scanning = true
    cache.scanState = "SCANNING"
    cache.scanStartedAt = time()
    cache.scanError = nil
    cache.bySlot = {}
    cache.totalSources = 0
    cache.totalVisuals = 0

    local index = 1
    local function Step()
        local definition = Wardrobe.slotDefinitions[index]
        if not definition then
            Wardrobe.scanning = false
            cache.scanState = "COMPLETE"
            cache.scanCompletedAt = time()
            cache.dirty = false
            cache.dirtyReason = nil
            cache.characterKey = QC.GetCurrentCharacter().key
            if QC.Notify then
                QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
            end
            return
        end

        local ok, sources, rawCount = pcall(ScanSlot, definition)
        if ok then
            cache.bySlot[definition.key] = sources or {}
            cache.totalSources = cache.totalSources + (rawCount or 0)
            cache.totalVisuals = cache.totalVisuals + #(sources or {})
        else
            cache.bySlot[definition.key] = {}
            cache.scanError = tostring(sources)
        end

        if QC.Notify then
            QC.Notify("WARDROBE_SCAN_PROGRESS", index, #Wardrobe.slotDefinitions, definition.key, #(cache.bySlot[definition.key] or {}))
        end
        index = index + 1
        if C_Timer and C_Timer.After then
            C_Timer.After(0, Step)
        else
            Step()
        end
    end

    Step()
    return true, "Wardrobe scan started."
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
        EnsureCache()
        EnsurePreviewState()
    else
        Wardrobe.MarkDirty(event)
    end
end)
