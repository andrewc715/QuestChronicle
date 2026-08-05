QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local P = QuestChronicle.Wardrobe._Private
local T = QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER = { "HEAD", "BACK", "HANDS", "WAIST" }
P.slotByKey = {}
for _, key in ipairs(P.SUPPORT_SLOT_ORDER) do P.slotByKey[key] = { key = key, label = key } end
P.SupportVisualIdentity = function(source) return tostring(source and source.visualID or "") end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, HEAD = .9, BACK = .55, HANDS = .65, WAIST = .5 }
T.CONFIG = { thresholds = { loudImpact = .55 } }
T.GetTravelerDominantPalette = function(descriptor) return descriptor.paletteFamily end
T.GetTravelerProfileCohesion = function(descriptor)
    return descriptor.profile or 1, { finish = descriptor.finish or 1, visualWeight = descriptor.weight or 1, material = 1, motif = 1 }
end
T.GetTravelerEchoSupport = function(entry) return entry.descriptor.echo or 0 end
T.ClassifyTravelerMismatch = function(entry, profile, components, echo)
    entry.visualImpact = entry.descriptor.impact or 0
    return entry.descriptor.class or "COHESIVE", entry.descriptor.points or 0, "fixture", entry.descriptor.bridge or 1, "material"
end
T.GetTravelerOutlierSeverity = function(entry) return entry.descriptor.severity or 0, {} end

dofile("Core/Wardrobe/SupportFinalValidation.lua")

local nextID = 0
local function Candidate(slot, descriptor)
    nextID = nextID + 1
    return { source = { sourceID = nextID, visualID = nextID }, descriptor = descriptor, prominence = T.SLOT_VISIBILITY_WEIGHTS[slot] }
end
local function Profile(anchorPalettes)
    local entries = {}
    for index, palette in ipairs(anchorPalettes or { "steel" }) do
        entries[#entries + 1] = { slotKey = index == 1 and "CHEST" or ("ANCHOR" .. index), label = "Anchor", source = { sourceID = 900 + index }, descriptor = { paletteFamily = palette } }
    end
    return { descriptor = {}, entries = entries, meanAnchorCohesion = .7 }
end
local function Validate(descriptors, anchorPalettes, locks)
    local selected, decisions, active = {}, {}, {}
    for index, descriptor in ipairs(descriptors) do
        local slot = P.SUPPORT_SLOT_ORDER[index]
        selected[slot] = Candidate(slot, descriptor)
        decisions[#decisions + 1] = { slotKey = slot, candidate = selected[slot], outlierState = descriptor.phaseCOutlier }
        active[#active + 1] = slot
    end
    local job = { draft = { hidden = {}, locks = locks or {} } }
    local work = { profile = Profile(anchorPalettes), activeSlots = active }
    return P.ValidateSupportConfiguration(job, work, { selected = selected, decisions = decisions, totalScore = 1 })
end

local atBudget = Validate({ { paletteFamily = "steel", class = "MILD", points = 1 }, { paletteFamily = "steel", class = "MILD", points = 1 } })
assert(atBudget.status == "CLEAN" and atBudget.mismatchUsed == 2.00, "2.00 mismatch must pass")
local overBudget = Validate({ { paletteFamily = "steel", class = "MILD", points = 1 }, { paletteFamily = "steel", class = "MILD", points = 1.01 } })
assert(overBudget.status == "REPAIR_REQUIRED" and overBudget.mismatchOverflow == .01, "2.01 mismatch must fail")

local atSeverity = Validate({ { paletteFamily = "steel", severity = .720 } })
assert(atSeverity.status == "CLEAN", "severity 0.720 must pass")
local overSeverity = Validate({ { paletteFamily = "steel", severity = .721 } })
assert(overSeverity.status == "REPAIR_REQUIRED" and overSeverity.repairableSevere == 1, "severity 0.721 must fail")

local threePalettes = Validate({ { paletteFamily = "red" }, { paletteFamily = "blue" } }, { "steel" })
assert(threePalettes.paletteFamilies == 3 and threePalettes.status == "CLEAN", "three palettes must pass")
local fourPalettes = Validate({ { paletteFamily = "red" }, { paletteFamily = "blue" }, { paletteFamily = "green" } }, { "steel" })
assert(fourPalettes.paletteFamilies == 4 and fourPalettes.status == "REPAIR_REQUIRED", "four palettes must fail")

local zeroEcho = Validate({ { paletteFamily = "red", class = "SUPPORTED", impact = .8, echo = 0 } })
assert(zeroEcho.status == "REPAIR_REQUIRED" and zeroEcho.repairableZeroEcho == 1, "loud zero-echo accent must fail")
local supportedEcho = Validate({ { paletteFamily = "red", class = "SUPPORTED", impact = .8, echo = .65 } })
assert(supportedEcho.status == "CLEAN" and supportedEcho.repairableZeroEcho == 0, "echo 0.65 must support the accent")

local locked = Validate({ { paletteFamily = "red", class = "POSTAL", impact = .9, severity = .9 } }, { "steel" }, { HEAD = true })
assert(locked.status == "LOCKED_OVERRIDE" and locked.protectedLockedViolations > 0, "locked-only violations must be preserved")

print("PASS Phase D final validation boundaries and locked sovereignty")
