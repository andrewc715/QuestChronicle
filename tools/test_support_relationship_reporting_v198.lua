QuestChronicle = {
    Wardrobe = {
        _Private = { SUPPORT_SLOT_ORDER = { "WAIST", "HANDS" } },
        GetSlotDefinition = function(key) return { key = key, label = key == "WAIST" and "Waist" or "Hands" } end,
    },
    Diagnostics = { _Private = {} },
}
local P = QuestChronicle.Diagnostics._Private

dofile("Core/Diagnostics/SupportReportFormatter.lua")

local report = {
    support = {
        profile = { activeAnchorCount = 4, meanAnchorCohesion = .65, activeAnchors = {}, centers = {}, tolerance = {}, confidence = {} },
        startingBudget = 10.75, lockedCommitment = 0, generatedSpend = .4, borrowed = 0, overrun = 0, remainingBudget = 10.35,
        configurationScore = 40, wholeOutfitCohesion = .66, controlledAccents = 0, outliers = 0, fallbackSlots = 0, emptySlots = 0,
        chosenRank = 1, shortlistSize = 6, poolSizes = {}, expansions = {}, retained = {}, deduplicated = 0, budgetRejections = 0,
        decisions = {
            {
                slotKey = "HANDS", slotLabel = "Hands", name = "True Bridge", role = "Chest ↔ Weapon bridge",
                profileFit = .7, neighborCohesion = .7, bridgeBonus = 1.32, bridgeTarget = "CHEST ↔ WEAPON",
                bridgeBefore = .532, bridgeAfter = .587, bridgeImprovement = true, mismatchSpent = .1,
                budgetState = "WITHIN", outlierState = "NORMAL", repeatPenalty = 0,
            },
            {
                slotKey = "WAIST", slotLabel = "Waist", name = "Context Match", role = "Chest ↔ Legs bridge",
                profileFit = .7, neighborCohesion = .6, bridgeBonus = 0, bridgeTarget = "CHEST ↔ LEGS",
                bridgeBefore = .767, bridgeAfter = .567, bridgeImprovement = false, mismatchSpent = .2,
                budgetState = "WITHIN", outlierState = "NORMAL", repeatPenalty = 0,
            },
        },
        excluded = {},
    },
}
local lines = {}
P.AddSupportSection(lines, report, false, false)
local text = table.concat(lines, "\n")
assert(text:find("Bridge improvement: CHEST ↔ WEAPON", 1, true), "positive relationship must use Bridge improvement wording")
assert(text:find("Relationship: CHEST ↔ LEGS", 1, true), "non-improving relationship must use Relationship wording")
assert(text:find("bridge bonus None", 1, true), "non-improving relationship must explicitly report no bridge bonus")
assert(not text:find("Bridge improvement: CHEST ↔ LEGS", 1, true), "negative relationship must not be called a bridge improvement")
print("PASS v1.9.0.8 support relationship reporting: genuine bridge and neutral/weaker relationship wording verified")
