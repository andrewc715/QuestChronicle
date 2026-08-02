local QC = QuestChronicle
QC.ZoneStyle = QC.ZoneStyle or {}
local ZoneStyle = QC.ZoneStyle
ZoneStyle._Private = ZoneStyle._Private or {}
local P = ZoneStyle._Private


ZoneStyle.MODE_ZONE_NATIVE = "ZONE_NATIVE"
ZoneStyle.MODE_TRAVELER = "TRAVELER"
ZoneStyle.MODE_CLASS_FANTASY = "CLASS_FANTASY"
ZoneStyle.MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO"

ZoneStyle.modes = {
    { key = ZoneStyle.MODE_ZONE_NATIVE, label = "Zone Native", shortLabel = "Zone", description = "Favor the culture, climate, magic, and materials of the current zone profile." },
    { key = ZoneStyle.MODE_TRAVELER, label = "Traveler", shortLabel = "Traveler", description = "Favor practical, weathered, expedition-ready appearances with a lighter touch of local style." },
    { key = ZoneStyle.MODE_CLASS_FANTASY, label = "Class Fantasy", shortLabel = "Class", description = "Favor iconic class themes while borrowing a smaller accent from the current zone." },
    { key = ZoneStyle.MODE_CHRONICLE_ECHO, label = "Chronicle Echo", shortLabel = "Echo", description = "Let recent quests, factions, and enemies shape the outfit while retaining the current zone's era and source limits." },
}

P.modeByKey = {}
for _, mode in ipairs(ZoneStyle.modes) do
    P.modeByKey[mode.key] = mode
end

function P.SafeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h, i = pcall(func, ...)
    if ok then return a, b, c, d, e, f, g, h, i end
end

function P.Normalize(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("[’']", "")
    text = text:gsub("[^%w]+", " ")
    return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
end

ZoneStyle.expansions = {
    [0] = { label = "Classic", shortLabel = "Classic" },
    [1] = { label = "The Burning Crusade", shortLabel = "TBC" },
    [2] = { label = "Wrath of the Lich King", shortLabel = "Wrath" },
    [3] = { label = "Cataclysm", shortLabel = "Cataclysm" },
    [4] = { label = "Mists of Pandaria", shortLabel = "Mists" },
    [5] = { label = "Warlords of Draenor", shortLabel = "Warlords" },
    [6] = { label = "Legion", shortLabel = "Legion" },
    [7] = { label = "Battle for Azeroth", shortLabel = "BFA" },
    [8] = { label = "Shadowlands", shortLabel = "Shadowlands" },
    [9] = { label = "Dragonflight", shortLabel = "Dragonflight" },
    [10] = { label = "The War Within", shortLabel = "TWW" },
    [11] = { label = "Midnight", shortLabel = "Midnight" },
}

P.eraRules = {
    { maxExpansionID = 11, match = { "midnight", "amani highlands", "harandar", "har mara", "voidstorm" } },
    { maxExpansionID = 10, match = { "khaz algar", "isle of dorn", "dornogal", "ringing deeps", "hall of awakening", "hallowfall", "azjkahet", "azj kahet", "undermine", "siren isle", "karesh", "k aresh" } },
    { maxExpansionID = 9, match = { "dragon isles", "forbidden reach", "war creche", "waking shores", "ohnahran", "ohn ahran", "azure span", "thaldraszus", "valdrakken", "zaralek", "emerald dream", "amirdrassil" } },
    { maxExpansionID = 8, match = { "shadowlands", "exiles reach", "darkmaul citadel", "oribos", "bastion", "maldraxxus", "ardenweald", "revendreth", "the maw", "korthia", "zereth mortis" } },
    { maxExpansionID = 7, match = { "kul tiras", "zandalar", "boralus", "tiragarde", "drustvar", "stormsong", "zuldazar", "nazmir", "voldun", "vol dun", "nazjatar", "mechagon" } },
    { maxExpansionID = 6, match = { "broken isles", "mardum", "telogrus rift", "vindicaar", "azsuna", "valsharah", "val sharah", "highmountain", "stormheim", "suramar", "broken shore", "argus" } },
    { maxExpansionID = 5, match = { "draenor", "frostfire ridge", "shadowmoon valley draenor", "gorgrond", "talador", "spires of arak", "nagrand draenor", "tanaan jungle", "ashran" } },
    { maxExpansionID = 4, match = { "pandaria", "wandering isle", "shang xi training grounds", "temple of five dawns", "jade forest", "valley of the four winds", "krasarang", "kun lai", "townlong", "dread wastes", "vale of eternal blossoms", "timeless isle", "isle of thunder" } },
    { maxExpansionID = 3, match = { "gilneas", "kezan", "lost isles", "mount hyjal", "vashjir", "vashj ir", "deepholm", "uldum", "twilight highlands", "tol barad", "molten front" } },
    { maxExpansionID = 2, match = { "scarlet enclave", "acherus the ebon hold", "frozen throne", "northrend", "borean tundra", "howling fjord", "dragonblight", "grizzly hills", "zul drak", "sholazar", "storm peaks", "icecrown", "wintergrasp" } },
    { maxExpansionID = 1, match = { "outland", "azuremyst isle", "ammen vale", "bloodmyst isle", "hellfire peninsula", "zangarmarsh", "terokkar", "nagrand", "blades edge", "blade s edge", "netherstorm", "shadowmoon valley", "shattrath", "silvermoon", "eversong", "sunstrider isle", "ghostlands", "queldanas", "quel danas", "sunwell", "zulaman", "zul aman" } },
}

-- Each retail racial or hero-class opening maps to one of these geographic
-- source pools. Shared starts deliberately share a pool: dwarves and gnomes
-- both remain in Dun Morogh, while orcs and trolls both remain in Durotar.
-- This table also drives the deterministic starting-zone regression matrix.
ZoneStyle.startingZoneCases = {
    { race = "Human", zone = "Elwynn Forest", subzone = "Northshire Valley", provenanceKey = "northshire", maxExpansionID = 0 },
    { race = "Dwarf", zone = "Dun Morogh", subzone = "Coldridge Valley", provenanceKey = "dunmorogh", maxExpansionID = 0 },
    { race = "Gnome", zone = "Dun Morogh", subzone = "New Tinkertown", provenanceKey = "dunmorogh", maxExpansionID = 0 },
    { race = "Night Elf", zone = "Teldrassil", subzone = "Shadowglen", provenanceKey = "teldrassil", maxExpansionID = 0 },
    { race = "Draenei", zone = "Azuremyst Isle", subzone = "Ammen Vale", provenanceKey = "azuremyst", maxExpansionID = 1 },
    { race = "Worgen", zone = "Gilneas", subzone = "Gilneas City", provenanceKey = "gilneas", maxExpansionID = 3 },
    { race = "Pandaren", zone = "The Wandering Isle", subzone = "Shang Xi Training Grounds", provenanceKey = "wanderingisle", maxExpansionID = 4 },
    { race = "Dracthyr", zone = "The Forbidden Reach", subzone = "The War Creche", provenanceKey = "forbiddenreach", maxExpansionID = 9 },
    { race = "Orc", zone = "Durotar", subzone = "Valley of Trials", provenanceKey = "durotar", maxExpansionID = 0 },
    { race = "Undead", zone = "Tirisfal Glades", subzone = "Deathknell", provenanceKey = "tirisfal", maxExpansionID = 0 },
    { race = "Tauren", zone = "Mulgore", subzone = "Camp Narache", provenanceKey = "mulgore", maxExpansionID = 0 },
    { race = "Troll", zone = "Durotar", subzone = "Echo Isles", provenanceKey = "durotar", maxExpansionID = 0 },
    { race = "Blood Elf", zone = "Eversong Woods", subzone = "Sunstrider Isle", provenanceKey = "sunstrider", maxExpansionID = 1 },
    { race = "Goblin", zone = "Kezan", subzone = "Bilgewater Port", provenanceKey = "kezan", maxExpansionID = 3 },
    { race = "Core-race Death Knight", zone = "Plaguelands: The Scarlet Enclave", subzone = "Acherus: The Ebon Hold", provenanceKey = "scarletenclave", maxExpansionID = 2 },
    { race = "Pandaren/Allied Death Knight", zone = "Icecrown", subzone = "The Frozen Throne", provenanceKey = "frozenthrone", maxExpansionID = 2 },
    { race = "Demon Hunter", zone = "Mardum, the Shattered Abyss", subzone = "Illidari Foothold", provenanceKey = "mardum", maxExpansionID = 6 },
    { race = "Core races", zone = "Exile's Reach", subzone = "Darkmaul Citadel", provenanceKey = "exilesreach", maxExpansionID = 8 },
    { race = "Void Elf", zone = "Telogrus Rift", subzone = "Telogrus Rift", provenanceKey = "telogrus", maxExpansionID = 6 },
    { race = "Lightforged Draenei", zone = "The Vindicaar", subzone = "The Vindicaar", provenanceKey = "vindicaar", maxExpansionID = 6 },
    { race = "Dark Iron Dwarf", zone = "Blackrock Mountain", subzone = "Shadowforge City", provenanceKey = "shadowforge", maxExpansionID = 0 },
    { race = "Kul Tiran", zone = "Tiragarde Sound", subzone = "Boralus", provenanceKey = "tiragarde", maxExpansionID = 7 },
    { race = "Mechagnome", zone = "Mechagon Island", subzone = "Mechagon City", provenanceKey = "mechagon", maxExpansionID = 7 },
    { race = "Nightborne", zone = "Suramar", subzone = "The Nighthold", provenanceKey = "suramar", maxExpansionID = 6 },
    { race = "Highmountain Tauren", zone = "Highmountain", subzone = "Thunder Totem", provenanceKey = "highmountain", maxExpansionID = 6 },
    { race = "Mag'har Orc", zone = "Orgrimmar", subzone = "Valley of Honor", provenanceKey = "orgrimmar", maxExpansionID = 0 },
    { race = "Zandalari Troll", zone = "Zuldazar", subzone = "Dazar'alor", provenanceKey = "zuldazar", maxExpansionID = 7 },
    { race = "Vulpera", zone = "Orgrimmar", subzone = "Valley of Honor", provenanceKey = "orgrimmar", maxExpansionID = 0 },
    { race = "Earthen", zone = "The Ringing Deeps", subzone = "Hall of Awakening", provenanceKey = "hallofawakening", maxExpansionID = 10 },
    { race = "Haranir", zone = "Harandar", subzone = "Har'mara", provenanceKey = "harandar", maxExpansionID = 11 },
}

-- Blizzard exposes exact instance provenance for boss-drop appearances. Other
-- sources do not consistently carry a zone, so their explicit item/source names
-- are checked against the same curated vocabulary and otherwise remain eligible.
ZoneStyle.provenanceProfiles = {
    { key = "exilesreach", label = "Exile's Reach", match = { "exiles reach", "darkmaul citadel" }, origins = { "exiles reach", "darkmaul citadel", "north sea" } },
    { key = "northshire", label = "Northshire Valley", match = { "northshire valley", "northshire abbey" }, origins = { "northshire", "northshire abbey", "elwynn forest", "goldshire" } },
    { key = "dunmorogh", label = "Dun Morogh", match = { "dun morogh", "coldridge valley", "new tinkertown", "chill breeze valley" }, origins = { "dun morogh", "coldridge", "anvilmar", "new tinkertown", "chill breeze", "kharanos", "gnomeregan" } },
    { key = "teldrassil", label = "Teldrassil", match = { "teldrassil", "shadowglen", "aldrassil" }, origins = { "teldrassil", "shadowglen", "aldrassil", "dolanaar" } },
    { key = "azuremyst", label = "Azuremyst Isle", match = { "azuremyst isle", "ammen vale", "crash site" }, origins = { "azuremyst", "ammen vale", "crash site", "azure watch", "bloodmyst" } },
    { key = "gilneas", label = "Gilneas", match = { "gilneas", "gilneas city", "duskhaven" }, origins = { "gilneas", "gilneas city", "duskhaven" } },
    { key = "durotar", label = "Durotar", match = { "durotar", "valley of trials", "echo isles", "darkspear training grounds" }, origins = { "durotar", "valley of trials", "the den", "razor hill", "echo isles", "darkspear", "senjin" } },
    { key = "tirisfal", label = "Tirisfal Glades", match = { "tirisfal glades", "deathknell" }, origins = { "tirisfal", "deathknell", "brill", "undercity" } },
    { key = "mulgore", label = "Mulgore", match = { "mulgore", "red cloud mesa", "camp narache" }, origins = { "mulgore", "red cloud mesa", "camp narache", "bloodhoof village" } },
    { key = "sunstrider", label = "Sunstrider Isle", match = { "sunstrider isle", "the sunspire" }, origins = { "sunstrider isle", "sunspire", "eversong", "falconwing square" } },
    { key = "kezan", label = "Kezan and the Lost Isles", match = { "kezan", "bilgewater port", "lost isles", "shipwreck shore", "town in a box" }, origins = { "kezan", "bilgewater", "lost isles", "shipwreck shore", "town in a box", "ktc headquarters" } },
    { key = "wanderingisle", label = "The Wandering Isle", match = { "wandering isle", "shang xi training grounds", "temple of five dawns" }, origins = { "wandering isle", "shang xi", "temple of five dawns", "dai lo farmstead", "shen zin su" } },
    { key = "forbiddenreach", label = "The Forbidden Reach", match = { "forbidden reach", "war creche" }, origins = { "forbidden reach", "war creche" } },
    { key = "scarletenclave", label = "The Scarlet Enclave", match = { "scarlet enclave", "acherus the ebon hold" }, origins = { "scarlet enclave", "acherus", "ebon hold", "havenshire", "new avalon" } },
    { key = "frozenthrone", label = "The Frozen Throne", match = { "frozen throne" }, origins = { "frozen throne", "icecrown" } },
    { key = "mardum", label = "Mardum", match = { "mardum", "illidari foothold", "fel hammer" }, origins = { "mardum", "illidari foothold", "fel hammer" } },
    { key = "telogrus", label = "Telogrus Rift", match = { "telogrus rift" }, origins = { "telogrus rift", "telogrus" } },
    { key = "vindicaar", label = "The Vindicaar", match = { "vindicaar" }, origins = { "vindicaar" } },
    { key = "shadowforge", label = "Shadowforge City", match = { "shadowforge city" }, origins = { "shadowforge city", "blackrock depths" } },
    { key = "mechagon", label = "Mechagon", match = { "mechagon island", "mechagon city", "mechagon" }, origins = { "mechagon", "operation mechagon" } },
    { key = "orgrimmar", label = "Orgrimmar", match = { "orgrimmar", "valley of honor" }, origins = { "orgrimmar", "valley of honor" } },
    { key = "hallofawakening", label = "Hall of Awakening", match = { "hall of awakening" }, origins = { "hall of awakening", "ringing deeps" } },

    -- Classic questing regions. These profiles keep old-world generation local
    -- even when an appearance's expansion metadata alone would permit it.
    { key = "elwynn", label = "Elwynn Forest", match = { "elwynn forest", "goldshire" }, origins = { "elwynn forest", "goldshire", "stormwind", "the stockade" } },
    { key = "westfall", label = "Westfall", match = { "westfall", "sentinel hill", "moonbrook" }, origins = { "westfall", "sentinel hill", "moonbrook", "deadmines" } },
    { key = "redridge", label = "Redridge Mountains", match = { "redridge mountains", "lakeshire" }, origins = { "redridge", "lakeshire", "stonewatch" } },
    { key = "duskwood", label = "Duskwood", match = { "duskwood", "darkshire", "raven hill" }, origins = { "duskwood", "darkshire", "raven hill" } },
    { key = "stranglethorn", label = "Stranglethorn", match = { "stranglethorn", "northern stranglethorn", "cape of stranglethorn", "booty bay" }, origins = { "stranglethorn", "booty bay", "zul gurub", "gurubashi" } },
    { key = "lochmodan", label = "Loch Modan", match = { "loch modan", "thelsamar" }, origins = { "loch modan", "thelsamar" } },
    { key = "wetlands", label = "Wetlands", match = { "wetlands", "menethil harbor" }, origins = { "wetlands", "menethil" } },
    { key = "silverpine", label = "Silverpine Forest", match = { "silverpine forest" }, origins = { "silverpine", "shadowfang keep" } },
    { key = "hillsbrad", label = "Hillsbrad Foothills", match = { "hillsbrad foothills" }, origins = { "hillsbrad", "durnholde" } },
    { key = "arathi", label = "Arathi Highlands", match = { "arathi highlands", "refuge pointe", "hammerfall" }, origins = { "arathi highlands", "stromgarde", "refuge pointe", "hammerfall" } },
    { key = "hinterlands", label = "The Hinterlands", match = { "the hinterlands", "aerie peak" }, origins = { "hinterlands", "aerie peak", "jintha alor" } },
    { key = "badlands", label = "Badlands", match = { "badlands", "new kargath" }, origins = { "badlands", "uldaman", "new kargath" } },
    { key = "searinggorge", label = "Searing Gorge", match = { "searing gorge", "thorium point" }, origins = { "searing gorge", "thorium point", "blackrock depths", "molten core" } },
    { key = "burningsteppes", label = "Burning Steppes", match = { "burning steppes", "morgan vigil" }, origins = { "burning steppes", "blackrock spire", "blackwing lair" } },
    { key = "swampofsorrows", label = "Swamp of Sorrows", match = { "swamp of sorrows", "stonard" }, origins = { "swamp of sorrows", "stonard", "sunken temple", "temple of atal hakkar" } },
    { key = "blastedlands", label = "Blasted Lands", match = { "blasted lands", "nethergarde keep" }, origins = { "blasted lands", "nethergarde", "dark portal" } },
    { key = "westernplaguelands", label = "Western Plaguelands", match = { "western plaguelands", "andorhal" }, origins = { "western plaguelands", "andorhal", "scholomance" } },
    { key = "easternplaguelands", label = "Eastern Plaguelands", match = { "eastern plaguelands", "lights hope chapel" }, origins = { "eastern plaguelands", "lights hope", "stratholme", "naxxramas" } },
    { key = "bloodmyst", label = "Bloodmyst Isle", match = { "bloodmyst isle", "blood watch" }, origins = { "bloodmyst", "blood watch" } },
    { key = "ghostlands", label = "Ghostlands", maxExpansionID = 1, match = { "ghostlands", "tranquillien", "deatholme" }, origins = { "ghostlands", "tranquillien", "deatholme" } },

    { key = "darkshore", label = "Darkshore", match = { "darkshore", "lor danel", "auberdine" }, origins = { "darkshore", "lor danel", "auberdine" } },
    { key = "ashenvale", label = "Ashenvale", match = { "ashenvale", "astranaar" }, origins = { "ashenvale", "astranaar", "blackfathom deeps" } },
    { key = "stonetalon", label = "Stonetalon Mountains", match = { "stonetalon mountains", "stonetalon" }, origins = { "stonetalon" } },
    { key = "barrens", label = "The Barrens", match = { "northern barrens", "southern barrens", "the barrens", "crossroads" }, origins = { "barrens", "crossroads", "wailing caverns", "razorfen kraul", "razorfen downs" } },
    { key = "dustwallow", label = "Dustwallow Marsh", match = { "dustwallow marsh", "theramore" }, origins = { "dustwallow", "theramore", "onyxias lair" } },
    { key = "thousandneedles", label = "Thousand Needles", match = { "thousand needles", "freewind post" }, origins = { "thousand needles", "freewind" } },
    { key = "desolace", label = "Desolace", match = { "desolace", "nijels point", "shadowprey village" }, origins = { "desolace", "maraudon" } },
    { key = "feralas", label = "Feralas", match = { "feralas", "feathermoon stronghold", "camp mojache" }, origins = { "feralas", "dire maul", "feathermoon", "mojache" } },
    { key = "tanaris", label = "Tanaris", match = { "tanaris", "gadgetzan" }, origins = { "tanaris", "gadgetzan", "zul farrak", "caverns of time" } },
    { key = "ungoro", label = "Un'Goro Crater", match = { "un goro crater", "marshals stand" }, origins = { "un goro", "marshals stand" } },
    { key = "silithus", label = "Silithus", match = { "silithus", "cenarion hold" }, origins = { "silithus", "ahn qiraj", "cenarion hold" } },
    { key = "felwood", label = "Felwood", match = { "felwood", "emerald sanctuary" }, origins = { "felwood", "emerald sanctuary" } },
    { key = "winterspring", label = "Winterspring", match = { "winterspring", "everlook" }, origins = { "winterspring", "everlook" } },
    { key = "azshara", label = "Azshara", match = { "azshara", "bilgewater harbor" }, origins = { "azshara", "bilgewater harbor" } },

    -- Cataclysm launch and patch zones.
    { key = "hyjal", label = "Mount Hyjal", match = { "mount hyjal", "nordrassil" }, origins = { "mount hyjal", "nordrassil", "firelands", "molten front" } },
    { key = "vashjir", label = "Vashj'ir", match = { "vashjir", "vashj ir", "kelpthar forest", "shimmering expanse", "abyssal depths" }, origins = { "vashj ir", "throne of the tides" } },
    { key = "deepholm", label = "Deepholm", match = { "deepholm", "temple of earth" }, origins = { "deepholm", "stonecore" } },
    { key = "uldum", label = "Uldum", match = { "uldum", "ramkahen" }, origins = { "uldum", "ramkahen", "halls of origination", "vortex pinnacle", "throne of the four winds" } },
    { key = "twilighthighlands", label = "Twilight Highlands", match = { "twilight highlands", "dragonmaw port", "highbank" }, origins = { "twilight highlands", "grim batol", "bastion of twilight" } },
    { key = "tolbarad", label = "Tol Barad", match = { "tol barad", "tol barad peninsula" }, origins = { "tol barad", "baradin hold" } },
    { key = "moltenfront", label = "Molten Front", match = { "molten front" }, origins = { "molten front", "firelands" } },

    { key = "sunwell", label = "Isle of Quel'Danas", match = { "queldanas", "quel danas", "sunwell" }, origins = { "sunwell", "magisters terrace", "queldanas", "quel danas", "kiljaeden", "kil jaeden", "muru", "eredar twins", "felmyst", "brutallus" } },
    { key = "eversong_midnight", label = "Renewed Eversong Woods", minExpansionID = 11, match = { "silvermoon", "eversong woods", "ghostlands" }, origins = { "silvermoon", "eversong woods", "ghostlands", "march on quel danas", "lightbloom" } },
    { key = "eversong", label = "Eversong and Ghostlands", maxExpansionID = 1, match = { "silvermoon", "eversong", "ghostlands" }, origins = { "silvermoon", "eversong", "ghostlands", "deatholme" } },
    { key = "zulaman", label = "Amani Highlands", match = { "zulaman", "zul aman", "amani highlands", "atal aman" }, origins = { "zulaman", "zul aman", "amani", "nalorakk", "akilzon", "janalai", "halazzi", "malacrass" } },
    { key = "harandar", label = "Harandar", match = { "harandar", "har athir", "har mara", "har kuai", "sporefall" }, origins = { "harandar", "har athir", "har mara", "har kuai", "sporefall", "rootway" } },
    { key = "voidstorm", label = "Voidstorm", match = { "voidstorm", "voidspire", "sunkiller" }, origins = { "voidstorm", "voidspire", "sunkiller", "shadowguard point" } },

    { key = "hellfire", label = "Hellfire Peninsula", match = { "hellfire peninsula" }, origins = { "hellfire peninsula", "hellfire ramparts", "blood furnace", "shattered halls", "magtheridons lair", "magtheridon" } },
    { key = "zangarmarsh", label = "Zangarmarsh", match = { "zangarmarsh" }, origins = { "zangarmarsh", "coilfang reservoir", "slave pens", "underbog", "steamvault", "serpentshrine cavern" } },
    { key = "terokkar", label = "Terokkar Forest", match = { "terokkar", "shattrath" }, origins = { "terokkar", "shattrath", "auchindoun", "mana tombs", "auchenai crypts", "sethekk halls", "shadow labyrinth" } },
    { key = "nagrand_outland", label = "Nagrand", maxExpansionID = 1, match = { "nagrand" }, origins = { "nagrand", "oshugun", "ring of blood" } },
    { key = "bladesedge", label = "Blade's Edge Mountains", match = { "blades edge mountains", "blade s edge mountains", "sylvanaar", "thunderlord stronghold", "moknathal village", "mok nathal village" }, origins = { "blades edge", "blade s edge", "gruuls lair", "gruul the dragonkiller", "high king maulgar" } },
    { key = "netherstorm", label = "Netherstorm", match = { "netherstorm" }, origins = { "netherstorm", "tempest keep", "the mechanar", "the botanica", "the arcatraz", "the eye" } },
    { key = "shadowmoon_outland", label = "Shadowmoon Valley", maxExpansionID = 1, match = { "shadowmoon valley" }, origins = { "shadowmoon valley", "black temple", "illidan stormrage", "battle for mount hyjal" } },

    { key = "borean", label = "Borean Tundra", match = { "borean tundra" }, origins = { "borean tundra", "the nexus", "the oculus", "eye of eternity" } },
    { key = "howling", label = "Howling Fjord", match = { "howling fjord" }, origins = { "howling fjord", "utgarde keep", "utgarde pinnacle" } },
    { key = "dragonblight", label = "Dragonblight", match = { "dragonblight" }, origins = { "dragonblight", "azjol nerub", "ahnkahet", "naxxramas", "obsidian sanctum" } },
    { key = "grizzly", label = "Grizzly Hills", match = { "grizzly hills" }, origins = { "grizzly hills", "draktharon keep" } },
    { key = "zuldrak", label = "Zul'Drak", match = { "zul drak" }, origins = { "zul drak", "gundrak" } },
    { key = "sholazar", label = "Sholazar Basin", match = { "sholazar" }, origins = { "sholazar" } },
    { key = "stormpeaks", label = "The Storm Peaks", match = { "storm peaks" }, origins = { "storm peaks", "halls of stone", "halls of lightning", "ulduar" } },
    { key = "icecrown", label = "Icecrown", match = { "icecrown" }, origins = { "icecrown", "icecrown citadel", "trial of the champion", "trial of the crusader", "forge of souls", "pit of saron", "halls of reflection" } },

    { key = "jadeforest", label = "The Jade Forest", match = { "jade forest" }, origins = { "jade forest", "temple of the jade serpent" } },
    { key = "fourwinds", label = "Valley of the Four Winds", match = { "valley of the four winds" }, origins = { "valley of the four winds", "stormstout brewery" } },
    { key = "kunlai", label = "Kun-Lai Summit", match = { "kun lai" }, origins = { "kun lai", "shado pan monastery", "mogu shan vaults" } },
    { key = "vale", label = "Vale of Eternal Blossoms", match = { "vale of eternal blossoms" }, origins = { "vale of eternal blossoms", "mogu shan palace", "siege of orgrimmar" } },
    { key = "thunderisle", label = "Isle of Thunder", match = { "isle of thunder" }, origins = { "isle of thunder", "throne of thunder" } },
    { key = "krasarang", label = "Krasarang Wilds", match = { "krasarang wilds" }, origins = { "krasarang", "domination point", "lions landing" } },
    { key = "townlong", label = "Townlong Steppes", match = { "townlong steppes" }, origins = { "townlong", "siege of niuzao temple" } },
    { key = "dreadwastes", label = "Dread Wastes", match = { "dread wastes" }, origins = { "dread wastes", "heart of fear" } },
    { key = "timelessisle", label = "Timeless Isle", match = { "timeless isle" }, origins = { "timeless isle", "ordos", "celestials" } },

    { key = "frostfire", label = "Frostfire Ridge", match = { "frostfire ridge" }, origins = { "frostfire ridge", "bloodmaul slag mines", "the slag mines" } },
    { key = "gorgrond", label = "Gorgrond", match = { "gorgrond" }, origins = { "gorgrond", "iron docks", "blackrock foundry", "everbloom" } },
    { key = "talador", label = "Talador", match = { "talador" }, origins = { "talador", "auchindoun" } },
    { key = "shadowmoon_draenor", label = "Shadowmoon Valley", minExpansionID = 5, match = { "shadowmoon valley" }, origins = { "shadowmoon valley", "shadowmoon burial grounds" } },
    { key = "arak", label = "Spires of Arak", match = { "spires of arak" }, origins = { "spires of arak", "skyreach" } },
    { key = "nagrand_draenor", label = "Nagrand", match = { "nagrand draenor" }, origins = { "nagrand", "highmaul" } },
    { key = "tanaan", label = "Tanaan Jungle", match = { "tanaan jungle" }, origins = { "tanaan jungle", "hellfire citadel" } },
    { key = "ashran", label = "Ashran", match = { "ashran", "warspear", "stormshield" }, origins = { "ashran", "warspear", "stormshield" } },

    { key = "azsuna", label = "Azsuna", match = { "azsuna" }, origins = { "azsuna", "eye of azshara", "vault of the wardens" } },
    { key = "valsharah", label = "Val'sharah", match = { "valsharah", "val sharah" }, origins = { "valsharah", "val sharah", "darkheart thicket", "emerald nightmare" } },
    { key = "highmountain", label = "Highmountain", match = { "highmountain" }, origins = { "highmountain", "neltharions lair" } },
    { key = "stormheim", label = "Stormheim", match = { "stormheim" }, origins = { "stormheim", "halls of valor", "maw of souls", "trial of valor" } },
    { key = "suramar", label = "Suramar", match = { "suramar" }, origins = { "suramar", "court of stars", "the arcway", "nighthold" } },
    { key = "brokenshore", label = "Broken Shore", match = { "broken shore" }, origins = { "broken shore", "tomb of sargeras", "cathedral of eternal night" } },
    { key = "argus", label = "Argus", match = { "argus", "krokuun", "antoran wastes", "macaree" }, origins = { "argus", "krokuun", "antoran wastes", "macaree", "seat of the triumvirate", "antorus" } },

    { key = "tiragarde", label = "Tiragarde Sound", match = { "tiragarde", "boralus" }, origins = { "tiragarde", "boralus", "freehold", "tol dagor", "siege of boralus" } },
    { key = "drustvar", label = "Drustvar", match = { "drustvar" }, origins = { "drustvar", "waycrest manor" } },
    { key = "stormsong", label = "Stormsong Valley", match = { "stormsong" }, origins = { "stormsong", "shrine of the storm" } },
    { key = "zuldazar", label = "Zuldazar", match = { "zuldazar", "dazaralor", "dazar alor" }, origins = { "zuldazar", "atal dazar", "kings rest", "battle of dazaralor" } },
    { key = "nazmir", label = "Nazmir", match = { "nazmir" }, origins = { "nazmir", "underrot", "uldir" } },
    { key = "voldun", label = "Vol'dun", match = { "voldun", "vol dun" }, origins = { "voldun", "vol dun", "temple of sethraliss" } },
    { key = "nazjatar", label = "Nazjatar", match = { "nazjatar", "newhome", "mezzamere" }, origins = { "nazjatar", "eternal palace", "newhome", "mezzamere" } },

    { key = "bastion", label = "Bastion", match = { "bastion" }, origins = { "bastion", "spires of ascension", "necrotic wake" } },
    { key = "maldraxxus", label = "Maldraxxus", match = { "maldraxxus" }, origins = { "maldraxxus", "theater of pain", "plaguefall" } },
    { key = "ardenweald", label = "Ardenweald", match = { "ardenweald" }, origins = { "ardenweald", "mists of tirna scithe", "de other side" } },
    { key = "revendreth", label = "Revendreth", match = { "revendreth" }, origins = { "revendreth", "halls of atonement", "sanguine depths", "castle nathria" } },
    { key = "maw", label = "The Maw", match = { "the maw", "korthia" }, origins = { "the maw", "korthia", "torghast", "sanctum of domination" } },
    { key = "zerethmortis", label = "Zereth Mortis", match = { "zereth mortis" }, origins = { "zereth mortis", "sepulcher of the first ones" } },

    { key = "wakingshores", label = "The Waking Shores", match = { "waking shores" }, origins = { "waking shores", "ruby life pools", "neltharus", "vault of the incarnates" } },
    { key = "ohnahran", label = "Ohn'ahran Plains", match = { "ohn ahran" }, origins = { "ohn ahran", "nokhud offensive" } },
    { key = "azurespan", label = "The Azure Span", match = { "azure span" }, origins = { "azure span", "azure vault", "brackenhide hollow" } },
    { key = "thaldraszus", label = "Thaldraszus", match = { "thaldraszus", "valdrakken" }, origins = { "thaldraszus", "valdrakken", "algethar academy", "halls of infusion", "dawn of the infinite" } },
    { key = "zaralek", label = "Zaralek Cavern", match = { "zaralek" }, origins = { "zaralek", "aberrus" } },
    { key = "dream", label = "Emerald Dream", match = { "emerald dream", "amirdrassil" }, origins = { "emerald dream", "amirdrassil" } },

    { key = "dorn", label = "Isle of Dorn", match = { "isle of dorn", "dornogal" }, origins = { "isle of dorn", "dornogal", "the rookery", "cinderbrew meadery" } },
    { key = "ringingdeeps", label = "The Ringing Deeps", match = { "ringing deeps" }, origins = { "ringing deeps", "stonevault", "darkflame cleft" } },
    { key = "hallowfall", label = "Hallowfall", match = { "hallowfall" }, origins = { "hallowfall", "priory of the sacred flame", "dawnbreaker" } },
    { key = "azjkahet", label = "Azj-Kahet", match = { "azj kahet" }, origins = { "azj kahet", "ara kara", "city of threads", "nerub ar palace" } },
    { key = "undermine", label = "Undermine", match = { "undermine" }, origins = { "undermine", "liberation of undermine", "operation floodgate" } },
    { key = "sirenisle", label = "Siren Isle", match = { "siren isle" }, origins = { "siren isle", "storm phase", "flame blessed" } },
    { key = "karesh", label = "K'aresh", match = { "karesh", "k aresh", "tazavesh" }, origins = { "karesh", "k aresh", "tazavesh", "eco dome", "manaforge omega" } },
}

P.provenanceByKey = {}
P.provenanceOriginMarkers = {}
P.provenanceOriginMarkerByText = {}
for _, profile in ipairs(ZoneStyle.provenanceProfiles) do
    P.provenanceByKey[profile.key] = profile
    for _, phrase in ipairs(profile.origins or {}) do
        local normalized = P.Normalize(phrase)
        if normalized ~= "" then
            local marker = P.provenanceOriginMarkerByText[normalized]
            if not marker then
                marker = { text = normalized, profile = profile, profileKeys = {} }
                P.provenanceOriginMarkerByText[normalized] = marker
                table.insert(P.provenanceOriginMarkers, marker)
            end
            marker.profileKeys[profile.key] = true
        end
    end
end

function P.BuildContextText(context)
    local parts = { context and context.subzone, context and context.zone, context and context.mapName }
    for _, name in ipairs(context and context.mapTrail or {}) do table.insert(parts, name) end
    local values = {}
    for _, value in ipairs(parts) do
        if value and value ~= "" then table.insert(values, value) end
    end
    return " " .. P.Normalize(table.concat(values, " ")) .. " "
end

function P.TextMatchesAny(text, phrases)
    local padded = " " .. P.Normalize(text) .. " "
    for _, phrase in ipairs(phrases or {}) do
        local needle = P.Normalize(phrase)
        if needle ~= "" and padded:find(" " .. needle .. " ", 1, true) then return true, phrase end
    end
    return false
end

function ZoneStyle.ResolveEra(context)
    context = context or ZoneStyle.DetectContext()
    local text = P.BuildContextText(context)
    for _, rule in ipairs(P.eraRules) do
        local matches = P.TextMatchesAny(text, rule.match)
        if matches then
            local info = ZoneStyle.expansions[rule.maxExpansionID]
            return rule.maxExpansionID, info.label, info.shortLabel
        end
    end
    return 0, ZoneStyle.expansions[0].label, ZoneStyle.expansions[0].shortLabel
end

function ZoneStyle.ResolveProvenance(context)
    context = context or ZoneStyle.DetectContext()
    local text = P.BuildContextText(context)
    local eraMax = ZoneStyle.ResolveEra(context)
    for _, profile in ipairs(ZoneStyle.provenanceProfiles) do
        local eraMatches = (profile.minExpansionID == nil or eraMax >= profile.minExpansionID)
            and (profile.maxExpansionID == nil or eraMax <= profile.maxExpansionID)
        if eraMatches and P.TextMatchesAny(text, profile.match) then return profile, profile.key end
    end
    return nil
end

P.travelerKeywords = {
    traveler = 10, travelling = 8, wanderer = 9, wayfarer = 10, expedition = 9,
    explorer = 9, scout = 8, ranger = 7, trail = 7, pathfinder = 9, outpost = 5,
    field = 5, campaign = 5, rugged = 8, weathered = 8, worn = 5, battered = 5,
    sturdy = 7, reinforced = 5, leather = 4, hide = 4, fur = 4, cloak = 4,
    pack = 6, pouch = 5, belt = 4, boots = 5, hood = 5, torch = 4, compass = 7,
}

P.travelerAvoid = {
    throne = -5, coronation = -5, ceremonial = -4, jeweled = -3, cosmic = -3,
    infinite = -3, apocalypse = -5, annihilator = -4,
}

P.classKeywords = {
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

-- Trading Post is source type 7 in Blizzard's Wardrobe filters. Older
-- subscription, shop, Recruit-a-Friend, and preorder rewards predate that
-- dedicated source type, so their stable collection names are also guarded.
-- These restrictions apply only to generated outfits; manual browsing and
-- preview remain untouched.
P.TRADING_POST_SOURCE_TYPE = 7
P.promotionalItemIDs = {
    [171324] = true, -- Renowned Explorer's Akubra
    [171340] = true, -- Wooly Wendigo Hood
}
P.promotionalNameFragments = {
    "renowned explorers",
    "wooly wendigo",
    "sprite darters",
    "celestial observers",
    "vestments of the eternal traveler",
    "crown of the eternal winter",
    "hood of hungering darkness",
    "jewel of the firelord",
    "fireplume regalia",
}
P.promotionalSourceFragments = {
    "trading post",
    "promotion",
    "promotional",
    "recruit a friend",
    "subscription",
    "blizzard shop",
    "in game shop",
    "battle net shop",
    "shop",
    "store",
    "game time promotion",
}

-- WoW does not expose a palette for an appearance texture. Native transmog-set
-- membership and strong semantic motifs are therefore the most reliable safe
-- signals available to an addon for keeping a generated outfit coordinated.
P.styleFamilies = {
    fire = { fire = 3, flame = 3, flaming = 4, fiery = 3, molten = 5, magma = 5, lava = 5, inferno = 4, infernal = 3, ember = 3, cinder = 3, burning = 4, firelord = 5, sulfuras = 5 },
    frost = { frost = 4, frosted = 4, ice = 3, icy = 3, glacial = 5, rime = 4, snow = 2, winter = 3, frozen = 4, icicle = 4 },
    shadow = { shadow = 4, dark = 2, darkness = 3, black = 2, ebon = 3, ebony = 3, night = 2, midnight = 3, void = 4, abyss = 4, twilight = 2 },
    radiant = { holy = 4, light = 3, radiant = 5, luminous = 4, dawn = 3, sun = 3, solar = 4, golden = 2, celestial = 4, sacred = 3 },
    nature = { nature = 4, natural = 3, leaf = 3, leafy = 3, grove = 4, vine = 3, verdant = 4, emerald = 2, wild = 2, bark = 3, bloom = 3, floral = 3 },
    arcane = { arcane = 5, mana = 4, spell = 2, runic = 3, mage = 3, sorcerer = 3, cosmic = 4, astral = 4, prismatic = 4, crystal = 3 },
    storm = { storm = 4, thunder = 4, lightning = 5, tempest = 4, static = 3, cyclone = 4 },
    fel = { fel = 5, demon = 3, demonic = 4, legion = 2, chaos = 4, corrupt = 3, diabolic = 4 },
    necrotic = { death = 3, dead = 2, necrotic = 5, plague = 4, bone = 3, skeletal = 4, skull = 3, grave = 3, crypt = 3, scourge = 4 },
    mechanical = { mechanical = 4, machine = 4, mechanized = 4, gear = 2, cog = 3, clockwork = 5, industrial = 4, engine = 3 },
    rustic = { weathered = 4, worn = 3, battered = 3, rugged = 4, explorer = 3, traveler = 3, scout = 3, leather = 2, hide = 2, fur = 2, wool = 2 },
    regal = { royal = 4, regal = 4, imperial = 4, jeweled = 3, crown = 3, throne = 3, ceremonial = 3, noble = 3 },
}
P.dramaticFamilies = { fire = true, frost = true, shadow = true, radiant = true, arcane = true, storm = true, fel = true, necrotic = true }
P.conflictingFamilies = {
    fire = { frost = true, shadow = true },
    frost = { fire = true },
    shadow = { fire = true, radiant = true, nature = true },
    radiant = { shadow = true, necrotic = true, fel = true },
    nature = { shadow = true, necrotic = true, mechanical = true, fel = true },
    fel = { radiant = true, nature = true },
    necrotic = { radiant = true, nature = true },
    mechanical = { nature = true, rustic = true },
    rustic = { mechanical = true, arcane = true, regal = true },
    regal = { rustic = true },
}
