local QC = QuestChronicle

QC.ZoneStyle = QC.ZoneStyle or {}
local ZoneStyle = QC.ZoneStyle

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

local eraRules = {
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

local provenanceByKey = {}
local provenanceOriginMarkers = {}
local provenanceOriginMarkerByText = {}
for _, profile in ipairs(ZoneStyle.provenanceProfiles) do
    provenanceByKey[profile.key] = profile
    for _, phrase in ipairs(profile.origins or {}) do
        local normalized = Normalize(phrase)
        if normalized ~= "" then
            local marker = provenanceOriginMarkerByText[normalized]
            if not marker then
                marker = { text = normalized, profile = profile, profileKeys = {} }
                provenanceOriginMarkerByText[normalized] = marker
                table.insert(provenanceOriginMarkers, marker)
            end
            marker.profileKeys[profile.key] = true
        end
    end
end

local function BuildContextText(context)
    local parts = { context and context.subzone, context and context.zone, context and context.mapName }
    for _, name in ipairs(context and context.mapTrail or {}) do table.insert(parts, name) end
    local values = {}
    for _, value in ipairs(parts) do
        if value and value ~= "" then table.insert(values, value) end
    end
    return " " .. Normalize(table.concat(values, " ")) .. " "
end

local function TextMatchesAny(text, phrases)
    local padded = " " .. Normalize(text) .. " "
    for _, phrase in ipairs(phrases or {}) do
        local needle = Normalize(phrase)
        if needle ~= "" and padded:find(" " .. needle .. " ", 1, true) then return true, phrase end
    end
    return false
end

function ZoneStyle.ResolveEra(context)
    context = context or ZoneStyle.DetectContext()
    local text = BuildContextText(context)
    for _, rule in ipairs(eraRules) do
        local matches = TextMatchesAny(text, rule.match)
        if matches then
            local info = ZoneStyle.expansions[rule.maxExpansionID]
            return rule.maxExpansionID, info.label, info.shortLabel
        end
    end
    return 0, ZoneStyle.expansions[0].label, ZoneStyle.expansions[0].shortLabel
end

function ZoneStyle.ResolveProvenance(context)
    context = context or ZoneStyle.DetectContext()
    local text = BuildContextText(context)
    local eraMax = ZoneStyle.ResolveEra(context)
    for _, profile in ipairs(ZoneStyle.provenanceProfiles) do
        local eraMatches = (profile.minExpansionID == nil or eraMax >= profile.minExpansionID)
            and (profile.maxExpansionID == nil or eraMax <= profile.maxExpansionID)
        if eraMatches and TextMatchesAny(text, profile.match) then return profile, profile.key end
    end
    return nil
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

-- Trading Post is source type 7 in Blizzard's Wardrobe filters. Older
-- subscription, shop, Recruit-a-Friend, and preorder rewards predate that
-- dedicated source type, so their stable collection names are also guarded.
-- These restrictions apply only to generated outfits; manual browsing and
-- preview remain untouched.
local TRADING_POST_SOURCE_TYPE = 7
local promotionalItemIDs = {
    [171324] = true, -- Renowned Explorer's Akubra
    [171340] = true, -- Wooly Wendigo Hood
}
local promotionalNameFragments = {
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
local promotionalSourceFragments = {
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
local styleFamilies = {
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
local dramaticFamilies = { fire = true, frost = true, shadow = true, radiant = true, arcane = true, storm = true, fel = true, necrotic = true }
local conflictingFamilies = {
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

-- Chronicle Intelligence deliberately uses only the quest record already kept
-- by schema 2. The evidence vocabulary converts recent quest titles and
-- objectives into appearance vocabulary; no new event fields or external quest
-- database are required.
local chronicleThemes = {
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

local profileOrder = {
    "quelthalas", "amani", "harandar", "voidstorm", "hallowfall", "khazalgar",
    "dragonisles", "cataclysm", "draenor", "brokenisles", "kaldorei", "zandalar",
    "nazjatar", "kultiras", "pandaria", "northrend", "outland", "bfa", "shadowlands",
    "human", "orcish", "forsaken", "easternkingdoms", "kalimdor",
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
    context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    local provenance, provenanceKey = ZoneStyle.ResolveProvenance(context)
    context.provenanceKey = provenanceKey
    context.provenanceResolved = true
    context.provenanceLabel = provenance and provenance.label or context.zone
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
    local state = GetStyleState()
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

local function LoadItemMetadata(source)
    if not source or not source.itemID then return nil end
    local genericName = not source.name or tostring(source.name):match("^Appearance %d+$")
    if source.expansionID ~= nil and not genericName then
        return source.expansionID
    end

    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) == "function" then
        local ok, name, link, quality, _, _, itemType, itemSubType, _, equipLocation, _, _, _, _, _, expansionID = pcall(getter, source.itemID)
        if ok and name then
            source.styleName = name
            if genericName then source.name = name end
            source.styleItemLink = link or source.styleItemLink
            source.quality = source.quality or quality
            source.styleItemType = itemType
            source.styleItemSubType = itemSubType
            source.styleEquipLocation = equipLocation
            if expansionID ~= nil then source.expansionID = tonumber(expansionID) end
            return source.expansionID
        end
    end

    if C_Item and C_Item.RequestLoadItemDataByID then
        SafeCall(C_Item.RequestLoadItemDataByID, source.itemID)
    end
    return source.expansionID
end

local function SourceMetadata(source)
    if not source then return "" end
    LoadItemMetadata(source)
    local parts = {}
    local function AddPart(value)
        if value ~= nil and tostring(value) ~= "" then
            table.insert(parts, tostring(value))
        end
    end

    AddPart(source.name)
    AddPart(source.styleName)
    AddPart(source.styleItemLink)
    AddPart(source.styleItemType)
    AddPart(source.styleItemSubType)
    AddPart(source.styleEquipLocation)
    return Normalize(table.concat(parts, " "))
end

-- C_Item.GetItemInfo's expansionID is useful but is not authoritative for
-- every legacy quest reward. The Wandering Isle's low-quality starter gear is
-- a known example: several sources are catalogued like older generic items.
-- Keep the fallback exact and reviewable so similarly named gear elsewhere is
-- not swept into Pandaria by a broad keyword rule.
local wanderingIsleSourceIDs = {
    [38062] = true, -- Unmarred Cord
    [38063] = true, -- Unmarred Waistband
    [38064] = true, -- Unmarred Belt
    [38091] = true, -- Cord of Grieving
    [38092] = true, -- Ropes of Grieving
    [38093] = true, -- Cinch of Grieving
}

local wanderingIsleItemIDs = {
    [74597] = true, -- Cord of Grieving
}

local wanderingIsleStarterNames = {}
for _, name in ipairs({
    "Initiate's Robes", "Initiate's Wristwraps", "Initiate's Gloves", "Initiate's Rope Belt", "Initiate's Leggings", "Initiate's Slippers",
    "Initiate's Vest", "Initiate's Bracers", "Initiate's Handguards", "Initiate's Belt", "Initiate's Britches", "Initiate's Footgear",
    "Initiate's Chestpiece", "Initiate's Cuffs", "Initiate's Grips", "Initiate's Braided Belt", "Initiate's Greaves", "Initiate's Boots",
    "Initiate's Breastplate", "Initiate's Armguards", "Initiate's Gauntlets", "Initiate's Plate Belt", "Initiate's Legguards", "Initiate's Sabatons",
    "Robes of the Water Spirit", "Playful Wristbands", "Sun Pearl Gloves", "Unmarred Cord", "Homespun Leggings", "Silk Shoes",
    "Sun Pearl Vest", "Bindings of the Earth Spirit", "Gloves of Splashing Water", "Unmarred Waistband", "Soft Britches", "Summer Shoes",
    "Sun Pearl Chainmail", "Bracers of the Earth Spirit", "Gauntlets of Splashing Water", "Unmarred Chain", "Padded Greaves", "Ringing Boots",
    "Glistening Breastplate", "Sun Pearl Bracers", "Gauntlets of Earth and Water", "Unmarred Belt", "Comfortable Greaves", "Dancing Boots",
    "Protector's Robes", "Healer's Wristwraps", "Gloves of Wisdom", "Cord of Grieving", "Survival Leggings",
    "Vest of Compassion", "Gloves of Verity", "Ropes of Grieving", "Ceremonial Leggings", "Boots of Courage",
    "Empathetic Mail", "Handgrips of Verity", "Links of Grieving", "Service Greaves", "Waders of Bravery",
    "Ritual Breastplate", "Unvarnished Vambraces", "Gauntlets of Mercy", "Cinch of Grieving", "Legguards of the Brave",
    "Flameheart Crossbow", "Jade Crossbow", "Dagger of the Master", "Dagger of Silent Flame", "Dagger of the Hozen", "Jade Hilted Dagger",
    "Mace of the Master", "Humble Cudgel", "Sword of the Hozen", "Shield of Blazing Will", "Jade Shield", "Staff of the Master",
    "Staff of the Hozen", "Sword of the Burning Spirit", "Jade Hilted Sword",
}) do
    wanderingIsleStarterNames[Normalize(name)] = true
end

local function GetCuratedSourceOrigin(source, nativeExpansionID)
    if not source then return nil end
    if wanderingIsleSourceIDs[tonumber(source.sourceID)] or wanderingIsleItemIDs[tonumber(source.itemID)] then
        return { provenanceKey = "wanderingisle", label = "The Wandering Isle", expansionID = 4, method = "curated source" }
    end

    local name = Normalize(source.styleName or source.name)
    if tonumber(source.sourceType) == 2 and tonumber(nativeExpansionID) and tonumber(nativeExpansionID) <= 1 and wanderingIsleStarterNames[name] then
        return { provenanceKey = "wanderingisle", label = "The Wandering Isle", expansionID = 4, method = "curated starter family" }
    end
    return nil
end

local trackedOriginCache = {}

local function GetAppearanceTrackingType()
    return Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Appearance
end

local function GetTrackedSourceOrigin(source)
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or tonumber(source.sourceType) ~= 2 then return nil end
    if trackedOriginCache[sourceID] ~= nil then return trackedOriginCache[sourceID] or nil end

    local trackingType = GetAppearanceTrackingType()
    local getter = C_ContentTracking and C_ContentTracking.GetBestMapForTrackable
    if trackingType == nil or type(getter) ~= "function" then return nil end

    local identifiers = { sourceID }
    local visualID = tonumber(source.visualID)
    if visualID and visualID ~= sourceID then table.insert(identifiers, visualID) end

    local lastResult
    for _, trackableID in ipairs(identifiers) do
        local result, mapID = SafeCall(getter, trackingType, trackableID, true)
        lastResult = result
        if mapID then
            local mapInfo = SafeCall(C_Map and C_Map.GetMapInfo, mapID)
            local mapName = mapInfo and mapInfo.name or "Tracked appearance source"
            local originContext = {
                mapID = mapID,
                mapName = mapName,
                zone = mapName,
                subzone = "",
                mapTrail = BuildMapTrail(mapID),
            }
            local provenance, provenanceKey = ZoneStyle.ResolveProvenance(originContext)
            local origin = {
                provenanceKey = provenanceKey,
                label = provenance and provenance.label or mapName,
                mapID = mapID,
                result = result,
                method = "WoW appearance tracking",
            }
            trackedOriginCache[sourceID] = origin
            return origin
        end
    end

    -- A hard failure is stable for the session. DataPending is intentionally
    -- retried because Blizzard may finish loading the trackable later.
    local failure = Enum and Enum.ContentTrackingResult and Enum.ContentTrackingResult.Failure
    if failure == nil then failure = 2 end
    if lastResult == failure then trackedOriginCache[sourceID] = false end
    return nil
end

local function GetSourceTypeLabel(source)
    local sourceType = tonumber(source and source.sourceType)
    local label = sourceType and _G and _G["TRANSMOG_SOURCE_" .. tostring(sourceType)]
    return Normalize(label)
end

local promotionalSetCache = {}

local function GetPromotionReason(source)
    if not source then return nil end
    if tonumber(source.sourceType) == TRADING_POST_SOURCE_TYPE then
        return "Trading Post appearances are excluded from generated outfits."
    end

    local sourceLabel = GetSourceTypeLabel(source)
    if sourceLabel ~= "" and TextMatchesAny(sourceLabel, promotionalSourceFragments) then
        return "Promotional and shop appearances are excluded from generated outfits."
    end
    if promotionalItemIDs[tonumber(source.itemID)] then
        return "This known promotional reward is excluded from generated outfits."
    end

    local metadata = SourceMetadata(source)
    if TextMatchesAny(metadata, promotionalNameFragments) then
        return "This known subscription, shop, or Recruit-a-Friend appearance is excluded from generated outfits."
    end
    return nil
end

local styleSignalCache = setmetatable({}, { __mode = "k" })
local function GetSourceStyleSignals(source)
    if not source then return { families = {}, intensity = 0 } end
    local text = SourceMetadata(source)
    local cached = styleSignalCache[source]
    if cached and cached.text == text then return cached end

    local families = {}
    local intensity = 0
    for family, keywords in pairs(styleFamilies) do
        local score = 0
        local padded = " " .. text .. " "
        for token, value in pairs(keywords) do
            local normalizedToken = Normalize(token)
            if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
                score = score + value
            end
        end
        if score > 0 then
            families[family] = score
            if dramaticFamilies[family] then intensity = math.max(intensity, score) end
        end
    end

    cached = { text = text, families = families, intensity = intensity }
    styleSignalCache[source] = cached
    return cached
end

local sourceSetCache = {}
local function GetSourceSetIDs(source)
    local sourceID = tonumber(source and source.sourceID)
    if not sourceID or not C_TransmogSets or type(C_TransmogSets.GetSetsContainingSourceID) ~= "function" then
        return {}
    end
    if sourceSetCache[sourceID] then return sourceSetCache[sourceID] end
    local setIDs = SafeCall(C_TransmogSets.GetSetsContainingSourceID, sourceID)
    if type(setIDs) ~= "table" then return {} end
    sourceSetCache[sourceID] = setIDs
    return setIDs
end

local function GetPromotionalSetReason(source)
    if not C_TransmogSets or type(C_TransmogSets.GetSetInfo) ~= "function" then return nil end
    for _, setID in ipairs(GetSourceSetIDs(source)) do
        local cached = promotionalSetCache[setID]
        if cached == nil then
            local setInfo = SafeCall(C_TransmogSets.GetSetInfo, setID)
            if type(setInfo) == "table" then
                local setText = table.concat({ setInfo.name or "", setInfo.label or "", setInfo.description or "" }, " ")
                local namedPromotion = TextMatchesAny(setText, promotionalNameFragments)
                local sourcedPromotion = TextMatchesAny(setText, promotionalSourceFragments)
                cached = (namedPromotion or sourcedPromotion) and (setInfo.name or "Promotional set") or false
                promotionalSetCache[setID] = cached
            end
        end
        if cached then
            return string.format("%s is a promotional set and is excluded from generated outfits.", cached)
        end
    end
    return nil
end

function ZoneStyle.GetSourcePromotionReason(source)
    return GetPromotionReason(source) or GetPromotionalSetReason(source)
end

function ZoneStyle.GetPromotionReason(source)
    return ZoneStyle.GetSourcePromotionReason(source)
end

local AddKeywordScore
local chronicleEventWeights = {
    QUEST_TURNED_IN = 7,
    QUEST_ACCEPTED = 5,
    QUEST_BECAME_ACTIVE = 4,
    QUEST_OBJECTIVE_UPDATED = 3,
    QUEST_STATE_CHANGED = 2,
}

local function AppendQuestText(parts, value)
    if value ~= nil and tostring(value) ~= "" then
        table.insert(parts, tostring(value))
    end
end

local function BuildQuestEvidenceText(quest)
    local parts = {}
    AppendQuestText(parts, quest and quest.questName)
    AppendQuestText(parts, quest and quest.objectiveText)
    AppendQuestText(parts, quest and quest.changeReason)
    AppendQuestText(parts, quest and quest.zone)
    AppendQuestText(parts, quest and quest.subZone)
    for _, objective in ipairs(quest and quest.objectives or {}) do
        AppendQuestText(parts, objective.text or objective.objectiveText)
    end
    return Normalize(table.concat(parts, " "))
end

local function ChronicleCacheKey()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    local events = QC.GetEvents and QC.GetEvents() or {}
    local active = QC.GetActiveQuests and QC.GetActiveQuests() or {}
    local activeStamp = 0
    for _, quest in ipairs(active) do
        activeStamp = activeStamp + (tonumber(quest.updatedAt or quest.lastSeenAt) or 0)
    end
    return table.concat({ tostring(character.key or "UNKNOWN"), tostring(character.lastEventAt or 0), tostring(#events), tostring(#active), tostring(activeStamp) }, ":")
end

local chronicleProfileCache = {}

function ZoneStyle.BuildChronicleProfile(context)
    local records = {}
    local seen = {}
    local events = QC.GetEvents and QC.GetEvents() or {}

    -- Events are append-only, so walk from newest to oldest and merge each
    -- quest into one record. This prevents objective spam from overpowering
    -- the actual sequence of adventures while retaining its useful text.
    local oldestEventIndex = math.max(1, #events - 199)
    for index = #events, oldestEventIndex, -1 do
        local event = events[index]
        local eventWeight = event and chronicleEventWeights[event.eventType]
        local identity = event and (event.questID or event.questName)
        local key = identity and tostring(identity)
        if eventWeight and key then
            local record = seen[key]
            if record then
                record.weight = math.max(record.weight, eventWeight)
                record.text = Normalize(record.text .. " " .. BuildQuestEvidenceText(event))
            elseif #records < 12 then
                record = {
                    key = key,
                    weight = eventWeight,
                    text = BuildQuestEvidenceText(event),
                    questName = event.questName,
                    eventType = event.eventType,
                }
                seen[key] = record
                table.insert(records, record)
            end
        end
    end

    local active = QC.GetActiveQuests and QC.GetActiveQuests() or {}
    table.sort(active, function(left, right)
        return (tonumber(left.updatedAt or left.lastSeenAt) or 0) > (tonumber(right.updatedAt or right.lastSeenAt) or 0)
    end)
    for _, quest in ipairs(active) do
        if #records >= 12 then break end
        local identity = quest.questID or quest.questName
        local key = identity and tostring(identity)
        if key and not seen[key] then
            local record = {
                key = key,
                weight = 4,
                text = BuildQuestEvidenceText(quest),
                questName = quest.questName,
                eventType = "ACTIVE",
            }
            seen[key] = record
            table.insert(records, record)
        end
    end

    local profile = {
        questCount = #records,
        records = records,
        themeScores = {},
        appearanceKeywords = {},
        topThemes = {},
    }

    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    local playerFaction = Normalize(character.faction or (type(UnitFactionGroup) == "function" and UnitFactionGroup("player")))
    if playerFaction == "alliance" or playerFaction == "horde" then
        profile.themeScores[playerFaction] = 1.5
    end

    for rank, record in ipairs(records) do
        local recency = math.max(0.42, 1.12 - ((rank - 1) * 0.065))
        for _, theme in ipairs(chronicleThemes) do
            local matches = TextMatchesAny(record.text, theme.evidence)
            if matches then
                profile.themeScores[theme.key] = (profile.themeScores[theme.key] or 0) + (record.weight * recency)
            end
        end
    end

    local ranked = {}
    for _, theme in ipairs(chronicleThemes) do
        local score = profile.themeScores[theme.key] or 0
        if score > 0 then
            local entry = { theme = theme, score = score }
            table.insert(ranked, entry)
            if not profile.dominantTheme or score > profile.dominantTheme.score then
                profile.dominantTheme = entry
            end
            if theme.kind == "faction" and (not profile.dominantFaction or score > profile.dominantFaction.score) then
                profile.dominantFaction = entry
            elseif theme.kind == "enemy" and (not profile.dominantEnemy or score > profile.dominantEnemy.score) then
                profile.dominantEnemy = entry
            end
            local keywordScale = math.min(1.35, score / 12)
            for token, value in pairs(theme.appearance or {}) do
                profile.appearanceKeywords[token] = (profile.appearanceKeywords[token] or 0) + (value * keywordScale)
            end
        end
    end
    table.sort(ranked, function(left, right)
        if left.score == right.score then return left.theme.key < right.theme.key end
        return left.score > right.score
    end)
    for index = 1, math.min(3, #ranked) do profile.topThemes[index] = ranked[index] end
    return profile
end

function ZoneStyle.GetChronicleProfile(context)
    local key = ChronicleCacheKey()
    if not chronicleProfileCache[key] then
        chronicleProfileCache = { [key] = ZoneStyle.BuildChronicleProfile(context) }
    end
    return chronicleProfileCache[key]
end

function ZoneStyle.GetChronicleSummary(context)
    local profile = ZoneStyle.GetChronicleProfile(context)
    if not profile or profile.questCount == 0 then
        return "Echo: no recent quest signal"
    end
    local labels = {}
    if profile.dominantEnemy then table.insert(labels, profile.dominantEnemy.theme.label) end
    if profile.dominantFaction and (not profile.dominantEnemy or profile.dominantFaction.theme.key ~= profile.dominantEnemy.theme.key) then
        table.insert(labels, profile.dominantFaction.theme.label)
    end
    if #labels == 0 and profile.dominantTheme then table.insert(labels, profile.dominantTheme.theme.label) end
    local signal = #labels > 0 and table.concat(labels, " + ") or "adventuring memory"
    return string.format("Echo: %s • %d recent quest%s", signal, profile.questCount, profile.questCount == 1 and "" or "s")
end

function ZoneStyle.GetSourcePreference(source, context)
    if QC.Wardrobe and QC.Wardrobe.GetSourceZonePreference then
        return QC.Wardrobe.GetSourceZonePreference(source, context)
    end
end

local function ChronicleScore(source, context, multiplier, reasons)
    local chronicle = context and context.chronicleProfile or ZoneStyle.GetChronicleProfile(context)
    if not chronicle or chronicle.questCount == 0 then return 0 end
    return AddKeywordScore(SourceMetadata(source), chronicle.appearanceKeywords, multiplier, reasons, "Echo: ")
end

local modeNameParts = {
    [ZoneStyle.MODE_ZONE_NATIVE] = { adjectives = { "Native", "Local", "Homeland", "Wayfarer's" }, nouns = { "Regalia", "Vanguard", "Attire", "Guard" } },
    [ZoneStyle.MODE_TRAVELER] = { adjectives = { "Trailworn", "Wayfarer's", "Far-Roaming", "Expedition" }, nouns = { "Kit", "Road", "Venture", "Attire" } },
    [ZoneStyle.MODE_CLASS_FANTASY] = { adjectives = { "Heroic", "Classforged", "Champion's", "Battleworn" }, nouns = { "Regalia", "Legacy", "Arsenal", "Oath" } },
    [ZoneStyle.MODE_CHRONICLE_ECHO] = { adjectives = { "Echoed", "Remembered", "Chronicle", "Quest-Bound" }, nouns = { "Echo", "Memory", "Legacy", "Tale" } },
}

function ZoneStyle.GenerateOutfitName(modeKey, context, sources)
    modeKey = ZoneStyle.NormalizeMode(modeKey)
    context = context or ZoneStyle.GetCurrentContext()
    local chronicle = context.chronicleProfile or ZoneStyle.GetChronicleProfile(context)
    local themeEntry = chronicle and (chronicle.dominantEnemy or chronicle.dominantFaction or chronicle.dominantTheme)
    local parts = themeEntry and themeEntry.theme or modeNameParts[modeKey]
    local adjectives = parts.adjectives or modeNameParts[modeKey].adjectives
    local nouns = parts.nouns or modeNameParts[modeKey].nouns
    local seed = tonumber((ZoneStyle.profiles[context.profileKey] or {}).seed) or 1
    for _, source in ipairs(sources or {}) do
        seed = seed + (tonumber(source.visualID or source.sourceID or source.itemID) or 0)
    end
    if themeEntry then seed = seed + math.floor(themeEntry.score * 10) end
    local adjective = adjectives[(seed % #adjectives) + 1]
    local noun = nouns[((math.floor(seed / 7)) % #nouns) + 1]
    local zoneLabel = context.provenanceLabel or context.profileLabel or context.zone or "Azeroth"
    local pattern = seed % 4
    local name
    if pattern == 0 then
        name = adjective .. " " .. noun
    elseif pattern == 1 then
        name = zoneLabel .. " " .. noun
    elseif pattern == 2 then
        name = noun .. " of " .. zoneLabel
    else
        name = (modeKey == ZoneStyle.MODE_CHRONICLE_ECHO and "Echo of " or adjective .. " ") .. (themeEntry and themeEntry.theme.label or zoneLabel)
    end
    if #name > 48 then name = string.sub(name, 1, 48) end
    return name
end

function ZoneStyle.CreateGenerationContext(baseContext)
    local context = {}
    for key, value in pairs(baseContext or ZoneStyle.GetCurrentContext()) do
        context[key] = value
    end
    context.outfitProfile = {
        sourceIDs = {},
        setIDs = {},
        families = {},
        sourceCount = 0,
        themedSources = 0,
    }
    context.chronicleProfile = ZoneStyle.GetChronicleProfile(context)
    return context
end

function ZoneStyle.AddSourceToGenerationContext(context, source)
    local profile = context and context.outfitProfile
    if not profile or not source then return end
    local identity = tonumber(source.sourceID) or tonumber(source.itemID)
    if identity and profile.sourceIDs[identity] then return end
    if identity then profile.sourceIDs[identity] = true end

    profile.sourceCount = profile.sourceCount + 1
    local signals = GetSourceStyleSignals(source)
    local hasTheme = false
    for family, score in pairs(signals.families) do
        profile.families[family] = (profile.families[family] or 0) + score
        hasTheme = true
    end
    if hasTheme then profile.themedSources = profile.themedSources + 1 end
    for _, setID in ipairs(GetSourceSetIDs(source)) do
        profile.setIDs[setID] = (profile.setIDs[setID] or 0) + 1
    end
end

local function GetDominantFamily(families)
    local dominant, dominantScore
    for family, score in pairs(families or {}) do
        if not dominantScore or score > dominantScore then
            dominant, dominantScore = family, score
        end
    end
    return dominant, dominantScore or 0
end

function ZoneStyle.GetSourceCoherence(source, context)
    local profile = context and context.outfitProfile
    if not profile or profile.sourceCount == 0 then return 0, true, nil end

    for _, setID in ipairs(GetSourceSetIDs(source)) do
        if profile.setIDs[setID] then
            return 24, true, "same Blizzard transmog set"
        end
    end

    local signals = GetSourceStyleSignals(source)
    local overlap = 0
    local conflictingFamily
    for family, score in pairs(signals.families) do
        if profile.families[family] then
            overlap = overlap + math.min(score, profile.families[family])
        end
        for profileFamily, profileScore in pairs(profile.families) do
            if profileScore >= 2 and conflictingFamilies[family] and conflictingFamilies[family][profileFamily] then
                conflictingFamily = profileFamily
            end
        end
    end

    local dominantFamily = GetDominantFamily(profile.families)
    if overlap > 0 then
        return math.min(16, 3 + overlap * 1.5), true, "matching " .. tostring(dominantFamily or "outfit") .. " motif"
    end
    if conflictingFamily and signals.intensity >= 3 then
        return -20, false, string.format("dramatic %s conflicts with the outfit's %s motif", GetDominantFamily(signals.families) or "accent", conflictingFamily)
    end
    if profile.sourceCount >= 2 and signals.intensity >= 4 then
        return -18, false, profile.themedSources > 0
            and "dramatic accent does not match the established outfit motif"
            or "dramatic accent would overpower the established neutral outfit"
    end
    return 0, true, nil
end

local dropOriginCache = {}

local function GetDropOrigin(source)
    if not source or not source.sourceID then return "", nil end
    local cached = dropOriginCache[source.sourceID]
    if cached then return cached.text, cached.label end

    local parts = {}
    local label
    local bossDropType = TRANSMOG_SOURCE_BOSS_DROP
    if bossDropType ~= nil and source.sourceType == bossDropType and C_TransmogCollection and C_TransmogCollection.GetAppearanceSourceDrops then
        local drops = SafeCall(C_TransmogCollection.GetAppearanceSourceDrops, source.sourceID)
        for _, drop in ipairs(type(drops) == "table" and drops or {}) do
            if not label and drop.instance then label = drop.instance end
            if drop.instance then table.insert(parts, drop.instance) end
            if drop.encounter then table.insert(parts, drop.encounter) end
            if drop.tier then table.insert(parts, drop.tier) end
        end
    end

    cached = { text = Normalize(table.concat(parts, " ")), label = label }
    dropOriginCache[source.sourceID] = cached
    return cached.text, cached.label
end

function ZoneStyle.GetSourceExpansionID(source)
    local nativeExpansionID = LoadItemMetadata(source)
    local curatedOrigin = GetCuratedSourceOrigin(source, nativeExpansionID)
    return curatedOrigin and curatedOrigin.expansionID or nativeExpansionID
end

function ZoneStyle.GetSourceEligibility(source, modeKey, context)
    context = context or ZoneStyle.GetCurrentContext()
    local preference = ZoneStyle.GetSourcePreference(source, context)
    if preference == "excluded" then
        return false, "excluded", "Excluded from generated outfits in this zone. Manual preview remains available."
    end
    local promotionReason = GetPromotionReason(source) or GetPromotionalSetReason(source)
    if promotionReason then
        return false, "promotional", promotionReason
    end
    if context.eraMax == nil then
        context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    end
    local eraMax, eraLabel = context.eraMax, context.eraLabel

    local nativeExpansionID = LoadItemMetadata(source)
    local curatedOrigin = GetCuratedSourceOrigin(source, nativeExpansionID)
    local expansionID = curatedOrigin and curatedOrigin.expansionID or nativeExpansionID
    if expansionID == nil then
        return false, "pending", "Waiting for WoW to load this item's era."
    end
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local restrictToZoneEra = settings.restrictOutfitsToZoneEra ~= false
    local eraEligibilityText = restrictToZoneEra and ("through " .. tostring(eraLabel)) or "with the zone era limit disabled"
    if restrictToZoneEra and expansionID > eraMax then
        local expansion = ZoneStyle.expansions[expansionID]
        return false, "era", string.format(
            "%s item; this zone permits Classic through %s.",
            expansion and expansion.label or ("Expansion " .. tostring(expansionID)),
            eraLabel
        )
    end

    if not context.provenanceResolved then
        local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
        context.provenanceKey = resolvedKey
        context.provenanceLabel = resolved and resolved.label or context.zone
        context.provenanceResolved = true
    end
    local provenance = provenanceByKey[context.provenanceKey]
    if not provenance then
        return true, "eligible", "Eligible " .. eraEligibilityText .. "."
    end
    context.provenanceKey = provenance.key
    context.provenanceLabel = provenance.label

    if curatedOrigin then
        if curatedOrigin.provenanceKey == provenance.key then
            return true, "eligible", string.format("Curated %s origin; eligible for %s %s.", curatedOrigin.label, provenance.label, eraEligibilityText)
        end
        return false, "zone", string.format("%s starter reward; outside the %s source pool.", curatedOrigin.label, provenance.label)
    end

    local dropText, dropLabel = GetDropOrigin(source)
    if dropText ~= "" then
        if TextMatchesAny(dropText, provenance.origins) then
            return true, "eligible", string.format("Eligible for %s %s.", provenance.label, eraEligibilityText)
        end
        return false, "zone", string.format("%s is outside the %s source pool.", dropLabel or "This boss drop", provenance.label)
    end

    local trackedOrigin = GetTrackedSourceOrigin(source)
    if trackedOrigin and trackedOrigin.provenanceKey then
        if trackedOrigin.provenanceKey == provenance.key then
            return true, "eligible", string.format("WoW tracks this appearance to %s; eligible %s.", trackedOrigin.label, eraEligibilityText)
        end
        return false, "zone", string.format("WoW tracks this appearance to %s, outside the %s source pool.", trackedOrigin.label, provenance.label)
    end

    local metadata = SourceMetadata(source)
    if TextMatchesAny(metadata, provenance.origins) then
        return true, "eligible", string.format("Eligible for %s %s.", provenance.label, eraEligibilityText)
    end
    local paddedMetadata = " " .. metadata .. " "
    for _, marker in ipairs(provenanceOriginMarkers) do
        if not marker.profileKeys[provenance.key] and paddedMetadata:find(" " .. marker.text .. " ", 1, true) then
            return false, "zone", string.format("Associated with %s, not %s.", marker.profile.label, provenance.label)
        end
    end

    return true, "eligible", restrictToZoneEra
        and "Era eligible; no conflicting source zone is reported by WoW."
        or "Zone era limit disabled; no conflicting source zone is reported by WoW."
end

function ZoneStyle.GetContextRestrictionLabel(context)
    context = context or ZoneStyle.GetCurrentContext()
    if context.eraMax == nil then
        context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    end
    if not context.provenanceResolved then
        local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
        context.provenanceKey = resolvedKey
        context.provenanceLabel = resolved and resolved.label or context.zone
        context.provenanceResolved = true
    end
    local eraLabel, eraShortLabel = context.eraLabel, context.eraShortLabel
    local provenance = provenanceByKey[context.provenanceKey]
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local eraText = settings.restrictOutfitsToZoneEra ~= false and ("Through " .. tostring(eraShortLabel)) or "Zone era limit off"
    return string.format("%s%s", eraText, provenance and (" • " .. provenance.label .. " sources") or ""), eraLabel, provenance
end

AddKeywordScore = function(text, keywords, multiplier, reasons, reasonPrefix)
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
    local modeSeed = modeKey == ZoneStyle.MODE_TRAVELER and 37
        or (modeKey == ZoneStyle.MODE_CLASS_FANTASY and 73
        or (modeKey == ZoneStyle.MODE_CHRONICLE_ECHO and 109 or 11))
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
        score = score + ChronicleScore(source, context, 0.22, reasons)
        if definition and (definition.key == "BACK" or definition.key == "TABARD") then score = score + 1.2 end
    elseif modeKey == ZoneStyle.MODE_TRAVELER then
        score = score + AddKeywordScore(text, travelerKeywords, 1.25, reasons, "Travel: ")
        score = score + AddKeywordScore(text, travelerAvoid, 1.0, reasons)
        score = score + AddKeywordScore(text, profile.keywords, 0.28, reasons, "Local: ")
        score = score + AddKeywordScore(text, classProfile, 0.16, reasons, "Class: ")
        score = score + ChronicleScore(source, context, 0.18, reasons)
        if definition and (definition.key == "BACK" or definition.key == "WAIST" or definition.key == "FEET" or definition.key == "SHIRT") then score = score + 2.0 end
    elseif modeKey == ZoneStyle.MODE_CLASS_FANTASY then
        score = score + AddKeywordScore(text, classProfile, 1.35, reasons, "Class: ")
        score = score + AddKeywordScore(text, profile.keywords, 0.24, reasons, "Local: ")
        score = score + AddKeywordScore(text, travelerKeywords, 0.10, reasons, "Travel: ")
        score = score + ChronicleScore(source, context, 0.15, reasons)
        if definition and (definition.weaponRole or definition.key == "HEAD" or definition.key == "SHOULDER" or definition.key == "CHEST") then score = score + 2.0 end
        score = score + math.min(2.0, tonumber(source.quality or 0) * 0.35)
    else
        score = score + ChronicleScore(source, context, 1.35, reasons)
        score = score + AddKeywordScore(text, profile.keywords, 0.30, reasons, "Local: ")
        score = score + AddKeywordScore(text, classProfile, 0.18, reasons, "Class: ")
        score = score + AddKeywordScore(text, travelerKeywords, 0.12, reasons, "Travel: ")
        if definition and (definition.key == "BACK" or definition.key == "CHEST" or definition.weaponRole) then score = score + 1.2 end
    end

    if context.outfitProfile then
        local coherenceScore, coherent, coherenceReason = ZoneStyle.GetSourceCoherence(source, context)
        score = score + coherenceScore
        if #reasons < 4 and coherenceReason and (coherenceScore > 0 or not coherent) then
            table.insert(reasons, (coherent and "Match: " or "Clash: ") .. coherenceReason)
        end
    end

    if ZoneStyle.GetSourcePreference(source, context) == "favorite" then
        score = score + 24
        if #reasons < 4 then table.insert(reasons, "Zone favorite") end
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
        local eligible = ZoneStyle.GetSourceEligibility(source, modeKey, context)
        local _, coherent = ZoneStyle.GetSourceCoherence(source, context)
        if eligible and coherent then
            local weight, score = ZoneStyle.WeightForSource(source, definition, modeKey, context)
            local entry = { source = source, weight = weight, score = score }
            if source.sourceID == excludeSourceID then
                fallback = entry
            else
                total = total + weight
                table.insert(pool, entry)
            end
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
    for index = #(candidates or {}), 1, -1 do
        local candidate = candidates[index]
        local eligible = ZoneStyle.GetSourceEligibility(candidate.source, modeKey, context)
        local _, coherent = ZoneStyle.GetSourceCoherence(candidate.source, context)
        if not eligible or not coherent then table.remove(candidates, index) end
    end
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

function ZoneStyle.GetEligibilitySummary(source, modeKey, context)
    local eligible, kind, reason = ZoneStyle.GetSourceEligibility(source, modeKey, context)
    return eligible, kind, reason
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
