local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ANCHOR_REPEAT_PENALTIES = {
    CHEST = 10,
    LEGS = 6,
    SHOULDER = 8,
    WEAPONS = 10,
    EXACT = 12,
}

local COMPONENT_ORDER = { "CHEST", "LEGS", "SHOULDER", "WEAPONS" }
local COMPONENT_LABELS = {
    CHEST = "Chest",
    LEGS = "Legs",
    SHOULDER = "Shoulders",
    WEAPONS = "Weapon bundle",
}

local CLASS_PRIORITY = {
    INITIAL = 4,
    MEANINGFULLY_NEW = 3,
    PARTIAL_CHANGE = 2,
    EXACT_REPEAT = 1,
}

local function VisualIdentity(source)
    return tostring(source and (source.visualID or source.sourceID or source.itemID) or "")
end

local function StateVisualIdentity(state, slotKey)
    if not state then return "" end
    local visualID = state.selectionVisuals and state.selectionVisuals[slotKey]
    if visualID then return tostring(visualID) end
    local sourceID = state.selections and state.selections[slotKey]
    if not sourceID or not P.GetSourceByID then return tostring(sourceID or "") end
    return VisualIdentity(P.GetSourceByID(slotKey, sourceID))
end

local function SelectedMainSlot(state)
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS or { "ONE_HAND", "TWO_HAND", "RANGED" }) do
        if state and state.selections and state.selections[slotKey] then return slotKey end
    end
    return nil
end

local function ArmorComponent(state, slotKey)
    local locked = state and state.locks and state.locks[slotKey] == true
    local hidden = state and state.hidden and state.hidden[slotKey] == true
    return {
        key = slotKey,
        label = COMPONENT_LABELS[slotKey],
        ignored = locked or hidden,
        locked = locked,
        hidden = hidden,
        currentIdentity = locked or hidden and "" or StateVisualIdentity(state, slotKey),
    }
end

local function WeaponComponent(state)
    local mainSlotKey = SelectedMainSlot(state)
    local mainLocked = mainSlotKey and state and state.locks and state.locks[mainSlotKey] == true or false
    local mainHidden = mainSlotKey and state and state.hidden and state.hidden[mainSlotKey] == true or false
    local offLocked = state and state.locks and state.locks.OFF_HAND == true or false
    local offHidden = state and state.hidden and state.hidden.OFF_HAND == true or false
    local mainIgnored = mainLocked or mainHidden
    local offIgnored = offLocked or offHidden
    return {
        key = "WEAPONS",
        label = COMPONENT_LABELS.WEAPONS,
        mainSlotKey = mainSlotKey,
        mainIgnored = mainIgnored,
        offIgnored = offIgnored,
        ignored = mainIgnored and offIgnored,
        locked = mainLocked and offLocked,
        hidden = mainHidden and offHidden,
        currentMainIdentity = mainIgnored and "" or StateVisualIdentity(state, mainSlotKey),
        currentOffIdentity = offIgnored and "" or StateVisualIdentity(state, "OFF_HAND"),
    }
end

function P.BuildAnchorNoveltyContext(state)
    local context = {
        components = {
            CHEST = ArmorComponent(state, "CHEST"),
            LEGS = ArmorComponent(state, "LEGS"),
            SHOULDER = ArmorComponent(state, "SHOULDER"),
            WEAPONS = WeaponComponent(state),
        },
        currentActiveComponents = 0,
        available = false,
    }
    for _, key in ipairs(COMPONENT_ORDER) do
        local component = context.components[key]
        if not component.ignored then
            local active
            if key == "WEAPONS" then
                active = component.currentMainIdentity ~= "" or component.currentOffIdentity ~= ""
            else
                active = component.currentIdentity ~= ""
            end
            if active then context.currentActiveComponents = context.currentActiveComponents + 1 end
        end
    end
    context.available = context.currentActiveComponents > 0
    return context
end

local function CandidateArmorIdentity(entry, slotKey)
    local candidate = entry and entry.armorNode and entry.armorNode.sourceBySlot
        and entry.armorNode.sourceBySlot[slotKey]
    return VisualIdentity(candidate and candidate.source)
end

local function CandidateWeaponIdentities(entry, component)
    return component.mainIgnored and "" or VisualIdentity(entry and entry.mainSource),
        component.offIgnored and "" or VisualIdentity(entry and entry.offSource)
end

local function CompareIdentity(currentIdentity, candidateIdentity)
    if currentIdentity == "" and candidateIdentity == "" then return nil end
    return currentIdentity == candidateIdentity
end

function P.EvaluateAnchorNovelty(entry, context)
    local result = {
        class = "INITIAL",
        classPriority = CLASS_PRIORITY.INITIAL,
        comparedComponents = {},
        changedComponents = {},
        repeatedComponents = {},
        repeatedKeys = {},
        changedCount = 0,
        repeatedCount = 0,
        comparedCount = 0,
        repeatPenalty = 0,
        baseScore = tonumber(entry and entry.score) or 0,
        adjustedScore = tonumber(entry and entry.score) or 0,
        exactRepeatAccepted = false,
        exactRepeatReason = nil,
    }
    if not context or not context.available then return result end

    for _, key in ipairs(COMPONENT_ORDER) do
        local component = context.components[key]
        if component and not component.ignored then
            local same
            if key == "WEAPONS" then
                local candidateMain, candidateOff = CandidateWeaponIdentities(entry, component)
                local mainSame = CompareIdentity(component.currentMainIdentity, candidateMain)
                local offSame = CompareIdentity(component.currentOffIdentity, candidateOff)
                if mainSame ~= nil or offSame ~= nil then
                    same = (mainSame == nil or mainSame) and (offSame == nil or offSame)
                end
            else
                same = CompareIdentity(component.currentIdentity, CandidateArmorIdentity(entry, key))
            end
            if same ~= nil then
                result.comparedCount = result.comparedCount + 1
                result.comparedComponents[#result.comparedComponents + 1] = component.label
                if same then
                    result.repeatedCount = result.repeatedCount + 1
                    result.repeatedComponents[#result.repeatedComponents + 1] = component.label
                    result.repeatedKeys[key] = true
                    result.repeatPenalty = result.repeatPenalty - (P.ANCHOR_REPEAT_PENALTIES[key] or 0)
                else
                    result.changedCount = result.changedCount + 1
                    result.changedComponents[#result.changedComponents + 1] = component.label
                end
            end
        end
    end

    if result.comparedCount == 0 then return result end
    if result.changedCount >= 2 then
        result.class = "MEANINGFULLY_NEW"
    elseif result.changedCount == 1 then
        result.class = "PARTIAL_CHANGE"
    else
        result.class = "EXACT_REPEAT"
        result.repeatPenalty = result.repeatPenalty - (P.ANCHOR_REPEAT_PENALTIES.EXACT or 0)
    end
    result.classPriority = CLASS_PRIORITY[result.class] or 0
    result.adjustedScore = result.baseScore + result.repeatPenalty
    return result
end

function P.GetAnchorNoveltyClassLabel(classKey)
    local labels = {
        INITIAL = "Initial Generation",
        MEANINGFULLY_NEW = "Meaningfully New",
        PARTIAL_CHANGE = "Partial Change",
        EXACT_REPEAT = "Exact Repeat",
    }
    return labels[classKey] or tostring(classKey or "Unknown")
end

function P.GetAnchorNoveltyClassPriority(classKey)
    return CLASS_PRIORITY[classKey] or 0
end
