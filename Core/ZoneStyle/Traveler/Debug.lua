local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local T = ZoneStyle.Traveler

local function FormatPercent(value)
    return string.format("%.0f%%", (tonumber(value) or 0) * 100)
end

local function FormatCost(value)
    return string.format("%.2f", tonumber(value) or 0)
end

local function FormatMap(values, limit)
    local entries = {}
    for key, value in pairs(values or {}) do table.insert(entries, { key = key, value = value }) end
    table.sort(entries, function(left, right)
        if left.value == right.value then return left.key < right.key end
        return left.value > right.value
    end)
    local parts = {}
    for index = 1, math.min(limit or 2, #entries) do
        table.insert(parts, string.format("%s %s", entries[index].key, FormatPercent(entries[index].value)))
    end
    return #parts > 0 and table.concat(parts, ", ") or "unknown"
end

local function Print(message)
    if QC._Core and QC._Core.Print then QC._Core.Print(message)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Quest Chronicle: " .. tostring(message)) end
end

local function SourceName(source)
    return tostring(source and (source.styleName or source.name) or "Unknown appearance")
end

local function EntryName(entry)
    local name = SourceName(entry.source)
    if entry.isWeaponBlock and (entry.memberCount or 1) > 1 then return name .. " x" .. tostring(entry.memberCount) end
    return name
end

local function CurrentEntries()
    local Wardrobe = QC.Wardrobe
    if not Wardrobe or not Wardrobe.GetPreviewState then return {} end
    local state = Wardrobe.GetPreviewState()
    local entries = {}
    for _, definition in ipairs(Wardrobe.slotDefinitions or {}) do
        local source = Wardrobe.GetSelectedSource and Wardrobe.GetSelectedSource(definition.key)
        if source and not (state.hidden and state.hidden[definition.key]) then
            local descriptor = T.GetDescriptor(source, definition)
            local scoringContext = ZoneStyle.GetCurrentContext and ZoneStyle.GetCurrentContext() or {}
            local travelerScore = ZoneStyle.ScoreSource and select(1, ZoneStyle.ScoreSource(source, definition, ZoneStyle.MODE_TRAVELER, scoringContext)) or 0
            table.insert(entries, {
                slotKey = definition.key,
                slotLabel = definition.label,
                definition = definition,
                source = source,
                descriptor = descriptor,
                travelerScore = travelerScore,
                locked = state.locks and state.locks[definition.key] == true,
                linkedHands = state.linkWeaponHands ~= false,
            })
        end
    end
    return entries, state
end

function T.AnalyzeCurrentOutfit(trigger)
    local entries, state = CurrentEntries()
    local context = ZoneStyle.GetCurrentContext and ZoneStyle.GetCurrentContext() or {}
    local analysis = T.AnalyzeEntries(entries, context)
    analysis.trigger = trigger or "manual debug"
    analysis.outfitName = state and state.generatedName or nil
    analysis.currentMode = state and ZoneStyle.NormalizeMode(state.styleMode) or nil
    T.lastAnalysis = analysis
    return analysis
end

function T.GetCurrentAnalysis()
    return T.AnalyzeCurrentOutfit("current outfit")
end

function T.GetEntrySummary(sourceID)
    local analysis = T.lastAnalysis or T.AnalyzeCurrentOutfit("tooltip")
    for _, entry in ipairs(analysis.entries or {}) do
        if tonumber(entry.source and entry.source.sourceID) == tonumber(sourceID) then
            return string.format(
                "Traveler cohesion %s • %s • mismatch %s",
                FormatPercent(entry.profileCohesion),
                entry.mismatchClass,
                FormatCost(entry.mismatchPoints)
            ), entry
        end
    end
    return nil
end

function T.PrintDiagnostics()
    local analysis = T.AnalyzeCurrentOutfit("/qc traveler debug")
    Print("Traveler cohesion diagnostics (calibrated instrumentation only; generation is unchanged):")
    Print(string.format(
        "Outfit: %s | current mode %s | %d selected appearances | %d analysis blocks",
        tostring(analysis.outfitName or "Unnamed current look"),
        tostring(analysis.currentMode or "unknown"),
        tonumber(analysis.selectedAppearanceCount) or #(analysis.entries or {}),
        tonumber(analysis.analysisBlockCount) or #(analysis.entries or {})
    ))
    Print(string.format(
        "Profile: palette %s | material %s | finish %s | motif %s | visual weight %.2f",
        FormatMap(analysis.profile.palette, 2),
        FormatMap(analysis.profile.material, 2),
        FormatMap(analysis.profile.finish, 2),
        FormatMap(analysis.profile.motifs, 2),
        tonumber(analysis.profile.visualWeight) or 0
    ))
    Print(string.format(
        "Anchor cohesion %s | mean Traveler score %.1f | diagnostic skeleton score %.1f",
        FormatPercent(analysis.meanAnchorCohesion),
        tonumber(analysis.meanTravelerScore) or 0,
        tonumber(analysis.skeletonScore) or 0
    ))
    Print(string.format(
        "Mismatch budget %s/%s | supported variations %d | postal-code outliers %d | hard anchor clashes %d",
        FormatCost(analysis.mismatchUsed),
        FormatCost(analysis.mismatchBudget),
        tonumber(analysis.supportedVariationCount) or 0,
        tonumber(analysis.postalCount) or 0,
        tonumber(analysis.hardClashes) or 0
    ))

    table.sort(analysis.entries, function(left, right)
        local leftVisibility = left.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[left.slotKey] or 0
        local rightVisibility = right.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[right.slotKey] or 0
        if leftVisibility == rightVisibility then return tostring(left.slotKey) < tostring(right.slotKey) end
        return leftVisibility > rightVisibility
    end)
    for _, entry in ipairs(analysis.entries) do
        Print(string.format(
            "%s%s: %s | base %.1f | cohesion %s | loud %s raw / %s impact | echo %s | %s (%s) — %s",
            tostring(entry.slotLabel or entry.slotKey),
            entry.locked and " [locked]" or "",
            EntryName(entry),
            tonumber(entry.travelerScore) or 0,
            FormatPercent(entry.profileCohesion),
            FormatPercent(entry.intrinsicLoudness or entry.descriptor.loudness),
            FormatPercent(entry.visualImpact),
            FormatPercent(entry.echoSupport),
            tostring(entry.mismatchClass),
            FormatCost(entry.mismatchPoints),
            tostring(entry.mismatchReason or "")
        ))
    end
    return analysis
end

function ZoneStyle.GetTravelerCurrentAnalysis()
    return T.GetCurrentAnalysis()
end

function ZoneStyle.GetTravelerEntrySummary(sourceID)
    return T.GetEntrySummary(sourceID)
end

function ZoneStyle.PrintTravelerDiagnostics()
    return T.PrintDiagnostics()
end
