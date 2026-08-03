local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.supportRerollToken = P.supportRerollToken or 0
P.supportRerollJob = nil

local supportKeys = {}
for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do supportKeys[slotKey] = true end

local function CopyRerollPrimitiveMap(source)
    if P.CopyPrimitiveMap then return P.CopyPrimitiveMap(source) end
    local result = {}
    for key, value in pairs(source or {}) do
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then result[key] = value end
    end
    return result
end

function P.IsSupportSlotKey(slotKey)
    return supportKeys[slotKey] == true
end

function P.CopySupportRerollState(state)
    local draft = {}
    for key, value in pairs(state or {}) do if type(value) ~= "table" then draft[key] = value end end
    draft.selections = CopyRerollPrimitiveMap(state and state.selections)
    draft.selectionVisuals = CopyRerollPrimitiveMap(state and state.selectionVisuals)
    draft.locks = CopyRerollPrimitiveMap(state and state.locks)
    draft.hidden = CopyRerollPrimitiveMap(state and state.hidden)
    draft.weaponFamilies = CopyRerollPrimitiveMap(state and state.weaponFamilies)
    draft.weaponSubtypes = CopyRerollPrimitiveMap(state and state.weaponSubtypes)
    draft.lastWeaponRoute = state and state.lastWeaponRoute
    draft.lastAnchorSkeletonSignature = state and state.lastAnchorSkeletonSignature
    draft.activeAnchorMask = P.CopySupportProfileValue and P.CopySupportProfileValue(state and state.activeAnchorMask) or nil
    draft.contextualSupportProfile = P.CopySupportProfileValue and P.CopySupportProfileValue(state and state.contextualSupportProfile) or nil
    return draft
end

local function AppendMapSignature(parts, label, values)
    local keys = {}
    for key in pairs(values or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    parts[#parts + 1] = label
    for _, key in ipairs(keys) do
        local value = values[key]
        if value == nil then value = values[tonumber(key)] end
        parts[#parts + 1] = key .. "=" .. tostring(value)
    end
end

function P.SupportRerollStateSignature(state)
    local parts = {
        "link=" .. tostring(state and state.linkWeaponHands ~= false),
        "mode=" .. tostring(state and state.styleMode or ""),
    }
    AppendMapSignature(parts, "selections", state and state.selections)
    AppendMapSignature(parts, "locks", state and state.locks)
    AppendMapSignature(parts, "hidden", state and state.hidden)
    AppendMapSignature(parts, "families", state and state.weaponFamilies)
    AppendMapSignature(parts, "subtypes", state and state.weaponSubtypes)
    return table.concat(parts, "|")
end

function P.GetActiveSupportSlots(state)
    local active = {}
    for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do
        local hasSources = #(Wardrobe.GetSlotSources(slotKey) or {}) > 0
        local selected = state and state.selections and state.selections[slotKey]
        if P.slotByKey[slotKey] and not (state and state.hidden and state.hidden[slotKey]) and (hasSources or selected) then
            active[#active + 1] = slotKey
        end
    end
    return active
end

function P.GetSupportDecisionBySlot(supportSnapshot, slotKey)
    for _, decision in ipairs(supportSnapshot and supportSnapshot.decisions or {}) do
        if decision.slotKey == slotKey then return decision end
    end
end

function P.GetSupportRerollParentReports(identity)
    local diagnostics = QC.Diagnostics
    if not diagnostics or not diagnostics.GetReportByID then return nil, nil end
    local pending = diagnostics._Private and diagnostics._Private.latestEligiblePendingReport
    local lookup = diagnostics.PeekReportByID or diagnostics.GetReportByID
    local parent = identity and identity.parentCompletedReportID and lookup and lookup(identity.parentCompletedReportID) or nil
    if not parent and pending and identity and pending.id == identity.parentCompletedReportID then parent = pending end
    local anchorID = identity and identity.anchorSourceReportID or (parent and parent.anchorSourceReportID)
    local anchor = anchorID and lookup and lookup(anchorID) or nil
    if not anchor and pending and pending.id == anchorID then anchor = pending end
    if not anchor and parent and parent.skeleton then anchor = parent end
    return parent, anchor
end

function Wardrobe.IsSupportRerolling()
    return P.supportRerollJob ~= nil
end
