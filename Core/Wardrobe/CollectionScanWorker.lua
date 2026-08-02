local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function NewDiagnostics()
    return {
        expectedCollected = 0,
        returnedAppearances = 0,
        collectedAppearances = 0,
        returnedSources = 0,
        compatibleVisuals = 0,
        excludedVisuals = 0,
        categories = {},
    }
end

local function FinishResults(worker)
    local results = {}
    for _, source in pairs(worker.visuals) do
        table.insert(results, source)
    end
    table.sort(results, function(left, right)
        local leftName = string.lower(left.name or "")
        local rightName = string.lower(right.name or "")
        if leftName == rightName then
            return (left.sourceID or 0) < (right.sourceID or 0)
        end
        return leftName < rightName
    end)
    worker.diagnostics.compatibleVisuals = #results
    return results, worker.diagnostics
end

local function BeginCategory(worker)
    local categoryID = worker.categoryIDs[worker.categoryIndex]
    if not categoryID then return false end

    local expected = tonumber(P.SafeCall(C_TransmogCollection.GetCategoryCollectedCount, categoryID)) or 0
    local appearances, retrievalMode = P.GetCategoryAppearancesRobust(categoryID, worker.transmogLocation)
    worker.currentCategory = {
        categoryID = categoryID,
        expectedCollected = expected,
        returnedAppearances = #appearances,
        collectedAppearances = 0,
        returnedSources = 0,
        compatibleVisuals = 0,
        retrievalMode = retrievalMode,
    }
    worker.currentAppearances = appearances
    worker.appearanceIndex = 1
    worker.diagnostics.expectedCollected = worker.diagnostics.expectedCollected + expected
    worker.diagnostics.returnedAppearances = worker.diagnostics.returnedAppearances + #appearances
    return true
end

local function FinishCategory(worker)
    table.insert(worker.diagnostics.categories, worker.currentCategory)
    worker.currentCategory = nil
    worker.currentAppearances = nil
    worker.appearanceIndex = 1
    worker.categoryIndex = worker.categoryIndex + 1
end

local function ProcessAppearance(worker, appearance)
    if appearance.isCollected ~= true or appearance.isHideVisual == true then return end

    local category = worker.currentCategory
    category.collectedAppearances = category.collectedAppearances + 1
    worker.diagnostics.collectedAppearances = worker.diagnostics.collectedAppearances + 1

    local acceptedForAppearance = false
    local bestSource
    local sources = P.GetKnownSources(appearance, category.categoryID, worker.transmogLocation)
    category.returnedSources = category.returnedSources + #sources
    worker.diagnostics.returnedSources = worker.diagnostics.returnedSources + #sources

    for _, source in ipairs(sources) do
        local normalized = P.NormalizeSource(source, appearance, worker.definition.key, category.categoryID)
        if normalized and Wardrobe.ValidateSource(normalized, worker.definition.key) then
            acceptedForAppearance = true
            if P.BetterSource(normalized, bestSource) then bestSource = normalized end
        end
    end

    if acceptedForAppearance and bestSource then
        P.AttachEraSourceManifest(bestSource, false)
        P.TrackAppearanceMetadata(bestSource, false)
        local visualKey = appearance.visualID
        if visualKey and P.BetterSource(bestSource, worker.visuals[visualKey]) then
            worker.visuals[visualKey] = bestSource
        end
        category.compatibleVisuals = category.compatibleVisuals + 1
    else
        worker.diagnostics.excludedVisuals = worker.diagnostics.excludedVisuals + 1
    end
end

function P.CreateSlotScanWorker(definition)
    local transmogLocation = P.GetTransmogLocation(definition)
    if not transmogLocation then
        error("WoW did not provide a transmog location for " .. tostring(definition.slotName))
    end
    return {
        definition = definition,
        transmogLocation = transmogLocation,
        categoryIDs = P.ResolveCategoryIDs(definition),
        categoryIndex = 1,
        appearanceIndex = 1,
        visuals = {},
        diagnostics = NewDiagnostics(),
    }
end

function P.StepSlotScanWorker(worker, maxAppearances, maxSeconds)
    maxAppearances = math.max(1, tonumber(maxAppearances) or 20)
    maxSeconds = math.max(0, tonumber(maxSeconds) or 0.003)
    local started = GetTime and GetTime() or nil
    local processed = 0

    while processed < maxAppearances do
        if not worker.currentCategory then
            if not BeginCategory(worker) then
                local results, diagnostics = FinishResults(worker)
                return true, results, diagnostics
            end
        end

        local appearance = worker.currentAppearances[worker.appearanceIndex]
        if not appearance then
            FinishCategory(worker)
        else
            ProcessAppearance(worker, appearance)
            worker.appearanceIndex = worker.appearanceIndex + 1
            processed = processed + 1
        end

        if started and GetTime and (GetTime() - started) >= maxSeconds then break end
    end

    return false
end

function P.ScanSlot(definition)
    local worker = P.CreateSlotScanWorker(definition)
    while true do
        local done, results, diagnostics = P.StepSlotScanWorker(worker, 1000000, 3600)
        if done then return results, diagnostics end
    end
end
