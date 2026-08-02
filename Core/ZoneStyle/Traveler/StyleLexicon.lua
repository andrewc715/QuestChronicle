local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
ZoneStyle.Traveler = ZoneStyle.Traveler or {}
local T = ZoneStyle.Traveler

T.INSTRUMENTATION_VERSION = 2
T.DEFAULT_MISMATCH_BUDGET = 2
T.CONFIG = {
    pairWeights = {
        palette = 0.40,
        material = 0.22,
        finish = 0.14,
        visualWeight = 0.10,
        motif = 0.09,
        provenance = 0.05,
    },
    profileWeights = {
        palette = 0.38,
        material = 0.22,
        finish = 0.16,
        visualWeight = 0.12,
        motif = 0.12,
    },
    thresholds = {
        cohesive = 0.70,
        supportedCohesion = 0.65,
        mild = 0.45,
        postalCohesion = 0.40,
        loudImpact = 0.55,
        echo = 0.65,
        mildBridge = 0.58,
        strongBridge = 0.65,
        postalBridge = 0.55,
        severe = 0.72,
    },
}

T.ANCHOR_SLOT_WEIGHTS = {
    CHEST = 1.00,
    LEGS = 0.90,
    SHOULDER = 1.00,
    ONE_HAND = 0.90,
    TWO_HAND = 0.90,
    RANGED = 0.90,
    OFF_HAND = 0.45,
}

T.SLOT_VISIBILITY_WEIGHTS = {
    CHEST = 1.00,
    SHOULDER = 1.00,
    HEAD = 0.90,
    ONE_HAND = 0.90,
    TWO_HAND = 0.90,
    RANGED = 0.90,
    LEGS = 0.80,
    HANDS = 0.65,
    OFF_HAND = 0.65,
    FEET = 0.60,
    BACK = 0.55,
    WAIST = 0.50,
    WRIST = 0.25,
    SHIRT = 0.20,
    TABARD = 0.20,
}

T.SUPPORT_SLOT_ORDER = {
    "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD",
}

T.LEXICON = {
    palette = {
        neutral = { gray = 4, grey = 4, silver = 3, iron = 2, slate = 3, ashen = 3, ash = 2, pewter = 3, stone = 2 },
        earth = { brown = 4, bronze = 3, copper = 3, bark = 4, hide = 3, leather = 2, sand = 3, tan = 3, khaki = 4, earthen = 4, clay = 3, rust = 3, rustic = 3 },
        steel = { steel = 5, plate = 2, iron = 3, mithril = 4, thorium = 4, cobalt = 4, saronite = 4, metal = 2, chain = 2 },
        blue = { blue = 5, azure = 5, cobalt = 4, sapphire = 5, frost = 3, ice = 3, icy = 3, winter = 2, sea = 2, tide = 2 },
        green = { green = 5, emerald = 5, verdant = 5, jade = 5, moss = 4, olive = 4, fel = 2, nature = 2, leaf = 3, vine = 3 },
        red = { red = 5, crimson = 5, scarlet = 5, blood = 4, ruby = 5, ember = 3, flame = 2, fiery = 3, fire = 2 },
        gold = { gold = 5, golden = 5, gilt = 4, brass = 4, amber = 4, sun = 2, radiant = 2, light = 1 },
        purple = { purple = 5, violet = 5, amethyst = 5, arcane = 3, twilight = 3, void = 2, magenta = 5 },
        pale = { white = 5, ivory = 5, pearl = 4, bone = 3, pale = 4, light = 1, frost = 2 },
        dark = { black = 5, dark = 4, ebon = 5, ebony = 5, shadow = 4, night = 3, midnight = 4, obsidian = 4 },
    },
    material = {
        plate = { plate = 6, breastplate = 6, chestplate = 6, cuirass = 5, gauntlet = 3, sabaton = 4, greave = 3, pauldrons = 4, helm = 2 },
        mail = { mail = 6, chain = 5, links = 4, ringmail = 5, hauberk = 5 },
        leather = { leather = 6, hide = 5, buckskin = 6, rawhide = 5, brigandine = 3 },
        cloth = { cloth = 6, linen = 5, wool = 5, silk = 5, weave = 4, mageweave = 5, robe = 3, shirt = 2 },
        scale = { scale = 6, scales = 6, dragonscale = 7, barkplate = 4, chitin = 5 },
        hide = { fur = 5, pelt = 5, hide = 4, skin = 3, woolly = 4 },
        bone = { bone = 6, skull = 5, tusk = 5, horn = 4, skeletal = 6 },
        wood = { wood = 6, wooden = 6, bark = 5, branch = 5, bamboo = 5 },
        crystal = { crystal = 6, crystalline = 6, gem = 4, jewel = 4, glass = 3, naaru = 4 },
        mixed = { reinforced = 2, composite = 4, patchwork = 5, scavenged = 5 },
    },
    finish = {
        weathered = { weathered = 6, worn = 5, battered = 5, battleworn = 7, corroded = 6, rusted = 6, decrepit = 6, shattered = 4, frostworn = 5, frost_worn = 5, scarred = 5, patched = 4 },
        plain = { simple = 5, plain = 6, field = 3, basic = 4, common = 3, recruit = 3, sturdy = 3, practical = 5 },
        military = { soldier = 5, warrior = 4, guard = 4, marshal = 5, combatant = 5, battle = 3, campaign = 4, judicator = 4, vindicator = 4, protector = 4, valor = 3 },
        polished = { polished = 6, burnished = 6, gleaming = 5, shining = 5, silvered = 4, gilded = 5, immaculate = 6 },
        ornate = { ornate = 6, royal = 5, noble = 5, imperial = 5, ceremonial = 6, jeweled = 6, crown = 4, replica = 2, conqueror = 3 },
        primal = { savage = 5, tribal = 5, primal = 6, trophy = 5, wyrm = 4, beast = 3, fang = 4, claw = 4, bark = 3 },
        magical = { arcane = 5, enchanted = 5, mystic = 5, eternal = 5, radiant = 4, frost = 3, fel = 4, void = 4, celestial = 5, spell = 3 },
    },
    motif = {
        frontier = { frontier = 6, outpost = 5, field = 4, trail = 4, scout = 4, expedition = 5, explorer = 5, rugged = 4, weathered = 4 },
        alliance = { alliance = 6, stormwind = 6, lion = 5, valor = 4, lightforge = 4, knight = 3 },
        outland = { outland = 7, shattrath = 6, naaru = 5, nether = 5, draenei = 5, maghar = 5, fel = 3, shattered = 3, sha_tari = 6, shatari = 6 },
        demonic = { demon = 6, demonic = 6, fel = 7, legion = 5, infernal = 5, diabolic = 5 },
        draconic = { dragon = 6, draconic = 6, wyrm = 5, scale = 3, dragonflight = 5 },
        tribal = { tribal = 6, troll = 4, loa = 5, totem = 5, tusk = 4, bone = 3 },
        crusader = { crusader = 6, templar = 5, paladin = 5, holy = 4, lightforge = 5, judicator = 4 },
        royal = { royal = 6, noble = 5, crown = 5, imperial = 5, conqueror = 4, admiral = 4 },
        trophy = { trophy = 7, wyrm = 4, beast = 4, fang = 4, claw = 4, skull = 4, hunter = 3 },
        mercenary = { marauder = 6, brigand = 5, mercenary = 6, freebooter = 5, battleworn = 4, veteran = 4 },
        frost = { frost = 6, ice = 5, winter = 5, glacial = 6, frozen = 5 },
        fel = { fel = 7, legion = 5, corrupt = 5, chaos = 5 },
        mechanical = { mechanical = 7, gear = 4, cog = 5, clockwork = 6, machine = 5 },
    },
    loudness = {
        crown = 0.22, eternal = 0.18, radiant = 0.18, celestial = 0.20, jeweled = 0.24,
        glowing = 0.20, fiery = 0.18, infernal = 0.18, frost = 0.10, fel = 0.14,
        void = 0.16, ornate = 0.18, royal = 0.14, trophy = 0.12, massive = 0.12,
        colossal = 0.15, grand = 0.10, apocalypse = 0.28, annihilator = 0.25,
    },
}

T.PALETTE_RELATIONS = {
    neutral = { steel = 0.82, earth = 0.70, blue = 0.68, red = 0.58, green = 0.60, gold = 0.62, purple = 0.58, pale = 0.80, dark = 0.82 },
    earth = { steel = 0.66, green = 0.76, gold = 0.68, red = 0.58, pale = 0.62, dark = 0.64 },
    steel = { blue = 0.78, pale = 0.76, dark = 0.76, gold = 0.62, red = 0.56, green = 0.52 },
    blue = { pale = 0.78, purple = 0.68, steel = 0.78, dark = 0.62, gold = 0.42 },
    green = { earth = 0.76, gold = 0.58, dark = 0.62, red = 0.28, purple = 0.30 },
    red = { gold = 0.78, dark = 0.62, earth = 0.58, pale = 0.52, green = 0.28, blue = 0.34 },
    gold = { red = 0.78, earth = 0.68, pale = 0.72, dark = 0.64, blue = 0.42 },
    purple = { dark = 0.70, pale = 0.58, blue = 0.68, green = 0.30 },
    pale = { steel = 0.76, blue = 0.78, gold = 0.72, neutral = 0.80, dark = 0.60 },
    dark = { neutral = 0.82, steel = 0.76, red = 0.62, purple = 0.70, green = 0.62, gold = 0.64 },
}

T.MATERIAL_RELATIONS = {
    plate = { mail = 0.82, scale = 0.86, leather = 0.58, cloth = 0.32, bone = 0.52, crystal = 0.56, mixed = 0.70 },
    mail = { plate = 0.82, scale = 0.82, leather = 0.66, cloth = 0.42, hide = 0.58, mixed = 0.72 },
    leather = { mail = 0.66, hide = 0.86, cloth = 0.72, scale = 0.62, plate = 0.58, wood = 0.62, mixed = 0.74 },
    cloth = { leather = 0.72, hide = 0.62, crystal = 0.48, plate = 0.32, mixed = 0.64 },
    scale = { plate = 0.86, mail = 0.82, leather = 0.62, hide = 0.66, bone = 0.64, mixed = 0.72 },
    hide = { leather = 0.86, scale = 0.66, cloth = 0.62, bone = 0.62, wood = 0.64, mixed = 0.70 },
    bone = { hide = 0.62, scale = 0.64, wood = 0.60, plate = 0.52, mixed = 0.66 },
    wood = { hide = 0.64, leather = 0.62, bone = 0.60, cloth = 0.50, mixed = 0.62 },
    crystal = { plate = 0.56, cloth = 0.48, mixed = 0.62 },
    mixed = { plate = 0.70, mail = 0.72, leather = 0.74, cloth = 0.64, scale = 0.72, hide = 0.70, bone = 0.66, wood = 0.62, crystal = 0.62 },
}

T.FINISH_RELATIONS = {
    weathered = { plain = 0.88, military = 0.78, primal = 0.78, polished = 0.42, ornate = 0.24, magical = 0.38 },
    plain = { weathered = 0.88, military = 0.82, polished = 0.62, primal = 0.62, ornate = 0.46, magical = 0.46 },
    military = { weathered = 0.78, plain = 0.82, polished = 0.72, ornate = 0.60, primal = 0.54, magical = 0.50 },
    polished = { military = 0.72, plain = 0.62, ornate = 0.78, magical = 0.66, weathered = 0.42, primal = 0.36 },
    ornate = { polished = 0.78, military = 0.60, magical = 0.72, plain = 0.46, primal = 0.30, weathered = 0.24 },
    primal = { weathered = 0.78, plain = 0.62, military = 0.54, magical = 0.44, polished = 0.36, ornate = 0.30 },
    magical = { ornate = 0.72, polished = 0.66, military = 0.50, plain = 0.46, primal = 0.44, weathered = 0.38 },
}
