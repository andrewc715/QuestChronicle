local QC = QuestChronicle
local Generation = QC.Generation
local P = Generation._Private

P.modeRegistry = P.modeRegistry or {}
P.modeOrder = P.modeOrder or {}

local function CopyCapabilities(policy)
    local result = {}
    for key, value in pairs(policy and policy.capabilities or {}) do
        if type(value) == "boolean" or type(value) == "string" or type(value) == "number" then result[key] = value end
    end
    result.modeID = policy and policy.modeID or nil
    result.displayLabel = policy and policy.displayLabel or nil
    result.diagnosticLabel = policy and policy.diagnosticLabel or nil
    result.implementation = policy and policy.implementation or nil
    result.implementationGeneration = policy and policy.implementationGeneration or nil
    result.policyContractVersion = policy and policy.contractVersion or nil
    return result
end

function Generation.RegisterGenerationMode(modeID, policy)
    modeID = P.NormalizeModeID(modeID)
    if not modeID then return false, "Cannot register a generation mode without a mode ID." end
    if P.modeRegistry[modeID] then return false, "Generation mode " .. modeID .. " is already registered." end
    if type(policy) ~= "table" then return false, "Generation mode " .. modeID .. " has no policy." end
    if policy.modeID ~= modeID then return false, "Generation mode registration ID does not match its policy ID." end
    local ok, reason = P.ValidateModePolicy(policy)
    if not ok then return false, reason end
    P.modeRegistry[modeID] = policy
    P.modeOrder[#P.modeOrder + 1] = modeID
    return true, policy
end

function Generation.GetGenerationMode(modeID)
    modeID = P.NormalizeModeID(modeID)
    if not modeID then return nil, "No generation mode was requested." end
    local policy = P.modeRegistry[modeID]
    if not policy then return nil, "Unsupported generation mode: " .. modeID .. "." end
    return policy
end

function Generation.GetRegisteredGenerationModes()
    local result = {}
    for _, modeID in ipairs(P.modeOrder) do
        local policy = P.modeRegistry[modeID]
        if policy then result[#result + 1] = CopyCapabilities(policy) end
    end
    return result
end

function Generation.GetActiveGenerationMode()
    local modeID = QC.ZoneStyle and QC.ZoneStyle.GetMode and QC.ZoneStyle.GetMode() or nil
    return Generation.GetGenerationMode(modeID)
end

function Generation.SupportsSharedFramework(modeID)
    local policy = Generation.GetGenerationMode(modeID)
    return policy ~= nil and policy.implementation == Generation.IMPLEMENTATION_SHARED_FRAMEWORK
end

function Generation.GetModeCapabilities(modeID)
    local policy, reason = Generation.GetGenerationMode(modeID)
    if not policy then return nil, reason end
    return CopyCapabilities(policy)
end
