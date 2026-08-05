QuestChronicle = {
    ZoneStyle = { Traveler = {} },
    Diagnostics = { _Private = { DeepCopy = function(value) return value end } },
    Wardrobe = { _Private = {}, GetSlotDefinition = function(key) return { key = key, label = key } end },
}
local QC = QuestChronicle
local T = QC.ZoneStyle.Traveler
T.CURATED_TUNING_VERSION = 1
T.GetCuratedDescriptorMetadata = function(source)
    if source.visualID == 5237 then return { fields = { "palette", "finish" }, keyType = "visualID", key = 5237, version = 1 } end
end
T.GetCuratedFieldsLabel = function(meta) return meta and table.concat(meta.fields, ", ") or nil end

dofile("Core/Diagnostics/SupportSnapshot.lua")
local state = { hidden = {}, locks = {} }
local job = { supportDiagnostics = {
    decisions = { {
        slotKey = "SHOULDER",
        source = { sourceID = 14444, visualID = 5237, itemID = 31521, styleName = "Expedition Defender's Shoulders" },
    } },
    activeSlots = { "SHOULDER" },
} }
local snapshot = QC.Diagnostics._Private.BuildSupportSnapshot(state, job)
local decision = snapshot.decisions[1]
assert(decision.curatedFields == "palette, finish", "Support snapshot curated marker missing")
assert(decision.curatedKeyType == "visualID" and decision.curatedKey == 5237, "Support snapshot curated identity missing")
assert(decision.curatedTuningVersion == 1, "Support snapshot tuning version missing")
print("PASS Phase E compact curated diagnostic marker")
