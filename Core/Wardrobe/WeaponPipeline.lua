local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.activeWeaponCoroutine = nil

function P.MaybeYieldWeaponGeneration(phaseKey)
    if not coroutine or type(coroutine.running) ~= "function" or type(coroutine.yield) ~= "function" then return end
    local running = coroutine.running()
    if running and running == P.activeWeaponCoroutine then
        coroutine.yield(phaseKey or "weaponRouting")
    end
end

function P.CreateWeaponGenerationWork(state, reroll, styleMode, styleContext)
    if not coroutine or type(coroutine.create) ~= "function" then return nil end
    local work = { done = false, yields = 0, lastYieldPhase = nil }
    work.thread = coroutine.create(function()
        return P.GenerateWeapons(state, reroll, styleMode, styleContext)
    end)
    return work
end

function P.StepWeaponGenerationWork(work)
    if not work then return true, false, "Weapon generation work was not initialized." end
    if work.done then return true, work.ok, work.value, work.notice end
    if not work.thread then
        local ok, value, notice = P.GenerateWeapons(work.state, work.reroll, work.styleMode, work.styleContext)
        work.done, work.ok, work.value, work.notice = true, ok, value, notice
        return true, ok, value, notice
    end

    P.activeWeaponCoroutine = work.thread
    local resumed, first, second, third = coroutine.resume(work.thread)
    P.activeWeaponCoroutine = nil
    if not resumed then
        work.done, work.ok, work.value = true, false, tostring(first)
        return true, false, work.value
    end
    if coroutine.status(work.thread) == "dead" then
        work.done, work.ok, work.value, work.notice = true, first, second, third
        return true, first, second, third
    end
    work.yields = work.yields + 1
    work.lastYieldPhase = first
    return false, nil, nil, nil, first
end
