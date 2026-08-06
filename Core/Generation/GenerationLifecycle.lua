local QC = QuestChronicle
local Generation = QC.Generation
local P = Generation._Private

P.nextActionID = P.nextActionID or 0
P.activeAction = nil

local function NowMilliseconds(policy)
    local runtime = policy and policy.runtime
    if runtime and type(runtime.NowMilliseconds) == "function" then return runtime.NowMilliseconds() end
    return 0
end

function Generation.BeginAction(policy, actionType, options)
    if P.activeAction then return nil, "Quest Chronicle is already preparing an outfit." end
    P.nextActionID = P.nextActionID + 1
    local action = {
        id = P.nextActionID,
        actionType = actionType,
        modeID = policy.modeID,
        implementation = policy.implementation,
        state = "STARTING",
        startedAtMs = NowMilliseconds(policy),
        options = options,
    }
    P.activeAction = action
    return action
end

function Generation.MarkActionRunning(action)
    if action and P.activeAction == action then action.state = "RUNNING" end
end

function Generation.CompleteAction(action, success, message, performance)
    if not action then return end
    action.state = success == true and "COMPLETED" or "FAILED"
    action.success = success == true
    action.message = message
    action.performance = performance
    action.completedAtMs = action.startedAtMs + (tonumber(performance and performance.elapsedMs) or 0)
    if P.activeAction == action then P.activeAction = nil end
end

function Generation.ClearStartingAction(action)
    if action and P.activeAction == action and action.state == "STARTING" then P.activeAction = nil end
end

function Generation.GetActiveAction()
    return P.activeAction
end

function Generation.StartSharedGenerate(policy, reroll, options)
    local actionType = reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT"
    local action, reason = Generation.BeginAction(policy, actionType, options)
    if not action then return false, reason end
    local ok, message, deferred = policy.StartGenerate(reroll == true, options, action)
    if not ok then
        Generation.ClearStartingAction(action)
        return ok, message, deferred
    end
    Generation.MarkActionRunning(action)
    return ok, message, deferred
end

function Generation.CancelSharedAction(policy, reason)
    local action = P.activeAction
    local ok = policy.Cancel(reason)
    if ok and action and action.state == "STARTING" then Generation.ClearStartingAction(action) end
    return ok
end
