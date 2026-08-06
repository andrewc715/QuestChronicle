local QC = QuestChronicle
local Generation = QC.Generation

Generation.API_CONTRACT_VERSION = 1

local function ResolvePolicy(options)
    options = type(options) == "table" and options or {}
    local modeID = options.modeID
    if modeID == nil and QC.ZoneStyle and QC.ZoneStyle.GetMode then modeID = QC.ZoneStyle.GetMode() end
    return Generation.GetGenerationMode(modeID)
end

local function RequireCapability(policy, capability)
    if policy and policy.capabilities and policy.capabilities[capability] == true then return true end
    return false, string.format(
        "%s does not support %s through the current generation implementation.",
        policy and policy.displayLabel or "This mode", tostring(capability)
    )
end

local function StartGenerate(policy, reroll, options)
    if policy.implementation == Generation.IMPLEMENTATION_SHARED_FRAMEWORK then
        return Generation.StartSharedGenerate(policy, reroll, options)
    end
    return policy.StartGenerate(reroll, options)
end

function Generation.GenerateCurrentMode(options)
    local policy, reason = ResolvePolicy(options)
    if not policy then return false, reason end
    local supported, unsupportedReason = RequireCapability(policy, "generate")
    if not supported then return false, unsupportedReason end
    return StartGenerate(policy, false, options)
end

function Generation.RerollUnlockedCurrentMode(options)
    local policy, reason = ResolvePolicy(options)
    if not policy then return false, reason end
    local supported, unsupportedReason = RequireCapability(policy, "rerollUnlocked")
    if not supported then return false, unsupportedReason end
    return StartGenerate(policy, true, options)
end

function Generation.RerollCurrentModeSlot(slotKey, options)
    local policy, reason = ResolvePolicy(options)
    if not policy then return false, reason end
    local supported, unsupportedReason = RequireCapability(policy, "rerollSlot")
    if not supported then return false, unsupportedReason end
    return Generation.RerollEngine.RerollSlot(policy, slotKey, options)
end

function Generation.RerollSupportSlotCurrentMode(slotKey, options)
    local policy, reason = ResolvePolicy(options)
    if not policy then return false, reason end
    local supported, unsupportedReason = RequireCapability(policy, "rerollSupportSlot")
    if not supported then return false, unsupportedReason end
    return Generation.RerollEngine.RerollSlot(policy, slotKey, options)
end

function Generation.CancelCurrentGeneration(reason, options)
    local policy, lookupReason = ResolvePolicy(options)
    if not policy then return false, lookupReason end
    local supported, unsupportedReason = RequireCapability(policy, "cancel")
    if not supported then return false, unsupportedReason end
    if policy.implementation == Generation.IMPLEMENTATION_SHARED_FRAMEWORK then
        return Generation.CancelSharedAction(policy, reason)
    end
    return policy.Cancel(reason)
end

function Generation.IsGenerating(options)
    local policy = ResolvePolicy(options)
    return policy ~= nil and type(policy.IsGenerating) == "function" and policy.IsGenerating() == true
end

function Generation.GetCurrentGenerationState(options)
    local policy, reason = ResolvePolicy(options)
    if not policy then return nil, reason end
    local action = Generation.GetActiveAction and Generation.GetActiveAction() or nil
    if action and action.modeID ~= policy.modeID then action = nil end
    return {
        active = type(policy.IsGenerating) == "function" and policy.IsGenerating() == true,
        actionID = action and action.id or nil,
        actionType = action and action.actionType or nil,
        actionState = action and action.state or nil,
        modeID = policy.modeID,
        displayLabel = policy.displayLabel,
        implementation = policy.implementation,
        implementationGeneration = policy.implementationGeneration,
        performance = type(policy.GetLastPerformance) == "function" and policy.GetLastPerformance() or nil,
    }
end
