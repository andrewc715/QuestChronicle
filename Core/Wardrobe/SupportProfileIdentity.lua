local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.SUPPORT_ANCHOR_ORDER = { "CHEST", "LEGS", "SHOULDER", "WEAPON" }

local MAIN_WEAPON_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }

local function DeepCopy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 10
    if depth <= 0 then return nil end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        local keyType, childType = type(key), type(child)
        if keyType == "string" or keyType == "number" then
            if childType ~= "function" and childType ~= "userdata" and childType ~= "thread" then
                copy[key] = DeepCopy(child, depth - 1, seen)
            end
        end
    end
    return copy
end

local function ComponentsBySlot(skeleton)
    local result = {}
    for _, component in ipairs(skeleton and skeleton.components or {}) do
        if component.slotKey then result[component.slotKey] = component end
    end
    return result
end

local function FirstMainComponent(components)
    for _, slotKey in ipairs(MAIN_WEAPON_KEYS) do
        if components[slotKey] then return components[slotKey], slotKey end
    end
end

local function FirstMainStateSlot(state)
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS or MAIN_WEAPON_KEYS) do
        if state and state.selections and state.selections[slotKey] then return slotKey end
    end
end

local function ResolveState(hidden, available, locked)
    if hidden then return "HIDDEN" end
    if not available then return "UNAVAILABLE" end
    if locked then return "LOCKED" end
    return "ACTIVE"
end

local function BuildArmorMask(state, components, slotKey)
    local component = components[slotKey]
    local sourceID = component and component.sourceID or (state and state.selections and state.selections[slotKey])
    local visualID = component and component.visualID or (state and state.selectionVisuals and state.selectionVisuals[slotKey])
    local hidden = component and component.hidden == true or state and state.hidden and state.hidden[slotKey] == true
    local locked = component and component.locked == true or state and state.locks and state.locks[slotKey] == true
    local available = sourceID ~= nil or visualID ~= nil
    return {
        logicalKey = slotKey,
        slotKey = slotKey,
        state = ResolveState(hidden, available, locked),
        sourceID = tonumber(sourceID),
        visualID = tonumber(visualID),
    }
end

local function BuildWeaponMask(state, components)
    local mainComponent, mainSlot = FirstMainComponent(components)
    mainSlot = mainSlot or FirstMainStateSlot(state)
    local offComponent = components.OFF_HAND
    local mainSourceID = mainComponent and mainComponent.sourceID or (mainSlot and state and state.selections and state.selections[mainSlot])
    local mainVisualID = mainComponent and mainComponent.visualID or (mainSlot and state and state.selectionVisuals and state.selectionVisuals[mainSlot])
    local offSourceID = offComponent and offComponent.sourceID or (state and state.selections and state.selections.OFF_HAND)
    local offVisualID = offComponent and offComponent.visualID or (state and state.selectionVisuals and state.selectionVisuals.OFF_HAND)
    local hidden = mainComponent and mainComponent.hidden == true or offComponent and offComponent.hidden == true
    local locked = mainComponent and mainComponent.locked == true or offComponent and offComponent.locked == true
        or mainSlot and state and state.locks and state.locks[mainSlot] == true
        or state and state.locks and state.locks.OFF_HAND == true
    local available = mainSourceID ~= nil or mainVisualID ~= nil or offSourceID ~= nil or offVisualID ~= nil
    return {
        logicalKey = "WEAPON",
        state = ResolveState(hidden, available, locked),
        mainSlotKey = mainSlot,
        mainSourceID = tonumber(mainSourceID),
        mainVisualID = tonumber(mainVisualID),
        offSourceID = tonumber(offSourceID),
        offVisualID = tonumber(offVisualID),
    }
end

function P.BuildActiveAnchorMask(state, skeleton)
    if not skeleton and state and type(state.activeAnchorMask) == "table" and tonumber(state.activeAnchorMask.version) == 1 then
        return DeepCopy(state.activeAnchorMask, 6)
    end
    local components = ComponentsBySlot(skeleton)
    return {
        version = 1,
        CHEST = BuildArmorMask(state, components, "CHEST"),
        LEGS = BuildArmorMask(state, components, "LEGS"),
        SHOULDER = BuildArmorMask(state, components, "SHOULDER"),
        WEAPON = BuildWeaponMask(state, components),
    }
end

local function LogicalAnchorKey(slotKey)
    if slotKey == "CHEST" or slotKey == "LEGS" or slotKey == "SHOULDER" then return slotKey end
    if slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED" or slotKey == "OFF_HAND" then return "WEAPON" end
end

function P.RefreshCanonicalAnchorMask(state, slotKey)
    if not state then return nil end
    local logicalKey = LogicalAnchorKey(slotKey)
    if not logicalKey then return state.activeAnchorMask end
    local previous = state.activeAnchorMask
    state.activeAnchorMask = nil
    local rebuilt = P.BuildActiveAnchorMask(state)
    if logicalKey ~= "WEAPON" and previous and previous.WEAPON and not rebuilt.WEAPON then rebuilt.WEAPON = DeepCopy(previous.WEAPON, 4) end
    state.activeAnchorMask = rebuilt
    state.contextualSupportProfile = nil
    return rebuilt
end

function P.IsActiveAnchorState(value)
    local state = type(value) == "table" and value.state or value
    return state == "ACTIVE" or state == "LOCKED"
end

function P.IsAnchorActive(mask, logicalKey)
    return P.IsActiveAnchorState(mask and mask[logicalKey])
end

function P.ActiveAnchorMaskSignature(mask)
    local parts = { "v=" .. tostring(mask and mask.version or 0) }
    for _, key in ipairs(P.SUPPORT_ANCHOR_ORDER) do
        local entry = mask and mask[key] or {}
        parts[#parts + 1] = table.concat({
            key, tostring(entry.state or "UNAVAILABLE"), tostring(entry.slotKey or entry.mainSlotKey or ""),
            tostring(entry.sourceID or entry.mainSourceID or ""), tostring(entry.visualID or entry.mainVisualID or ""),
            tostring(entry.offSourceID or ""), tostring(entry.offVisualID or ""),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function HashText(text)
    local hash = 5381
    for index = 1, #text do hash = (hash * 33 + string.byte(text, index)) % 2147483647 end
    return tostring(hash)
end

function P.CreateContextualSupportProfileID(sourceReportID, mask)
    return "QCPROFILE-" .. HashText(tostring(sourceReportID or "LEGACY") .. "|" .. P.ActiveAnchorMaskSignature(mask))
end

local function SourceByIdentity(slotKey, sourceID, visualID)
    local source = sourceID and P.GetSourceByID(slotKey, sourceID) or nil
    if not source and visualID and P.FindSourceByVisualID then source = P.FindSourceByVisualID(slotKey, visualID) end
    return source
end

function P.GetActiveAnchorSource(mask, state, logicalKey)
    local entry = mask and mask[logicalKey]
    if not P.IsActiveAnchorState(entry) then return nil end
    if logicalKey == "WEAPON" then
        local mainSlot = entry.mainSlotKey or FirstMainStateSlot(state)
        local main = mainSlot and SourceByIdentity(mainSlot, entry.mainSourceID, entry.mainVisualID) or nil
        local off = SourceByIdentity("OFF_HAND", entry.offSourceID, entry.offVisualID)
        return main, mainSlot, off
    end
    local slotKey = entry.slotKey or logicalKey
    return SourceByIdentity(slotKey, entry.sourceID, entry.visualID), slotKey
end

function P.CopySupportProfileValue(value)
    return DeepCopy(value, 12)
end

function P.ExportContextualSupportProfile(profile)
    if not profile then return nil end
    local snapshot = {
        version = 2,
        profileID = profile.profileID,
        profileSourceReportID = profile.profileSourceReportID,
        activeAnchorMask = DeepCopy(profile.activeAnchorMask, 6),
        activeAnchorMaskSignature = profile.activeAnchorMaskSignature,
        activeAnchorCount = profile.activeAnchorCount,
        meanAnchorCohesion = profile.meanAnchorCohesion,
        strongestRelationship = DeepCopy(profile.strongestRelationship, 4),
        weakestRelationship = DeepCopy(profile.weakestRelationship, 4),
        cohesionComponents = DeepCopy(profile.cohesionComponents, 5),
        tolerance = DeepCopy(profile.tolerance, 5),
        confidence = DeepCopy(profile.confidence, 5),
        descriptor = DeepCopy(profile.descriptor, 8),
        centers = {
            palette = profile.descriptor and profile.descriptor.dominantPalette,
            material = profile.descriptor and profile.descriptor.dominantMaterial,
            finish = profile.descriptor and profile.descriptor.dominantFinish,
            motif = profile.descriptor and profile.descriptor.dominantMotif,
            visualWeight = profile.descriptor and profile.descriptor.visualWeight,
            provenance = profile.descriptor and profile.descriptor.expansionID,
        },
        mainWeaponSlot = profile.mainWeaponSlot,
        entries = {}, activeAnchors = {},
    }
    for _, entry in ipairs(profile.entries or {}) do
        snapshot.entries[#snapshot.entries + 1] = {
            slotKey = entry.slotKey, label = entry.label, weight = entry.weight,
            sourceID = entry.source and tonumber(entry.source.sourceID) or entry.sourceID,
            visualID = entry.source and tonumber(entry.source.visualID) or entry.visualID,
        }
        snapshot.activeAnchors[#snapshot.activeAnchors + 1] = { slotKey = entry.slotKey, label = entry.label, weight = entry.weight }
    end
    return snapshot
end

local function RestoreProfile(snapshot, state)
    local profile = DeepCopy(snapshot, 12)
    profile.entries = profile.entries or {}
    for _, entry in ipairs(profile.entries) do
        entry.source = SourceByIdentity(entry.slotKey, entry.sourceID, entry.visualID)
    end
    return profile
end

local function SnapshotIsReusable(snapshot, canonicalMask)
    if type(snapshot) ~= "table" or (tonumber(snapshot.version) or 0) < 2 then return false, "LEGACY_PROFILE" end
    if type(snapshot.descriptor) ~= "table" or type(snapshot.descriptor.palette) ~= "table" then return false, "MISSING_DESCRIPTOR" end
    if type(snapshot.activeAnchorMask) ~= "table" then return false, "MISSING_ANCHOR_MASK" end
    local expected = P.ActiveAnchorMaskSignature(canonicalMask)
    local actual = snapshot.activeAnchorMaskSignature or P.ActiveAnchorMaskSignature(snapshot.activeAnchorMask)
    if actual ~= expected then return false, "PROFILE_MASK_MISMATCH" end
    return true
end

function P.ResolveContextualSupportProfile(snapshot, state, skeleton, anchorSourceReportID)
    local canonicalMask = P.BuildActiveAnchorMask(state, skeleton)
    local reusable, reason = SnapshotIsReusable(snapshot, canonicalMask)
    if reusable then
        local profile = RestoreProfile(snapshot, state)
        profile.activeAnchorMask = canonicalMask
        profile.activeAnchorMaskSignature = P.ActiveAnchorMaskSignature(canonicalMask)
        return profile, { reused = true, repaired = false, migrated = false, activeAnchorMask = canonicalMask }
    end
    local profile = P.BuildContextualSupportProfile(state, {
        activeAnchorMask = canonicalMask,
        profileSourceReportID = anchorSourceReportID,
        profileID = P.CreateContextualSupportProfileID(anchorSourceReportID, canonicalMask),
    })
    return profile, {
        reused = false,
        repaired = snapshot ~= nil,
        migrated = snapshot ~= nil and reason == "LEGACY_PROFILE",
        repairReason = reason,
        activeAnchorMask = canonicalMask,
    }
end
