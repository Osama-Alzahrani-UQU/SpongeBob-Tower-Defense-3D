extends Area3D

## TowerBase 3D - Tactical 3D unit script with Economy Cash Fountains and Signature Power Class Mechanics

signal tower_selected(tower)
signal tower_upgraded(tower)

var tower_id: String = "spongebob"
var unit_level: int = 1
var trait_id: String = "none"
var power_class: String = "control"

var current_upgrade_level: int = 0
var targeting_mode: String = "First" # "First", "Last", "Strongest", "Closest"

var current_damage: float = 18.0
var current_spa: float = 1.2
var current_range: float = 8.0
var current_income: int = 0
var total_cash_generated: int = 0
var total_spent: int = 0
var total_damage_dealt: float = 0.0

var attack_cooldown: float = 0.0
var attack_count: int = 0
var enemies_in_range: Array = []
var current_target: Node3D = null

# Marksman Focus Combo
var combo_target: Node3D = null
var combo_stacks: int = 0

var is_selected: bool = false

# Articulated 3D Model Pivots & Animation Controls
var body_pivot: Node3D = null
var left_arm_pivot: Node3D = null
var right_arm_pivot: Node3D = null
var base_body_pos: Vector3 = Vector3.ZERO
var base_body_rot: Vector3 = Vector3.ZERO
var base_body_scale: Vector3 = Vector3.ONE
var base_left_rot: Vector3 = Vector3.ZERO
var base_right_rot: Vector3 = Vector3.ZERO

var idle_anim_time: float = 0.0
var is_playing_attack_anim: bool = false
var active_attack_tween: Tween = null

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var range_shape: SphereShape3D = null
var visual_root: Node3D = null
var range_dome: Node3D = null
var name_label_3d: Label3D = null

const RangeDome3DScript = preload("res://scripts/towers/range_dome_3d.gd")
var projectile_scene = preload("res://scenes/towers/projectile.tscn")

func _ready() -> void:
	range_shape = SphereShape3D.new()
	range_shape.radius = current_range
	collision_shape.shape = range_shape
	
	area_entered.connect(_on_enemy_entered)
	area_exited.connect(_on_enemy_exited)
	
	_create_range_ring()
	recalculate_stats()

func setup(p_id: String, p_level: int = 1, p_trait: String = "none") -> void:
	tower_id = p_id
	unit_level = p_level
	trait_id = p_trait
	
	var data = GameData.TOWERS.get(tower_id, {})
	power_class = data.get("power_class", "control")
	total_spent = data.get("cost", 100)
	
	_load_visuals()
	recalculate_stats()
	if range_dome:
		range_dome.setup(current_range, tower_id, trait_id)

func _load_visuals() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	visual_root = ModelBuilder3D.build_tower_model(tower_id)
	add_child(visual_root)
	
	# Cache animation pivots and base poses
	body_pivot = visual_root.find_child("BodyPivot", true, false)
	left_arm_pivot = visual_root.find_child("LeftArmPivot", true, false)
	right_arm_pivot = visual_root.find_child("RightArmPivot", true, false)
	
	if body_pivot:
		base_body_pos = body_pivot.position
		base_body_rot = body_pivot.rotation
		base_body_scale = body_pivot.scale
	elif visual_root:
		base_body_pos = Vector3.ZERO
		base_body_rot = Vector3.ZERO
		base_body_scale = Vector3.ONE
		
	if left_arm_pivot:
		base_left_rot = left_arm_pivot.rotation
	if right_arm_pivot:
		base_right_rot = right_arm_pivot.rotation
	
	if not name_label_3d:
		name_label_3d = Label3D.new()
		name_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label_3d.no_depth_test = true
		name_label_3d.render_priority = 20
		name_label_3d.pixel_size = 0.009
		name_label_3d.font_size = 40
		name_label_3d.outline_size = 14
		name_label_3d.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
		var custom_font = UIThemeBuilder.get_title_font()
		if custom_font:
			name_label_3d.font = custom_font
		name_label_3d.position = Vector3(0, 2.7, 0)
		add_child(name_label_3d)
	var data = GameData.TOWERS.get(tower_id, {})
	if power_class == "economy":
		name_label_3d.text = "%s [Lv.%d] 💰" % [data.get("name", tower_id), current_upgrade_level + 1]
	else:
		name_label_3d.text = "%s [Lv.%d]" % [data.get("name", tower_id), current_upgrade_level + 1]

func _create_range_ring() -> void:
	if range_dome and is_instance_valid(range_dome):
		range_dome.queue_free()
	range_dome = RangeDome3DScript.new()
	range_dome.name = "TacticalRangeDome"
	add_child(range_dome)
	range_dome.setup(current_range, tower_id, trait_id)

func set_selected_visual(sel: bool) -> void:
	is_selected = sel
	if range_dome:
		if is_selected:
			range_dome.animate_show(false)
		else:
			range_dome.animate_hide(false)

func recalculate_stats() -> void:
	var data = GameData.TOWERS.get(tower_id, {})
	power_class = data.get("power_class", "control")
	var trait_data = GameData.TRAITS.get(trait_id, GameData.TRAITS["none"])
	
	var base_dmg = data.get("base_damage", 10.0)
	var base_spa = data.get("base_spa", 1.5)
	var base_rng = data.get("base_range", 8.0)
	var base_inc = data.get("income_per_wave", 0)
	
	var lvl_mult = 1.0 + (unit_level - 1) * 0.05
	base_dmg *= lvl_mult
	
	var add_dmg = 0.0
	var add_rng = 0.0
	var add_inc = 0
	var mult_spa = 1.0
	var upgrades = data.get("upgrades", [])
	
	for i in range(mini(current_upgrade_level, upgrades.size())):
		var up = upgrades[i]
		add_dmg += up.get("damage_add", 0.0)
		add_rng += up.get("range_add", 0.0)
		add_inc += up.get("income_add", 0)
		mult_spa *= up.get("spa_mult", 1.0)
		
	var trait_dmg_mult = trait_data.get("damage_mult", 1.0)
	var trait_spa_mult = trait_data.get("spa_mult", 1.0)
	var trait_rng_mult = trait_data.get("range_mult", 1.0)
	var trait_inc_mult = trait_data.get("income_mult", 1.0)
	
	if power_class == "economy":
		current_damage = 0.0 # Dedicated economy engine - zero attack damage
		current_income = int((base_inc + add_inc) * lvl_mult * trait_inc_mult)
	else:
		current_damage = (base_dmg + add_dmg) * trait_dmg_mult
		current_income = 0
		
	current_spa = maxf(0.15, (base_spa * mult_spa) * trait_spa_mult)
	current_range = (base_rng + add_rng) * trait_rng_mult
	
	if range_shape:
		range_shape.radius = current_range
	if range_dome:
		range_dome.set_radius(current_range, is_selected)
	if name_label_3d:
		if power_class == "economy":
			name_label_3d.text = "%s [Upg.%d] 💰" % [data.get("name", tower_id), current_upgrade_level]
		else:
			name_label_3d.text = "%s [Upg.%d]" % [data.get("name", tower_id), current_upgrade_level]

func _process(delta: float) -> void:
	# Update active idle animation (breathing, belly wobble, gentle arm sways)
	_update_idle_animation(delta)

	# Economy Class: Dedicated cash engine, does NOT target or fire at enemies
	if power_class == "economy":
		if visual_root:
			visual_root.rotation.y += delta * 0.6
		return
		
	attack_cooldown -= delta
	
	_clean_enemy_list()
	current_target = _find_target()
	
	if current_target and is_instance_valid(current_target) and visual_root:
		var look_pos = current_target.global_position
		look_pos.y = global_position.y
		if global_position.distance_to(look_pos) > 0.1:
			visual_root.look_at(look_pos, Vector3.UP)
			visual_root.rotate_y(PI) # Align +Z (character's front face) directly with enemy
	
	if current_target and attack_cooldown <= 0.0:
		_execute_attack()
		attack_cooldown = current_spa

func _clean_enemy_list() -> void:
	var valid = []
	for e in enemies_in_range:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			valid.append(e)
	enemies_in_range = valid

func _find_target() -> Node3D:
	if power_class == "economy" or enemies_in_range.is_empty():
		return null
		
	var best_target: Node3D = null
	
	match targeting_mode:
		"First":
			var max_progress = -1.0
			for e in enemies_in_range:
				var prog = e.get_path_progress()
				if prog > max_progress:
					max_progress = prog
					best_target = e
		"Last":
			var min_progress = 9999999.0
			for e in enemies_in_range:
				var prog = e.get_path_progress()
				if prog < min_progress:
					min_progress = prog
					best_target = e
		"Strongest":
			var max_hp = -1.0
			for e in enemies_in_range:
				if e.current_hp > max_hp:
					max_hp = e.current_hp
					best_target = e
		"Closest":
			var min_dist = 999999.0
			for e in enemies_in_range:
				var dist = global_position.distance_to(e.global_position)
				if dist < min_dist:
					min_dist = dist
					best_target = e
					
	return best_target

func _execute_attack() -> void:
	if power_class == "economy" or not is_instance_valid(current_target):
		return
		
	attack_count += 1
	var proj = projectile_scene.instantiate()
	var container = get_parent().get_parent() if (get_parent() and get_parent().get_parent()) else get_parent()
	container.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0)
	
	var t_data = GameData.TOWERS.get(tower_id, {})
	var t_type = t_data.get("type", "single_target")
	var is_aoe = (t_type in ["aoe", "hybrid_annihilator"]) or (power_class in ["aoe", "spectral", "cosmic"]) or (tower_id == "spongebob" and current_upgrade_level >= 3)
	var slow_amt = 0.45 if (t_type == "crowd_control" or power_class == "control" or tower_id == "dirty_bubble") else 0.0
	var proj_type = "bubble"
	
	# Class signature perks
	var is_crit = false
	var is_freeze = false
	var final_atk_damage = current_damage
	
	match power_class:
		"brawler":
			is_crit = (randf() < 0.25)
			if is_crit:
				final_atk_damage *= 2.5
			proj_type = "boulder"
		"control":
			is_freeze = (attack_count % 4 == 0)
			proj_type = "freeze_bubble" if is_freeze else "bubble"
		"marksman":
			if current_target == combo_target:
				combo_stacks = mini(5, combo_stacks + 1)
			else:
				combo_target = current_target
				combo_stacks = 1
			final_atk_damage *= (1.0 + combo_stacks * 0.10)
			proj_type = "laser"
		"aoe":
			proj_type = "sonic_note"
		"spectral":
			proj_type = "soul_wisp"
		"cosmic":
			proj_type = "divine_ray"
	
	proj.setup(current_target, final_atk_damage, proj_type, slow_amt, is_aoe, 4.2 if power_class == "aoe" else 3.8, power_class, is_crit, is_freeze)
	total_damage_dealt += final_atk_damage
	
	if AudioManager:
		match proj_type:
			"boulder":
				AudioManager.play_sfx("boulder_throw")
			"sonic_note":
				AudioManager.play_sfx("clarinet_blast")
			"laser", "divine_ray":
				AudioManager.play_sfx("plankton_laser")
			"bubble", "freeze_bubble":
				AudioManager.play_sfx("bubble_shoot")
			_:
				if tower_id == "sandy":
					AudioManager.play_sfx("karate_chop")
				elif tower_id == "gary":
					AudioManager.play_sfx("meow")
				else:
					AudioManager.play_sfx("bubble_shoot")
	
	# High-energy attack animation on 3D character and pivots
	_play_attack_animation()

func _update_idle_animation(delta: float) -> void:
	if is_playing_attack_anim:
		return
	idle_anim_time += delta
	
	if body_pivot and is_instance_valid(body_pivot):
		# Breathing squash-stretch & gentle potbelly wobble
		var breath = sin(idle_anim_time * 2.8)
		var sway = sin(idle_anim_time * 1.6)
		body_pivot.scale = base_body_scale * Vector3(1.0 - breath * 0.025, 1.0 + breath * 0.035, 1.0 - breath * 0.025)
		body_pivot.position.y = base_body_pos.y + breath * 0.02
		body_pivot.rotation.z = base_body_rot.z + sway * 0.035
		body_pivot.rotation.x = base_body_rot.x + cos(idle_anim_time * 2.0) * 0.02
	elif visual_root and is_instance_valid(visual_root) and power_class != "economy":
		# General idle squash & stretch for any unit without a BodyPivot
		var breath = sin(idle_anim_time * 2.5)
		visual_root.scale = Vector3(1.0 - breath * 0.02, 1.0 + breath * 0.025, 1.0 - breath * 0.02)
		
	# Subtle arm idle sways
	if left_arm_pivot and is_instance_valid(left_arm_pivot):
		var arm_sway_l = sin(idle_anim_time * 2.4)
		left_arm_pivot.rotation = base_left_rot + Vector3(arm_sway_l * 0.08, 0.0, arm_sway_l * 0.04)
		
	if right_arm_pivot and is_instance_valid(right_arm_pivot):
		var arm_sway_r = -sin(idle_anim_time * 2.4)
		right_arm_pivot.rotation = base_right_rot + Vector3(arm_sway_r * 0.08, 0.0, arm_sway_r * 0.04)

func _play_attack_animation() -> void:
	if active_attack_tween and is_instance_valid(active_attack_tween):
		active_attack_tween.kill()
		
	is_playing_attack_anim = true
	active_attack_tween = create_tween()
	active_attack_tween.set_parallel(true)
	
	if body_pivot and is_instance_valid(body_pivot):
		# Phase 1: Windup / Inhale (0.08s) - arches backward slightly
		active_attack_tween.tween_property(body_pivot, "rotation:x", base_body_rot.x - 0.25, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		active_attack_tween.tween_property(body_pivot, "scale", base_body_scale * Vector3(1.08, 1.15, 0.95), 0.08)
		
		# Phase 2: Forward Attack Slam (0.09s) - powerful slam forward
		active_attack_tween.chain().tween_property(body_pivot, "rotation:x", base_body_rot.x + 0.38, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		active_attack_tween.tween_property(body_pivot, "scale", base_body_scale * Vector3(1.15, 0.85, 1.12), 0.09)
		active_attack_tween.tween_property(body_pivot, "position:z", base_body_pos.z + 0.14, 0.09)
		
		# Phase 3: Recovery / Spring back to base pose (0.18s)
		active_attack_tween.chain().tween_property(body_pivot, "rotation:x", base_body_rot.x, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		active_attack_tween.tween_property(body_pivot, "scale", base_body_scale, 0.18)
		active_attack_tween.tween_property(body_pivot, "position:z", base_body_pos.z, 0.18)
	elif visual_root and is_instance_valid(visual_root):
		# Fallback scale bounce for root
		active_attack_tween.tween_property(visual_root, "scale", Vector3(1.22, 1.28, 1.22), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		active_attack_tween.chain().tween_property(visual_root, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Arm attack motions: Wind up high then slam down!
	if right_arm_pivot and is_instance_valid(right_arm_pivot):
		# Windup
		active_attack_tween.tween_property(right_arm_pivot, "rotation:x", base_right_rot.x - 1.2, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Powerful karate slam forward
		active_attack_tween.chain().tween_property(right_arm_pivot, "rotation:x", base_right_rot.x + 0.95, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		# Return to base
		active_attack_tween.chain().tween_property(right_arm_pivot, "rotation:x", base_right_rot.x, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	if left_arm_pivot and is_instance_valid(left_arm_pivot):
		# Counter-balance raise and thrust
		active_attack_tween.tween_property(left_arm_pivot, "rotation:x", base_left_rot.x - 0.6, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		active_attack_tween.chain().tween_property(left_arm_pivot, "rotation:x", base_left_rot.x + 0.5, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		active_attack_tween.chain().tween_property(left_arm_pivot, "rotation:x", base_left_rot.x, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	active_attack_tween.chain().tween_callback(func():
		is_playing_attack_anim = false
		if body_pivot and is_instance_valid(body_pivot):
			body_pivot.position = base_body_pos
			body_pivot.rotation = base_body_rot
			body_pivot.scale = base_body_scale
		if left_arm_pivot and is_instance_valid(left_arm_pivot):
			left_arm_pivot.rotation = base_left_rot
		if right_arm_pivot and is_instance_valid(right_arm_pivot):
			right_arm_pivot.rotation = base_right_rot
	)

func get_wave_income() -> int:
	return current_income

func play_wave_end_cash_fountain(amount: int) -> void:
	total_cash_generated += amount
	if AudioManager:
		AudioManager.play_sfx("money_fountain")
	var container = get_parent().get_parent() if (get_parent() and get_parent().get_parent()) else get_parent()
	if not container:
		return
		
	# 1. Squash & Stretch Celebration Jump
	if visual_root:
		var tw_jump = create_tween()
		tw_jump.tween_property(visual_root, "position:y", 0.85, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_jump.parallel().tween_property(visual_root, "scale", Vector3(1.3, 1.45, 1.3), 0.22)
		tw_jump.tween_property(visual_root, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw_jump.parallel().tween_property(visual_root, "scale", Vector3.ONE, 0.28)
		
	# 2. 3D Floating Cash Billboard
	var cash_label = Label3D.new()
	cash_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cash_label.no_depth_test = true
	cash_label.render_priority = 30
	cash_label.pixel_size = 0.011
	cash_label.text = "+$%d 💰" % amount
	cash_label.font_size = 52
	cash_label.modulate = Color(1.0, 0.95, 0.25)
	cash_label.outline_size = 16
	cash_label.outline_modulate = Color(0.08, 0.18, 0.04, 1.0)
	var custom_font = UIThemeBuilder.get_title_font()
	if custom_font:
		cash_label.font = custom_font
	container.add_child(cash_label)
	cash_label.global_position = global_position + Vector3(0, 2.8, 0)
	
	var tw_lbl = cash_label.create_tween()
	tw_lbl.parallel().tween_property(cash_label, "position:y", cash_label.position.y + 2.6, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_lbl.parallel().tween_property(cash_label, "modulate:a", 0.0, 1.6).set_delay(0.4)
	tw_lbl.tween_callback(cash_label.queue_free)
	
	# 3. 3D Spinning Gold Coins Fountain Erupting to the Sky
	var gold_mat = ModelBuilder3D.make_mat(Color("#F4D03F"), 0.15, 0.85, Color("#F7DC6F"), 0.95)
	for i in range(12):
		var coin = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = 0.04
		coin.mesh = cyl
		coin.material_override = gold_mat
		container.add_child(coin)
		coin.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 1.2, randf_range(-0.3, 0.3))
		
		var target_height = randf_range(4.5, 7.8)
		var spread = Vector3(randf_range(-1.4, 1.4), target_height, randf_range(-1.4, 1.4))
		var spin_rot = Vector3(randf_range(360, 1080), randf_range(360, 1080), 0)
		
		var tw_coin = coin.create_tween()
		tw_coin.parallel().tween_property(coin, "position", coin.position + spread, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_coin.parallel().tween_property(coin, "rotation_degrees", spin_rot, 1.4)
		tw_coin.parallel().tween_property(coin, "scale", Vector3.ZERO, 0.4).set_delay(1.0)
		tw_coin.tween_callback(coin.queue_free)
		
	# 4. 3D Dollar Bills Fluttering to the Sky
	var bill_mat = ModelBuilder3D.make_mat(Color("#2ECC71"), 0.3, 0.1, Color("#27AE60"), 0.95)
	for i in range(8):
		var bill = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.38, 0.02, 0.22)
		bill.mesh = box
		bill.material_override = bill_mat
		container.add_child(bill)
		bill.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 1.3, randf_range(-0.3, 0.3))
		
		var bill_spread = Vector3(randf_range(-1.8, 1.8), randf_range(5.0, 8.5), randf_range(-1.8, 1.8))
		var bill_rot = Vector3(randf_range(180, 720), randf_range(180, 720), randf_range(180, 720))
		
		var tw_bill = bill.create_tween()
		tw_bill.parallel().tween_property(bill, "position", bill.position + bill_spread, 1.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_bill.parallel().tween_property(bill, "rotation_degrees", bill_rot, 1.7)
		tw_bill.parallel().tween_property(bill, "scale", Vector3.ZERO, 0.45).set_delay(1.25)
		tw_bill.tween_callback(bill.queue_free)

func get_next_upgrade_cost() -> int:
	var data = GameData.TOWERS.get(tower_id, {})
	var upgrades = data.get("upgrades", [])
	if current_upgrade_level >= upgrades.size():
		return -1
	var raw_cost = upgrades[current_upgrade_level].get("cost", 100)
	var trait_data = GameData.TRAITS.get(trait_id, GameData.TRAITS["none"])
	var cost_mult = trait_data.get("upgrade_cost_mult", 1.0)
	return int(raw_cost * cost_mult)

func upgrade() -> bool:
	var cost = get_next_upgrade_cost()
	if cost <= 0:
		return false
	total_spent += cost
	current_upgrade_level += 1
	recalculate_stats()
	emit_signal("tower_upgraded", self)
	return true

func get_sell_value() -> int:
	return int(total_spent * 0.7)

func _on_enemy_entered(area: Area3D) -> void:
	if area.is_in_group("enemies") and area not in enemies_in_range:
		enemies_in_range.append(area)

func _on_enemy_exited(area: Area3D) -> void:
	if area in enemies_in_range:
		enemies_in_range.erase(area)
