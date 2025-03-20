--
-- Data Module
-- Item data, globals and misc functions
--

Crafty_Data = {}

-- Table of items and prices, if they are crafted it stores the number produced
-- and a list of reagents required
Crafty_Items = {}

-- Table of Trade Skill data, ie names
Crafty_TradeSkills = {}

-- Table of character data, ie Trade Skills
Crafty_Characters = {}

-- Import
local Data = Crafty_Data
local ScanTip = Crafty_ScanningTooltip
local GetItemInfo = GetItemInfo
local GetServerTime = GetServerTime
local LE_ITEM_QUALITY_EPIC = LE_ITEM_QUALITY_EPIC
local LE_ITEM_QUALITY_RARE = LE_ITEM_QUALITY_RARE
local LE_ITEM_QUALITY_UNCOMMON = LE_ITEM_QUALITY_UNCOMMON
local math = math
local next = next
local pairs = pairs
local print = print
local string = string
local tonumber = tonumber
local type = type
local wipe = wipe
local _G = _G

-- Make sure we don't polute the global environment
setfenv(1, {})

-- RGB Colours
Data.colour = {
    white     = { 1,   1,   1   },
    grey      = { 0.7, 0.7, 0.7 },
    greyMid   = { 0.5, 0.5, 0.5 },
    green     = { 0,   1,   0   },
    greenMid  = { 0.1, 0.7, 0.1 },
    yellow    = { 1,   1,   0   },
    yellowMid = { 0.8, 0.7, 0.2 },
    red       = { 1,   0,   0   },
    redMid    = { 0.7, 0.1, 0.1 }
}

-- Escape sequence colours
Data.escapeColour = {
    reset     = "|r",
    white     = "|cFFFFFFFF",
    grey      = "|cFFBBBBBB",
    greyMid   = "|cFF888888",
    green     = "|cFF00FF00",
    greenMid  = "|cFF22AA22",
    yellow    = "|cFFFFFF00",
    yellowMid = "|cFFBB9933",
    red       = "|cFFFF0000",
    redMid    = "|cFFAA2222"
}

-- How much profit is significant, ie 1G
Data.ProfitThreshold = 10000
-- Minimum profit required
Data.ProfitPercentage = 10
-- AH cut percentage
Data.AHcut = 5
-- How many to queue
Data.ProfitStackNum = 1
-- If item is stackable then how many?
Data.ProfitStackSize = 5
-- If none on AH how much to mark up (multiplier)?
Data.ProfitMarkup = 2

-- Auction lengths
Data.AH12Hours = 1
Data.AH24Hours = 2
Data.AH48Hours = 3

-- We can use traders to calcuate the value of some items
Data.Traders = {
    -- Blood of Sargeras trader
    [124124] = {
	[124117] = 10, -- Lean Shank
	[124118] = 10, -- Fatty Bearsteak
	[124119] = 10, -- Big Gamy Ribs
	[124120] = 10, -- Leyblood
	[124121] = 10, -- Wildfowl Egg
	[124107] = 10, -- Cursed Queenfish
	[124108] = 10, -- Mossgill Perch
	[124109] = 10, -- Highmountain Salmon
	[124110] = 10, -- Stormray
	[124111] = 10, -- Runescale Koi
	[124112] = 10, -- Black Barracuda
	[124101] = 10, -- Aethril
	[124102] = 10, -- Dreamleaf
	[124103] = 10, -- Foxflower
	[124104] = 10, -- Fjarnskaggl
	[124105] = 3,  -- Starlight Rose
	[123918] = 10, -- Leystone Ore
	[123919] = 5,  -- Felslate
	[124113] = 10, -- Stonehide Leather
	[124115] = 10, -- Stormscale
	[124438] = 20, -- Unbroken Claw
	[124439] = 20, -- Unbroken Tooth
	[124437] = 10, -- Shal'dorei Silk
	[124440] = 10, -- Arkhana
	[124441] = 3   -- Leylight Shard
    },
    -- Primal Sargerite trader
    [151568] = {
	[151564] = 10, -- Empyrium
	[151565] = 10, -- Astral Glory
	[151566] = 10, -- Fiendish Leather
	[151567] = 10, -- Lightweave Cloth
	[151579] = 0.1,  -- Labradorite
	[151718] = 0.1,  -- Argulite
	[151719] = 0.1,  -- Lightsphene
	[151720] = 0.1,  -- Chemirine
	[151721] = 0.1,  -- Hesselian
	[151722] = 0.1   -- Florid Malachite
    }
}

-- Draenor reagents from the Garrison Resources vendor
local DraenorReagents = {
    [109118] = true,   -- Blackrock Ore
    [109119] = true,   -- True Iron Ore
    [109124] = true,   -- Frostweed
    [109125] = true,   -- Fireweed
    [109126] = true,   -- Gorgrond Flytrap
    [109127] = true,   -- Starflower
    [109128] = true,   -- Nagrand Arrowbloom
    [109129] = true,   -- Talador Orchid
    [109131] = true,   -- Raw Clefthoof Meat
    [109132] = true,   -- Raw Talbuk Meat
    [109133] = true,   -- Rylak Egg
    [109134] = true,   -- Raw Elekk Meat
    [109135] = true,   -- Raw Riverbeast Meat
    [109136] = true,   -- Raw Boar Meat
    [109137] = true,   -- Crescent Saberfish Flesh
    [109138] = true,   -- Jawless Skulker Flesh
    [109139] = true,   -- Fat Sleeper Flesh
    [109140] = true,   -- Blind Lake Sturgeon Flesh
    [109141] = true,   -- Fire Ammonite Tentacle
    [109142] = true,   -- Sea Scorpion Segment
    [109143] = true,   -- Abyssal Gulper Eel Flesh
    [109144] = true,   -- Blackwater Whiptail Flesh
    [109693] = true,   -- Draenic Dust
    [110609] = true,   -- Raw Beast Hide
    [111557] = true,   -- Sumptuous Fur
}

-- Reagents that are from a vendor and their prices
Data.vendorIDs = {
    [136654] = 20000,   -- Field Pack
    [136638] = 89500,   -- True Iron Barrel
    [136637] = 11500,   -- Oversized Blasting Cap
    [136636] = 57500,   -- Sniping Scope
    [136633] = 25000,   -- Loose Trigger
    [136632] = 210800,  -- Chaos Blaster
    [136631] = 450000,  -- Surface-to-Infernal Rocket Launcher
    [136630] = 118500,  -- "Twirling Bottom" Repeater
    [136629] = 173300,  -- Felgibber Shotgun
    [133593] = 25000,   -- Royal Olive
    [133592] = 25000,   -- Stonedark Snail
    [133591] = 25000,   -- River Onion
    [133590] = 25000,   -- Muskenbutter
    [133589] = 25000,   -- Dalapeño Pepper
    [133588] = 25000,   -- Flaked Sea Salt
    [127681] = 5000,    -- Sharp Spritethorn
    [127037] = 5000,    -- Runic Catgut
    [124436] = 40000,   -- Foxflower Flux
    [102540] = 5000,    -- Fresh Mangos
    [102539] = 5000,    -- Fresh Strawberries
    [90146] = 20000,    -- Tinker's Kit
    [85585] = 27000,    -- Red Beans
    [85584] = 17000,    -- Silkworm Pupa
    [85583] = 12000,    -- Needle Mushrooms
    [83092] = 200000000,-- Orb of Mystery
    [79740] = 23,	-- Plain Wooden Staff
    [74854] = 7000,	-- Instant Noodles
    [74852] = 16000,    -- Yak Milk
    [74851] = 14000,    -- Rice
    [74845] = 35000,    -- Ginseng
    [74832] = 12000,    -- Barley
    [74660] = 15000,    -- Pandaren Peach
    [74659] = 30000,    -- Farm Chicken
    [67335] = 445561,   -- Silver Charm Bracelet
    [67319] = 328990,   -- Preserved Ogre Eye
    [65893] = 30000000,	-- Sands of Time
    [65892] = 50000000,	-- Pyrium-Laced Crystalline Vial
    [62323] = 60000,    -- Deathwing Scale Fragment
    [58278] = 16000,    -- Tropical Sunfruit
    [58265] = 20000,    -- Highland Pomegranate
    [52188] = 15000,    -- Jeweler's Setting
    [46797] = 25,	-- Mulgore Sweet Potato
    [46796] = 25,	-- Ripe Tirisfal Pumpkin
    [46793] = 25,	-- Tangy Southfury Cranberries
    [46784] = 25,	-- Ripe Elwynn Pumpkin
    [44855] = 25,	-- Teldrassil Sweet Potato
    [44854] = 25,	-- Tangy Wetland Cranberries
    [44853] = 25,	-- Honey
    [44835] = 10,	-- Autumnal Herbs
    [44501] = 10000000,	-- Goblin-Machined Piston
    [44500] = 15000000,	-- Elementium-Plated Exhaust Pipe
    [44499] = 30000000,	-- Salvaged Iron Golem Parts
    [40533] = 50000,    -- Walnut Stock
    [39684] = 9000,	-- Hair Trigger
    [39354] = 15,	-- Light Parchment
    [38426] = 30000,    -- Eternium Thread
    [35949] = 8500,	-- Tundra Berries
    [35948] = 16000,    -- Savory Snowplum
    [34249] = 1000000,  -- Hula Girl Doll
    [30817] = 25,	-- Simple Flour
    [27860] = 6400,	-- Purified Draenic Water
    [18567] = 30000,    -- Elemental Flux
    [17202] = 10,	-- Snowball
    [17196] = 50,	-- Holiday Spirits
    [17194] = 10,	-- Holiday Spices
    [14341] = 5000,	-- Rune Thread
    [11291] = 4500,	-- Star Wood
    [10647] = 2000,	-- Engineer's Ink
    [10290] = 2500,	-- Pink Dye
    [9260] = 1600,	-- Volatile Rum
    [8343] = 2000,	-- Heavy Silken Thread
    [7005] = 82,	-- Skinning Knife
    [6530] = 100,	-- Nightcrawlers
    [6261] = 1000,	-- Orange Dye
    [6260] = 50,	-- Blue Dye
    [6217] = 124,	-- Copper Rod
    [5956] = 18,	-- Blacksmith Hammer
    [4537] = 125,	-- Tel'Abim Banana
    [4470] = 38,	-- Simple Wood
    [4400] = 2000,	-- Heavy Stock
    [4399] = 200,	-- Wooden Stock
    [4342] = 2500,	-- Purple Dye
    [4341] = 500,	-- Yellow Dye
    [4340] = 350,	-- Gray Dye
    [4291] = 500,	-- Silken Thread
    [4289] = 50,	-- Salt
    [3857] = 500,	-- Coal
    [3466] = 2000,	-- Strong Flux
    [3371] = 150,	-- Crystal Vial
    [2901] = 81,	-- Mining Pick
    [2880] = 100,	-- Weak Flux
    [2775] = 300,	-- Silver Ore
    [2678] = 10,	-- Mild Spices
    [2605] = 100,	-- Green Dye
    [2604] = 50,	-- Red Dye
    [2596] = 120,	-- Skin of Dwarven Stout
    [2595] = 2000,	-- Jug of Badlands Bourbon
    [2594] = 1500,	-- Flagon of Dwarven Mead
    [2593] = 150,	-- Flask of Stormwind Tawny
    [2325] = 1000,	-- Black Dye
    [2324] = 25,	-- Bleach
    [2321] = 100,	-- Fine Thread
    [2320] = 10,	-- Coarse Thread
    [1179] = 125,	-- Ice Cold Milk
    [159] = 25,		-- Refreshing Spring Water
}

-- Enchanting uses spells, convert to the scroll item
Data.enchantScrolls = {
    [235706] = 144307,  -- Enchant Neck - Mark of the Deadly
    [235702] = 144307,  -- Enchant Neck - Mark of the Deadly
    [235698] = 144307,	-- Enchant Neck - Mark of the Deadly
    [235705] = 144306,  -- Enchant Neck - Mark of the Quick
    [235701] = 144306,  -- Enchant Neck - Mark of the Quick
    [235697] = 144306,	-- Enchant Neck - Mark of the Quick
    [235704] = 144305,  -- Enchant Neck - Mark of the Versatile
    [235700] = 144305,  -- Enchant Neck - Mark of the Versatile
    [235696] = 144305,	-- Enchant Neck - Mark of the Versatile
    [235703] = 144304,  -- Enchant Neck - Mark of the Master
    [235699] = 144304,  -- Enchant Neck - Mark of the Master
    [235695] = 144304,	-- Enchant Neck - Mark of the Master
    [228410] = 141910,  -- Enchant Neck - Mark of the Ancient Priestess
    [228409] = 141910,  -- Enchant Neck - Mark of the Ancient Priestess
    [228408] = 141910,	-- Enchant Neck - Mark of the Ancient Priestess
    [228407] = 141909,  -- Enchant Neck - Mark of the Trained Soldier
    [228406] = 141909,  -- Enchant Neck - Mark of the Trained Soldier
    [228405] = 141909,	-- Enchant Neck - Mark of the Trained Soldier
    [228404] = 141908,  -- Enchant Neck - Mark of the Heavy Hide
    [228403] = 141908,  -- Enchant Neck - Mark of the Heavy Hide
    [228402] = 141908,	-- Enchant Neck - Mark of the Heavy Hide
    [190991] = 128561,	-- Enchant Gloves - Legion Surveying
    [190990] = 128560,	-- Enchant Gloves - Legion Skinning
    [190989] = 128559,	-- Enchant Gloves - Legion Mining
    [190988] = 128558,	-- Enchant Gloves - Legion Herbalism
    [190954] = 128554,	-- Enchant Shoulder - Boon of the Scavenger
    [191025] = 128553,  -- Enchant Neck - Mark of the Hidden Satyr
    [191008] = 128553,  -- Enchant Neck - Mark of the Hidden Satyr
    [190894] = 128553,	-- Enchant Neck - Mark of the Hidden Satyr
    [191024] = 128552,  -- Enchant Neck - Mark of the Distant Army
    [191007] = 128552,  -- Enchant Neck - Mark of the Distant Army
    [190893] = 128552,	-- Enchant Neck - Mark of the Distant Army
    [191023] = 128551,  -- Enchant Neck - Mark of the Claw
    [191006] = 128551,  -- Enchant Neck - Mark of the Claw
    [190892] = 128551,	-- Enchant Neck - Mark of the Claw
    [191022] = 128550,  -- Enchant Cloak - Binding of Intellect
    [191005] = 128550,  -- Enchant Cloak - Binding of Intellect
    [190879] = 128550,	-- Enchant Cloak - Binding of Intellect
    [191021] = 128549,  -- Enchant Cloak - Binding of Agility
    [191004] = 128549,  -- Enchant Cloak - Binding of Agility
    [190878] = 128549,	-- Enchant Cloak - Binding of Agility
    [191020] = 128548,  -- Enchant Cloak - Binding of Strength
    [191003] = 128548,  -- Enchant Cloak - Binding of Strength
    [190877] = 128548,	-- Enchant Cloak - Binding of Strength
    [191019] = 128547,  -- Enchant Cloak - Word of Intellect
    [191002] = 128547,  -- Enchant Cloak - Word of Intellect
    [190876] = 128547,	-- Enchant Cloak - Word of Intellect
    [191018] = 128546,  -- Enchant Cloak - Word of Agility
    [191001] = 128546,  -- Enchant Cloak - Word of Agility
    [190875] = 128546,	-- Enchant Cloak - Word of Agility
    [191017] = 128545,  -- Enchant Cloak - Word of Strength
    [191000] = 128545,  -- Enchant Cloak - Word of Strength
    [190874] = 128545,	-- Enchant Cloak - Word of Strength
    [191016] = 128544,  -- Enchant Ring - Binding of Versatility
    [190999] = 128544,  -- Enchant Ring - Binding of Versatility
    [190873] = 128544,	-- Enchant Ring - Binding of Versatility
    [191015] = 128543,  -- Enchant Ring - Binding of Mastery
    [190998] = 128543,  -- Enchant Ring - Binding of Mastery
    [190872] = 128543,	-- Enchant Ring - Binding of Mastery
    [191014] = 128542,  -- Enchant Ring - Binding of Haste
    [190997] = 128542,  -- Enchant Ring - Binding of Haste
    [190871] = 128542,	-- Enchant Ring - Binding of Haste
    [191013] = 128541,  -- Enchant Ring - Binding of Critical Strike
    [190996] = 128541,  -- Enchant Ring - Binding of Critical Strike
    [190870] = 128541,	-- Enchant Ring - Binding of Critical Strike
    [191012] = 128540,  -- Enchant Ring - Word of Versatility
    [190995] = 128540,  -- Enchant Ring - Word of Versatility
    [190869] = 128540,	-- Enchant Ring - Word of Versatility
    [191011] = 128539,  -- Enchant Ring - Word of Mastery
    [190994] = 128539,  -- Enchant Ring - Word of Mastery
    [190868] = 128539,	-- Enchant Ring - Word of Mastery
    [191010] = 128538,  -- Enchant Ring - Word of Haste
    [190993] = 128538,  -- Enchant Ring - Word of Haste
    [190867] = 128538,	-- Enchant Ring - Word of Haste
    [191009] = 128537,  -- Enchant Ring - Word of Critical Strike
    [190992] = 128537,  -- Enchant Ring - Word of Critical Strike
    [190866] = 128537,	-- Enchant Ring - Word of Critical Strike
    [173323] = 118015,	-- Enchant Weapon - Mark of Bleeding Hollow
    [159672] = 112165,	-- Enchant Weapon - Mark of the Frostwolf
    [159671] = 112164,	-- Enchant Weapon - Mark of Warsong
    [159674] = 112160,	-- Enchant Weapon - Mark of Blackrock
    [159673] = 112115,	-- Enchant Weapon - Mark of Shadowmoon
    [159236] = 112093,	-- Enchant Weapon - Mark of the Shattered Hand
    [159235] = 110682,	-- Enchant Weapon - Mark of the Thunderlord
    [158889] = 110656,	-- Enchant Cloak - Gift of Versatility
    [158886] = 110654,	-- Enchant Cloak - Gift of Mastery
    [158885] = 110653,	-- Enchant Cloak - Gift of Haste
    [158884] = 110652,	-- Enchant Cloak - Gift of Critical Strike
    [158903] = 110649,	-- Enchant Neck - Gift of Versatility
    [158901] = 110647,	-- Enchant Neck - Gift of Mastery
    [158900] = 110646,	-- Enchant Neck - Gift of Haste
    [158899] = 110645,	-- Enchant Neck - Gift of Critical Strike
    [158918] = 110642,	-- Enchant Ring - Gift of Versatility
    [158916] = 110640,	-- Enchant Ring - Gift of Mastery
    [158915] = 110639,	-- Enchant Ring - Gift of Haste
    [158914] = 110638,	-- Enchant Ring - Gift of Critical Strike
    [158881] = 110635,	-- Enchant Cloak - Breath of Versatility
    [158879] = 110633,	-- Enchant Cloak - Breath of Mastery
    [158878] = 110632,	-- Enchant Cloak - Breath of Haste
    [158877] = 110631,	-- Enchant Cloak - Breath of Critical Strike
    [158896] = 110628,	-- Enchant Neck - Breath of Versatility
    [158894] = 110626,	-- Enchant Neck - Breath of Mastery
    [158893] = 110625,	-- Enchant Neck - Breath of Haste
    [158892] = 110624,	-- Enchant Neck - Breath of Critical Strike
    [158911] = 110621,	-- Enchant Ring - Breath of Versatility
    [158909] = 110619,	-- Enchant Ring - Breath of Mastery
    [158908] = 110618,	-- Enchant Ring - Breath of Haste
    [158907] = 110617,	-- Enchant Ring - Breath of Critical Strike
    [130758] = 89737,	-- Enchant Shield - Greater Parry
    [104445] = 74729,	-- Enchant Off-Hand - Major Intellect
    [104442] = 74728,	-- Enchant Weapon - River's Song
    [104440] = 74727,	-- Enchant Weapon - Colossus
    [104434] = 74726,	-- Enchant Weapon - Dancing Steel
    [104430] = 74725,	-- Enchant Weapon - Elemental Force
    [104427] = 74724,	-- Enchant Weapon - Jade Spirit
    [104425] = 74723,	-- Enchant Weapon - Windsong
    [104420] = 74722,	-- Enchant Gloves - Superior Mastery
    [104419] = 74721,	-- Enchant Gloves - Super Strength
    [104417] = 74720,	-- Enchant Gloves - Superior Haste
    [104416] = 74719,	-- Enchant Gloves - Greater Haste
    [104414] = 74718,	-- Enchant Boots - Pandaren's Step
    [104409] = 74717,	-- Enchant Boots - Blurred Speed
    [104408] = 74716,	-- Enchant Boots - Greater Precision
    [104407] = 74715,	-- Enchant Boots - Greater Haste
    [104404] = 74713,	-- Enchant Cloak - Superior Critical Strike
    [104403] = 74712,	-- Enchant Cloak - Superior Intellect
    [104401] = 74711,	-- Enchant Cloak - Greater Protection
    [104398] = 74710,	-- Enchant Cloak - Accuracy
    [104397] = 74709,	-- Enchant Chest - Superior Stamina
    [104395] = 74708,	-- Enchant Chest - Glorious Stats
    [104393] = 74707,	-- Enchant Chest - Mighty Versatility
    [104392] = 74706,	-- Enchant Chest - Super Resilience
    [104391] = 74705,	-- Enchant Bracer - Greater Agility
    [104390] = 74704,	-- Enchant Bracer - Exceptional Strength
    [104389] = 74703,	-- Enchant Bracer - Super Intellect
    [104385] = 74701,	-- Enchant Bracer - Major Dodge
    [104338] = 74700,	-- Enchant Bracer - Mastery
    [96262] = 68786,	-- Enchant Bracer - Mighty Intellect
    [96261] = 68785,	-- Enchant Bracer - Major Strength
    [96264] = 68784,	-- Enchant Bracer - Agility
    [95471] = 68134,	-- Enchant 2H Weapon - Mighty Agility
    [74256] = 52785,	-- Enchant Bracer - Greater Speed
    [74255] = 52784,	-- Enchant Gloves - Greater Mastery
    [74254] = 52783,	-- Enchant Gloves - Mighty Strength
    [74253] = 52782,	-- Enchant Boots - Lavawalker
    [74252] = 52781,	-- Enchant Boots - Assassin's Step
    [74251] = 52780,	-- Enchant Chest - Greater Stamina
    [74250] = 52779,	-- Enchant Chest - Peerless Stats
    [74248] = 52778,	-- Enchant Bracer - Greater Critical Strike
    [74247] = 52777,	-- Enchant Cloak - Greater Critical Strike
    [74246] = 52776,	-- Enchant Weapon - Landslide
    [74244] = 52775,	-- Enchant Weapon - Windwalk
    [74242] = 52774,	-- Enchant Weapon - Power Torrent
    [74240] = 52773,	-- Enchant Cloak - Greater Intellect
    [74239] = 52772,	-- Enchant Bracer - Greater Haste
    [74238] = 52771,	-- Enchant Boots - Mastery
    [74237] = 52770,	-- Enchant Bracer - Exceptional Versatility
    [74236] = 52769,	-- Enchant Boots - Precision
    [74235] = 52768,	-- Enchant Off-Hand - Superior Intellect
    [74234] = 52767,	-- Enchant Cloak - Protection
    [74232] = 52766,	-- Enchant Bracer - Precision
    [74231] = 52765,	-- Enchant Chest - Exceptional Versatility
    [74230] = 52764,	-- Enchant Cloak - Critical Strike
    [74229] = 52763,	-- Enchant Bracer - Superior Dodge
    [74226] = 52762,	-- Enchant Shield - Mastery
    [74225] = 52761,	-- Enchant Weapon - Heartsong
    [74223] = 52760,	-- Enchant Weapon - Hurricane
    [74220] = 52759,	-- Enchant Gloves - Greater Haste
    [74214] = 52758,	-- Enchant Chest - Mighty Resilience
    [74213] = 52757,	-- Enchant Boots - Major Agility
    [74212] = 52756,	-- Enchant Gloves - Exceptional Strength
    [74211] = 52755,	-- Enchant Weapon - Elemental Slayer
    [74207] = 52754,	-- Enchant Shield - Protection
    [74202] = 52753,	-- Enchant Cloak - Intellect
    [74201] = 52752,	-- Enchant Bracer - Critical Strike
    [74200] = 52751,	-- Enchant Chest - Stamina
    [74199] = 52750,	-- Enchant Boots - Haste
    [74198] = 52749,	-- Enchant Gloves - Haste
    [74197] = 52748,	-- Enchant Weapon - Avalanche
    [74195] = 52747,	-- Enchant Weapon - Mending
    [74193] = 52746,	-- Enchant Bracer - Speed
    [74192] = 52745,	-- Enchant Cloak - Lesser Power
    [74191] = 52744,	-- Enchant Chest - Mighty Stats
    [74189] = 52743,	-- Enchant Boots - Earthen Vitality
    [74132] = 52687,	-- Enchant Gloves - Mastery
    [71692] = 50816,	-- Enchant Gloves - Angler
    [64579] = 46098,	-- Enchant Weapon - Blood Draining
    [64441] = 46026,	-- Enchant Weapon - Blade Ward
    [63746] = 45628,	-- Enchant Boots - Lesser Accuracy
    [62959] = 45060,	-- Enchant Staff - Spellpower
    [62948] = 45056,	-- Enchant Staff - Greater Spellpower
    [62256] = 44947,	-- Enchant Bracer - Major Stamina
    [44575] = 44815,	-- Enchant Bracer - Greater Assault
    [59619] = 44497,	-- Enchant Weapon - Accuracy
    [59621] = 44493,	-- Enchant Weapon - Berserking
    [60767] = 44470,	-- Enchant Bracer - Superior Spellpower
    [60763] = 44469,	-- Enchant Boots - Greater Assault
    [60714] = 44467,	-- Enchant Weapon - Mighty Spellpower
    [60707] = 44466,	-- Enchant Weapon - Superior Potency
    [60692] = 44465,	-- Enchant Chest - Powerful Stats
    [60691] = 44463,	-- Enchant 2H Weapon - Massacre
    [60668] = 44458,	-- Enchant Gloves - Crusher
    [60663] = 44457,	-- Enchant Cloak - Major Agility
    [60609] = 44456,	-- Enchant Cloak - Speed
    [60653] = 44455,	-- Enchant Shield - Greater Intellect
    [60621] = 44453,	-- Enchant Weapon - Greater Potency
    [60606] = 44449,	-- Enchant Boots - Assault
    [59625] = 43987,	-- Enchant Weapon - Black Magic
    [47901] = 39006,	-- Enchant Boots - Tuskarr's Vitality
    [47900] = 39005,	-- Enchant Chest - Super Health
    [47899] = 39004,	-- Enchant Cloak - Wisdom
    [47898] = 39003,	-- Enchant Cloak - Greater Speed
    [47766] = 39002,	-- Enchant Chest - Greater Dodge
    [47672] = 39001,	-- Enchant Cloak - Mighty Stamina
    [47051] = 39000,	-- Enchant Cloak - Greater Dodge
    [46594] = 38999,	-- Enchant Chest - Dodge
    [46578] = 38998,	-- Enchant Weapon - Deathfrost
    [44635] = 38997,	-- Enchant Bracer - Greater Spellpower
    [44633] = 38995,	-- Enchant Weapon - Exceptional Agility
    [44631] = 38993,	-- Enchant Cloak - Shadow Armor
    [44630] = 38992,	-- Enchant 2H Weapon - Greater Savagery
    [44629] = 38991,	-- Enchant Weapon - Exceptional Spellpower
    [44625] = 38990,	-- Enchant Gloves - Armsman
    [44623] = 38989,	-- Enchant Chest - Super Stats
    [44621] = 38988,	-- Enchant Weapon - Giant Slayer
    [44616] = 38987,	-- Enchant Bracer - Greater Stats
    [60623] = 38986,	-- Enchant Boots - Icewalker
    [44598] = 38984,	-- Enchant Bracer - Haste
    [44595] = 38981,	-- Enchant 2H Weapon - Scourgebane
    [44593] = 38980,	-- Enchant Bracer - Major Versatility
    [44592] = 38979,	-- Enchant Gloves - Exceptional Spellpower
    [44591] = 38978,	-- Enchant Cloak - Superior Dodge
    [44589] = 38976,	-- Enchant Boots - Superior Agility
    [44588] = 38975,	-- Enchant Chest - Exceptional Resilience
    [44584] = 38974,	-- Enchant Boots - Greater Vitality
    [44582] = 38973,	-- Enchant Cloak - Minor Power
    [44576] = 38972,	-- Enchant Weapon - Lifeward
    [60616] = 38971,	-- Enchant Bracer - Assault
    [44555] = 38968,	-- Enchant Bracer - Exceptional Intellect
    [44529] = 38967,	-- Enchant Gloves - Major Agility
    [44528] = 38966,	-- Enchant Boots - Greater Fortitude
    [44524] = 38965,	-- Enchant Weapon - Icebreaker
    [44513] = 38964,	-- Enchant Gloves - Greater Assault
    [44510] = 38963,	-- Enchant Weapon - Exceptional Versatility
    [44509] = 38962,	-- Enchant Chest - Greater Versatility
    [44508] = 38961,	-- Enchant Boots - Greater Versatility
    [44506] = 38960,	-- Enchant Gloves - Gatherer
    [44500] = 38959,	-- Enchant Cloak - Superior Agility
    [44492] = 38955,	-- Enchant Chest - Mighty Health
    [44489] = 38954,	-- Enchant Shield - Dodge
    [44488] = 38953,	-- Enchant Gloves - Precision
    [44484] = 38951,	-- Enchant Gloves - Haste
    [44383] = 38949,	-- Enchant Shield - Resilience
    [42974] = 38948,	-- Enchant Weapon - Executioner
    [42620] = 38947,	-- Enchant Weapon - Greater Agility
    [34010] = 38946,	-- Enchant Weapon - Major Healing
    [34009] = 38945,	-- Enchant Shield - Major Stamina
    [34008] = 38944,	-- Enchant Boots - Boar's Speed
    [34007] = 38943,	-- Enchant Boots - Cat's Swiftness
    [34004] = 38940,	-- Enchant Cloak - Greater Agility
    [34003] = 38939,	-- Enchant Cloak - PvP Power
    [34002] = 38938,	-- Enchant Bracer - Lesser Assault
    [34001] = 38937,	-- Enchant Bracer - Major Intellect
    [33999] = 38936,	-- Enchant Gloves - Major Healing
    [33997] = 38935,	-- Enchant Gloves - Major Spellpower
    [33996] = 38934,	-- Enchant Gloves - Assault
    [33995] = 38933,	-- Enchant Gloves - Major Strength
    [33994] = 38932,	-- Enchant Gloves - Precise Strikes
    [33993] = 38931,	-- Enchant Gloves - Blasting
    [33992] = 38930,	-- Enchant Chest - Major Resilience
    [33991] = 38929,	-- Enchant Chest - Versatility Prime
    [33990] = 38928,	-- Enchant Chest - Major Versatility
    [28004] = 38927,	-- Enchant Weapon - Battlemaster
    [28003] = 38926,	-- Enchant Weapon - Spellsurge
    [27984] = 38925,	-- Enchant Weapon - Mongoose
    [27982] = 38924,	-- Enchant Weapon - Soulfrost
    [27981] = 38923,	-- Enchant Weapon - Sunfire
    [27977] = 38922,	-- Enchant 2H Weapon - Major Agility
    [27975] = 38921,	-- Enchant Weapon - Major Spellpower
    [27972] = 38920,	-- Enchant Weapon - Potency
    [27971] = 38919,	-- Enchant 2H Weapon - Savagery
    [27968] = 38918,	-- Enchant Weapon - Major Intellect
    [27967] = 38917,	-- Enchant Weapon - Major Striking
    [27961] = 38914,	-- Enchant Cloak - Major Armor
    [27960] = 38913,	-- Enchant Chest - Exceptional Stats
    [27958] = 38912,	-- Enchant Chest - Exceptional Mana
    [27957] = 38911,	-- Enchant Chest - Exceptional Health
    [27954] = 38910,	-- Enchant Boots - Surefooted
    [27950] = 38909,	-- Enchant Boots - Fortitude
    [27948] = 38908,	-- Enchant Boots - Vitality
    [27946] = 38906,	-- Enchant Shield - Parry
    [27945] = 38905,	-- Enchant Shield - Intellect
    [27944] = 38904,	-- Enchant Shield - Lesser Dodge
    [27917] = 38903,	-- Enchant Bracer - Spellpower
    [27914] = 38902,	-- Enchant Bracer - Fortitude
    [27913] = 38901,	-- Enchant Bracer - Versatility Prime
    [27911] = 38900,	-- Enchant Bracer - Superior Healing
    [27906] = 38899,	-- Enchant Bracer - Greater Dodge
    [27905] = 38898,	-- Enchant Bracer - Stats
    [27899] = 38897,	-- Enchant Bracer - Brawn
    [27837] = 38896,	-- Enchant 2H Weapon - Agility
    [25086] = 38895,	-- Enchant Cloak - Dodge
    [25084] = 38894,	-- Enchant Cloak - Subtlety
    [25083] = 38893,	-- Enchant Cloak - Stealth
    [25080] = 38890,	-- Enchant Gloves - Superior Agility
    [25079] = 38889,	-- Enchant Gloves - Healing Power
    [25078] = 38888,	-- Enchant Gloves - Fire Power
    [25074] = 38887,	-- Enchant Gloves - Frost Power
    [25073] = 38886,	-- Enchant Gloves - Shadow Power
    [25072] = 38885,	-- Enchant Gloves - Threat
    [23804] = 38884,	-- Enchant Weapon - Mighty Intellect
    [23803] = 38883,	-- Enchant Weapon - Mighty Versatility
    [23802] = 38882,	-- Enchant Bracer - Healing Power
    [23801] = 38881,	-- Enchant Bracer - Argent Versatility
    [23800] = 38880,	-- Enchant Weapon - Agility
    [23799] = 38879,	-- Enchant Weapon - Strength
    [22750] = 38878,	-- Enchant Weapon - Healing Power
    [22749] = 38877,	-- Enchant Weapon - Spellpower
    [21931] = 38876,	-- Enchant Weapon - Winter's Might
    [20036] = 38875,	-- Enchant 2H Weapon - Major Intellect
    [20035] = 38874,	-- Enchant 2H Weapon - Major Versatility
    [20034] = 38873,	-- Enchant Weapon - Crusader
    [20033] = 38872,	-- Enchant Weapon - Unholy Weapon
    [20032] = 38871,	-- Enchant Weapon - Lifestealing
    [20031] = 38870,	-- Enchant Weapon - Superior Striking
    [20030] = 38869,	-- Enchant 2H Weapon - Superior Impact
    [20029] = 38868,	-- Enchant Weapon - Icy Chill
    [20028] = 38867,	-- Enchant Chest - Major Mana
    [20026] = 38866,	-- Enchant Chest - Major Health
    [20025] = 38865,	-- Enchant Chest - Greater Stats
    [20024] = 38864,	-- Enchant Boots - Versatility
    [20023] = 38863,	-- Enchant Boots - Greater Agility
    [20020] = 38862,	-- Enchant Boots - Greater Stamina
    [20017] = 38861,	-- Enchant Shield - Greater Stamina
    [20016] = 38860,	-- Enchant Shield - Vitality
    [20015] = 38859,	-- Enchant Cloak - Superior Defense
    [20013] = 38857,	-- Enchant Gloves - Greater Strength
    [20012] = 38856,	-- Enchant Gloves - Greater Agility
    [20011] = 38855,	-- Enchant Bracer - Superior Stamina
    [20010] = 38854,	-- Enchant Bracer - Superior Strength
    [20009] = 38853,	-- Enchant Bracer - Superior Versatility
    [20008] = 38852,	-- Enchant Bracer - Greater Intellect
    [13948] = 38851,	-- Enchant Gloves - Minor Haste
    [13947] = 38850,	-- Enchant Gloves - Riding Skill
    [13945] = 38849,	-- Enchant Bracer - Greater Stamina
    [13943] = 38848,	-- Enchant Weapon - Greater Striking
    [13941] = 38847,	-- Enchant Chest - Stats
    [13939] = 38846,	-- Enchant Bracer - Greater Strength
    [13937] = 38845,	-- Enchant 2H Weapon - Greater Impact
    [13935] = 38844,	-- Enchant Boots - Agility
    [13931] = 38842,	-- Enchant Bracer - Dodge
    [13917] = 38841,	-- Enchant Chest - Superior Mana
    [13915] = 38840,	-- Enchant Weapon - Demonslaying
    [13905] = 38839,	-- Enchant Shield - Greater Versatility
    [13898] = 38838,	-- Enchant Weapon - Fiery Weapon
    [13890] = 38837,	-- Enchant Boots - Minor Speed
    [13887] = 38836,	-- Enchant Gloves - Strength
    [13882] = 38835,	-- Enchant Cloak - Lesser Agility
    [13868] = 38834,	-- Enchant Gloves - Advanced Herbalism
    [13858] = 38833,	-- Enchant Chest - Superior Health
    [13846] = 38832,	-- Enchant Bracer - Greater Versatility
    [13841] = 38831,	-- Enchant Gloves - Advanced Mining
    [13836] = 38830,	-- Enchant Boots - Stamina
    [13822] = 38829,	-- Enchant Bracer - Intellect
    [13817] = 38828,	-- Enchant Shield - Stamina
    [13815] = 38827,	-- Enchant Gloves - Agility
    [13746] = 38825,	-- Enchant Cloak - Greater Defense
    [13700] = 38824,	-- Enchant Chest - Lesser Stats
    [13698] = 38823,	-- Enchant Gloves - Skinning
    [13695] = 38822,	-- Enchant 2H Weapon - Impact
    [13693] = 38821,	-- Enchant Weapon - Striking
    [13689] = 38820,	-- Enchant Shield - Lesser Parry
    [13687] = 38819,	-- Enchant Boots - Lesser Versatility
    [13663] = 38818,	-- Enchant Chest - Greater Mana
    [13661] = 38817,	-- Enchant Bracer - Strength
    [13659] = 38816,	-- Enchant Shield - Versatility
    [13655] = 38814,	-- Enchant Weapon - Lesser Elemental Slayer
    [13653] = 38813,	-- Enchant Weapon - Lesser Beastslayer
    [13648] = 38812,	-- Enchant Bracer - Stamina
    [13646] = 38811,	-- Enchant Bracer - Lesser Dodge
    [13644] = 38810,	-- Enchant Boots - Lesser Stamina
    [13642] = 38809,	-- Enchant Bracer - Versatility
    [13640] = 38808,	-- Enchant Chest - Greater Health
    [13637] = 38807,	-- Enchant Boots - Lesser Agility
    [13635] = 38806,	-- Enchant Cloak - Defense
    [13631] = 38805,	-- Enchant Shield - Lesser Stamina
    [13626] = 38804,	-- Enchant Chest - Minor Stats
    [13622] = 38803,	-- Enchant Bracer - Lesser Intellect
    [13620] = 38802,	-- Enchant Gloves - Fishing
    [13617] = 38801,	-- Enchant Gloves - Herbalism
    [13612] = 38800,	-- Enchant Gloves - Mining
    [13607] = 38799,	-- Enchant Chest - Mana
    [13538] = 38798,	-- Enchant Chest - Lesser Absorption
    [13536] = 38797,	-- Enchant Bracer - Lesser Strength
    [13529] = 38796,	-- Enchant 2H Weapon - Lesser Impact
    [13503] = 38794,	-- Enchant Weapon - Lesser Striking
    [13501] = 38793,	-- Enchant Bracer - Lesser Stamina
    [13485] = 38792,	-- Enchant Shield - Lesser Versatility
    [13464] = 38791,	-- Enchant Shield - Lesser Protection
    [13421] = 38790,	-- Enchant Cloak - Lesser Protection
    [13419] = 38789,	-- Enchant Cloak - Minor Agility
    [13380] = 38788,	-- Enchant 2H Weapon - Lesser Versatility
    [13378] = 38787,	-- Enchant Shield - Minor Stamina
    [7867] = 38786,	-- Enchant Boots - Minor Agility
    [7863] = 38785,	-- Enchant Boots - Minor Stamina
    [7859] = 38783,	-- Enchant Bracer - Lesser Versatility
    [7857] = 38782,	-- Enchant Chest - Health
    [7793] = 38781,	-- Enchant 2H Weapon - Lesser Intellect
    [7788] = 38780,	-- Enchant Weapon - Minor Striking
    [7786] = 38779,	-- Enchant Weapon - Minor Beastslayer
    [7782] = 38778,	-- Enchant Bracer - Minor Strength
    [7779] = 38777,	-- Enchant Bracer - Minor Agility
    [7776] = 38776,	-- Enchant Chest - Lesser Mana
    [7771] = 38775,	-- Enchant Cloak - Minor Protection
    [7766] = 38774,	-- Enchant Bracer - Minor Versatility
    [7748] = 38773,	-- Enchant Chest - Lesser Health
    [7745] = 38772,	-- Enchant 2H Weapon - Minor Impact
    [7457] = 38771,	-- Enchant Bracer - Minor Stamina
    [7443] = 38769,	-- Enchant Chest - Minor Mana
    [7428] = 38768,	-- Enchant Bracer - Minor Dodge
    [7426] = 38767,	-- Enchant Chest - Minor Absorption
    [7420] = 38766,	-- Enchant Chest - Minor Health
    [7418] = 38679,	-- Enchant Bracer - Minor Health
    [27951] = 37603	-- Enchant Boots - Dexterity
}

local CHAOS_CRYSTAL  = 124442
local LEYLIGHT_SHARD = 124441
local ARKHANA        = 124440

-- [quality][ilvl] = { { itemID, probability, quantity, }, { itemID, ...
Data.disenchant = {
    [LE_ITEM_QUALITY_EPIC] = {
	[835] = { { CHAOS_CRYSTAL, 1,   1 }, { Data.BoSItemID, 0.04, 1 } },
	[745] = { { CHAOS_CRYSTAL, 0.1, 1 }, { LEYLIGHT_SHARD, 0.90, 1 }, 
	    { Data.BoSItemID, 0.04, 1 } }
    },
    [LE_ITEM_QUALITY_RARE] = {
	[660] = { { LEYLIGHT_SHARD, 1, 1 }, { Data.BoSItemID, 0.04, 1 } }
    },
    [LE_ITEM_QUALITY_UNCOMMON] = {
	[660] = { { ARKHANA, 1, 3 } }
    }
}

-- Uses a trivial hash of the rgb values: math.floor((r + g + b) * 1000)
Data.rgbToRarity = {
    [1780] = LE_ITEM_QUALITY_EPIC,
    [1305] = LE_ITEM_QUALITY_RARE,
    [1117] = LE_ITEM_QUALITY_UNCOMMON
}

function Data:OnLoad()
    -- Make sure we at least know about all the trader items
    for traderItemID in pairs(self.Traders) do
	for itemID in pairs(self.Traders[traderItemID]) do
	    if _G.Crafty_Items[itemID] == nil then
		_G.Crafty_Items[itemID] = { minBuyout = -1 }
	    end
	end
    end

    -- Add in Draenor mats bought with Garrison Resources, if we don't know them
    local items = _G.Crafty_Items
    for itemID in pairs(DraenorReagents) do
	if not items[itemID] then
	    items[itemID] = { minBuyout = -1 }
	end
    end
end

-- Returns the item's ID and item's name, given a wow item link
function Data:GetItemInfoFromLink(itemLink)
    if itemLink then
	local itemID, itemName = string.match(itemLink, "item:(%d+):.-%[(.*)%]")
	if itemID then
	    return tonumber(itemID), itemName
	else
	    -- Try again without matching name
	    itemID = string.match(itemLink, "item:(%d+):")
	    return tonumber(itemID)
	end
    else
	return nil
    end
end

-- Cacluate the value of an item used at a trader
function Data:TraderValue(traderItemID)
    if self.Traders[traderItemID] == nil then
	return nil
    end

    local max
    for itemID, num in pairs(self.Traders[traderItemID]) do
	local item = _G.Crafty_Items[itemID]
	if item and item.minBuyout and item.minBuyout > 0 then
	    local cost = item.minBuyout * num
	    if cost and (not max or cost > max) then
		max = cost
	    end
	end
    end
    return max
end

Data.seen = {}	-- Detect crafting cost infinite loops

function Data:CraftingCost(itemID)
    wipe(Data.seen)
    return self:CraftingCost_(itemID)
end

-- Calculates crafting cost of an item, factors in intermediate crafts
function Data:CraftingCost_(itemID)
    -- If we've seen the item before we're in an infinite loop
    -- Happens for some Enchanting transformations and Alchemy Transmutes
    -- Thanks Tecosu for finding the bug!
    if self.seen[itemID] then
	return nil
    else
	self.seen[itemID] = true
    end

    local item = _G.Crafty_Items[itemID]
    if item and item.reagents then
        local cost = 0
        for reagentID, num in pairs(item.reagents) do
	    local vendorCost = Data.vendorIDs[reagentID]
	    if vendorCost then
		cost = cost + vendorCost * num
	    else
		local reagent = _G.Crafty_Items[reagentID]
		if reagent then
		    local minBuyout = reagent.minBuyout
		    local reagentCost
		    if self.Traders[reagentID] then
			minBuyout = self:TraderValue(reagentID)
		    else
			-- Intermediate craft
			if reagent.reagents then
			    reagentCost = self:CraftingCost_(reagentID)
			end
		    end
		    if minBuyout and minBuyout > 0 then
			if reagentCost and reagentCost < minBuyout then
			    cost = cost + reagentCost * num
			else
			    cost = cost + minBuyout * num
			end
		    else
			if reagentCost then
			    cost = cost + reagentCost * num
			else
			    return nil
			end
		    end
		end
	    end
        end
        return math.ceil(cost / item.numProduced)
    else
        return nil
    end
end

function Data:DisenchantValue(itemID, quality, ilvl)
    local val = 0
    local table = self.disenchant[quality]
    if table then
	for minilvl in pairs(table) do
	    if ilvl >= minilvl then
		for i = 1, #table[minilvl] do
		    local resultID = table[minilvl][i][1]
		    local prob     = table[minilvl][i][2]
		    local num      = table[minilvl][i][3]
		    if self.Traders[resultID] then
			local cost = self:TraderValue(resultID)
			if cost then
			    val = val + cost * prob * num
			end
		    else
			local item = _G.Crafty_Items[resultID]
			if item then
			    local minBuyout = item.minBuyout
			    if minBuyout and minBuyout > 0 then
				val = val + minBuyout * prob * num
			    end
			end
		    end
		end
		break
	    end
	end
    end
    return math.floor(val)
end

-- Work out if crafting an item is profitable
function Data:GetProfit(itemID, isAH)
    local cost = self:CraftingCost(itemID)
    local item = _G.Crafty_Items[itemID]
    if item and item.minBuyout and cost then
	local price
	-- If none on AH then use a markup
	if item.minBuyout == -1 then
	    price = cost * Data.ProfitMarkup
	else
	    price = item.minBuyout - 1
	end
	local profit = price - cost
	-- Take off the AH cut
	if isAH then
	    profit = profit - price * Data.AHcut / 100
	end

	-- Is the profit significant?
	local isProfitable = profit > Data.ProfitThreshold and 
	    profit > cost * Data.ProfitPercentage / 100

	return math.floor(profit), isProfitable
    else
	return nil, nil
    end
end

-- My version of GetCoinTextureString, always displays silver and copper, makes
-- aligning lists of prices easier
function Data:GetCoinTextureString(money)
    local gold = math.floor(money / 10000)
    local silver = math.floor(money / 100) % 100
    local copper = money % 100
    local goldTexture = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
    local silverTexture = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
    local copperTexture = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"

    if gold > 0 then
	silver = silver > 9 and silver or "0"..silver
	copper = copper > 9 and copper or "0"..copper
	return gold..goldTexture.." "..silver..silverTexture..
	    " "..copper..copperTexture
    elseif silver > 0 then
	copper = copper > 9 and copper or "0"..copper
	return silver..silverTexture.." "..copper..copperTexture
    else
	return copper..copperTexture
    end
end

-- Usually the spell name of a craft is the same as the item name, but not 
-- always!
function Data:GetSpellName(itemID)
    local itemName = GetItemInfo(itemID)
    if itemName then
	if itemName == "Arkhana" then
	    itemName = "Ley Shatter"
	else
	    itemName = string.gsub(itemName, "&", "and")
	    itemName = string.gsub(itemName, "Enchant.-- ", "")
	end
    end
    --self:Debug("Data:GetSpellName:", itemName)
    return itemName
end

-- Test to see if an item is Bind on Pickup
function Data:IsBoP(itemLink)
    -- Use scanning tooltip to see if it's BoP
    ScanTip:Set(itemLink)
    local text = { ScanTip:GetText() }
    return text[2] and string.find(text[2], "Binds when picked up")
end

-- Print a debug message
function Data:Debug(func, ...)
    print("Crafty_" .. func .. ":", ...)
end
