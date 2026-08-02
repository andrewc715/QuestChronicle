local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
-- Chronicle Intelligence deliberately uses only the quest record already kept
-- by schema 2. The evidence vocabulary converts recent quest titles and
-- objectives into appearance vocabulary; no new event fields or external quest
-- database are required.
P.chronicleThemes = {
    {
        key = "alliance", label = "Alliance", kind = "faction",
        evidence = { "alliance", "stormwind", "7th legion", "seventh legion", "lion", "gryphon", "wildhammer", "dark iron", "night elf", "sentinel", "draenei", "kul tiran", "gnome" },
        appearance = { alliance = 11, stormwind = 10, lion = 8, gryphon = 8, sentinel = 6, royal = 4, silver = 4, blue = 3, defender = 4 },
        adjectives = { "Lionhearted", "Stormwind", "Alliance", "Gryphon" }, nouns = { "Vanguard", "Oath", "March", "Watch" },
    },
    {
        key = "horde", label = "Horde", kind = "faction",
        evidence = { "horde", "orgrimmar", "warsong", "frostwolf", "darkspear", "forsaken", "blood elf", "sindorei", "sin dorei", "tauren", "zandalari", "vulpera", "orc" },
        appearance = { horde = 11, orgrimmar = 10, warsong = 9, frostwolf = 9, darkspear = 8, forsaken = 7, clan = 6, wolf = 5, iron = 4 },
        adjectives = { "Horde", "Warsong", "Frostwolf", "Orgrimmar" }, nouns = { "Vanguard", "Oath", "March", "Standard" },
    },
    {
        key = "fel", label = "Burning Legion", kind = "enemy",
        evidence = { "burning legion", "legion", "demon", "demons", "eredar", "satyr", "infernal", "felguard", "felhound", "fel" },
        appearance = { fel = 12, demon = 10, demonic = 10, legion = 9, infernal = 8, chaos = 8, corrupt = 6, abyss = 5, flame = 3 },
        adjectives = { "Fel-Scarred", "Demonbane", "Legionfall", "Felsworn" }, nouns = { "Reckoning", "Hunt", "Bulwark", "Defiance" },
    },
    {
        key = "undead", label = "Undead", kind = "enemy",
        evidence = { "undead", "scourge", "necromancer", "ghoul", "skeleton", "abomination", "plague", "lich", "death knight", "cult of the damned" },
        appearance = { scourge = 11, undead = 10, death = 8, necrotic = 9, plague = 8, bone = 7, skull = 7, grave = 6, crypt = 6, ebon = 5 },
        adjectives = { "Graveworn", "Scourgebane", "Ebon", "Plagueward" }, nouns = { "Vigil", "Requiem", "Reckoning", "Guard" },
    },
    {
        key = "void", label = "Void and Old Gods", kind = "enemy",
        evidence = { "void", "old god", "old gods", "twilight cult", "twilights hammer", "cultist", "faceless", "sha", "nraqi", "n raqi" },
        appearance = { void = 12, twilight = 9, shadow = 8, abyss = 7, dark = 4, cosmic = 4, eye = 5, whisper = 6 },
        adjectives = { "Void-Touched", "Twilight", "Whisperbane", "Abyssal" }, nouns = { "Vigil", "Defiance", "Secret", "Ward" },
    },
    {
        key = "elemental", label = "Elementals", kind = "enemy",
        evidence = { "elemental", "elementals", "fire elemental", "water elemental", "earth elemental", "air elemental", "raging fire", "living flame", "wind fury" },
        appearance = { elemental = 11, flame = 7, fire = 7, storm = 7, thunder = 6, earth = 6, tide = 6, magma = 7, frost = 5 },
        adjectives = { "Element-Bound", "Stormforged", "Earthshaken", "Flameward" }, nouns = { "Concord", "Fury", "Aegis", "March" },
    },
    {
        key = "dragon", label = "Dragonkin", kind = "enemy",
        evidence = { "dragon", "dragons", "dragonkin", "drake", "drakes", "wyrm", "whelps", "black dragon", "blue dragon", "red dragon", "infinite dragonflight" },
        appearance = { dragon = 12, draconic = 11, drake = 9, wyrm = 8, scale = 7, obsidian = 5, ruby = 4, azure = 4, bronze = 4 },
        adjectives = { "Dragonsworn", "Scale-Bound", "Wyrmward", "Drakeforged" }, nouns = { "Aegis", "Legacy", "Vigil", "Roar" },
    },
    {
        key = "beast", label = "Wild Beasts", kind = "enemy",
        evidence = { "beast", "beasts", "wildlife", "wolf", "wolves", "bear", "boar", "raptor", "spider", "moth", "basilisk", "ravager" },
        appearance = { beast = 10, hunt = 7, hunter = 6, wild = 7, wolf = 6, bear = 6, hide = 6, fur = 6, fang = 6, claw = 6 },
        adjectives = { "Wild", "Beaststalker", "Fang-Bound", "Trailworn" }, nouns = { "Hunt", "Prowl", "Trail", "Instinct" },
    },
    {
        key = "troll", label = "Troll Tribes", kind = "enemy",
        evidence = { "troll", "trolls", "amani", "gurubashi", "drakkari", "sandfury", "bloodscalp", "skullsplitter", "zandalari" },
        appearance = { troll = 11, amani = 10, voodoo = 9, hex = 8, loa = 8, tribal = 7, tusk = 6, mask = 5, jungle = 5 },
        adjectives = { "Hex-Bound", "Amani", "Loa-Touched", "Tribal" }, nouns = { "Hunt", "Vengeance", "Mask", "Oath" },
    },
    {
        key = "naga", label = "Naga", kind = "enemy",
        evidence = { "naga", "sirens", "myrmidon", "coilfang", "sea witch", "nazjatar", "azshara" },
        appearance = { naga = 12, coilfang = 10, serpent = 8, scale = 7, tide = 7, sea = 6, coral = 5, shell = 5, azshara = 7 },
        adjectives = { "Tideworn", "Serpentine", "Coilfang", "Sea-Bound" }, nouns = { "Defiance", "Wake", "Trident", "Vigil" },
    },
    {
        key = "pirate", label = "Pirates", kind = "enemy",
        evidence = { "pirate", "pirates", "buccaneer", "corsair", "freebooter", "southsea", "bloodsail", "blackwater raiders" },
        appearance = { pirate = 12, buccaneer = 10, corsair = 9, captain = 7, admiral = 7, sea = 5, tide = 4, plunder = 7, cutlass = 7 },
        adjectives = { "Corsair", "Bloodsail", "Sea-Worn", "Freebooter" }, nouns = { "Fortune", "Wake", "Raid", "Reprisal" },
    },
    {
        key = "mechanical", label = "Mechanical Forces", kind = "enemy",
        evidence = { "mechanical", "machine", "robot", "construct", "gnome", "gnomeregan", "mechagon", "venture company", "iron horde", "titan keeper" },
        appearance = { mechanical = 12, machine = 10, mechanized = 10, gear = 7, cog = 7, clockwork = 9, industrial = 7, iron = 5, titan = 6 },
        adjectives = { "Gearforged", "Clockwork", "Ironbound", "Machinist's" }, nouns = { "Bulwark", "Device", "March", "Protocol" },
    },
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
    cataclysm = {
        label = "Cataclysm Frontiers",
        seed = 463,
        match = { "mount hyjal", "vashj ir", "deepholm", "uldum", "twilight highlands", "tol barad", "molten front" },
        keywords = { elemental = 10, dragon = 8, twilight = 8, earth = 7, stone = 6, flame = 7, tide = 7, wind = 6, titan = 6, explorer = 4 },
        avoid = { cosmic = -3 },
        description = "Elemental upheaval, dragon warfare, titan ruins, twilight corruption, and hard-worn expedition gear.",
    },
    draenor = {
        label = "Draenor",
        seed = 467,
        match = { "draenor", "frostfire ridge", "shadowmoon valley draenor", "gorgrond", "talador", "spires of arak", "nagrand draenor", "tanaan jungle", "ashran" },
        keywords = { draenor = 10, clan = 8, iron = 8, primal = 7, frostwolf = 8, warsong = 7, arakkoa = 9, draenei = 7, crystal = 6, gronn = 7 },
        avoid = { cosmic = -3 },
        description = "Orc clan craft, Iron Horde industry, arakkoa relics, draenei crystalwork, and untamed primal materials.",
    },
    brokenisles = {
        label = "Broken Isles",
        seed = 471,
        match = { "broken isles", "azsuna", "valsharah", "val sharah", "highmountain", "stormheim", "suramar", "broken shore", "argus" },
        keywords = { legion = 9, fel = 7, ancient = 6, runic = 7, nightborne = 9, vrykul = 7, highmountain = 8, sentinel = 5, demon = 6, titan = 5 },
        avoid = {},
        description = "Ancient elven relics, vrykul runes, Highmountain craft, Nightborne magic, and scars of the Legion war.",
    },
    nazjatar = {
        label = "Nazjatar",
        seed = 475,
        match = { "nazjatar", "newhome", "mezzamere", "eternal palace" },
        keywords = { naga = 12, tide = 9, sea = 8, coral = 8, shell = 7, serpent = 7, azshara = 9, abyss = 6, pearl = 6 },
        avoid = { rustic = -3 },
        description = "Naga scale, coral and shell, deep-sea magic, royal Azsharan detail, and tide-worn survival gear.",
    },
    bfa = {
        label = "Fourth War",
        seed = 477,
        match = { "battle for azeroth", "arathi warfront", "darkshore warfront", "mechagon", "nazjatar" },
        keywords = { alliance = 6, horde = 6, warfront = 9, marine = 6, expedition = 6, naval = 6, azerite = 9, mechanical = 6, soldier = 6 },
        avoid = {},
        description = "Fourth War uniforms, faction heraldry, naval campaigns, Azerite arms, and expedition equipment.",
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
    easternkingdoms = {
        label = "Eastern Kingdoms Frontier",
        seed = 587,
        match = { "stranglethorn", "loch modan", "wetlands", "hinterlands", "badlands", "searing gorge", "burning steppes", "swamp of sorrows", "blasted lands" },
        keywords = { adventurer = 8, militia = 6, explorer = 6, iron = 5, leather = 4, woodland = 5, mountain = 5, frontier = 7, guard = 5 },
        avoid = { cosmic = -4 },
        description = "Old-world militia, practical frontier layers, woodland leathers, mountain iron, and road-worn adventuring kit.",
    },
    kalimdor = {
        label = "Kalimdor Wilds",
        seed = 593,
        match = { "darkshore", "ashenvale", "stonetalon", "barrens", "dustwallow", "thousand needles", "desolace", "feralas", "tanaris", "un goro", "silithus", "felwood", "winterspring", "azshara" },
        keywords = { wild = 8, tribal = 6, hide = 6, leather = 5, bone = 4, desert = 5, jungle = 5, nature = 6, expedition = 5, ancient = 4 },
        avoid = { regal = -3, cosmic = -3 },
        description = "Wildland hides, tribal craft, desert and jungle survival gear, ancient ruins, and practical expedition pieces.",
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

P.profileOrder = {
    "quelthalas", "amani", "harandar", "voidstorm", "hallowfall", "khazalgar",
    "dragonisles", "cataclysm", "draenor", "brokenisles", "kaldorei", "zandalar",
    "nazjatar", "kultiras", "pandaria", "northrend", "outland", "bfa", "shadowlands",
    "human", "orcish", "forsaken", "easternkingdoms", "kalimdor",
}

function P.GetStyleState()
    local ui = QC.GetUIState()
    ui.outfits = ui.outfits or {}
    ui.outfits.styleMode = P.modeByKey[ui.outfits.styleMode] and ui.outfits.styleMode or ZoneStyle.MODE_ZONE_NATIVE
    ui.zoneStyle = ui.zoneStyle or {}
    return ui.zoneStyle, ui.outfits
end

function ZoneStyle.NormalizeMode(modeKey)
    return P.modeByKey[modeKey] and modeKey or ZoneStyle.MODE_ZONE_NATIVE
end

function ZoneStyle.GetMode()
    local _, outfits = P.GetStyleState()
    return ZoneStyle.NormalizeMode(outfits.styleMode)
end

function ZoneStyle.SetMode(modeKey)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    local _, outfits = P.GetStyleState()
    if outfits.styleMode == modeKey then return true, P.modeByKey[modeKey].label end
    outfits.styleMode = modeKey
    outfits.selectedConceptID = nil
    if QC.Notify then QC.Notify("ZONE_STYLE_MODE_CHANGED", modeKey) end
    return true, P.modeByKey[modeKey].label
end

function ZoneStyle.GetModeInfo(modeKey)
    return P.modeByKey[ZoneStyle.NormalizeMode(modeKey)]
end

function P.BuildMapTrail(mapID)
    local names = {}
    local seen = {}
    local current = mapID
    for _ = 1, 7 do
        if not current or seen[current] then break end
        seen[current] = true
        local info = P.SafeCall(C_Map and C_Map.GetMapInfo, current)
        if not info then break end
        if info.name and info.name ~= "" then table.insert(names, info.name) end
        current = info.parentMapID
    end
    return names
end

function ZoneStyle.DetectContext()
    local mapID = P.SafeCall(C_Map and C_Map.GetBestMapForUnit, "player")
    local mapInfo = mapID and P.SafeCall(C_Map and C_Map.GetMapInfo, mapID)
    local mapTrail = P.BuildMapTrail(mapID)
    local zone = P.SafeCall(GetRealZoneText) or P.SafeCall(GetZoneText) or (mapInfo and mapInfo.name) or "Unknown Zone"
    local subzone = P.SafeCall(GetSubZoneText) or ""
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
    local haystack = " " .. P.Normalize(table.concat(parts, " ")) .. " "
    for _, profileKey in ipairs(P.profileOrder) do
        local profile = ZoneStyle.profiles[profileKey]
        for _, match in ipairs(profile.match or {}) do
            local needle = P.Normalize(match)
            if needle ~= "" and haystack:find(" " .. needle .. " ", 1, true) then
                return profile, profileKey
            end
        end
    end
    return ZoneStyle.profiles.azeroth, "azeroth"
end

function P.ContextZoneKey(context)
    return tostring(context.mapID or P.Normalize(context.zone)) .. ":" .. P.Normalize(context.zone)
end

function P.ContextDetailKey(context, profileKey)
    return P.ContextZoneKey(context) .. ":" .. P.Normalize(context.subzone) .. ":" .. tostring(profileKey)
end

function ZoneStyle.RefreshZone(force, silent)
    local state = P.GetStyleState()
    local context = ZoneStyle.DetectContext()
    local profile, profileKey = ZoneStyle.ResolveProfile(context)
    context.profileKey = profileKey
    context.profileLabel = profile.label
    context.profileDescription = profile.description
    context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    local provenance, provenanceKey = ZoneStyle.ResolveProvenance(context)
    context.provenanceKey = provenanceKey
    context.provenanceResolved = true
    context.provenanceLabel = provenance and provenance.label or context.zone
    context.zoneKey = P.ContextZoneKey(context)
    context.detailKey = P.ContextDetailKey(context, profileKey)

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
            eraMax = context.eraMax,
            eraLabel = context.eraLabel,
            provenanceKey = context.provenanceKey,
            provenanceLabel = context.provenanceLabel,
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
    local state = P.GetStyleState()
    if not state.currentContext then
        return ZoneStyle.RefreshZone(true, true)
    end
    if state.currentContext.eraMax == nil then
        state.currentContext.eraMax, state.currentContext.eraLabel, state.currentContext.eraShortLabel = ZoneStyle.ResolveEra(state.currentContext)
        local provenance, provenanceKey = ZoneStyle.ResolveProvenance(state.currentContext)
        state.currentContext.provenanceKey = provenanceKey
        state.currentContext.provenanceResolved = true
        state.currentContext.provenanceLabel = provenance and provenance.label or state.currentContext.zone
    end
    return state.currentContext
end

function ZoneStyle.GetCurrentProfile()
    local context = ZoneStyle.GetCurrentContext()
    return ZoneStyle.profiles[context.profileKey] or ZoneStyle.profiles.azeroth, context.profileKey, context
end

function ZoneStyle.GetPendingSuggestion()
    local state = P.GetStyleState()
    return state.pendingSuggestion
end

function ZoneStyle.AcknowledgeSuggestion()
    local state = P.GetStyleState()
    if state.pendingSuggestion and state.pendingSuggestion.unread then
        state.pendingSuggestion.unread = false
        if QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION_ACKNOWLEDGED", state.pendingSuggestion) end
    end
end

function ZoneStyle.ConsumeSuggestion()
    local state = P.GetStyleState()
    local suggestion = state.pendingSuggestion
    state.pendingSuggestion = nil
    if suggestion and QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION_CONSUMED", suggestion) end
    return suggestion
end
