local QC = QuestChronicle
QC._Core = QC._Core or {}
QC._Core.Workers = QC._Core.Workers or {}
local W = QC._Core.Workers

local OPTIONS = { 1, 2, 4, 8, 16 }

function W.NoteAdaptiveCost(state, elapsedMs)
    state = state or {}
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0)
    local previous = tonumber(state.averageMs)
    state.averageMs = previous and ((previous * 0.75) + (elapsedMs * 0.25)) or elapsedMs
    state.maximumRecentMs = math.max(tonumber(state.maximumRecentMs) or 0, elapsedMs)
    state.samples = (tonumber(state.samples) or 0) + 1
    if elapsedMs >= 2 then state.forceSingle = true end
    return state
end

function W.GetAdaptiveBatchSize(state, remainingMs, remainingItems)
    state = state or {}
    remainingMs = math.max(0, tonumber(remainingMs) or 0)
    remainingItems = math.max(1, math.floor(tonumber(remainingItems) or 1))
    if state.forceSingle then state.forceSingle = nil return 1 end
    local average = math.max(0.01, tonumber(state.averageMs) or 0.05)
    local target = math.max(1, math.floor((remainingMs * 0.65) / average))
    local chosen = 1
    for _, option in ipairs(OPTIONS) do
        if option <= target and option <= remainingItems then chosen = option end
    end
    return chosen
end
