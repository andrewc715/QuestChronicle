QuestChronicle = { Wardrobe = { _Private = { SUPPORT_SLOT_ORDER = {} } }, Diagnostics = { _Private = {} } }
local P = QuestChronicle.Diagnostics._Private
QuestChronicle.Wardrobe.GetSlotDefinition = function(key) return { key = key, label = key } end
dofile("Core/Diagnostics/SupportReportFormatter.lua")
local lines = {}
P.AddSupportSection(lines, { support = {
    targetSlotKey = "HEAD", previousTargetName = "Old",
    budgetBefore = 1.234, previousTargetCost = 0.006, replacementCost = 0.004,
    profileAdjustment = 0, budgetAfter = 1.232, budgetReconciled = true,
    profile = { activeAnchorCount = 0, centers = {}, tolerance = {}, confidence = {} },
    decisions = {}, excluded = {},
} }, false, false)
local text = table.concat(lines, "\n")
assert(text:find("+0.01 display rounding", 1, true), "rounding correction should make the visible equation coherent")
assert(text:find("= 1.23 after", 1, true), "visible budget result missing")
assert(text:find("Budget reconciliation: Pass", 1, true), "full-precision reconciliation result missing")
print("PASS v1.9.0.9 budget equation reporting: rounded display remains coherent and full-precision reconciliation is explicit")
