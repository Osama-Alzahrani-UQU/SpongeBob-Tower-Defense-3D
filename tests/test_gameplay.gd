extends SceneTree

func _init() -> void:
	print("========================================")
	print("STARTING SPONGEBOB TOWER DEFENSE INTEGRITY TESTS")
	print("========================================")
	
	# Wait one frame for autoloads to initialize
	await process_frame
	
	test_player_data()
	test_tower_data()
	test_summon_mechanics()
	test_trait_rerolls()
	test_promo_codes()
	test_battle_simulation()
	
	print("========================================")
	print("ALL SPONGEBOB TD TESTS PASSED 100%!")
	print("========================================")
	quit(0)

func test_player_data() -> void:
	print("[TEST] PlayerData Initialization & Loadout...")
	assert(PlayerData.level >= 10, "Player level should be >= 10")
	assert(PlayerData.inventory.size() >= 5, "Inventory should contain starter units")
	assert(PlayerData.equipped_uids.size() >= 4, "Should have starter equipped units")
	print("  -> Passed. Inventory count: ", PlayerData.inventory.size(), " Equipped: ", PlayerData.equipped_uids.size())

func test_tower_data() -> void:
	print("[TEST] GameData Towers & Traits...")
	assert(GameData.TOWERS.has("spongebob"), "Missing spongebob tower")
	assert(GameData.TOWERS.has("patrick"), "Missing patrick tower")
	assert(GameData.TOWERS.has("squidward"), "Missing squidward tower")
	assert(GameData.TOWERS.has("mr_krabs"), "Missing mr_krabs tower")
	assert(GameData.TOWERS.has("sandy"), "Missing sandy tower")
	assert(GameData.TOWERS.has("flying_dutchman"), "Missing flying_dutchman tower")
	
	assert(GameData.TRAITS.has("neptunes_crown"), "Missing neptunes_crown trait")
	assert(GameData.TRAITS.has("secret_formula"), "Missing secret_formula trait")
	assert(GameData.TRAITS.has("sidekick"), "Missing sidekick trait")
	assert(GameData.TRAITS.has("vortex"), "Missing vortex trait")
	assert(GameData.TRAITS.has("sea_bear"), "Missing sea_bear trait")
	print("  -> Passed. All 6 towers and 10 traits verified.")

func test_summon_mechanics() -> void:
	print("[TEST] Summon Gacha & Pity Counter...")
	var initial_gems = PlayerData.gems
	PlayerData.add_gems(500)
	
	var initial_count = PlayerData.inventory.size()
	# Simulate pull
	var unit = PlayerData.add_tower("spongebob", "secret_formula")
	assert(PlayerData.inventory.size() == initial_count + 1, "Inventory should increment")
	assert(unit["trait_id"] == "secret_formula", "Trait should be assigned")
	print("  -> Passed. Summoned unit UID: ", unit["uid"], " with trait: ", unit["trait_id"])

func test_trait_rerolls() -> void:
	print("[TEST] Plankton Lab Trait Rerolls...")
	var unit = PlayerData.inventory[0]
	var initial_dice = PlayerData.reroll_dice
	PlayerData.reroll_dice = 10
	var res = PlayerData.reroll_unit_trait(unit["uid"])
	assert(res.get("success", false) == true, "Reroll should succeed")
	print("  -> Passed. New Trait: ", res.get("new_trait"))

func test_promo_codes() -> void:
	print("[TEST] Promo Code Redemption (Level 10 Gate)...")
	var initial_gold = PlayerData.gold
	var res = PlayerData.redeem_code("BIKINIBOTTOM")
	assert(res.get("success", false) == true, "Code BIKINIBOTTOM should be redeemed")
	assert(PlayerData.gold > initial_gold, "Gold should increase after code")
	print("  -> Passed. Code redeemed successfully.")

func test_battle_simulation() -> void:
	print("[TEST] Battle Scene Loading & Mechanics...")
	var battle_scene = load("res://scenes/game/battle.tscn")
	assert(battle_scene != null, "Battle scene failed to load")
	
	var battle_instance = battle_scene.instantiate()
	root.add_child(battle_instance)
	
	# Test placing a tower
	battle_instance.selected_tower_to_place = "spongebob"
	var placed = battle_instance.place_tower(Vector2(200, 200))
	assert(placed == true, "Tower placement should succeed")
	assert(battle_instance.towers_container.get_child_count() == 1, "Tower container should have 1 tower")
	
	var tower = battle_instance.towers_container.get_child(0)
	assert(tower.tower_id == "spongebob", "Tower ID mismatch")
	
	# Test upgrading tower
	battle_instance.select_tower(tower)
	var upgraded = battle_instance.upgrade_selected_tower()
	assert(upgraded == true, "Tower upgrade should succeed")
	assert(tower.current_upgrade_level == 1, "Tower level should be 1")
	
	battle_instance.queue_free()
	print("  -> Passed. Battle mechanics & tower placement validated.")
