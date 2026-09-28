extends Area3D

## EnemyBase 3D - Moves along Path3D, renders 3D enemy mesh, high-visibility 3D billboards, damage popups, and recursion-safe power class debuffs

signal enemy_defeated(reward_cash, enemy_node)
signal enemy_escaped(damage_to_base, enemy_node)

var enemy_id: String = "jellyfish_pink"
var max_hp: float = 100.0
var current_hp: float = 100.0
var base_speed: float = 4.5
var current_speed: float = 4.5
var reward_cash: int = 20

var is_boss: bool = false
var is_dead: bool = false
var slow_timer: float = 0.0
var anim_time: float = 0.0

# Class Debuff States
var is_frozen: bool = false
var freeze_timer: float = 0.0

var armor_shred_mult: float = 0.0
var armor_shred_timer: float = 0.0

var soul_burn_dps: float = 0.0
var soul_burn_timer: float = 0.0
var soul_burn_tick: float = 0.0

@onready var path_follow: PathFollow3D = get_parent() if get_parent() is PathFollow3D else null
var visual_root: Node3D = null
var hp_label_3d: Label3D = null
var badge_label_3d: Label3D = null
var status_label_3d: Label3D = null
var freeze_mesh: MeshInstance3D = null
var speed_trail_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("enemies")
	if get_parent() is PathFollow3D:
		path_follow = get_parent()
	_setup_visuals()

func setup(p_id: String, hp_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	enemy_id = p_id
	var data = GameData.ENEMIES.get(enemy_id, GameData.ENEMIES["jellyfish_pink"])
	
	max_hp = data.get("hp", 100.0) * hp_mult
	current_hp = max_hp
	base_speed = data.get("speed", 4.5) * speed_mult
	current_speed = base_speed
	reward_cash = maxi(1, int(data.get("reward", 8) * (1.0 + max(0.0, hp_mult - 1.0) * 0.35)))
	is_boss = data.get("is_boss", false)
	
	_setup_visuals()

func _setup_visuals() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	visual_root = ModelBuilder3D.build_enemy_model(enemy_id)
	visual_root.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(visual_root)
	
	# High-Visibility 3D Billboard HP Label (Crisp rendering, zero depth-test clipping)
	if not hp_label_3d:
		hp_label_3d = Label3D.new()
		hp_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hp_label_3d.no_depth_test = true
		hp_label_3d.render_priority = 20
		hp_label_3d.pixel_size = 0.009
		hp_label_3d.font_size = 40 if not is_boss else 48
		hp_label_3d.outline_size = 14
		hp_label_3d.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
		var custom_font = UIThemeBuilder.get_title_font()
		if custom_font:
			hp_label_3d.font = custom_font
		add_child(hp_label_3d)
	hp_label_3d.position = Vector3(0, 3.4 if is_boss else 2.3, 0)
	
	# High-Visibility 3D Billboard Ability Badge (Speed, Tank, Boss, Scout)
	if not badge_label_3d:
		badge_label_3d = Label3D.new()
		badge_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge_label_3d.no_depth_test = true
		badge_label_3d.render_priority = 24
		badge_label_3d.pixel_size = 0.0085
		badge_label_3d.font_size = 36 if is_boss else 30
		badge_label_3d.outline_size = 14
		badge_label_3d.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
		var custom_font = UIThemeBuilder.get_title_font()
		if custom_font:
			badge_label_3d.font = custom_font
		add_child(badge_label_3d)
		
	_update_ability_badge()
	
	# High-Visibility 3D Billboard Status Label (positioned above Badge to prevent overlapping)
	if not status_label_3d:
		status_label_3d = Label3D.new()
		status_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		status_label_3d.no_depth_test = true
		status_label_3d.render_priority = 21
		status_label_3d.pixel_size = 0.008
		status_label_3d.font_size = 32 if not is_boss else 38
		status_label_3d.outline_size = 12
		status_label_3d.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
		var custom_font = UIThemeBuilder.get_body_font()
		if custom_font:
			status_label_3d.font = custom_font
		status_label_3d.visible = false
		add_child(status_label_3d)
	status_label_3d.position = Vector3(0, 5.2 if is_boss else 3.8, 0)
	
	if not freeze_mesh:
		freeze_mesh = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 1.1 if is_boss else 0.95
		sp.height = 2.2 if is_boss else 1.9
		freeze_mesh.mesh = sp
		var frost_mat = ModelBuilder3D.make_mat(Color("#5DADE2"), 0.1, 0.1, Color("#85C1E9"), 0.5)
		freeze_mesh.material_override = frost_mat
		freeze_mesh.visible = false
		add_child(freeze_mesh)
		
	_update_hp_display()

func _update_ability_badge() -> void:
	if not badge_label_3d:
		return
	var y_pos = 4.3 if is_boss else 3.1
	badge_label_3d.position = Vector3(0, y_pos, 0)
	
	if is_boss:
		badge_label_3d.text = "👑 BOSS"
		badge_label_3d.modulate = Color(1.0, 0.25, 0.35)
	elif base_speed >= 5.0:
		badge_label_3d.text = "⚡ SPEED"
		badge_label_3d.modulate = Color(1.0, 0.95, 0.20)
		_setup_speed_trail()
	elif max_hp >= 1000.0:
		badge_label_3d.text = "🛡️ TANK"
		badge_label_3d.modulate = Color(0.35, 0.88, 1.0)
	elif base_speed >= 4.2 and max_hp < 300.0:
		badge_label_3d.text = "💨 SCOUT"
		badge_label_3d.modulate = Color(0.40, 1.0, 0.65)
	else:
		badge_label_3d.text = "⚙️ DRONE"
		badge_label_3d.modulate = Color(0.85, 0.92, 0.98)

func _setup_speed_trail() -> void:
	if speed_trail_mesh:
		return
	speed_trail_mesh = MeshInstance3D.new()
	var tr = TorusMesh.new()
	tr.inner_radius = 0.45
	tr.outer_radius = 0.70
	speed_trail_mesh.mesh = tr
	speed_trail_mesh.position = Vector3(0, 0.12, 0)
	var trail_mat = ModelBuilder3D.make_mat(Color(1.0, 0.9, 0.2, 0.55), 0.2, 0.0, Color(1.0, 0.85, 0.1), 0.85)
	speed_trail_mesh.material_override = trail_mat
	add_child(speed_trail_mesh)

func _update_hp_display() -> void:
	if hp_label_3d and not is_dead:
		var pct = clampf(current_hp / maxf(1.0, max_hp), 0.0, 1.0)
		hp_label_3d.text = "HP: %d/%d" % [int(ceilf(maxf(0.0, current_hp))), int(max_hp)]
		if pct > 0.5:
			hp_label_3d.modulate = Color(0.3, 1.0, 0.5)
		elif pct > 0.25:
			hp_label_3d.modulate = Color(1.0, 0.88, 0.2)
		else:
			hp_label_3d.modulate = Color(1.0, 0.35, 0.35)

func _update_status_display() -> void:
	if not status_label_3d or is_dead:
		return
	var tags = []
	if is_frozen:
		tags.append("❄️ FROZEN")
	elif slow_timer > 0.0:
		tags.append("💧 SLOWED")
	if armor_shred_timer > 0.0:
		tags.append("🛡️ SHRED (+30%)")
	if soul_burn_timer > 0.0:
		tags.append("👻 SOUL BURN")
		
	if tags.is_empty():
		status_label_3d.visible = false
	else:
		status_label_3d.visible = true
		status_label_3d.text = " ".join(tags)
		if is_frozen:
			status_label_3d.modulate = Color("#5DADE2")
		elif soul_burn_timer > 0.0:
			status_label_3d.modulate = Color("#C39BD3")
		elif armor_shred_timer > 0.0:
			status_label_3d.modulate = Color("#E74C3C")
		else:
			status_label_3d.modulate = Color("#F39C12")

func _process(delta: float) -> void:
	if is_dead:
		return
		
	anim_time += delta * 5.0
	if visual_root and not is_frozen:
		visual_root.position.y = sin(anim_time) * 0.12
		
	if badge_label_3d:
		var base_y = 4.3 if is_boss else 3.1
		badge_label_3d.position.y = base_y + sin(anim_time * 0.7) * 0.08
	if speed_trail_mesh:
		speed_trail_mesh.scale = Vector3.ONE * (1.0 + sin(anim_time * 1.6) * 0.14)
		
	# Process Freeze
	if freeze_timer > 0.0:
		freeze_timer -= delta
		is_frozen = true
		current_speed = 0.0
		if freeze_mesh:
			freeze_mesh.visible = true
		if freeze_timer <= 0.0:
			is_frozen = false
			current_speed = base_speed
			if freeze_mesh:
				freeze_mesh.visible = false
	elif slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			current_speed = base_speed
	else:
		current_speed = base_speed
		
	# Process Armor Shred
	if armor_shred_timer > 0.0:
		armor_shred_timer -= delta
		if armor_shred_timer <= 0.0:
			armor_shred_mult = 0.0
			
	# Process Soul Burn True DoT
	if soul_burn_timer > 0.0:
		soul_burn_timer -= delta
		soul_burn_tick += delta
		if soul_burn_tick >= 0.5:
			soul_burn_tick = 0.0
			take_damage(soul_burn_dps * 0.5, true)
		if soul_burn_timer <= 0.0:
			soul_burn_dps = 0.0
			
	_update_status_display()

	if path_follow and not is_frozen and not is_dead:
		path_follow.progress += current_speed * delta
		if path_follow.progress_ratio >= 0.995:
			_reach_end()

func get_path_progress() -> float:
	if path_follow:
		return path_follow.progress
	return 0.0

func _spawn_damage_popup(amount: float, is_true_damage: bool = false) -> void:
	var container = get_parent().get_parent() if (get_parent() and get_parent().get_parent()) else get_parent()
	if not container or not is_inside_tree():
		return
		
	var dmg_lbl = Label3D.new()
	dmg_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_lbl.no_depth_test = true
	dmg_lbl.render_priority = 25
	dmg_lbl.pixel_size = 0.009
	dmg_lbl.font_size = 38
	dmg_lbl.outline_size = 12
	dmg_lbl.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
	var custom_font = UIThemeBuilder.get_title_font()
	if custom_font:
		dmg_lbl.font = custom_font
		
	dmg_lbl.text = "-%d" % int(ceilf(amount))
	if is_true_damage:
		dmg_lbl.modulate = Color(0.85, 0.45, 1.0) # Violet
	elif armor_shred_mult > 0.0:
		dmg_lbl.modulate = Color(1.0, 0.60, 0.25) # Orange
	else:
		dmg_lbl.modulate = Color(1.0, 0.35, 0.35) # Red
		
	container.add_child(dmg_lbl)
	var jitter = Vector3(randf_range(-0.4, 0.4), 2.2, randf_range(-0.4, 0.4))
	dmg_lbl.global_position = global_position + jitter
	
	var tw = dmg_lbl.create_tween()
	tw.parallel().tween_property(dmg_lbl, "position:y", dmg_lbl.position.y + 1.5, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dmg_lbl, "modulate:a", 0.0, 0.75).set_delay(0.2)
	tw.tween_callback(dmg_lbl.queue_free)

func take_damage(amount: float, is_true_damage: bool = false) -> void:
	if is_dead or is_queued_for_deletion():
		return
		
	var final_dmg = amount
	if not is_true_damage and armor_shred_mult > 0.0:
		final_dmg *= (1.0 + armor_shred_mult)
		
	current_hp -= final_dmg
	_update_hp_display()
	_spawn_damage_popup(final_dmg, is_true_damage)
	
	if visual_root:
		var tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector3(1.25, 0.85, 1.25), 0.04)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.06)
	
	if current_hp <= 0.0:
		is_dead = true
		set_process(false)
		remove_from_group("enemies")
		if soul_burn_timer > 0.0:
			soul_burn_timer = 0.0 # Clear immediately to prevent any recursive loops
			_soul_detonation()
		_die()

func apply_slow(factor: float, duration: float) -> void:
	if is_frozen or is_dead:
		return
	var slow_f = factor * 0.4 if is_boss else factor
	current_speed = base_speed * (1.0 - slow_f)
	slow_timer = maxf(slow_timer, duration * (0.35 if is_boss else 1.0))

func apply_freeze(duration: float) -> void:
	if is_dead:
		return
	var f_dur = duration * 0.25 if is_boss else duration
	freeze_timer = maxf(freeze_timer, f_dur)
	is_frozen = true
	current_speed = 0.0
	if freeze_mesh:
		freeze_mesh.visible = true


func apply_armor_shred(mult: float, duration: float) -> void:
	if is_dead:
		return
	armor_shred_mult = maxf(armor_shred_mult, mult)
	armor_shred_timer = maxf(armor_shred_timer, duration)

func apply_soul_burn(max_hp_pct: float, duration: float) -> void:
	if is_dead:
		return
	soul_burn_dps = max_hp * max_hp_pct
	soul_burn_timer = maxf(soul_burn_timer, duration)
	soul_burn_tick = 0.0

func check_divine_execution(threshold_pct: float = 0.18) -> bool:
	if is_boss or is_dead or is_queued_for_deletion():
		return false
	if current_hp > 0.0 and (current_hp / maxf(1.0, max_hp)) <= threshold_pct:
		_execute_smite()
		return true
	return false

func _execute_smite() -> void:
	if is_dead or is_queued_for_deletion():
		return
	is_dead = true
	set_process(false)
	remove_from_group("enemies")
	
	var parent_scene = get_parent().get_parent() if (get_parent() and get_parent().get_parent()) else get_parent()
	if parent_scene:
		var beam = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.65
		cyl.height = 14.0
		beam.mesh = cyl
		beam.material_override = ModelBuilder3D.make_mat(Color("#F4D03F"), 0.1, 0.2, Color("#F7DC6F"), 0.95)
		parent_scene.add_child(beam)
		beam.global_position = global_position + Vector3(0, 7.0, 0)
		
		var smite_lbl = Label3D.new()
		smite_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		smite_lbl.no_depth_test = true
		smite_lbl.render_priority = 32
		smite_lbl.pixel_size = 0.012
		smite_lbl.text = "👑 SMITED!"
		smite_lbl.font_size = 52
		smite_lbl.modulate = Color(1.0, 0.92, 0.25)
		smite_lbl.outline_size = 16
		smite_lbl.outline_modulate = Color(0.04, 0.06, 0.10, 1.0)
		var custom_font = UIThemeBuilder.get_title_font()
		if custom_font:
			smite_lbl.font = custom_font
			
		parent_scene.add_child(smite_lbl)
		smite_lbl.global_position = global_position + Vector3(0, 2.8, 0)
		
		var tw = create_tween()
		tw.parallel().tween_property(smite_lbl, "position:y", smite_lbl.position.y + 2.4, 1.2)
		tw.parallel().tween_property(smite_lbl, "modulate:a", 0.0, 1.2)
		tw.parallel().tween_property(beam, "scale:x", 0.0, 0.4).set_delay(0.2)
		tw.parallel().tween_property(beam, "scale:z", 0.0, 0.4).set_delay(0.2)
		tw.tween_callback(func():
			if is_instance_valid(beam): beam.queue_free()
			if is_instance_valid(smite_lbl): smite_lbl.queue_free()
		)
	current_hp = 0.0
	_die()

func _soul_detonation() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e != self and not e.is_queued_for_deletion() and not e.get("is_dead"):
			if e.global_position.distance_to(global_position) <= 3.8:
				if e.has_method("take_damage"):
					e.take_damage(60.0, true)

func _die() -> void:
	is_dead = true
	set_process(false)
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	
	emit_signal("enemy_defeated", reward_cash, self)
	if path_follow:
		path_follow.queue_free()
	else:
		queue_free()

func _reach_end() -> void:
	if is_dead or is_queued_for_deletion():
		return
	is_dead = true
	set_process(false)
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	
	var base_damage = 5 if is_boss else 1
	emit_signal("enemy_escaped", base_damage, self)
	if path_follow:
		path_follow.queue_free()
	else:
		queue_free()
