local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function CopyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function InsertSortedLimited(values, entry, limit, field)
    field = field or "score"
    local inserted = false
    for index, existing in ipairs(values) do
        if (tonumber(entry[field]) or -math.huge) > (tonumber(existing[field]) or -math.huge) then
            table.insert(values, index, entry)
            inserted = true
            break
        end
    end
    if not inserted then values[#values + 1] = entry end
    while #values > limit do table.remove(values) end
end

function P.AddAnchorPoolCandidate(work, candidate)
    if not work or not candidate then return end
    work.seenVisuals = work.seenVisuals or {}
    local visualKey = tostring(candidate.source and (candidate.source.visualID or candidate.source.sourceID) or "")
    if work.seenVisuals[visualKey] then return end
    work.seenVisuals[visualKey] = true
    if candidate.source and candidate.source.sourceID == work.excludeSourceID then
        if not work.fallback or candidate.poolPriority > work.fallback.poolPriority then work.fallback = candidate end
        return
    end
    InsertSortedLimited(work.pool, candidate, work.poolLimit or 32, "poolPriority")
end

function P.FinalizeAnchorPool(work)
    if not work then return {} end
    if #work.pool == 0 and work.fallback then work.pool[1] = work.fallback end
    table.sort(work.pool, function(left, right)
        if left.baseScore == right.baseScore then
            return tostring(left.source and left.source.sourceID) < tostring(right.source and right.source.sourceID)
        end
        return (left.baseScore or 0) > (right.baseScore or 0)
    end)
    if #work.pool > 1 then
        local balanced, overflow, counts = {}, {}, {}
        local familyCap = math.max(2, math.ceil((work.poolLimit or 32) * 0.25))
        for _, candidate in ipairs(work.pool) do
            local key = candidate.diversityKey or "UNKNOWN"
            if (counts[key] or 0) < familyCap then
                balanced[#balanced + 1] = candidate
                counts[key] = (counts[key] or 0) + 1
            else
                overflow[#overflow + 1] = candidate
            end
        end
        for _, candidate in ipairs(overflow) do
            if #balanced >= (work.poolLimit or 32) then break end
            balanced[#balanced + 1] = candidate
        end
        work.pool = balanced
    end
    return work.pool
end

local function NewRootNode()
    return {
        sourceBySlot = {},
        sources = {},
        baseScore = 0,
        relationshipBonus = 0,
        visualRelationshipBonus = 0,
        zonePairSupportBonus = 0,
        pairScoreTotal = 0,
        pairCount = 0,
        hardClashes = 0,
        score = 0,
        activeComponents = 0,
    }
end


local function ScoreRelationship(job, left, right)
    if P.ScoreAnchorRelationshipForJob then
        return P.ScoreAnchorRelationshipForJob(job, left, right)
    end
    return P.ScoreAnchorRelationship(left, right)
end

local function ExtendNode(job, node, candidate)
    local result = {
        sourceBySlot = CopyMap(node.sourceBySlot),
        sources = {},
        baseScore = (node.baseScore or 0) + (candidate.baseScore or 0),
        relationshipBonus = node.relationshipBonus or 0,
        visualRelationshipBonus = node.visualRelationshipBonus or node.relationshipBonus or 0,
        zonePairSupportBonus = node.zonePairSupportBonus or 0,
        pairScoreTotal = node.pairScoreTotal or 0,
        pairCount = node.pairCount or 0,
        hardClashes = node.hardClashes or 0,
        activeComponents = (node.activeComponents or 0) + 1,
    }
    for _, existing in ipairs(node.sources or {}) do result.sources[#result.sources + 1] = existing end
    for _, existing in ipairs(node.sources or {}) do
        local bonus, pairScore, _, hardClash, details = ScoreRelationship(job, existing, candidate)
        result.relationshipBonus = result.relationshipBonus + bonus
        result.visualRelationshipBonus = result.visualRelationshipBonus
            + (details and tonumber(details.visualBonus) or bonus)
        result.zonePairSupportBonus = result.zonePairSupportBonus
            + (details and tonumber(details.zonePairBonus) or 0)
        result.pairScoreTotal = result.pairScoreTotal + pairScore
        result.pairCount = result.pairCount + 1
        if hardClash then result.hardClashes = result.hardClashes + 1 end
    end
    result.sources[#result.sources + 1] = candidate
    result.sourceBySlot[candidate.slotKey] = candidate
    result.meanPairCohesion = result.pairCount > 0 and result.pairScoreTotal / result.pairCount or 0.50
    result.score = result.baseScore + result.relationshipBonus - result.hardClashes * 18
    return result
end

function P.CreateAnchorBeamWork(candidatePools, job, searchConfig, anchorSlots)
    return {
        candidatePools = candidatePools or {},
        job = job,
        anchorSlots = anchorSlots or P.ANCHOR_SLOT_ORDER,
        beamWidth = searchConfig and searchConfig.beamWidth or P.ANCHOR_BEAM_WIDTH,
        stageIndex = 1,
        beam = { NewRootNode() },
        nextBeam = {},
        nodeIndex = 1,
        candidateIndex = 1,
        expansions = { CHEST = 0, LEGS = 0, SHOULDER = 0 },
        retained = {},
        done = false,
    }
end

local function FinishBeamStage(work, slotKey)
    if #work.nextBeam > 0 then
        table.sort(work.nextBeam, function(left, right)
            if left.score == right.score then
                return P.AnchorSkeletonSignature(left.sourceBySlot) < P.AnchorSkeletonSignature(right.sourceBySlot)
            end
            return left.score > right.score
        end)
        work.beam = {}
        for index = 1, math.min(work.beamWidth or P.ANCHOR_BEAM_WIDTH, #work.nextBeam) do
            work.beam[index] = work.nextBeam[index]
        end
    end
    work.retained[slotKey] = #work.beam
    work.nextBeam = {}
    work.stageIndex = work.stageIndex + 1
    work.nodeIndex = 1
    work.candidateIndex = 1
    if work.stageIndex > #(work.anchorSlots or P.ANCHOR_SLOT_ORDER) then work.done = true end
end

function P.StepAnchorBeamWork(work)
    if not work or work.done then return true end
    local slotKey = (work.anchorSlots or P.ANCHOR_SLOT_ORDER)[work.stageIndex]
    local pool = work.candidatePools[slotKey] or {}
    if #pool == 0 then
        work.retained[slotKey] = #work.beam
        work.stageIndex = work.stageIndex + 1
        if work.stageIndex > #(work.anchorSlots or P.ANCHOR_SLOT_ORDER) then work.done = true end
        return work.done
    end

    local node = work.beam[work.nodeIndex]
    local candidate = pool[work.candidateIndex]
    if not node or not candidate then
        FinishBeamStage(work, slotKey)
        return work.done
    end

    work.nextBeam[#work.nextBeam + 1] = ExtendNode(work.job, node, candidate)
    work.expansions[slotKey] = (work.expansions[slotKey] or 0) + 1
    work.candidateIndex = work.candidateIndex + 1
    if work.candidateIndex > #pool then
        work.candidateIndex = 1
        work.nodeIndex = work.nodeIndex + 1
        if work.nodeIndex > #work.beam then FinishBeamStage(work, slotKey) end
    end
    return work.done
end

function P.ScoreWeaponBundleForAnchor(node, draft, styleMode, styleContext, job)
    local mainSource, mainSlotKey
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS) do
        if draft.selections[slotKey] then
            mainSlotKey = slotKey
            mainSource = P.GetSourceByID(slotKey, draft.selections[slotKey])
            break
        end
    end
    local offSource = draft.selections.OFF_HAND and P.GetSourceByID("OFF_HAND", draft.selections.OFF_HAND) or nil
    if not mainSource then return nil end

    local style = QC.ZoneStyle
    local mainCandidate = P.EvaluateAnchorCandidateForJob
        and P.EvaluateAnchorCandidateForJob(job, mainSource, P.slotByKey[mainSlotKey], styleContext, false)
        or P.BuildAnchorCandidate(mainSource, P.slotByKey[mainSlotKey], styleMode, styleContext)
    if not mainCandidate then return nil end
    local weaponCandidates = { mainCandidate }
    if offSource and tonumber(offSource.visualID) ~= tonumber(mainSource.visualID) then
        local offCandidate = P.EvaluateAnchorCandidateForJob
            and P.EvaluateAnchorCandidateForJob(job, offSource, P.slotByKey.OFF_HAND, styleContext, false)
            or P.BuildAnchorCandidate(offSource, P.slotByKey.OFF_HAND, styleMode, styleContext)
        if offCandidate then weaponCandidates[#weaponCandidates + 1] = offCandidate end
    end

    local relationshipBonus, visualRelationshipBonus, zonePairSupportBonus = 0, 0, 0
    local pairTotal, pairCount, hardClashes = 0, 0, 0
    for _, weaponCandidate in ipairs(weaponCandidates) do
        for _, armorCandidate in ipairs(node.sources or {}) do
            local bonus, pairScore, _, hardClash, details = ScoreRelationship(job, armorCandidate, weaponCandidate)
            relationshipBonus = relationshipBonus + bonus
            visualRelationshipBonus = visualRelationshipBonus + (details and tonumber(details.visualBonus) or bonus)
            zonePairSupportBonus = zonePairSupportBonus + (details and tonumber(details.zonePairBonus) or 0)
            pairTotal = pairTotal + pairScore
            pairCount = pairCount + 1
            if hardClash then hardClashes = hardClashes + 1 end
        end
    end
    if #weaponCandidates > 1 then
        local bonus, pairScore, _, hardClash, details = ScoreRelationship(job, weaponCandidates[1], weaponCandidates[2])
        relationshipBonus = relationshipBonus + bonus
        visualRelationshipBonus = visualRelationshipBonus + (details and tonumber(details.visualBonus) or bonus)
        zonePairSupportBonus = zonePairSupportBonus + (details and tonumber(details.zonePairBonus) or 0)
        pairTotal = pairTotal + pairScore
        pairCount = pairCount + 1
        if hardClash then hardClashes = hardClashes + 1 end
    end

    local baseScore = 0
    for _, candidate in ipairs(weaponCandidates) do baseScore = baseScore + (candidate.baseScore or 0) end
    local score = (node.score or 0) + baseScore + relationshipBonus - hardClashes * 18
    local signature = P.AnchorSkeletonSignature(node.sourceBySlot, draft.lastWeaponRoute)
    return {
        armorNode = node,
        draft = draft,
        mainSource = mainSource,
        offSource = offSource,
        mainSlotKey = mainSlotKey,
        weaponCandidates = weaponCandidates,
        weaponCount = offSource and 2 or 1,
        score = score,
        relationshipBonus = relationshipBonus,
        visualRelationshipBonus = visualRelationshipBonus,
        zonePairSupportBonus = zonePairSupportBonus,
        linkedVisualDeduplicated = offSource ~= nil and tonumber(offSource.visualID) == tonumber(mainSource.visualID),
        meanPairCohesion = pairCount > 0 and pairTotal / pairCount or node.meanPairCohesion or 0.50,
        hardClashes = (node.hardClashes or 0) + hardClashes,
        activeComponents = (node.activeComponents or 0) + 1,
        signature = signature,
    }
end

local function AnchorSelectionDetails(choice, qualitySize, classSize, chosenClass)
    local selection = choice.novelty or {}
    selection.baseScore = tonumber(choice.entry.score) or 0
    selection.adjustedScore = tonumber(choice.adjustedScore) or selection.baseScore
    selection.repeatPenalty = tonumber(selection.repeatPenalty) or 0
    selection.qualityShortlistSize = qualitySize
    selection.noveltyClassSize = classSize
    if chosenClass == "EXACT_REPEAT" then
        selection.exactRepeatAccepted = true
        selection.exactRepeatReason = "No meaningfully new or partial-change skeleton remained inside the quality window."
    end
    return selection
end

function P.BuildAnchorSkeletonChoices(finalists, options)
    if not finalists or #finalists == 0 then return {}, {}, nil end
    if type(options) ~= "table" then options = { previousSignature = options } end
    table.sort(finalists, function(left, right) return (left.score or 0) > (right.score or 0) end)
    local quality = {}
    local bestScore = tonumber(finalists[1].score) or 0
    local finalShortlist = math.max(1, math.floor(tonumber(options.finalShortlist) or P.ANCHOR_FINAL_SHORTLIST))
    local scoreWindow = math.max(0, tonumber(options.scoreWindow) or P.ANCHOR_FINAL_SCORE_WINDOW)
    for index = 1, math.min(finalShortlist, #finalists) do
        local entry = finalists[index]
        if index > 1 and (tonumber(entry.score) or 0) < bestScore - scoreWindow then break end
        local novelty
        if options.action == "GENERATE_OUTFIT" and (P.ClassifyAnchorNoveltyForOptions or P.EvaluateAnchorNovelty) then
            novelty = P.ClassifyAnchorNoveltyForOptions
                and P.ClassifyAnchorNoveltyForOptions(entry, options.noveltyContext, options)
                or P.EvaluateAnchorNovelty(entry, options.noveltyContext)
        else
            novelty = {
                class = nil, classPriority = 0, baseScore = tonumber(entry.score) or 0,
                adjustedScore = tonumber(entry.score) or 0, repeatPenalty = 0,
                comparedComponents = {}, changedComponents = {}, repeatedComponents = {},
                comparedCount = 0, changedCount = 0, repeatedCount = 0,
            }
            if options.previousSignature and entry.signature == options.previousSignature and #finalists > 1 then
                novelty.adjustedScore = novelty.adjustedScore - 35
                novelty.repeatPenalty = -35
            end
        end
        quality[#quality + 1] = { entry = entry, baseRank = index, adjustedScore = novelty.adjustedScore, novelty = novelty }
    end
    local choices, chosenClass = quality, nil
    if options.action == "GENERATE_OUTFIT" and options.noveltyContext and options.noveltyContext.available then
        local bestPriority = -math.huge
        for _, choice in ipairs(quality) do bestPriority = math.max(bestPriority, tonumber(choice.novelty.classPriority) or 0) end
        choices = {}
        for _, choice in ipairs(quality) do
            if (tonumber(choice.novelty.classPriority) or 0) == bestPriority then
                choices[#choices + 1] = choice
                chosenClass = choice.novelty.class
            end
        end
    end
    return quality, choices, chosenClass
end

function P.ChooseAnchorSkeleton(finalists, options)
    local quality, choices, chosenClass = P.BuildAnchorSkeletonChoices(finalists, options)
    if #choices == 0 then return nil end
    local minimum = tonumber(choices[#choices].adjustedScore) or 0
    if type(options) == "table" and options.action == "GENERATE_OUTFIT" and options.noveltyContext and options.noveltyContext.available then
        minimum = math.huge
        for _, choice in ipairs(choices) do minimum = math.min(minimum, tonumber(choice.adjustedScore) or 0) end
    end
    local total = 0
    for _, choice in ipairs(choices) do
        choice.weight = math.max(1, (tonumber(choice.adjustedScore) or 0) - minimum + 5) ^ 2
        total = total + choice.weight
    end
    local roll = math.random() * total
    local selectedChoice = choices[#choices]
    for _, choice in ipairs(choices) do
        roll = roll - choice.weight
        if roll <= 0 then selectedChoice = choice break end
    end
    return selectedChoice.entry, selectedChoice.baseRank, #quality,
        AnchorSelectionDetails(selectedChoice, #quality, #choices, chosenClass)
end

function P.GetNextAnchorSkeleton(finalists, options, excludedSignatures)
    local quality, choices, chosenClass = P.BuildAnchorSkeletonChoices(finalists, options)
    local visited = {}
    local function Find(pool, classLabel)
        for _, choice in ipairs(pool or {}) do
            local signature = choice.entry and choice.entry.signature
            if signature and not visited[signature] then
                visited[signature] = true
                if not (excludedSignatures and excludedSignatures[signature]) then
                    return choice.entry, choice.baseRank, #quality,
                        AnchorSelectionDetails(choice, #quality, #choices, classLabel or choice.novelty.class)
                end
            end
        end
    end
    local selected, rank, shortlist, details = Find(choices, chosenClass)
    if selected then return selected, rank, shortlist, details end
    return Find(quality, nil)
end

function Wardrobe.GetLastAnchorSkeletonDiagnostics()
    return P.lastAnchorSkeletonDiagnostics
end

function Wardrobe.PrintAnchorSkeletonDiagnostics()
    local d = P.lastAnchorSkeletonDiagnostics
    local printLine = QC.Print or print
    if not d then printLine("No anchor skeleton has been generated this session.") return nil end
    if d.fallbackReason and not d.sources then
        printLine("Anchor skeleton fallback: " .. tostring(d.fallbackReason))
        return d
    end
    printLine(string.format("Anchor skeleton rank %d/%d • score %.1f • cohesion %.3f", d.chosenRank or 0, d.shortlistSize or 0, d.score or 0, d.meanPairCohesion or 0))
    for _, slotKey in ipairs(P.ANCHOR_SLOT_ORDER) do
        local source = d.sources and d.sources[slotKey]
        printLine(string.format("  %s: %s", P.slotByKey[slotKey].label, source and (source.styleName or source.name or source.sourceID) or "Hidden/unavailable"))
    end
    printLine(string.format("  Main Hand: %s", d.mainSource and (d.mainSource.styleName or d.mainSource.name or d.mainSource.sourceID) or "None"))
    printLine(string.format("  Off Hand: %s", d.offSource and (d.offSource.styleName or d.offSource.name or d.offSource.sourceID) or "None"))
    if d.noveltyClass then
        printLine(string.format("  Novelty: %s • changed %s • repeated %s • penalty %.1f", P.GetAnchorNoveltyClassLabel and P.GetAnchorNoveltyClassLabel(d.noveltyClass) or tostring(d.noveltyClass), #(d.changedComponents or {}), #(d.repeatedComponents or {}), tonumber(d.repeatPenalty) or 0))
    end
    printLine(string.format("  Beam: %d chest • %d legs • %d shoulders • %d weapon bundles • fallback %s", d.expansions and d.expansions.CHEST or 0, d.expansions and d.expansions.LEGS or 0, d.expansions and d.expansions.SHOULDER or 0, d.weaponBundles or 0, tostring(d.fallbackReason or "none")))
    return d
end
