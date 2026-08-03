local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local BASE_ROLES = {
    WAIST = "Chest ↔ Legs bridge",
    HANDS = "Chest ↔ Weapon bridge",
    FEET = "Lower silhouette continuity",
    HEAD = "Chest ↔ Shoulders identity",
    BACK = "Chest ↔ Shoulders silhouette support",
    WRIST = "Hands ↔ Chest continuity",
    SHIRT = "Chest ↔ Waist underlayer",
    TABARD = "Chest ↔ Legs overlay",
}

local BASE_BRIDGES = {
    WAIST = { "CHEST", "LEGS" },
    HANDS = { "CHEST", "WEAPON" },
    FEET = { "LEGS" },
    HEAD = { "CHEST", "SHOULDER" },
    BACK = { "CHEST", "SHOULDER" },
    WRIST = { "HANDS", "CHEST" },
    SHIRT = { "CHEST", "WAIST" },
    TABARD = { "CHEST", "LEGS" },
}

local function CopyArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do result[index] = value end
    return result
end

function P.ResolveSupportRole(slotKey, activeAnchorMask)
    local role = BASE_ROLES[slotKey] or "Contextual support"
    local targets = CopyArray(BASE_BRIDGES[slotKey])
    if (slotKey == "HEAD" or slotKey == "BACK") and not P.IsAnchorActive(activeAnchorMask, "SHOULDER") then
        targets = { "CHEST" }
        role = slotKey == "HEAD" and "Chest identity support" or "Chest silhouette support"
    end
    return {
        slotKey = slotKey,
        role = role,
        bridgeTargets = targets,
        relationshipLabel = table.concat(targets, " ↔ "),
    }
end

P.SUPPORT_SLOT_ROLES = P.SUPPORT_SLOT_ROLES or BASE_ROLES
P.SUPPORT_BRIDGES = P.SUPPORT_BRIDGES or BASE_BRIDGES
