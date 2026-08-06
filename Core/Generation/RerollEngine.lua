local QC = QuestChronicle
local Generation = QC.Generation
Generation.RerollEngine = Generation.RerollEngine or {}
local Engine = Generation.RerollEngine

function Engine.RerollSlot(policy, slotKey, options)
    local sharedSupport = policy.implementation == Generation.IMPLEMENTATION_SHARED_FRAMEWORK
        and policy.runtime and policy.runtime.IsSupportSlot and policy.runtime.IsSupportSlot(slotKey)
    if not sharedSupport then return policy.RerollSlot(slotKey, options) end
    local action, reason = Generation.BeginAction(policy, "REROLL_SLOT", options)
    if not action then return false, reason end
    action.slotKey = slotKey
    local ok, message, deferred = policy.RerollSlot(slotKey, options, action)
    if not ok then
        Generation.ClearStartingAction(action)
        return ok, message, deferred
    end
    Generation.MarkActionRunning(action)
    return ok, message, deferred
end
