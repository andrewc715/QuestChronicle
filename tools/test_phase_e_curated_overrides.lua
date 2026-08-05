QuestChronicle = {
    Wardrobe = {},
    ZoneStyle = { _Private = {}, Traveler = {} },
}
local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
local T = ZoneStyle.Traveler

P.Normalize = function(value)
    return string.lower(tostring(value or "")):gsub("[^%w]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
P.SourceMetadata = function(source)
    return P.Normalize(table.concat({ source.styleName or source.name or "", source.styleItemSubType or "" }, " "))
end
P.GetSourceSetIDs = function() return {} end
P.GetSourceStyleSignals = function() return nil end
ZoneStyle.GetSourceExpansionID = function() return 1 end
QC.Wardrobe.GetSlotDefinition = function(slotKey) return { key = slotKey, label = slotKey } end

dofile("Core/ZoneStyle/Traveler/StyleLexicon.lua")
dofile("Core/ZoneStyle/Traveler/CuratedOverrides.lua")
dofile("Core/ZoneStyle/Traveler/Descriptors.lua")

local function Close(actual, expected, label)
    assert(math.abs((actual or 0) - expected) < 0.000001, string.format("%s: %.6f ~= %.6f", label, actual or 0, expected))
end

local fixtures = {
    {
        source = { visualID = 912, sourceID = 888, itemID = 2587, slotKey = "SHIRT", styleName = "Gray Woolen Shirt", styleItemSubType = "Cloth" },
        palette = { neutral = 1.00 }, finish = { plain = 1.00 }, dominantPalette = "neutral", dominantFinish = "plain",
        curated = { finish = true },
    },
    {
        source = { visualID = 1208, sourceID = 1254, itemID = 3427, slotKey = "SHIRT", styleName = "Stylish Black Shirt", styleItemSubType = "Cloth" },
        palette = { dark = 1.00 }, finish = { plain = 1.00 }, dominantPalette = "dark", dominantFinish = "plain",
        curated = { finish = true },
    },
    {
        source = { visualID = 1051, sourceID = 1057, itemID = 3018, slotKey = "BACK", styleName = "Hide of Lupos", styleItemSubType = "Cloth" },
        palette = { dark = .45, neutral = .35, purple = .20 }, finish = { primal = .75, weathered = .25 }, dominantPalette = "dark", dominantFinish = "primal",
        curated = { palette = true, finish = true },
    },
    {
        source = { visualID = 1139, sourceID = 1159, itemID = 3273, slotKey = "CHEST", styleName = "Rugged Plate Vest", styleItemSubType = "Plate" },
        palette = { blue = .45, steel = .35, dark = .20 }, finish = { weathered = .60, plain = .40 }, dominantPalette = "blue", dominantFinish = "weathered",
        curated = { palette = true, finish = true },
    },
    {
        source = { visualID = 5237, sourceID = 14444, itemID = 31521, slotKey = "SHOULDER", styleName = "Expedition Defender's Shoulders", styleItemSubType = "Plate" },
        palette = { green = .70, steel = .30 }, finish = { military = .80, polished = .20 }, dominantPalette = "green", dominantFinish = "military",
        curated = { palette = true, finish = true },
    },
    {
        source = { visualID = 12877, sourceID = 25917, itemID = 52931, slotKey = "FEET", styleName = "Orcish Scout Boots", styleItemSubType = "Plate" },
        palette = { dark = .70, blue = .20, steel = .10 }, finish = { plain = .75, polished = .25 }, dominantPalette = "dark", dominantFinish = "plain",
        curated = { palette = true, finish = true },
    },
}

for _, fixture in ipairs(fixtures) do
    local descriptor = T.GetDescriptor(fixture.source, QC.Wardrobe.GetSlotDefinition(fixture.source.slotKey))
    assert(descriptor.dominantPalette == fixture.dominantPalette, fixture.source.styleName .. " dominant palette")
    assert(descriptor.dominantFinish == fixture.dominantFinish, fixture.source.styleName .. " dominant finish")
    for key, expected in pairs(fixture.palette) do Close(descriptor.palette[key], expected, fixture.source.styleName .. " palette " .. key) end
    for key, expected in pairs(fixture.finish) do Close(descriptor.finish[key], expected, fixture.source.styleName .. " finish " .. key) end
    for key, expected in pairs(fixture.curated) do assert(descriptor.curatedFields[key] == expected, fixture.source.styleName .. " curated " .. key) end
    Close(descriptor.confidence[fixture.curated.palette and "palette" or "finish"], .95, fixture.source.styleName .. " curated confidence")
    for key, expected in pairs(descriptor.palette) do Close(descriptor.echoPalette[key], expected, fixture.source.styleName .. " default echo parity " .. key) end
    assert(descriptor.curatedKeyType == "visualID" and descriptor.curatedKey == fixture.source.visualID, fixture.source.styleName .. " override identity")
end

-- Reviewed shirts retain their lexicon palette; only finish is curated.
local gray = T.GetDescriptor(fixtures[1].source)
local black = T.GetDescriptor(fixtures[2].source)
assert(gray.curatedFields.palette ~= true and gray.dominantPalette == "neutral", "Gray shirt palette must remain lexicon-derived")
assert(black.curatedFields.palette ~= true and black.dominantPalette == "dark", "Black shirt palette must remain lexicon-derived")

-- An unrelated appearance remains untouched.
local unrelated = { visualID = 999999, sourceID = 999998, itemID = 999997, slotKey = "CHEST", styleName = "Red Steel Breastplate", styleItemSubType = "Plate" }
local plain = T.GetDescriptor(unrelated)
assert(not plain.curatedFields, "Unreviewed appearance received an override")
assert(plain.dominantPalette == "steel", "Existing lexicon behavior changed for unrelated appearance")

-- Visual, item, then source refinements apply by field without changing unrelated fields.
T.CURATED_DESCRIPTOR_OVERRIDES.item[2587] = { palette = { blue = 1 } }
T.CURATED_DESCRIPTOR_OVERRIDES.source[888] = { finish = { polished = 1 } }
local layered = T.ResolveCuratedDescriptorOverride(fixtures[1].source)
assert(layered.palette.blue == 1 and layered.finish.polished == 1, "Override precedence failed")
T.CURATED_DESCRIPTOR_OVERRIDES.item[2587] = nil
T.CURATED_DESCRIPTOR_OVERRIDES.source[888] = nil

-- Curated version participates in the descriptor cache fingerprint.
local before = T.GetDescriptor(fixtures[6].source)
local oldFingerprint = before.fingerprint
T.CURATED_TUNING_VERSION = T.CURATED_TUNING_VERSION + 1
local after = T.GetDescriptor(fixtures[6].source)
assert(after.fingerprint ~= oldFingerprint and after ~= before, "Curated tuning version did not invalidate descriptor cache")
T.CURATED_TUNING_VERSION = T.CURATED_TUNING_VERSION - 1

print("PASS Phase E curated visual-ID overrides, shirt guardrails, precedence, echo parity, and cache fingerprint")
