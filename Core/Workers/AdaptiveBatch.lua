local QC = QuestChronicle
QC._Core = QC._Core or {}
QC._Core.Workers = QC._Core.Workers or {}
local W = QC._Core.Workers

local OPTIONS = { 1, 2, 4, 8, 16, 32 }

function W.NoteAdaptiveCost(state, elapsedMs)
    state = state or {}
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0)
    local previous = tonumber(state.averageMs)
    state.averageMs = previous and ((previous * 0.75) + (elapsedMs * 0.25)) or elapsedMs
    state.maximumRecentMs = math.max(tonumber(state.maximumRecentMs) or 0, elapsedMs)
    state.samples = (tonumber(state.samples) or 0) + 1
    if elapsedMs >= 2 then
        state.level, state.fastStreak, state.forceSingle = 1, 0, true
    elseif elapsedMs >= 1 then
        state.level, state.fastStreak = math.max(1, (state.level or 2) - 1), 0
    elseif elapsedMs <= 0.25 then
        state.fastStreak = (state.fastStreak or 0) + 1
        if state.fastStreak >= 2 then state.level = math.min(#OPTIONS, (state.level or 1) + 1) state.fastStreak = 0 end
    else
        state.fastStreak = 0
    end
    return state
end

function W.GetAdaptiveBatchSize(state, remainingMs, remainingItems)
    state = state or {}
    remainingMs = math.max(0, tonumber(remainingMs) or 0)
    remainingItems = math.max(1, math.floor(tonumber(remainingItems) or 1))
    if state.forceSingle then state.forceSingle = nil return 1 end
    local average = math.max(0.01, tonumber(state.averageMs) or 0.05)
    local target = math.max(1, math.floor((remainingMs * 0.72) / average))
    local level = math.max(1, math.min(#OPTIONS, tonumber(state.level) or 1))
    local ceiling = math.min(OPTIONS[level], target, remainingItems)
    local chosen = 1
    for _, option in ipairs(OPTIONS) do
        if option <= ceiling then chosen = option end
    end
    return math.max(1, chosen)
end
