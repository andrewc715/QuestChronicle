local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.ChooseRandomSource(slotKey, excludeSourceID, styleMode, styleContext)
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
        return styleEngine.ChooseWeightedSource(candidates, P.slotByKey[slotKey], styleMode, styleContext, excludeSourceID)
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

function P.SetRandomSelection(state, slotKey, reroll, styleMode, styleContext)
    local current = reroll and state.selections[slotKey] or nil
    local source = P.ChooseRandomSource(slotKey, current, styleMode, styleContext)
    if not source then
        if not reroll then P.SetSelectedSource(state, slotKey, nil) end
        return false
    end
    P.SetSelectedSource(state, slotKey, source)
    if not state.hidden[slotKey] and QC.ZoneStyle and QC.ZoneStyle.AddSourceToGenerationContext then
        QC.ZoneStyle.AddSourceToGenerationContext(styleContext, source)
    end
    return true
end

P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }
P.ARMOR_GENERATION_ORDER = { "CHEST", "SHOULDER", "LEGS", "WAIST", "HEAD", "HANDS", "FEET", "WRIST", "BACK", "SHIRT", "TABARD" }

function P.CreateStyleGenerationContext(state, styleEngine, baseContext, excludedSlotKey, lockedOnly)
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
            styleEngine.AddSourceToGenerationContext(context, P.GetSourceByID(slotKey, state.selections[slotKey]))
        end
    end
    if styleEngine.PrepareGenerationEligibilityContext then
        styleEngine.PrepareGenerationEligibilityContext(context)
    end
    return context
end

function P.GetEquippedItemInfo(slotName)
    local slotID = P.SafeCall(GetInventorySlotInfo, slotName)
    if not slotID then
        return nil
    end
    local itemLink = P.SafeCall(GetInventoryItemLink, "player", slotID)
    if itemLink then
        return itemLink
    end
    return P.SafeCall(GetInventoryItemID, "player", slotID)
end

function P.GetItemEquipLocation(itemInfo)
    if not itemInfo then return nil end

    -- GetItemInfoInstant is synchronous and its fourth return value is the
    -- authoritative itemEquipLoc (for example INVTYPE_2HWEAPON). Prefer it to
    -- broad transmog categories, because a two-handed sword can still be valid
    -- for a generic sword appearance category.
    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if type(getInstant) == "function" then
        local _, _, _, equipLoc = P.SafeCall(getInstant, itemInfo)
        if equipLoc and equipLoc ~= "" then
            return equipLoc
        end
    end

    -- Fall back to the cached item-info API when instant data is unavailable.
    local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getInfo) == "function" then
        local _, _, _, _, _, _, _, _, equipLoc = P.SafeCall(getInfo, itemInfo)
        if equipLoc and equipLoc ~= "" then
            return equipLoc
        end
    end

    return nil
end

function P.EquipLocationSupportsWeaponFamily(equipLoc, familyKey)
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

function P.ItemSupportsWeaponFamily(itemInfo, familyKey)
    if not itemInfo then return false end

    -- The equipped item's inventory location defines its hand topology. Do not
    -- let IsCategoryValidForItem blur a two-handed sword into the one-hand sword
    -- collection simply because both are swords.
    local equipLoc = P.GetItemEquipLocation(itemInfo)
    local equipResult = P.EquipLocationSupportsWeaponFamily(equipLoc, familyKey)
    if equipResult ~= nil then
        return equipResult
    end

    -- Category compatibility is only a last-resort fallback for unusual items
    -- whose equipment location is not available yet.
    local definition = P.slotByKey[familyKey]
    if definition and C_TransmogCollection and type(C_TransmogCollection.IsCategoryValidForItem) == "function" then
        for _, categoryID in ipairs(P.ResolveCategoryIDs(definition)) do
            if P.SafeCall(C_TransmogCollection.IsCategoryValidForItem, categoryID, itemInfo) == true then
                return true
            end
        end
    end

    return false
end

function P.CountCachedWeaponSubtype(subtypeKey)
    local subtype = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not subtype then return 0 end
    local categoryID = P.ResolveWeaponSubtypeCategoryID(subtype)
    local count = 0
    for _, source in ipairs(Wardrobe.GetSlotSources(subtype.familyKey)) do
        if tonumber(source.categoryID) == tonumber(categoryID) then count = count + 1 end
    end
    return count
end

function P.HasCachedWeaponFamily(familyKey)
    for _, subtypeKey in ipairs(P.GetWeaponSubtypeKeysForFamily(familyKey)) do
        if P.CountCachedWeaponSubtype(subtypeKey) > 0 then return true end
    end
    return false
end

function P.GetPhysicalWeaponKind(equipLoc)
    if equipLoc == "INVTYPE_2HWEAPON" then return "TWO_HAND" end
    if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" then return "RANGED" end
    if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND" then return "ONE_HAND" end
    if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return "OFF_HAND" end
    return equipLoc and "UNKNOWN" or "NONE"
end

function P.GetEquippedWeaponSubtype(itemInfo)
    if not itemInfo or not C_TransmogCollection then return nil end
    local _, sourceID = P.SafeCall(C_TransmogCollection.GetItemInfo, itemInfo)
    if sourceID and C_TransmogCollection.GetCategoryForItem then
        local categoryID = P.SafeCall(C_TransmogCollection.GetCategoryForItem, sourceID)
        local subtypeKey = P.GetWeaponSubtypeKeyForCategoryID(categoryID)
        if subtypeKey then return subtypeKey end
    end
    return nil
end

function Wardrobe.GetWeaponTopology()
    local mainItem = P.GetEquippedItemInfo("MAINHANDSLOT")
    local offItem = P.GetEquippedItemInfo("SECONDARYHANDSLOT")
    local mainEquipLoc = P.GetItemEquipLocation(mainItem)
    local offEquipLoc = P.GetItemEquipLocation(offItem)
    local mainKind = P.GetPhysicalWeaponKind(mainEquipLoc)
    local offKind = P.GetPhysicalWeaponKind(offEquipLoc)
    local topology = {
        mainItem = mainItem,
        offItem = offItem,
        mainEquipLoc = mainEquipLoc,
        offEquipLoc = offEquipLoc,
        mainHandKind = mainKind,
        offHandKind = offKind,
        mainPhysicalSubtype = P.GetEquippedWeaponSubtype(mainItem),
        offPhysicalSubtype = P.GetEquippedWeaponSubtype(offItem),
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

function P.GetTransmogOutfitSlotForInventorySlotName(slotName)
    if not slotName or not GetInventorySlotInfo then return nil end
    if not C_TransmogOutfitInfo or type(C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot) ~= "function" then
        return nil
    end
    local inventorySlotID = P.SafeCall(GetInventorySlotInfo, slotName)
    if inventorySlotID == nil then return nil end

    -- GetInventorySlotInfo returns the traditional 1-based INVSLOT_* value
    -- (Main Hand 16, Off Hand 17). GetTransmogOutfitSlotFromInventorySlot
    -- accepts Enum.InventorySlots, whose equipment values are zero-based
    -- (Main Hand 15, Off Hand 16). Passing the INVSLOT value directly shifts
    -- every lookup one slot to the right: Main Hand becomes Off Hand and Off
    -- Hand becomes Ranged. That left Fury's secondary one-hand capability empty.
    local inventorySlotEnum = inventorySlotID - 1
    if inventorySlotEnum < 0 then return nil end
    return P.SafeCall(C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot, inventorySlotEnum)
end

function P.GetLinkedWeaponSlotContext(outfitSlot)
    local context = {
        requestedSlot = outfitSlot,
        optionOwnerSlot = outfitSlot,
        primarySlot = outfitSlot,
        secondarySlot = nil,
        isLinked = false,
        isSecondary = false,
    }
    if outfitSlot == nil or not C_TransmogOutfitInfo or type(C_TransmogOutfitInfo.GetLinkedSlotInfo) ~= "function" then
        return context
    end

    local linked = P.SafeCall(C_TransmogOutfitInfo.GetLinkedSlotInfo, outfitSlot)
    if type(linked) ~= "table" or type(linked.primarySlotInfo) ~= "table" or type(linked.secondarySlotInfo) ~= "table" then
        return context
    end

    local primarySlot = linked.primarySlotInfo.slot
    local secondarySlot = linked.secondarySlotInfo.slot
    if primarySlot == nil or secondarySlot == nil then
        return context
    end

    context.isLinked = true
    context.primarySlot = primarySlot
    context.secondarySlot = secondarySlot
    context.optionOwnerSlot = primarySlot
    context.isSecondary = outfitSlot == secondarySlot
    context.linkedSlotInfo = linked
    return context
end

P.MAIN_ROUTE_FAMILIES = { "ONE_HAND", "TWO_HAND", "RANGED" }
P.MAIN_ROUTE_FAMILY_SET = { ONE_HAND = true, TWO_HAND = true, RANGED = true }

P.weaponRouteCache = nil
P.weaponRouteCacheKey = nil
P.weaponRouteCacheExpiresAt = 0

function Wardrobe.InvalidateWeaponAppearanceRoutes()
    P.weaponRouteCache = nil
    P.weaponRouteCacheKey = nil
    P.weaponRouteCacheExpiresAt = 0
    if P.InvalidateWeaponCandidateIndex then P.InvalidateWeaponCandidateIndex() end
end

function P.GetWeaponOptionCandidatesForOutfitSlot(outfitSlot)
    if outfitSlot == nil or not C_TransmogOutfitInfo then return {}, nil end

    local candidates = {}
    local seen = {}
    local equippedOption
    if type(C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot) == "function" then
        equippedOption = P.SafeCall(C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot, outfitSlot)
    end

    local function AddOption(optionInfo, sourceKind)
        if not optionInfo or optionInfo.enabled == false or optionInfo.weaponOption == nil then return end
        local key = tostring(optionInfo.weaponOption)
        if seen[key] then return end
        seen[key] = true
        table.insert(candidates, {
            weaponOption = optionInfo.weaponOption,
            name = optionInfo.name,
            enabled = optionInfo.enabled ~= false,
            sourceKind = sourceKind,
            isArtifact = sourceKind == "ARTIFACT",
            isEquipped = equippedOption ~= nil and optionInfo.weaponOption == equippedOption,
        })
    end

    local weaponOptions, artifactOptions
    if type(C_TransmogOutfitInfo.GetWeaponOptionsForSlot) == "function" then
        weaponOptions, artifactOptions = P.SafeCall(C_TransmogOutfitInfo.GetWeaponOptionsForSlot, outfitSlot)
    end

    -- Match Blizzard's preferred-option behavior without throwing away the
    -- provenance of the remaining options. The equipped option is first, then
    -- every other enabled standard and artifact route remains independent.
    for _, optionInfo in ipairs(weaponOptions or {}) do
        if equippedOption ~= nil and optionInfo.weaponOption == equippedOption then AddOption(optionInfo, "STANDARD") end
    end
    for _, optionInfo in ipairs(artifactOptions or {}) do
        if equippedOption ~= nil and optionInfo.weaponOption == equippedOption then AddOption(optionInfo, "ARTIFACT") end
    end
    for _, optionInfo in ipairs(weaponOptions or {}) do AddOption(optionInfo, "STANDARD") end
    for _, optionInfo in ipairs(artifactOptions or {}) do AddOption(optionInfo, "ARTIFACT") end

    -- During early initialization Blizzard may briefly omit the option list but
    -- still expose the equipped option. Preserve that single route. Do not
    -- invent a catch-all None option: unknown native data must fail closed.
    if #candidates == 0 and equippedOption ~= nil then
        table.insert(candidates, {
            weaponOption = equippedOption,
            name = "Equipped weapon option",
            enabled = true,
            sourceKind = "EQUIPPED_FALLBACK",
            isArtifact = false,
            isEquipped = true,
        })
    end

    return candidates, equippedOption
end

function P.QueryWeaponOptionSubtypes(outfitSlot, optionInfo)
    local result = {
        slot = outfitSlot,
        weaponOption = optionInfo and optionInfo.weaponOption or nil,
        optionName = optionInfo and optionInfo.name or nil,
        subtypes = {},
        families = {},
    }
    if outfitSlot == nil or not optionInfo or optionInfo.weaponOption == nil
        or not C_TransmogOutfitInfo
        or type(C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption) ~= "function"
    then
        return result
    end

    for _, subtypeKey in ipairs(Wardrobe.WEAPON_SUBTYPE_ORDER) do
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        local categoryID = P.ResolveWeaponSubtypeCategoryID(definition)
        local collectionInfo = categoryID and P.SafeCall(
            C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption,
            outfitSlot,
            optionInfo.weaponOption,
            categoryID
        ) or nil
        if collectionInfo and collectionInfo.isWeapon == true then
            result.subtypes[subtypeKey] = {
                key = subtypeKey,
                familyKey = definition.familyKey,
                categoryID = categoryID,
                collectionName = collectionInfo.name,
            }
            result.families[definition.familyKey] = (result.families[definition.familyKey] or 0) + 1
        end
    end
    return result
end

function P.CopySubtypePermissionMap(source, familyKey, inherited)
    local result = {}
    for subtypeKey, permission in pairs(source or {}) do
        local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
        if definition and (not familyKey or definition.familyKey == familyKey) then
            result[subtypeKey] = {
                key = subtypeKey,
                familyKey = definition.familyKey,
                categoryID = permission.categoryID,
                collectionName = permission.collectionName,
                inheritedFromPrimary = inherited == true,
            }
        end
    end
    return result
end

function P.CountMapEntries(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

function P.IsMeleeWeaponFamily(familyKey)
    return familyKey == "ONE_HAND" or familyKey == "TWO_HAND"
end

function P.IsPhysicalMeleeWeaponPair(topology)
    return topology
        and topology.hasWeaponOffHand == true
        and P.IsMeleeWeaponFamily(topology.mainHandKind)
        and P.IsMeleeWeaponFamily(topology.offHandKind)
end

function P.GetTopologyMainFamilyGate(topology)
    local allowed = { ONE_HAND = false, TWO_HAND = false, RANGED = false }
    if not topology then return allowed end

    if topology.mainHandKind == "RANGED" then
        allowed.RANGED = true
    elseif P.IsMeleeWeaponFamily(topology.mainHandKind) then
        -- Blizzard may expose both one-hand and two-hand presentation routes for
        -- a physically equipped melee weapon. Fury is the prominent example.
        -- Ranged remains suppressed unless the physical presentation is ranged.
        allowed.ONE_HAND = true
        allowed.TWO_HAND = true
    end
    return allowed
end

function P.MakeWeaponRouteID(ownerSlot, optionInfo, familyKey, suffix)
    return table.concat({
        tostring(ownerSlot or "?"),
        tostring(optionInfo and optionInfo.weaponOption or "?"),
        tostring(familyKey or "UNKNOWN"),
        tostring(suffix or "MAIN"),
    }, ":")
end
