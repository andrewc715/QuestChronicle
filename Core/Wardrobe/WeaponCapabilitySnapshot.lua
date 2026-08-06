local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local BuildCapabilities = Wardrobe.GetWeaponAppearanceCapabilities
P.BuildWeaponAppearanceCapabilities = P.BuildWeaponAppearanceCapabilities or BuildCapabilities
P.weaponCapabilityGeneration = tonumber(P.weaponCapabilityGeneration) or 1
P.weaponCapabilitySnapshot = P.weaponCapabilitySnapshot or nil
P.weaponCapabilitySnapshotInvalidationReason = P.weaponCapabilitySnapshotInvalidationReason or "LOGIN_SESSION_RESET"
P.weaponCapabilitySnapshotBuildCount = tonumber(P.weaponCapabilitySnapshotBuildCount) or 0
P.weaponCapabilitySnapshotReuseCount = tonumber(P.weaponCapabilitySnapshotReuseCount) or 0

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

local function Record(job, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    if job and P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if job and P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
    return elapsed
end

function P.InvalidateWeaponCapabilitySnapshot(reason)
    P.weaponCapabilitySnapshot = nil
    P.weaponCapabilityGeneration = (tonumber(P.weaponCapabilityGeneration) or 0) + 1
    P.weaponCapabilitySnapshotInvalidationReason = reason or "UNKNOWN"
end

function Wardrobe.GetWeaponAppearanceCapabilities(forceRefresh)
    if forceRefresh == true then P.weaponCapabilitySnapshot = nil end
    if P.weaponCapabilitySnapshot then
        P.weaponCapabilitySnapshotReuseCount = P.weaponCapabilitySnapshotReuseCount + 1
        return P.weaponCapabilitySnapshot, "REUSED", P.weaponCapabilityGeneration
    end
    local capabilities = P.BuildWeaponAppearanceCapabilities()
    if type(capabilities) == "table" then
        capabilities.__qcCapabilityGeneration = P.weaponCapabilityGeneration
        P.weaponCapabilitySnapshot = capabilities
        P.weaponCapabilitySnapshotBuildCount = P.weaponCapabilitySnapshotBuildCount + 1
    end
    return capabilities, "BUILT", P.weaponCapabilityGeneration
end

function P.GetWeaponCapabilitySnapshotForJob(job)
    if job and job.weaponCapabilitySnapshot then
        job.weaponCapabilityReusesThisAction = (tonumber(job.weaponCapabilityReusesThisAction) or 0) + 1
        return job.weaponCapabilitySnapshot, "REUSED", job.weaponCapabilityGeneration
    end
    local capabilities, status, generation = Wardrobe.GetWeaponAppearanceCapabilities()
    if job then
        job.weaponCapabilitySnapshot = capabilities
        job.weaponCapabilityGeneration = generation
        job.weaponCapabilitySnapshotStatus = status
        job.weaponCapabilityInvalidationReason = P.weaponCapabilitySnapshotInvalidationReason
        job.weaponCapabilityBuildsThisAction = (tonumber(job.weaponCapabilityBuildsThisAction) or 0) + (status == "BUILT" and 1 or 0)
        job.weaponCapabilityReusesThisAction = (tonumber(job.weaponCapabilityReusesThisAction) or 0) + (status == "REUSED" and 1 or 0)
        job.weaponCapabilityStaleAtCommit = false
    end
    return capabilities, status, generation
end

function P.ValidateWeaponCapabilitySnapshotAtCommit(job)
    if not job or not job.weaponCapabilityGeneration then return true end
    local current = tonumber(P.weaponCapabilityGeneration) or 0
    local captured = tonumber(job.weaponCapabilityGeneration) or 0
    if current ~= captured then
        job.weaponCapabilityStaleAtCommit = true
        job.weaponCapabilityCurrentGeneration = current
        job.weaponCapabilityInvalidationReason = P.weaponCapabilitySnapshotInvalidationReason
        return false, "Weapon equipment or specialization changed while Quest Chronicle was preparing the outfit; the previous preview was preserved."
    end
    job.weaponCapabilityStaleAtCommit = false
    job.weaponCapabilityCurrentGeneration = current
    return true
end

function P.CreateWeaponGenerationContext(job)
    local snapshotStarted = NowMilliseconds()
    local capabilities, status, generation = P.GetWeaponCapabilitySnapshotForJob(job)
    Record(job, status == "BUILT" and "weaponCapabilitiesBuild" or "weaponCapabilitiesReuse", snapshotStarted)
    if P.MaybeYieldWeaponGeneration then
        P.MaybeYieldWeaponGeneration(status == "BUILT" and "weaponCapabilitiesBuild" or "weaponCapabilitiesReuse")
    end

    local mutableStarted = NowMilliseconds()
    local context = {
        mainItem = capabilities.topology.mainItem,
        offItem = capabilities.topology.offItem,
        appearancesByCategory = {},
        locationsBySlot = {},
        validation = {},
        topology = capabilities.topology,
        capabilities = capabilities,
        capabilityGeneration = generation,
        capabilitySnapshotStatus = status,
    }
    Record(job, "weaponContextMutableState", mutableStarted)
    if P.MaybeYieldWeaponGeneration then P.MaybeYieldWeaponGeneration("weaponContextMutableState") end
    return context
end
