local QC = QuestChronicle
local Generation = QC.Generation
Generation.VisualLanguage = Generation.VisualLanguage or {}
local Visual = Generation.VisualLanguage

local function Provider(policy)
    return policy and policy.visualLanguage
end

function Visual.GetDescriptor(policy, source, definition)
    local provider = Provider(policy)
    if not provider or type(provider.GetDescriptor) ~= "function" then return nil end
    return provider.GetDescriptor(source, definition)
end

function Visual.GetPairCohesion(policy, ...)
    local provider = Provider(policy)
    if not provider or type(provider.GetPairCohesion) ~= "function" then return nil end
    return provider.GetPairCohesion(...)
end

function Visual.GetCuratedMetadata(policy, source)
    local provider = Provider(policy)
    if not provider or type(provider.GetCuratedMetadata) ~= "function" then return nil end
    return provider.GetCuratedMetadata(source)
end
