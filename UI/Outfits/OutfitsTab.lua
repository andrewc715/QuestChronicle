local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits

function UI.CreateOutfitsTab(parent)
    local context = { parent = parent }
    for _, build in ipairs(P.builders or {}) do
        build(context)
    end
    return context.pane
end
