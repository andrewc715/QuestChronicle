local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.GENERATION_CANDIDATE_BATCH = 30
P.GENERATION_TIME_BUDGET_MS = 2.5
P.generationToken = P.generationToken or 0
P.generationJob = nil
P.lastGenerationPerformance = nil

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end
    if type(GetTime) == "function" then
        return GetTime() * 1000
    end
    return 0
end

local function CopyDraftState(state)
    local draft = {}
    for key, value in pairs(state or {}) do
        if type(value) ~= "table" then draft[key] = value end
    end
    draft.selections = P.CopyPrimitiveMap(state and state.selections)
    draft.selectionVisuals = P.CopyPrimitiveMap(state and state.selectionVisuals)
    draft.locks = P.CopyPrimitiveMap(state and state.locks)
    draft.hidden = P.CopyPrimitiveMap(state and state.hidden)
    draft.weaponFamilies = P.CopyPrimitiveMap(state and state.weaponFamilies)
    draft.weaponSubtypes = P.CopyPrimitiveMap(state and state.weaponSubtypes)
    draft.lastWeaponRoute = state and state.lastWeaponRoute
    return draft
end

local function AppendMapSignature(parts, label, values)
    local keys = {}
    for key in pairs(values or {}) do table.insert(keys, tostring(key)) end
    table.sort(keys)
    table.insert(parts, label)
    for _, key in ipairs(keys) do
        local value = values[key]
        if value == nil then value = values[tonumber(key)] end
        table.insert(parts, key .. "=" .. tostring(value))
    end
end

local function GenerationStateSignature(state)
    local parts = {
        "link=" .. tostring(state and state.linkWeaponHands ~= false),
        "mode=" .. tostring(state and state.styleMode or ""),
    }
    AppendMapSignature(parts, "selections", state and state.selections)
    AppendMapSignature(parts, "locks", state and state.locks)
    AppendMapSignature(parts, "hidden", state and state.hidden)
    AppendMapSignature(parts, "families", state and state.weaponFamilies)
    AppendMapSignature(parts, "subtypes", state and state.weaponSubtypes)
    return table.concat(parts, "|")
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
    local finishedAt = NowMilliseconds()
    local performance = {
        elapsedMs = math.max(0, finishedAt - job.startedAtMs),
        steps = job.steps or 0,
        maxStepMs = math.max(job.maxStepMs or 0, job.weaponMs or 0, job.commitMs or 0),
        weaponMs = job.weaponMs or 0,
        commitMs = job.commitMs or 0,
        candidates = job.candidatesProcessed or 0,
        selectedArmor = job.selectedArmor or 0,
    }
    P.lastGenerationPerformance = performance
    P.generationJob = nil
    Notify("WARDROBE_GENERATION_COMPLETE", success == true, message, performance)
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
    if weaponNotice then message = message .. " " .. weaponNotice end
    if styleEngine then
        message = message .. " Promotional rewards were excluded, and native-set or shared-motif matches were favored."
    end
    return message
end

local function CommitDraft(job, weaponCount, weaponNotice)
    if GenerationStateSignature(job.liveState) ~= job.startSignature then
        FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
        return
    end

    local commitStarted = NowMilliseconds()
    local generatedName = P.RefreshGeneratedOutfitName(job.draft, job.styleEngine, job.styleMode, job.styleContext)
    job.liveState.selections = job.draft.selections
    job.liveState.selectionVisuals = job.draft.selectionVisuals
    job.liveState.lastWeaponRoute = job.draft.lastWeaponRoute
    job.liveState.generatedName = generatedName
    job.liveState.styleMode = job.styleMode
    job.liveState.selectedConceptID = nil
    job.commitMs = NowMilliseconds() - commitStarted
    job.maxStepMs = math.max(job.maxStepMs or 0, job.commitMs)
    FinishJob(job, true, BuildGenerationMessage(job, generatedName, weaponCount, weaponNotice))
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
    else
        if #work.pool == 0 then
            chosen = work.fallback
        else
            chosen = work.pool[math.random(1, #work.pool)]
        end
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
    }
end

local function EvaluateArmorCandidate(job, work, source)
    local valid = Wardrobe.ValidateSource(source, work.slotKey)
    if not valid then return end

    if job.styleEngine and job.styleEngine.ChooseWeightedSource then
        local eligible = job.styleEngine.GetSourceEligibility(source, job.styleMode, job.styleContext)
        local _, coherent = job.styleEngine.GetSourceCoherence(source, job.styleContext)
        if not eligible or not coherent then return end
        local weight, score = job.styleEngine.WeightForSource(source, work.definition, job.styleMode, job.styleContext)
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

local function ProcessArmor(job, stepStarted)
    while job.armorIndex <= #P.ARMOR_GENERATION_ORDER do
        if not job.armorWork then
            local slotKey = P.ARMOR_GENERATION_ORDER[job.armorIndex]
            job.armorWork = BeginArmorSlot(job, slotKey)
            if not job.armorWork then job.armorIndex = job.armorIndex + 1 end
        end

        local work = job.armorWork
        if work then
            local processed = 0
            while work.sourceIndex <= #work.sources do
                EvaluateArmorCandidate(job, work, work.sources[work.sourceIndex])
                work.sourceIndex = work.sourceIndex + 1
                processed = processed + 1
                job.candidatesProcessed = job.candidatesProcessed + 1
                if processed >= P.GENERATION_CANDIDATE_BATCH then break end
                if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then break end
            end
            if work.sourceIndex > #work.sources then
                FinalizeArmorSlot(job, work)
                Notify("WARDROBE_GENERATION_PROGRESS", job.armorIndex, #P.ARMOR_GENERATION_ORDER, work.slotKey)
                job.armorWork = nil
                job.armorIndex = job.armorIndex + 1
            end
        end

        if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then return false end
    end
    return true
end

function P.StepGenerationJob(token)
    local job = P.generationJob
    if not job or job.token ~= token then return end
    job.steps = job.steps + 1
    local stepStarted = NowMilliseconds()

    if GenerationStateSignature(job.liveState) ~= job.startSignature then
        FinishJob(job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
        return
    end

    if job.phase == "ARMOR" then
        if ProcessArmor(job, stepStarted) then job.phase = "WEAPONS" end
        local stepMs = NowMilliseconds() - stepStarted
        job.maxStepMs = math.max(job.maxStepMs, stepMs)
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end

    if job.phase == "WEAPONS" then
        local weaponStarted = NowMilliseconds()
        local ok, countOrMessage, notice = P.GenerateWeapons(job.draft, job.reroll, job.styleMode, job.styleContext)
        job.weaponMs = NowMilliseconds() - weaponStarted
        job.maxStepMs = math.max(job.maxStepMs, job.weaponMs)
        if not ok then
            FinishJob(job, false, countOrMessage)
            return
        end
        job.weaponCount = countOrMessage
        job.weaponNotice = notice
        job.phase = "COMMIT"
        if not ScheduleNextStep(token) then
            FinishJob(job, false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        end
        return
    end

    if job.phase == "COMMIT" then
        CommitDraft(job, job.weaponCount, job.weaponNotice)
        return
    end
end

function Wardrobe.IsGenerating()
    return P.generationJob ~= nil
end

function Wardrobe.GetLastGenerationPerformance()
    return P.lastGenerationPerformance
end

function Wardrobe.CancelGeneration(reason)
    local job = P.generationJob
    if not job then return false end
    P.generationToken = P.generationToken + 1
    FinishJob(job, false, reason or "Outfit generation was cancelled.")
    return true
end

function Wardrobe.StartGenerateOutfit(reroll, requestedStyleMode)
    if Wardrobe.IsGenerating() then return false, "Quest Chronicle is already generating an outfit." end
    if Wardrobe.IsScanning() then return false, "Wait for the wardrobe scan to finish before generating an outfit." end

    local cache = P.EnsureCache()
    if cache.scanState ~= "COMPLETE" and cache.scanState ~= "COMPLETE_WITH_WARNINGS" then
        return false, "Scan the wardrobe collection before generating an outfit."
    end

    if not C_Timer or type(C_Timer.After) ~= "function" then
        local startedAt = NowMilliseconds()
        local ok, message = Wardrobe.GenerateOutfit(reroll, requestedStyleMode)
        local elapsed = math.max(0, NowMilliseconds() - startedAt)
        local performance = { elapsedMs = elapsed, steps = 1, maxStepMs = elapsed, weaponMs = 0, commitMs = 0, candidates = 0 }
        P.lastGenerationPerformance = performance
        Notify("WARDROBE_GENERATION_COMPLETE", ok == true, message, performance)
        return ok, message
    end

    local liveState = P.EnsurePreviewState()
    local draft = CopyDraftState(liveState)
    local styleEngine = QC.ZoneStyle
    local styleMode = requestedStyleMode or draft.styleMode
    local styleContext
    if styleEngine then
        styleMode = styleEngine.NormalizeMode(styleMode)
        draft.styleMode = styleMode
        styleContext = P.CreateStyleGenerationContext(draft, styleEngine, styleEngine.GetCurrentContext(), nil, true)
    end

    P.generationToken = P.generationToken + 1
    local job = {
        token = P.generationToken,
        reroll = reroll == true,
        liveState = liveState,
        draft = draft,
        styleEngine = styleEngine,
        styleMode = styleMode,
        styleContext = styleContext,
        startSignature = GenerationStateSignature(liveState),
        phase = "ARMOR",
        armorIndex = 1,
        armorWork = nil,
        selectedArmor = 0,
        candidatesProcessed = 0,
        steps = 0,
        maxStepMs = 0,
        startedAtMs = NowMilliseconds(),
    }
    P.generationJob = job
    Notify("WARDROBE_GENERATION_STARTED", job.reroll, styleMode)
    if not ScheduleNextStep(job.token) then
        P.generationJob = nil
        return false, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload."
    end
    return true, job.reroll and "Rerolling unlocked outfit pieces..." or "Generating outfit..."
end
