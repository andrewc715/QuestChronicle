QuestChronicle = { ZoneStyle = { Zone = {} } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_export_encoding_v1112.lua$", "")
assert(loadfile(root .. "Core/ZoneStyle/Zone/ExportEncoding.lua"))()
local Zone = QuestChronicle.ZoneStyle.Zone

local fixtures = {
    { "HEAD|Templar Crown", "HEAD\\u007CTemplar Crown" },
    { "BACK|Royal Cloak", "BACK\\u007CRoyal Cloak" },
    { "CHEST|Replica Lightforge Breastplate", "CHEST\\u007CReplica Lightforge Breastplate" },
    { "FEET|Heavy Lamellar Boots", "FEET\\u007CHeavy Lamellar Boots" },
    { "|Hitem:123|h[Test]|h", "\\u007CHitem:123\\u007Ch[Test]\\u007Ch" },
    { "|Ttexture:path|t", "\\u007CTtexture:path\\u007Ct" },
    { "|cffffffffColor|r", "\\u007CcffffffffColor\\u007Cr" },
    { "slash\\tick`line\r\n", "slash\\\\tick\\u0060line\\r\\n" },
}
for _, fixture in ipairs(fixtures) do
    local encoded = Zone.EscapeDiagnosticValue(fixture[1])
    assert(encoded == fixture[2], string.format("encoding mismatch: %q ~= %q", encoded, fixture[2]))
    assert(not Zone.ContainsUnsafeWoWControl(encoded), "encoded value retained an unsafe WoW control token")
end
assert(Zone.ContainsUnsafeWoWControl("HEAD|Templar Crown"), "unsafe-token detector missed |T")
assert(Zone.ContainsUnsafeWoWControl("|Hitem:123|h"), "unsafe-token detector missed |H")
assert(Zone.MarkdownCell("A|B") == "A\\u007CB", "Markdown cell did not use diagnostic encoding")
assert(Zone.MarkdownCode("A`B") == "`A\\u0060B`", "Markdown code did not encode a literal backtick")
print("PASS v1.11.2 Zone export encoding: dynamic diagnostic values survive WoW control parsing")
