QuestChronicle = { Wardrobe = { _Private = {} }, Generation = {} }
local QC = QuestChronicle
local P = QC.Wardrobe._Private
local fingerprint = "ZCTX-A"
local contextPolicy = {
    BuildModeContext = function() return { format = 1, fingerprint = fingerprint } end,
    ValidateContext = function(snapshot) return type(snapshot) == "table" and snapshot.format == 1 and type(snapshot.fingerprint) == "string" end,
}
QC.Generation.GetGenerationMode = function()
    return { capabilities = { zoneAnchorPolicy = true }, contextPolicy = contextPolicy, anchorPolicy = {} }
end
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_context_staleness_v1113.lua$", "")
assert(loadfile(root .. "Core/Wardrobe/AnchorPolicyBridge.lua"))()
local job = { requestedStyleMode = "ZONE_NATIVE" }
P.AttachGenerationModePolicy(job)
assert(P.CaptureAnchorPolicyContext(job) == true and job.modeContextFingerprint == "ZCTX-A", "action snapshot was not captured")
assert(P.ValidateAnchorPolicyContextAtCommit(job) == true, "unchanged context was rejected")
fingerprint = "ZCTX-B"
local valid, reason = P.ValidateAnchorPolicyContextAtCommit(job)
assert(valid == false and reason:find("Zone context changed", 1, true), "stale Zone work did not cancel")
assert(job.zoneContextStaleAtCommit == true and job.zoneContextCurrentFingerprint == "ZCTX-B", "stale context diagnostics missing")
assert(job.modeContextFingerprint == "ZCTX-A", "action snapshot was silently replaced")
print("PASS v1.11.3 Zone context staleness: one immutable action snapshot and atomic stale-work cancellation")
