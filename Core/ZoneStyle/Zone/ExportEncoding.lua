local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

Zone.DIAGNOSTIC_VALUE_ENCODING = "DIAGNOSTIC_ESCAPE_V1"

local UNSAFE_WOW_CONTROL_PATTERN = "|[TtAaHhCcRrKk]"

function Zone.EscapeDiagnosticValue(value)
    local text = tostring(value == nil and "" or value)
    text = text:gsub("\\", "\\\\")
    text = text:gsub("|", "\\u007C")
    text = text:gsub("`", "\\u0060")
    text = text:gsub("\r", "\\r")
    text = text:gsub("\n", "\\n")
    return text
end

function Zone.MarkdownCell(value)
    return Zone.EscapeDiagnosticValue(value)
end

function Zone.MarkdownCode(value)
    return "`" .. Zone.EscapeDiagnosticValue(value) .. "`"
end

function Zone.ContainsUnsafeWoWControl(value)
    return tostring(value or ""):find(UNSAFE_WOW_CONTROL_PATTERN) ~= nil
end
