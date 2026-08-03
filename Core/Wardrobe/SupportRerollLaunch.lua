local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function Primitive(value)
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then return value end
end

function P.GetPreviewRevision(state)
    return math.max(0, math.floor(tonumber(state and state.supportRerollRevision) or 0))
end

function P.TouchPreviewRevision(state)
    if not state then return 0 end
    state.supportRerollRevision = P.GetPreviewRevision(state) + 1
    return state.supportRerollRevision
end

function P.CreateSupportRerollManifest(state, slotKey, styleMode, token)
    local selections = state and state.selections or {}
    local visuals = state and state.selectionVisuals or {}
    local profile = state and state.contextualSupportProfile or {}
    return {
        generationToken = token,
        targetSlot = slotKey,
        previousSourceID = Primitive(selections[slotKey]),
        previousVisualID = Primitive(visuals[slotKey]),
        previewRevision = P.GetPreviewRevision(state),
        styleMode = Primitive(styleMode),
        profileID = Primitive(profile.profileID),
        profileSourceReportID = Primitive(profile.profileSourceReportID),
        requestedAtMs = P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0,
    }
end

function P.ValidateSupportRerollManifest(manifest, state)
    if not manifest or not state then return false, "MISSING_STATE" end
    if P.GetPreviewRevision(state) ~= (tonumber(manifest.previewRevision) or 0) then return false, "REVISION_CHANGED" end
    local selections = state.selections or {}
    local visuals = state.selectionVisuals or {}
    if selections[manifest.targetSlot] ~= manifest.previousSourceID then return false, "TARGET_SOURCE_CHANGED" end
    if visuals[manifest.targetSlot] ~= manifest.previousVisualID then return false, "TARGET_VISUAL_CHANGED" end
    local profile = state.contextualSupportProfile or {}
    if manifest.profileID and profile.profileID and manifest.profileID ~= profile.profileID then return false, "PROFILE_CHANGED" end
    return true
end
