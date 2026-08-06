local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

-- Reviewed, explicit evidence channels. These values describe place identity;
-- they are observational in v1.11.0 and never alter legacy selection weights.
Zone.CANONICAL_STYLES = {
    quelthalas = {
        cultures = { sindorei = 1.0, magister = 0.9, spellbreaker = 0.8 },
        climates = { temperate = 0.7 }, terrain = { enchanted_forest = 0.8, sunwell = 1.0 },
        palette = { gold = 1.0, red = 0.9, pale = 0.5 }, materials = { plate = 0.7, cloth = 0.6, crystal = 0.6 },
        finishes = { ornate = 1.0, polished = 0.9, magical = 0.8 }, motifs = { royal = 0.8, crusader = 0.6 },
        magic = { arcane = 1.0, light = 0.8, sunwell = 1.0 }, silhouette = { elegant = 1.0, angular = 0.6 },
        avoids = { crude = 1.0, savage = 0.8, rusted = 0.7 },
    },
    amani = {
        cultures = { amani = 1.0, troll = 0.9, loa = 0.9 }, climates = { forest = 0.9, mountain = 0.8 },
        terrain = { pine_forest = 0.9, highlands = 1.0 }, palette = { green = 0.8, earth = 1.0, dark = 0.4 },
        materials = { hide = 1.0, bone = 0.9, wood = 0.8, leather = 0.7 }, finishes = { primal = 1.0, weathered = 0.8 },
        motifs = { tribal = 1.0, trophy = 0.7 }, magic = { loa = 1.0, hex = 0.8, voodoo = 0.7 },
        silhouette = { layered = 0.8, trophy_heavy = 0.8 }, avoids = { imperial = 0.8, polished = 0.6 },
    },
    harandar = {
        cultures = { haranir = 1.0, primal_guardian = 0.8 }, climates = { subterranean = 0.8, humid = 0.7 },
        terrain = { roots = 1.0, fungal = 1.0, living_wood = 0.9 }, palette = { green = 1.0, purple = 0.6, earth = 0.7 },
        materials = { wood = 1.0, hide = 0.7, mixed = 0.6 }, finishes = { primal = 1.0, magical = 0.7, weathered = 0.5 },
        motifs = { tribal = 0.7, frontier = 0.5 }, magic = { bioluminescent = 1.0, dream = 0.7, memory = 0.6 },
        silhouette = { organic = 1.0, rooted = 0.8 }, avoids = { industrial = 1.0, mechanical = 1.0, polished = 0.5 },
    },
    voidstorm = {
        cultures = { rendorei = 1.0, ethereal = 0.7 }, climates = { cosmic = 1.0 }, terrain = { rifts = 1.0, void_space = 1.0 },
        palette = { purple = 1.0, dark = 1.0, blue = 0.4 }, materials = { crystal = 0.8, cloth = 0.6, plate = 0.5 },
        finishes = { magical = 1.0, ornate = 0.6, polished = 0.5 }, motifs = { fel = 0.2, demonic = 0.2 },
        magic = { void = 1.0, shadow = 0.9, entropy = 0.8, astral = 0.7 }, silhouette = { cosmic = 1.0, sharp = 0.7 },
        avoids = { pastoral = 1.0, rustic = 0.9, harvest = 0.6 },
    },
    hallowfall = {
        cultures = { arathi = 1.0, lamplighter = 0.9 }, climates = { subterranean = 0.8 }, terrain = { cavern = 0.8, beacon_fields = 0.9 },
        palette = { gold = 1.0, pale = 0.8, steel = 0.8, red = 0.4 }, materials = { plate = 1.0, mail = 0.6 },
        finishes = { military = 1.0, polished = 0.8, magical = 0.6 }, motifs = { crusader = 1.0, alliance = 0.5 },
        magic = { light = 1.0, sacred_flame = 1.0 }, silhouette = { templar = 1.0, expedition = 0.7 },
        avoids = { necrotic = 1.0, void = 1.0 },
    },
    khazalgar = {
        cultures = { earthen = 1.0, nerubian = 0.7, goblin_cartel = 0.5 }, climates = { subterranean = 1.0 },
        terrain = { stone_depths = 1.0, forge = 0.9, webs = 0.6 }, palette = { earth = 0.9, steel = 1.0, dark = 0.5 },
        materials = { plate = 0.9, stone = 1.0, scale = 0.6, mixed = 0.7 }, finishes = { military = 0.6, plain = 0.6, polished = 0.4 },
        motifs = { mechanical = 0.8, frontier = 0.5 }, magic = { titan = 0.9 }, silhouette = { sturdy = 1.0, utility = 0.9 },
        avoids = { delicate = 0.8 },
    },
    dragonisles = {
        cultures = { dragonflight = 1.0, dracthyr = 0.7 }, climates = { varied = 1.0 }, terrain = { volcanic = 0.6, plains = 0.6, azure_wilds = 0.6, titan_ruins = 0.8 },
        palette = { red = 0.7, blue = 0.7, green = 0.7, gold = 0.7, dark = 0.5 }, materials = { scale = 1.0, plate = 0.7, crystal = 0.5 },
        finishes = { primal = 0.8, magical = 0.7, polished = 0.5 }, motifs = { draconic = 1.0 }, magic = { elemental = 0.8, titan = 0.7 },
        silhouette = { draconic = 1.0, winged = 0.5 }, avoids = {},
    },
    cataclysm = {
        cultures = { expedition = 0.7 }, climates = { elemental = 1.0 }, terrain = { upheaval = 1.0, titan_ruins = 0.7 },
        palette = { earth = 0.8, red = 0.7, blue = 0.6, purple = 0.5 }, materials = { plate = 0.6, scale = 0.7, stone = 0.8 },
        finishes = { weathered = 0.9, primal = 0.8, military = 0.5 }, motifs = { draconic = 0.8, frontier = 0.7 },
        magic = { elemental = 1.0, twilight = 0.8, titan = 0.6 }, silhouette = { expedition = 0.8, battle_worn = 0.8 }, avoids = { cosmic = 0.6 },
    },
    draenor = {
        cultures = { orc_clan = 1.0, draenei = 0.7, arakkoa = 0.8 }, climates = { primal = 0.8 }, terrain = { savage_world = 0.9 },
        palette = { earth = 1.0, steel = 0.8, pale = 0.4 }, materials = { plate = 0.8, bone = 0.8, hide = 0.8, crystal = 0.6 },
        finishes = { primal = 1.0, military = 0.8, weathered = 0.6 }, motifs = { tribal = 0.8, mechanical = 0.5, trophy = 0.6 },
        magic = { naaru = 0.6, primal = 0.7 }, silhouette = { clan_war = 0.9, rugged = 0.8 }, avoids = { cosmic = 0.5 },
    },
    brokenisles = {
        cultures = { nightborne = 0.9, highmountain = 0.8, vrykul = 0.8, kaldorei = 0.6 }, climates = { varied = 0.8 }, terrain = { ancient_ruins = 0.9 },
        palette = { purple = 0.7, green = 0.6, steel = 0.6, earth = 0.5 }, materials = { plate = 0.6, leather = 0.6, hide = 0.5, crystal = 0.5 },
        finishes = { magical = 0.8, primal = 0.6, military = 0.5 }, motifs = { fel = 0.7, tribal = 0.4, royal = 0.5 },
        magic = { arcane = 0.8, fel = 0.8, titan = 0.5 }, silhouette = { ancient = 0.8, runic = 0.8 }, avoids = {},
    },
    kaldorei = {
        cultures = { kaldorei = 1.0, sentinel = 0.9, warden = 0.9 }, climates = { forest = 1.0, moonlit = 0.8 }, terrain = { ancient_grove = 1.0 },
        palette = { green = 1.0, purple = 0.8, blue = 0.5, dark = 0.4 }, materials = { leather = 0.8, wood = 0.8, cloth = 0.6 },
        finishes = { magical = 0.7, primal = 0.6, plain = 0.4 }, motifs = { frontier = 0.3 }, magic = { lunar = 1.0, nature = 0.9, dream = 0.8 },
        silhouette = { sentinel = 1.0, warden = 0.9, elegant = 0.7 }, avoids = { fel = 1.0, industrial = 1.0 },
    },
    zandalar = {
        cultures = { zandalari = 1.0, loa = 0.9 }, climates = { tropical = 0.9 }, terrain = { jungle = 0.9, temple_city = 0.8 },
        palette = { gold = 1.0, red = 0.6, green = 0.5, earth = 0.5 }, materials = { bone = 0.8, scale = 0.8, plate = 0.6 },
        finishes = { ornate = 0.9, primal = 0.8, polished = 0.7 }, motifs = { tribal = 1.0, royal = 0.8, trophy = 0.7 },
        magic = { loa = 1.0, blood = 0.5, voodoo = 0.5 }, silhouette = { imperial_troll = 1.0, ritual = 0.8 }, avoids = {},
    },
    nazjatar = {
        cultures = { naga = 1.0, azsharan = 0.9 }, climates = { deep_sea = 1.0 }, terrain = { coral = 1.0, abyss = 0.8 },
        palette = { blue = 1.0, green = 0.7, pale = 0.6, purple = 0.5 }, materials = { scale = 1.0, crystal = 0.6, mixed = 0.5 },
        finishes = { ornate = 0.8, magical = 0.8, weathered = 0.5 }, motifs = { royal = 0.7, draconic = 0.2 },
        magic = { tide = 1.0, abyssal = 0.8 }, silhouette = { serpentine = 1.0, aquatic = 0.9 }, avoids = { rustic = 0.7 },
    },
    kultiras = {
        cultures = { kul_tiran = 1.0, sailor = 0.9, drust = 0.7 }, climates = { maritime = 1.0, stormy = 0.8 }, terrain = { coast = 1.0, wicker_woods = 0.6 },
        palette = { blue = 1.0, neutral = 0.7, earth = 0.5 }, materials = { cloth = 0.7, leather = 0.7, wood = 0.6, plate = 0.5 },
        finishes = { military = 0.8, weathered = 0.8, plain = 0.7 }, motifs = { royal = 0.4, frontier = 0.7 },
        magic = { storm = 0.8, tide = 0.8, drust = 0.7 }, silhouette = { naval = 1.0, layered = 0.7 }, avoids = {},
    },
    pandaria = {
        cultures = { pandaren = 1.0, mogu = 0.6 }, climates = { temperate = 0.8 }, terrain = { bamboo = 0.9, jade_landscape = 1.0 },
        palette = { green = 1.0, gold = 0.7, red = 0.5, pale = 0.4 }, materials = { cloth = 0.8, wood = 0.7, stone = 0.6, leather = 0.5 },
        finishes = { ornate = 0.6, plain = 0.7, magical = 0.5 }, motifs = { tribal = 0.3, draconic = 0.3 },
        magic = { celestial = 1.0, sha = 0.6 }, silhouette = { layered = 0.9, wandering = 0.7 }, avoids = {},
    },
    northrend = {
        cultures = { vrykul = 0.9, tuskarr = 0.8, scourge = 0.7 }, climates = { arctic = 1.0 }, terrain = { snow = 1.0, titan_ruins = 0.7 },
        palette = { blue = 1.0, pale = 0.9, steel = 0.7, dark = 0.5 }, materials = { hide = 0.9, plate = 0.8, mail = 0.6, bone = 0.5 },
        finishes = { weathered = 1.0, military = 0.7, magical = 0.5 }, motifs = { frost = 1.0, trophy = 0.4 },
        magic = { frost = 1.0, runic = 0.8, necrotic = 0.6, titan = 0.5 }, silhouette = { cold_weather = 1.0, expedition = 0.8 }, avoids = { tropical = 1.0 },
    },
    outland = {
        cultures = { draenei = 0.9, ethereal = 0.8, maghar = 0.7 }, climates = { shattered = 1.0 }, terrain = { nether = 1.0, crystal = 0.8, spores = 0.5 },
        palette = { purple = 0.8, green = 0.7, steel = 0.6, earth = 0.5 }, materials = { crystal = 0.9, plate = 0.6, leather = 0.6, mixed = 0.7 },
        finishes = { weathered = 0.9, magical = 0.8, military = 0.5 }, motifs = { outland = 1.0, fel = 0.7, frontier = 0.7 },
        magic = { nether = 1.0, fel = 0.8, naaru = 0.8 }, silhouette = { survival = 1.0, shattered = 0.8 }, avoids = {},
    },
    bfa = {
        cultures = { alliance = 0.7, horde = 0.7, expedition = 0.8 }, climates = { wartime = 1.0 }, terrain = { warfront = 0.9, naval = 0.7 },
        palette = { steel = 0.9, blue = 0.5, red = 0.5, gold = 0.4 }, materials = { plate = 0.8, mail = 0.7, mixed = 0.6 },
        finishes = { military = 1.0, weathered = 0.7, polished = 0.4 }, motifs = { alliance = 0.7, mechanical = 0.6, frontier = 0.6 },
        magic = { azerite = 1.0 }, silhouette = { uniform = 1.0, expedition = 0.8 }, avoids = {},
    },
    shadowlands = {
        cultures = { kyrian = 0.7, necrolord = 0.7, night_fae = 0.7, venthyr = 0.7 }, climates = { afterlife = 1.0 }, terrain = { eternal_realms = 1.0 },
        palette = { purple = 0.8, pale = 0.7, dark = 0.8, blue = 0.5, red = 0.5 }, materials = { plate = 0.6, cloth = 0.7, bone = 0.6, crystal = 0.5 },
        finishes = { magical = 1.0, ornate = 0.8, polished = 0.5 }, motifs = { royal = 0.4, tribal = 0.3 },
        magic = { anima = 1.0, soul = 1.0, death = 0.9 }, silhouette = { covenant = 1.0, otherworldly = 0.9 }, avoids = {},
    },
    human = {
        cultures = { human_kingdoms = 1.0, stormwind = 0.9, arathi = 0.7, gilnean = 0.6 }, climates = { temperate = 0.8 }, terrain = { kingdom = 1.0 },
        palette = { steel = 1.0, blue = 0.8, gold = 0.7, red = 0.4 }, materials = { plate = 1.0, mail = 0.7, leather = 0.4 },
        finishes = { military = 1.0, polished = 0.7, ornate = 0.5 }, motifs = { alliance = 1.0, royal = 0.8, crusader = 0.5 },
        magic = { light = 0.5 }, silhouette = { knightly = 1.0, militia = 0.7 }, avoids = { fel = 1.0 },
    },
    orcish = {
        cultures = { orc = 1.0, horde = 0.8, clan = 0.9 }, climates = { frontier = 0.9 }, terrain = { badlands = 0.7, clanlands = 0.8 },
        palette = { earth = 1.0, dark = 0.7, steel = 0.7, red = 0.5 }, materials = { plate = 0.7, hide = 0.9, bone = 0.8, leather = 0.7 },
        finishes = { primal = 1.0, weathered = 0.8, military = 0.7 }, motifs = { tribal = 0.8, trophy = 0.8, frontier = 0.7 },
        magic = { shamanic = 0.6 }, silhouette = { spiked = 1.0, clan_war = 0.9 }, avoids = { delicate = 1.0 },
    },
    forsaken = {
        cultures = { forsaken = 1.0, lordaeron = 0.7, apothecary = 0.9 }, climates = { blighted = 1.0 }, terrain = { ruins = 0.9, plague_lands = 1.0 },
        palette = { dark = 1.0, green = 0.7, purple = 0.5, neutral = 0.5 }, materials = { leather = 0.7, cloth = 0.7, bone = 0.8, plate = 0.5 },
        finishes = { weathered = 1.0, magical = 0.6, military = 0.5 }, motifs = { demonic = 0.2, royal = 0.4, trophy = 0.4 },
        magic = { blight = 1.0, necrotic = 0.9, shadow = 0.6 }, silhouette = { apothecary = 0.9, ruined_royal = 0.8 }, avoids = { radiant = 1.0 },
    },
    easternkingdoms = {
        cultures = { frontier_kingdoms = 0.8, militia = 0.8 }, climates = { temperate = 0.8 }, terrain = { woodland = 0.7, mountain = 0.7, road = 0.8 },
        palette = { earth = 0.8, steel = 0.8, neutral = 0.7, green = 0.4 }, materials = { leather = 0.8, plate = 0.6, mail = 0.6, hide = 0.4 },
        finishes = { weathered = 0.8, plain = 1.0, military = 0.6 }, motifs = { frontier = 1.0, alliance = 0.3 },
        magic = {}, silhouette = { practical = 1.0, road_worn = 0.9 }, avoids = { cosmic = 1.0 },
    },
    kalimdor = {
        cultures = { wildland = 0.8, tribal = 0.7 }, climates = { desert = 0.7, jungle = 0.7, forest = 0.6 }, terrain = { wilderness = 1.0, ancient_ruins = 0.6 },
        palette = { earth = 1.0, green = 0.8, pale = 0.4 }, materials = { hide = 0.9, leather = 0.9, bone = 0.6, wood = 0.6 },
        finishes = { primal = 0.8, weathered = 1.0, plain = 0.7 }, motifs = { tribal = 0.7, frontier = 0.8 },
        magic = { nature = 0.6 }, silhouette = { survival = 1.0, expedition = 0.8 }, avoids = { regal = 0.8, cosmic = 1.0 },
    },
    azeroth = {
        cultures = {}, climates = {}, terrain = {}, palette = { neutral = 0.8, earth = 0.7, steel = 0.6 },
        materials = { mixed = 1.0, leather = 0.6, plate = 0.5 }, finishes = { plain = 1.0, weathered = 0.8, military = 0.4 },
        motifs = { frontier = 1.0 }, magic = {}, silhouette = { adventurer = 1.0, practical = 0.9 }, avoids = {},
    },
}

function Zone.GetCanonicalStyle(profileKey)
    return Zone.Copy(Zone.CANONICAL_STYLES[profileKey] or {})
end
