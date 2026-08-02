local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
function P.ScanSlot(definition)
    local visuals = {}
    local diagnostics = {
        expectedCollected = 0,
        returnedAppearances = 0,
        collectedAppearances = 0,
        returnedSources = 0,
        compatibleVisuals = 0,
        excludedVisuals = 0,
        categories = {},
    }

    local transmogLocation = P.GetTransmogLocation(definition)
    if not transmogLocation then
        error("WoW did not provide a transmog location for " .. tostring(definition.slotName))
    end

    for _, categoryID in ipairs(P.ResolveCategoryIDs(definition)) do
        -- Use the unfiltered collection count as the diagnostic baseline. The
        -- filtered count can temporarily be zero while WoW rebuilds a search.
        local expected = tonumber(P.SafeCall(C_TransmogCollection.GetCategoryCollectedCount, categoryID)) or 0
        local appearances, retrievalMode = P.GetCategoryAppearancesRobust(categoryID, transmogLocation)
        local categoryDiagnostic = {
            categoryID = categoryID,
            expectedCollected = expected,
            returnedAppearances = #appearances,
            collectedAppearances = 0,
            returnedSources = 0,
            compatibleVisuals = 0,
            retrievalMode = retrievalMode,
        }
        diagnostics.expectedCollected = diagnostics.expectedCollected + expected
        diagnostics.returnedAppearances = diagnostics.returnedAppearances + #appearances

        for _, appearance in ipairs(appearances) do
            if appearance.isCollected == true and appearance.isHideVisual ~= true then
                categoryDiagnostic.collectedAppearances = categoryDiagnostic.collectedAppearances + 1
                diagnostics.collectedAppearances = diagnostics.collectedAppearances + 1

                local acceptedForAppearance = false
                local bestSource
                local sources = P.GetKnownSources(appearance, categoryID, transmogLocation)
                categoryDiagnostic.returnedSources = categoryDiagnostic.returnedSources + #sources
                diagnostics.returnedSources = diagnostics.returnedSources + #sources

                for _, source in ipairs(sources) do
                    local normalized = P.NormalizeSource(source, appearance, definition.key, categoryID)
                    if normalized then
                        local valid = Wardrobe.ValidateSource(normalized, definition.key)
                        if valid then
                            acceptedForAppearance = true
                            if P.BetterSource(normalized, bestSource) then
                                bestSource = normalized
                            end
                        end
                    end
                end

                if acceptedForAppearance and bestSource then
                    P.AttachEraSourceManifest(bestSource)
                    P.TrackAppearanceMetadata(bestSource)
                    -- One entry per Blizzard appearance row. Resolving a source
                    -- chooses how to preview that row; it does not define or
                    -- deduplicate the catalog itself.
                    local visualKey = appearance.visualID
                    if visualKey and P.BetterSource(bestSource, visuals[visualKey]) then
                        visuals[visualKey] = bestSource
                    end
                    categoryDiagnostic.compatibleVisuals = categoryDiagnostic.compatibleVisuals + 1
                else
                    diagnostics.excludedVisuals = diagnostics.excludedVisuals + 1
                end
            end
        end

        table.insert(diagnostics.categories, categoryDiagnostic)
    end

    local results = {}
    for _, source in pairs(visuals) do
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

    diagnostics.compatibleVisuals = #results
    return results, diagnostics
end

function Wardrobe.IsScanning()
    return Wardrobe.scanning == true
end

function P.ScheduleLoginRefresh()
    if P.loginRefreshScheduled then
        return
    end
    P.loginRefreshScheduled = true

    local cache = P.EnsureCache()
    if not C_Timer or type(C_Timer.After) ~= "function" then
        cache.loginRefreshPending = false
        cache.loginRefreshDeferredReason = "TIMER_UNAVAILABLE"
        return
    end

    P.loginRefreshToken = P.loginRefreshToken + 1
    local token = P.loginRefreshToken
    local attempts = 0
    cache.loginRefreshPending = true
    cache.loginRefreshDeferredReason = nil
    if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_SCHEDULED") end

    local function TryRefresh()
        if token ~= P.loginRefreshToken then
            cache.loginRefreshPending = false
            return
        end

        attempts = attempts + 1
        local blockedByCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
        local blockedByWardrobe = P.IsBlizzardWardrobeVisible()
        if Wardrobe.scanning or blockedByCombat or blockedByWardrobe then
            if attempts < P.LOGIN_REFRESH_MAX_ATTEMPTS then
                C_Timer.After(P.LOGIN_REFRESH_RETRY_DELAY, TryRefresh)
                return
            end

            cache.loginRefreshPending = false
            cache.loginRefreshDeferredReason = blockedByCombat and "COMBAT" or (blockedByWardrobe and "BLIZZARD_WARDROBE_OPEN" or "SCAN_BUSY")
            local settings = QC.GetSettings and QC.GetSettings() or {}
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print("Login wardrobe refresh deferred. Use Scan Collection when ready.")
            end
            if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_DEFERRED", cache.loginRefreshDeferredReason) end
            return
        end

        cache.loginRefreshPending = false
        local started, message = Wardrobe.Scan(true, "AUTO_LOGIN")
        if not started then
            cache.loginRefreshDeferredReason = message or "SCAN_UNAVAILABLE"
            if QC.Notify then QC.Notify("WARDROBE_LOGIN_REFRESH_DEFERRED", cache.loginRefreshDeferredReason) end
        end
    end

    C_Timer.After(P.LOGIN_REFRESH_DELAY, TryRefresh)
end

function Wardrobe.MarkDirty(reason)
    Wardrobe.InvalidateWeaponAppearanceRoutes()
    local cache = P.EnsureCache()
    cache.dirty = true
    cache.dirtyReason = reason or "COLLECTION_CHANGED"
    cache.lastCollectionChangeAt = time and time() or 0
    if QC.Notify then
        QC.Notify("WARDROBE_CACHE_DIRTY", cache.dirtyReason)
    end
end

function Wardrobe.Scan(force, trigger)
    if Wardrobe.scanning then
        return false, "A wardrobe scan is already running."
    end
    if not C_TransmogCollection or not C_TransmogCollection.GetCategoryAppearances then
        return false, "The transmog collection API is unavailable."
    end
    if P.IsBlizzardWardrobeVisible() then
        return false, "Close Blizzard's Transmogrify or Wardrobe window before scanning. Quest Chronicle temporarily uses the collection filters and then restores them."
    end
    if not P.LoadTransmogSupport() then
        return false, "Blizzard's transmog location helpers are unavailable. Try /reload and scan again."
    end

    local cache = P.EnsureCache()
    if not force and cache.scanState == "COMPLETE" and not cache.dirty then
        return false, "The wardrobe cache is current."
    end

    P.loginRefreshToken = P.loginRefreshToken + 1
    cache.loginRefreshPending = false
    P.CaptureRecoveryIdentities()
    Wardrobe.scanning = true
    Wardrobe.scanCollectionState = P.CaptureCollectionState()
    P.ApplyScanCollectionState()
    P.SafeCall(C_TransmogCollection.UpdateUsableAppearances)

    cache.scanState = "PREPARING"
    cache.scanStartedAt = time()
    cache.scanTrigger = trigger or "MANUAL"
    cache.scanCompletedAt = nil
    cache.scanError = nil
    cache.scanWarning = nil

    -- Build into a staging area. An empty or failed API response must never
    -- erase a previously healthy wardrobe cache.
    local pending = {
        bySlot = {},
        slotDiagnostics = {},
        totalSources = 0,
        totalVisuals = 0,
        expectedCollectedVisuals = 0,
        scanError = nil,
    }
    local index = 1
    local scanStartedPrecise = GetTime and GetTime() or nil

    local function RestoreFilters()
        P.RestoreCollectionState(Wardrobe.scanCollectionState)
        Wardrobe.scanCollectionState = nil
    end

    local function FinishFailure(message)
        RestoreFilters()
        Wardrobe.scanning = false
        cache.scanState = "FAILED"
        cache.scanCompletedAt = time()
        cache.scanError = message
        cache.scanWarning = nil
        cache.dirty = true
        cache.dirtyReason = "SCAN_FAILED"
        if scanStartedPrecise and GetTime then cache.scanDurationMS = math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) end
        P.RebuildAppearanceMetadataIndex(cache, false, false)
        if QC.Notify then
            QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
        end
    end

    local function FinishScan()
        RestoreFilters()
        Wardrobe.scanning = false

        if pending.expectedCollectedVisuals > 0 and pending.totalVisuals == 0 then
            cache.scanState = "FAILED"
            cache.scanCompletedAt = time()
            cache.scanError = "WoW reports collected appearances, but every collection query returned an empty usable cache. The previous cache was preserved."
            cache.scanWarning = nil
            cache.dirty = true
            cache.dirtyReason = "EMPTY_COLLECTION_RESPONSE"
            if scanStartedPrecise and GetTime then cache.scanDurationMS = math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) end
            P.RebuildAppearanceMetadataIndex(cache, false, false)
            if QC.Notify then
                QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
            end
            return
        end

        cache.bySlot = pending.bySlot
        cache.slotDiagnostics = pending.slotDiagnostics
        cache.totalSources = pending.totalSources
        cache.totalVisuals = pending.totalVisuals
        cache.expectedCollectedVisuals = pending.expectedCollectedVisuals
        cache.scanError = pending.scanError
        cache.scanState = pending.scanError and "COMPLETE_WITH_WARNINGS" or "COMPLETE"
        cache.scanCompletedAt = time()
        cache.dirty = false
        cache.dirtyReason = nil
        cache.characterKey = QC.GetCurrentCharacter().key
        cache.scanDurationMS = scanStartedPrecise and GetTime and math.floor(((GetTime() - scanStartedPrecise) * 1000) + 0.5) or nil
        P.RecoverAppearanceReferences(cache)
        Wardrobe.InvalidateWeaponAppearanceRoutes()
        if cache.scanTrigger == "AUTO_LOGIN" then
            cache.lastLoginRefreshAt = cache.scanCompletedAt
            cache.loginRefreshDeferredReason = nil
            local settings = QC.GetSettings and QC.GetSettings() or {}
            if settings.announceWardrobeUpdates ~= false and QC.Print then
                QC.Print(string.format("Wardrobe refreshed for this login: %d previewable appearances in %.1f seconds.", cache.totalVisuals or 0, (cache.scanDurationMS or 0) / 1000))
            end
        end

        -- Collected source counts and cached visual counts describe different things.
        -- Multiple item sources may share one visual, and character-incompatible
        -- sources are intentionally excluded. Do not flag a healthy non-empty
        -- cache merely because those totals differ.
        cache.scanWarning = nil
        P.RebuildAppearanceMetadataIndex(cache, true, false)

        if QC.Notify then
            QC.Notify("WARDROBE_SCAN_COMPLETE", cache)
        end
    end

    local function ScanCurrentSlot(retryCount)
        local definition = Wardrobe.slotDefinitions[index]
        if not definition then
            FinishScan()
            return
        end

        local ok, sources, diagnostics = pcall(P.ScanSlot, definition)
        if ok and diagnostics and diagnostics.expectedCollected > 0 and diagnostics.returnedAppearances == 0 and (retryCount or 0) < 2 then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.25, function() ScanCurrentSlot((retryCount or 0) + 1) end)
                return
            end
        end

        if ok then
            pending.bySlot[definition.key] = sources or {}
            pending.slotDiagnostics[definition.key] = diagnostics or {}
            pending.totalSources = pending.totalSources + ((diagnostics and diagnostics.returnedSources) or 0)
            pending.totalVisuals = pending.totalVisuals + #(sources or {})
            pending.expectedCollectedVisuals = pending.expectedCollectedVisuals + ((diagnostics and diagnostics.expectedCollected) or 0)
        else
            pending.bySlot[definition.key] = {}
            pending.slotDiagnostics[definition.key] = { error = tostring(sources) }
            pending.scanError = tostring(sources)
        end

        if QC.Notify then
            QC.Notify(
                "WARDROBE_SCAN_PROGRESS",
                index,
                #Wardrobe.slotDefinitions,
                definition.key,
                #(pending.bySlot[definition.key] or {}),
                pending.slotDiagnostics[definition.key]
            )
        end

        index = index + 1
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() ScanCurrentSlot(0) end)
        else
            ScanCurrentSlot(0)
        end
    end

    local readyStarted = GetTime and GetTime() or 0
    local function WaitForCollectionReady()
        local searchType = P.GetSearchType()
        local dbLoading = P.SafeCall(C_TransmogCollection.IsSearchDBLoading) == true
        local searchRunning = P.SafeCall(C_TransmogCollection.IsSearchInProgress, searchType) == true
        if not dbLoading and not searchRunning then
            cache.scanState = "SCANNING"
            ScanCurrentSlot(0)
            return
        end

        local now = GetTime and GetTime() or readyStarted
        if now - readyStarted >= 12 then
            FinishFailure("WoW's wardrobe search database did not become ready within 12 seconds. Open the native Collections Wardrobe once, close it, and scan again.")
            return
        end

        if C_Timer and C_Timer.After then
            C_Timer.After(0.10, WaitForCollectionReady)
        else
            FinishFailure("WoW's wardrobe search database is still loading.")
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.10, WaitForCollectionReady)
    else
        WaitForCollectionReady()
    end
    return true, "Preparing WoW's wardrobe collection for scanning..."
end

function Wardrobe.SelectSource(slotKey, sourceID)
    local sources = Wardrobe.GetSlotSources(slotKey)
    for _, source in ipairs(sources) do
        if source.sourceID == sourceID then
            local valid, reason = Wardrobe.ValidateSource(source, slotKey)
            if not valid then
                return false, reason
            end
            local state = P.EnsurePreviewState()
            P.SetSelectedSource(state, slotKey, source)
            state.hidden[slotKey] = nil
            state.selectedConceptID = nil
            state.generatedName = nil
            state.generatedAt = nil
            P.ApplyWeaponSelectionRules(state, slotKey)
            if slotKey ~= "OFF_HAND" and state.linkWeaponHands then
                P.SynchronizeLinkedOffHand(state, source, state.styleMode, nil, state.selections.OFF_HAND)
            end
            if QC.Notify then
                QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, source)
            end
            return true, reason
        end
    end
    return false, "The selected appearance is not present in the current cache."
end

function Wardrobe.ClearSelection(slotKey)
    local state = P.EnsurePreviewState()
    P.SetSelectedSource(state, slotKey, nil)
    state.locks[slotKey] = nil
    state.hidden[slotKey] = nil
    state.selectedConceptID = nil
    state.generatedName = nil
    state.generatedAt = nil
    if QC.Notify then
        QC.Notify("WARDROBE_SELECTION_CHANGED", slotKey, nil)
    end
end

function Wardrobe.ClearAllSelections()
    local state = P.EnsurePreviewState()
    state.selections = {}
    state.selectionVisuals = {}
    state.locks = {}
    state.hidden = {}
    state.selectedConceptID = nil
    state.generatedName = nil
    state.generatedAt = nil
    if QC.Notify then
        QC.Notify("WARDROBE_SELECTIONS_CLEARED")
    end
end

function Wardrobe.ApplyPreview(model)
    if not model then
        return false, "Preview model is unavailable."
    end

    -- v1.6.5 deliberately restores the synchronous player-model baseline used
    -- before the v1.6.3/v1.6.4 preview experiments. SetUnit establishes the
    -- equipped actor, then TryOn overlays the selected appearances without
    -- replacing the actor or scheduling competing model-load callbacks.
    P.SafeCall(model.SetUnit, model, "player")
    local applied = 0
    local failedSlots = {}
    local state = P.EnsurePreviewState()

    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local source = Wardrobe.GetSelectedSource(definition.key)
        if state.hidden[definition.key] and definition.hideable and model.UndressSlot then
            local slotID = P.SafeCall(GetInventorySlotInfo, definition.slotName)
            if slotID then
                P.SafeCall(model.UndressSlot, model, slotID)
            end
        elseif source then
            local valid = Wardrobe.ValidateSource(source, definition.key)
            if valid and source.sourceID and type(model.TryOn) == "function" then
                local targetHand
                if definition.slotName == "MAINHANDSLOT" or definition.slotName == "SECONDARYHANDSLOT" then
                    targetHand = definition.slotName
                end
                local ok, result = pcall(model.TryOn, model, source.sourceID, targetHand)
                local successValue = Enum and Enum.ItemTryOnReason and Enum.ItemTryOnReason.Success
                if ok and (result == nil or successValue == nil or result == successValue) then
                    applied = applied + 1
                else
                    table.insert(failedSlots, definition.label)
                end
            end
        end
    end

    model.qcPreviewLastApplied = applied
    model.qcPreviewFailedSlots = failedSlots
    if QC.Notify then
        QC.Notify("WARDROBE_PREVIEW_APPLIED", applied, failedSlots)
    end

    if #failedSlots > 0 then
        return false, string.format(
            "Previewed %d selected appearances; WoW rejected: %s.",
            applied,
            table.concat(failedSlots, ", ")
        )
    end
    return true, string.format("Previewed %d selected appearances.", applied)
end
