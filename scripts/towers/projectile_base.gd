extends Area3D

## ProjectileBase (3D) - High-fidelity projectile physics, visual palettes, and signature class mechanics

var target_enemy: Node3D = null
var speed: float = 24.0
var damage: float = 20.0
var is_aoe: bool = false
var aoe_radius: float = 3.8
var slow_factor: float = 0.0
var slow_duration: float = 2.0
var projectile_type: String = "bubble"
var power_class: String = "control"
var is_crit: bool = false
var is_freeze: bool = false

var target_last_pos: Vector3 = Vector3.ZERO
var mesh_inst: MeshInstance3D = null
var aura_mesh: MeshInstance3D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_build_visual()

func setup(
	p_target: Node3D,
	p_damage: float,
	p_type: String = "bubble",
	p_slow: float = 0.0,
	p_aoe: bool = false,
	p_aoe_radius: float = 3.8,
	p_class: String = "control",
	p_is_crit: bool = false,
	p_is_freeze: bool = false
) -> void:
	target_enemy = p_target
	damage = p_damage
	projectile_type = p_type
	slow_factor = p_slow
	is_aoe = p_aoe
	aoe_radius = p_aoe_radius
	power_class = p_class
	is_crit = p_is_crit
	is_freeze = p_is_freeze
	
	if power_class == "marksman":
		speed = 46.0 # Hyper-velocity sniper laser
	elif power_class == "brawler":
		speed = 18.0 # Heavy kinetic boulder
		
	if is_instance_valid(target_enemy):
		target_last_pos = target_enemy.global_position + Vector3(0, 1.0, 0)
		
	_build_visual()

func _build_visual() -> void:
	if mesh_inst and is_instance_valid(mesh_inst):
		mesh_inst.queue_free()
	if aura_mesh and is_instance_valid(aura_mesh):
		aura_mesh.queue_free()
		
	mesh_inst = MeshInstance3D.new()
	var col = Color("#85C1E9")
	var emit_col = Color("#AED6F1")
	
	match power_class:
		"control":
			if is_freeze:
				col = Color("#5DADE2")
				emit_col = Color("#D4E6F1")
				var box = BoxMesh.new()
				box.size = Vector3(0.5, 0.5, 0.5)
				mesh_inst.mesh = box
			else:
				col = Color("#85C1E9")
				emit_col = Color("#3498DB")
				var sphere = SphereMesh.new()
				sphere.radius = 0.28
				sphere.height = 0.56
				mesh_inst.mesh = sphere
		"brawler":
			col = Color("#E74C3C") if not is_crit else Color("#FF2A2A")
			emit_col = Color("#C0392B") if not is_crit else Color("#FF8844")
			var rock = SphereMesh.new()
			rock.radius = 0.42 if is_crit else 0.32
			rock.height = 0.74 if is_crit else 0.58
			mesh_inst.mesh = rock
		"aoe":
			col = Color("#1ABC9C")
			emit_col = Color("#48C9B0")
			var ring = TorusMesh.new()
			ring.inner_radius = 0.16
			ring.outer_radius = 0.36
			mesh_inst.mesh = ring
		"marksman":
			col = Color("#F39C12")
			emit_col = Color("#F1C40F")
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.08
			cyl.height = 1.1
			mesh_inst.mesh = cyl
			mesh_inst.rotation_degrees = Vector3(90, 0, 0)
		"spectral":
			col = Color("#9B59B6")
			emit_col = Color("#2ECC71") # Eerie violet-green ghost flame
			var sphere = SphereMesh.new()
			sphere.radius = 0.32
			sphere.height = 0.64
			mesh_inst.mesh = sphere
		"cosmic":
			col = Color("#F4D03F")
			emit_col = Color("#00FFAA") # Celestial aurora & gold
			var sphere = SphereMesh.new()
			sphere.radius = 0.35
			sphere.height = 0.70
			mesh_inst.mesh = sphere
		_:
			var sphere = SphereMesh.new()
			sphere.radius = 0.28
			sphere.height = 0.56
			mesh_inst.mesh = sphere

	mesh_inst.material_override = ModelBuilder3D.make_mat(col, 0.15, 0.2, emit_col, 0.92)
	add_child(mesh_inst)

func _process(delta: float) -> void:
	if is_instance_valid(target_enemy):
		target_last_pos = target_enemy.global_position + Vector3(0, 1.0, 0)
	
	var diff = target_last_pos - global_position
	if diff.length_squared() > 0.01:
		var dir = diff.normalized()
		global_position += dir * speed * delta
		if mesh_inst and power_class != "marksman":
			mesh_inst.rotation_degrees.y += delta * 360.0
		elif power_class == "marksman":
			look_at(target_last_pos, Vector3.UP)
	
	if global_position.distance_to(target_last_pos) < 0.65:
		_impact()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemies"):
		_impact()

func _impact() -> void:
	var container = get_parent()
	
	# 1. Brawler: Crit Label & Armor Shred
	if power_class == "brawler":
		if is_crit and container:
			_spawn_crit_label(global_position, damage, container)
		if is_instance_valid(target_enemy) and target_enemy.has_method("apply_armor_shred"):
			target_enemy.apply_armor_shred(0.30, 3.5)
			
	# 2. Control: Freeze or Slow
	if power_class == "control":
		if is_freeze:
			if is_instance_valid(target_enemy) and target_enemy.has_method("apply_freeze"):
				target_enemy.apply_freeze(1.2)
		elif slow_factor > 0:
			if is_instance_valid(target_enemy) and target_enemy.has_method("apply_slow"):
				target_enemy.apply_slow(slow_factor, slow_duration)
				
	# 3. Spectral: Soul Burn True DoT
	if power_class == "spectral":
		if is_instance_valid(target_enemy) and target_enemy.has_method("apply_soul_burn"):
			target_enemy.apply_soul_burn(0.04, 3.0)
			
	# 4. AoE: Blast Damage + Lingering Sonic Resonance Field
	if is_aoe:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= aoe_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage)
				if power_class == "control" and slow_factor > 0 and enemy.has_method("apply_slow"):
					enemy.apply_slow(slow_factor, slow_duration)
				elif power_class == "brawler" and enemy.has_method("apply_armor_shred"):
					enemy.apply_armor_shred(0.30, 3.5)
				elif power_class == "spectral" and enemy.has_method("apply_soul_burn"):
					enemy.apply_soul_burn(0.04, 3.0)
					
		if power_class == "aoe" and container:
			_spawn_resonance_field(global_position, container)
	else:
		if is_instance_valid(target_enemy) and target_enemy.has_method("take_damage"):
			target_enemy.take_damage(damage)
			
	# 5. Cosmic: Divine Smite Execution Check
	if power_class == "cosmic":
		if is_instance_valid(target_enemy) and target_enemy.has_method("check_divine_execution"):
			target_enemy.check_divine_execution(0.18)
			
	if AudioManager:
		if power_class == "brawler":
			AudioManager.play_sfx("boulder_impact")
		elif projectile_type in ["bubble", "freeze_bubble"]:
			AudioManager.play_sfx("bubble_pop")
		else:
			AudioManager.play_sfx("enemy_hit")
			
	queue_free()

func _spawn_crit_label(pos: Vector3, crit_dmg: float, container: Node) -> void:
	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 30
	lbl.pixel_size = 0.011
	lbl.text = "💥 CRIT! %d" % int(crit_dmg)
	lbl.font_size = 46
	lbl.outline_size = 14
	lbl.outline_modulate = Color(0.08, 0.02, 0.02, 1.0)
	lbl.modulate = Color(1.0, 0.25, 0.2)
	var custom_font = UIThemeBuilder.get_title_font()
	if custom_font:
		lbl.font = custom_font
	container.add_child(lbl)
	lbl.global_position = pos + Vector3(0, 2.2, 0)
	
	var tw = lbl.create_tween()
	tw.parallel().tween_property(lbl, "position:y", lbl.position.y + 2.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.2)
	tw.tween_callback(lbl.queue_free)

func _spawn_resonance_field(pos: Vector3, container: Node) -> void:
	var field = Node3D.new()
	field.name = "SonicResonanceField"
	container.add_child(field)
	field.global_position = Vector3(pos.x, 0.05, pos.z)
	
	var ring = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = 1.8
	tor.outer_radius = 2.4
	ring.mesh = tor
	var cyan_mat = ModelBuilder3D.make_mat(Color("#1ABC9C"), 0.2, 0.1, Color("#48C9B0"), 0.85)
	ring.material_override = cyan_mat
	field.add_child(ring)
	
	var note_lbl = Label3D.new()
	note_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	note_lbl.no_depth_test = true
	note_lbl.render_priority = 25
	note_lbl.pixel_size = 0.009
	note_lbl.text = "♪ ♫ ♬"
	note_lbl.font_size = 38
	note_lbl.outline_size = 12
	note_lbl.outline_modulate = Color(0.02, 0.08, 0.06, 1.0)
	note_lbl.modulate = Color(0.25, 1.0, 0.85)
	note_lbl.position = Vector3(0, 1.5, 0)
	field.add_child(note_lbl)
	
	var tw = field.create_tween()
	tw.set_loops(3)
	tw.tween_property(ring, "scale", Vector3(1.3, 1.0, 1.3), 0.3)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.3)
	
	var tw_lbl = note_lbl.create_tween()
	tw_lbl.parallel().tween_property(note_lbl, "position:y", 2.2, 1.8)
	tw_lbl.parallel().tween_property(note_lbl, "modulate:a", 0.0, 1.8)
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	field.add_child(timer)
	var pulses = [0]
	timer.timeout.connect(func():
		pulses[0] += 1
		var enemies = field.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(field.global_position) <= 2.8:
				if e.has_method("take_damage"):
					e.take_damage(damage * 0.2)
		if pulses[0] >= 4:
			field.queue_free()
	)
