local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

local function FinishEligibilityWork(work, eligible, kind, reason)
    work.done, work.eligible, work.kind, work.reason = true, eligible == true, kind, reason
    return true, work.eligible, kind, reason, "COMPLETE"
end

local function EraOptions(work)
    return { executionMode = work.executionMode, schedulerOwner = work.schedulerOwner }
end

function ZoneStyle.CreateSourceEligibilityWork(source, modeKey, context, resolvedEraEvidence, prechecked, options)
    local executionMode, schedulerOwner = P.NormalizeEraExecutionOptions(options, P.ERA_EXECUTION_SYNCHRONOUS)
    return {
        source = source, modeKey = modeKey, context = context or ZoneStyle.GetCurrentContext(),
        eraEvidence = resolvedEraEvidence, prechecked = prechecked == true,
        executionMode = executionMode, schedulerOwner = schedulerOwner,
        stage = "PRECHECK", markerIndex = 1, done = false,
    }
end

function ZoneStyle.StepSourceEligibilityWork(work, markerBatch)
    if not work then return true, false, "pending", "No eligibility work was provided.", "COMPLETE" end
    if work.done then return true, work.eligible, work.kind, work.reason, "COMPLETE" end
    markerBatch = math.max(1, math.floor(tonumber(markerBatch) or 4))
    local source, context = work.source, work.context

    if work.stage == "PRECHECK" then
        if not work.prechecked then
            local eligible, kind, reason = ZoneStyle.GetSourcePreEraEligibility(source, context)
            if not eligible then return FinishEligibilityWork(work, false, kind, reason) end
        end
        work.stage = work.eraEvidence and "ERA_APPLY" or "ERA_INIT"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "ERA_INIT" then
        work.eraWork = ZoneStyle.CreateSourceEraEvidenceWork(source, EraOptions(work))
        if work.eraWork.done then
            work.eraEvidence, work.stage = work.eraWork.result, "ERA_APPLY"
        else
            work.stage = "ERA_STEP"
        end
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "ERA_STEP" then
        local done, evidence, _, status = ZoneStyle.StepSourceEraEvidenceWork(work.eraWork, 1)
        if status == "DEFERRED" then return false, nil, nil, nil, "DEFERRED" end
        if not done then return false, nil, nil, nil, "PROGRESSED" end
        work.eraEvidence, work.stage = evidence, "ERA_APPLY"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "ERA_APPLY" then
        if context.eraMax == nil then context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context) end
        work.eraMax, work.eraLabel = context.eraMax, context.eraLabel
        if not work.eraEvidence or work.eraEvidence.expansionID == nil then
            local reason = work.eraEvidence and work.eraEvidence.reason or "WoW did not expose source-era evidence."
            return FinishEligibilityWork(work, false, "pending", reason)
        end
        work.expansionID = work.eraEvidence.expansionID
        work.curatedOrigin = P.GetCuratedSourceOrigin(source, work.expansionID)
        work.evidenceText = ZoneStyle.FormatEraEvidence(work.eraEvidence)
        local settings = QC.GetSettings and QC.GetSettings() or {}
        work.restrictToZoneEra = settings.restrictOutfitsToZoneEra ~= false
        work.eraEligibilityText = work.restrictToZoneEra and ("through " .. tostring(work.eraLabel)) or "with the zone era limit disabled"
        if work.restrictToZoneEra and work.expansionID > work.eraMax then
            local expansion = ZoneStyle.expansions[work.expansionID]
            return FinishEligibilityWork(work, false, "era", string.format(
                "%s appearance (%s); this zone permits Classic through %s.",
                expansion and expansion.label or ("Expansion " .. tostring(work.expansionID)),
                work.evidenceText, work.eraLabel
            ))
        end
        work.stage = "PROVENANCE"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "PROVENANCE" then
        if not context.provenanceResolved then
            local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
            context.provenanceKey, context.provenanceLabel = resolvedKey, resolved and resolved.label or context.zone
            context.provenanceResolved = true
        end
        work.provenance = P.provenanceByKey[context.provenanceKey]
        if not work.provenance then return FinishEligibilityWork(work, true, "eligible", "Eligible " .. work.eraEligibilityText .. ".") end
        context.provenanceKey, context.provenanceLabel = work.provenance.key, work.provenance.label
        work.stage = "CURATED"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "CURATED" then
        if work.curatedOrigin then
            if work.curatedOrigin.provenanceKey == work.provenance.key then
                return FinishEligibilityWork(work, true, "eligible", string.format("Curated %s origin; eligible for %s %s.", work.curatedOrigin.label, work.provenance.label, work.eraEligibilityText))
            end
            return FinishEligibilityWork(work, false, "zone", string.format("%s starter reward; outside the %s source pool.", work.curatedOrigin.label, work.provenance.label))
        end
        work.stage = "DROP"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "DROP" then
        local dropText, dropLabel = P.GetDropOrigin(source)
        if dropText ~= "" then
            if P.TextMatchesAny(dropText, work.provenance.origins) then return FinishEligibilityWork(work, true, "eligible", string.format("Eligible for %s %s.", work.provenance.label, work.eraEligibilityText)) end
            return FinishEligibilityWork(work, false, "zone", string.format("%s is outside the %s source pool.", dropLabel or "This boss drop", work.provenance.label))
        end
        work.stage = "TRACKED"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "TRACKED" then
        local trackedOrigin = P.GetTrackedSourceOrigin(source)
        if trackedOrigin and trackedOrigin.provenanceKey then
            if trackedOrigin.provenanceKey == work.provenance.key then return FinishEligibilityWork(work, true, "eligible", string.format("WoW tracks this appearance to %s; eligible %s.", trackedOrigin.label, work.eraEligibilityText)) end
            return FinishEligibilityWork(work, false, "zone", string.format("WoW tracks this appearance to %s, outside the %s source pool.", trackedOrigin.label, work.provenance.label))
        end
        work.stage = "METADATA"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "METADATA" then
        work.metadata = P.SourceMetadata(source)
        if P.TextMatchesAny(work.metadata, work.provenance.origins) then return FinishEligibilityWork(work, true, "eligible", string.format("Eligible for %s %s.", work.provenance.label, work.eraEligibilityText)) end
        work.paddedMetadata = " " .. work.metadata .. " "
        work.markerIndex = 1
        work.stage = "MARKERS"
        return false, nil, nil, nil, "PROGRESSED"
    elseif work.stage == "MARKERS" then
        local last = math.min(#P.provenanceOriginMarkers, work.markerIndex + markerBatch - 1)
        for index = work.markerIndex, last do
            local marker = P.provenanceOriginMarkers[index]
            if not marker.profileKeys[work.provenance.key] and work.paddedMetadata:find(" " .. marker.text .. " ", 1, true) then
                return FinishEligibilityWork(work, false, "zone", string.format("Associated with %s, not %s.", marker.profile.label, work.provenance.label))
            end
        end
        work.markerIndex = last + 1
        if work.markerIndex <= #P.provenanceOriginMarkers then return false, nil, nil, nil, "PROGRESSED" end
        return FinishEligibilityWork(work, true, "eligible", work.restrictToZoneEra
            and ("Era verified: " .. work.evidenceText .. "; no conflicting source zone is reported by WoW.")
            or ("Zone era limit disabled; era evidence: " .. work.evidenceText .. "."))
    end
    return FinishEligibilityWork(work, false, "pending", "Eligibility work entered an unknown stage.")
end

function ZoneStyle.GetSourceEligibility(source, modeKey, context, resolvedEraEvidence, prechecked)
    local work = ZoneStyle.CreateSourceEligibilityWork(source, modeKey, context, resolvedEraEvidence, prechecked, {
        executionMode = P.ERA_EXECUTION_SYNCHRONOUS,
    })
    local guard = 0
    while not work.done do
        local _, _, _, _, status = ZoneStyle.StepSourceEligibilityWork(work, 16)
        guard = guard + 1
        if status == "DEFERRED" or guard > 8192 then
            work.done, work.eligible, work.kind, work.reason = true, false, "pending", "Synchronous eligibility failed to make bounded progress."
        end
    end
    return work.eligible, work.kind, work.reason
end
