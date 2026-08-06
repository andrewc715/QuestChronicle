local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers
P.GENERATION_TIME_BUDGET_MS = 5.5
P.GENERATION_OPERATION_SAFETY_CAP = 2000
P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
P.generationToken = P.generationToken or 0
P.generationJob = nil
P.lastGenerationPerformance = nil
local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end
local function BeginWorkerSlice()
    if P.BeginGenerationWorkerSlice then return P.BeginGenerationWorkerSlice() end
    if Workers and Workers.BeginSlice then return Workers.BeginSlice(P.GENERATION_TIME_BUDGET_MS, 7.5) end
    return { startedAtMs = NowMilliseconds(), preferredMs = P.GENERATION_TIME_BUDGET_MS }
end
local function WorkerShouldYield(slice, reserveMs)
    if Workers and Workers.ShouldYield then return Workers.ShouldYield(slice, reserveMs) end
    return NowMilliseconds() - (slice.startedAtMs or 0) >= (slice.preferredMs or P.GENERATION_TIME_BUDGET_MS)
end
local function RecordPhase(job, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
end
local function ScheduleNextStep(token)
    if not C_Timer or type(C_Timer.After) ~= "function" then return false end
    C_Timer.After(0, function()
        if P.generationJob and P.generationJob.token == token then
            P.StepGenerationJob(token)
        end
    end)
    return true
end
local function Notify(event, ...)
    if QC.Notify then QC.Notify(event, ...) end
end
local function FinishJob(job, success, message)
    if not job or P.generationJob ~= job then return end
    if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
    local finishedAt = NowMilliseconds()
    local performance = P.BuildGenerationPerformance
        and P.BuildGenerationPerformance(job, finishedAt)
        or {
            elapsedMs = math.max(0, finishedAt - job.startedAtMs),
            steps = job.steps or 0,
            maxStepMs = job.maxStepMs or 0,
            candidates = job.candidatesProcessed or 0,
            selectedArmor = job.selectedArmor or 0,
        }
    P.lastGenerationPerformance = performance
    if job.sharedAction and QC.Generation and QC.Generation.CompleteAction then QC.Generation.CompleteAction(job.sharedAction, success == true, message, performance) end
    P.generationJob = nil
    local notifyStarted = NowMilliseconds()
    Notify("WARDROBE_GENERATION_COMPLETE", success == true, message, performance)
    if Wardrobe.RecordGenerationPostPhase then
        Wardrobe.RecordGenerationPostPhase(performance, "completionNotify", NowMilliseconds() - notifyStarted)
    end
    if QC.Diagnostics and QC.Diagnostics.QueueGenerationAttempt then QC.Diagnostics.QueueGenerationAttempt(job, success == true, message, performance) end
    return performance
end
local function BuildGenerationMessage(job, generatedName, weaponCount, weaponNotice)
    local styleLabel = "Random"
    local profileLabel
    local restrictionLabel
    local styleEngine = job.styleEngine
    if styleEngine then
        local modeInfo = styleEngine.GetModeInfo(job.styleMode)
        styleLabel = modeInfo and modeInfo.label or styleLabel
        profileLabel = job.styleContext and job.styleContext.profileLabel
        restrictionLabel = styleEngine.GetContextRestrictionLabel and styleEngine.GetContextRestrictionLabel(job.styleContext)
        if job.styleMode == styleEngine.MODE_ZONE_NATIVE then styleEngine.ConsumeSuggestion() end
    end
    local message = string.format(
        "Generated %s, a %s outfit%s with %d armor slots and %d equipped-weapon-safe appearance%s%s; locked and hidden choices were preserved.",
        generatedName or "a new outfit",
        styleLabel,
        profileLabel and (" for " .. profileLabel) or "",
        job.selectedArmor or 0,
        weaponCount or 0,
        weaponCount == 1 and "" or "s",
        restrictionLabel and (" under " .. restrictionLabel) or ""
    )
    if job.anchorStats then
        message = message .. string.format(" Anchor skeleton rank %d/%d scored %.1f.", job.anchorStats.chosenRank or 0, job.anchorStats.shortlistSize or 0, job.anchorStats.chosenScore or 0)
        if job.anchorStats.noveltyClass and P.GetAnchorNoveltyClassLabel then
            message = message .. " Novelty: " .. P.GetAnchorNoveltyClassLabel(job.anchorStats.noveltyClass) .. "."
        end
    elseif job.anchorFallbackReason then
        message = message .. " Anchor search used the legacy fallback: " .. tostring(job.anchorFallbackReason) .. "."
    end
    if job.supportStats then
        message = message .. string.format(" Contextual support cohesion %.3f used %.2f of %.2f mismatch points.", job.supportStats.wholeOutfitCohesion or 0, (job.supportStats.lockedCommitment or 0) + (job.supportStats.generatedSpend or 0), job.supportStats.startingBudget or 0)
        if job.supportStats.finalValidationStatus == "REPAIRED" then
            message = message .. string.format(" Final validation repaired %d support outlier%s.", job.supportStats.repairPasses or 0, (job.supportStats.repairPasses or 0) == 1 and "" or "s")
        elseif job.supportStats.finalValidationStatus == "LOCKED_OVERRIDE" then
            message = message .. " Final validation preserved user-locked mismatch."
        elseif job.supportStats.finalValidationStatus == "ALTERNATE_SKELETON" then
            message = message .. " Final validation used the next valid anchor skeleton after support repair was exhausted."
        end
    elseif job.supportFallbackReason then message = message .. " Contextual support used the legacy fallback: " .. tostring(job.supportFallbackReason) .. "." end
    if weaponNotice then message = message .. " " .. weaponNotice end
    if styleEngine then
        message = message .. " Promotional rewards were excluded, and native-set or shared-motif matches were favored."
    end
    return message
end
local function CommitDraft(job, weaponCount, weaponNotice)
    if P.BuildGenerationStateSignature(job.liveState) ~= job.startSignature then
        return FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
    end
    if P.ValidateAnchorPolicyContextAtCommit then
        local valid, reason = P.ValidateAnchorPolicyContextAtCommit(job)
        if not valid then
            job.resultOverride = "CANCELLED"
            return FinishJob(job, false, reason)
        end
    end
    local commitStarted = NowMilliseconds()
    local generatedName = P.RefreshGeneratedOutfitName(job.draft, job.styleEngine, job.styleMode, job.styleContext)
    job.liveState.selections = job.draft.selections
    job.liveState.selectionVisuals = job.draft.selectionVisuals
    job.liveState.lastWeaponRoute = job.draft.lastWeaponRoute
    job.liveState.lastAnchorSkeletonSignature = job.draft.lastAnchorSkeletonSignature
    job.liveState.activeAnchorMask = P.CopySupportProfileValue and P.CopySupportProfileValue(job.activeAnchorMask) or job.activeAnchorMask
    job.liveState.contextualSupportProfile = P.ExportContextualSupportProfile and P.ExportContextualSupportProfile(job.supportStats and job.supportStats.profile) or nil
    job.liveState.generatedName = generatedName
    job.liveState.styleMode = job.styleMode
    job.liveState.selectedConceptID = nil
    if P.TouchPreviewRevision then P.TouchPreviewRevision(job.liveState) end
    RecordPhase(job, "stateCommit", commitStarted)
    return FinishJob(job, true, BuildGenerationMessage(job, generatedName, weaponCount, weaponNotice))
end
local function FinalizeArmorSlot(job, work)
    local chosen
    if job.styleEngine then
        if #work.pool == 0 then
            chosen = work.fallback and work.fallback.source
        else
            local roll = math.random() * work.totalWeight
            for _, entry in ipairs(work.pool) do
                roll = roll - entry.weight
                if roll <= 0 then chosen = entry.source break end
            end
            chosen = chosen or work.pool[#work.pool].source
        end
    elseif #work.pool == 0 then
        chosen = work.fallback
    else
        chosen = work.pool[math.random(1, #work.pool)]
    end
    if chosen then
        P.SetSelectedSource(job.draft, work.slotKey, chosen)
        if not job.draft.hidden[work.slotKey] and job.styleEngine and job.styleEngine.AddSourceToGenerationContext then
            job.styleEngine.AddSourceToGenerationContext(job.styleContext, chosen)
        end
        job.selectedArmor = job.selectedArmor + 1
    elseif not job.reroll then
        P.SetSelectedSource(job.draft, work.slotKey, nil)
    end
end
local function BeginArmorSlot(job, slotKey)
    local definition = P.slotByKey[slotKey]
    if not definition or job.draft.locks[slotKey] then return nil end
    return {
        slotKey = slotKey,
        definition = definition,
        sources = Wardrobe.GetSlotSources(slotKey),
        sourceIndex = 1,
        excludeSourceID = job.reroll and job.draft.selections[slotKey] or nil,
        pool = {},
        totalWeight = 0,
        fallback = nil,
        candidateWork = nil,
    }
end
local function AddCandidateToPool(job, work, source, coherenceScore, coherent, coherenceReason)
    if job.styleEngine and job.styleEngine.ChooseWeightedSource then
        local scoringStarted = NowMilliseconds()
        local weight, score = job.styleEngine.WeightForSource(
            source,
            work.definition,
            job.styleMode,
            job.styleContext,
            coherenceScore,
            coherent,
            coherenceReason
        )
        RecordPhase(job, "scoring", scoringStarted)
        local entry = { source = source, weight = weight, score = score }
        if source.sourceID == work.excludeSourceID then
            work.fallback = entry
        else
            work.totalWeight = work.totalWeight + weight
            table.insert(work.pool, entry)
        end
    elseif source.sourceID == work.excludeSourceID then
        work.fallback = source
    else
        table.insert(work.pool, source)
    end
end
local function ContinueArmorCandidate(job, work)
    local candidate = work.candidateWork
    if not candidate then
        local source = work.sources[work.sourceIndex]
        candidate = { source = source }
        work.candidateWork = candidate
        local validationStarted = NowMilliseconds()
        candidate.valid = Wardrobe.ValidateSource(source, work.slotKey) == true
        RecordPhase(job, "validation", validationStarted)
        if not candidate.valid then return true end
        if not job.styleEngine or not job.styleEngine.ChooseWeightedSource then
            AddCandidateToPool(job, work, source)
            return true
        end
        if job.styleEngine.GetSourcePreEraEligibility then
            local eligibilityStarted = NowMilliseconds()
            local eligible
            if job.styleEngine.GetSourcePreEraEligibilityCached then
                eligible = job.styleEngine.GetSourcePreEraEligibilityCached(source, job.styleContext)
            else
                eligible = job.styleEngine.GetSourcePreEraEligibility(source, job.styleContext)
            end
            RecordPhase(job, "eligibility", eligibilityStarted)
            if not eligible then return true end
            candidate.prechecked = true
        end
        local eraStarted = NowMilliseconds()
        if job.styleEngine.CreateSourceEraEvidenceWork then
            candidate.eraWork = job.styleEngine.CreateSourceEraEvidenceWork(source)
            if candidate.eraWork.done then candidate.eraEvidence = candidate.eraWork.result end
        else
            candidate.eraEvidence = job.styleEngine.GetSourceEraEvidence(source)
        end
        RecordPhase(job, "eraEvidence", eraStarted)
    end
    if candidate.eraWork and not candidate.eraWork.done then
        local eraStarted = NowMilliseconds()
        local done, evidence, processed = job.styleEngine.StepSourceEraEvidenceWork(
            candidate.eraWork,
            P.GENERATION_ERA_CANDIDATES_PER_OPERATION
        )
        job.eraCandidatesProcessed = job.eraCandidatesProcessed + (tonumber(processed) or 0)
        RecordPhase(job, "eraEvidence", eraStarted)
        if not done then return false end
        candidate.eraEvidence = evidence
    end
    local eligibilityStarted = NowMilliseconds()
    local eligible
    if job.styleEngine.GetSourceEligibilityCached then
        eligible = job.styleEngine.GetSourceEligibilityCached(
            candidate.source,
            job.styleMode,
            job.styleContext,
            candidate.eraEvidence,
            candidate.prechecked
        )
    else
        eligible = job.styleEngine.GetSourceEligibility(
            candidate.source,
            job.styleMode,
            job.styleContext,
            candidate.eraEvidence,
            candidate.prechecked
        )
    end
    RecordPhase(job, "eligibility", eligibilityStarted)
    if not eligible then return true end
    local coherenceStarted = NowMilliseconds()
    local coherenceScore, coherent, coherenceReason = job.styleEngine.GetSourceCoherence(candidate.source, job.styleContext)
    RecordPhase(job, "coherence", coherenceStarted)
    if not coherent then return true end
    AddCandidateToPool(job, work, candidate.source, coherenceScore, coherent, coherenceReason)
    return true
end
local function ProcessArmor(job, stepStarted, slice)
    local operations = 0
    local armorOrder = job.armorOrder or P.ARMOR_GENERATION_ORDER
    while job.armorIndex <= #armorOrder do
        if not job.armorWork then
            local setupStarted = NowMilliseconds()
            local slotKey = armorOrder[job.armorIndex]
            job.armorWork = BeginArmorSlot(job, slotKey)
            RecordPhase(job, "slotSetup", setupStarted)
            if WorkerShouldYield(slice, 0.5) then return false end
            if not job.armorWork then job.armorIndex = job.armorIndex + 1 end
        end
        local work = job.armorWork
        if work then
            while work.sourceIndex <= #work.sources do
                local complete = ContinueArmorCandidate(job, work)
                operations = operations + 1
                if complete then
                    work.candidateWork = nil
                    work.sourceIndex = work.sourceIndex + 1
                    job.candidatesProcessed = job.candidatesProcessed + 1
                end
                if operations >= P.GENERATION_OPERATION_SAFETY_CAP then return false end
                if WorkerShouldYield(slice, 0.15) then return false end
            end
            local finalizationStarted = NowMilliseconds()
            FinalizeArmorSlot(job, work)
            RecordPhase(job, "slotFinalization", finalizationStarted)
            if WorkerShouldYield(slice, 0.5) then return false end
            local progressStarted = NowMilliseconds()
            Notify("WARDROBE_GENERATION_PROGRESS", job.armorIndex, #armorOrder, work.slotKey)
            RecordPhase(job, "progressUpdate", progressStarted)
            job.armorWork = nil
            job.armorIndex = job.armorIndex + 1
        end
        if operations >= P.GENERATION_OPERATION_SAFETY_CAP then return false end
        if WorkerShouldYield(slice, 0.15) then return false end
    end
    return true
end

P.ProcessLegacyArmorGeneration, P.CommitSharedGenerationDraft = ProcessArmor, CommitDraft
function P.GetSharedGenerationRuntime()
    return { NowMilliseconds = NowMilliseconds, BeginWorkerSlice = BeginWorkerSlice,
        WorkerShouldYield = WorkerShouldYield, RecordPhase = RecordPhase, ScheduleNextStep = ScheduleNextStep,
        FinishJob = FinishJob, AccumulateSliceDiagnostics = P.AccumulateGenerationSliceDiagnostics,
        CanStartPhase = function(job, reserveMs) return not P.CanStartGenerationPhase or P.CanStartGenerationPhase(job, reserveMs) end }
end
function P.StepGenerationJob(token)
    local job = P.generationJob
    if not job or job.token ~= token then return end
    if job.sharedFrameworkPolicy and QC.Generation and QC.Generation.StepSharedGenerationJob then return QC.Generation.StepSharedGenerationJob(job, job.sharedFrameworkPolicy, job.sharedFrameworkPolicy.runtime) end
    job.steps = job.steps + 1
    local stepStarted = NowMilliseconds()
    local slice = BeginWorkerSlice()
    job.currentSlice = slice
    if job.startSignature and P.BuildGenerationStateSignature(job.liveState) ~= job.startSignature then
        FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
        return
    end
    if job.phase == "SETUP" then
        local ready, reason = P.StepGenerationSetup and P.StepGenerationSetup(job)
        if reason then FinishJob(job, false, reason) return end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
        if not ready and not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule cooperative generation setup. Try /reload.") end
        if ready and not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
        return
    end
    if job.phase == "ANCHORS" then
        local status, reason = P.AdvanceAnchorGenerationPhase(job, stepStarted)
        if status == "FAILED" then
            FinishJob(job, false, reason or job.anchorPolicyFatalError or "Zone anchor policy failed; the previous preview was preserved.")
            return
        end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
        if not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
        return
    end
    if job.phase == "SUPPORT" then
        local status, reason = P.StepSupportGenerationJob(job, stepStarted)
        if status == "READY" then
            job.phase = "COMMIT"
        elseif status == "ALTERNATE" then
            local started = NowMilliseconds()
            local ok, alternateReason = P.ApplyNextAnchorSkeleton and P.ApplyNextAnchorSkeleton(job)
            RecordPhase(job, "supportAlternateSkeleton", started)
            if not ok then
                FinishJob(job, false, alternateReason or reason or "No alternate anchor skeleton could resolve the final support outliers.")
                return
            end
            job.phaseDAlternateNoRepair = true
            job.supportWork = nil
            job.phase = "SUPPORT"
        elseif status == "FAILED" then
            FinishJob(job, false, reason or "Final support validation failed; the preview was left unchanged.")
            return
        elseif status == "FALLBACK" then
            job.supportFallbackReason = reason
            job.phase = "ARMOR"
            job.armorOrder = P.SUPPORTING_ARMOR_GENERATION_ORDER
            job.armorIndex, job.armorWork = 1, nil
        end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
        if not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
        return
    end
    if job.phase == "ARMOR" then
        if ProcessArmor(job, stepStarted, slice) then job.phase = job.weaponsPrepared and "COMMIT" or "WEAPONS" end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end
    if job.phase == "WEAPONS" then
        if not job.weaponWork and P.CreateWeaponGenerationWork then
            job.weaponWork = P.CreateWeaponGenerationWork(job.draft, job.reroll, job.styleMode, job.styleContext)
        end
        local operations = 0
        while operations < P.GENERATION_OPERATION_SAFETY_CAP do
            local weaponStarted = NowMilliseconds()
            local done, ok, countOrMessage, notice
            if job.weaponWork and P.StepWeaponGenerationWork then
                done, ok, countOrMessage, notice = P.StepWeaponGenerationWork(job.weaponWork)
            else
                done = true
                ok, countOrMessage, notice = P.GenerateWeapons(job.draft, job.reroll, job.styleMode, job.styleContext)
            end
            RecordPhase(job, "weaponRouting", weaponStarted)
            operations = operations + 1
            if done then
                if not ok then
                    FinishJob(job, false, countOrMessage)
                    return
                end
                job.weaponCount = countOrMessage
                job.weaponNotice = notice
                job.phase = "COMMIT"
                break
            end
            job.weaponYields = job.weaponYields + 1
            if WorkerShouldYield(slice, 0.15) then break end
        end
        job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
        if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end
    if job.phase == "COMMIT" then
        if P.CanStartGenerationPhase and not P.CanStartGenerationPhase(job, 1.5) then
            job.maxStepMs = math.max(job.maxStepMs, NowMilliseconds() - stepStarted)
            if P.AccumulateGenerationSliceDiagnostics then P.AccumulateGenerationSliceDiagnostics(job) end
            if not ScheduleNextStep(token) then FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.") end
            return
        end
        local performance = CommitDraft(job, job.weaponCount, job.weaponNotice)
        if performance then
            performance.maxStepMs = math.max(tonumber(performance.maxStepMs) or 0, NowMilliseconds() - stepStarted)
        end
    end
end
function Wardrobe.IsGenerating()
    return P.generationJob ~= nil or P.supportRerollJob ~= nil
end
function Wardrobe.GetLastGenerationPerformance() return P.lastGenerationPerformance end
function Wardrobe.CancelGeneration(reason)
    if P.supportRerollJob and P.CancelSupportReroll then return P.CancelSupportReroll(reason) end
    local job = P.generationJob
    if not job then return false end
    P.generationToken = P.generationToken + 1
    FinishJob(job, false, reason or "Outfit generation was cancelled.")
    return true
end
function Wardrobe.StartGenerateOutfit(reroll, requestedStyleMode, sharedPolicy, sharedAction)
    if Wardrobe.IsGenerating() then return false, "Quest Chronicle is already generating an outfit." end
    if Wardrobe.IsScanning() then return false, "Wait for the wardrobe scan to finish before generating an outfit." end
    local cache = P.EnsureCache()
    if cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS" then
        return false, "Scan the wardrobe collection before generating an outfit."
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then
        local diagnosticIdentity = QC.Diagnostics and QC.Diagnostics.BeginGenerationAttempt and QC.Diagnostics.BeginGenerationAttempt(reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT") or nil
        local startedAt = NowMilliseconds()
        local ok, message = Wardrobe.GenerateOutfit(reroll, requestedStyleMode)
        local elapsed = math.max(0, NowMilliseconds() - startedAt)
        local performance = {
            elapsedMs = elapsed, steps = 1, maxStepMs = elapsed, candidates = 0, phaseStats = {},
            cacheDiagnostics = P.BuildGenerationCachePerformance
                and P.BuildGenerationCachePerformance(nil) or nil,
        }
        P.lastGenerationPerformance = performance
        if sharedAction and QC.Generation and QC.Generation.CompleteAction then QC.Generation.CompleteAction(sharedAction, ok == true, message, performance) end
        Notify("WARDROBE_GENERATION_COMPLETE", ok == true, message, performance)
        if QC.Diagnostics and QC.Diagnostics.RecordImmediateAttempt then QC.Diagnostics.RecordImmediateAttempt({ action = reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT", reroll = reroll == true, liveState = P.EnsurePreviewState(), draft = P.EnsurePreviewState(), styleMode = requestedStyleMode, diagnosticIdentity = diagnosticIdentity }, ok == true, message, performance) end
        return ok, message
    end
    local startedAtMs = NowMilliseconds()
    local liveState = P.EnsurePreviewState()
    P.generationToken = P.generationToken + 1
    local job = P.CreateWardrobeGenerationJob({
        token = P.generationToken, reroll = reroll, requestedStyleMode = requestedStyleMode,
        sharedPolicy = sharedPolicy, sharedAction = sharedAction, liveState = liveState, startedAtMs = startedAtMs,
    })
    if P.AttachGenerationModePolicy then P.AttachGenerationModePolicy(job) end
    local policyOK, policyReason = true, nil
    if P.ValidateAttachedAnchorPolicy then policyOK, policyReason = P.ValidateAttachedAnchorPolicy(job) end
    if not policyOK then return false, policyReason end
    P.generationJob = job
    Notify("WARDROBE_GENERATION_STARTED", job.reroll, requestedStyleMode)
    if not ScheduleNextStep(job.token) then
        P.generationJob = nil
        return false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload."
    end
    return true, job.reroll and "Rerolling unlocked outfit pieces..." or "Generating outfit..."
end
