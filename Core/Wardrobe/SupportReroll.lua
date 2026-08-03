local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local supportKeys = {}
for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do supportKeys[slotKey] = true end

local function Eligible(job, source, slotKey)
    if Wardrobe.ValidateSource(source, slotKey) ~= true then return false end
    local style = job.styleEngine
    if not style then return true end
    local prechecked = false
    if style.GetSourcePreEraEligibility then
        local eligible = style.GetSourcePreEraEligibilityCached and style.GetSourcePreEraEligibilityCached(source, job.styleContext)
            or style.GetSourcePreEraEligibility(source, job.styleContext)
        if not eligible then return false end
        prechecked = true
    end
    local evidence = style.GetSourceEraEvidence and style.GetSourceEraEvidence(source) or nil
    return style.GetSourceEligibilityCached and style.GetSourceEligibilityCached(source, job.styleMode, job.styleContext, evidence, prechecked)
        or style.GetSourceEligibility(source, job.styleMode, job.styleContext, evidence, prechecked)
end

local function ActiveSlots(state)
    local result = {}
    for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do
        local hasSources = #(Wardrobe.GetSlotSources(slotKey) or {}) > 0
        if not state.hidden[slotKey] and (hasSources or state.selections[slotKey]) then result[#result + 1] = slotKey end
    end
    return result
end

local function CurrentDecision(job, profile, budget, node, slotKey)
    local sourceID = job.draft.selections[slotKey]
    local source = sourceID and P.GetSourceByID(slotKey, sourceID)
    if not source then return budget end
    local candidate = P.BuildSupportCandidate(source, P.slotByKey[slotKey], job, profile, nil, true)
    if not candidate then return budget end
    local decision = P.ScoreSupportCandidate(candidate, node, job, profile, {}, true)
    decision.allowed, decision.fixed, decision.locked = true, true, job.draft.locks[slotKey] == true
    decision.budgetEvaluation.allowed = true
    node.selected[slotKey] = candidate
    node.decisions[#node.decisions + 1] = decision
    node.budget = P.CommitSupportBudget(node.budget, decision.budgetEvaluation, decision.locked)
    return node.budget
end

local function BuildRoot(job, profile, targetSlot)
    local active = ActiveSlots(job.draft)
    local budget = P.CreateSupportBudget(job.draft, active)
    local node = { selected = {}, decisions = {}, budget = budget, totalScore = 0 }
    for _, slotKey in ipairs(active) do if slotKey ~= targetSlot then CurrentDecision(job, profile, budget, node, slotKey) budget = node.budget end end
    return node, active
end

local function Choose(decisions)
    table.sort(decisions, function(left, right) return left.score > right.score end)
    local shortlist, limit = {}, math.min(6, #decisions)
    for index = 1, limit do shortlist[index] = decisions[index] end
    if #shortlist == 0 then return nil, 0, 0 end
    local minimum = shortlist[#shortlist].score
    local total = 0
    for _, decision in ipairs(shortlist) do decision.weight = math.max(1, (decision.score - minimum + 4) ^ 2) total = total + decision.weight end
    local roll = math.random() * total
    for rank, decision in ipairs(shortlist) do roll = roll - decision.weight if roll <= 0 then return decision, rank, #shortlist end end
    return shortlist[#shortlist], #shortlist, #shortlist
end

local function BuildDiagnostics(profile, node, chosen, active, chosenRank, shortlistSize, poolSize)
    local finalBudget = chosen and P.CommitSupportBudget(node.budget, chosen.budgetEvaluation, false) or node.budget
    local decisions = {}
    for _, decision in ipairs(node.decisions) do decisions[#decisions + 1] = decision end
    if chosen then decisions[#decisions + 1] = chosen end
    local total, scoreTotal, count, accents, outliers, fallbacks = 0, 0, 0, 0, 0, 0
    for _, decision in ipairs(decisions) do
        total, scoreTotal, count = total + (decision.profileFit + decision.neighborCohesion) * 0.5, scoreTotal + (decision.score or 0), count + 1
        if decision.outlierState == "OUTLIER" then outliers = outliers + 1 elseif decision.outlierState == "ACCENT" or decision.outlierState == "LOUD_ACCENT" then accents = accents + 1 end
        if decision.fallback then fallbacks = fallbacks + 1 end
    end
    return {
        profile = profile, startingBudget = finalBudget.starting, lockedCommitment = finalBudget.lockedCommitment,
        generatedSpend = finalBudget.generatedSpend, borrowed = finalBudget.borrowed, overrun = finalBudget.overrun,
        remainingBudget = finalBudget.remaining, configurationScore = scoreTotal,
        wholeOutfitCohesion = count > 0 and total / count or profile.meanAnchorCohesion,
        controlledAccents = accents, outliers = outliers, fallbackSlots = fallbacks,
        chosenRank = chosenRank or 0, shortlistSize = shortlistSize or 0,
        poolSizes = { [chosen and chosen.slotKey or ""] = poolSize or 0 }, expansions = { [chosen and chosen.slotKey or ""] = poolSize or 0 }, retained = { [chosen and chosen.slotKey or ""] = shortlistSize or 0 }, deduplicated = 0, budgetRejections = 0, emptySlots = 0,
        decisions = decisions, activeSlots = active,
    }
end

function P.SelectContextualSupportSlot(state, slotKey, styleMode, hardExcludeCurrent)
    local style = QC.ZoneStyle
    local context = style and P.CreateStyleGenerationContext(state, style, style.GetCurrentContext(), slotKey, false) or nil
    local job = { draft = state, liveState = state, styleEngine = style, styleMode = styleMode, styleContext = context, reroll = hardExcludeCurrent == true }
    local profile = P.BuildContextualSupportProfile(state)
    local root, active = BuildRoot(job, profile, slotKey)
    local currentSourceID = state.selections[slotKey]
    local currentSource = currentSourceID and P.GetSourceByID(slotKey, currentSourceID)
    local currentIdentity = currentSource and P.SupportVisualIdentity(currentSource)
    local decisions, fallback, overBudgetAlternative = {}, nil, nil
    for _, source in ipairs(Wardrobe.GetSlotSources(slotKey)) do
        if Eligible(job, source, slotKey) then
            local identity = P.SupportVisualIdentity(source)
            local candidate = P.BuildSupportCandidate(source, P.slotByKey[slotKey], job, profile, hardExcludeCurrent and nil or currentIdentity)
            if candidate then
                local decision = P.ScoreSupportCandidate(candidate, root, job, profile, {}, false)
                if hardExcludeCurrent and identity == currentIdentity then fallback = decision
                elseif decision.allowed then decisions[#decisions + 1] = decision
                elseif not overBudgetAlternative or decision.mismatchSpent < overBudgetAlternative.mismatchSpent
                    or (decision.mismatchSpent == overBudgetAlternative.mismatchSpent and decision.score > overBudgetAlternative.score) then overBudgetAlternative = decision end
            end
        end
    end
    local chosen, chosenRank, shortlistSize = Choose(decisions)
    if not chosen and overBudgetAlternative then
        chosen, chosenRank, shortlistSize = overBudgetAlternative, 1, 1
        chosen.fallback, chosen.allowed, chosen.budgetState = true, true, "OVER"
        chosen.budgetEvaluation.allowed = true
    end
    if not chosen then chosen, chosenRank, shortlistSize = fallback, fallback and 1 or 0, fallback and 1 or 0 end
    if not chosen then return false, "No compatible contextual appearance is cached for this slot." end
    if chosen == fallback then chosen.fallback, chosen.allowed = true, true chosen.budgetEvaluation.allowed = true end
    P.SetSelectedSource(state, slotKey, chosen.source)
    P.lastSupportDiagnostics = BuildDiagnostics(profile, root, chosen, active, chosenRank, shortlistSize, #decisions + (fallback and 1 or 0))
    return true
end

function P.RebuildContextualSupport(state, styleMode)
    for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do
        if not state.hidden[slotKey] and not state.locks[slotKey] then P.SelectContextualSupportSlot(state, slotKey, styleMode, false) end
    end
    return true
end

local originalRerollSlot = Wardrobe.RerollSlot
Wardrobe.RerollSlot = function(slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition then return false, "Unknown equipment slot." end
    if Wardrobe.IsSlotLocked(slotKey) then return false, "Unlock this slot before rerolling it." end
    local state = P.EnsurePreviewState()
    local style = QC.ZoneStyle
    local styleMode = style and style.NormalizeMode(state.styleMode) or state.styleMode
    if supportKeys[slotKey] then
        local ok, message = P.SelectContextualSupportSlot(state, slotKey, styleMode, true)
        if not ok then return false, message end
        state.selectedConceptID = nil
        local name = P.RefreshGeneratedOutfitName(state, style, styleMode, style and P.CreateStyleGenerationContext(state, style, style.GetCurrentContext(), nil, false) or nil)
        if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
        return true, string.format("%s rerolled contextually%s.", definition.label, name and ("; the current look is now " .. name) or "")
    end
    local ok, message = originalRerollSlot(slotKey)
    if ok then
        P.RebuildContextualSupport(state, styleMode)
        state.selectedConceptID = nil
        local context = style and P.CreateStyleGenerationContext(state, style, style.GetCurrentContext(), nil, false) or nil
        local name = P.RefreshGeneratedOutfitName(state, style, styleMode, context)
        if QC.Notify then QC.Notify("WARDROBE_WORKBENCH_CHANGED", slotKey) end
        if name then message = message .. " Contextual support rebuilt around the new anchor; the current look is now " .. name .. "." end
    end
    return ok, message
end
