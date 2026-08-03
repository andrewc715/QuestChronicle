QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local W, P, T = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions = {}
for _, key in ipairs({ "HEAD", "SHOULDER", "BACK", "CHEST", "SHIRT", "TABARD", "WRIST", "HANDS", "WAIST", "LEGS", "FEET", "ONE_HAND", "OFF_HAND" }) do
    local d = { key = key, label = key }
    W.slotDefinitions[#W.slotDefinitions + 1] = d
end
P.slotByKey = {}; for _, d in ipairs(W.slotDefinitions) do P.slotByKey[d.key] = d end
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND" }
local sources = {}
local function S(id, slot, value, loud)
    local source = { sourceID = id, visualID = id, slotKey = slot, styleName = slot .. id }
    source.descriptor = {
        palette = { steel = value, red = 1 - value }, material = { plate = value, cloth = 1 - value },
        finish = { military = value, ornate = 1 - value }, motifs = { frontier = value, royal = 1 - value },
        confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1, provenance = 1 },
        visualWeight = 2 + value, loudness = loud or 0.2, expansionID = 1, setIDs = {},
        dominantPalette = value >= 0.5 and "steel" or "red", dominantMaterial = value >= 0.5 and "plate" or "cloth",
        dominantFinish = value >= 0.5 and "military" or "ornate", dominantMotif = value >= 0.5 and "frontier" or "royal",
    }
    sources[slot .. id] = source
    return source
end
local chest, legs, shoulder, weapon = S(1, "CHEST", 0.9), S(2, "LEGS", 0.85), S(3, "SHOULDER", 0.8), S(4, "ONE_HAND", 0.8)
local waistGood, waistBad = S(11, "WAIST", 0.84), S(12, "WAIST", 0.1, 0.9)
local handsGood, handsBad = S(21, "HANDS", 0.82), S(22, "HANDS", 0.2, 0.8)
function P.GetSourceByID(slot, id) return sources[slot .. id] end
function QuestChronicle.ZoneStyle.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST=1, LEGS=.8, SHOULDER=1, ONE_HAND=.9, WAIST=.5, HANDS=.65 }
function T.GetPairCohesion(left, right)
    local function v(d) return d and d.palette and (d.palette.steel or 0) or 0 end
    local score = 1 - math.abs(v(left) - v(right))
    return score, { palette=score, material=score, finish=score, visualWeight=score, motif=score, provenance=.78 }
end
P.SupportVisualIdentity = function(source) return tostring(source and source.visualID or "") end
function P.GetSupportSlotAllowance(slot) return ({ WAIST=1.5, HANDS=1.25, HEAD=2, BACK=2, FEET=1.25, WRIST=.5, SHIRT=.75, TABARD=1.5 })[slot] or 0 end
math.randomseed(1907)
dofile("Core/Wardrobe/SupportProfileIdentity.lua")
dofile("Core/Wardrobe/SupportProfile.lua")
dofile("Core/Wardrobe/SupportBudget.lua")
dofile("Core/Wardrobe/SupportScoring.lua")
dofile("Core/Wardrobe/SupportBeam.lua")
local state = { selections = { CHEST=1, LEGS=2, SHOULDER=3, ONE_HAND=4 }, hidden = {}, locks = {} }
local profile = P.BuildContextualSupportProfile(state)
assert(profile.activeAnchorCount == 4, "four active anchors expected")
local weight = 0; for _, entry in ipairs(profile.entries) do weight = weight + entry.weight end
assert(math.abs(weight - 1) < .0001, "anchor weights must normalize")
local budget = P.CreateSupportBudget(state, P.SUPPORT_SLOT_ORDER)
assert(math.abs(budget.starting - 10.75) < .001, "full mismatch budget must be 10.75")
local job = { draft = state, styleEngine = { GetSourceCoherence=function() return .8, true end, ScoreSource=function(source) return source == waistGood or source == handsGood and 20 or 5, {} end }, styleMode="TRAVELER", styleContext={} }
local wg = P.BuildSupportCandidate(waistGood, P.slotByKey.WAIST, job, profile)
local wb = P.BuildSupportCandidate(waistBad, P.slotByKey.WAIST, job, profile)
local hg = P.BuildSupportCandidate(handsGood, P.slotByKey.HANDS, job, profile)
local hb = P.BuildSupportCandidate(handsBad, P.slotByKey.HANDS, job, profile)
local work = P.CreateSupportBeamWork(job, profile, P.CreateSupportBudget(state, {"WAIST","HANDS"}), {"WAIST","HANDS"}, { WAIST={wg,wb}, HANDS={hg,hb} }, {}, {})
local guard=0
while not P.StepSupportBeamWork(work) do guard=guard+1 assert(guard < 100, "support beam did not finish") end
local chosen, rank, shortlist = P.ChooseSupportConfiguration(work)
assert(chosen and chosen.selected.WAIST.source == waistGood, "contextual waist should win")
assert(chosen.selected.HANDS.source == handsGood, "contextual hands should win")
assert(chosen.budget.remaining >= 0, "chosen support must preserve budget")
assert(rank >= 1 and shortlist <= 6, "bounded final shortlist")
state.hidden.SHOULDER = true
local hiddenProfile = P.BuildContextualSupportProfile(state)
assert(hiddenProfile.activeAnchorCount == 3, "hidden anchor must contribute zero")
print(string.format("PASS contextual support phase: profile %d anchors, budget %.2f, beam rank %d/%d, remaining %.2f", profile.activeAnchorCount, budget.starting, rank, shortlist, chosen.budget.remaining))
