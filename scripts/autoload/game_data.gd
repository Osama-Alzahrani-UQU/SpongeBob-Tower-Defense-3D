extends Node

## GameData - Central static data definitions for 3D SpongeBob Tower Defense (24 Characters across 7 Power Classifications & 6 Rarity Tiers)
## Created & Owned by: Osama-Alzahrani-UQU (https://github.com/Osama-Alzahrani-UQU)

const PROJECT_OWNER: String = "Osama-Alzahrani-UQU"
const PROJECT_GITHUB_URL: String = "https://github.com/Osama-Alzahrani-UQU"

# Rarities
enum Rarity { COMMON, RARE, EPIC, LEGENDARY, MYTHIC, SECRET }

const RARITY_COLORS = {
	Rarity.COMMON: Color("#A6B4C0"),
	Rarity.RARE: Color("#3498DB"),
	Rarity.EPIC: Color("#AF52DE"),
	Rarity.LEGENDARY: Color("#F39C12"),
	Rarity.MYTHIC: Color("#FF3B30"),
	Rarity.SECRET: Color("#00FFAA"),
}

const RARITY_NAMES = {
	Rarity.COMMON: "Common",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic",
	Rarity.LEGENDARY: "Legendary",
	Rarity.MYTHIC: "Mythic",
	Rarity.SECRET: "Secret",
}

const RARITY_DROP_RATES = {
	Rarity.COMMON: 0.52,
	Rarity.RARE: 0.26,
	Rarity.EPIC: 0.13,
	Rarity.LEGENDARY: 0.065,
	Rarity.MYTHIC: 0.020,
	Rarity.SECRET: 0.005,
}

# Power Classifications
const POWER_CLASSES = {
	"all": {
		"id": "all",
		"name": "All Power Classes",
		"short": "🌐 All",
		"color": Color("#38D2FF")
	},
	"control": {
		"id": "control",
		"name": "Crowd Control",
		"short": "❄️ Control",
		"color": Color("#5DADE2")
	},
	"brawler": {
		"id": "brawler",
		"name": "Heavy Brawler",
		"short": "🪨 Brawler",
		"color": Color("#EC7063")
	},
	"aoe": {
		"id": "aoe",
		"name": "Sonic & Splash AoE",
		"short": "🎵 AoE",
		"color": Color("#48C9B0")
	},
	"marksman": {
		"id": "marksman",
		"name": "Rapid Marksman",
		"short": "⚡ Rapid",
		"color": Color("#F5B041")
	},
	"economy": {
		"id": "economy",
		"name": "Economy & Support",
		"short": "💰 Economy",
		"color": Color("#F4D03F")
	},
	"spectral": {
		"id": "spectral",
		"name": "Spectral & Abyssal",
		"short": "👻 Spectral",
		"color": Color("#BB8FCE")
	},
	"cosmic": {
		"id": "cosmic",
		"name": "Cosmic & Divine",
		"short": "👑 Divine",
		"color": Color("#00FFAA")
	}
}

const POWER_CLASS_ORDER = ["all", "control", "brawler", "aoe", "marksman", "economy", "spectral", "cosmic"]

const TOWER_ORDER = [
	# Common (3)
	"spongebob", "patrick", "gary",
	# Rare (5)
	"squidward", "mrs_puff", "larry_lobster", "plankton_mech", "karen_2",
	# Epic (5)
	"mr_krabs", "sandy", "pearl_krabs", "dirty_bubble", "barnacle_boy",
	# Legendary (4)
	"man_ray", "squilliam", "mermaid_man", "patchy_pirate",
	# Mythic (4)
	"flying_dutchman", "goofy_goober_rock", "hash_slinging_slasher", "alaskan_bull_worm",
	# Secret / Cosmic (3)
	"king_neptune", "david_hasselhoff", "doodlebob"
]

# 24 Iconic 3D Tower Definitions
const TOWERS = {
	# ==================== COMMON ====================
	"spongebob": {
		"id": "spongebob",
		"name": "SpongeBob",
		"arabic_name": "SpongeBob",
		"rarity": Rarity.COMMON,
		"power_class": "control",
		"power_rating": 140,
		"cost": 150,
		"base_damage": 18.0,
		"base_spa": 1.2,
		"base_range": 7.5,
		"type": "crowd_control",
		"placement_limit": 4,
		"description": "Fires 3D soap bubbles that damage and slow enemies down by 40%.",
		"color": Color("#F7DC6F"),
		"attack_color": Color("#85C1E9"),
		"upgrades": [
			{"cost": 120, "damage_add": 12.0, "spa_mult": 0.9, "range_add": 1.0, "title": "Bubble Wand"},
			{"cost": 250, "damage_add": 20.0, "spa_mult": 0.85, "range_add": 1.5, "title": "Soapy Torrent"},
			{"cost": 500, "damage_add": 35.0, "spa_mult": 0.8, "range_add": 2.0, "title": "Bubble Bomb (AoE Pop)"},
			{"cost": 1100, "damage_add": 80.0, "spa_mult": 0.7, "range_add": 3.0, "title": "MAX: Goofy Goober Wrath"}
		]
	},
	"patrick": {
		"id": "patrick",
		"name": "Patrick Star",
		"arabic_name": "Patrick Star",
		"rarity": Rarity.COMMON,
		"power_class": "brawler",
		"power_rating": 165,
		"cost": 200,
		"base_damage": 45.0,
		"base_spa": 2.2,
		"base_range": 6.5,
		"type": "single_target",
		"placement_limit": 4,
		"description": "Hurls 3D heavy boulders with massive single-target impact.",
		"color": Color("#F1948A"),
		"attack_color": Color("#D98880"),
		"upgrades": [
			{"cost": 180, "damage_add": 30.0, "spa_mult": 0.95, "range_add": 0.8, "title": "Heavier Boulders"},
			{"cost": 380, "damage_add": 65.0, "spa_mult": 0.9, "range_add": 1.2, "title": "Wumbo Smash"},
			{"cost": 850, "damage_add": 140.0, "spa_mult": 0.85, "range_add": 1.8, "title": "Starfish Slammer"},
			{"cost": 1800, "damage_add": 320.0, "spa_mult": 0.75, "range_add": 2.5, "title": "MAX: Patrick Unstoppable"}
		]
	},
	"gary": {
		"id": "gary",
		"name": "Gary the Snail",
		"arabic_name": "Gary the Snail",
		"rarity": Rarity.COMMON,
		"power_class": "control",
		"power_rating": 180,
		"cost": 175,
		"base_damage": 22.0,
		"base_spa": 1.3,
		"base_range": 7.0,
		"type": "crowd_control",
		"placement_limit": 4,
		"description": "Coats lanes in sticky snail slime, slowing enemies by 50% and corroding armor.",
		"color": Color("#F5B7B1"),
		"attack_color": Color("#58D68D"),
		"upgrades": [
			{"cost": 140, "damage_add": 15.0, "spa_mult": 0.9, "range_add": 0.9, "title": "Sticky Mucus"},
			{"cost": 290, "damage_add": 28.0, "spa_mult": 0.86, "range_add": 1.3, "title": "Shell Spin"},
			{"cost": 600, "damage_add": 55.0, "spa_mult": 0.8, "range_add": 1.8, "title": "Meow Sonic Pulse"},
			{"cost": 1250, "damage_add": 110.0, "spa_mult": 0.72, "range_add": 2.4, "title": "MAX: Dream Library Sage"}
		]
	},

	# ==================== RARE ====================
	"squidward": {
		"id": "squidward",
		"name": "Squidward",
		"arabic_name": "Squidward",
		"rarity": Rarity.RARE,
		"power_class": "aoe",
		"power_rating": 280,
		"cost": 300,
		"base_damage": 25.0,
		"base_spa": 1.8,
		"base_range": 8.5,
		"type": "aoe",
		"placement_limit": 3,
		"description": "Plays dissonant clarinet melodies creating 3D sonic shockwaves that hit all enemies in range.",
		"color": Color("#73C6B6"),
		"attack_color": Color("#48C9B0"),
		"upgrades": [
			{"cost": 240, "damage_add": 18.0, "spa_mult": 0.92, "range_add": 1.2, "title": "Sharp Notes"},
			{"cost": 500, "damage_add": 38.0, "spa_mult": 0.88, "range_add": 1.8, "title": "Fortissimo Blast"},
			{"cost": 1100, "damage_add": 85.0, "spa_mult": 0.82, "range_add": 2.5, "title": "Sonic Shockwave"},
			{"cost": 2400, "damage_add": 210.0, "spa_mult": 0.7, "range_add": 3.5, "title": "MAX: Talent Concert Maestro"}
		]
	},
	"mrs_puff": {
		"id": "mrs_puff",
		"name": "Mrs. Puff",
		"arabic_name": "Mrs. Puff",
		"rarity": Rarity.RARE,
		"power_class": "control",
		"power_rating": 310,
		"cost": 320,
		"base_damage": 34.0,
		"base_spa": 1.6,
		"base_range": 7.8,
		"type": "crowd_control",
		"placement_limit": 3,
		"description": "Inflates into a giant spiky pufferball, knocking back and slowing enemies with boating rage.",
		"color": Color("#F9E79F"),
		"attack_color": Color("#F4D03F"),
		"upgrades": [
			{"cost": 260, "damage_add": 22.0, "spa_mult": 0.9, "range_add": 1.0, "title": "Failed Road Test"},
			{"cost": 540, "damage_add": 45.0, "spa_mult": 0.85, "range_add": 1.5, "title": "Spiky Inflation"},
			{"cost": 1150, "damage_add": 95.0, "spa_mult": 0.8, "range_add": 2.0, "title": "Boating School Crash"},
			{"cost": 2300, "damage_add": 220.0, "spa_mult": 0.7, "range_add": 2.8, "title": "MAX: Demolition Derby Queen"}
		]
	},
	"larry_lobster": {
		"id": "larry_lobster",
		"name": "Larry Lobster",
		"arabic_name": "Larry Lobster",
		"rarity": Rarity.RARE,
		"power_class": "brawler",
		"power_rating": 340,
		"cost": 350,
		"base_damage": 75.0,
		"base_spa": 1.9,
		"base_range": 6.8,
		"type": "single_target",
		"placement_limit": 3,
		"description": "Goo Lagoon lifeguard who slams iron barbells and anchor weights onto armored targets.",
		"color": Color("#E74C3C"),
		"attack_color": Color("#C0392B"),
		"upgrades": [
			{"cost": 280, "damage_add": 48.0, "spa_mult": 0.92, "range_add": 0.8, "title": "Protein Shake"},
			{"cost": 580, "damage_add": 95.0, "spa_mult": 0.86, "range_add": 1.2, "title": "Anchor Deadlift"},
			{"cost": 1200, "damage_add": 190.0, "spa_mult": 0.8, "range_add": 1.6, "title": "Goo Lagoon Flex"},
			{"cost": 2500, "damage_add": 420.0, "spa_mult": 0.72, "range_add": 2.2, "title": "MAX: Mr. Sun Tan Champion"}
		]
	},
	"plankton_mech": {
		"id": "plankton_mech",
		"name": "Sheldon Plankton",
		"arabic_name": "Sheldon Plankton",
		"rarity": Rarity.RARE,
		"power_class": "marksman",
		"power_rating": 330,
		"cost": 310,
		"base_damage": 28.0,
		"base_spa": 0.85,
		"base_range": 9.0,
		"type": "rapid_dps",
		"placement_limit": 3,
		"description": "Fires rapid-fire Chum Bucket plasma bolts from his laboratory laser turret.",
		"color": Color("#117864"),
		"attack_color": Color("#FF3B30"),
		"upgrades": [
			{"cost": 250, "damage_add": 18.0, "spa_mult": 0.9, "range_add": 1.2, "title": "Overclocked Diode"},
			{"cost": 520, "damage_add": 38.0, "spa_mult": 0.85, "range_add": 1.6, "title": "Plan Z Cannon"},
			{"cost": 1100, "damage_add": 82.0, "spa_mult": 0.78, "range_add": 2.2, "title": "Micro-Mecha Assault"},
			{"cost": 2200, "damage_add": 195.0, "spa_mult": 0.68, "range_add": 3.0, "title": "MAX: Supreme Evil Genius"}
		]
	},
	"karen_2": {
		"id": "karen_2",
		"name": "Karen 2.0",
		"arabic_name": "Karen 2.0",
		"rarity": Rarity.RARE,
		"power_class": "economy",
		"power_rating": 325,
		"cost": 340,
		"base_damage": 0.0,
		"base_spa": 1.5,
		"base_range": 8.2,
		"type": "economy",
		"placement_limit": 2,
		"income_per_wave": 110,
		"description": "Supercomputer AI that mines crypto-cash each wave with celebratory data cash fountains! Dedicated economy unit (does not attack).",
		"color": Color("#2C3E50"),
		"attack_color": Color("#2ECC71"),
		"upgrades": [
			{"cost": 280, "income_add": 95, "range_add": 1.0, "title": "RAM Expansion"},
			{"cost": 600, "income_add": 210, "range_add": 1.5, "title": "Quantum Mining Core"},
			{"cost": 1250, "income_add": 420, "range_add": 2.0, "title": "Mainframe Overdrive"},
			{"cost": 2600, "income_add": 920, "range_add": 2.8, "title": "MAX: Singularity Crypto Vault"}
		]
	},

	# ==================== EPIC ====================
	"mr_krabs": {
		"id": "mr_krabs",
		"name": "Mr. Krabs",
		"arabic_name": "Mr. Krabs",
		"rarity": Rarity.EPIC,
		"power_class": "economy",
		"power_rating": 520,
		"cost": 400,
		"base_damage": 0.0,
		"base_spa": 2.4,
		"base_range": 6.5,
		"type": "economy",
		"placement_limit": 2,
		"description": "Generates massive cash at the end of each wave with a golden celebration fountain! Dedicated economy unit (does not attack).",
		"color": Color("#E74C3C"),
		"attack_color": Color("#F4D03F"),
		"income_per_wave": 165,
		"upgrades": [
			{"cost": 350, "income_add": 140, "range_add": 0.8, "title": "Tip Jar Expansion"},
			{"cost": 750, "income_add": 320, "range_add": 1.2, "title": "First Dollar Frame"},
			{"cost": 1600, "income_add": 680, "range_add": 1.8, "title": "Franchise Expansion"},
			{"cost": 3200, "income_add": 1500, "range_add": 2.5, "title": "MAX: Secret Vault Empire"},
		]
	},
	"sandy": {
		"id": "sandy",
		"name": "Sandy Cheeks",
		"arabic_name": "Sandy Cheeks",
		"rarity": Rarity.EPIC,
		"power_class": "marksman",
		"power_rating": 580,
		"cost": 450,
		"base_damage": 55.0,
		"base_spa": 0.7,
		"base_range": 9.5,
		"type": "rapid_dps",
		"placement_limit": 3,
		"description": "High-velocity karate strikes and explosive 3D acorns with blistering attack speed.",
		"color": Color("#D35400"),
		"attack_color": Color("#E67E22"),
		"upgrades": [
			{"cost": 320, "damage_add": 35.0, "spa_mult": 0.9, "range_add": 1.0, "title": "Black Belt Chop"},
			{"cost": 700, "damage_add": 75.0, "spa_mult": 0.85, "range_add": 1.5, "title": "Acorn Grenades"},
			{"cost": 1500, "damage_add": 160.0, "spa_mult": 0.8, "range_add": 2.0, "title": "Rodeo Cyclone"},
			{"cost": 3000, "damage_add": 380.0, "spa_mult": 0.65, "range_add": 3.0, "title": "MAX: Texas Supreme Master"}
		]
	},
	"pearl_krabs": {
		"id": "pearl_krabs",
		"name": "Pearl Krabs",
		"arabic_name": "Pearl Krabs",
		"rarity": Rarity.EPIC,
		"power_class": "brawler",
		"power_rating": 560,
		"cost": 480,
		"base_damage": 115.0,
		"base_spa": 2.0,
		"base_range": 7.5,
		"type": "aoe",
		"placement_limit": 3,
		"description": "Unleashes colossal cheerleader whale stomps that shake the ocean floor in an AoE radius.",
		"color": Color("#FF69B4"),
		"attack_color": Color("#F48FB1"),
		"upgrades": [
			{"cost": 380, "damage_add": 70.0, "spa_mult": 0.92, "range_add": 1.0, "title": "Mall Spree Tremor"},
			{"cost": 820, "damage_add": 145.0, "spa_mult": 0.86, "range_add": 1.4, "title": "Cheer Megaphone"},
			{"cost": 1700, "damage_add": 310.0, "spa_mult": 0.8, "range_add": 2.0, "title": "Tidal Tantrum"},
			{"cost": 3400, "damage_add": 680.0, "spa_mult": 0.72, "range_add": 2.8, "title": "MAX: Prom Queen Tsunami"}
		]
	},
	"dirty_bubble": {
		"id": "dirty_bubble",
		"name": "Dirty Bubble",
		"arabic_name": "Dirty Bubble",
		"rarity": Rarity.EPIC,
		"power_class": "aoe",
		"power_rating": 590,
		"cost": 500,
		"base_damage": 68.0,
		"base_spa": 1.4,
		"base_range": 8.8,
		"type": "aoe",
		"placement_limit": 3,
		"description": "Supervillain bubble that engulfs enemy squads in corrosive sludge explosions and slows them.",
		"color": Color("#6E473B"),
		"attack_color": Color("#8E44AD"),
		"upgrades": [
			{"cost": 400, "damage_add": 42.0, "spa_mult": 0.9, "range_add": 1.1, "title": "Sludge Coat"},
			{"cost": 850, "damage_add": 92.0, "spa_mult": 0.85, "range_add": 1.6, "title": "E.V.I.L. Smog"},
			{"cost": 1800, "damage_add": 195.0, "spa_mult": 0.78, "range_add": 2.2, "title": "Muddy Vortex"},
			{"cost": 3600, "damage_add": 450.0, "spa_mult": 0.68, "range_add": 3.0, "title": "MAX: Abyssal Pollution Lord"}
		]
	},
	"barnacle_boy": {
		"id": "barnacle_boy",
		"name": "Barnacle Boy",
		"arabic_name": "Barnacle Boy",
		"rarity": Rarity.EPIC,
		"power_class": "marksman",
		"power_rating": 610,
		"cost": 520,
		"base_damage": 85.0,
		"base_spa": 0.95,
		"base_range": 11.5,
		"type": "rapid_dps",
		"placement_limit": 3,
		"description": "Long-range superhero sidekick who snipes distant threats with scorching Sulfur Vision beams.",
		"color": Color("#2E86C1"),
		"attack_color": Color("#FF5722"),
		"upgrades": [
			{"cost": 420, "damage_add": 55.0, "spa_mult": 0.9, "range_add": 1.5, "title": "Adult-Sized Pipsqueak"},
			{"cost": 880, "damage_add": 115.0, "spa_mult": 0.84, "range_add": 2.0, "title": "Sulfur Vision II"},
			{"cost": 1850, "damage_add": 240.0, "spa_mult": 0.78, "range_add": 2.8, "title": "Aqua Laser Focus"},
			{"cost": 3800, "damage_add": 540.0, "spa_mult": 0.66, "range_add": 3.8, "title": "MAX: Barnacle Man Awakened"}
		]
	},

	# ==================== LEGENDARY ====================
	"man_ray": {
		"id": "man_ray",
		"name": "Man Ray",
		"arabic_name": "Man Ray",
		"rarity": Rarity.LEGENDARY,
		"power_class": "brawler",
		"power_rating": 920,
		"cost": 680,
		"base_damage": 160.0,
		"base_spa": 1.1,
		"base_range": 9.8,
		"type": "single_target",
		"placement_limit": 2,
		"description": "Arch-nemesis of Mermaid Man who blasts high-density plasma rays and heavy anti-boss torpedoes.",
		"color": Color("#C0392B"),
		"attack_color": Color("#FF1744"),
		"upgrades": [
			{"cost": 550, "damage_add": 105.0, "spa_mult": 0.9, "range_add": 1.2, "title": "Tickle Belt Removed"},
			{"cost": 1150, "damage_add": 220.0, "spa_mult": 0.84, "range_add": 1.8, "title": "Manta Plasma Cannon"},
			{"cost": 2400, "damage_add": 460.0, "spa_mult": 0.78, "range_add": 2.4, "title": "Tartar Sauce Detonator"},
			{"cost": 4800, "damage_add": 980.0, "spa_mult": 0.65, "range_add": 3.2, "title": "MAX: Emperor of E.V.I.L."}
		]
	},
	"squilliam": {
		"id": "squilliam",
		"name": "Squilliam Fancyson",
		"arabic_name": "Squilliam Fancyson",
		"rarity": Rarity.LEGENDARY,
		"power_class": "aoe",
		"power_rating": 960,
		"cost": 720,
		"base_damage": 135.0,
		"base_spa": 1.35,
		"base_range": 10.5,
		"type": "aoe",
		"placement_limit": 2,
		"description": "Conducts a golden Bubble Bowl symphony that rains harmonic shockwaves and bonus gold on impact.",
		"color": Color("#78281F"),
		"attack_color": Color("#F1C40F"),
		"income_per_wave": 140,
		"upgrades": [
			{"cost": 600, "damage_add": 85.0, "income_add": 90, "spa_mult": 0.9, "range_add": 1.3, "title": "Golden Unibrow"},
			{"cost": 1250, "damage_add": 180.0, "income_add": 180, "spa_mult": 0.85, "range_add": 1.8, "title": "Private Yacht Sonar"},
			{"cost": 2600, "damage_add": 380.0, "income_add": 360, "spa_mult": 0.78, "range_add": 2.5, "title": "Five-Star Crescendo"},
			{"cost": 5200, "damage_add": 840.0, "income_add": 720, "spa_mult": 0.68, "range_add": 3.5, "title": "MAX: Bubble Bowl Maestro"}
		]
	},
	"mermaid_man": {
		"id": "mermaid_man",
		"name": "Mermaid Man",
		"arabic_name": "Mermaid Man",
		"rarity": Rarity.LEGENDARY,
		"power_class": "marksman",
		"power_rating": 990,
		"cost": 750,
		"base_damage": 145.0,
		"base_spa": 0.9,
		"base_range": 11.0,
		"type": "aoe",
		"placement_limit": 2,
		"description": "Defender of the Deep! Hurls Raging Whirlpool waterballs and shrinks bosses with the Wumbo Belt.",
		"color": Color("#E67E22"),
		"attack_color": Color("#00BFFF"),
		"upgrades": [
			{"cost": 620, "damage_add": 95.0, "spa_mult": 0.9, "range_add": 1.4, "title": "Raging Whirlpool"},
			{"cost": 1300, "damage_add": 200.0, "spa_mult": 0.84, "range_add": 2.0, "title": "Invisible Boatmobile"},
			{"cost": 2700, "damage_add": 420.0, "spa_mult": 0.76, "range_add": 2.6, "title": "Orb of Confusion"},
			{"cost": 5500, "damage_add": 920.0, "spa_mult": 0.64, "range_add": 3.5, "title": "MAX: Prime Hero of Atlantis"}
		]
	},
	"patchy_pirate": {
		"id": "patchy_pirate",
		"name": "Patchy the Pirate",
		"arabic_name": "Patchy the Pirate",
		"rarity": Rarity.LEGENDARY,
		"power_class": "economy",
		"power_rating": 1020,
		"cost": 700,
		"base_damage": 0.0,
		"base_spa": 1.4,
		"base_range": 9.5,
		"type": "economy",
		"placement_limit": 2,
		"income_per_wave": 280,
		"description": "President of the SpongeBob Fan Club! Excavates buried treasure chests erupting with gold & cash every wave! Dedicated economy unit (does not attack).",
		"color": Color("#C0392B"),
		"attack_color": Color("#F39C12"),
		"upgrades": [
			{"cost": 580, "income_add": 240, "range_add": 1.2, "title": "Potty Gold Chest"},
			{"cost": 1200, "income_add": 520, "range_add": 1.6, "title": "Encino Galleon Vault"},
			{"cost": 2500, "income_add": 1100, "range_add": 2.2, "title": "Lost Episode Treasure"},
			{"cost": 5000, "income_add": 2400, "range_add": 3.0, "title": "MAX: Pirate King's Hoard"}
		]
	},

	# ==================== MYTHIC ====================
	"flying_dutchman": {
		"id": "flying_dutchman",
		"name": "Flying Dutchman",
		"arabic_name": "Flying Dutchman",
		"rarity": Rarity.MYTHIC,
		"power_class": "spectral",
		"power_rating": 1850,
		"cost": 1000,
		"base_damage": 220.0,
		"base_spa": 1.5,
		"base_range": 13.0,
		"type": "hybrid_annihilator",
		"placement_limit": 1,
		"description": "Summons ghostly 3D spectral flames that burn entire lanes and drag bosses into Davy Jones' Locker.",
		"color": Color("#1ABC9C"),
		"attack_color": Color("#58D68D"),
		"upgrades": [
			{"cost": 800, "damage_add": 150.0, "spa_mult": 0.9, "range_add": 1.5, "title": "Soul Collector"},
			{"cost": 1800, "damage_add": 320.0, "spa_mult": 0.85, "range_add": 2.2, "title": "Ghost Ship Cannons"},
			{"cost": 3800, "damage_add": 700.0, "spa_mult": 0.78, "range_add": 3.0, "title": "Davy Jones' Maelstrom"},
			{"cost": 8000, "damage_add": 1600.0, "spa_mult": 0.65, "range_add": 4.0, "title": "MAX: Reign of the Spectral Pirate"}
		]
	},
	"goofy_goober_rock": {
		"id": "goofy_goober_rock",
		"name": "Goofy Goober Wizard",
		"arabic_name": "Goofy Goober Wizard",
		"rarity": Rarity.MYTHIC,
		"power_class": "aoe",
		"power_rating": 2100,
		"cost": 1150,
		"base_damage": 260.0,
		"base_spa": 1.1,
		"base_range": 13.5,
		"type": "aoe",
		"placement_limit": 1,
		"description": "Shreds the Electric Peanut Guitar to unleash blinding magenta laser solos that vaporize Plankton's buckets.",
		"color": Color("#8E44AD"),
		"attack_color": Color("#FF00FF"),
		"upgrades": [
			{"cost": 900, "damage_add": 175.0, "spa_mult": 0.88, "range_add": 1.6, "title": "Power Chord Solo"},
			{"cost": 2000, "damage_add": 380.0, "spa_mult": 0.82, "range_add": 2.4, "title": "Laser Amp Overdrive"},
			{"cost": 4200, "damage_add": 820.0, "spa_mult": 0.74, "range_add": 3.2, "title": "Mind Control Breaker"},
			{"cost": 8800, "damage_add": 1850.0, "spa_mult": 0.60, "range_add": 4.5, "title": "MAX: I'm a Goofy Goober ROCK!"}
		]
	},
	"hash_slinging_slasher": {
		"id": "hash_slinging_slasher",
		"name": "Hash-Slinging Slasher",
		"arabic_name": "Hash-Slinging Slasher",
		"rarity": Rarity.MYTHIC,
		"power_class": "spectral",
		"power_rating": 2250,
		"cost": 1200,
		"base_damage": 310.0,
		"base_spa": 1.25,
		"base_range": 12.5,
		"type": "hybrid_annihilator",
		"placement_limit": 1,
		"description": "Emerges from the Graveyard Shift mist with a glowing spectral spatula that cleaves and terrifies bosses.",
		"color": Color("#4A235A"),
		"attack_color": Color("#00E676"),
		"upgrades": [
			{"cost": 950, "damage_add": 210.0, "spa_mult": 0.88, "range_add": 1.5, "title": "Flickering Lights"},
			{"cost": 2100, "damage_add": 450.0, "spa_mult": 0.82, "range_add": 2.2, "title": "Ringing Phone Omen"},
			{"cost": 4500, "damage_add": 960.0, "spa_mult": 0.74, "range_add": 3.0, "title": "Ghost Bus Arrival"},
			{"cost": 9200, "damage_add": 2100.0, "spa_mult": 0.62, "range_add": 4.2, "title": "MAX: Graveyard Shift Nightmare"}
		]
	},
	"alaskan_bull_worm": {
		"id": "alaskan_bull_worm",
		"name": "Alaskan Bull Worm",
		"arabic_name": "Alaskan Bull Worm",
		"rarity": Rarity.MYTHIC,
		"power_class": "brawler",
		"power_rating": 2400,
		"cost": 1300,
		"base_damage": 420.0,
		"base_spa": 1.7,
		"base_range": 12.0,
		"type": "aoe",
		"placement_limit": 1,
		"description": "It's BIG, SCARY, and PINK! Devours entire waves and crushes bosses with seismic tectonic slams.",
		"color": Color("#F1948A"),
		"attack_color": Color("#E74C3C"),
		"upgrades": [
			{"cost": 1000, "damage_add": 280.0, "spa_mult": 0.9, "range_add": 1.5, "title": "Tongue Lash"},
			{"cost": 2300, "damage_add": 600.0, "spa_mult": 0.84, "range_add": 2.2, "title": "Tectonic Tunnel"},
			{"cost": 4800, "damage_add": 1250.0, "spa_mult": 0.76, "range_add": 3.0, "title": "Cliff Fall Crush"},
			{"cost": 9800, "damage_add": 2700.0, "spa_mult": 0.65, "range_add": 4.0, "title": "MAX: Devourer of Bikini Bottom"}
		]
	},

	# ==================== SECRET / COSMIC ====================
	"king_neptune": {
		"id": "king_neptune",
		"name": "King Neptune",
		"arabic_name": "King Neptune",
		"rarity": Rarity.SECRET,
		"power_class": "cosmic",
		"power_rating": 4800,
		"cost": 1600,
		"base_damage": 480.0,
		"base_spa": 0.95,
		"base_range": 15.0,
		"type": "hybrid_annihilator",
		"placement_limit": 1,
		"description": "Supreme Ruler of the Seven Seas! Calls down divine golden Trident lightning storms across the map.",
		"color": Color("#48C9B0"),
		"attack_color": Color("#00FFAA"),
		"upgrades": [
			{"cost": 1300, "damage_add": 350.0, "spa_mult": 0.88, "range_add": 2.0, "title": "Royal Trident Zap"},
			{"cost": 2800, "damage_add": 780.0, "spa_mult": 0.80, "range_add": 3.0, "title": "Poseidon's Colosseum"},
			{"cost": 6000, "damage_add": 1650.0, "spa_mult": 0.72, "range_add": 4.0, "title": "Shining Bald Crown"},
			{"cost": 12000, "damage_add": 3600.0, "spa_mult": 0.58, "range_add": 5.5, "title": "MAX: God of the Seven Seas"}
		]
	},
	"david_hasselhoff": {
		"id": "david_hasselhoff",
		"name": "The Hasselhoff",
		"arabic_name": "The Hasselhoff",
		"rarity": Rarity.SECRET,
		"power_class": "cosmic",
		"power_rating": 5200,
		"cost": 1750,
		"base_damage": 390.0,
		"base_spa": 0.65,
		"base_range": 16.0,
		"type": "rapid_dps",
		"placement_limit": 1,
		"description": "Legendary human lifeguard who launches supersonic pectoral missiles and turbo speedboat shockwaves.",
		"color": Color("#E74C3C"),
		"attack_color": Color("#FFD700"),
		"upgrades": [
			{"cost": 1400, "damage_add": 290.0, "spa_mult": 0.86, "range_add": 2.0, "title": "Turbo Swim Thrust"},
			{"cost": 3000, "damage_add": 640.0, "spa_mult": 0.78, "range_add": 3.0, "title": "Baywatch Rescue Flare"},
			{"cost": 6500, "damage_add": 1400.0, "spa_mult": 0.70, "range_add": 4.2, "title": "Pectoral Launchpad"},
			{"cost": 13500, "damage_add": 3100.0, "spa_mult": 0.55, "range_add": 6.0, "title": "MAX: Ocean Highway Legend"}
		]
	},
	"doodlebob": {
		"id": "doodlebob",
		"name": "DoodleBob",
		"arabic_name": "DoodleBob",
		"rarity": Rarity.SECRET,
		"power_class": "cosmic",
		"power_rating": 6000,
		"cost": 1900,
		"base_damage": 620.0,
		"base_spa": 1.05,
		"base_range": 15.5,
		"type": "hybrid_annihilator",
		"placement_limit": 1,
		"description": "ME HOY MINOY! Wields the giant Magic Pencil from above to erase enemies from reality in 3D space.",
		"color": Color("#FFFFFF"),
		"attack_color": Color("#1C2833"),
		"upgrades": [
			{"cost": 1500, "damage_add": 440.0, "spa_mult": 0.88, "range_add": 2.0, "title": "Graphite Slash"},
			{"cost": 3200, "damage_add": 950.0, "spa_mult": 0.80, "range_add": 3.0, "title": "Rubber Eraser Sweep"},
			{"cost": 7000, "damage_add": 2050.0, "spa_mult": 0.72, "range_add": 4.2, "title": "2D Dimension Trap"},
			{"cost": 15000, "damage_add": 4500.0, "spa_mult": 0.58, "range_add": 5.8, "title": "MAX: ME HOY MINOY Omnipotence"}
		]
	}
}

# Traits System (Each Trait has a Custom SVG Emblem + Animated Card Visual Effect)
const TRAITS = {
	"none": {
		"id": "none",
		"name": "None",
		"arabic_name": "None",
		"symbol": "⚪",
		"icon": "",
		"color": Color("#85929E"),
		"glow_color": Color("#5D6D7E"),
		"fx_style": "none",
		"rarity_weight": 0,
		"damage_mult": 1.0,
		"spa_mult": 1.0,
		"range_mult": 1.0,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "Standard unit stats."
	},
	"neptunes_crown": {
		"id": "neptunes_crown",
		"name": "Neptune's Crown",
		"arabic_name": "Neptune's Crown",
		"symbol": "👑",
		"icon": "res://assets/trait_neptunes_crown.svg",
		"color": Color("#00FFAA"),
		"glow_color": Color("#FFD700"),
		"fx_style": "divine_crown",
		"chance": 0.0001,
		"damage_mult": 1.6,
		"spa_mult": 0.6,
		"range_mult": 1.4,
		"extra_placement": 1,
		"upgrade_cost_mult": 0.8,
		"desc": "+60% Damage, -40% SPA, +40% Range, +1 Placement Limit."
	},
	"secret_formula": {
		"id": "secret_formula",
		"name": "Secret Formula",
		"arabic_name": "Secret Formula",
		"symbol": "🧪",
		"icon": "res://assets/trait_secret_formula.svg",
		"color": Color("#00E676"),
		"glow_color": Color("#B9F6CA"),
		"fx_style": "radioactive_formula",
		"chance": 0.005,
		"damage_mult": 1.5,
		"spa_mult": 0.5,
		"range_mult": 1.5,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "+50% Damage, -50% SPA (2x speed), +50% Range."
	},
	"sidekick": {
		"id": "sidekick",
		"name": "Sidekick",
		"arabic_name": "Sidekick",
		"symbol": "🛡️",
		"icon": "res://assets/trait_sidekick.svg",
		"color": Color("#00E5FF"),
		"glow_color": Color("#FF6D00"),
		"fx_style": "hero_shield",
		"chance": 0.0075,
		"damage_mult": 1.15,
		"spa_mult": 0.9,
		"range_mult": 1.1,
		"extra_placement": 1,
		"upgrade_cost_mult": 1.0,
		"desc": "+1 Placement Limit, +15% Damage."
	},
	"vortex": {
		"id": "vortex",
		"name": "Vortex",
		"arabic_name": "Vortex",
		"symbol": "🌀",
		"icon": "res://assets/trait_vortex.svg",
		"color": Color("#D500F9"),
		"glow_color": Color("#00E5FF"),
		"fx_style": "spinning_vortex",
		"chance": 0.01,
		"damage_mult": 1.0,
		"spa_mult": 0.5,
		"range_mult": 1.0,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "-50% SPA (Attacks twice as fast)."
	},
	"sea_bear": {
		"id": "sea_bear",
		"name": "Sea Bear",
		"arabic_name": "Sea Bear",
		"symbol": "🐾",
		"icon": "res://assets/trait_sea_bear.svg",
		"color": Color("#FF1744"),
		"glow_color": Color("#FFEA00"),
		"fx_style": "berserk_claw",
		"chance": 0.03,
		"damage_mult": 2.5,
		"spa_mult": 1.2,
		"range_mult": 0.8,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "+150% Damage, +20% SPA (slower), -20% Range."
	},
	"surge_3": {
		"id": "surge_3",
		"name": "Surge III",
		"arabic_name": "Surge III",
		"symbol": "⚡",
		"icon": "res://assets/trait_surge_3.svg",
		"color": Color("#00E5FF"),
		"glow_color": Color("#FFEA00"),
		"fx_style": "electric_surge",
		"chance": 0.05,
		"damage_mult": 1.0,
		"spa_mult": 0.7,
		"range_mult": 1.0,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "-30% SPA."
	},
	"reach_3": {
		"id": "reach_3",
		"name": "Reach III",
		"arabic_name": "Reach III",
		"symbol": "🎯",
		"icon": "res://assets/trait_reach_3.svg",
		"color": Color("#1DE9B6"),
		"glow_color": Color("#64FFDA"),
		"fx_style": "radar_pulse",
		"chance": 0.08,
		"damage_mult": 1.0,
		"spa_mult": 1.0,
		"range_mult": 1.45,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "+45% Range."
	},
	"strike_3": {
		"id": "strike_3",
		"name": "Strike III",
		"arabic_name": "Strike III",
		"symbol": "⚔️",
		"icon": "res://assets/trait_strike_3.svg",
		"color": Color("#FF6D00"),
		"glow_color": Color("#FFEA00"),
		"fx_style": "blazing_strike",
		"chance": 0.10,
		"damage_mult": 1.45,
		"spa_mult": 1.0,
		"range_mult": 1.0,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.0,
		"desc": "+45% Damage."
	},
	"wealth": {
		"id": "wealth",
		"name": "Wealth",
		"arabic_name": "Wealth",
		"symbol": "💰",
		"icon": "res://assets/trait_wealth.svg",
		"color": Color("#FFD700"),
		"glow_color": Color("#FFF59D"),
		"fx_style": "golden_wealth",
		"chance": 0.12,
		"damage_mult": 1.0,
		"spa_mult": 1.0,
		"range_mult": 1.0,
		"extra_placement": 0,
		"upgrade_cost_mult": 0.8,
		"desc": "-20% Battle upgrade costs."
	},
	"scurvy": {
		"id": "scurvy",
		"name": "Scurvy (Curse)",
		"arabic_name": "Scurvy (Curse)",
		"symbol": "💀",
		"icon": "res://assets/trait_scurvy.svg",
		"color": Color("#AB47BC"),
		"glow_color": Color("#00E676"),
		"fx_style": "cursed_mist",
		"chance": 0.15,
		"damage_mult": 0.75,
		"spa_mult": 1.25,
		"range_mult": 0.8,
		"extra_placement": 0,
		"upgrade_cost_mult": 1.25,
		"desc": "Cursed: -25% Damage, +25% SPA, -20% Range, +25% Upgrade Costs."
	}
}

# Trait Reroll Odds in Plankton's Laboratory (Full list of obtainable traits with appearance percentages)
const TRAIT_REROLL_POOL = [
	{
		"id": "neptunes_crown",
		"chance": 0.005,
		"chance_pct": "0.5%",
		"tier": "Cosmic",
		"tier_color": Color("#00FFAA"),
		"summary": "+60% DMG, -40% SPA, +40% RNG, +1 Limit"
	},
	{
		"id": "secret_formula",
		"chance": 0.015,
		"chance_pct": "1.5%",
		"tier": "Secret",
		"tier_color": Color("#00E676"),
		"summary": "+50% DMG, -50% SPA (2x Speed), +50% RNG"
	},
	{
		"id": "sidekick",
		"chance": 0.04,
		"chance_pct": "4.0%",
		"tier": "Heroic",
		"tier_color": Color("#00E5FF"),
		"summary": "+1 Placement Limit, +15% DMG"
	},
	{
		"id": "vortex",
		"chance": 0.07,
		"chance_pct": "7.0%",
		"tier": "Legendary",
		"tier_color": Color("#D500F9"),
		"summary": "-50% SPA (Attacks 2x faster)"
	},
	{
		"id": "sea_bear",
		"chance": 0.10,
		"chance_pct": "10.0%",
		"tier": "Berserk",
		"tier_color": Color("#FF1744"),
		"summary": "+150% DMG, +20% SPA, -20% RNG"
	},
	{
		"id": "wealth",
		"chance": 0.12,
		"chance_pct": "12.0%",
		"tier": "Economy",
		"tier_color": Color("#FFD700"),
		"summary": "-20% In-Battle Upgrade Costs"
	},
	{
		"id": "surge_3",
		"chance": 0.16,
		"chance_pct": "16.0%",
		"tier": "Rare",
		"tier_color": Color("#38D2FF"),
		"summary": "-30% Attack Interval (Faster)"
	},
	{
		"id": "reach_3",
		"chance": 0.17,
		"chance_pct": "17.0%",
		"tier": "Rare",
		"tier_color": Color("#1DE9B6"),
		"summary": "+45% Attack Range"
	},
	{
		"id": "strike_3",
		"chance": 0.20,
		"chance_pct": "20.0%",
		"tier": "Rare",
		"tier_color": Color("#FF6D00"),
		"summary": "+45% Attack Damage"
	},
	{
		"id": "scurvy",
		"chance": 0.12,
		"chance_pct": "12.0%",
		"tier": "Curse",
		"tier_color": Color("#AB47BC"),
		"summary": "Cursed: -25% DMG, +25% SPA, -20% RNG"
	}
]

# 3D Enemy Definitions (Speed in 3D meters per second)
const ENEMIES = {
	# Zone 1: Bikini Bottom Outskirts Enemies
	"jellyfish_pink": {
		"name": "Pink Jellyfish",
		"hp": 90.0,
		"speed": 4.5,
		"reward": 8,
		"color": Color("#FF69B4"),
		"scale": 1.0
	},
	"jellyfish_blue": {
		"name": "Electric Blue Jellyfish",
		"hp": 220.0,
		"speed": 6.0,
		"reward": 14,
		"color": Color("#00BFFF"),
		"scale": 1.15
	},
	"robot_worker": {
		"name": "Plankton Robot Drone",
		"hp": 450.0,
		"speed": 3.5,
		"reward": 24,
		"color": Color("#7F8C8D"),
		"scale": 1.25
	},
	"robot_enforcer": {
		"name": "Chum Enforcer",
		"hp": 1200.0,
		"speed": 2.8,
		"reward": 45,
		"color": Color("#2C3E50"),
		"scale": 1.5
	},
	"mecha_plankton_boss": {
		"name": "Mecha Plankton (BOSS)",
		"hp": 5500.0,
		"speed": 2.0,
		"reward": 180,
		"color": Color("#27AE60"),
		"scale": 2.2,
		"is_boss": true
	},
	# Zone 2: Inside The Krusty Krab Enemies
	"patty_thief_anchovy": {
		"name": "Patty Thief Anchovy",
		"hp": 240.0,
		"speed": 5.8,
		"reward": 12,
		"color": Color("#3498DB"),
		"scale": 1.0
	},
	"robo_spatula": {
		"name": "Flying Robo-Spatula",
		"hp": 480.0,
		"speed": 6.4,
		"reward": 22,
		"color": Color("#BDC3C7"),
		"scale": 1.15
	},
	"grease_gremlin": {
		"name": "Kitchen Grease Gremlin",
		"hp": 1350.0,
		"speed": 2.7,
		"reward": 42,
		"color": Color("#D35400"),
		"scale": 1.4
	},
	"chum_infiltrator": {
		"name": "Chum Spy Infiltrator",
		"hp": 2100.0,
		"speed": 3.6,
		"reward": 60,
		"color": Color("#8E44AD"),
		"scale": 1.45
	},
	"robo_krabs_boss": {
		"name": "Robo-Krabs Imposter (BOSS)",
		"hp": 8800.0,
		"speed": 1.9,
		"reward": 220,
		"color": Color("#C0392B"),
		"scale": 2.4,
		"is_boss": true
	},
	# Zone 3: Inside Squidward's Moai Art Salon Enemies
	"abstract_art_creep": {
		"name": "Cubist Art Creeper",
		"hp": 650.0,
		"speed": 4.4,
		"reward": 28,
		"color": Color("#1ABC9C"),
		"scale": 1.2
	},
	"dissonant_note_drone": {
		"name": "Clarinet Sonic Note",
		"hp": 1050.0,
		"speed": 5.4,
		"reward": 38,
		"color": Color("#9B59B6"),
		"scale": 1.25
	},
	"robo_clarinetist": {
		"name": "Robo-Clarinet Virtuoso",
		"hp": 2400.0,
		"speed": 3.2,
		"reward": 70,
		"color": Color("#F39C12"),
		"scale": 1.5
	},
	"tentacle_heavy_mech": {
		"name": "Tentacle Heavy Walker",
		"hp": 3900.0,
		"speed": 2.3,
		"reward": 95,
		"color": Color("#2980B9"),
		"scale": 1.85
	},
	"squidward_critic_boss": {
		"name": "Art Critic Colossus (BOSS)",
		"hp": 14500.0,
		"speed": 1.7,
		"reward": 280,
		"color": Color("#884EA0"),
		"scale": 2.6,
		"is_boss": true
	}
}

# Campaign Expedition Zones (3 Zones)
const ZONES = {
	1: {
		"id": 1,
		"name": "Bikini Bottom Outskirts",
		"arabic_name": "Bikini Bottom Outskirts",
		"stage_range": [1, 5],
		"icon": "🌊",
		"theme": "outskirts",
		"accent_color": Color("#38BDF8"),
		"bg_color": Color("#0369A1"),
		"description": "Defend the sunlit entrance to Bikini Bottom from Plankton's scouting army."
	},
	2: {
		"id": 2,
		"name": "Inside The Krusty Krab",
		"arabic_name": "Inside The Krusty Krab",
		"stage_range": [6, 10],
		"icon": "🍔",
		"theme": "krusty_interior",
		"accent_color": Color("#FBBF24"),
		"bg_color": Color("#92400E"),
		"description": "Protect the dining tables, kitchen grill, and the Secret Formula vault safe!"
	},
	3: {
		"id": 3,
		"name": "Inside Squidward's Moai House",
		"arabic_name": "Inside Squidward's Moai House",
		"stage_range": [11, 15],
		"icon": "🗿",
		"theme": "squidward_interior",
		"accent_color": Color("#C084FC"),
		"bg_color": Color("#581C87"),
		"description": "Defend Squidward's private gallery, clarinet stage, and avant-garde art masterpieces."
	}
}

# Campaign Stages 1 to 15 Across 3 Zones
const STAGES = {
	1: {
		"id": 1,
		"zone_id": 1,
		"name": "Jellyfish Fields Trail",
		"arabic_name": "Jellyfish Fields Trail",
		"zone_name": "Bikini Bottom Outskirts",
		"waves": 5,
		"theme": "outskirts",
		"enemies": ["jellyfish_pink", "jellyfish_blue"],
		"boss": "jellyfish_blue",
		"gold_reward": 350,
		"gems_reward": 5,
		"description": "Pink and electric blue jellyfish swarm the outer road."
	},
	2: {
		"id": 2,
		"zone_id": 1,
		"name": "Plankton's Drone Recon",
		"arabic_name": "Plankton's Drone Recon",
		"zone_name": "Bikini Bottom Outskirts",
		"waves": 6,
		"theme": "outskirts",
		"enemies": ["jellyfish_pink", "robot_worker"],
		"boss": "robot_worker",
		"gold_reward": 450,
		"gems_reward": 6,
		"description": "Plankton sends scouting robot drones alongside jellyfish."
	},
	3: {
		"id": 3,
		"zone_id": 1,
		"name": "Chum Enforcer Patrol",
		"arabic_name": "Chum Enforcer Patrol",
		"zone_name": "Bikini Bottom Outskirts",
		"waves": 7,
		"theme": "outskirts",
		"enemies": ["jellyfish_blue", "robot_worker", "robot_enforcer"],
		"boss": "robot_enforcer",
		"gold_reward": 600,
		"gems_reward": 8,
		"description": "Armored chum enforcers march down the seaside promenade."
	},
	4: {
		"id": 4,
		"zone_id": 1,
		"name": "Robot Army Vanguard",
		"arabic_name": "Robot Army Vanguard",
		"zone_name": "Bikini Bottom Outskirts",
		"waves": 8,
		"theme": "outskirts",
		"enemies": ["robot_worker", "robot_enforcer", "jellyfish_blue"],
		"boss": "robot_enforcer",
		"gold_reward": 750,
		"gems_reward": 10,
		"description": "A dense legion of mechs marches relentlessly toward the town."
	},
	5: {
		"id": 5,
		"zone_id": 1,
		"name": "Mecha Plankton Showdown",
		"arabic_name": "Mecha Plankton Showdown",
		"zone_name": "Bikini Bottom Outskirts",
		"waves": 10,
		"theme": "outskirts",
		"enemies": ["jellyfish_pink", "jellyfish_blue", "robot_worker", "robot_enforcer", "mecha_plankton_boss"],
		"boss": "mecha_plankton_boss",
		"gold_reward": 1200,
		"gems_reward": 20,
		"description": "The colossal Mecha Plankton boss attacks the gates of Bikini Bottom!"
	},
	6: {
		"id": 6,
		"zone_id": 2,
		"name": "Dining Room Infiltration",
		"arabic_name": "Dining Room Infiltration",
		"zone_name": "Inside The Krusty Krab",
		"waves": 6,
		"theme": "krusty_interior",
		"enemies": ["patty_thief_anchovy"],
		"boss": "patty_thief_anchovy",
		"gold_reward": 800,
		"gems_reward": 12,
		"description": "Hungry anchovy swarms rush between the wooden dining tables!"
	},
	7: {
		"id": 7,
		"zone_id": 2,
		"name": "Rogue Kitchen Spatulas",
		"arabic_name": "Rogue Kitchen Spatulas",
		"zone_name": "Inside The Krusty Krab",
		"waves": 7,
		"theme": "krusty_interior",
		"enemies": ["patty_thief_anchovy", "robo_spatula"],
		"boss": "robo_spatula",
		"gold_reward": 950,
		"gems_reward": 15,
		"description": "Flying motorized spatulas hack the kitchen orders and dive-bomb the tables."
	},
	8: {
		"id": 8,
		"zone_id": 2,
		"name": "Grill Grease Gremlins",
		"arabic_name": "Grill Grease Gremlins",
		"zone_name": "Inside The Krusty Krab",
		"waves": 8,
		"theme": "krusty_interior",
		"enemies": ["robo_spatula", "grease_gremlin"],
		"boss": "grease_gremlin",
		"gold_reward": 1100,
		"gems_reward": 18,
		"description": "Sludge-covered grease gremlins ooze from the fryers with heavy armor."
	},
	9: {
		"id": 9,
		"zone_id": 2,
		"name": "Chum Spy Safe-Heist",
		"arabic_name": "Chum Spy Safe-Heist",
		"zone_name": "Inside The Krusty Krab",
		"waves": 9,
		"theme": "krusty_interior",
		"enemies": ["grease_gremlin", "chum_infiltrator", "robo_spatula"],
		"boss": "chum_infiltrator",
		"gold_reward": 1350,
		"gems_reward": 22,
		"description": "Disguised chum saboteurs attempt to crack open Mr. Krabs' office door."
	},
	10: {
		"id": 10,
		"zone_id": 2,
		"name": "Robo-Krabs Imposter Raid",
		"arabic_name": "Robo-Krabs Imposter Raid",
		"zone_name": "Inside The Krusty Krab",
		"waves": 10,
		"theme": "krusty_interior",
		"enemies": ["patty_thief_anchovy", "robo_spatula", "grease_gremlin", "chum_infiltrator", "robo_krabs_boss"],
		"boss": "robo_krabs_boss",
		"gold_reward": 2000,
		"gems_reward": 35,
		"description": "The giant mechanical Robo-Krabs marches straight for the Secret Formula safe!"
	},
	11: {
		"id": 11,
		"zone_id": 3,
		"name": "Avant-Garde Exhibition",
		"arabic_name": "Avant-Garde Exhibition",
		"zone_name": "Inside Squidward's Moai House",
		"waves": 7,
		"theme": "squidward_interior",
		"enemies": ["abstract_art_creep"],
		"boss": "abstract_art_creep",
		"gold_reward": 1400,
		"gems_reward": 25,
		"description": "Surrealist abstract geometric sculptures come to life inside the art salon."
	},
	12: {
		"id": 12,
		"zone_id": 3,
		"name": "Clarinet Dissonance",
		"arabic_name": "Clarinet Dissonance",
		"zone_name": "Inside Squidward's Moai House",
		"waves": 8,
		"theme": "squidward_interior",
		"enemies": ["abstract_art_creep", "dissonant_note_drone"],
		"boss": "dissonant_note_drone",
		"gold_reward": 1650,
		"gems_reward": 28,
		"description": "Floating musical shockwave drones blast screeching clarinet notes."
	},
	13: {
		"id": 13,
		"zone_id": 3,
		"name": "Robo-Clarinetist Recital",
		"arabic_name": "Robo-Clarinetist Recital",
		"zone_name": "Inside Squidward's Moai House",
		"waves": 9,
		"theme": "squidward_interior",
		"enemies": ["dissonant_note_drone", "robo_clarinetist"],
		"boss": "robo_clarinetist",
		"gold_reward": 1900,
		"gems_reward": 32,
		"description": "Rapid-firing mechanical clarinet bots overwhelm Squidward's gallery room."
	},
	14: {
		"id": 14,
		"zone_id": 3,
		"name": "Tentacle Mech Rampage",
		"arabic_name": "Tentacle Mech Rampage",
		"zone_name": "Inside Squidward's Moai House",
		"waves": 10,
		"theme": "squidward_interior",
		"enemies": ["robo_clarinetist", "tentacle_heavy_mech", "abstract_art_creep"],
		"boss": "tentacle_heavy_mech",
		"gold_reward": 2200,
		"gems_reward": 38,
		"description": "Heavy 6-legged stone tentacle mechs trample across the gallery's velvet rug."
	},
	15: {
		"id": 15,
		"zone_id": 3,
		"name": "The Art Critic Colossus",
		"arabic_name": "The Art Critic Colossus",
		"zone_name": "Inside Squidward's Moai House",
		"waves": 12,
		"theme": "squidward_interior",
		"enemies": ["abstract_art_creep", "dissonant_note_drone", "robo_clarinetist", "tentacle_heavy_mech", "squidward_critic_boss"],
		"boss": "squidward_critic_boss",
		"gold_reward": 3500,
		"gems_reward": 50,
		"description": "The towering Snobbish Art Critic Titan vows to demolish Squidward's masterpieces!"
	}
}

# Promo Codes
const PROMO_CODES = {
	"BIKINIBOTTOM": {"gold": 1500, "gems": 150, "rerolls": 5},
	"SECRETFORMULA": {"gold": 3000, "gems": 300, "rerolls": 10},
	"SPONGEBOB2026": {"gold": 5000, "gems": 500, "rerolls": 15},
	"KRUSTYKRAB": {"gold": 2500, "gems": 200, "rerolls": 8}
}

func get_towers_by_rarity(r: int) -> Array:
	var res = []
	for tid in TOWER_ORDER:
		var t = TOWERS.get(tid, {})
		if t.get("rarity", Rarity.COMMON) == r:
			res.append(tid)
	return res

func get_stage(stage_id: int) -> Dictionary:
	return STAGES.get(stage_id, STAGES.get(1, {}))

func get_zone(zone_id: int) -> Dictionary:
	return ZONES.get(zone_id, ZONES.get(1, {}))

