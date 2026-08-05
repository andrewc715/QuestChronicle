QuestChronicle = { Wardrobe = { _Private = {} } }
local P = QuestChronicle.Wardrobe._Private

local currentSource = {
    sourceID = 200,
    visualID = 2200,
    styleName = "Sterling Chain Cloak",
}

P.GetSourceByID = function(slotKey, sourceID)
    assert(slotKey == "BACK", "unexpected slot")
    if sourceID == currentSource.sourceID then return currentSource end
end

P.slotByKey = { BACK = { key = "BACK", label = "Back" } }
P.BuildSupportCandidate = function(source)
    return { source = source, mismatchCost = 0.30 }
end
P.EvaluateSupportBudget = function(ledger, slotKey, mismatchCost)
    return { cost = mismatchCost, allowed = true }
end
P.CommitSupportBudget = function(ledger, evaluation)
    return {
        starting = ledger.starting,
        lockedCommitment = ledger.lockedCommitment,
        generatedSpend = ledger.generatedSpend + (evaluation and evaluation.cost or 0),
        borrowed = 0,
        overrun = 0,
        remaining = ledger.starting - ledger.lockedCommitment - ledger.generatedSpend - (evaluation and evaluation.cost or 0),
    }
end

local job = {
    actionSlotKey = "BACK",
    draft = { selections = { BACK = 200 } },
    supportRerollProfile = { profileID = "PROFILE-LIVE", meanAnchorCohesion = 0.6 },
    profileResolution = { reused = true, repaired = false },
    supportRerollRoot = {
        budget = {
            starting = 9.25,
            lockedCommitment = 0.20,
            generatedSpend = 0.30,
            borrowed = 0,
            overrun = 0,
            remaining = 8.75,
        },
        decisions = {
            { slotKey = "HANDS", profileFit = 0.7, neighborCohesion = 0.7, score = 10, contextFixed = true },
        },
    },
    supportRerollPool = { pool = {}, deduplicated = 0 },
    supportRerollScoreIndex = 1,
    supportRerollActiveSlots = { "HANDS", "BACK" },
    -- Deliberately stale ancestry from a different ledger/profile moment.
    parentReport = {
        support = {
            lockedCommitment = 0.90,
            generatedSpend = 0.60,
        },
    },
    previousTargetDecision = {
        name = "Old Parent Cloak",
        sourceID = 999,
        visualID = 9999,
        mismatchSpent = 0.90,
    },
}

local chosen = {
    source = { sourceID = 201, visualID = 2201, styleName = "Replacement Cloak" },
    candidate = {},
    budgetEvaluation = { cost = 0.20, allowed = true },
    mismatchSpent = 0.20,
    profileFit = 0.8,
    neighborCohesion = 0.8,
    score = 12,
    outlierState = "NORMAL",
}

dofile("Core/Wardrobe/SupportRerollStats.lua")
local stats = P.BuildSupportRerollStats(job, chosen, 1, 1)

assert(stats.budgetReconciled == true, "live one-profile ledger should reconcile despite stale parent totals")
assert(math.abs(stats.budgetBefore - 0.80) < 0.0001, "budget before must be rebuilt from live fixed spend plus current target")
assert(math.abs(stats.expectedBudgetAfter - 0.70) < 0.0001, "expected budget must use the live fixed ledger plus replacement")
assert(math.abs(stats.budgetAfter - 0.70) < 0.0001, "actual budget after mismatch")
assert(stats.previousTargetSourceID == 200, "current live target must replace stale parent identity")
assert(stats.previousTargetVisualID == 2200, "current live visual must replace stale parent identity")
assert(stats.profileAdjustment == 0, "live one-profile ledger produced a false adjustment")

print("PASS v1.9.0.15a1 support reroll reconciles on the current live profile basis")
