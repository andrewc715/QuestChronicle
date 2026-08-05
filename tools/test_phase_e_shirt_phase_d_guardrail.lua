QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = { Traveler = {} },
}
local QC = QuestChronicle
local P = QC.Wardrobe._Private
local T = QC.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER = { "SHIRT" }
P.slotByKey = { SHIRT = { key = "SHIRT", label = "Shirt" } }
P.SupportVisualIdentity = function(source) return tostring(source and source.visualID or "") end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, LEGS = .8, SHOULDER = 1, SHIRT = .2 }
T.CONFIG = { thresholds = { loudImpact = .55 } }
T.GetTravelerProfileCohesion = function() return .8, { palette = .8, material = .8, finish = .8, visualWeight = .8, motif = .8 } end
T.GetTravelerEchoSupport = function() return 1 end
T.ClassifyTravelerMismatch = function() return "COHESIVE", 0, "cohesive", .8, "finish" end
T.GetTravelerOutlierSeverity = function() return .1, {} end
T.GetTravelerDominantPalette = function(descriptor) return descriptor and descriptor.dominantPalette end

dofile("Core/Wardrobe/SupportFinalValidation.lua")

local function anchor(slot, visual, palette)
    return { slotKey = slot, label = slot, source = { visualID = visual }, descriptor = { dominantPalette = palette } }
end

local profile = {
    entries = {
        anchor("CHEST", 1, "steel"),
        anchor("LEGS", 2, "earth"),
        anchor("SHOULDER", 3, "blue"),
    },
    descriptor = { dominantPalette = "steel" },
    meanAnchorCohesion = .8,
}

for _, fixture in ipairs({
    { visualID = 912, palette = "neutral", name = "Gray Woolen Shirt" },
    { visualID = 1208, palette = "dark", name = "Stylish Black Shirt" },
}) do
    local candidate = {
        source = { visualID = fixture.visualID, sourceID = fixture.visualID + 1 },
        descriptor = { dominantPalette = fixture.palette, loudness = .08 },
        prominence = .2,
    }
    local configuration = {
        selected = { SHIRT = candidate },
        decisions = { { slotKey = "SHIRT", source = candidate.source, outlierState = "NORMAL" } },
        totalScore = 1,
    }
    local job = { draft = { hidden = {}, locks = {} } }
    local work = { profile = profile, activeSlots = { "SHIRT" } }
    local validation = P.ValidateSupportConfiguration(job, work, configuration)
    assert(validation.paletteFamilies == 4 and validation.paletteOverflow == 1, fixture.name .. " did not remain a normal fourth family")
    assert(validation.status == "REPAIR_REQUIRED", fixture.name .. " was incorrectly exempted from Phase D")
    local target = P.SelectSupportRepairTarget(validation, {})
    assert(target and target.slotKey == "SHIRT", fixture.name .. " could not remain a normal repair target")
end

print("PASS Phase E shirt palettes remain ordinary Phase D palette-overflow repair candidates")
