local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
P.eventFrame = CreateFrame("Frame")
P.eventFrame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
P.eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
P.eventFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
P.eventFrame:RegisterEvent("TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "TRANSMOG_CUSTOM_SETS_CHANGED")
P.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "PLAYER_EQUIPMENT_CHANGED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "PLAYER_SPECIALIZATION_CHANGED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "TRAIT_CONFIG_UPDATED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "GET_ITEM_INFO_RECEIVED")
pcall(P.eventFrame.RegisterEvent, P.eventFrame, "ITEM_DATA_LOAD_RESULT")
P.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local cache = P.EnsureCache()
        if not P.loginRefreshScheduled then
            cache.loginRefreshPending = false
        end
        P.EnsurePreviewState()
        local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter()
        if character and cache.characterKey and cache.characterKey ~= character.key then
            P.ResetCache(cache, "STALE")
            cache.dirtyReason = "CHARACTER_CHANGED"
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() P.RebuildAppearanceMetadataIndex(cache, false, true) end)
        else
            P.RebuildAppearanceMetadataIndex(cache, false, true)
        end
        P.ScheduleLoginRefresh()
    elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        Wardrobe.QueueItemMetadataUpdate(itemID, success, event)
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "TRAIT_CONFIG_UPDATED"
    then
        local eventArg1 = select(1, ...)
        Wardrobe.InvalidateWeaponAppearanceRoutes()
        local now = GetTime and GetTime()
        P.internalUsabilityUpdateUntil = now and (now + 1.0) or nil
        P.SafeCall(C_TransmogCollection and C_TransmogCollection.UpdateUsableAppearances)
        local function NotifyCapabilities()
            local state = P.EnsurePreviewState()
            local capabilities = P.NormalizeWeaponFamilyChoices(state, Wardrobe.GetWeaponAppearanceCapabilities())
            if QC.Notify then
                QC.Notify("WARDROBE_WEAPON_TOPOLOGY_CHANGED", capabilities.topology, eventArg1)
                QC.Notify("WARDROBE_WEAPON_CAPABILITIES_CHANGED", capabilities, event)
            end
        end
        NotifyCapabilities()
        if C_Timer and C_Timer.After then C_Timer.After(0.25, NotifyCapabilities) end
    elseif event == "TRANSMOG_CUSTOM_SETS_CHANGED" then
        local request = P.pendingCustomSetSync
        local resolved = P.TryVerifyPendingCustomSet(false)
        if request and not resolved and C_Timer and C_Timer.After then
            C_Timer.After(0.20, function()
                if P.pendingCustomSetSync == request then
                    P.TryVerifyPendingCustomSet(true)
                end
            end)
        end
    elseif event == "TRANSMOG_COLLECTION_UPDATED"
        and P.internalUsabilityUpdateUntil
        and GetTime
        and GetTime() <= P.internalUsabilityUpdateUntil
    then
        -- Weapon generation asks Blizzard to refresh current-character
        -- usability before validating the equipped hands. Blizzard reports
        -- that calculation through the generic collection-updated event even
        -- though no appearance was learned or removed. Do not turn our own
        -- validation refresh into a full wardrobe rescan.
        local cache = P.EnsureCache()
        cache.lastInternalUsabilityUpdateAt = time and time() or 0
    else
        Wardrobe.MarkDirty(event)
    end
end)
