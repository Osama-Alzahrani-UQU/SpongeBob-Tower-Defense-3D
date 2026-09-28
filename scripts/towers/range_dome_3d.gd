extends Node3D

## RangeDome3D - Tactical Holographic Range Dome with Radiant Undulating Ripples & Elastic Animation

var current_radius: float = 8.0
var dome_color: Color = Color(0.10, 0.72, 0.98)
var rim_color: Color = Color(0.38, 0.96, 1.0)
var wave_color: Color = Color(0.75, 1.0, 0.92)

var dome_mesh_inst: MeshInstance3D = null
var ground_ring_inst: MeshInstance3D = null
var ground_ripple_inst: MeshInstance3D = null
var compass_root: Node3D = null

var shader_mat: ShaderMaterial = null
var active_tween: Tween = null
var is_active: bool = false
var is_invalid_placement: bool = false
var ripple_time: float = 0.0

const DOME_SHADER = preload("res://shaders/range_dome.gdshader")

func _ready() -> void:
	visible = false
	scale = Vector3(0.01, 0.01, 0.01)

func setup(radius: float, tower_id: String = "spongebob", trait_id: String = "none") -> void:
	current_radius = maxf(1.5, radius)
	is_invalid_placement = false
	_pick_palette(tower_id, trait_id)
	_build_components()

func _pick_palette(tower_id: String, trait_id: String) -> void:
	var t_data = GameData.TOWERS.get(tower_id, {})
	var p_class = t_data.get("power_class", "")
	
	if trait_id != "none" and GameData.TRAITS.has(trait_id):
		var tr_data = GameData.TRAITS[trait_id]
		dome_color = tr_data.get("color", Color(0.12, 0.76, 0.98))
		rim_color = tr_data.get("glow_color", Color(0.5, 0.95, 1.0))
		wave_color = rim_color.lightened(0.35)
	elif p_class != "":
		match p_class:
			"economy":
				dome_color = Color(1.0, 0.82, 0.18)
				rim_color = Color(1.0, 0.95, 0.45)
				wave_color = Color(1.0, 1.0, 0.85)
			"control":
				dome_color = Color(0.18, 0.68, 1.0)
				rim_color = Color(0.65, 0.95, 1.0)
				wave_color = Color(0.85, 1.0, 1.0)
			"brawler":
				dome_color = Color(0.92, 0.25, 0.20)
				rim_color = Color(1.0, 0.55, 0.30)
				wave_color = Color(1.0, 0.85, 0.60)
			"aoe":
				dome_color = Color(0.15, 0.85, 0.70)
				rim_color = Color(0.40, 1.0, 0.88)
				wave_color = Color(0.80, 1.0, 0.95)
			"marksman":
				dome_color = Color(0.98, 0.65, 0.10)
				rim_color = Color(1.0, 0.88, 0.25)
				wave_color = Color(1.0, 0.98, 0.75)
			"spectral":
				dome_color = Color(0.20, 0.95, 0.65)
				rim_color = Color(0.78, 0.45, 1.0)
				wave_color = Color(0.75, 1.0, 0.88)
			"cosmic":
				dome_color = Color(0.10, 1.0, 0.82)
				rim_color = Color(0.92, 0.86, 1.0)
				wave_color = Color(1.0, 1.0, 1.0)
			_:
				dome_color = Color(0.10, 0.72, 0.98)
				rim_color = Color(0.38, 0.96, 1.0)
				wave_color = Color(0.75, 1.0, 0.92)
	else:
		var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
		match r_enum:
			GameData.Rarity.MYTHIC:
				dome_color = Color(0.92, 0.28, 0.35)
				rim_color = Color(1.0, 0.85, 0.30)
				wave_color = Color(1.0, 0.95, 0.75)
			GameData.Rarity.LEGENDARY:
				dome_color = Color(0.95, 0.65, 0.12)
				rim_color = Color(1.0, 0.88, 0.35)
				wave_color = Color(1.0, 0.98, 0.80)
			GameData.Rarity.EPIC:
				dome_color = Color(0.68, 0.22, 0.92)
				rim_color = Color(0.88, 0.55, 1.0)
				wave_color = Color(0.96, 0.85, 1.0)
			GameData.Rarity.RARE:
				dome_color = Color(0.15, 0.55, 0.95)
				rim_color = Color(0.35, 0.85, 1.0)
				wave_color = Color(0.70, 0.95, 1.0)
			_:
				dome_color = Color(0.10, 0.72, 0.98)
				rim_color = Color(0.38, 0.96, 1.0)
				wave_color = Color(0.75, 1.0, 0.92)

func _build_components() -> void:
	for c in get_children():
		c.queue_free()
		
	# 1. Main Transparent Sci-Fi Forcefield Hemisphere Dome
	dome_mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = current_radius
	sphere.height = current_radius
	sphere.is_hemisphere = true
	dome_mesh_inst.mesh = sphere
	dome_mesh_inst.position = Vector3(0, 0.04, 0)
	
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = DOME_SHADER
	shader_mat.set_shader_parameter("base_color", Color(dome_color.r, dome_color.g, dome_color.b, 0.20))
	shader_mat.set_shader_parameter("rim_color", Color(rim_color.r, rim_color.g, rim_color.b, 0.85))
	shader_mat.set_shader_parameter("wave_color", Color(wave_color.r, wave_color.g, wave_color.b, 1.0))
	shader_mat.set_shader_parameter("master_alpha", 0.0)
	shader_mat.set_shader_parameter("wave_speed", 2.2)
	shader_mat.set_shader_parameter("wave_frequency", 13.0)
	dome_mesh_inst.material_override = shader_mat
	add_child(dome_mesh_inst)
	
	# 2. Sleek Luminous Ground Perimeter Ring
	ground_ring_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = maxf(0.5, current_radius - 0.12)
	torus.outer_radius = current_radius + 0.04
	ground_ring_inst.mesh = torus
	ground_ring_inst.position = Vector3(0, 0.06, 0)
	
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(rim_color.r, rim_color.g, rim_color.b, 0.85)
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_ring_inst.material_override = r_mat
	add_child(ground_ring_inst)
	
	# 3. Rotating Cardinal Compass Radar Ticks
	compass_root = Node3D.new()
	compass_root.position = Vector3(0, 0.07, 0)
	add_child(compass_root)
	
	var tick_mat = StandardMaterial3D.new()
	tick_mat.albedo_color = Color(wave_color.r, wave_color.g, wave_color.b, 0.95)
	tick_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for i in range(8):
		var angle = (float(i) / 8.0) * TAU
		var is_major = (i % 2 == 0)
		var tick = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.08 if is_major else 0.04, 0.03, 0.40 if is_major else 0.22)
		tick.mesh = box
		tick.material_override = tick_mat
		tick.position = Vector3(sin(angle) * current_radius, 0, cos(angle) * current_radius)
		tick.rotation.y = angle
		compass_root.add_child(tick)
		
	# 4. Expanding Battlefield Floor Pulse Ring
	ground_ripple_inst = MeshInstance3D.new()
	var rip_torus = TorusMesh.new()
	rip_torus.inner_radius = 0.1
	rip_torus.outer_radius = 0.25
	ground_ripple_inst.mesh = rip_torus
	ground_ripple_inst.position = Vector3(0, 0.05, 0)
	
	var rip_mat = StandardMaterial3D.new()
	rip_mat.albedo_color = Color(wave_color.r, wave_color.g, wave_color.b, 0.45)
	rip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_ripple_inst.material_override = rip_mat
	add_child(ground_ripple_inst)

func _process(delta: float) -> void:
	if not visible or not is_active:
		return
		
	# Smoothly rotate tactical compass ticks
	if compass_root:
		compass_root.rotate_y(delta * 0.38)
		
	# Animate expanding floor ground ripple
	if ground_ripple_inst and is_instance_valid(ground_ripple_inst):
		ripple_time += delta * 1.6
		var phase = fmod(ripple_time, 1.0) # 0.0 to 1.0
		var r = phase * current_radius
		var r_mesh = ground_ripple_inst.mesh as TorusMesh
		if r_mesh:
			r_mesh.inner_radius = maxf(0.05, r - 0.14)
			r_mesh.outer_radius = r + 0.02
		var m = ground_ripple_inst.material_override as StandardMaterial3D
		if m:
			var alpha_falloff = (1.0 - phase) * 0.55
			m.albedo_color.a = alpha_falloff

func animate_show(instant: bool = false) -> void:
	is_active = true
	visible = true
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	if instant:
		scale = Vector3.ONE
		if shader_mat:
			shader_mat.set_shader_parameter("deploy_progress", 1.0)
			shader_mat.set_shader_parameter("master_alpha", 1.0)
			shader_mat.set_shader_parameter("flash_intensity", 0.0)
		if ground_ring_inst:
			ground_ring_inst.scale = Vector3.ONE
		if compass_root:
			compass_root.scale = Vector3.ONE
		return
		
	# High-Impact Sci-Fi Shield Deployment Animation
	scale = Vector3(0.18, 0.02, 0.18)
	if ground_ring_inst:
		ground_ring_inst.scale = Vector3(0.08, 1.0, 0.08)
	if compass_root:
		compass_root.scale = Vector3(0.08, 1.0, 0.08)
		compass_root.rotation.y = 0.0
	ripple_time = 0.0
		
	if shader_mat:
		shader_mat.set_shader_parameter("deploy_progress", 0.0)
		shader_mat.set_shader_parameter("master_alpha", 1.0)
		shader_mat.set_shader_parameter("flash_intensity", 0.0)
		
	active_tween = create_tween().set_parallel(true)
	
	# Phase 1: Ascending blazing wavefront from ground to apex (0.0 -> 1.0)
	if shader_mat:
		active_tween.tween_method(
			func(v: float): shader_mat.set_shader_parameter("deploy_progress", v),
			0.0, 1.0, 0.42
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Phase 2: Elastic 3D physical expansion with dome height pop
	active_tween.tween_property(self, "scale", Vector3(1.05, 1.18, 1.05), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Phase 3: Ground ring & compass shockwave spreading out to perimeter
	if ground_ring_inst:
		active_tween.tween_property(ground_ring_inst, "scale", Vector3.ONE, 0.34).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	if compass_root:
		active_tween.tween_property(compass_root, "scale", Vector3.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		active_tween.tween_property(compass_root, "rotation:y", deg_to_rad(90.0), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Phase 4: Settle to stable scale + initialization energy flash burst
	active_tween.chain().tween_property(self, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if shader_mat:
		active_tween.parallel().tween_method(
			func(v: float): shader_mat.set_shader_parameter("flash_intensity", v),
			1.4, 0.0, 0.30
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func animate_hide(instant: bool = false) -> void:
	is_active = false
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	if instant:
		visible = false
		scale = Vector3(0.01, 0.01, 0.01)
		if shader_mat:
			shader_mat.set_shader_parameter("master_alpha", 0.0)
			shader_mat.set_shader_parameter("deploy_progress", 0.0)
		return
		
	active_tween = create_tween().set_parallel(true)
	if shader_mat:
		active_tween.tween_method(
			func(v: float): shader_mat.set_shader_parameter("deploy_progress", v),
			1.0, 0.0, 0.22
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		active_tween.tween_method(
			func(v: float): shader_mat.set_shader_parameter("master_alpha", v),
			1.0, 0.0, 0.20
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	active_tween.tween_property(self, "scale", Vector3(0.2, 0.02, 0.2), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if ground_ring_inst:
		active_tween.tween_property(ground_ring_inst, "scale", Vector3(0.1, 1.0, 0.1), 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if compass_root:
		active_tween.tween_property(compass_root, "scale", Vector3(0.1, 1.0, 0.1), 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
	active_tween.finished.connect(func():
		if not is_active:
			visible = false
	)

func set_radius(new_radius: float, animate_expansion: bool = true) -> void:
	current_radius = maxf(1.5, new_radius)
	if dome_mesh_inst and dome_mesh_inst.mesh is SphereMesh:
		var sp = dome_mesh_inst.mesh as SphereMesh
		sp.radius = current_radius
		sp.height = current_radius
	if ground_ring_inst and ground_ring_inst.mesh is TorusMesh:
		var tr = ground_ring_inst.mesh as TorusMesh
		tr.inner_radius = maxf(0.5, current_radius - 0.12)
		tr.outer_radius = current_radius + 0.04
	if compass_root:
		for i in range(compass_root.get_child_count()):
			var tick = compass_root.get_child(i)
			var angle = (float(i) / float(compass_root.get_child_count())) * TAU
			tick.position = Vector3(sin(angle) * current_radius, 0, cos(angle) * current_radius)
	if animate_expansion:
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector3(1.12, 1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_placement_validity(is_valid: bool) -> void:
	if is_invalid_placement == not is_valid:
		return
	is_invalid_placement = not is_valid
	if is_invalid_placement:
		# Forbidden Warning Palette (Intense Warning Crimson Red)
		if shader_mat:
			shader_mat.set_shader_parameter("base_color", Color(1.0, 0.08, 0.12, 0.32))
			shader_mat.set_shader_parameter("rim_color", Color(1.0, 0.22, 0.22, 0.95))
			shader_mat.set_shader_parameter("wave_color", Color(1.0, 0.55, 0.55, 1.0))
		if ground_ring_inst and ground_ring_inst.material_override is StandardMaterial3D:
			ground_ring_inst.material_override.albedo_color = Color(1.0, 0.20, 0.22, 0.95)
		if compass_root:
			for tick in compass_root.get_children():
				if tick is MeshInstance3D and tick.material_override is StandardMaterial3D:
					tick.material_override.albedo_color = Color(1.0, 0.45, 0.45, 0.95)
		if ground_ripple_inst and ground_ripple_inst.material_override is StandardMaterial3D:
			ground_ripple_inst.material_override.albedo_color = Color(1.0, 0.30, 0.30, 0.55)
	else:
		# Restore original tactical palette
		if shader_mat:
			shader_mat.set_shader_parameter("base_color", Color(dome_color.r, dome_color.g, dome_color.b, 0.20))
			shader_mat.set_shader_parameter("rim_color", Color(rim_color.r, rim_color.g, rim_color.b, 0.85))
			shader_mat.set_shader_parameter("wave_color", Color(wave_color.r, wave_color.g, wave_color.b, 1.0))
		if ground_ring_inst and ground_ring_inst.material_override is StandardMaterial3D:
			ground_ring_inst.material_override.albedo_color = Color(rim_color.r, rim_color.g, rim_color.b, 0.85)
		if compass_root:
			for tick in compass_root.get_children():
				if tick is MeshInstance3D and tick.material_override is StandardMaterial3D:
					tick.material_override.albedo_color = Color(wave_color.r, wave_color.g, wave_color.b, 0.95)
		if ground_ripple_inst and ground_ripple_inst.material_override is StandardMaterial3D:
			ground_ripple_inst.material_override.albedo_color = Color(wave_color.r, wave_color.g, wave_color.b, 0.45)
