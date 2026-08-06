local QC = QuestChronicle
local Generation = QC.Generation
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local ZoneStyle = QC.ZoneStyle

Generation.TravelerContextPolicy = {
    BuildModeContext = function(state, requestedMode)
        local mode = ZoneStyle and ZoneStyle.NormalizeMode and ZoneStyle.NormalizeMode(requestedMode or state.styleMode)
            or (requestedMode or state.styleMode)
        local base = ZoneStyle and ZoneStyle.GetCurrentContext and ZoneStyle.GetCurrentContext() or nil
        local context = ZoneStyle and ZoneStyle.CreateGenerationContext and ZoneStyle.CreateGenerationContext(base) or base
        return mode, context
    end,
    BuildContextSeed = function(state, context)
        if not ZoneStyle or not ZoneStyle.AddSourceToGenerationContext then return context end
        for _, definition in ipairs(Wardrobe.slotDefinitions or {}) do
            local slotKey = definition.key
            if state.locks[slotKey] and not state.hidden[slotKey] and state.selections[slotKey] then
                ZoneStyle.AddSourceToGenerationContext(context, P.GetSourceByID(slotKey, state.selections[slotKey]))
            end
        end
        return context
    end,
    DescribeContext = function(context)
        return context and (context.profileLabel or context.provenanceLabel or context.zone) or nil
    end,
    ValidateContext = function(context)
        return context ~= nil, context and nil or "Traveler context is unavailable."
    end,
}
