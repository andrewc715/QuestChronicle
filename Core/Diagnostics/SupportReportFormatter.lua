local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local function F(value, decimals)
    return string.format("%." .. tostring(decimals or 2) .. "f", tonumber(value) or 0)
end

local function Add(lines, text)
    lines[#lines + 1] = text or ""
end

local function RoundedCents(value)
    value = (tonumber(value) or 0) * 100
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

local function BudgetEquation(support)
    local before = RoundedCents(support.budgetBefore)
    local removed = RoundedCents(support.previousTargetCost)
    local replacement = RoundedCents(support.replacementCost)
    local adjustment = RoundedCents(support.profileAdjustment)
    local after = RoundedCents(support.budgetAfter)
    local rounding = after - (before - removed + replacement + adjustment)
    local parts = {
        string.format("%.2f before", before / 100),
        string.format("- %.2f removed", removed / 100),
        string.format("+ %.2f replacement", replacement / 100),
        string.format("%+.2f profile adjustment", adjustment / 100),
    }
    if rounding ~= 0 then parts[#parts + 1] = string.format("%+.2f display rounding", rounding / 100) end
    parts[#parts + 1] = string.format("= %.2f after", after / 100)
    return table.concat(parts, " • ")
end

local function Heading(lines, title, rich)
    if #lines > 0 then Add(lines, "") end
    Add(lines, rich and ("|cffd9b36c" .. title .. "|r") or ("== " .. title .. " =="))
end



local function AddFinalValidation(lines, support)
    local initial, final = support.phaseDInitial or {}, support.phaseDFinal or {}
    local status = tostring(support.finalValidationStatus or final.status or "CLEAN")
    local passes = tonumber(support.repairPasses) or 0
    local suffix = status == "REPAIRED" and string.format(" • %d pass%s", passes, passes == 1 and "" or "es") or ""
    Add(lines, "Final validation: " .. status .. suffix)
    if support.phaseDInitial or support.phaseDFinal then
        Add(lines, string.format("Final mismatch: %s → %s / %s", F(initial.mismatchUsed, 2), F(final.mismatchUsed, 2), F(final.mismatchBudget or initial.mismatchBudget or 2, 2)))
        Add(lines, string.format("Maximum severity: %s → %s / %s", F(initial.maximumSeverity, 3), F(final.maximumSeverity, 3), F(final.severityThreshold or initial.severityThreshold or 0.72, 2)))
        Add(lines, string.format("Palette families: %d → %d / %d", tonumber(initial.paletteFamilies) or 0, tonumber(final.paletteFamilies) or 0, tonumber(final.paletteLimit or initial.paletteLimit) or 3))
        Add(lines, string.format("Zero-echo loud accents: %d → %d • repairable outliers: %d → %d • protected locked violations: %d", tonumber(initial.repairableZeroEcho) or 0, tonumber(final.repairableZeroEcho) or 0, tonumber(initial.repairableOutliers) or 0, tonumber(final.repairableOutliers) or 0, tonumber(final.protectedLockedViolations) or 0))
    end
    for _, repair in ipairs(support.repairs or {}) do
        local definition = QC.Wardrobe and QC.Wardrobe.GetSlotDefinition and QC.Wardrobe.GetSlotDefinition(repair.slotKey)
        local label = definition and definition.label or repair.slotKey or "Unknown"
        Add(lines, string.format("Repair pass %d: %s • %s → %s", tonumber(repair.pass) or 0, tostring(label), tostring(repair.previousName or "None"), tostring(repair.replacementName or "None")))
        Add(lines, string.format("  Trigger: %s • severity %s → %s • mismatch %s → %s • palettes %d → %d • cohesion %s → %s", tostring(repair.trigger or "final validation"), F(repair.severityBefore, 3), F(repair.severityAfter, 3), F(repair.mismatchBefore, 2), F(repair.mismatchAfter, 2), tonumber(repair.paletteBefore) or 0, tonumber(repair.paletteAfter) or 0, F(repair.cohesionBefore, 3), F(repair.cohesionAfter, 3)))
    end
    if support.alternateSkeleton then Add(lines, "Skeleton fallback: alternate Phase B finalist used after support repair exhaustion") end
end

local function AnchorMaskText(mask)
    local labels = { CHEST = "Chest", LEGS = "Legs", SHOULDER = "Shoulders", WEAPON = "Weapon bundle" }
    local parts = {}
    for _, key in ipairs({ "CHEST", "LEGS", "SHOULDER", "WEAPON" }) do
        local entry = mask and mask[key] or {}
        local state = tostring(entry.state or "UNAVAILABLE")
        state = state:sub(1, 1) .. state:sub(2):lower()
        parts[#parts + 1] = tostring(labels[key]) .. " " .. state
    end
    return table.concat(parts, " • ")
end

local function SourceText(decision, rawIDs)
    local text = tostring(decision.name or "None")
    if decision.locked then text = text .. " [Locked]"
    elseif decision.contextFixed then text = text .. " [Context Fixed]"
    elseif decision.targetRerolled then text = text .. " [Rerolled]" end
    if rawIDs then
        local ids = {}
        if decision.visualID then ids[#ids + 1] = "visual " .. tostring(decision.visualID) end
        if decision.sourceID then ids[#ids + 1] = "source " .. tostring(decision.sourceID) end
        if decision.itemID then ids[#ids + 1] = "item " .. tostring(decision.itemID) end
        if #ids > 0 then text = text .. " {" .. table.concat(ids, ", ") .. "}" end
    end
    return text
end

function P.AddSupportSection(lines, report, rawIDs, rich)
    Heading(lines, "Contextual Support", rich)
    local support = report.support
    if not support then Add(lines, "Contextual support data: Not recorded by this version") return end
    if support.targetSlotKey then
        local definition = QC.Wardrobe and QC.Wardrobe.GetSlotDefinition and QC.Wardrobe.GetSlotDefinition(support.targetSlotKey)
        local targetLabel = definition and definition.label or support.targetSlotKey
        Add(lines, "Target slot: " .. tostring(targetLabel))
        Add(lines, "Previous appearance: " .. tostring(support.previousTargetName or "None"))
        Add(lines, string.format("Profile phase: %s%s", support.profileRepaired and "Repaired" or (support.profileReused and "Reused" or "Derived"), support.profileMigrated and " • legacy profile migrated" or ""))
        Add(lines, "Profile ID: " .. tostring(support.profileID or (support.profile and support.profile.profileID) or "Unknown"))
        Add(lines, "Profile source report: " .. tostring(support.profileSourceReportID or (support.profile and support.profile.profileSourceReportID) or "Unknown"))
        Add(lines, "Target budget: " .. BudgetEquation(support))
        Add(lines, "Budget reconciliation: " .. (support.budgetReconciled == false and "Failed" or "Pass"))
        if support.profileRepaired then Add(lines, "Profile repair: " .. tostring(support.profileRepairReason or "Inherited profile did not match the canonical anchor state")) end
        Add(lines, string.format("Fixed contextual slots: %d%s", tonumber(support.fixedContextCount) or 0, support.noAlternative and " • no legal alternative" or ""))
    end
    local profile = support.profile or {}
    local centers = profile.centers or {}
    Add(lines, string.format("Profile: %d active anchors • cohesion %s", tonumber(profile.activeAnchorCount) or 0, F(profile.meanAnchorCohesion, 3)))
    if profile.activeAnchorMask then Add(lines, "Active-anchor mask: " .. AnchorMaskText(profile.activeAnchorMask)) end
    local anchorLabels = {}
    for _, anchor in ipairs(profile.activeAnchors or {}) do anchorLabels[#anchorLabels + 1] = tostring(anchor.label or anchor.slotKey) end
    if #anchorLabels > 0 then Add(lines, "Active anchors: " .. table.concat(anchorLabels, ", ")) end
    Add(lines, string.format("Centers: palette %s • material %s • finish %s • motif %s • weight %s", tostring(centers.palette or "unknown"), tostring(centers.material or "unknown"), tostring(centers.finish or "unknown"), tostring(centers.motif or "unknown"), F(centers.visualWeight, 2)))
    if profile.weakestRelationship then Add(lines, string.format("Weakest anchor relationship: %s ↔ %s (%s)", tostring(profile.weakestRelationship.left), tostring(profile.weakestRelationship.right), F(profile.weakestRelationship.score, 3))) end
    local tolerance, confidence = profile.tolerance or {}, profile.confidence or {}
    Add(lines, string.format("Tolerance: palette %s • material %s • finish %s • weight %s • motif %s • provenance %s", F(tolerance.palette, 3), F(tolerance.material, 3), F(tolerance.finish, 3), F(tolerance.visualWeight, 3), F(tolerance.motif, 3), F(tolerance.provenance, 3)))
    Add(lines, string.format("Confidence: palette %s • material %s • finish %s • weight %s • motif %s • provenance %s", F(confidence.palette, 3), F(confidence.material, 3), F(confidence.finish, 3), F(confidence.visualWeight, 3), F(confidence.motifs, 3), F(confidence.provenance, 3)))
    Add(lines, string.format("Budget: %s start • %s locked • %s generated • %s borrowed • %s overrun • %s remaining", F(support.startingBudget, 2), F(support.lockedCommitment, 2), F(support.generatedSpend, 2), F(support.borrowed, 2), F(support.overrun, 2), F(support.remainingBudget, 2)))
    Add(lines, string.format("Configuration: rank %d/%d • score %s • whole-outfit cohesion %s • accents %d • outliers %d • fallbacks %d • empty %d", support.chosenRank or 0, support.shortlistSize or 0, F(support.configurationScore, 1), F(support.wholeOutfitCohesion, 3), support.controlledAccents or 0, support.outliers or 0, support.fallbackSlots or 0, support.emptySlots or 0))
    AddFinalValidation(lines, support)
    Add(lines, string.format("Support beam: %d deduplicated • %d budget rejects", support.deduplicated or 0, support.budgetRejections or 0))
    for _, slotKey in ipairs(QC.Wardrobe and QC.Wardrobe._Private and QC.Wardrobe._Private.SUPPORT_SLOT_ORDER or {}) do
        if support.poolSizes and support.poolSizes[slotKey] then Add(lines, string.format("  %s: %d prepared • %d expanded • %d retained", slotKey, support.poolSizes[slotKey] or 0, support.expansions and support.expansions[slotKey] or 0, support.retained and support.retained[slotKey] or 0)) end
    end
    for _, decision in ipairs(support.decisions or {}) do
        Add(lines, string.format("%s: %s", tostring(decision.slotLabel or decision.slotKey), SourceText(decision, rawIDs)))
        Add(lines, string.format("  Role: %s • profile %s • neighbor %s • bridge bonus %s • mismatch %s • %s • %s • repeat %s%s", tostring(decision.role or "Support"), F(decision.profileFit, 3), F(decision.neighborCohesion, 3), F(decision.bridgeBonus, 2), F(decision.mismatchSpent, 2), tostring(decision.budgetState or "WITHIN"), tostring(decision.outlierState or "NORMAL"), F(decision.repeatPenalty, 2), decision.fallback and " • fallback" or ""))
        if decision.finalMismatchClass or decision.repaired or decision.protectedByLock then
            Add(lines, string.format("  Final: %s • echo %s • severity %s%s%s", tostring(decision.finalMismatchClass or "COHESIVE"), F(decision.echoSupport, 3), F(decision.outlierSeverity, 3), decision.repaired and (" • repaired pass " .. tostring(decision.repairPass or "?")) or "", decision.protectedByLock and " • protected by lock" or ""))
        end
        if decision.bridgeTarget then
            local improved = decision.bridgeImprovement == true or ((tonumber(decision.bridgeAfter) or 0) - (tonumber(decision.bridgeBefore) or 0)) > 0.005
            if improved then
                Add(lines, string.format("  Bridge improvement: %s • %s → %s • bonus +%s", tostring(decision.bridgeTarget), F(decision.bridgeBefore, 3), F(decision.bridgeAfter, 3), F(decision.bridgeBonus, 2)))
            else
                Add(lines, string.format("  Relationship: %s • %s → %s • bridge bonus None", tostring(decision.bridgeTarget), F(decision.bridgeBefore, 3), F(decision.bridgeAfter, 3)))
            end
        end
    end
    if #(support.excluded or {}) > 0 then Add(lines, "Excluded: " .. table.concat(support.excluded, ", ")) else Add(lines, "Excluded: None") end
end

function P.AddSupportComparisonLines(lines, comparison)
    if not comparison or not comparison.supportChanged then return end
    Add(lines, "Support changed: " .. (#comparison.supportChanged > 0 and table.concat(comparison.supportChanged, ", ") or "None"))
    Add(lines, "Support unchanged: " .. (#comparison.supportUnchanged > 0 and table.concat(comparison.supportUnchanged, ", ") or "None"))
    Add(lines, "Support excluded: " .. (#comparison.supportExcluded > 0 and table.concat(comparison.supportExcluded, ", ") or "None"))
    Add(lines, string.format("Support mismatch: %.2f → %.2f", tonumber(comparison.previousMismatch) or 0, tonumber(comparison.mismatch) or 0))
    Add(lines, string.format("Whole-outfit cohesion: %.3f → %.3f", tonumber(comparison.previousWholeOutfitCohesion) or 0, tonumber(comparison.wholeOutfitCohesion) or 0))
    Add(lines, string.format("Support outliers: %d → %d", tonumber(comparison.previousOutliers) or 0, tonumber(comparison.outliers) or 0))
end
