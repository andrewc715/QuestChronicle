local QC = QuestChronicle

QC.ZoneStyle = QC.ZoneStyle or {}
local ZoneStyle = QC.ZoneStyle

ZoneStyle.MODE_ZONE_NATIVE = "ZONE_NATIVE"
ZoneStyle.MODE_TRAVELER = "TRAVELER"
ZoneStyle.MODE_CLASS_FANTASY = "CLASS_FANTASY"

ZoneStyle.modes = {
    { key = ZoneStyle.MODE_ZONE_NATIVE, label = "Zone Native", shortLabel = "Zone Native", description = "Favor the culture, climate, magic, and materials of the current zone profile." },
    { key = ZoneStyle.MODE_TRAVELER, label = "Traveler", shortLabel = "Traveler", description = "Favor practical, weathered, expedition-ready appearances with a lighter touch of local style." },
    { key = ZoneStyle.MODE_CLASS_FANTASY, label = "Class Fantasy", shortLabel = "Class Fantasy", description = "Favor iconic class themes while borrowing a smaller accent from the current zone." },
}

local modeByKey = {}
for _, mode in ipairs(ZoneStyle.modes) do
    modeByKey[mode.key] = mode
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h, i = pcall(func, ...)
    if ok then return a, b, c, d, e, f, g, h, i end
end

local function Normalize(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("[’']", "")
    text = text:gsub("[^%w]+", " ")
    return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
end

local travelerKeywords = {
    traveler = 10, travelling = 8, wanderer = 9, wayfarer = 10, expedition = 9,
    explorer = 9, scout = 8, ranger = 7, trail = 7, pathfinder = 9, outpost = 5,
    field = 5, campaign = 5, rugged = 8, weathered = 8, worn = 5, battered = 5,
    sturdy = 7, reinforced = 5, leather = 4, hide = 4, fur = 4, cloak = 4,
    pack = 6, pouch = 5, belt = 4, boots = 5, hood = 5, torch = 4, compass = 7,
}

local travelerAvoid = {
    throne = -5, coronation = -5, ceremonial = -4, jeweled = -3, cosmic = -3,
    infinite = -3, apocalypse = -5, annihilator = -4,
}

local classKeywords = {
    [1] = { warrior = 10, war = 5, battle = 7, gladiator = 9, soldier = 7, valor = 8, arsenal = 6, armageddon = 7, berserker = 8, colossus = 7 },
    [2] = { paladin = 10, holy = 8, light = 7, radiant = 7, crusader = 9, judgment = 9, templar = 8, silver = 4, hand = 3, dawn = 5 },
    [3] = { hunter = 10, hunt = 7, ranger = 9, beast = 7, stalker = 8, marksman = 9, wild = 5, tracker = 8, sentinel = 6 },
    [4] = { rogue = 10, assassin = 9, shadow = 7, silent = 7, poison = 7, venom = 7, blade = 5, night = 5, skulker = 7 },
    [5] = { priest = 10, holy = 7, divine = 8, faith = 7, absolution = 9, oracle = 7, shadow = 6, void = 5, confessor = 7 },
    [6] = { death = 7, scourge = 9, necrotic = 9, ebon = 9, runed = 7, frost = 6, grave = 7, lich = 8, saronite = 8 },
    [7] = { shaman = 10, element = 8, storm = 8, earth = 7, flame = 7, spirit = 7, wolf = 7, tide = 6, thunder = 8 },
    [8] = { mage = 10, arcane = 9, spell = 7, frost = 6, fire = 6, phoenix = 7, sorcerer = 8, magister = 9, chronomancer = 7 },
    [9] = { warlock = 10, fel = 9, demon = 8, shadow = 6, hell = 7, corrupt = 7, diabolic = 8, infernal = 8, dread = 6 },
    [10] = { monk = 10, zen = 8, tiger = 7, crane = 7, ox = 7, serpent = 7, brewmaster = 8, mist = 6, august = 6 },
    [11] = { druid = 10, nature = 7, wild = 6, grove = 8, thorn = 7, dream = 7, moon = 7, cenarion = 9, antler = 6 },
    [12] = { demon = 8, fel = 9, illidari = 10, warglaive = 10, glaive = 7, vengeance = 7, havoc = 7, abyss = 6 },
    [13] = { evoker = 10, dragon = 9, draconic = 9, scale = 7, obsidian = 7, bronze = 6, azure = 6, emerald = 6, ruby = 6 },
}

ZoneStyle.profiles = {
    quelthalas = {
        label = "Quel'Thalas",
        seed = 101,
        match = { "silvermoon", "eversong", "ghostlands", "quel danas", "sunwell", "magisters terrace", "murder row", "windrunner spire", "quelthalas" },
        keywords = { sun = 8, sunwell = 12, phoenix = 10, dawn = 7, radiant = 8, golden = 8, gold = 6, crimson = 7, scarlet = 5, blood = 5, sindorei = 12, spellbreaker = 11, magister = 10, runic = 6, arcane = 7, falcon = 6, hawkstrider = 8, light = 5 },
        avoid = { crude = -4, rusted = -3, savage = -3 },
        description = "Radiant elven craft, Sunwell magic, crimson and gold, phoenix and magister motifs.",
    },
    amani = {
        label = "Amani Highlands",
        seed = 131,
        match = { "zul aman", "atal aman", "amani", "nalorakk", "maisara", "shadebasin", "torntusk", "stonewash" },
        keywords = { amani = 13, troll = 9, loa = 10, forest = 6, tribal = 8, totem = 8, tusk = 8, fang = 8, lynx = 9, bear = 7, eagle = 7, dragonhawk = 9, hex = 8, voodoo = 8, moss = 5, pine = 5 },
        avoid = { polished = -2, imperial = -3 },
        description = "Amani forest craft, loa iconography, fangs, tusks, totems, and mountain-weathered materials.",
    },
    harandar = {
        label = "Harandar Rootways",
        seed = 151,
        match = { "harandar", "har athir", "har mara", "har kuai", "dreamrift", "sporefall", "rootway", "gulf of memory", "grudge pit" },
        keywords = { haranir = 13, root = 9, fungal = 10, fungus = 9, spore = 10, bloom = 8, bioluminescent = 11, luminous = 7, primal = 8, ancient = 6, vine = 8, moss = 6, bark = 7, dream = 6, memory = 5 },
        avoid = { mechanical = -5, industrial = -5, polished = -2 },
        description = "Bioluminescent fungal growth, world-tree roots, primal guardianship, vines, bark, and living materials.",
    },
    voidstorm = {
        label = "The Voidstorm",
        seed = 181,
        match = { "voidstorm", "voidspire", "sunkiller", "shadowguard point", "torments rise", "locus point", "the ingress" },
        keywords = { void = 12, cosmic = 9, abyss = 9, shadow = 7, twilight = 7, star = 6, astral = 8, hunger = 6, devour = 8, entropy = 8, dark = 4, rendorei = 12, ethereal = 8, rift = 8 },
        avoid = { pastoral = -5, rustic = -4, harvest = -3 },
        description = "Void-touched cosmic armor, rifts, stars, shadow, entropy, and ren'dorei aesthetics.",
    },
    hallowfall = {
        label = "Hallowfall",
        seed = 211,
        match = { "hallowfall", "mereldar", "priory of the sacred flame", "dawnbreaker" },
        keywords = { light = 8, radiant = 8, sacred = 9, flame = 7, dawn = 8, arathi = 11, templar = 8, lamplighter = 9, beacon = 8, holy = 7, gold = 5 },
        avoid = { void = -5, necrotic = -5 },
        description = "Arathi plate, sacred flame, lamplighter tools, beacons, and radiant expedition gear.",
    },
    khazalgar = {
        label = "Khaz Algar",
        seed = 241,
        match = { "isle of dorn", "dornogal", "ringing deeps", "azj kahet", "khaz algar", "undermine", "kaheti" },
        keywords = { earthen = 11, stone = 8, forge = 8, forged = 7, titan = 8, machine = 6, cog = 6, iron = 6, deep = 5, nerubian = 9, web = 7, chitin = 7, cartel = 6, undermine = 8 },
        avoid = { delicate = -2 },
        description = "Earthen stonework, deep-forge industry, titan craft, nerubian chitin, and subterranean utility.",
    },
    dragonisles = {
        label = "Dragon Isles",
        seed = 271,
        match = { "dragon isles", "valdrakken", "waking shores", "ohn ahran", "azure span", "thaldraszus", "zaralek", "forbidden reach", "emerald dream" },
        keywords = { dragon = 10, draconic = 10, scale = 8, obsidian = 7, ruby = 7, azure = 7, bronze = 7, emerald = 7, primal = 6, aspect = 8, flight = 6, titan = 5 },
        avoid = {},
        description = "Dragonflight scales, elemental primalism, titan craft, and the colors of the great flights.",
    },
    kaldorei = {
        label = "Kaldorei Wilds",
        seed = 307,
        match = { "teldrassil", "darkshore", "ashenvale", "hyjal", "valsharah", "val sharah", "amirdrassil", "belameth", "bel ameth", "moonglade" },
        keywords = { kaldorei = 12, moon = 9, lunar = 8, star = 7, sentinel = 8, warden = 8, huntress = 8, owl = 6, leaf = 7, grove = 7, ancient = 5, emerald = 6, dream = 7 },
        avoid = { industrial = -5, fel = -4 },
        description = "Moonlit kaldorei craft, sentinel and warden silhouettes, leaves, stars, and ancient groves.",
    },
    zandalar = {
        label = "Zandalar",
        seed = 337,
        match = { "zuldazar", "nazmir", "voldun", "vol dun", "dazaralor", "dazar alor", "atal dazar", "zandalar" },
        keywords = { zandalari = 12, troll = 8, loa = 10, gold = 6, dinosaur = 8, raptor = 8, serpent = 6, blood = 5, bone = 6, tusk = 7, voodoo = 6 },
        avoid = {},
        description = "Zandalari goldwork, loa symbols, dinosaur scales, ritual bone, and imperial troll craft.",
    },
    kultiras = {
        label = "Kul Tiras",
        seed = 367,
        match = { "boralus", "tiragarde", "drustvar", "stormsong", "kul tiras", "tol dagor" },
        keywords = { ["kul tiran"] = 11, marine = 8, admiral = 9, tide = 8, sea = 7, sailor = 8, harpoon = 7, storm = 6, drust = 8, wicker = 8, anchor = 8, nautical = 8 },
        avoid = {},
        description = "Maritime uniforms, storm and tide motifs, Drust wickerwork, anchors, and practical seafaring layers.",
    },
    pandaria = {
        label = "Pandaria",
        seed = 397,
        match = { "jade forest", "valley of the four winds", "kun lai", "townlong", "dread wastes", "vale of eternal blossoms", "timeless isle", "pandaria" },
        keywords = { pandaren = 11, jade = 9, lotus = 9, cloud = 6, tiger = 7, crane = 7, ox = 7, serpent = 7, bamboo = 7, brew = 7, sha = 6, mogu = 7 },
        avoid = {},
        description = "Jade, celestial animals, bamboo, lotus, mogu stonework, and practical wandering-isle layers.",
    },
    northrend = {
        label = "Northrend",
        seed = 421,
        match = { "borean tundra", "howling fjord", "dragonblight", "grizzly hills", "zul drak", "sholazar", "storm peaks", "icecrown", "wintergrasp", "northrend", "dalaran crater" },
        keywords = { frost = 9, ice = 8, snow = 7, fur = 7, vrykul = 9, tuskarr = 8, titan = 6, saronite = 8, scourge = 7, winter = 7, runed = 6, northern = 5 },
        avoid = { tropical = -5 },
        description = "Cold-weather furs, vrykul runes, titan relics, saronite, ice, and expedition armor.",
    },
    outland = {
        label = "Outland",
        seed = 449,
        match = { "hellfire peninsula", "zangarmarsh", "terokkar", "nagrand", "blades edge", "blade s edge", "netherstorm", "shadowmoon valley", "shattrath", "outland" },
        keywords = { outland = 10, fel = 7, nether = 9, ethereal = 8, draenei = 8, crystal = 7, shattered = 7, maghar = 7, spore = 6, naaru = 8, demon = 5 },
        avoid = {},
        description = "Shattered-world survival gear, nether and crystal motifs, draenei relics, fel scars, and ethereal craft.",
    },
    shadowlands = {
        label = "Shadowlands",
        seed = 479,
        match = { "oribos", "bastion", "maldraxxus", "ardenweald", "revendreth", "the maw", "korthia", "zereth mortis", "shadowlands" },
        keywords = { anima = 10, covenant = 8, soul = 7, kyrian = 9, necrolord = 9, ["night fae"] = 9, venthyr = 9, maw = 7, runecarver = 7, eternal = 6 },
        avoid = {},
        description = "Anima-bound covenant craft, soul magic, eternal runes, and the silhouettes of the realms of Death.",
    },
    human = {
        label = "Human Kingdoms",
        seed = 509,
        match = { "stormwind", "elwynn", "westfall", "redridge", "duskwood", "deadwind", "arathi highlands", "gilneas", "lordaeron" },
        keywords = { alliance = 8, lion = 9, knight = 8, guard = 6, stormwind = 11, arathi = 8, gilnean = 8, royal = 6, footman = 8, gryphon = 7 },
        avoid = { fel = -4 },
        description = "Knightly plate, royal heraldry, lion and gryphon motifs, militia layers, and kingdom-made arms.",
    },
    orcish = {
        label = "Orcish Frontier",
        seed = 541,
        match = { "orgrimmar", "durotar", "barrens", "mulgore", "frostfire ridge", "gorgrond", "warsong", "nagrand draenor" },
        keywords = { horde = 7, orc = 9, warsong = 10, frostwolf = 9, iron = 6, spike = 6, savage = 6, clan = 7, wolf = 7, bone = 5, gronn = 6 },
        avoid = { delicate = -3 },
        description = "Orcish clan identity, iron and hide, wolves, bones, spikes, and frontier war gear.",
    },
    forsaken = {
        label = "Forsaken Marches",
        seed = 571,
        match = { "tirisfal", "undercity", "silverpine", "hillsbrad foothills", "western plaguelands", "eastern plaguelands" },
        keywords = { forsaken = 11, blight = 9, plague = 8, apothecary = 9, dark = 5, death = 6, skull = 6, bat = 6, royal = 4, lordaeron = 7, shadow = 5 },
        avoid = { radiant = -3 },
        description = "Forsaken apothecary gear, blight, plague, ruined Lordaeron heraldry, dark leathers, and bone.",
    },
    azeroth = {
        label = "Azeroth Adventurer",
        seed = 601,
        match = {},
        keywords = { adventurer = 8, champion = 5, azeroth = 8, explorer = 6, expedition = 6, heroic = 4, defender = 5, guardian = 5 },
        avoid = {},
        description = "A flexible adventurer profile used when no more specific cultural or environmental profile matches.",
    },
}

local profileOrder = {
    "quelthalas", "amani", "harandar", "voidstorm", "hallowfall", "khazalgar",
    "dragonisles", "kaldorei", "zandalar", "kultiras", "pandaria", "northrend",
    "outland", "shadowlands", "human", "orcish", "forsaken",
}

local function GetStyleState()
    local ui = QC.GetUIState()
    ui.outfits = ui.outfits or {}
    ui.outfits.styleMode = modeByKey[ui.outfits.styleMode] and ui.outfits.styleMode or ZoneStyle.MODE_ZONE_NATIVE
    ui.zoneStyle = ui.zoneStyle or {}
    return ui.zoneStyle, ui.outfits
end

function ZoneStyle.NormalizeMode(modeKey)
    return modeByKey[modeKey] and modeKey or ZoneStyle.MODE_ZONE_NATIVE
end

function ZoneStyle.GetMode()
    local _, outfits = GetStyleState()
    return ZoneStyle.NormalizeMode(outfits.styleMode)
end

function ZoneStyle.SetMode(modeKey)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    local _, outfits = GetStyleState()
    if outfits.styleMode == modeKey then return true, modeByKey[modeKey].label end
    outfits.styleMode = modeKey
    outfits.selectedConceptID = nil
    if QC.Notify then QC.Notify("ZONE_STYLE_MODE_CHANGED", modeKey) end
    return true, modeByKey[modeKey].label
end

function ZoneStyle.GetModeInfo(modeKey)
    return modeByKey[ZoneStyle.NormalizeMode(modeKey)]
end

local function BuildMapTrail(mapID)
    local names = {}
    local seen = {}
    local current = mapID
    for _ = 1, 7 do
        if not current or seen[current] then break end
        seen[current] = true
        local info = SafeCall(C_Map and C_Map.GetMapInfo, current)
        if not info then break end
        if info.name and info.name ~= "" then table.insert(names, info.name) end
        current = info.parentMapID
    end
    return names
end

function ZoneStyle.DetectContext()
    local mapID = SafeCall(C_Map and C_Map.GetBestMapForUnit, "player")
    local mapInfo = mapID and SafeCall(C_Map and C_Map.GetMapInfo, mapID)
    local mapTrail = BuildMapTrail(mapID)
    local zone = SafeCall(GetRealZoneText) or SafeCall(GetZoneText) or (mapInfo and mapInfo.name) or "Unknown Zone"
    local subzone = SafeCall(GetSubZoneText) or ""
    if subzone == zone then subzone = "" end
    return {
        mapID = mapID,
        mapName = mapInfo and mapInfo.name or zone,
        zone = zone,
        subzone = subzone,
        mapTrail = mapTrail,
    }
end

function ZoneStyle.ResolveProfile(context)
    context = context or ZoneStyle.DetectContext()
    local parts = { context.subzone, context.zone, context.mapName }
    for _, name in ipairs(context.mapTrail or {}) do table.insert(parts, name) end
    local haystack = " " .. Normalize(table.concat(parts, " ")) .. " "
    for _, profileKey in ipairs(profileOrder) do
        local profile = ZoneStyle.profiles[profileKey]
        for _, match in ipairs(profile.match or {}) do
            local needle = Normalize(match)
            if needle ~= "" and haystack:find(" " .. needle .. " ", 1, true) then
                return profile, profileKey
            end
        end
    end
    return ZoneStyle.profiles.azeroth, "azeroth"
end

local function ContextZoneKey(context)
    return tostring(context.mapID or Normalize(context.zone)) .. ":" .. Normalize(context.zone)
end

local function ContextDetailKey(context, profileKey)
    return ContextZoneKey(context) .. ":" .. Normalize(context.subzone) .. ":" .. tostring(profileKey)
end

function ZoneStyle.RefreshZone(force, silent)
    local state = GetStyleState()
    local context = ZoneStyle.DetectContext()
    local profile, profileKey = ZoneStyle.ResolveProfile(context)
    context.profileKey = profileKey
    context.profileLabel = profile.label
    context.profileDescription = profile.description
    context.zoneKey = ContextZoneKey(context)
    context.detailKey = ContextDetailKey(context, profileKey)

    local previous = state.currentContext
    local zoneChanged = force == true or not previous or previous.zoneKey ~= context.zoneKey or previous.profileKey ~= profileKey
    local detailChanged = zoneChanged or not previous or previous.detailKey ~= context.detailKey
    state.currentContext = context

    if zoneChanged then
        state.pendingSuggestion = {
            mapID = context.mapID,
            zone = context.zone,
            subzone = context.subzone,
            profileKey = profileKey,
            profileLabel = profile.label,
            createdAt = time and time() or 0,
            unread = true,
        }
        if QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION", state.pendingSuggestion, context) end
        if not silent and QC.Print then
            QC.Print(string.format("New Zone Native outfit suggestion: %s (%s). Open Outfits to preview it.", context.zone, profile.label))
        end
    elseif detailChanged and QC.Notify then
        QC.Notify("ZONE_STYLE_CONTEXT_CHANGED", context)
    end
    return context, zoneChanged
end

function ZoneStyle.GetCurrentContext()
    local state = GetStyleState()
    if not state.currentContext then
        return ZoneStyle.RefreshZone(true, true)
    end
    return state.currentContext
end

function ZoneStyle.GetCurrentProfile()
    local context = ZoneStyle.GetCurrentContext()
    return ZoneStyle.profiles[context.profileKey] or ZoneStyle.profiles.azeroth, context.profileKey, context
end

function ZoneStyle.GetPendingSuggestion()
    local state = GetStyleState()
    return state.pendingSuggestion
end

function ZoneStyle.AcknowledgeSuggestion()
    local state = GetStyleState()
    if state.pendingSuggestion and state.pendingSuggestion.unread then
        state.pendingSuggestion.unread = false
        if QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION_ACKNOWLEDGED", state.pendingSuggestion) end
    end
end

function ZoneStyle.ConsumeSuggestion()
    local state = GetStyleState()
    local suggestion = state.pendingSuggestion
    state.pendingSuggestion = nil
    if suggestion and QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION_CONSUMED", suggestion) end
    return suggestion
end

local function SourceMetadata(source)
    if not source then return "" end
    local parts = {}
    local function AddPart(value)
        if value ~= nil and tostring(value) ~= "" then
            table.insert(parts, tostring(value))
        end
    end

    AddPart(source.name)
    AddPart(source.styleItemLink)

    local genericName = not source.name or tostring(source.name):match("^Appearance %d+$")
    if genericName and source.itemID then
        local itemName = SafeCall(C_Item and C_Item.GetItemNameByID, source.itemID)
        if not itemName and type(GetItemInfo) == "function" then
            local ok, name, link, quality, _, _, itemType, itemSubType, _, equipLocation = pcall(GetItemInfo, source.itemID)
            if ok then
                itemName = name
                source.styleItemLink = link or source.styleItemLink
                source.quality = source.quality or quality
                AddPart(itemType)
                AddPart(itemSubType)
                AddPart(equipLocation)
            end
        end
        if itemName then
            source.styleName = itemName
            source.name = itemName
        elseif C_Item and C_Item.RequestLoadItemDataByID then
            SafeCall(C_Item.RequestLoadItemDataByID, source.itemID)
        end
    end

    AddPart(source.styleName)
    AddPart(source.styleItemLink)
    return Normalize(table.concat(parts, " "))
end

local function AddKeywordScore(text, keywords, multiplier, reasons, reasonPrefix)
    local score = 0
    local padded = " " .. text .. " "
    for token, value in pairs(keywords or {}) do
        local normalizedToken = Normalize(token)
        if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
            local contribution = value * multiplier
            score = score + contribution
            if contribution > 0 and #reasons < 4 then
                table.insert(reasons, (reasonPrefix or "") .. token)
            end
        end
    end
    return score
end

local function StableAffinity(source, profile, modeKey, classID)
    local identity = tonumber(source.visualID or source.sourceID or source.itemID) or 1
    local modeSeed = modeKey == ZoneStyle.MODE_TRAVELER and 37 or (modeKey == ZoneStyle.MODE_CLASS_FANTASY and 73 or 11)
    local value = (identity * 1103515245 + (profile.seed or 1) * 12345 + (classID or 0) * 7919 + modeSeed) % 2147483647
    return (value / 2147483647) * 3.0
end

function ZoneStyle.ScoreSource(source, definition, modeKey, context)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    context = context or ZoneStyle.GetCurrentContext()
    local profile = ZoneStyle.profiles[context.profileKey] or ZoneStyle.profiles.azeroth
    local classID
    if type(UnitClass) == "function" then
        local _, _, resolvedClassID = UnitClass("player")
        classID = resolvedClassID
    end
    local classProfile = classKeywords[classID] or {}
    local text = SourceMetadata(source)
    local reasons = {}
    local score = 10

    if modeKey == ZoneStyle.MODE_ZONE_NATIVE then
        score = score + AddKeywordScore(text, profile.keywords, 1.35, reasons, "Local: ")
        score = score + AddKeywordScore(text, profile.avoid, 1.0, reasons)
        score = score + AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + AddKeywordScore(text, travelerKeywords, 0.12, reasons, "Travel: ")
        if definition and (definition.key == "BACK" or definition.key == "TABARD") then score = score + 1.2 end
    elseif modeKey == ZoneStyle.MODE_TRAVELER then
        score = score + AddKeywordScore(text, travelerKeywords, 1.25, reasons, "Travel: ")
        score = score + AddKeywordScore(text, travelerAvoid, 1.0, reasons)
        score = score + AddKeywordScore(text, profile.keywords, 0.28, reasons, "Local: ")
        score = score + AddKeywordScore(text, classProfile, 0.16, reasons, "Class: ")
        if definition and (definition.key == "BACK" or definition.key == "WAIST" or definition.key == "FEET" or definition.key == "SHIRT") then score = score + 2.0 end
    else
        score = score + AddKeywordScore(text, classProfile, 1.35, reasons, "Class: ")
        score = score + AddKeywordScore(text, profile.keywords, 0.24, reasons, "Local: ")
        score = score + AddKeywordScore(text, travelerKeywords, 0.10, reasons, "Travel: ")
        if definition and (definition.weaponRole or definition.key == "HEAD" or definition.key == "SHOULDER" or definition.key == "CHEST") then score = score + 2.0 end
        score = score + math.min(2.0, tonumber(source.quality or 0) * 0.35)
    end

    score = score + StableAffinity(source, profile, modeKey, classID)
    return score, reasons
end

function ZoneStyle.WeightForSource(source, definition, modeKey, context)
    local score = ZoneStyle.ScoreSource(source, definition, modeKey, context)
    return math.max(1, score + 4) ^ 2, score
end

function ZoneStyle.ChooseWeightedSource(candidates, definition, modeKey, context, excludeSourceID)
    local pool = {}
    local total = 0
    local fallback
    for _, source in ipairs(candidates or {}) do
        local weight, score = ZoneStyle.WeightForSource(source, definition, modeKey, context)
        local entry = { source = source, weight = weight, score = score }
        if source.sourceID == excludeSourceID then
            fallback = entry
        else
            total = total + weight
            table.insert(pool, entry)
        end
    end
    if #pool == 0 then
        return fallback and fallback.source, fallback and fallback.score
    end
    local roll = math.random() * total
    for _, entry in ipairs(pool) do
        roll = roll - entry.weight
        if roll <= 0 then return entry.source, entry.score end
    end
    local entry = pool[#pool]
    return entry.source, entry.score
end

function ZoneStyle.OrderWeaponCandidates(candidates, modeKey, context)
    for _, candidate in ipairs(candidates or {}) do
        local definition = QC.Wardrobe and QC.Wardrobe.GetSlotDefinition and QC.Wardrobe.GetSlotDefinition(candidate.slotKey)
        local weight = ZoneStyle.WeightForSource(candidate.source, definition, modeKey, context)
        local roll = math.max(0.000001, math.random())
        candidate.stylePriority = math.log(roll) / weight
    end
    table.sort(candidates, function(left, right)
        return (left.stylePriority or -math.huge) > (right.stylePriority or -math.huge)
    end)
    return candidates
end

function ZoneStyle.GetScoreSummary(source, definition, modeKey, context)
    local score, reasons = ZoneStyle.ScoreSource(source, definition, modeKey, context)
    local mode = ZoneStyle.GetModeInfo(modeKey)
    local reasonText = #reasons > 0 and table.concat(reasons, ", ") or "profile affinity"
    return string.format("%s score %.1f • %s", mode.label, score, reasonText)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_MAP_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local refreshToken = 0
eventFrame:SetScript("OnEvent", function()
    refreshToken = refreshToken + 1
    local token = refreshToken
    local function Refresh()
        if token == refreshToken then ZoneStyle.RefreshZone(false, false) end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.35, Refresh) else Refresh() end
end)
