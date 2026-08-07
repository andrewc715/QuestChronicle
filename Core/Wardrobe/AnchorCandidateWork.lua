local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local API_RESERVE_MS = 3.0

local function IsZonePolicyJob(job)
    return job and job.modePolicy and job.modePolicy.capabilities
        and job.modePolicy.capabilities.zoneAnchorPolicy == true
end

local function TrackingNeedsAPI(source)
    local style = QC.ZoneStyle
    local private = style and style._Private
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or not private then return false end
    if private.trackedOriginCache and private.trackedOriginCache[sourceID] ~= nil then return false end
    local trackingType = private.GetAppearanceTrackingType and private.GetAppearanceTrackingType()
    return trackingType ~= nil and C_ContentTracking and type(C_ContentTracking.GetBestMapForTrackable) == "function"
end

local function SetIDsNeedAPI(source)
    local style = QC.ZoneStyle
    local private = style and style._Private
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or not private then return false end
    if private.sourceSetCache and private.sourceSetCache[sourceID] ~= nil then return false end
    return C_TransmogSets and type(C_TransmogSets.GetSetsContainingSourceID) == "function"
end

local function MetadataNeedsAPI(source)
    local private = QC.ZoneStyle and QC.ZoneStyle._Private
    if not source or not source.itemID or not private then return false end
    return not (private.IsSourceItemMetadataTrusted and private.IsSourceItemMetadataTrusted(source))
end

local function SourceIdentity(source)
    return tostring(source and (source.visualID or source.sourceID or source.itemID) or "")
end

local function BuildLegacyCandidate(work)
    local source, definition = work.source, work.definition
    local score = tonumber(work.baseScore) or 0
    local descriptor = work.prepared and work.prepared.descriptor
    local weight = math.max(1, score + 4) ^ 2
    local randomValue = math.max(0.000001, math.random())
    work.randomValue = randomValue
    work.candidate = {
        source = source,
        definition = definition,
        slotKey = definition.key,
        baseScore = score,
        scoreReasons = work.scoreReasons or {},
        weight = weight,
        poolRandomValue = randomValue,
        poolPriority = math.log(randomValue) / weight,
        descriptor = descriptor,
        diversityKey = descriptor and ((descriptor.setIDs and descriptor.setIDs[1] and ("SET:" .. tostring(descriptor.setIDs[1])))
            or table.concat({ descriptor.dominantMaterial or "?", descriptor.dominantMotif or "?", descriptor.dominantPalette or "?" }, ":"))
            or ("VISUAL:" .. SourceIdentity(source)),
        coherenceScore = work.coherenceScore,
        coherenceReason = work.coherenceReason,
    }
end

function P.CreateAnchorCandidateWork(job, source, definition, styleContext, fixed, eraEvidence)
    local style = QC.ZoneStyle
    local private = style and style._Private
    return {
        job = job,
        source = source,
        definition = definition,
        styleMode = job and job.styleMode,
        styleContext = styleContext or (job and job.styleContext),
        fixed = fixed == true,
        eraEvidence = eraEvidence,
        prepared = private and private.NewPreparedSourceInputs and private.NewPreparedSourceInputs(source, eraEvidence) or {},
        stage = eraEvidence ~= nil and "METADATA_SNAPSHOT" or "ERA_INIT",
        done = source == nil or definition == nil,
        result = nil,
        lastStage = nil,
        lastInvokedAPI = false,
    }
end

function P.DescribeNextAnchorCandidateOperation(work)
    if not work or work.done then return { class = "COMPLETE", phase = "COMPLETE", reserveMs = 0 } end
    local stage = work.stage
    if stage == "METADATA_SNAPSHOT" and MetadataNeedsAPI(work.source) then
        return { class = "API_HEADROOM", phase = stage, reserveMs = API_RESERVE_MS }
    elseif stage == "SET_IDS_SNAPSHOT" and SetIDsNeedAPI(work.source) then
        return { class = "API_HEADROOM", phase = stage, reserveMs = API_RESERVE_MS }
    elseif stage == "TRACKING" and TrackingNeedsAPI(work.source) then
        return { class = "API_HEADROOM", phase = stage, reserveMs = API_RESERVE_MS }
    end
    return { class = "LOCAL", phase = stage, reserveMs = 1.0 }
end

local function Finish(work, result)
    work.result = result
    work.done = true
    work.stage = "COMPLETE"
    return true, result
end

function P.StepAnchorCandidateWork(work)
    if not work or work.done then return true, work and work.result end
    local style = QC.ZoneStyle
    local private = style and style._Private
    local Generation = QC.Generation
    local Zone = style and style.Zone
    work.lastStage = work.stage
    work.lastInvokedAPI, work.lastAPIKind, work.lastPreparedHit = false, nil, nil

    if work.stage == "ERA_INIT" then
        if style and style.CreateSourceEraEvidenceWork then
            work.eraWork = style.CreateSourceEraEvidenceWork(work.source, {
                executionMode = private and private.ERA_EXECUTION_GENERATION_COOPERATIVE,
                schedulerOwner = work.job,
            })
            if work.eraWork.done then
                work.eraEvidence = work.eraWork.result
                work.prepared.expansionID = work.eraEvidence and tonumber(work.eraEvidence.expansionID) or nil
                work.prepared.expansionIDKnown = true
                work.stage = "METADATA_SNAPSHOT"
            else
                work.stage = "ERA_STEP"
            end
        else
            work.prepared.expansionID = work.source and work.source.expansionID or nil
            work.prepared.expansionIDKnown = false
            work.stage = "METADATA_SNAPSHOT"
        end
    elseif work.stage == "ERA_STEP" then
        local done, evidence = style.StepSourceEraEvidenceWork(work.eraWork, P.GENERATION_ERA_CANDIDATES_PER_OPERATION)
        if not done then return false end
        work.eraEvidence = evidence
        work.prepared.expansionID = evidence and tonumber(evidence.expansionID) or nil
        work.prepared.expansionIDKnown = true
        work.stage = "METADATA_SNAPSHOT"
    elseif work.stage == "METADATA_SNAPSHOT" then
        if MetadataNeedsAPI(work.source) and private and private.LoadItemMetadata then
            work.lastInvokedAPI, work.lastAPIKind = true, "metadata"
            work.metadataAPICalls = (work.metadataAPICalls or 0) + 1
            private.LoadItemMetadata(work.source)
        else
            work.lastPreparedHit = "metadata"
        end
        work.prepared.metadataText = private and private.BuildSourceMetadataSnapshot
            and private.BuildSourceMetadataSnapshot(work.source)
            or (private and private.SourceMetadata and private.SourceMetadata(work.source) or "")
        work.prepared.itemMetadataVerified = private and private.IsSourceItemMetadataTrusted
            and private.IsSourceItemMetadataTrusted(work.source) or false
        work.stage = "SET_IDS_SNAPSHOT"
    elseif work.stage == "SET_IDS_SNAPSHOT" then
        if SetIDsNeedAPI(work.source) then
            work.lastInvokedAPI, work.lastAPIKind = true, "set"
            work.setListAPICalls = (work.setListAPICalls or 0) + 1
        else
            work.lastPreparedHit = "set"
        end
        work.prepared.setIDs = private and private.GetSourceSetIDs and private.GetSourceSetIDs(work.source) or {}
        work.prepared.setIDsKnown = true
        work.stage = "STYLE_SIGNALS"
    elseif work.stage == "STYLE_SIGNALS" then
        work.prepared.styleSignals = private and private.GetSourceStyleSignalsPrepared
            and private.GetSourceStyleSignalsPrepared(work.source, work.prepared.metadataText)
            or (private and private.GetSourceStyleSignals and private.GetSourceStyleSignals(work.source))
        work.stage = "COHERENCE"
    elseif work.stage == "COHERENCE" then
        work.coherenceScore, work.coherent, work.coherenceReason = 0, true, nil
        local coherence = style and (style.GetSourceCoherencePrepared or style.GetSourceCoherence)
        if coherence then
            work.coherenceScore, work.coherent, work.coherenceReason = coherence(work.source, work.styleContext, work.prepared)
        end
        if work.coherent == false and not work.fixed then return Finish(work, nil) end
        if work.fixed then work.coherent = true end
        work.stage = "LEGACY_SCORE"
    elseif work.stage == "LEGACY_SCORE" then
        work.baseScore, work.scoreReasons = 10, {}
        local scorer = style and (style.ScoreSourcePrepared or style.ScoreSource)
        if scorer then
            work.baseScore, work.scoreReasons = scorer(
                work.source, work.definition, work.styleMode, work.styleContext,
                work.coherenceScore, work.coherent, work.coherenceReason, work.prepared
            )
        end
        work.stage = "DESCRIPTOR"
    elseif work.stage == "DESCRIPTOR" then
        work.prepared.descriptor = style and style.GetTravelerDescriptor
            and style.GetTravelerDescriptor(work.source, work.definition, work.prepared) or nil
        work.stage = "POOL_RANDOM"
    elseif work.stage == "POOL_RANDOM" then
        BuildLegacyCandidate(work)
        if work.job and work.job.zoneAnchorPolicyFallback then
            work.stage = "ZONE_POLICY_APPLY"
        elseif IsZonePolicyJob(work.job) then
            work.stage = "TRACKING"
        else
            return Finish(work, work.candidate)
        end
    elseif work.stage == "TRACKING" then
        local sourceID = tonumber(work.source and work.source.sourceID)
        if TrackingNeedsAPI(work.source) then
            work.lastInvokedAPI, work.lastAPIKind = true, "tracking"
            work.trackingAPICalls = (work.trackingAPICalls or 0) + 1
        else
            work.lastPreparedHit = "tracking"
        end
        if sourceID and private and private.trackedOriginCache and private.trackedOriginCache[sourceID] ~= nil then
            work.prepared.trackedOrigin = private.trackedOriginCache[sourceID] or nil
        elseif private and private.GetTrackedSourceOrigin then
            work.prepared.trackedOrigin = private.GetTrackedSourceOrigin(work.source)
        end
        work.prepared.trackedOriginKnown = true
        work.stage = "ZONE_AFFINITY"
    elseif work.stage == "ZONE_AFFINITY" then
        local analyzer = Generation and Generation.ZoneAffinityPolicy and Generation.ZoneAffinityPolicy.AnalyzeAppearance
        work.affinity = analyzer and analyzer(work.source, work.definition, work.job and work.job.modeContext, work.prepared) or nil
        work.stage = "ZONE_POLICY_APPLY"
    elseif work.stage == "ZONE_POLICY_APPLY" then
        if work.job and work.job.zoneAnchorPolicyFallback then
            work.candidate.anchorPolicy = {
                policyID = Zone and Zone.ANCHOR_POLICY_ID,
                policyFormat = Zone and Zone.ANCHOR_POLICY_FORMAT,
                authority = "FALLBACK",
                legacyRelevance = work.candidate.baseScore,
                zoneAffinity = 0,
                zoneConfidence = 0,
                zoneClassification = "UNKNOWN",
                zoneAdjustment = 0,
                slotMultiplier = 1,
                finalRelevance = work.candidate.baseScore,
                locked = work.fixed == true,
                reasons = { "Zone context was unavailable; the legacy score remained authoritative." },
            }
            return Finish(work, work.candidate)
        end
        if Zone and Zone.ApplyAnchorEvidence then
            work.candidate = Zone.ApplyAnchorEvidence(work.candidate, work.affinity, work.definition, work.fixed)
        end
        work.stage = "PREFERENCE"
    elseif work.stage == "PREFERENCE" then
        if work.candidate and work.candidate.anchorPolicy and style and style.GetSourcePreference then
            work.candidate.anchorPolicy.favorite = style.GetSourcePreference(work.source, work.styleContext) == "favorite"
        end
        return Finish(work, work.candidate)
    else
        return Finish(work, work.candidate)
    end
    return work.done, work.result
end

local function GetWeaponSources(draft)
    local mainSource, mainSlotKey
    for _, slotKey in ipairs(P.MAIN_WEAPON_SLOT_KEYS or {}) do
        if draft and draft.selections and draft.selections[slotKey] then
            mainSlotKey = slotKey
            mainSource = P.GetSourceByID(slotKey, draft.selections[slotKey])
            break
        end
    end
    local offSource = draft and draft.selections and draft.selections.OFF_HAND
        and P.GetSourceByID("OFF_HAND", draft.selections.OFF_HAND) or nil
    return mainSource, mainSlotKey, offSource
end

function P.CreateWeaponAnchorScoringWork(job, node, draft, styleContext)
    local mainSource, mainSlotKey, offSource = GetWeaponSources(draft)
    return {
        job = job, node = node, draft = draft, styleContext = styleContext,
        mainSource = mainSource, mainSlotKey = mainSlotKey, offSource = offSource,
        stage = mainSource and "MAIN_CANDIDATE" or "COMPLETE", done = mainSource == nil,
        weaponCandidates = {}, weaponIndex = 1, armorIndex = 1,
        relationshipBonus = 0, visualRelationshipBonus = 0, zonePairSupportBonus = 0,
        pairTotal = 0, pairCount = 0, hardClashes = 0,
    }
end

function P.DescribeNextWeaponAnchorScoringOperation(work)
    if not work or work.done then return { class = "COMPLETE", phase = "COMPLETE", reserveMs = 0 } end
    if work.stage == "MAIN_CANDIDATE" or work.stage == "OFF_CANDIDATE" then
        local candidateWork = work.candidateWork
        if candidateWork then return P.DescribeNextAnchorCandidateOperation(candidateWork) end
        return { class = "LOCAL", phase = work.stage, reserveMs = 0.5 }
    end
    return { class = "LOCAL", phase = work.stage, reserveMs = 0.75 }
end

local function AddRelationship(work, left, right)
    local bonus, pairScore, _, hardClash, details
    if P.ScoreAnchorRelationshipForJob then
        bonus, pairScore, _, hardClash, details = P.ScoreAnchorRelationshipForJob(work.job, left, right)
    else
        bonus, pairScore, _, hardClash = P.ScoreAnchorRelationship(left, right)
    end
    work.relationshipBonus = work.relationshipBonus + (bonus or 0)
    work.visualRelationshipBonus = work.visualRelationshipBonus + (details and tonumber(details.visualBonus) or bonus or 0)
    work.zonePairSupportBonus = work.zonePairSupportBonus + (details and tonumber(details.zonePairBonus) or 0)
    work.pairTotal = work.pairTotal + (pairScore or 0.5)
    work.pairCount = work.pairCount + 1
    if hardClash then work.hardClashes = work.hardClashes + 1 end
end

local function FinalizeWeaponAnchorWork(work)
    local baseScore = 0
    for _, candidate in ipairs(work.weaponCandidates) do baseScore = baseScore + (candidate.baseScore or 0) end
    local node = work.node
    local score = (node.score or 0) + baseScore + work.relationshipBonus - work.hardClashes * 18
    work.result = {
        armorNode = node,
        draft = work.draft,
        mainSource = work.mainSource,
        offSource = work.offSource,
        mainSlotKey = work.mainSlotKey,
        weaponCandidates = work.weaponCandidates,
        weaponCount = work.offSource and 2 or 1,
        score = score,
        relationshipBonus = work.relationshipBonus,
        visualRelationshipBonus = work.visualRelationshipBonus,
        zonePairSupportBonus = work.zonePairSupportBonus,
        linkedVisualDeduplicated = work.offSource ~= nil and tonumber(work.offSource.visualID) == tonumber(work.mainSource.visualID),
        meanPairCohesion = work.pairCount > 0 and work.pairTotal / work.pairCount or node.meanPairCohesion or 0.50,
        hardClashes = (node.hardClashes or 0) + work.hardClashes,
        activeComponents = (node.activeComponents or 0) + 1,
        signature = P.AnchorSkeletonSignature(node.sourceBySlot, work.draft.lastWeaponRoute),
    }
    work.done, work.stage = true, "COMPLETE"
    return true, work.result
end

function P.StepWeaponAnchorScoringWork(work)
    if not work or work.done then return true, work and work.result end
    if work.stage == "MAIN_CANDIDATE" then
        if not work.candidateWork then
            work.candidateWork = P.CreateAnchorCandidateWork(work.job, work.mainSource, P.slotByKey[work.mainSlotKey], work.styleContext, false, nil)
        end
        local done, candidate = P.StepAnchorCandidateWork(work.candidateWork)
        if not done then return false end
        work.candidateWork = nil
        if not candidate then work.done, work.stage = true, "COMPLETE" return true, nil end
        work.weaponCandidates[1] = candidate
        if work.offSource and tonumber(work.offSource.visualID) ~= tonumber(work.mainSource.visualID) then
            work.stage = "OFF_CANDIDATE"
        else
            work.stage = "RELATIONSHIP"
        end
    elseif work.stage == "OFF_CANDIDATE" then
        if not work.candidateWork then
            work.candidateWork = P.CreateAnchorCandidateWork(work.job, work.offSource, P.slotByKey.OFF_HAND, work.styleContext, false, nil)
        end
        local done, candidate = P.StepAnchorCandidateWork(work.candidateWork)
        if not done then return false end
        work.candidateWork = nil
        if candidate then work.weaponCandidates[#work.weaponCandidates + 1] = candidate end
        work.stage = "RELATIONSHIP"
    elseif work.stage == "RELATIONSHIP" then
        local weaponCandidate = work.weaponCandidates[work.weaponIndex]
        local armorCandidate = work.node.sources and work.node.sources[work.armorIndex]
        if weaponCandidate and armorCandidate then
            AddRelationship(work, armorCandidate, weaponCandidate)
            work.armorIndex = work.armorIndex + 1
            if work.armorIndex > #(work.node.sources or {}) then
                work.armorIndex = 1
                work.weaponIndex = work.weaponIndex + 1
            end
        else
            work.stage = #work.weaponCandidates > 1 and "WEAPON_PAIR" or "FINALIZE"
        end
    elseif work.stage == "WEAPON_PAIR" then
        AddRelationship(work, work.weaponCandidates[1], work.weaponCandidates[2])
        work.stage = "FINALIZE"
    elseif work.stage == "FINALIZE" then
        return FinalizeWeaponAnchorWork(work)
    else
        return FinalizeWeaponAnchorWork(work)
    end
    return work.done, work.result
end
