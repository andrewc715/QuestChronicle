local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local T = QC.ZoneStyle and QC.ZoneStyle.Traveler

P.SUPPORT_FINAL_MISMATCH_BUDGET = 2.00
P.SUPPORT_FINAL_SEVERITY_THRESHOLD = 0.72
P.SUPPORT_FINAL_PALETTE_LIMIT = 3
P.SUPPORT_FINAL_REPAIR_LIMIT = 2

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function Round(value, places)
    local scale = 10 ^ (places or 0)
    return math.floor((tonumber(value) or 0) * scale + 0.5) / scale
end

local function CopyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function DecisionMap(configuration)
    local result = {}
    for _, decision in ipairs(configuration and configuration.decisions or {}) do
        if decision and decision.slotKey then result[decision.slotKey] = decision end
    end
    return result
end

local function VisualIdentity(source)
    if P.SupportVisualIdentity then return P.SupportVisualIdentity(source) end
    return tostring(source and (source.visualID or source.sourceID or source.itemID) or "")
end

local function SlotIndex(slotKey)
    for index, key in ipairs(P.SUPPORT_SLOT_ORDER or {}) do if key == slotKey then return index end end
    return 999
end

local function AddAnchorEntries(entries, profile)
    for _, anchor in ipairs(profile and profile.entries or {}) do
        if anchor.source and anchor.descriptor then
            entries[#entries + 1] = {
                slotKey = anchor.slotKey, slotLabel = anchor.label or anchor.slotKey,
                source = anchor.source, descriptor = anchor.descriptor,
                slotProminence = T and T.SLOT_VISIBILITY_WEIGHTS and T.SLOT_VISIBILITY_WEIGHTS[anchor.slotKey] or 0.40,
                isAnchor = true, repairable = false, locked = false,
            }
        end
    end
end

local function AddSupportEntries(entries, job, work, configuration, decisions)
    local state = job and job.draft or {}
    for _, slotKey in ipairs(work and work.activeSlots or {}) do
        if not (state.hidden and state.hidden[slotKey]) then
            local candidate = configuration and configuration.selected and configuration.selected[slotKey]
            local decision = decisions[slotKey]
            if candidate and candidate.source and candidate.descriptor then
                entries[#entries + 1] = {
                    slotKey = slotKey,
                    slotLabel = P.slotByKey[slotKey] and P.slotByKey[slotKey].label or slotKey,
                    source = candidate.source, descriptor = candidate.descriptor,
                    slotProminence = candidate.prominence or (T and T.SLOT_VISIBILITY_WEIGHTS and T.SLOT_VISIBILITY_WEIGHTS[slotKey]) or 0.40,
                    isAnchor = false, repairable = not (state.locks and state.locks[slotKey]),
                    locked = state.locks and state.locks[slotKey] == true or false,
                    decision = decision, phaseCOutlierState = decision and decision.outlierState or candidate.outlierState,
                }
            end
        end
    end
end

local function Signature(configuration, activeSlots)
    local parts = {}
    for _, slotKey in ipairs(activeSlots or {}) do
        local candidate = configuration and configuration.selected and configuration.selected[slotKey]
        parts[#parts + 1] = slotKey .. "=" .. VisualIdentity(candidate and candidate.source)
    end
    return table.concat(parts, "|")
end

local function AnalyzeSupportEntry(entry, allEntries, profileDescriptor)
    local profileScore, components = T.GetTravelerProfileCohesion(entry.descriptor, profileDescriptor)
    local echoSupport = T.GetTravelerEchoSupport(entry, allEntries)
    local mismatchClass, mismatchPoints, mismatchReason, bridgeSupport, bridgeType =
        T.ClassifyTravelerMismatch(entry, profileScore, components, echoSupport)
    local severity, severityParts = T.GetTravelerOutlierSeverity(entry, profileScore, components, echoSupport, bridgeSupport)
    local threshold = T.CONFIG and T.CONFIG.thresholds or {}
    local visualImpact = tonumber(entry.visualImpact) or 0
    local zeroEcho = visualImpact >= (tonumber(threshold.loudImpact) or 0.55) and echoSupport <= 0.0005 and mismatchClass ~= "COHESIVE"
    local explicitOutlier = mismatchClass == "POSTAL" or entry.phaseCOutlierState == "OUTLIER"
    entry.profileCohesion = profileScore
    entry.cohesionComponents = components
    entry.echoSupport = echoSupport
    entry.bridgeSupport = bridgeSupport
    entry.bridgeType = bridgeType
    entry.mismatchClass = mismatchClass
    entry.mismatchPoints = mismatchPoints
    entry.mismatchReason = mismatchReason
    entry.outlierSeverity = severity
    entry.severityParts = severityParts
    entry.zeroEchoLoudAccent = zeroEcho
    entry.explicitOutlier = explicitOutlier
    entry.severe = severity > P.SUPPORT_FINAL_SEVERITY_THRESHOLD
    entry.dominantPalette = T.GetTravelerDominantPalette(entry.descriptor)
    return entry
end

local function CountPaletteFamilies(entries)
    local counts = {}
    for _, entry in ipairs(entries or {}) do
        local family = entry.dominantPalette or T.GetTravelerDominantPalette(entry.descriptor)
        entry.dominantPalette = family
        if family then counts[family] = (counts[family] or 0) + 1 end
    end
    local total = 0
    for _ in pairs(counts) do total = total + 1 end
    return total, counts
end

local function Objective(validation, configuration)
    return {
        validation.internalValid and 0 or 1,
        validation.repairableOutliers or 0,
        validation.repairableZeroEcho or 0,
        validation.repairableSevere or 0,
        validation.paletteOverflow or 0,
        validation.mismatchOverflow or 0,
        validation.weightedSeverity or 0,
        tonumber(configuration and configuration.fallbackCount) or 0,
        tonumber(configuration and configuration.emptySlots) or 0,
        -(tonumber(validation.wholeOutfitCohesion) or 0),
        -(tonumber(configuration and configuration.totalScore) or 0),
    }
end

function P.CompareSupportValidation(left, right)
    if not left then return 1 end
    if not right then return -1 end
    local leftObjective, rightObjective = left.objective or {}, right.objective or {}
    local count = math.max(#leftObjective, #rightObjective)
    for index = 1, count do
        local leftValue = tonumber(leftObjective[index]) or 0
        local rightValue = tonumber(rightObjective[index]) or 0
        if math.abs(leftValue - rightValue) > 0.000001 then return leftValue < rightValue and -1 or 1 end
    end
    local leftSignature = tostring(left.signature or "")
    local rightSignature = tostring(right.signature or "")
    if leftSignature == rightSignature then return 0 end
    return leftSignature < rightSignature and -1 or 1
end

function P.IsSupportValidationImprovement(candidate, current)
    return P.CompareSupportValidation(candidate, current) < 0
end

function P.ValidateSupportConfiguration(job, work, configuration)
    local profile = work and work.profile
    if not profile or not profile.descriptor then
        return {
            status = "FAILED", internalValid = false, failureReason = "The contextual support profile is unavailable.",
            objective = { 1 }, signature = Signature(configuration, work and work.activeSlots),
        }
    end
    local decisions = DecisionMap(configuration)
    local entries = {}
    AddAnchorEntries(entries, profile)
    AddSupportEntries(entries, job, work, configuration, decisions)
    local supportEntries = {}
    local mismatchUsed, repairableOutliers, protectedOutliers = 0, 0, 0
    local repairableZeroEcho, protectedZeroEcho = 0, 0
    local repairableSevere, protectedSevere = 0, 0
    local weightedSeverity, maximumSeverity, cohesionTotal, cohesionCount = 0, 0, 0, 0
    local unlockedCount = 0
    for _, entry in ipairs(entries) do
        entry.dominantPalette = T.GetTravelerDominantPalette(entry.descriptor)
        if not entry.isAnchor then
            AnalyzeSupportEntry(entry, entries, profile.descriptor)
            supportEntries[#supportEntries + 1] = entry
            if entry.mismatchClass ~= "POSTAL" then mismatchUsed = mismatchUsed + (tonumber(entry.mismatchPoints) or 0) end
            weightedSeverity = weightedSeverity + (tonumber(entry.outlierSeverity) or 0) * (tonumber(entry.slotProminence) or 0.40)
            maximumSeverity = math.max(maximumSeverity, tonumber(entry.outlierSeverity) or 0)
            cohesionTotal = cohesionTotal + (tonumber(entry.profileCohesion) or 0)
            cohesionCount = cohesionCount + 1
            if entry.repairable then unlockedCount = unlockedCount + 1 end
            if entry.explicitOutlier then
                if entry.repairable then repairableOutliers = repairableOutliers + 1 else protectedOutliers = protectedOutliers + 1 end
            end
            if entry.zeroEchoLoudAccent then
                if entry.repairable then repairableZeroEcho = repairableZeroEcho + 1 else protectedZeroEcho = protectedZeroEcho + 1 end
            end
            if entry.severe then
                if entry.repairable then repairableSevere = repairableSevere + 1 else protectedSevere = protectedSevere + 1 end
            end
        end
    end
    local paletteFamilies, paletteCounts = CountPaletteFamilies(entries)
    local mismatchOverflow = math.max(0, mismatchUsed - P.SUPPORT_FINAL_MISMATCH_BUDGET)
    local paletteOverflow = math.max(0, paletteFamilies - P.SUPPORT_FINAL_PALETTE_LIMIT)
    local globalRepairable = unlockedCount > 0 and (mismatchOverflow > 0.0005 or paletteOverflow > 0)
    local repairableFailure = repairableOutliers > 0 or repairableZeroEcho > 0 or repairableSevere > 0 or globalRepairable
    local protectedFailure = protectedOutliers > 0 or protectedZeroEcho > 0 or protectedSevere > 0
        or (not globalRepairable and (mismatchOverflow > 0.0005 or paletteOverflow > 0))
    local status
    if repairableFailure then status = "REPAIR_REQUIRED"
    elseif protectedFailure then status = "LOCKED_OVERRIDE"
    else status = "CLEAN" end
    local validation = {
        status = status, internalValid = true, entries = entries, supportEntries = supportEntries,
        analysisBySlot = {}, mismatchBudget = P.SUPPORT_FINAL_MISMATCH_BUDGET,
        mismatchUsed = Round(mismatchUsed, 2), mismatchOverflow = Round(mismatchOverflow, 2),
        severityThreshold = P.SUPPORT_FINAL_SEVERITY_THRESHOLD,
        paletteLimit = P.SUPPORT_FINAL_PALETTE_LIMIT, paletteFamilies = paletteFamilies,
        paletteCounts = paletteCounts, paletteOverflow = paletteOverflow,
        repairableOutliers = repairableOutliers, protectedOutliers = protectedOutliers,
        repairableZeroEcho = repairableZeroEcho, protectedZeroEcho = protectedZeroEcho,
        repairableSevere = repairableSevere, protectedSevere = protectedSevere,
        protectedLockedViolations = protectedOutliers + protectedZeroEcho + protectedSevere,
        weightedSeverity = Round(weightedSeverity, 4), maximumSeverity = Round(maximumSeverity, 4),
        wholeOutfitCohesion = cohesionCount > 0 and cohesionTotal / cohesionCount or profile.meanAnchorCohesion,
        signature = Signature(configuration, work and work.activeSlots),
    }
    for _, entry in ipairs(supportEntries) do validation.analysisBySlot[entry.slotKey] = entry end
    validation.objective = Objective(validation, configuration)
    return validation
end

function P.SelectSupportRepairTarget(validation, exhaustedSlots)
    local candidates = {}
    for _, entry in ipairs(validation and validation.supportEntries or {}) do
        if entry.repairable and not (exhaustedSlots and exhaustedSlots[entry.slotKey]) then
            local uniquePalette = validation.paletteOverflow > 0 and entry.dominantPalette
                and (validation.paletteCounts[entry.dominantPalette] or 0) == 1 and 1 or 0
            candidates[#candidates + 1] = {
                entry = entry,
                explicit = entry.explicitOutlier and 1 or 0,
                severity = tonumber(entry.outlierSeverity) or 0,
                zeroEcho = entry.zeroEchoLoudAccent and 1 or 0,
                uniquePalette = uniquePalette,
                impact = tonumber(entry.visualImpact) or 0,
                mismatch = tonumber(entry.mismatchPoints) or 0,
                prominence = tonumber(entry.slotProminence) or 0,
                order = SlotIndex(entry.slotKey),
            }
        end
    end
    table.sort(candidates, function(left, right)
        for _, key in ipairs({ "explicit", "severity", "zeroEcho", "uniquePalette", "impact", "mismatch", "prominence" }) do
            if math.abs((left[key] or 0) - (right[key] or 0)) > 0.000001 then return (left[key] or 0) > (right[key] or 0) end
        end
        return left.order < right.order
    end)
    return candidates[1] and candidates[1].entry or nil
end

function P.AttachSupportFinalAnalysis(configuration, validation, repairs)
    local bySlot = validation and validation.analysisBySlot or {}
    local repairBySlot = {}
    for _, repair in ipairs(repairs or {}) do repairBySlot[repair.slotKey] = repair end
    for _, decision in ipairs(configuration and configuration.decisions or {}) do
        local analysis = bySlot[decision.slotKey]
        if analysis then
            decision.finalMismatchClass = analysis.mismatchClass
            decision.echoSupport = analysis.echoSupport
            decision.outlierSeverity = analysis.outlierSeverity
            decision.protectedByLock = analysis.locked == true
        end
        local repair = repairBySlot[decision.slotKey]
        if repair then
            decision.repaired = true
            decision.repairPass = repair.pass
            decision.replacedVisualID = repair.previousVisualID
        end
    end
end

function P.CopySupportCandidateMap(source)
    return CopyMap(source)
end
