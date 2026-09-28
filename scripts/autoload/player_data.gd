extends Node

## PlayerData - Manages player progress, inventory, currencies, and persistent save data

signal currencies_changed()
signal inventory_changed()
signal loadout_changed()
signal level_up(new_level: int)

var level: int = 15 # Default level 15 so user can test Trading and Codes immediately
var xp: int = 0
var gold: int = 5000
var gems: int = 600
var reroll_dice: int = 12

var pity_counter: int = 0
const PITY_THRESHOLD: int = 50

# Inventory of owned tower instances (Capped at 50 max)
# Format: {"uid": int, "tower_id": String, "level": int, "trait_id": String, "xp": int, "is_locked": bool}
const MAX_INVENTORY_CAPACITY: int = 50
var inventory: Array = []
var next_uid: int = 1

# Auto-Sell Configuration for Summon Shop
var auto_sell_config: Dictionary = {
	"rarities": {
		GameData.Rarity.COMMON: false,
		GameData.Rarity.RARE: false,
		GameData.Rarity.EPIC: false
	},
	"towers": {}
}

# Equipped loadout: Array of tower_ids or uids (up to 5 slots)
var equipped_uids: Array = []

# Persistent list of discovered/unlocked character IDs for the Summon Shop Index
var unlocked_towers: Array = []

# Redeemed promo codes
var redeemed_codes: Array = []

# Volume & settings
var sfx_volume: float = 1.0
var music_volume: float = 0.8
var lag_reducer_enabled: bool = false

# Active Battle Mode ("campaign" or "infinity") & Infinity Records
var current_battle_mode: String = "campaign"
var selected_infinity_map: String = "outskirts"
var highest_infinity_wave: int = 0
var highest_infinity_kills: int = 0
var highest_infinity_waves_by_map: Dictionary = {
	"outskirts": 0,
	"krusty_interior": 0,
	"squidward_interior": 0
}

# Campaign Expedition Stages (Levels 1 to 15 across 3 Zones)
var selected_stage_id: int = 1
var highest_unlocked_stage: int = 1
var stage_stars: Dictionary = {}

# =========================================================
# GLOBAL CONTINUOUS AFK SYSTEM (Sandy's AFK Resort Engine)
# =========================================================
signal afk_rewards_updated(gold: int, gems: int, xp: int)

var afk_accumulated_gold: int = 0
var afk_accumulated_gems: int = 0
var afk_accumulated_xp: int = 0
var last_afk_timestamp: int = 0
var is_afk_boosted: bool = false
var afk_tick_timer: float = 0.0

const AFK_BASE_GOLD_PER_SEC: float = 4.0
const AFK_BASE_GEMS_PER_SEC: float = 0.25 # 1 Gem every 4 sec
const AFK_BASE_XP_PER_SEC: float = 2.0
const AFK_BOOST_MULTIPLIER: float = 2.5 # Treedome Zen Mode boost (10 gold/s, 0.625 gem/s, 5 xp/s)

const SAVE_PATH: String = "user://player_data.json"

func _ready() -> void:
	load_game()
	if inventory.size() < 5:
		_initialize_starter_inventory()
	_sync_unlocked_towers()

func _process(delta: float) -> void:
	afk_tick_timer += delta
	if afk_tick_timer >= 1.0:
		var mult: float = AFK_BOOST_MULTIPLIER if is_afk_boosted else 1.0
		var g_gain: int = int(round(AFK_BASE_GOLD_PER_SEC * mult * afk_tick_timer))
		var sec_tick: int = int(Time.get_ticks_msec() / 1000)
		var gem_interval: int = 2 if is_afk_boosted else 4
		var gem_gain: int = 1 if (sec_tick % gem_interval == 0) else 0
		var xp_gain: int = int(round(AFK_BASE_XP_PER_SEC * mult * afk_tick_timer))
		
		afk_accumulated_gold += g_gain
		afk_accumulated_gems += gem_gain
		afk_accumulated_xp += xp_gain
		afk_tick_timer = 0.0
		emit_signal("afk_rewards_updated", afk_accumulated_gold, afk_accumulated_gems, afk_accumulated_xp)

func claim_afk_rewards() -> Dictionary:
	var claimed := {
		"gold": afk_accumulated_gold,
		"gems": afk_accumulated_gems,
		"xp": afk_accumulated_xp
	}
	if claimed["gold"] > 0 or claimed["gems"] > 0 or claimed["xp"] > 0:
		add_gold(claimed["gold"])
		add_gems(claimed["gems"])
		add_xp(claimed["xp"])
		afk_accumulated_gold = 0
		afk_accumulated_gems = 0
		afk_accumulated_xp = 0
		last_afk_timestamp = int(Time.get_unix_time_from_system())
		save_game()
		emit_signal("afk_rewards_updated", 0, 0, 0)
	return claimed

func get_afk_status() -> Dictionary:
	var mult: float = AFK_BOOST_MULTIPLIER if is_afk_boosted else 1.0
	return {
		"gold": afk_accumulated_gold,
		"gems": afk_accumulated_gems,
		"xp": afk_accumulated_xp,
		"is_boosted": is_afk_boosted,
		"gold_per_min": int(AFK_BASE_GOLD_PER_SEC * mult * 60.0),
		"gems_per_min": int(AFK_BASE_GEMS_PER_SEC * mult * 60.0),
		"xp_per_min": int(AFK_BASE_XP_PER_SEC * mult * 60.0)
	}

func _sync_unlocked_towers() -> void:
	var changed := false
	for u in inventory:
		var tid: String = str(u.get("tower_id", ""))
		if tid != "" and tid not in unlocked_towers:
			unlocked_towers.append(tid)
			changed = true
		if tid == "flying_dutchman" and str(u.get("trait_id", "none")) == "none":
			u["trait_id"] = "neptunes_crown"
			changed = true
	if changed:
		save_game()

func is_tower_unlocked(tower_id: String) -> bool:
	if tower_id in unlocked_towers:
		return true
	for u in inventory:
		if u.get("tower_id", "") == tower_id:
			return true
	return false

func get_owned_count(tower_id: String) -> int:
	var c := 0
	for u in inventory:
		if u.get("tower_id", "") == tower_id:
			c += 1
	return c

func get_highest_level_for_tower(tower_id: String) -> int:
	var best := 1
	for u in inventory:
		if u.get("tower_id", "") == tower_id:
			best = maxi(best, int(u.get("level", 1)))
	return best

func get_unlocked_count() -> int:
	var c := 0
	for tid in GameData.TOWER_ORDER:
		if is_tower_unlocked(tid):
			c += 1
	return c

func _initialize_starter_inventory() -> void:
	var existing_ids = []
	for u in inventory:
		existing_ids.append(u["tower_id"])
	for starter in [
		{"id": "spongebob", "trait": "surge_3"},
		{"id": "patrick", "trait": "strike_3"},
		{"id": "squidward", "trait": "reach_3"},
		{"id": "mr_krabs", "trait": "wealth"},
		{"id": "sandy", "trait": "vortex"},
		{"id": "spongebob", "trait": "none"},
		{"id": "patrick", "trait": "none"}
	]:
		if inventory.size() < 7:
			add_tower(starter["id"], starter["trait"])
	
	if equipped_uids.is_empty():
		for i in range(mini(4, inventory.size())):
			equipped_uids.append(inventory[i]["uid"])
	emit_signal("loadout_changed")
	save_game()

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	emit_signal("currencies_changed")
	save_game()

func add_gems(amount: int) -> void:
	gems = maxi(0, gems + amount)
	emit_signal("currencies_changed")
	save_game()

func add_rerolls(amount: int) -> void:
	reroll_dice = maxi(0, reroll_dice + amount)
	emit_signal("currencies_changed")
	save_game()

func add_xp(amount: int) -> void:
	xp += amount
	var needed = get_xp_for_next_level()
	while xp >= needed:
		xp -= needed
		level += 1
		emit_signal("level_up", level)
		needed = get_xp_for_next_level()
	save_game()

func get_xp_for_next_level() -> int:
	return level * 350

func is_inventory_full() -> bool:
	return inventory.size() >= MAX_INVENTORY_CAPACITY

func get_inventory_capacity() -> int:
	return MAX_INVENTORY_CAPACITY

func get_inventory_count() -> int:
	return inventory.size()

func get_inventory_remaining_space() -> int:
	return maxi(0, MAX_INVENTORY_CAPACITY - inventory.size())

func toggle_unit_lock(uid: int) -> bool:
	var unit = get_tower_by_uid(int(uid))
	if unit.is_empty():
		return false
	var new_state: bool = not bool(unit.get("is_locked", false))
	unit["is_locked"] = new_state
	emit_signal("inventory_changed")
	save_game()
	return new_state

func is_unit_locked(uid: int) -> bool:
	var unit = get_tower_by_uid(int(uid))
	return bool(unit.get("is_locked", false)) if not unit.is_empty() else false

func set_unit_lock(uid: int, locked: bool) -> bool:
	var unit = get_tower_by_uid(int(uid))
	if unit.is_empty():
		return false
	unit["is_locked"] = locked
	emit_signal("inventory_changed")
	save_game()
	return locked

func is_tower_auto_sold(tower_id: String) -> bool:
	var t_data = GameData.TOWERS.get(tower_id, {})
	var r_enum: int = t_data.get("rarity", GameData.Rarity.COMMON)
	var rarities_cfg: Dictionary = auto_sell_config.get("rarities", {})
	var r_sold: bool = false
	if rarities_cfg.has(r_enum):
		r_sold = bool(rarities_cfg[r_enum])
	elif rarities_cfg.has(str(r_enum)):
		r_sold = bool(rarities_cfg[str(r_enum)])
	if r_sold:
		return true
	var towers_cfg: Dictionary = auto_sell_config.get("towers", {})
	if bool(towers_cfg.get(tower_id, false)):
		return true
	return false

func set_auto_sell_rarity(r_enum: int, enabled: bool) -> void:
	if not auto_sell_config.has("rarities"):
		auto_sell_config["rarities"] = {}
	auto_sell_config["rarities"][r_enum] = enabled
	auto_sell_config["rarities"][str(r_enum)] = enabled
	save_game()

func set_auto_sell_tower(tower_id: String, enabled: bool) -> void:
	if not auto_sell_config.has("towers"):
		auto_sell_config["towers"] = {}
	auto_sell_config["towers"][tower_id] = enabled
	save_game()

func get_tower_sell_value(tower_id: String, lvl: int = 1) -> Dictionary:
	var t_data = GameData.TOWERS.get(tower_id, {})
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var base_gold := 150
	var base_gems := 15
	match r_enum:
		GameData.Rarity.RARE:
			base_gold = 300
			base_gems = 30
		GameData.Rarity.EPIC:
			base_gold = 600
			base_gems = 60
		GameData.Rarity.LEGENDARY:
			base_gold = 1000
			base_gems = 100
		GameData.Rarity.MYTHIC, GameData.Rarity.SECRET:
			base_gold = 1800
			base_gems = 160
	return {
		"gold": base_gold + (lvl - 1) * 75,
		"gems": base_gems + (lvl - 1) * 8
	}

func add_tower(tower_id: String, trait_id: String = "none", bypass_limit: bool = false) -> Dictionary:
	if not bypass_limit and inventory.size() >= MAX_INVENTORY_CAPACITY:
		return {}
	var unit = {
		"uid": next_uid,
		"tower_id": tower_id,
		"level": 1,
		"trait_id": trait_id,
		"xp": 0,
		"is_locked": false
	}
	next_uid += 1
	inventory.append(unit)
	if tower_id not in unlocked_towers:
		unlocked_towers.append(tower_id)
	emit_signal("inventory_changed")
	save_game()
	return unit

func get_tower_by_uid(uid: int) -> Dictionary:
	var target_int := int(uid)
	for item in inventory:
		if int(item.get("uid", -1)) == target_int:
			return item
	return {}

func cleanup_equipped_uids() -> void:
	var valid_uids: Array[int] = []
	for u in inventory:
		valid_uids.append(int(u.get("uid", -1)))
	var cleaned: Array[int] = []
	for eq_uid in equipped_uids:
		var eq_int := int(eq_uid)
		if eq_int in valid_uids and eq_int not in cleaned:
			cleaned.append(eq_int)
	if cleaned.size() != equipped_uids.size():
		equipped_uids = cleaned
		emit_signal("loadout_changed")
		save_game()

func equip_tower(uid: int) -> bool:
	cleanup_equipped_uids()
	var target_int := int(uid)
	if is_equipped(target_int):
		return false
	if equipped_uids.size() >= 5:
		return false
	var unit = get_tower_by_uid(target_int)
	if unit.is_empty():
		return false
	equipped_uids.append(target_int)
	emit_signal("loadout_changed")
	save_game()
	return true

func unequip_tower(uid: int) -> bool:
	var target_int := int(uid)
	var found := false
	var new_eq: Array[int] = []
	for eq in equipped_uids:
		if int(eq) == target_int:
			found = true
		else:
			new_eq.append(int(eq))
	if found:
		equipped_uids = new_eq
		emit_signal("loadout_changed")
		save_game()
		return true
	return false

func is_equipped(uid: int) -> bool:
	var target_int := int(uid)
	for eq in equipped_uids:
		if int(eq) == target_int:
			return true
	return false

func get_equipped_towers() -> Array:
	cleanup_equipped_uids()
	var result = []
	for uid in equipped_uids:
		var t = get_tower_by_uid(int(uid))
		if not t.is_empty():
			result.append(t)
	return result

func reroll_unit_trait(uid: int) -> Dictionary:
	if reroll_dice <= 0:
		return {"success": false, "message": "No trait dice remaining!"}
	
	var unit = get_tower_by_uid(uid)
	if unit.is_empty():
		return {"success": false, "message": "Unit not found."}
	
	reroll_dice -= 1
	emit_signal("currencies_changed")
	
	var old_trait: String = str(unit.get("trait_id", "none"))
	var new_trait_id := "surge_3"
	for _attempt in range(5):
		var rand_val = randf()
		if rand_val <= 0.005:
			new_trait_id = "neptunes_crown"
		elif rand_val <= 0.020:
			new_trait_id = "secret_formula"
		elif rand_val <= 0.060:
			new_trait_id = "sidekick"
		elif rand_val <= 0.130:
			new_trait_id = "vortex"
		elif rand_val <= 0.230:
			new_trait_id = "sea_bear"
		elif rand_val <= 0.350:
			new_trait_id = "wealth"
		elif rand_val <= 0.510:
			new_trait_id = "surge_3"
		elif rand_val <= 0.680:
			new_trait_id = "reach_3"
		elif rand_val <= 0.880:
			new_trait_id = "strike_3"
		else:
			new_trait_id = "scurvy"
		if new_trait_id != old_trait:
			break
		
	unit["trait_id"] = new_trait_id
	emit_signal("inventory_changed")
	save_game()
	
	return {
		"success": true,
		"new_trait": new_trait_id,
		"trait_data": GameData.TRAITS[new_trait_id]
	}

func feed_unit(target_uid: int, sacrifice_uids: Array) -> Dictionary:
	var target = get_tower_by_uid(int(target_uid))
	if target.is_empty() or sacrifice_uids.is_empty():
		return {"success": false, "message": "Invalid target or sacrifice list"}
		
	var total_xp_gain = 0
	var sacrificed_count = 0
	for s_uid in sacrifice_uids:
		var s_int := int(s_uid)
		if s_int == int(target_uid):
			continue
		if is_unit_locked(s_int):
			continue # Protect locked units from being sacrificed!
		var s_unit = get_tower_by_uid(s_int)
		if not s_unit.is_empty():
			total_xp_gain += int(s_unit.get("level", 1)) * 120
			sacrificed_count += 1
			# If sacrificed unit was in hotbar loadout, unequip it immediately so its slot is freed!
			if is_equipped(s_int):
				unequip_tower(s_int)
			inventory.erase(s_unit)
			
	if sacrificed_count == 0 and not sacrifice_uids.is_empty():
		return {"success": false, "message": "🔒 Cannot sacrifice locked units! Unlock them first."}
			
	target["xp"] = int(target.get("xp", 0)) + total_xp_gain
	var max_lvl = 50
	while target["xp"] >= target["level"] * 200 and target["level"] < max_lvl:
		target["xp"] -= target["level"] * 200
		target["level"] += 1
		
	cleanup_equipped_uids()
	emit_signal("inventory_changed")
	save_game()
	return {"success": true, "new_level": target["level"], "xp_gained": total_xp_gain}

func get_unit_sell_reward(uid: int) -> Dictionary:
	var unit = get_tower_by_uid(int(uid))
	if unit.is_empty():
		return {"gold": 0, "gems": 0}
	var t_data = GameData.TOWERS.get(unit["tower_id"], {})
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var base_gold := 150
	var base_gems := 15
	match r_enum:
		GameData.Rarity.RARE:
			base_gold = 300
			base_gems = 30
		GameData.Rarity.EPIC:
			base_gold = 600
			base_gems = 60
		GameData.Rarity.LEGENDARY:
			base_gold = 1000
			base_gems = 100
		GameData.Rarity.MYTHIC, GameData.Rarity.SECRET:
			base_gold = 1800
			base_gems = 160
	var lvl = maxi(1, int(unit.get("level", 1)))
	return {
		"gold": base_gold + (lvl - 1) * 75,
		"gems": base_gems + (lvl - 1) * 8
	}

func sell_unit(uid: int) -> Dictionary:
	if inventory.size() <= 1:
		return {"success": false, "message": "Cannot sell your last remaining unit!"}
	var s_int := int(uid)
	if is_unit_locked(s_int):
		return {"success": false, "message": "🔒 This unit is LOCKED! Unlock it before selling."}
	var unit = get_tower_by_uid(s_int)
	if unit.is_empty():
		return {"success": false, "message": "Unit not found."}
	var reward = get_unit_sell_reward(s_int)
	if is_equipped(s_int):
		unequip_tower(s_int)
	inventory.erase(unit)
	cleanup_equipped_uids()
	gold += reward["gold"]
	gems += reward["gems"]
	emit_signal("currencies_changed")
	emit_signal("inventory_changed")
	save_game()
	return {"success": true, "gold": reward["gold"], "gems": reward["gems"]}

func redeem_code(code_str: String) -> Dictionary:
	var clean_code = code_str.strip_edges().to_upper()
	if level < 10:
		return {"success": false, "message": "Level 10 required to redeem codes!"}
	if clean_code in redeemed_codes:
		return {"success": false, "message": "Code already redeemed!"}
	if not GameData.PROMO_CODES.has(clean_code):
		return {"success": false, "message": "Invalid promo code."}
		
	var reward = GameData.PROMO_CODES[clean_code]
	add_gold(reward.get("gold", 0))
	add_gems(reward.get("gems", 0))
	add_rerolls(reward.get("rerolls", 0))
	redeemed_codes.append(clean_code)
	save_game()
	return {"success": true, "reward": reward}

func save_game() -> void:
	last_afk_timestamp = int(Time.get_unix_time_from_system())
	var data = {
		"level": level,
		"xp": xp,
		"gold": gold,
		"gems": gems,
		"reroll_dice": reroll_dice,
		"pity_counter": pity_counter,
		"next_uid": next_uid,
		"inventory": inventory,
		"equipped_uids": equipped_uids,
		"unlocked_towers": unlocked_towers,
		"redeemed_codes": redeemed_codes,
		"lag_reducer_enabled": lag_reducer_enabled,
		"highest_infinity_wave": highest_infinity_wave,
		"highest_infinity_kills": highest_infinity_kills,
		"selected_infinity_map": selected_infinity_map,
		"highest_infinity_waves_by_map": highest_infinity_waves_by_map,
		"selected_stage_id": selected_stage_id,
		"highest_unlocked_stage": highest_unlocked_stage,
		"stage_stars": stage_stars,
		"afk_accumulated_gold": afk_accumulated_gold,
		"afk_accumulated_gems": afk_accumulated_gems,
		"afk_accumulated_xp": afk_accumulated_xp,
		"last_afk_timestamp": last_afk_timestamp,
		"auto_sell_config": auto_sell_config
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var res = json.parse(text)
		if res == OK and json.data is Dictionary:
			var d = json.data
			level = d.get("level", 15)
			xp = d.get("xp", 0)
			gold = d.get("gold", 5000)
			gems = maxi(900, int(d.get("gems", 1200)))
			reroll_dice = d.get("reroll_dice", 12)
			pity_counter = d.get("pity_counter", 0)
			next_uid = int(d.get("next_uid", 1))
			
			var raw_cfg = d.get("auto_sell_config", {})
			if raw_cfg is Dictionary:
				auto_sell_config["towers"] = raw_cfg.get("towers", {})
				var raw_rar = raw_cfg.get("rarities", {})
				if raw_rar is Dictionary:
					auto_sell_config["rarities"].clear()
					for r_k in raw_rar.keys():
						var r_val: bool = bool(raw_rar[r_k])
						auto_sell_config["rarities"][int(r_k)] = r_val
						auto_sell_config["rarities"][str(r_k)] = r_val
			
			inventory.clear()
			for u in d.get("inventory", []):
				if u is Dictionary:
					u["uid"] = int(u.get("uid", 0))
					u["level"] = int(u.get("level", 1))
					u["xp"] = int(u.get("xp", 0))
					u["is_locked"] = bool(u.get("is_locked", false))
					inventory.append(u)
					
			equipped_uids.clear()
			for eq in d.get("equipped_uids", []):
				equipped_uids.append(int(eq))
				
			unlocked_towers = d.get("unlocked_towers", [])
			redeemed_codes = d.get("redeemed_codes", [])
			lag_reducer_enabled = d.get("lag_reducer_enabled", false)
			highest_infinity_wave = int(d.get("highest_infinity_wave", 0))
			highest_infinity_kills = int(d.get("highest_infinity_kills", 0))
			selected_infinity_map = str(d.get("selected_infinity_map", "outskirts"))
			var inf_by_map = d.get("highest_infinity_waves_by_map", {})
			if inf_by_map is Dictionary:
				for k in ["outskirts", "krusty_interior", "squidward_interior"]:
					highest_infinity_waves_by_map[k] = int(inf_by_map.get(k, 0))
			selected_stage_id = int(d.get("selected_stage_id", 1))
			stage_stars = d.get("stage_stars", {})
			var max_star_stage := 1
			for s in range(1, 16):
				if get_stage_stars(s) >= 1:
					max_star_stage = maxi(max_star_stage, s + 1)
			highest_unlocked_stage = mini(15, max_star_stage)
			cleanup_equipped_uids()
			
			afk_accumulated_gold = int(d.get("afk_accumulated_gold", 0))
			afk_accumulated_gems = int(d.get("afk_accumulated_gems", 0))
			afk_accumulated_xp = int(d.get("afk_accumulated_xp", 0))
			last_afk_timestamp = int(d.get("last_afk_timestamp", 0))
			
			var now: int = int(Time.get_unix_time_from_system())
			if last_afk_timestamp > 0 and now > last_afk_timestamp:
				var elapsed_sec: int = clampi(now - last_afk_timestamp, 0, 86400 * 3) # Cap at 72h offline
				if elapsed_sec >= 10:
					afk_accumulated_gold += int(elapsed_sec * AFK_BASE_GOLD_PER_SEC)
					afk_accumulated_gems += int(elapsed_sec * AFK_BASE_GEMS_PER_SEC)
					afk_accumulated_xp += int(elapsed_sec * AFK_BASE_XP_PER_SEC)
			last_afk_timestamp = now

func record_stage_clear(stage_id: int, stars: int) -> void:
	var s_key := str(stage_id)
	var prev_stars: int = int(stage_stars.get(s_key, 0))
	stage_stars[s_key] = maxi(prev_stars, stars)
	if stars >= 1:
		highest_unlocked_stage = maxi(highest_unlocked_stage, stage_id + 1)
	save_game()

func get_stage_stars(stage_id: int) -> int:
	return int(stage_stars.get(str(stage_id), 0))

func get_calculated_highest_unlocked_stage() -> int:
	var h: int = 1
	for s in range(1, 16):
		if get_stage_stars(s) >= 1:
			h = maxi(h, s + 1)
		else:
			break
	return mini(15, h)

func is_stage_unlocked(stage_id: int) -> bool:
	if stage_id <= 1:
		return true
	return get_stage_stars(stage_id - 1) >= 1

func is_zone_unlocked(zone_id: int) -> bool:
	if zone_id <= 1:
		return true
	elif zone_id == 2:
		return get_stage_stars(5) >= 1
	elif zone_id == 3:
		return get_stage_stars(10) >= 1
	return false
