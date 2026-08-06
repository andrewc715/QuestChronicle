local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers

local PHASE_RESERVE = {
    IDENTITY = 0.5, STATE = 0.75, CONTEXT = 1.5, SEED = 0.5,
    ELIGIBILITY = 1.5, NOVELTY = 1.0, CACHE = 0.5, WEAPON_INDEX = 0.5, READY = 0.25,
}

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function Record(job, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if Workers and Workers.NoteCall and job.currentSlice then Workers.NoteCall(job.currentSlice, elapsed) end
    return elapsed
end

local function CopySetupPrimitiveMap(values)
    local copy = {}
    for key, value in pairs(values or {}) do copy[key] = value end
    return copy
end

function P.CopyGenerationDraftState(state)
    local draft = {}
    for key, value in pairs(state or {}) do if type(value) ~= "table" then draft[key] = value end end
    draft.selections = CopySetupPrimitiveMap(state and state.selections)
    draft.selectionVisuals = CopySetupPrimitiveMap(state and state.selectionVisuals)
    draft.locks = CopySetupPrimitiveMap(state and state.locks)
    draft.hidden = CopySetupPrimitiveMap(state and state.hidden)
    draft.weaponFamilies = CopySetupPrimitiveMap(state and state.weaponFamilies)
    draft.weaponSubtypes = CopySetupPrimitiveMap(state and state.weaponSubtypes)
    draft.lastWeaponRoute = state and state.lastWeaponRoute
    return draft
end

local function AppendMapSignature(parts, label, values)
    local keys = {}
    for key in pairs(values or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    parts[#parts + 1] = label
    for _, key in ipairs(keys) do
        local value = values[key]
        if value == nil then value = values[tonumber(key)] end
        parts[#parts + 1] = key .. "=" .. tostring(value)
    end
end

function P.BuildGenerationStateSignature(state)
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

local function ShouldYield(job, reserveMs)
    return Workers and Workers.ShouldYield and Workers.ShouldYield(job.currentSlice, reserveMs or 0.25)
end

local function StartContext(job)
    local started = NowMilliseconds()
    local style = QC.ZoneStyle
    job.styleEngine = style
    job.styleMode = job.requestedStyleMode or job.draft.styleMode
    if style then
        job.styleMode = style.NormalizeMode(job.styleMode)
        job.draft.styleMode = job.styleMode
        local base = style.GetCurrentContext and style.GetCurrentContext() or nil
        job.styleContext = style.CreateGenerationContext and style.CreateGenerationContext(base) or base
    end
    if P.AttachGenerationModePolicy then P.AttachGenerationModePolicy(job) end
    if P.CaptureAnchorPolicyContext then P.CaptureAnchorPolicyContext(job) end
    job.setupSeedIndex = 1
    Record(job, "generationModeContext", started)
end

local function SeedContext(job)
    local definitions = Wardrobe.slotDefinitions or {}
    local definition = definitions[job.setupSeedIndex]
    if not definition then return true end
    local started = NowMilliseconds()
    local slotKey = definition.key
    local shouldSeed = job.draft.locks[slotKey] == true
        and job.draft.hidden[slotKey] ~= true and job.draft.selections[slotKey] ~= nil
    if shouldSeed and job.styleEngine and job.styleEngine.AddSourceToGenerationContext then
        job.styleEngine.AddSourceToGenerationContext(job.styleContext, P.GetSourceByID(slotKey, job.draft.selections[slotKey]))
    end
    job.setupSeedIndex = job.setupSeedIndex + 1
    Record(job, "generationContextSeed", started)
    return job.setupSeedIndex > #definitions
end

function P.StepGenerationSetup(job)
    local operations = 0
    while operations < 32 do
        if ShouldYield(job, 0.5) then return false end
        if Workers and Workers.CanStartPhase
            and not Workers.CanStartPhase(job.currentSlice, PHASE_RESERVE[job.setupPhase] or 0.5)
        then return false end
        if job.setupPhase == "IDENTITY" then
            local started = NowMilliseconds()
            job.diagnosticIdentity = QC.Diagnostics and QC.Diagnostics.BeginGenerationAttempt
                and QC.Diagnostics.BeginGenerationAttempt(job.action) or nil
            Record(job, "generationActionIdentity", started)
            job.setupPhase = "STATE"
        elseif job.setupPhase == "STATE" then
            local started = NowMilliseconds()
            job.draft = P.CopyGenerationDraftState(job.liveState)
            job.startSignature = P.BuildGenerationStateSignature(job.liveState)
            Record(job, "generationStateSnapshot", started)
            job.setupPhase = "CONTEXT"
        elseif job.setupPhase == "CONTEXT" then
            StartContext(job)
            job.setupPhase = "SEED"
        elseif job.setupPhase == "SEED" then
            if SeedContext(job) then job.setupPhase = "ELIGIBILITY" end
        elseif job.setupPhase == "ELIGIBILITY" then
            local started = NowMilliseconds()
            if job.styleEngine and job.styleEngine.PrepareGenerationEligibilityContext then
                job.styleEngine.PrepareGenerationEligibilityContext(job.styleContext)
            end
            Record(job, "generationEligibilityContext", started)
            job.setupPhase = "NOVELTY"
        elseif job.setupPhase == "NOVELTY" then
            local started = NowMilliseconds()
            job.currentAnchorNovelty = P.BuildAnchorNoveltyReferenceForJob
                and P.BuildAnchorNoveltyReferenceForJob(job, job.liveState)
                or (P.BuildAnchorNoveltyContext and P.BuildAnchorNoveltyContext(job.liveState) or nil)
            Record(job, "generationNoveltyReference", started)
            job.setupPhase = "CACHE"
        elseif job.setupPhase == "CACHE" then
            local started = NowMilliseconds()
            job.cacheCountersStarted = P.GetGenerationCacheCounterSnapshot and P.GetGenerationCacheCounterSnapshot() or nil
            Record(job, "generationCacheScalarSnapshot", started)
            job.setupPhase = "WEAPON_INDEX"
        elseif job.setupPhase == "WEAPON_INDEX" then
            local started = NowMilliseconds()
            job.weaponIndexActionStarted = P.BeginWeaponIndexActionSnapshot and P.BeginWeaponIndexActionSnapshot() or nil
            Record(job, "generationWeaponIndexSnapshot", started)
            job.setupPhase = "READY"
        elseif job.setupPhase == "READY" then
            job.phase = P.AdvanceAnchorGenerationPhase and "ANCHORS" or "ARMOR"
            job.armorIndex, job.armorOrder, job.armorWork = 1, nil, nil
            return true
        else
            return false, "Unknown generation setup phase"
        end
        operations = operations + 1
        if Workers and Workers.ShouldYield and Workers.ShouldYield(job.currentSlice, 0.5) then return false end
    end
    return false
end
