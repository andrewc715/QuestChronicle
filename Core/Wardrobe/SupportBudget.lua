local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.SUPPORT_SLOT_ALLOWANCES = { HEAD = 2.00, BACK = 2.00, WAIST = 1.50, HANDS = 1.25, FEET = 1.25, WRIST = 0.50, SHIRT = 0.75, TABARD = 1.50 }
P.SUPPORT_BORROW_FRACTION = 0.25
P.SUPPORT_MINIMUM_RESERVE_FRACTION = 0.15

local function Round(value)
    return math.floor((tonumber(value) or 0) * 1000 + 0.5) / 1000
end

function P.GetSupportSlotAllowance(slotKey)
    return tonumber(P.SUPPORT_SLOT_ALLOWANCES[slotKey]) or 0
end

function P.CreateSupportBudget(state, activeSlots)
    local starting = 0
    for _, slotKey in ipairs(activeSlots or {}) do starting = starting + P.GetSupportSlotAllowance(slotKey) end
    return {
        starting = Round(starting), lockedCommitment = 0, generatedSpend = 0,
        borrowed = 0, overrun = 0, remaining = Round(starting),
    }
end

function P.CopySupportBudget(ledger)
    return {
        starting = ledger.starting or 0, lockedCommitment = ledger.lockedCommitment or 0,
        generatedSpend = ledger.generatedSpend or 0, borrowed = ledger.borrowed or 0,
        overrun = ledger.overrun or 0, remaining = ledger.remaining or 0,
    }
end

function P.GetSupportReserve(remainingSlots)
    local reserve = 0
    for _, slotKey in ipairs(remainingSlots or {}) do reserve = reserve + P.GetSupportSlotAllowance(slotKey) * P.SUPPORT_MINIMUM_RESERVE_FRACTION end
    return Round(reserve)
end

function P.EvaluateSupportBudget(ledger, slotKey, cost, remainingSlots, locked)
    cost = math.max(0, tonumber(cost) or 0)
    local allowance = P.GetSupportSlotAllowance(slotKey)
    local reserve = P.GetSupportReserve(remainingSlots)
    local slotMaximum = allowance * (1 + P.SUPPORT_BORROW_FRACTION)
    local after = (tonumber(ledger.remaining) or 0) - cost
    local budgetState = cost <= allowance and "WITHIN" or (cost <= slotMaximum and "BORROWED" or "OVER")
    local allowed = locked == true or (budgetState ~= "OVER" and after >= reserve)
    local pressure = after < reserve and (reserve - after) * 8 or 0
    return {
        allowed = allowed, state = budgetState, cost = Round(cost), allowance = allowance,
        reserve = reserve, after = Round(after), pressurePenalty = Round(pressure),
        borrowed = budgetState == "BORROWED" and Round(math.max(0, cost - allowance)) or 0,
        overrun = budgetState == "OVER" and Round(math.max(0, cost - allowance)) or 0,
    }
end

function P.CommitSupportBudget(ledger, evaluation, locked)
    local result = P.CopySupportBudget(ledger)
    local cost = tonumber(evaluation and evaluation.cost) or 0
    result.remaining = Round((result.remaining or 0) - cost)
    if locked then result.lockedCommitment = Round((result.lockedCommitment or 0) + cost)
    else result.generatedSpend = Round((result.generatedSpend or 0) + cost) end
    result.borrowed = Round((result.borrowed or 0) + (tonumber(evaluation and evaluation.borrowed) or 0))
    result.overrun = Round((result.overrun or 0) + (tonumber(evaluation and evaluation.overrun) or 0))
    return result
end
