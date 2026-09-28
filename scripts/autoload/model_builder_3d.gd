extends Node

## ModelBuilder3D - Procedurally constructs stylized 3D meshes and PBR materials for SpongeBob TD

func make_mat(color: Color, roughness: float = 0.6, metallic: float = 0.0, emission: Color = Color.BLACK, alpha: float = 1.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.roughness = roughness
	mat.metallic = metallic
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.8
	return mat

func add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func add_sphere(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	mesh.rings = 24
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func add_cylinder(parent: Node3D, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = height
	mesh.radial_segments = 48
	mesh.rings = 8
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func add_torus(parent: Node3D, inner_r: float, outer_r: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mesh.rings = 32
	mesh.ring_segments = 32
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func add_capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	mesh.rings = 16
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func build_player_spongebob_model() -> Node3D:
	var root := Node3D.new()
	root.name = "PlayerSpongeBob3D"
	_build_spongebob_character(root, false)
	return root

func _build_spongebob_character(root: Node3D, include_pedestal: bool = false) -> void:
	var y_off: float = 0.22 if include_pedestal else 0.0
	var yellow_mat := make_mat(Color("#FCE92B"), 0.52, 0.0, Color("#F4D03F") * 0.14)
	var yellow_edge_mat := make_mat(Color("#F7DC4F"), 0.56, 0.0, Color("#D4AC0D") * 0.10)
	var pore_mat := make_mat(Color("#9FB01E"), 0.78)
	var pore_deep_mat := make_mat(Color("#7D8C14"), 0.85)
	var brown_mat := make_mat(Color("#874C1E"), 0.75)
	var white_mat := make_mat(Color("#FDFEFE"), 0.30)
	var black_mat := make_mat(Color("#141B22"), 0.22, 0.25)
	var shoe_shine_mat := make_mat(Color("#2C3E50"), 0.12, 0.45)
	var red_mat := make_mat(Color("#E52521"), 0.35, 0.0, Color("#C0392B") * 0.15)
	var blue_mat := make_mat(Color("#29ABE2"), 0.28)
	var cheek_mat := make_mat(Color("#F5B041"), 0.45)
	var mouth_dark_mat := make_mat(Color("#4A1212"), 0.75)
	var tongue_mat := make_mat(Color("#F1948A"), 0.50)
	var steel_mat := make_mat(Color("#D5D8DC"), 0.22, 0.85)

	# 1. Articulated Legs, Striped Crew Socks & Shiny Black Shoes (Pivots at Hip y = 0.50 + y_off)
	for side_i: int in [-1, 1]:
		var side_f: float = float(side_i)
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LeftLegPivot" if side_i < 0 else "RightLegPivot"
		leg_pivot.position = Vector3(side_f * 0.22, 0.50 + y_off, 0.0)
		root.add_child(leg_pivot)

		# Brown shorts cuff at top of leg
		add_cylinder(leg_pivot, 0.11, 0.10, 0.12, Vector3(0, -0.04, 0), brown_mat)
		# Thin yellow sponge leg
		add_cylinder(leg_pivot, 0.052, 0.050, 0.28, Vector3(0, -0.20, 0), yellow_mat)
		# White crew sock with iconic Red (top) and Blue (bottom) stripes
		add_cylinder(leg_pivot, 0.058, 0.056, 0.15, Vector3(0, -0.34, 0), white_mat)
		add_torus(leg_pivot, 0.046, 0.064, Vector3(0, -0.285, 0), red_mat)
		add_torus(leg_pivot, 0.046, 0.064, Vector3(0, -0.325, 0), blue_mat)
		# Iconic Shiny Black Rounded Shoe pointing forward (+Z)
		add_box(leg_pivot, Vector3(0.16, 0.11, 0.24), Vector3(0, -0.44, 0.03), black_mat)
		add_sphere(leg_pivot, 0.095, 0.12, Vector3(0, -0.435, 0.13), black_mat)
		add_sphere(leg_pivot, 0.04, 0.04, Vector3(-0.02, -0.40, 0.17), shoe_shine_mat)
		add_box(leg_pivot, Vector3(0.17, 0.03, 0.26), Vector3(0, -0.49, 0.03), shoe_shine_mat)

	# 2. Square Brown Pants, 4-Sided Black Belt Dashes & Crisp White Collared Shirt
	# Square Brown Pants (y = 0.50 .. 0.78)
	add_box(root, Vector3(1.04, 0.28, 0.58), Vector3(0, 0.64 + y_off, 0), brown_mat)
	# Black belt dashes around all 4 sides (Front +Z, Back -Z, Left -X, Right +X)
	for bx_belt: float in [-0.36, -0.12, 0.12, 0.36]:
		add_box(root, Vector3(0.16, 0.055, 0.03), Vector3(bx_belt, 0.66 + y_off, 0.295), black_mat)
		add_box(root, Vector3(0.16, 0.055, 0.03), Vector3(bx_belt, 0.66 + y_off, -0.295), black_mat)
	for bz_belt: float in [-0.14, 0.14]:
		add_box(root, Vector3(0.03, 0.055, 0.16), Vector3(-0.525, 0.66 + y_off, bz_belt), black_mat)
		add_box(root, Vector3(0.03, 0.055, 0.16), Vector3(0.525, 0.66 + y_off, bz_belt), black_mat)

	# Crisp White Shirt Band (y = 0.78 .. 0.96)
	add_box(root, Vector3(1.05, 0.18, 0.59), Vector3(0, 0.87 + y_off, 0), white_mat)
	# White V-Neck Collar Triangles on Front (+Z) & Collar Seam on Back (-Z)
	add_box(root, Vector3(0.24, 0.10, 0.04), Vector3(-0.18, 0.91 + y_off, 0.295), white_mat, Vector3(0, 0, 22))
	add_box(root, Vector3(0.24, 0.10, 0.04), Vector3(0.18, 0.91 + y_off, 0.295), white_mat, Vector3(0, 0, -22))
	add_box(root, Vector3(0.56, 0.06, 0.03), Vector3(0, 0.93 + y_off, -0.295), white_mat)

	# Iconic Red Necktie on Front (+Z)
	add_sphere(root, 0.065, 0.09, Vector3(0, 0.90 + y_off, 0.31), red_mat)
	add_box(root, Vector3(0.13, 0.24, 0.04), Vector3(0, 0.74 + y_off, 0.31), red_mat)
	add_box(root, Vector3(0.11, 0.11, 0.04), Vector3(0, 0.62 + y_off, 0.31), red_mat, Vector3(0, 0, 45))

	# 3. Scalloped Yellow Sponge Body with Olive-Green Pores on ALL 4 Sides + Top (y = 0.96 .. 2.08)
	# Lower & Upper Sponge Torso (slightly wider toward the top like SpongeBob's classic silhouette)
	add_box(root, Vector3(1.06, 0.56, 0.58), Vector3(0, 1.24 + y_off, 0), yellow_mat)
	add_box(root, Vector3(1.12, 0.60, 0.60), Vector3(0, 1.76 + y_off, 0), yellow_mat)

	# Wavy / Scalloped Sponge Edge Bumps along Top, Left, and Right rims
	for tx_w: float in [-0.44, -0.22, 0.0, 0.22, 0.44]:
		add_sphere(root, 0.15, 0.14, Vector3(tx_w, 2.05 + y_off, 0.0), yellow_mat)
		add_cylinder(root, 0.13, 0.13, 0.56, Vector3(tx_w, 2.04 + y_off, 0.0), yellow_mat, Vector3(90, 0, 0))
	for sy_w: float in [1.08, 1.32, 1.56, 1.80, 1.98]:
		var side_x_off: float = lerpf(0.52, 0.56, (sy_w - 1.08) / 0.90)
		for sx_dir: float in [-1.0, 1.0]:
			add_cylinder(root, 0.11, 0.11, 0.54, Vector3(sx_dir * side_x_off, sy_w + y_off, 0.0), yellow_edge_mat, Vector3(90, 0, 0))

	# Olive-Green Sponge Pores on Front (+Z), Back (-Z), Left (-X), Right (+X), and Top (+Y)
	var front_pores: Array[Dictionary] = [
		{"pos": Vector3(-0.42, 1.92, 0.305), "r": 0.085},
		{"pos": Vector3(0.43, 1.88, 0.305), "r": 0.075},
		{"pos": Vector3(-0.45, 1.56, 0.305), "r": 0.065},
		{"pos": Vector3(-0.38, 1.12, 0.295), "r": 0.090},
		{"pos": Vector3(0.40, 1.15, 0.295), "r": 0.080},
		{"pos": Vector3(0.28, 1.04, 0.295), "r": 0.050}
	]
	for fp: Dictionary in front_pores:
		var p_pos: Vector3 = fp["pos"] + Vector3(0, y_off, 0)
		add_cylinder(root, fp["r"], fp["r"], 0.02, p_pos, pore_mat, Vector3(90, 0, 0))
		add_cylinder(root, fp["r"] * 0.65, fp["r"] * 0.65, 0.024, p_pos, pore_deep_mat, Vector3(90, 0, 0))

	var back_pores: Array[Dictionary] = [
		{"pos": Vector3(-0.36, 1.88, -0.305), "r": 0.105},
		{"pos": Vector3(0.34, 1.84, -0.305), "r": 0.090},
		{"pos": Vector3(-0.12, 1.62, -0.305), "r": 0.075},
		{"pos": Vector3(0.38, 1.50, -0.305), "r": 0.110},
		{"pos": Vector3(-0.38, 1.32, -0.295), "r": 0.095},
		{"pos": Vector3(0.14, 1.18, -0.295), "r": 0.085},
		{"pos": Vector3(-0.22, 1.08, -0.295), "r": 0.065}
	]
	for bp: Dictionary in back_pores:
		var p_pos: Vector3 = bp["pos"] + Vector3(0, y_off, 0)
		add_cylinder(root, bp["r"], bp["r"], 0.02, p_pos, pore_mat, Vector3(90, 0, 0))
		add_cylinder(root, bp["r"] * 0.65, bp["r"] * 0.65, 0.024, p_pos, pore_deep_mat, Vector3(90, 0, 0))

	for side_s: float in [-1.0, 1.0]:
		add_cylinder(root, 0.085, 0.085, 0.03, Vector3(side_s * 0.61, 1.82 + y_off, -0.08), pore_mat, Vector3(0, 0, 90))
		add_cylinder(root, 0.070, 0.070, 0.03, Vector3(side_s * 0.59, 1.44 + y_off, 0.10), pore_mat, Vector3(0, 0, 90))
	add_cylinder(root, 0.08, 0.08, 0.03, Vector3(-0.28, 2.11 + y_off, -0.05), pore_mat)
	add_cylinder(root, 0.07, 0.07, 0.03, Vector3(0.26, 2.11 + y_off, 0.06), pore_mat)

	# 4. Iconic Expressive SpongeBob Face on Front (+Z)
	# Two Large Touching White Eyes with 3 Black Eyelashes Each
	for eye_side: float in [-1.0, 1.0]:
		var ex: float = eye_side * 0.21
		var ey: float = 1.66 + y_off
		add_sphere(root, 0.22, 0.42, Vector3(ex, ey, 0.22), white_mat)
		add_sphere(root, 0.115, 0.22, Vector3(ex * 0.92, ey, 0.36), blue_mat)
		add_sphere(root, 0.065, 0.13, Vector3(ex * 0.90, ey, 0.41), black_mat)
		add_sphere(root, 0.024, 0.048, Vector3(ex * 0.90 - 0.03, ey + 0.04, 0.45), white_mat)
		# 3 Iconic Black Eyelashes above each eye
		for lash_i: int in [-1, 0, 1]:
			var l_ang: float = float(lash_i) * 22.0
			var l_rad: float = deg_to_rad(l_ang)
			var lx: float = ex + sin(l_rad) * 0.16
			var ly: float = ey + 0.22 + cos(l_rad) * 0.04
			add_box(root, Vector3(0.032, 0.09, 0.032), Vector3(lx, ly, 0.31), black_mat, Vector3(0, 0, -l_ang))

	# Long Upturned Yellow Sponge Nose (+Z)
	add_cylinder(root, 0.042, 0.052, 0.38, Vector3(0, 1.53 + y_off, 0.44), yellow_mat, Vector3(78, 0, 0))
	add_sphere(root, 0.058, 0.115, Vector3(0, 1.57 + y_off, 0.61), yellow_mat)

	# Chubby Rosy Cheeks with 3 Red Freckles on Each Side
	for ch_side: float in [-1.0, 1.0]:
		var cx: float = ch_side * 0.36
		var cy: float = 1.43 + y_off
		add_sphere(root, 0.105, 0.18, Vector3(cx, cy, 0.28), yellow_edge_mat)
		add_torus(root, 0.075, 0.095, Vector3(cx, cy + 0.02, 0.32), cheek_mat, Vector3(90, 0, 0))
		for fk_off: Vector2 in [Vector2(-0.03, 0.02), Vector2(0.03, 0.02), Vector2(0.0, -0.02)]:
			add_sphere(root, 0.014, 0.028, Vector3(cx + fk_off.x, cy + fk_off.y, 0.35), red_mat)

	# Wide Cheerful Smile Arc, Iconic Buck Teeth Hanging from Upper Lip & Floor-Recessed Tongue
	# Dark interior mouth cavity
	add_box(root, Vector3(0.56, 0.14, 0.04), Vector3(0, 1.29 + y_off, 0.29), mouth_dark_mat)
	# Upper and lower smile outlines
	add_box(root, Vector3(0.60, 0.03, 0.042), Vector3(0, 1.36 + y_off, 0.308), black_mat)
	add_box(root, Vector3(0.48, 0.024, 0.038), Vector3(0, 1.22 + y_off, 0.306), black_mat)
	# Two cute pink tongue lobes sitting flat on mouth floor behind teeth (zero forward protrusion)
	for t_side: float in [-0.045, 0.045]:
		add_sphere(root, 0.048, 0.032, Vector3(t_side, 1.23 + y_off, 0.278), tongue_mat)
	# Two Prominent White Rectangular Buck Teeth hanging proudly from upper lip with center gap
	for tooth_x: float in [-0.068, 0.068]:
		add_box(root, Vector3(0.096, 0.092, 0.026), Vector3(tooth_x, 1.315 + y_off, 0.326), white_mat)
		add_box(root, Vector3(0.106, 0.102, 0.016), Vector3(tooth_x, 1.315 + y_off, 0.316), black_mat)

	# 5. Articulated Arms with White Short Sleeves, Hands & Fry-Cook Spatula (Pivots at Shoulder y = 1.24 + y_off)
	for arm_i: int in [-1, 1]:
		var arm_f: float = float(arm_i)
		var arm_pivot := Node3D.new()
		arm_pivot.name = "LeftArmPivot" if arm_i < 0 else "RightArmPivot"
		arm_pivot.position = Vector3(arm_f * 0.60, 1.22 + y_off, 0.0)
		root.add_child(arm_pivot)

		# Flared White Shirt Sleeve
		add_cylinder(arm_pivot, 0.085, 0.125, 0.18, Vector3(arm_f * 0.04, -0.04, 0), white_mat, Vector3(0, 0, arm_f * 14.0))
		# Thin Yellow Sponge Arm
		add_cylinder(arm_pivot, 0.045, 0.042, 0.34, Vector3(arm_f * 0.08, -0.26, 0), yellow_mat, Vector3(0, 0, arm_f * 8.0))
		# Yellow Sponge Hand & Thumb
		var hand_pos := Vector3(arm_f * 0.10, -0.44, 0.02)
		add_sphere(arm_pivot, 0.075, 0.14, hand_pos, yellow_mat)
		add_sphere(arm_pivot, 0.035, 0.07, hand_pos + Vector3(-arm_f * 0.05, 0.02, 0.05), yellow_mat)

		# Right hand holds SpongeBob's iconic Krusty Krab Fry-Cook Spatula pointing forward (+Z) & outward
		if arm_i > 0:
			var spat := Node3D.new()
			spat.name = "FrySpatula"
			spat.position = hand_pos + Vector3(0.04, 0.02, 0.08)
			spat.rotation_degrees = Vector3(42, -12, 10)
			arm_pivot.add_child(spat)
			add_cylinder(spat, 0.032, 0.036, 0.22, Vector3(0, 0.08, 0), black_mat)
			add_cylinder(spat, 0.022, 0.022, 0.28, Vector3(0, 0.30, 0), steel_mat)
			add_box(spat, Vector3(0.24, 0.30, 0.025), Vector3(0, 0.56, 0), steel_mat)
			for slot_x: float in [-0.06, 0.0, 0.06]:
				add_box(spat, Vector3(0.025, 0.18, 0.032), Vector3(slot_x, 0.56, 0), black_mat)

func _build_patrick_character(root: Node3D) -> void:
	# High-Fidelity Stylized Patrick Star 3D Model with Articulated Animation Pivots
	var skin_pink = make_mat(Color("#FF8E9C"), 0.55, 0.05)       # Soft warm coral-pink starfish skin
	var belly_pink = make_mat(Color("#FFA2AD"), 0.52, 0.05)      # Slightly highlighted soft pink for potbelly
	var shorts_lime = make_mat(Color("#7BD83E"), 0.65, 0.05)     # Chartreuse / lime green board shorts
	var shorts_cuff = make_mat(Color("#65BE2E"), 0.60, 0.05)     # Darker green waistband & cuffs
	var floral_purple = make_mat(Color("#8E44AD"), 0.55, 0.05)   # Hawaiian tropical purple flower print
	var navel_mat = make_mat(Color("#D64558"), 0.6, 0.0)         # Dimpled belly button shadow
	var white_mat = make_mat(Color.WHITE, 0.25)
	var black_mat = make_mat(Color("#151515"), 0.2)
	var mouth_dark = make_mat(Color("#64142B"), 0.65)            # Deep cartoon mouth cavity
	var tongue_mat = make_mat(Color("#FF6584"), 0.5)             # Rosy pink tongue
	var eyebrow_mat = make_mat(Color("#1A1A1A"), 0.25)           # Thick expressive eyebrows
	var speckle_mat = make_mat(Color("#D95B6A"), 0.6)

	# 1. Chunky Starfish Legs & Stubby Feet resting on Pedestal
	for leg_dir: float in [-1.0, 1.0]:
		# Leg cuff opening
		add_cylinder(root, 0.23, 0.25, 0.18, Vector3(leg_dir * 0.24, 0.44, 0.0), shorts_cuff, Vector3(0, 0, leg_dir * 8.0))
		# Starfish leg (smooth capsule)
		add_capsule(root, 0.15, 0.34, Vector3(leg_dir * 0.24, 0.29, 0.0), skin_pink, Vector3(0, 0, leg_dir * 8.0))
		# Rounded starfish foot
		add_sphere(root, 0.14, 0.12, Vector3(leg_dir * 0.25, 0.16, 0.04), skin_pink)

	# 2. Iconic Lime Green Hawaiian Board Shorts (y = 0.48 .. 0.82)
	add_cylinder(root, 0.60, 0.52, 0.40, Vector3(0, 0.62, 0.0), shorts_lime)
	# Rolled waistband ring curving below belly
	add_torus(root, 0.52, 0.60, Vector3(0, 0.80, 0.0), shorts_cuff, Vector3(90, 0, 0))

	# Hawaiian Purple Flower Prints on Shorts
	for rot_p: float in [0.0, 60.0, 120.0]:
		add_box(root, Vector3(0.09, 0.035, 0.02), Vector3(-0.26, 0.62, 0.49), floral_purple, Vector3(10, -15, rot_p))
	for rot_p: float in [20.0, 80.0, 140.0]:
		add_box(root, Vector3(0.08, 0.035, 0.02), Vector3(0.25, 0.56, 0.49), floral_purple, Vector3(10, 15, rot_p))
	add_box(root, Vector3(0.03, 0.09, 0.09), Vector3(-0.54, 0.58, 0.05), floral_purple, Vector3(0, 0, 30))
	add_box(root, Vector3(0.03, 0.09, 0.09), Vector3(0.54, 0.60, -0.05), floral_purple, Vector3(0, 0, -30))
	add_box(root, Vector3(0.10, 0.04, 0.03), Vector3(0.0, 0.63, -0.53), floral_purple)

	# 3. Dedicated Articulated BodyPivot (Animated for Breathing, Idle Sway & Attack Slams)
	var body_pivot = Node3D.new()
	body_pivot.name = "BodyPivot"
	body_pivot.position = Vector3(0, 0.72, 0)
	root.add_child(body_pivot)

	# Potbelly & Navel
	add_sphere(body_pivot, 0.58, 0.62, Vector3(0, 0.22, 0.0), skin_pink)
	add_sphere(body_pivot, 0.40, 0.44, Vector3(0, 0.20, 0.22), belly_pink)
	add_cylinder(body_pivot, 0.028, 0.035, 0.04, Vector3(0, 0.20, 0.49), navel_mat, Vector3(90, 0, 0))
	add_torus(body_pivot, 0.028, 0.046, Vector3(0, 0.20, 0.485), skin_pink, Vector3(90, 0, 0))

	# Mid Torso & Pointed Starfish Cone Head with Classic Backward Tilt
	add_cylinder(body_pivot, 0.44, 0.58, 0.50, Vector3(0, 0.53, 0.0), skin_pink)
	add_cylinder(body_pivot, 0.16, 0.44, 0.65, Vector3(0, 0.96, -0.04), skin_pink, Vector3(-6, 0, 0))
	add_cylinder(body_pivot, 0.04, 0.16, 0.32, Vector3(0, 1.34, -0.10), skin_pink, Vector3(-10, 0, 0))
	add_sphere(body_pivot, 0.065, 0.08, Vector3(0, 1.50, -0.14), skin_pink)

	# 4. Articulated Starfish Arm Pivots
	# Left Arm Pivot (Animated for idle waving / bobbing)
	var left_arm = Node3D.new()
	left_arm.name = "LeftArmPivot"
	left_arm.position = Vector3(-0.48, 0.56, 0.06)
	body_pivot.add_child(left_arm)
	add_capsule(left_arm, 0.12, 0.44, Vector3(-0.16, 0.12, 0.0), skin_pink, Vector3(-10, 12, 54))
	add_capsule(left_arm, 0.10, 0.38, Vector3(-0.36, 0.32, 0.08), skin_pink, Vector3(12, -6, 26))
	add_sphere(left_arm, 0.12, 0.15, Vector3(-0.46, 0.50, 0.12), skin_pink)

	# Right Arm Pivot (Animated for Karate Slam & Punches)
	var right_arm = Node3D.new()
	right_arm.name = "RightArmPivot"
	right_arm.position = Vector3(0.48, 0.56, 0.06)
	body_pivot.add_child(right_arm)
	add_capsule(right_arm, 0.12, 0.44, Vector3(0.16, 0.12, 0.0), skin_pink, Vector3(-10, -12, -54))
	add_capsule(right_arm, 0.10, 0.38, Vector3(0.32, 0.08, 0.18), skin_pink, Vector3(60, 18, -16))
	add_sphere(right_arm, 0.12, 0.15, Vector3(0.40, 0.06, 0.36), skin_pink)

	# 5. Classic Expressive Patrick Face on Front (+Z)
	for eye_dir: float in [-1.0, 1.0]:
		var ex: float = eye_dir * 0.13
		add_sphere(body_pivot, 0.135, 0.22, Vector3(ex, 0.90, 0.31), white_mat)
		add_sphere(body_pivot, 0.055, 0.08, Vector3(ex * 0.85, 0.90, 0.41), black_mat)
		add_sphere(body_pivot, 0.020, 0.03, Vector3(ex * 0.85 - 0.015, 0.925, 0.44), white_mat)
		add_sphere(body_pivot, 0.138, 0.10, Vector3(ex, 0.99, 0.32), skin_pink)

	# Signature Thick Zigzag "Z" Eyebrows
	add_box(body_pivot, Vector3(0.10, 0.030, 0.025), Vector3(-0.16, 1.06, 0.28), eyebrow_mat, Vector3(0, 0, 26))
	add_box(body_pivot, Vector3(0.08, 0.030, 0.025), Vector3(-0.09, 1.10, 0.27), eyebrow_mat, Vector3(0, 0, -34))
	add_box(body_pivot, Vector3(0.10, 0.030, 0.025), Vector3(0.16, 1.06, 0.28), eyebrow_mat, Vector3(0, 0, -26))
	add_box(body_pivot, Vector3(0.08, 0.030, 0.025), Vector3(0.09, 1.10, 0.27), eyebrow_mat, Vector3(0, 0, 34))

	# Goofy Happy Open Smile & Pink Tongue
	add_cylinder(body_pivot, 0.17, 0.09, 0.08, Vector3(0, 0.65, 0.37), mouth_dark, Vector3(82, 0, 0))
	add_box(body_pivot, Vector3(0.36, 0.024, 0.03), Vector3(0, 0.72, 0.39), black_mat)
	add_box(body_pivot, Vector3(0.24, 0.020, 0.03), Vector3(0, 0.58, 0.36), black_mat)
	add_sphere(body_pivot, 0.075, 0.05, Vector3(0, 0.62, 0.38), tongue_mat)
	add_sphere(body_pivot, 0.045, 0.04, Vector3(-0.21, 0.71, 0.36), skin_pink)
	add_sphere(body_pivot, 0.045, 0.04, Vector3(0.21, 0.71, 0.36), skin_pink)

	# Skin Freckles / Speckles on Back (-Z)
	for sp_pos: Vector3 in [
		Vector3(-0.22, 0.63, -0.42),
		Vector3(0.18, 0.68, -0.40),
		Vector3(-0.12, 0.90, -0.32),
		Vector3(0.14, 1.00, -0.28),
		Vector3(-0.05, 0.43, -0.48)
	]:
		add_sphere(body_pivot, 0.035, 0.03, sp_pos, speckle_mat)

func build_tower_model(tower_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "Model3D"
	
	# Base Pedestal
	var ped_mat = make_mat(Color("#5D6D7E"), 0.7, 0.2)
	add_cylinder(root, 0.85, 0.95, 0.25, Vector3(0, 0.125, 0), ped_mat)
	
	var white_mat = make_mat(Color.WHITE, 0.3)
	var black_mat = make_mat(Color("#17202A"), 0.2)
	
	match tower_id:
		"spongebob":
			_build_spongebob_character(root, true)
			
		"patrick":
			_build_patrick_character(root)
			
		"squidward":
			var teal_mat = make_mat(Color("#73C6B6"), 0.5)
			var shirt_mat = make_mat(Color("#B9770E"), 0.7)
			# Torso
			add_cylinder(root, 0.35, 0.4, 0.85, Vector3(0, 0.75, 0), shirt_mat)
			# Big Head
			add_sphere(root, 0.55, 0.95, Vector3(0, 1.65, 0), teal_mat)
			# Droopy Nose
			add_cylinder(root, 0.08, 0.14, 0.5, Vector3(0, 1.45, 0.48), teal_mat, Vector3(20, 0, 0))
			# Clarinet
			add_cylinder(root, 0.04, 0.09, 0.8, Vector3(0.35, 1.15, 0.45), black_mat, Vector3(45, 0, 0))
			
		"mr_krabs":
			var red_mat = make_mat(Color("#E74C3C"), 0.4, 0.1)
			var shirt_mat = make_mat(Color("#3498DB"), 0.6)
			var gold_mat = make_mat(Color("#F1C40F"), 0.2, 0.9, Color("#B7950B"))
			# Body
			add_sphere(root, 0.65, 1.1, Vector3(0, 0.95, 0), red_mat)
			add_cylinder(root, 0.62, 0.66, 0.45, Vector3(0, 0.8, 0), shirt_mat)
			# Belt buckle
			add_box(root, Vector3(0.25, 0.18, 0.1), Vector3(0, 0.65, 0.62), gold_mat)
			# Tall Eye Stalks
			add_cylinder(root, 0.08, 0.08, 0.65, Vector3(-0.2, 1.75, 0.15), red_mat)
			add_cylinder(root, 0.08, 0.08, 0.65, Vector3(0.2, 1.75, 0.15), red_mat)
			add_sphere(root, 0.12, 0.24, Vector3(-0.2, 2.05, 0.22), white_mat)
			add_sphere(root, 0.12, 0.24, Vector3(0.2, 2.05, 0.22), white_mat)
			# Big Claws
			add_sphere(root, 0.32, 0.64, Vector3(-0.75, 1.15, 0.35), red_mat)
			add_sphere(root, 0.32, 0.64, Vector3(0.75, 1.15, 0.35), red_mat)
			
		"sandy":
			var suit_mat = make_mat(Color("#ECF0F1"), 0.4, 0.2)
			var fur_mat = make_mat(Color("#D35400"), 0.7)
			var glass_mat = make_mat(Color("#D6EAF8"), 0.1, 0.1, Color.BLACK, 0.42)
			var pink_mat = make_mat(Color("#FF69B4"), 0.4)
			# Suit
			add_cylinder(root, 0.42, 0.48, 1.0, Vector3(0, 0.8, 0), suit_mat)
			# Head inside
			add_sphere(root, 0.38, 0.76, Vector3(0, 1.65, 0), fur_mat)
			# Glass Helmet
			add_sphere(root, 0.6, 1.2, Vector3(0, 1.65, 0), glass_mat)
			# Pink Flower
			add_sphere(root, 0.18, 0.2, Vector3(0.35, 2.15, 0.15), pink_mat)
			
		"flying_dutchman":
			var ghost_mat = make_mat(Color("#2ECC71"), 0.2, 0.0, Color("#27AE60"), 0.85)
			var hat_mat = make_mat(Color("#145A32"), 0.5, 0.0, Color("#1E8449"))
			# Ghost Tail & Body
			add_cylinder(root, 0.55, 0.1, 1.5, Vector3(0, 1.0, 0), ghost_mat)
			# Head & Beard
			add_sphere(root, 0.48, 0.96, Vector3(0, 1.85, 0), ghost_mat)
			# Pirate Hat
			add_box(root, Vector3(1.1, 0.35, 0.6), Vector3(0, 2.35, 0), hat_mat)
			
		"gary":
			var shell_mat = make_mat(Color("#F5B7B1"), 0.4)
			var body_mat = make_mat(Color("#5DADE2"), 0.6)
			add_box(root, Vector3(0.7, 0.22, 1.1), Vector3(0, 0.35, 0), body_mat)
			add_sphere(root, 0.52, 0.95, Vector3(0, 0.85, -0.1), shell_mat)
			add_cylinder(root, 0.04, 0.04, 0.55, Vector3(-0.14, 0.75, 0.42), body_mat)
			add_cylinder(root, 0.04, 0.04, 0.55, Vector3(0.14, 0.75, 0.42), body_mat)
			add_sphere(root, 0.11, 0.22, Vector3(-0.14, 1.08, 0.42), white_mat)
			add_sphere(root, 0.11, 0.22, Vector3(0.14, 1.08, 0.42), white_mat)
			
		"mrs_puff":
			var puff_mat = make_mat(Color("#F9E79F"), 0.5)
			var hat_mat = make_mat(Color("#3498DB"), 0.5)
			add_sphere(root, 0.68, 1.25, Vector3(0, 1.15, 0), puff_mat)
			add_cylinder(root, 0.35, 0.4, 0.22, Vector3(0, 1.88, 0), hat_mat)
			add_sphere(root, 0.13, 0.26, Vector3(-0.2, 1.32, 0.56), white_mat)
			add_sphere(root, 0.13, 0.26, Vector3(0.2, 1.32, 0.56), white_mat)
			
		"larry_lobster":
			var lob_mat = make_mat(Color("#C0392B"), 0.35, 0.15)
			var trunk_mat = make_mat(Color("#F1C40F"), 0.6)
			add_cylinder(root, 0.45, 0.35, 0.45, Vector3(0, 0.5, 0), trunk_mat)
			add_cylinder(root, 0.7, 0.45, 0.95, Vector3(0, 1.2, 0), lob_mat)
			add_sphere(root, 0.36, 0.65, Vector3(0, 1.9, 0), lob_mat)
			add_sphere(root, 0.36, 0.7, Vector3(-0.78, 1.3, 0.35), lob_mat)
			add_sphere(root, 0.36, 0.7, Vector3(0.78, 1.3, 0.35), lob_mat)
			
		"plankton_mech":
			var plk_mat = make_mat(Color("#117864"), 0.4, 0.2)
			var eye_mat = make_mat(Color("#FF3B30"), 0.1, 0.0, Color("#FF1744"))
			add_cylinder(root, 0.34, 0.36, 1.1, Vector3(0, 0.95, 0), plk_mat)
			add_sphere(root, 0.18, 0.36, Vector3(0, 1.15, 0.32), eye_mat)
			add_cylinder(root, 0.03, 0.04, 0.55, Vector3(-0.18, 1.75, 0), plk_mat, Vector3(0, 0, 18))
			add_cylinder(root, 0.03, 0.04, 0.55, Vector3(0.18, 1.75, 0), plk_mat, Vector3(0, 0, -18))
			
		"karen_2":
			var stand_mat = make_mat(Color("#566573"), 0.3, 0.8)
			var screen_mat = make_mat(Color("#0B2631"), 0.2, 0.3, Color("#2ECC71"))
			add_cylinder(root, 0.15, 0.45, 1.0, Vector3(0, 0.75, 0), stand_mat)
			add_box(root, Vector3(1.1, 0.8, 0.45), Vector3(0, 1.65, 0), stand_mat)
			add_box(root, Vector3(0.92, 0.62, 0.08), Vector3(0, 1.65, 0.22), screen_mat)
			
		_:
			var t_data = GameData.TOWERS.get(tower_id, {})
			var main_col: Color = t_data.get("color", Color("#3498DB"))
			var atk_col: Color = t_data.get("attack_color", Color("#00FFAA"))
			var rarity: int = t_data.get("rarity", GameData.Rarity.COMMON)
			var emit_col: Color = atk_col * 0.65 if rarity >= GameData.Rarity.LEGENDARY else Color.BLACK
			var body_mat = make_mat(main_col, 0.35, 0.25, emit_col)
			var accent_mat = make_mat(atk_col, 0.2, 0.5, atk_col * 0.5)
			add_cylinder(root, 0.48, 0.56, 1.15, Vector3(0, 0.85, 0), body_mat)
			add_sphere(root, 0.46, 0.88, Vector3(0, 1.75, 0), body_mat)
			add_sphere(root, 0.14, 0.28, Vector3(-0.18, 1.8, 0.38), white_mat)
			add_sphere(root, 0.14, 0.28, Vector3(0.18, 1.8, 0.38), white_mat)
			add_sphere(root, 0.07, 0.14, Vector3(-0.18, 1.8, 0.48), black_mat)
			add_sphere(root, 0.07, 0.14, Vector3(0.18, 1.8, 0.48), black_mat)
			if rarity >= GameData.Rarity.LEGENDARY:
				add_torus(root, 0.55, 0.68, Vector3(0, 2.35, 0), accent_mat)
			
	return root

func build_enemy_model(enemy_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "EnemyModel3D"
	
	match enemy_id:
		"jellyfish_pink", "jellyfish_blue":
			var col = Color("#FF69B4") if enemy_id == "jellyfish_pink" else Color("#00BFFF")
			var emit = Color("#C71585") if enemy_id == "jellyfish_pink" else Color("#0077BE")
			var j_mat = make_mat(col, 0.2, 0.1, emit, 0.88)
			# Jellyfish Bell Dome
			add_sphere(root, 0.55, 0.9, Vector3(0, 1.1, 0), j_mat)
			# 4 Tentacles
			for pos_x in [-0.22, 0.22]:
				for pos_z in [-0.22, 0.22]:
					add_cylinder(root, 0.04, 0.02, 0.7, Vector3(pos_x, 0.55, pos_z), j_mat)
					
		"robot_worker", "robot_enforcer":
			var is_enf = (enemy_id == "robot_enforcer")
			var metal_col = Color("#2C3E50") if is_enf else Color("#7F8C8D")
			var m_mat = make_mat(metal_col, 0.25, 0.85)
			var eye_mat = make_mat(Color("#E74C3C"), 0.1, 0.0, Color("#FF0000"))
			var s = 1.35 if is_enf else 1.0
			add_box(root, Vector3(0.8, 1.1, 0.7) * s, Vector3(0, 0.75 * s, 0), m_mat)
			add_sphere(root, 0.22 * s, 0.44 * s, Vector3(0, 0.9 * s, 0.36 * s), eye_mat)
			
		"mecha_plankton_boss":
			var boss_mat = make_mat(Color("#1E8449"), 0.2, 0.9, Color("#117A65"))
			var tread_mat = make_mat(Color("#17202A"), 0.6, 0.5)
			var laser_mat = make_mat(Color("#FF0000"), 0.1, 0.0, Color("#FF3300"))
			# Treads
			add_box(root, Vector3(2.2, 0.6, 2.4), Vector3(0, 0.3, 0), tread_mat)
			# Giant Chassis
			add_cylinder(root, 1.1, 1.3, 2.4, Vector3(0, 1.6, 0), boss_mat)
			# Giant Cyclops Laser Eye
			add_sphere(root, 0.55, 1.1, Vector3(0, 1.9, 1.05), laser_mat)
			# Antennae
			add_cylinder(root, 0.05, 0.08, 1.2, Vector3(-0.5, 3.2, 0), boss_mat, Vector3(0, 0, 15))
			add_cylinder(root, 0.05, 0.08, 1.2, Vector3(0.5, 3.2, 0), boss_mat, Vector3(0, 0, -15))

		# Zone 2: Inside The Krusty Krab Enemies
		"patty_thief_anchovy":
			var fish_mat = make_mat(Color("#5DADE2"), 0.3, 0.2)
			var eye_mat = make_mat(Color.WHITE, 0.1)
			var pupil_mat = make_mat(Color.BLACK, 0.1)
			var bun_mat = make_mat(Color("#D35400"), 0.6)
			var patty_mat = make_mat(Color("#562506"), 0.8)
			# Long silvery anchovy fish body
			add_cylinder(root, 0.16, 0.22, 0.95, Vector3(0, 0.65, 0), fish_mat, Vector3(85, 0, 0))
			# Tail fin
			add_box(root, Vector3(0.04, 0.38, 0.26), Vector3(0, 0.68, -0.62), fish_mat, Vector3(25, 0, 0))
			# Big cartoon bug-eyes
			for es in [-0.14, 0.14]:
				add_sphere(root, 0.10, 0.18, Vector3(es, 0.75, 0.42), eye_mat)
				add_sphere(root, 0.05, 0.10, Vector3(es * 1.1, 0.75, 0.50), pupil_mat)
			# Stolen Krabby Patty held in mouth!
			add_cylinder(root, 0.18, 0.18, 0.06, Vector3(0, 0.55, 0.60), bun_mat)
			add_cylinder(root, 0.19, 0.19, 0.04, Vector3(0, 0.59, 0.60), patty_mat)
			add_cylinder(root, 0.17, 0.17, 0.05, Vector3(0, 0.63, 0.60), bun_mat)

		"robo_spatula":
			var chrome_mat = make_mat(Color("#BDC3C7"), 0.2, 0.85)
			var blade_mat = make_mat(Color("#ECF0F1"), 0.15, 0.95)
			var dark_mat = make_mat(Color("#2C3E50"), 0.5, 0.4)
			var eye_mat = make_mat(Color("#E74C3C"), 0.1, 0.0, Color("#FF0000"), 0.9)
			# Drone sphere head
			add_sphere(root, 0.32, 0.55, Vector3(0, 1.25, 0), chrome_mat)
			# Blinking red sensor eye
			add_sphere(root, 0.12, 0.22, Vector3(0, 1.28, 0.26), eye_mat)
			# Spinning rotor on top
			add_cylinder(root, 0.04, 0.04, 0.22, Vector3(0, 1.62, 0), dark_mat)
			add_box(root, Vector3(1.1, 0.03, 0.12), Vector3(0, 1.74, 0), dark_mat)
			# Twin sharp spatula blade arms pointing down
			for ss in [-0.38, 0.38]:
				add_cylinder(root, 0.035, 0.035, 0.45, Vector3(ss, 0.95, 0.1), chrome_mat, Vector3(35, 0, ss * -15))
				add_box(root, Vector3(0.24, 0.35, 0.02), Vector3(ss * 1.15, 0.65, 0.28), blade_mat)

		"grease_gremlin":
			var grease_mat = make_mat(Color("#784212"), 0.25, 0.1, Color("#B9770E"), 0.3)
			var eye_mat = make_mat(Color("#F1C40F"), 0.1, 0.0, Color("#F39C12"), 0.9)
			var pipe_mat = make_mat(Color("#1C2833"), 0.7, 0.6)
			# Armored sludge body (bulbous base and molten ripples)
			add_sphere(root, 0.65, 1.1, Vector3(0, 0.75, 0), grease_mat)
			add_sphere(root, 0.52, 0.85, Vector3(0, 1.25, 0), grease_mat)
			# Twin heavy exhaust smokestacks
			for ps in [-0.32, 0.32]:
				add_cylinder(root, 0.08, 0.10, 0.55, Vector3(ps, 1.65, -0.22), pipe_mat, Vector3(-18, 0, 0))
			# Glowing yellow eyes
			for es in [-0.20, 0.20]:
				add_sphere(root, 0.11, 0.20, Vector3(es, 1.35, 0.42), eye_mat)

		"chum_infiltrator":
			var spy_mat = make_mat(Color("#2C3E50"), 0.4, 0.5)
			var visor_mat = make_mat(Color("#1ABC9C"), 0.1, 0.0, Color("#16A085"), 0.95)
			var stache_mat = make_mat(Color("#17202A"), 0.9, 0.1)
			var drill_mat = make_mat(Color("#95A5A6"), 0.2, 0.8)
			# Cylinder body in dark trenchcoat tone
			add_cylinder(root, 0.38, 0.42, 1.2, Vector3(0, 0.85, 0), spy_mat)
			# Glowing cyan night-vision visor
			add_box(root, Vector3(0.55, 0.14, 0.16), Vector3(0, 1.28, 0.35), visor_mat)
			# Comic fake mustache
			add_box(root, Vector3(0.36, 0.08, 0.08), Vector3(0, 1.10, 0.40), stache_mat)
			# Infiltration safe-cracking drill arm
			add_cylinder(root, 0.03, 0.10, 0.45, Vector3(0.42, 0.75, 0.32), drill_mat, Vector3(80, 0, 0))

		"robo_krabs_boss":
			var red_bot_mat = make_mat(Color("#C0392B"), 0.2, 0.8, Color("#922B21"), 0.2)
			var steel_mat = make_mat(Color("#34495E"), 0.3, 0.8)
			var gold_mat = make_mat(Color("#F1C40F"), 0.25, 0.9, Color("#D4AC0D"), 0.4)
			var eye_glow = make_mat(Color("#E74C3C"), 0.1, 0.0, Color("#FF0000"), 0.95)
			# Bulky mechanical crab torso
			add_box(root, Vector3(2.4, 1.3, 1.6), Vector3(0, 1.1, 0), red_bot_mat)
			# Coin slot chest plate
			add_box(root, Vector3(0.9, 0.7, 0.12), Vector3(0, 1.1, 0.85), gold_mat)
			add_box(root, Vector3(0.4, 0.08, 0.14), Vector3(0, 1.15, 0.86), steel_mat)
			# 4 Robotic walking legs
			for ls in [-1.0, -0.35, 0.35, 1.0]:
				add_cylinder(root, 0.08, 0.06, 0.9, Vector3(ls, 0.4, -0.6), steel_mat, Vector3(-35, 0, ls * 12))
			# Twin giant hydraulic cutting pincers
			for cs in [-1.4, 1.4]:
				add_cylinder(root, 0.14, 0.14, 0.7, Vector3(cs, 1.2, 0.5), steel_mat, Vector3(45, 0, cs * 15))
				add_box(root, Vector3(0.35, 0.55, 0.18), Vector3(cs * 1.15, 1.35, 0.9), red_bot_mat)
				add_box(root, Vector3(0.20, 0.40, 0.12), Vector3(cs * 1.15, 1.70, 0.95), red_bot_mat)
			# Periscope robot eye stalks
			for es in [-0.45, 0.45]:
				add_cylinder(root, 0.06, 0.06, 0.8, Vector3(es, 2.0, 0.3), steel_mat)
				add_sphere(root, 0.18, 0.35, Vector3(es, 2.45, 0.35), eye_glow)

		# Zone 3: Inside Squidward's Moai Art Salon Enemies
		"abstract_art_creep":
			var teal_art = make_mat(Color("#16A085"), 0.2, 0.6, Color("#1ABC9C"), 0.4)
			var gold_ring = make_mat(Color("#F39C12"), 0.15, 0.9)
			var purple_art = make_mat(Color("#8E44AD"), 0.2, 0.3)
			# Floating rotating cubist diamond
			add_box(root, Vector3(0.75, 0.75, 0.75), Vector3(0, 1.15, 0), teal_art, Vector3(45, 45, 25))
			add_torus(root, 0.55, 0.65, Vector3(0, 1.15, 0), gold_ring, Vector3(65, 20, 0))
			add_cylinder(root, 0.22, 0.35, 0.6, Vector3(0, 0.3, 0), purple_art)

		"dissonant_note_drone":
			var note_mat = make_mat(Color("#2C3E50"), 0.3, 0.4)
			var wave_mat = make_mat(Color("#9B59B6"), 0.1, 0.0, Color("#8E44AD"), 0.9)
			# Musical eighth-note head
			add_sphere(root, 0.38, 0.65, Vector3(-0.15, 0.85, 0), note_mat, Vector3(0, 0, 30))
			# Vertical note stem & flag
			add_cylinder(root, 0.05, 0.05, 1.1, Vector3(0.12, 1.45, 0), note_mat)
			add_box(root, Vector3(0.35, 0.25, 0.06), Vector3(0.28, 1.9, 0), note_mat, Vector3(0, 0, -25))
			# Shockwave sonic aura ring
			add_torus(root, 0.65, 0.75, Vector3(0, 1.1, 0), wave_mat, Vector3(90, 0, 0))

		"robo_clarinetist":
			var brass_mat = make_mat(Color("#E67E22"), 0.2, 0.85)
			var wood_mat = make_mat(Color("#1B2631"), 0.6, 0.2)
			var silver_mat = make_mat(Color("#BDC3C7"), 0.15, 0.95)
			var eye_mat = make_mat(Color("#E74C3C"), 0.1, 0.0, Color("#FF0000"), 0.9)
			# Metallic android torso
			add_cylinder(root, 0.32, 0.38, 1.1, Vector3(0, 0.85, 0), brass_mat)
			add_sphere(root, 0.25, 0.45, Vector3(0, 1.55, 0), brass_mat)
			add_sphere(root, 0.08, 0.15, Vector3(0, 1.58, 0.22), eye_mat)
			# Mounted playing clarinet extending forward
			add_cylinder(root, 0.035, 0.045, 1.05, Vector3(0, 1.35, 0.65), wood_mat, Vector3(72, 0, 0))
			# Clarinet flared bell horn
			add_cylinder(root, 0.12, 0.05, 0.22, Vector3(0, 1.20, 1.15), silver_mat, Vector3(72, 0, 0))

		"tentacle_heavy_mech":
			var stone_mat = make_mat(Color("#5D6D7E"), 0.7, 0.3)
			var armor_mat = make_mat(Color("#2E4053"), 0.35, 0.75)
			var eye_mat = make_mat(Color("#3498DB"), 0.1, 0.0, Color("#2980B9"), 0.95)
			# Moai-inspired stone mech turret
			add_cylinder(root, 0.75, 0.95, 1.4, Vector3(0, 1.45, 0), stone_mat)
			add_box(root, Vector3(0.7, 0.18, 0.2), Vector3(0, 1.65, 0.85), eye_mat)
			# 6 Heavy articulated mechanical tentacles
			for t_i in range(6):
				var a_rad = deg_to_rad(float(t_i) * 60.0)
				var tx = sin(a_rad) * 0.95
				var tz = cos(a_rad) * 0.95
				add_cylinder(root, 0.11, 0.07, 1.1, Vector3(tx, 0.55, tz), armor_mat, Vector3(sin(a_rad) * 28, 0, cos(a_rad) * -28))

		"squidward_critic_boss":
			var critic_mat = make_mat(Color("#6C5CE7"), 0.3, 0.5, Color("#4834D4"), 0.3)
			var beret_mat = make_mat(Color("#A29BFE"), 0.5, 0.2)
			var gold_mono = make_mat(Color("#FDCB6E"), 0.15, 0.95)
			var palette_mat = make_mat(Color("#D63031"), 0.4, 0.1)
			var brush_mat = make_mat(Color("#0984E3"), 0.3, 0.3)
			# Colossal snobbish critic torso & head
			add_box(root, Vector3(2.2, 1.8, 1.4), Vector3(0, 1.4, 0), critic_mat)
			add_sphere(root, 0.75, 1.3, Vector3(0, 2.7, 0.2), critic_mat)
			# Elegant Parisian art beret hat tilted on head
			add_sphere(root, 0.95, 0.45, Vector3(-0.25, 3.45, 0.1), beret_mat, Vector3(15, 0, -25))
			# Golden snobbish monocle
			add_torus(root, 0.22, 0.28, Vector3(0.35, 2.75, 0.8), gold_mono, Vector3(90, 0, 0))
			# Giant wooden painter's palette shield on left hand
			add_cylinder(root, 0.95, 0.95, 0.08, Vector3(-1.6, 1.6, 0.6), palette_mat, Vector3(0, 0, 75))
			# Gigantic paintbrush club on right hand
			add_cylinder(root, 0.08, 0.12, 2.4, Vector3(1.6, 1.8, 0.5), brush_mat, Vector3(45, 0, -20))
			
	return root

var _pineapple_texture_cache: ImageTexture = null

func get_pineapple_texture() -> ImageTexture:
	if _pineapple_texture_cache != null:
		return _pineapple_texture_cache
	
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var base_col1 = Color("#E67E22")
	var base_col2 = Color("#F39C12")
	var line_col = Color("#78350A")
	var line_edge = Color("#9A4B12")
	var speck_col = Color("#512304")
	var highlight_col = Color("#FAD7A0")
	var spacing: int = 32
	
	for y in range(256):
		var y_ratio = float(y) / 256.0
		var base_c = base_col1.lerp(base_col2, sin(y_ratio * PI))
		for x in range(256):
			var d1 = (x + y) % spacing
			var d2 = (x - y + 512) % spacing
			var is_line = (d1 <= 2 or d1 >= spacing - 2 or d2 <= 2 or d2 >= spacing - 2)
			var is_edge = (d1 <= 3 or d1 >= spacing - 3 or d2 <= 3 or d2 >= spacing - 3)
			
			if is_line:
				img.set_pixel(x, y, line_col)
			elif is_edge:
				img.set_pixel(x, y, line_edge)
			else:
				var center_dist = abs(d1 - spacing / 2) + abs(d2 - spacing / 2)
				if center_dist < 4:
					img.set_pixel(x, y, base_c.lerp(highlight_col, 0.45))
				elif d1 > 10 and d1 < 14 and d2 > 10 and d2 < 14:
					img.set_pixel(x, y, speck_col)
				else:
					img.set_pixel(x, y, base_c)
					
	_pineapple_texture_cache = ImageTexture.create_from_image(img)
	return _pineapple_texture_cache

var _seabed_sand_texture_cache: ImageTexture = null
var _seabed_normal_texture_cache: ImageTexture = null
var _seabed_material_cache: StandardMaterial3D = null

func get_seabed_sand_material() -> StandardMaterial3D:
	if _seabed_material_cache != null:
		return _seabed_material_cache
	
	var tex_size = 512
	var img = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	var norm_img = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	
	var base_sand = Color("#EAD39E")     # Warm golden tropical sand
	var shadow_sand = Color("#C4A56B")   # Ripple trough shadow
	var crest_sand = Color("#F6E5B8")    # Sunlit ripple crest
	var caustic_col = Color("#FFF6DE")   # Prismatic underwater water caustics
	var shell_col = Color("#FFFDF5")     # Tiny crushed shell speckle
	var pebble_col = Color("#8A6F44")    # Tiny dark pebble speckle
	
	# Generate 512x512 Seamless Procedural Seabed Sand & Normal Map
	for y in range(tex_size):
		var v = float(y) / float(tex_size)
		var theta_v = v * 2.0 * PI
		for x in range(tex_size):
			var u = float(x) / float(tex_size)
			var theta_u = u * 2.0 * PI
			
			# Multi-harmonic seamless sinusoidal sand ripples
			var w1 = sin(theta_u * 4.0 + cos(theta_v * 2.0) * 1.5)
			var w2 = sin(theta_u * 8.0 - theta_v * 4.0) * 0.35
			var w3 = cos(theta_u * 2.0 + theta_v * 6.0) * 0.20
			var ripple = (w1 + w2 + w3) / 1.55 # normalized ~ -1 to +1
			
			# Natural caustic light web (refracted ocean surface sunlight)
			var c1 = sin(theta_u * 3.0 + sin(theta_v * 3.0) * 1.8)
			var c2 = cos(theta_v * 4.0 + sin(theta_u * 2.5) * 1.8)
			var caustic = maxf(0.0, (c1 * c2) - 0.40) * 1.5
			
			# Micro-grain procedural noise (sand grain micro-texture)
			var pseudo = sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
			var noise_val = (pseudo - floor(pseudo))
			var grain = (noise_val - 0.5) * 0.10
			
			# Base albedo composition
			var col: Color
			if ripple < 0.0:
				col = base_sand.lerp(shadow_sand, -ripple * 0.75)
			else:
				col = base_sand.lerp(crest_sand, ripple * 0.70)
				
			col = col.lerp(caustic_col, clampf(caustic * 0.55, 0.0, 0.65))
			col = Color(clampf(col.r + grain, 0.0, 1.0), clampf(col.g + grain, 0.0, 1.0), clampf(col.b + grain, 0.0, 1.0), 1.0)
			
			# Subtle shell & pebble speckling
			if noise_val > 0.988:
				col = shell_col
			elif noise_val < 0.012:
				col = pebble_col
				
			img.set_pixel(x, y, col)
			
			# Normal vector from ripple slope
			var du = (cos(theta_u * 4.0) * 4.0 + cos(theta_u * 8.0) * 2.8) * 0.04
			var dv = (-sin(theta_v * 2.0) * 3.0 - sin(theta_v * 4.0) * 1.4) * 0.03
			var norm = Vector3(-du, -dv, 1.0).normalized()
			var n_col = Color(norm.x * 0.5 + 0.5, norm.y * 0.5 + 0.5, norm.z * 0.5 + 0.5, 1.0)
			norm_img.set_pixel(x, y, n_col)
			
	_seabed_sand_texture_cache = ImageTexture.create_from_image(img)
	_seabed_normal_texture_cache = ImageTexture.create_from_image(norm_img)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = _seabed_sand_texture_cache
	mat.normal_enabled = true
	mat.normal_texture = _seabed_normal_texture_cache
	mat.normal_scale = 1.3
	mat.roughness = 0.85
	mat.metallic = 0.0
	mat.uv1_scale = Vector3(24.0, 22.0, 1.0) # Seamless high-DPI repetition across expanded 88x78 seabed
	_seabed_material_cache = mat
	return _seabed_material_cache

var _moai_stone_material_cache: StandardMaterial3D = null
var _moai_light_material_cache: StandardMaterial3D = null

func get_moai_stone_material(is_highlight: bool = false) -> StandardMaterial3D:
	if is_highlight and _moai_light_material_cache != null:
		return _moai_light_material_cache
	if not is_highlight and _moai_stone_material_cache != null:
		return _moai_stone_material_cache

	var size: int = 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var norm_img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	var base_col := Color("#234766") if not is_highlight else Color("#3D6E94")
	var dark_pit := Color("#0E2236") if not is_highlight else Color("#1D3D59")
	var mid_mottle := Color("#346388") if not is_highlight else Color("#578EB5")
	var light_fleck := Color("#629BC2") if not is_highlight else Color("#85B8DB")

	for y: int in range(size):
		var v: float = float(y) / float(size)
		var tv: float = v * TAU
		for x: int in range(size):
			var u: float = float(x) / float(size)
			var tu: float = u * TAU

			# Multi-octave seamless volcanic basalt mottling & porous pitting
			var m1: float = sin(tu * 3.0 + cos(tv * 2.0) * 1.5) * cos(tv * 3.0 - sin(tu * 2.0) * 1.4)
			var m2: float = sin(tu * 7.0 - tv * 5.0) * 0.45 + cos(tu * 11.0 + tv * 9.0) * 0.35
			var m3: float = sin(tu * 19.0 + tv * 17.0) * 0.22

			var h_hash: float = sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
			var grain: float = h_hash - floor(h_hash)

			var pit_hash: float = sin(float(x / 2) * 41.13 + float(y / 2) * 91.77) * 19531.25
			var pit_val: float = pit_hash - floor(pit_hash)

			var col: Color = base_col
			var blend_m: float = clampf((m1 + m2) * 0.5 + 0.5, 0.0, 1.0)
			col = dark_pit.lerp(mid_mottle, blend_m)
			if m1 + m2 + m3 > 0.65 or pit_val > 0.86:
				col = col.lerp(light_fleck, 0.65)
			elif pit_val < 0.18:
				col = col.lerp(dark_pit, 0.78)

			var g_off: float = (grain - 0.5) * 0.08
			col = Color(clampf(col.r + g_off, 0.0, 1.0), clampf(col.g + g_off, 0.0, 1.0), clampf(col.b + g_off, 0.0, 1.0), 1.0)
			img.set_pixel(x, y, col)

			var du: float = (cos(tu * 7.0 - tv * 5.0) * 3.0 + cos(tu * 19.0 + tv * 17.0) * 2.5) * 0.06
			var dv: float = (-sin(tu * 7.0 - tv * 5.0) * 2.5 + cos(tu * 19.0 + tv * 17.0) * 2.5) * 0.06
			var norm := Vector3(-du, -dv, 1.0).normalized()
			norm_img.set_pixel(x, y, Color(norm.x * 0.5 + 0.5, norm.y * 0.5 + 0.5, norm.z * 0.5 + 0.5, 1.0))

	var tex := ImageTexture.create_from_image(img)
	var n_tex := ImageTexture.create_from_image(norm_img)

	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.normal_enabled = true
	m.normal_texture = n_tex
	m.normal_scale = 1.4
	m.roughness = 0.84
	m.metallic = 0.05
	m.uv1_scale = Vector3(3.0, 3.0, 1.0)

	if is_highlight:
		_moai_light_material_cache = m
	else:
		_moai_stone_material_cache = m
	return m

var _patrick_rock_material_cache: StandardMaterial3D = null

func get_patrick_rock_material() -> StandardMaterial3D:
	if _patrick_rock_material_cache != null:
		return _patrick_rock_material_cache

	var size: int = 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var norm_img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	var warm_terracotta := Color("#884022")
	var mid_brown := Color("#692E16")
	var dark_umber := Color("#451B0B")
	var highlight_ochre := Color("#A1512E")

	for y: int in range(size):
		var v: float = float(y) / float(size)
		var tv: float = v * TAU
		for x: int in range(size):
			var u: float = float(x) / float(size)
			var tu: float = u * TAU

			var w1: float = sin(tu * 2.0 + cos(tv * 2.0) * 1.2) * cos(tv * 2.0 - sin(tu * 1.0) * 1.1)
			var w2: float = sin(tu * 5.0 - tv * 4.0) * 0.40 + cos(tu * 9.0 + tv * 7.0) * 0.28
			var h_hash: float = sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
			var grain: float = (h_hash - floor(h_hash) - 0.5) * 0.06

			var blend: float = clampf((w1 + w2) * 0.5 + 0.5, 0.0, 1.0)
			var col: Color = dark_umber.lerp(warm_terracotta, blend)
			if blend > 0.72:
				col = col.lerp(highlight_ochre, (blend - 0.72) * 2.2)
			elif blend < 0.28:
				col = col.lerp(mid_brown, 0.35)

			col = Color(clampf(col.r + grain, 0.0, 1.0), clampf(col.g + grain, 0.0, 1.0), clampf(col.b + grain, 0.0, 1.0), 1.0)
			img.set_pixel(x, y, col)

			var du: float = (cos(tu * 5.0 - tv * 4.0) * 2.5 + cos(tu * 9.0 + tv * 7.0) * 2.0) * 0.05
			var dv: float = (-sin(tu * 5.0 - tv * 4.0) * 2.0 - sin(tu * 9.0 + tv * 7.0) * 2.0) * 0.05
			var norm := Vector3(-du, -dv, 1.0).normalized()
			norm_img.set_pixel(x, y, Color(norm.x * 0.5 + 0.5, norm.y * 0.5 + 0.5, norm.z * 0.5 + 0.5, 1.0))

	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(norm_img)
	m.normal_scale = 1.25
	m.roughness = 0.86
	m.metallic = 0.02
	m.uv1_scale = Vector3(2.0, 2.0, 1.0)
	_patrick_rock_material_cache = m
	return m

func _add_pointed_leaf(parent: Node3D, pos: Vector3, rot_deg: Vector3, length: float, width: float, mat_outline: Material, mat_inner: Material, mat_vein: Material) -> void:
	var pivot = Node3D.new()
	pivot.position = pos
	pivot.rotation_degrees = rot_deg
	parent.add_child(pivot)
	
	# Dark green outline blade (slightly wider and extends to the very top edge for clear boundary)
	var out_mi = MeshInstance3D.new()
	var out_mesh = CylinderMesh.new()
	out_mesh.top_radius = 0.04
	out_mesh.bottom_radius = width * 0.55
	out_mesh.height = length * 1.05
	out_mi.mesh = out_mesh
	out_mi.scale = Vector3(1.0, 1.0, 0.22)
	out_mi.position = Vector3(0, length * 0.525, -0.01)
	out_mi.material_override = mat_outline
	pivot.add_child(out_mi)
	
	# Upper border cap on tip for distinct upper edge
	var cap_mi = MeshInstance3D.new()
	var cap_box = BoxMesh.new()
	cap_box.size = Vector3(width * 0.28, 0.12, 0.06)
	cap_mi.mesh = cap_box
	cap_mi.position = Vector3(0, length * 1.03, 0.01)
	cap_mi.material_override = mat_outline
	pivot.add_child(cap_mi)
	
	# Main vibrant green blade
	var in_mi = MeshInstance3D.new()
	var in_mesh = CylinderMesh.new()
	in_mesh.top_radius = 0.02
	in_mesh.bottom_radius = width * 0.46
	in_mesh.height = length
	in_mi.mesh = in_mesh
	in_mi.scale = Vector3(1.0, 1.0, 0.18)
	in_mi.position = Vector3(0, length * 0.5, 0.01)
	in_mi.material_override = mat_inner
	pivot.add_child(in_mi)
	
	# Center spine / vein line
	var vein_mi = MeshInstance3D.new()
	var vein_box = BoxMesh.new()
	vein_box.size = Vector3(width * 0.14, length * 0.88, 0.04)
	vein_mi.mesh = vein_box
	vein_mi.position = Vector3(0, length * 0.46, 0.03)
	vein_mi.material_override = mat_vein
	pivot.add_child(vein_mi)

func build_landmark_model(type: String) -> Node3D:
	var root = Node3D.new()
	var t = type.to_lower().replace("_", "").strip_edges()
	match t:
		"pineapple", "spongebob", "spongebobhouse":
			# Materials
			var p_tex = get_pineapple_texture()
			var pineapple_mat = StandardMaterial3D.new()
			pineapple_mat.albedo_texture = p_tex
			pineapple_mat.roughness = 0.65
			pineapple_mat.metallic = 0.0
			pineapple_mat.uv1_scale = Vector3(2.0, 1.0, 1.0)
			
			var door_frame_mat = make_mat(Color("#8E99C7"), 0.35, 0.65) # Lavender steel
			var door_plate_mat = make_mat(Color("#A4AED8"), 0.45, 0.5)  # Inner door plate
			var dark_steel = make_mat(Color("#34495E"), 0.3, 0.8)       # Hardware & rivets
			var bronze_mat = make_mat(Color("#6E2C00"), 0.5, 0.3)       # Wheel trim
			var cyan_window = make_mat(Color("#5DADE2"), 0.15, 0.1, Color("#2E86C1") * 0.5) # Glowing aqua glass
			var chimney_mat = make_mat(Color("#7B85A8"), 0.35, 0.7)     # Bent pipe
			var stone_mat = make_mat(Color("#5D6D7E"), 0.8)             # Cobblestone path
			
			var leaf_outline = make_mat(Color("#092F1E"), 0.6)          # Dark green border/outline
			var leaf_inner = make_mat(Color("#1E8449"), 0.4)            # Lush cartoon green
			var leaf_vein = make_mat(Color("#52BE80"), 0.3, 0.0, Color("#27AE60") * 0.3) # Bright vein spine
			var crown_socket_mat = make_mat(Color("#0B3C26"), 0.5)      # Stalk socket
			
			# 1. Broad-Based Pineapple Body (Firmly planted at y=0.0 to match the door bottom!)
			# Lower barrel section (y=0.0 to y=2.6) - matches ground plane perfectly!
			add_cylinder(root, 2.55, 2.15, 2.6, Vector3(0, 1.3, 0), pineapple_mat)
			# Upper tapering section (y=2.6 to y=4.8)
			add_cylinder(root, 1.55, 2.55, 2.2, Vector3(0, 3.7, 0), pineapple_mat)
			# Smooth top dome shoulder
			add_sphere(root, 1.62, 1.3, Vector3(0, 4.65, 0), pineapple_mat)
			
			# 2. Realistic Crown Socket / Stalk at Top (properly emerging socket)
			# Dark green leafy socket collar where crown emerges
			add_cylinder(root, 1.25, 1.45, 0.4, Vector3(0, 5.0, 0), crown_socket_mat)
			add_cylinder(root, 1.15, 1.15, 0.1, Vector3(0, 5.2, 0), leaf_outline)
			
			# 3. Realistic Palm Leaves with Outlines and Borders (distinct upper borders)
			var crown_y: float = 5.25
			# Tier 1: Tall upright central core (height 2.8)
			for a in [0.0, 90.0, 180.0, 270.0]:
				var rad = deg_to_rad(a)
				_add_pointed_leaf(root, Vector3(sin(rad) * 0.25, crown_y, cos(rad) * 0.25), Vector3(6.0, a, 0), 2.8, 0.50, leaf_outline, leaf_inner, leaf_vein)
			# Tier 2: Mid-tier flaring leaves (height 2.2)
			for a in [30.0, 90.0, 150.0, 210.0, 270.0, 330.0]:
				var rad = deg_to_rad(a)
				_add_pointed_leaf(root, Vector3(sin(rad) * 0.55, crown_y - 0.05, cos(rad) * 0.55), Vector3(22.0, a, 0), 2.2, 0.45, leaf_outline, leaf_inner, leaf_vein)
			# Tier 3: Outer perimeter spreading leaves (height 1.6)
			for a in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]:
				var rad = deg_to_rad(a)
				_add_pointed_leaf(root, Vector3(sin(rad) * 0.85, crown_y - 0.15, cos(rad) * 0.85), Vector3(42.0, a, 0), 1.6, 0.40, leaf_outline, leaf_inner, leaf_vein)

			# 4. Arched Submarine Hatch Door (Flushed to ground y=0.0, deeply anchored with 0 clipping!)
			# Outer Lavender Arch Frame (extending from z=2.05 inside to z=2.62 outside)
			add_box(root, Vector3(1.45, 1.40, 0.56), Vector3(0, 0.70, 2.34), door_frame_mat)
			add_cylinder(root, 0.725, 0.725, 0.56, Vector3(0, 1.40, 2.34), door_frame_mat, Vector3(90, 0, 0))
			# Inner Recessed Lavender Door Plate (proudly outside pineapple wall at z=2.60)
			add_box(root, Vector3(1.15, 1.32, 0.12), Vector3(0, 0.68, 2.60), door_plate_mat)
			add_cylinder(root, 0.575, 0.575, 0.12, Vector3(0, 1.36, 2.60), door_plate_mat, Vector3(90, 0, 0))
			# Door Rivets
			for i in range(8):
				var a = i * (180.0 / 7.0)
				var rad = deg_to_rad(a)
				var rx = cos(rad) * 0.65
				var ry = 1.40 + sin(rad) * 0.65
				add_sphere(root, 0.05, 0.1, Vector3(rx, ry, 2.64), dark_steel)
			add_sphere(root, 0.05, 0.1, Vector3(-0.65, 0.70, 2.64), dark_steel)
			add_sphere(root, 0.05, 0.1, Vector3(0.65, 0.70, 2.64), dark_steel)
			
			# Submarine Hatch Steering Wheel with 6 spokes
			var wheel_pos = Vector3(0, 1.05, 2.68)
			add_torus(root, 0.22, 0.32, wheel_pos, dark_steel, Vector3(90, 0, 0))
			add_cylinder(root, 0.09, 0.09, 0.15, wheel_pos, dark_steel, Vector3(90, 0, 0))
			for sa in [0.0, 60.0, 120.0]:
				add_cylinder(root, 0.03, 0.03, 0.54, wheel_pos, dark_steel, Vector3(0, 0, sa))
			for h in range(6):
				var h_rad = deg_to_rad(h * 60.0)
				add_sphere(root, 0.04, 0.08, wheel_pos + Vector3(sin(h_rad) * 0.34, cos(h_rad) * 0.34, 0.0), bronze_mat)

			# 5. Asymmetric Porthole Windows (Flushly embedded & 100% concentric/parallel via local normal pivots)
			# Upper-Left Window (High on the left at y=3.45, surface radius=2.14, slope=-24 deg)
			var w1_root = Node3D.new()
			w1_root.position = Vector3(-1.13, 3.45, 1.81)
			w1_root.rotation_degrees = Vector3(-24.0, -32.0, 0.0)
			root.add_child(w1_root)
			add_cylinder(w1_root, 0.48, 0.48, 0.46, Vector3(0, 0, -0.10), door_frame_mat, Vector3(90, 0, 0))
			add_torus(w1_root, 0.36, 0.50, Vector3(0, 0, 0.13), dark_steel, Vector3(90, 0, 0))
			add_cylinder(w1_root, 0.38, 0.38, 0.06, Vector3(0, 0, 0.11), cyan_window, Vector3(90, 0, 0))
			for ri in range(6):
				var ra = deg_to_rad(ri * 60.0)
				add_sphere(w1_root, 0.038, 0.076, Vector3(cos(ra) * 0.43, sin(ra) * 0.43, 0.15), dark_steel)

			# Lower-Right Window (Beside the door on the right at y=1.30, surface radius=2.33, slope=+8.7 deg)
			var w2_root = Node3D.new()
			w2_root.position = Vector3(1.56, 1.30, 1.73)
			w2_root.rotation_degrees = Vector3(8.7, 42.0, 0.0)
			root.add_child(w2_root)
			add_cylinder(w2_root, 0.45, 0.45, 0.46, Vector3(0, 0, -0.10), door_frame_mat, Vector3(90, 0, 0))
			add_torus(w2_root, 0.34, 0.47, Vector3(0, 0, 0.13), dark_steel, Vector3(90, 0, 0))
			add_cylinder(w2_root, 0.36, 0.36, 0.06, Vector3(0, 0, 0.11), cyan_window, Vector3(90, 0, 0))
			for ri in range(6):
				var ra = deg_to_rad(ri * 60.0)
				add_sphere(w2_root, 0.036, 0.072, Vector3(cos(ra) * 0.405, sin(ra) * 0.405, 0.15), dark_steel)

			# 6. Bent Exhaust Chimney Pipe (Upper Right Side)
			add_cylinder(root, 0.20, 0.20, 0.90, Vector3(2.35, 3.7, 0.2), chimney_mat, Vector3(0, 0, 90))
			add_sphere(root, 0.25, 0.50, Vector3(2.75, 3.7, 0.2), chimney_mat)
			add_cylinder(root, 0.20, 0.20, 1.5, Vector3(2.75, 4.45, 0.2), chimney_mat)
			add_torus(root, 0.19, 0.30, Vector3(2.75, 5.2, 0.2), chimney_mat)
			add_cylinder(root, 0.19, 0.19, 0.05, Vector3(2.75, 5.2, 0.2), dark_steel)

			# 7. Base Decor: Colorful Sea Flowers
			var flower_cols = [Color("#E91E63"), Color("#F4D03F"), Color("#9C27B0"), Color("#00BCD4"), Color("#FF9800"), Color("#4CAF50")]
			for fi in range(8):
				var fa = fi * (360.0 / 8.0)
				var frad = deg_to_rad(fa)
				var fcol = flower_cols[fi % flower_cols.size()]
				var fmat = make_mat(fcol, 0.5, 0.0, fcol * 0.3)
				var fx = sin(frad) * 2.3
				var fz = cos(frad) * 2.3
				if fz > 1.7 and abs(fx) < 0.9:
					continue
				var f_root = Node3D.new()
				f_root.position = Vector3(fx, 0.03, fz)
				root.add_child(f_root)
				for petal_i in range(5):
					var pa = deg_to_rad(petal_i * 72.0)
					var p_mesh = MeshInstance3D.new()
					var p_sph = SphereMesh.new()
					p_sph.radius = 0.15
					p_sph.height = 0.07
					p_mesh.mesh = p_sph
					p_mesh.material_override = fmat
					p_mesh.position = Vector3(sin(pa) * 0.20, 0, cos(pa) * 0.20)
					f_root.add_child(p_mesh)
				var c_mesh = MeshInstance3D.new()
				var c_sph = SphereMesh.new()
				c_sph.radius = 0.09
				c_sph.height = 0.07
				c_mesh.mesh = c_sph
				c_mesh.material_override = make_mat(Color.WHITE, 0.4)
				f_root.add_child(c_mesh)

		"krustykrab", "krab", "burger":
			# PBR Materials matching cartoon lobster trap aesthetic
			var plank_wood = make_mat(Color("#6E6845"), 0.72)       # Weathered olive-brown wood hull
			var dark_timber = make_mat(Color("#443F28"), 0.80)      # Frame timbers, roof seams, door trim
			var arch_wood = make_mat(Color("#544F31"), 0.68)        # Massive curved end arch beams
			var win_frame_mat = make_mat(Color("#3A3520"), 0.74)    # Distinct dark wooden window border frame
			var win_bevel_mat = make_mat(Color("#8A7D55"), 0.65)    # Inner carved frame trim
			var lattice_wood = make_mat(Color("#F6F3E1"), 0.55)     # Cream-white rope netting & knots
			var glass_mat = make_mat(Color("#74BDE8"), 0.12, 0.15, Color("#1E75A6") * 0.45) # Aqua glass
			var door_wood = make_mat(Color("#D35400"), 0.6)         # Rich orange-wood handles
			var bamboo_stalk = make_mat(Color("#CBB07B"), 0.65)     # Bamboo sign post
			var bamboo_node = make_mat(Color("#8E6E3E"), 0.75)      # Bamboo node rings
			var shell_mat = make_mat(Color("#FAF7EF"), 0.35, 0.05)  # Pearlescent clam shell face
			var shell_rim = make_mat(Color("#8E83B8"), 0.40)        # Lavender shell rim shading
			var stone_step_mat = make_mat(Color("#95A5A6"), 0.70)   # Curb and threshold stone
			var chimney_mat = make_mat(Color("#566573"), 0.35, 0.7) # Galvanized stovepipe
			var dark_steel = make_mat(Color("#212F3D"), 0.30, 0.85) # Weather vane and anemometer

			# 1. Foundation Timber Plinth & Entrance Step
			add_box(root, Vector3(8.0, 0.36, 5.8), Vector3(0, 0.18, 0), dark_timber)
			add_box(root, Vector3(2.4, 0.18, 0.7), Vector3(0, 0.09, 3.15), stone_step_mat)

			# 2. Main Lobster Trap Barrel Hull (Flush lower walls y=0.36..2.40 + semicircular barrel roof r=2.60)
			add_box(root, Vector3(7.20, 2.04, 5.20), Vector3(0, 1.38, 0), plank_wood)
			add_cylinder(root, 2.60, 2.60, 7.20, Vector3(0, 2.40, 0), plank_wood, Vector3(0, 0, 90))

			# Horizontal wooden plank seams / battens running across the barrel roof & walls
			var roof_angles = [-68, -45, -22, 0, 22, 45, 68]
			for ang in roof_angles:
				var rad = deg_to_rad(ang)
				var py = 2.40 + cos(rad) * 2.62
				var pz = sin(rad) * 2.62
				add_box(root, Vector3(7.24, 0.07, 0.07), Vector3(0, py, pz), dark_timber, Vector3(-ang, 0, 0))

			# Inverted-U barrel hoop bands (straight legs y=0.36..2.40 + top semicircle r=2.64 so zero bottom ring distortion!)
			for bx in [-2.3, 0.0, 2.3]:
				add_box(root, Vector3(0.14, 2.04, 0.12), Vector3(bx, 1.38, -2.62), dark_timber)
				add_box(root, Vector3(0.14, 2.04, 0.12), Vector3(bx, 1.38, 2.62), dark_timber)
				for hi in range(15):
					var hang = -84.0 + hi * 12.0
					var hrad = deg_to_rad(hang)
					var hy = 2.40 + cos(hrad) * 2.63
					var hz = sin(hrad) * 2.63
					add_box(root, Vector3(0.14, 0.10, 0.58), Vector3(bx, hy, hz), dark_timber, Vector3(-hang, 0, 0))

			# 3. Thick Arched End Frames + Bounded Side Arched Window with Frame & Tied White Ropes
			for side in [-1.0, 1.0]:
				var sx = side * 3.62
				# Massive outer lobster-trap arch (vertical legs y=0.36..2.40 + semicircular arch r=2.66 above y=2.40)
				add_box(root, Vector3(0.38, 2.08, 0.38), Vector3(sx, 1.38, -2.64), arch_wood)
				add_box(root, Vector3(0.38, 2.08, 0.38), Vector3(sx, 1.38, 2.64), arch_wood)
				for ai in range(19):
					var aang = -85.0 + ai * 9.444
					var arad = deg_to_rad(aang)
					var ay = 2.40 + cos(arad) * 2.64
					var az = sin(arad) * 2.64
					add_box(root, Vector3(0.38, 0.36, 0.52), Vector3(sx, ay, az), arch_wood, Vector3(-aang, 0, 0))

				# --- BOUNDED SIDE ARCHED WINDOW (Compact z in [-1.12, 1.12], y in [0.66, 2.45] + top semicircle r=1.12) ---
				var wx = sx + side * 0.02
				var r_win := 1.12
				var y_bot := 0.66
				var y_arch := 2.45

				# Bounded Aqua Glass Panel strictly inside the window frame
				add_box(root, Vector3(0.04, y_arch - y_bot, r_win * 2.0 - 0.04), Vector3(wx, (y_arch + y_bot) * 0.5, 0), glass_mat)
				add_cylinder(root, r_win - 0.02, r_win - 0.02, 0.038, Vector3(wx + side * 0.002, y_arch, 0), glass_mat, Vector3(0, 0, 90))

				# Prominent 3D Wooden Window Frame surrounding the bounded glass
				var fx = sx + side * 0.05
				# Bottom horizontal sill frame & inner bevel
				add_box(root, Vector3(0.14, 0.14, r_win * 2.0 + 0.24), Vector3(fx, y_bot, 0), win_frame_mat)
				add_box(root, Vector3(0.16, 0.06, r_win * 2.0 + 0.08), Vector3(fx, y_bot + 0.05, 0), win_bevel_mat)
				# Left and Right vertical side frame posts & inner bevels
				for sz in [-1.0, 1.0]:
					add_box(root, Vector3(0.14, y_arch - y_bot + 0.06, 0.14), Vector3(fx, (y_arch + y_bot) * 0.5, sz * r_win), win_frame_mat)
					add_box(root, Vector3(0.16, y_arch - y_bot, 0.06), Vector3(fx, (y_arch + y_bot) * 0.5, sz * (r_win - 0.05)), win_bevel_mat)
				# Semicircular arched top frame border (17 segments from -90 deg to +90 deg)
				for wi in range(17):
					var wang = -84.375 + wi * 10.547
					var wrad = deg_to_rad(wang)
					var wy = y_arch + cos(wrad) * r_win
					var wz = sin(wrad) * r_win
					add_box(root, Vector3(0.14, 0.14, 0.26), Vector3(fx, wy, wz), win_frame_mat, Vector3(-wang, 0, 0))
					var wy_in = y_arch + cos(wrad) * (r_win - 0.05)
					var wz_in = sin(wrad) * (r_win - 0.05)
					add_box(root, Vector3(0.16, 0.06, 0.24), Vector3(fx, wy_in, wz_in), win_bevel_mat, Vector3(-wang, 0, 0))

				# White Criss-Cross Lobster-Trap Ropes Tied Directly to the Window Frame Border!
				var rx: float = sx + side * 0.075
				var rope_intercepts: Array[float] = [1.15, 1.75, 2.35, 2.95]
				for slope: float in [-1.0, 1.0]:
					for y_mid: float in rope_intercepts:
						var z1: float = -r_win
						var z2: float = r_win
						if slope > 0.0:
							z1 = maxf(-r_win, y_bot - y_mid)
							z2 = minf(r_win, (y_arch + r_win) - y_mid)
						else:
							z1 = maxf(-r_win, y_mid - (y_arch + r_win))
							z2 = minf(r_win, y_mid - y_bot)
						# Clamp upper endpoint(s) precisely to the semicircular arch circle (y - y_arch)^2 + z^2 = r_win^2
						var dy: float = y_mid - y_arch
						var disc: float = 2.0 * r_win * r_win - dy * dy
						if disc > 0.01:
							var sq: float = sqrt(disc)
							if y_mid + slope * z1 > y_arch:
								z1 = (-slope * dy - sq) * 0.5
							if y_mid + slope * z2 > y_arch:
								z2 = (-slope * dy + sq) * 0.5
						var y1: float = y_mid + slope * z1
						var y2: float = y_mid + slope * z2
						var p1 := Vector2(z1, y1)
						var p2 := Vector2(z2, y2)
						var r_len: float = p1.distance_to(p2)
						if r_len > 0.25:
							var mid_z: float = (z1 + z2) * 0.5
							var mid_y: float = (y1 + y2) * 0.5
							var r_ang: float = 45.0 if slope > 0.0 else -45.0
							# Stretched white rope cord between frame border points P1 and P2
							add_cylinder(root, 0.028, 0.028, r_len, Vector3(rx, mid_y, mid_z), lattice_wood, Vector3(r_ang, 0, 0))
							# Visible white rope knot & lashing ring tied right onto the wooden frame at both ends!
							for ep: Vector2 in [p1, p2]:
								add_sphere(root, 0.052, 0.095, Vector3(fx + side * 0.03, ep.y, ep.x), lattice_wood)
								var lash_rot := Vector3.ZERO
								if ep.y <= y_bot + 0.03:
									lash_rot = Vector3(90, 0, 0)
								elif ep.y > y_arch:
									var a_deg: float = rad_to_deg(atan2(ep.x, ep.y - y_arch))
									lash_rot = Vector3(90.0 - a_deg, 0, 0)
								add_torus(root, 0.045, 0.085, Vector3(fx, ep.y, ep.x), lattice_wood, lash_rot)

			# 4. Front Panoramic Glass Windows & Double Doors
			# Left Window (Complete 4-sided frame)
			add_box(root, Vector3(2.3, 1.46, 0.06), Vector3(-1.98, 1.35, 2.62), glass_mat)
			add_box(root, Vector3(2.44, 0.12, 0.14), Vector3(-1.98, 2.10, 2.63), dark_timber)
			add_box(root, Vector3(2.44, 0.12, 0.14), Vector3(-1.98, 0.60, 2.63), dark_timber)
			add_box(root, Vector3(0.12, 1.56, 0.14), Vector3(-3.16, 1.35, 2.63), dark_timber)
			add_box(root, Vector3(0.12, 1.56, 0.14), Vector3(-0.82, 1.35, 2.63), dark_timber)

			# Right Window (Complete 4-sided frame)
			add_box(root, Vector3(2.3, 1.46, 0.06), Vector3(1.98, 1.35, 2.62), glass_mat)
			add_box(root, Vector3(2.44, 0.12, 0.14), Vector3(1.98, 2.10, 2.63), dark_timber)
			add_box(root, Vector3(2.44, 0.12, 0.14), Vector3(1.98, 0.60, 2.63), dark_timber)
			add_box(root, Vector3(0.12, 1.56, 0.14), Vector3(3.16, 1.35, 2.63), dark_timber)
			add_box(root, Vector3(0.12, 1.56, 0.14), Vector3(0.82, 1.35, 2.63), dark_timber)

			# Center Double Glass Doors
			add_box(root, Vector3(1.60, 0.14, 0.16), Vector3(0, 2.22, 2.66), dark_timber)
			add_box(root, Vector3(0.12, 2.24, 0.16), Vector3(-0.78, 1.12, 2.66), dark_timber)
			add_box(root, Vector3(0.12, 2.24, 0.16), Vector3(0.78, 1.12, 2.66), dark_timber)
			add_box(root, Vector3(0.66, 2.10, 0.06), Vector3(-0.35, 1.08, 2.68), glass_mat)
			add_box(root, Vector3(0.66, 2.10, 0.06), Vector3(0.35, 1.08, 2.68), glass_mat)
			add_box(root, Vector3(0.04, 2.10, 0.10), Vector3(0, 1.08, 2.69), dark_timber)
			add_cylinder(root, 0.03, 0.03, 0.32, Vector3(-0.12, 1.05, 2.76), door_wood)
			add_cylinder(root, 0.03, 0.03, 0.32, Vector3(0.12, 1.05, 2.76), door_wood)

			# 5. Nautical Signal Flags Bunting String (Strung across facade above windows)
			var flag_configs = [
				{"col1": Color("#E74C3C"), "col2": Color("#F1C40F")}, # Red/Yellow
				{"col1": Color("#2C3E50"), "col2": Color("#F1C40F")}, # Dark/Yellow
				{"col1": Color("#2980B9"), "col2": Color.WHITE},    # Blue/White
				{"col1": Color("#E74C3C"), "col2": Color.WHITE},    # Red/White
				{"col1": Color("#F1C40F"), "col2": Color("#2980B9")}, # Yellow/Blue
				{"col1": Color("#2980B9"), "col2": Color("#E74C3C")}, # Blue/Red
				{"col1": Color("#E74C3C"), "col2": Color.WHITE}       # Red/White
			]
			for fi in range(flag_configs.size()):
				var fx = -2.7 + fi * 0.90
				var sag = 2.65 - cos(float(fi - 3) / 3.2 * 1.4) * 0.28
				var fc = flag_configs[fi]
				var f_mat1 = make_mat(fc["col1"], 0.6)
				var f_mat2 = make_mat(fc["col2"], 0.6)
				var flag_root = Node3D.new()
				flag_root.position = Vector3(fx, sag, 2.74)
				flag_root.rotation_degrees = Vector3(0, 0, sin(float(fi) * 2.0) * 4.0)
				root.add_child(flag_root)
				add_box(flag_root, Vector3(0.38, 0.20, 0.02), Vector3(0, -0.10, 0), f_mat1)
				add_box(flag_root, Vector3(0.38, 0.20, 0.02), Vector3(0, -0.30, 0), f_mat2)

			# 6. Rooftop Stovepipe Chimney & Anemometer Weather Vane
			add_box(root, Vector3(0.48, 0.70, 0.48), Vector3(0.35, 4.4, 0.0), chimney_mat)
			add_cylinder(root, 0.18, 0.18, 0.85, Vector3(0.35, 5.0, 0.0), chimney_mat)
			add_cylinder(root, 0.32, 0.32, 0.08, Vector3(0.35, 5.46, 0.0), chimney_mat)

			add_cylinder(root, 0.025, 0.025, 1.6, Vector3(1.3, 5.2, 0.0), dark_steel)
			add_box(root, Vector3(0.65, 0.03, 0.03), Vector3(1.3, 5.75, 0.0), dark_steel)
			add_box(root, Vector3(0.03, 0.03, 0.65), Vector3(1.3, 5.75, 0.0), dark_steel)
			for d_ang in [0.0, 90.0, 180.0, 270.0]:
				var d_rad = deg_to_rad(d_ang)
				add_sphere(root, 0.06, 0.06, Vector3(1.3 + sin(d_rad) * 0.32, 5.75, cos(d_rad) * 0.32), dark_steel)
			add_cylinder(root, 0.01, 0.06, 0.25, Vector3(1.3, 6.1, 0.0), dark_steel)

			# 7. Iconic Clam Shell Sign on Tall Bamboo Post (Grouped under ClamSignPivot)
			var sign_x = -4.2
			var sign_z = 2.4
			var sign_pivot := Node3D.new()
			sign_pivot.name = "ClamSignPivot"
			sign_pivot.position = Vector3(sign_x, 0.0, sign_z)
			root.add_child(sign_pivot)

			add_cylinder(sign_pivot, 0.12, 0.14, 7.6, Vector3(0.0, 3.8, 0.0), bamboo_stalk)
			for j in range(9):
				add_torus(sign_pivot, 0.13, 0.18, Vector3(0.0, 0.6 + j * 0.8, 0.0), bamboo_node)

			add_cylinder(sign_pivot, 1.4, 0.35, 0.40, Vector3(0.0, 6.75, 0.5), shell_mat, Vector3(-35, 15, 0))
			add_torus(sign_pivot, 1.25, 1.45, Vector3(0.0, 6.85, 0.5), shell_rim, Vector3(-35, 15, 0))

			var shell_y = 8.1
			add_cylinder(sign_pivot, 0.85, 0.25, 2.1, Vector3(0.0, shell_y, 0.25), shell_mat)
			add_cylinder(sign_pivot, 0.70, 0.20, 1.9, Vector3(-0.55, shell_y - 0.15, 0.25), shell_mat, Vector3(0, 0, 18))
			add_cylinder(sign_pivot, 0.70, 0.20, 1.9, Vector3(0.55, shell_y - 0.15, 0.25), shell_mat, Vector3(0, 0, -18))
			add_cylinder(sign_pivot, 0.55, 0.15, 1.6, Vector3(-1.00, shell_y - 0.35, 0.25), shell_mat, Vector3(0, 0, 35))
			add_cylinder(sign_pivot, 0.55, 0.15, 1.6, Vector3(1.00, shell_y - 0.35, 0.25), shell_mat, Vector3(0, 0, -35))
			for k in range(5):
				add_sphere(sign_pivot, 0.32, 0.25, Vector3((k - 2) * 0.52, shell_y + 1.05, 0.25), shell_mat)

			var sign_lbl = Label3D.new()
			sign_lbl.text = "THE\nKRUSTY\nKRAB"
			sign_lbl.font = UIThemeBuilder.get_title_font()
			sign_lbl.font_size = 78
			sign_lbl.outline_size = 20
			sign_lbl.modulate = Color("#E52521")
			sign_lbl.outline_modulate = Color("#140404")
			sign_lbl.line_spacing = -2.0
			sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sign_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sign_lbl.position = Vector3(0.0, shell_y + 0.05, 0.40)
			sign_lbl.double_sided = true
			sign_lbl.no_depth_test = true
			sign_lbl.render_priority = 10
			sign_pivot.add_child(sign_lbl)

		"chumbucket", "lab", "planktonlab":
			# Galvanized Bucket & Rims Materials (matching cartoon muted blue-gray metal)
			var galvanized_mat = make_mat(Color("#546E7A"), 0.48, 0.35)
			var galvanized_shadow = make_mat(Color("#37474F"), 0.55, 0.4)
			var bucket_rim_mat = make_mat(Color("#263238"), 0.40, 0.5)
			var bucket_top_recess = make_mat(Color("#1C252B"), 0.60, 0.2)
			var wire_handle_mat = make_mat(Color("#1E272C"), 0.35, 0.7)

			# Rubber Glove Materials (matching cartoon periwinkle/lavender dishwashing glove)
			var glove_mat = make_mat(Color("#6558A6"), 0.42, 0.08)
			var glove_crease = make_mat(Color("#433878"), 0.50, 0.05)
			var glove_highlight = make_mat(Color("#7E72C4"), 0.38, 0.08)
			var glove_interior = make_mat(Color("#2E2656"), 0.6, 0.0)

			# Wooden Saloon Door Materials
			var door_wood_mat = make_mat(Color("#B8860B"), 0.75, 0.05)
			var door_frame_mat = make_mat(Color("#5D4037"), 0.8, 0.1)
			var peep_glass_mat = make_mat(Color("#1A252C"), 0.15, 0.1)
			var door_iron_mat = make_mat(Color("#212121"), 0.4, 0.8)

			# Pathway & Base Decor Materials
			var asphalt_mat = make_mat(Color("#37474F"), 0.85, 0.1)
			var rubble_mat = make_mat(Color("#263238"), 0.9, 0.05)

			# 1. Main Tapered Galvanized Bucket Body
			# Taper: top radius 2.75, bottom radius 2.12, height 5.0, sitting on ground at y=0.0
			add_cylinder(root, 2.75, 2.12, 5.0, Vector3(0, 2.5, 0), galvanized_mat)

			# Horizontal subtle bucket panel ribs (reinforcing seams)
			add_torus(root, 2.45, 2.53, Vector3(0, 2.5, 0), bucket_rim_mat)
			add_torus(root, 2.28, 2.36, Vector3(0, 1.25, 0), bucket_rim_mat)

			# Top Bucket Rim & Recessed Interior
			add_torus(root, 2.62, 2.88, Vector3(0, 5.0, 0), bucket_rim_mat)
			add_cylinder(root, 2.72, 2.72, 0.12, Vector3(0, 4.96, 0), bucket_top_recess)

			# Bottom Base Rim
			add_torus(root, 2.05, 2.22, Vector3(0, 0.08, 0), bucket_rim_mat)
			add_cylinder(root, 2.20, 2.20, 0.16, Vector3(0, 0.08, 0), galvanized_shadow)

			# 2. Side Ear Brackets & Rivets
			for side in [-1.0, 1.0]:
				var ex = side * 2.80
				# Bracket plate
				add_box(root, Vector3(0.16, 0.55, 0.45), Vector3(ex, 4.65, 0), bucket_rim_mat)
				# Rivets
				add_sphere(root, 0.08, 0.08, Vector3(ex + side * 0.08, 4.80, 0), wire_handle_mat)
				add_sphere(root, 0.08, 0.08, Vector3(ex + side * 0.08, 4.50, 0), wire_handle_mat)
				# Eyelet loop
				add_torus(root, 0.12, 0.28, Vector3(ex + side * 0.12, 4.65, 0), wire_handle_mat, Vector3(0, 0, 90))

			# 3. Arched Wire Bail Handle (Constructed smoothly via curved arch segments)
			var arch_steps = 18
			for i in range(arch_steps):
				var a1 = float(i) * PI / float(arch_steps)
				var a2 = float(i + 1) * PI / float(arch_steps)
				var p1 = Vector3(-cos(a1) * 2.82, 4.65 + sin(a1) * 3.35, 0.0)
				var p2 = Vector3(-cos(a2) * 2.82, 4.65 + sin(a2) * 3.35, 0.0)
				var diff = p2 - p1
				var seg_len = diff.length()
				var mid = (p1 + p2) * 0.5
				var rot_z = rad_to_deg(atan2(diff.y, diff.x)) - 90.0
				add_cylinder(root, 0.11, 0.11, seg_len, mid, wire_handle_mat, Vector3(0, 0, rot_z))

			# 4. Giant Lavender Cleaning Glove (Clenched Fist gripping handle from above)
			# Peak of handle is at y = 8.0, so the fist clamps right over y = 8.0!
			# Core palm and back of hand
			add_box(root, Vector3(2.1, 1.4, 1.6), Vector3(0, 8.2, 0.0), glove_mat)
			add_sphere(root, 1.15, 1.45, Vector3(0, 8.45, 0.05), glove_mat)

			# Four curled fingers gripping down and under the handle in front
			var finger_x_coords = [-0.66, -0.22, 0.22, 0.66]
			for fx in finger_x_coords:
				# Proximal knuckle bending down
				add_cylinder(root, 0.22, 0.22, 0.65, Vector3(fx, 8.1, 0.65), glove_mat, Vector3(15, 0, 0))
				# Middle knuckle joint
				add_sphere(root, 0.23, 0.23, Vector3(fx, 7.8, 0.74), glove_highlight)
				# Lower curling segment wrapping under the handle
				add_cylinder(root, 0.20, 0.20, 0.55, Vector3(fx, 7.6, 0.45), glove_mat, Vector3(75, 0, 0))
				# Fingertip pad tucked in
				add_sphere(root, 0.20, 0.20, Vector3(fx, 7.6, 0.20), glove_mat)

			# Dark crease lines between the four fingers
			for gap_x in [-0.44, 0.0, 0.44]:
				add_box(root, Vector3(0.04, 0.8, 0.35), Vector3(gap_x, 7.85, 0.68), glove_crease)

			# Clamped folded thumb
			add_sphere(root, 0.38, 0.42, Vector3(-1.10, 8.15, 0.35), glove_mat)
			add_cylinder(root, 0.26, 0.24, 0.80, Vector3(-0.88, 7.75, 0.66), glove_mat, Vector3(0, 25, -60))
			add_sphere(root, 0.25, 0.25, Vector3(-0.55, 7.55, 0.75), glove_highlight)

			# Rubber Glove Wrist & Ruffled Accordion Cuff
			add_cylinder(root, 1.05, 0.95, 0.75, Vector3(0, 9.25, 0), glove_mat)
			add_cylinder(root, 1.50, 1.05, 0.65, Vector3(0, 9.85, 0), glove_mat)
			add_torus(root, 1.30, 1.55, Vector3(0, 10.15, 0), glove_highlight)
			add_cylinder(root, 1.30, 1.30, 0.08, Vector3(0, 10.16, 0), glove_interior)

			# Pleated fluted ruffles around the cuff
			for ri in range(12):
				var r_ang = ri * (2.0 * PI / 12.0)
				var rx = sin(r_ang) * 1.36
				var rz = cos(r_ang) * 1.02
				add_cylinder(root, 0.15, 0.11, 0.70, Vector3(rx, 9.85, rz), glove_highlight)

			# 5. Hand-Painted Red "CHUM BUCKET" Sign
			var sign_lbl = Label3D.new()
			sign_lbl.text = "CHUM\nBUCKET"
			sign_lbl.font = UIThemeBuilder.get_title_font()
			sign_lbl.font_size = 76
			sign_lbl.pixel_size = 0.007
			sign_lbl.outline_size = 20
			sign_lbl.modulate = Color("#FF2B2B") # Bold vibrant cartoon red
			sign_lbl.outline_modulate = Color("#160404") # Dark bold cartoon outline
			sign_lbl.line_spacing = 2.0
			sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sign_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sign_lbl.position = Vector3(0.0, 3.46, 2.70)
			sign_lbl.rotation_degrees = Vector3(7.2, 0.0, 0.0) # Matches bucket forward taper slope
			sign_lbl.double_sided = false
			sign_lbl.no_depth_test = true
			sign_lbl.render_priority = 10
			sign_lbl.sorting_offset = 2.0
			root.add_child(sign_lbl)

			# 6. Double Swinging Wooden Saloon Doors with Porthole Peep-holes
			var door_pivot = Node3D.new()
			door_pivot.position = Vector3(0.0, 0.0, 0.0)
			door_pivot.rotation_degrees = Vector3(7.2, 0.0, 0.0) # Leans forward with bucket taper
			root.add_child(door_pivot)

			# Frame Header and Side Jambs with deep 0.50m depth that cleanly embeds into the cylinder wall
			add_box(door_pivot, Vector3(1.86, 0.18, 0.50), Vector3(0, 2.16, 2.24), door_frame_mat)
			add_box(door_pivot, Vector3(0.18, 2.24, 0.50), Vector3(-0.84, 1.07, 2.24), door_frame_mat)
			add_box(door_pivot, Vector3(0.18, 2.24, 0.50), Vector3(0.84, 1.07, 2.24), door_frame_mat)

			# Dark doorway threshold interior backing
			var dark_recess_mat = make_mat(Color("#18120C"), 0.85, 0.1)
			add_box(door_pivot, Vector3(1.70, 2.10, 0.12), Vector3(0, 1.05, 2.26), dark_recess_mat)

			# Saloon Double Doors - positioned proudly at z = 2.38 (completely in front of the bucket wall with 0 clipping!)
			add_box(door_pivot, Vector3(0.72, 2.04, 0.12), Vector3(-0.38, 1.02, 2.38), door_wood_mat)
			add_box(door_pivot, Vector3(0.72, 2.04, 0.12), Vector3(0.38, 1.02, 2.38), door_wood_mat)
			# Center dividing seam
			add_box(door_pivot, Vector3(0.04, 2.04, 0.15), Vector3(0.0, 1.02, 2.39), door_frame_mat)

			# Peep-hole porthole windows on each door
			for px in [-0.38, 0.38]:
				add_torus(door_pivot, 0.11, 0.20, Vector3(px, 1.55, 2.45), door_iron_mat, Vector3(90, 0, 0))
				add_sphere(door_pivot, 0.12, 0.06, Vector3(px, 1.55, 2.45), peep_glass_mat, Vector3(90, 0, 0))

			# Door handles
			add_cylinder(door_pivot, 0.02, 0.02, 0.24, Vector3(-0.10, 0.95, 2.46), door_iron_mat)
			add_cylinder(door_pivot, 0.02, 0.02, 0.24, Vector3(0.10, 0.95, 2.46), door_iron_mat)

			# 7. Side Ground Rubble Rocks
			add_sphere(root, 0.28, 0.22, Vector3(-2.25, 0.11, 1.8), rubble_mat)
			add_sphere(root, 0.35, 0.25, Vector3(2.35, 0.12, 1.7), rubble_mat)
			add_sphere(root, 0.20, 0.16, Vector3(2.65, 0.09, 2.0), rubble_mat)

		"moai", "squidward", "squidwardmoai":
			# Volcanic Mottled Dark-Blue Slate Materials matching cartoon reference (media_1790518513676.jpg)
			var moai_stone_mat := get_moai_stone_material(false)
			var moai_light_mat := get_moai_stone_material(true)
			var moai_dark_mat := make_mat(Color("#0D1F30"), 0.88, 0.05)
			var moai_cavity_mat := make_mat(Color("#071019"), 0.92, 0.0)
			var eye_rim_mat := make_mat(Color("#386790"), 0.50, 0.30)
			var eye_bezel_mat := make_mat(Color("#1A3650"), 0.60, 0.35)
			var eye_glass_mat := make_mat(Color("#5CB8F0"), 0.12, 0.15, Color("#2E86C1") * 0.45)
			var eye_glint_mat := make_mat(Color("#C2EBFF"), 0.08, 0.10, Color("#85D7F2") * 0.60)
			var door_wood_mat := make_mat(Color("#B6783A"), 0.72, 0.04)
			var door_plank_alt := make_mat(Color("#9E6328"), 0.75, 0.04)
			var door_seam_mat := make_mat(Color("#4A2B0F"), 0.85, 0.02)
			var brass_knob_mat := make_mat(Color("#E5B822"), 0.25, 0.85, Color("#B7950B") * 0.25)

			# 1. Main Tapered Volcanic Moai Head Cylinder (y = 0.0 to 6.50) & Rounded Crown Cap
			add_cylinder(root, 1.66, 2.04, 6.50, Vector3(0, 3.25, 0), moai_stone_mat)
			# Subtle flared base ring resting firmly on the ground
			add_cylinder(root, 2.04, 2.10, 0.24, Vector3(0, 0.12, 0), moai_dark_mat)
			# Weathered rounded top crown bevel (matching reference silhouette)
			add_cylinder(root, 1.50, 1.66, 0.20, Vector3(0, 6.60, 0), moai_light_mat)
			add_sphere(root, 1.52, 0.28, Vector3(0, 6.68, 0), moai_light_mat)

			# 2. Heavy Sculpted Unibrow Ledge (Clearly ABOVE the porthole eyes: y = 4.26 to 4.74)
			add_box(root, Vector3(2.46, 0.42, 0.92), Vector3(0, 4.47, 1.62), moai_stone_mat)
			# Sunlit cyan-slate top shelf of the unibrow
			add_box(root, Vector3(2.50, 0.12, 0.95), Vector3(0, 4.68, 1.64), moai_light_mat)
			# Dark shadowed brow underside overhang
			add_box(root, Vector3(2.42, 0.08, 0.88), Vector3(0, 4.25, 1.60), moai_dark_mat)
			# Slightly angled outer brow tips wrapping the temples
			for b_side: float in [-1.0, 1.0]:
				add_box(root, Vector3(0.46, 0.40, 0.78), Vector3(b_side * 1.32, 4.46, 1.44), moai_stone_mat, Vector3(0, -b_side * 18.0, 0))
				add_box(root, Vector3(0.48, 0.11, 0.80), Vector3(b_side * 1.32, 4.67, 1.45), moai_light_mat, Vector3(0, -b_side * 18.0, 0))

			# 3. Two Prominent Circular Porthole Window Eyes (y = 3.68, x = ±0.72, 100% visible below brow!)
			for e_side: float in [-1.0, 1.0]:
				var ex: float = e_side * 0.72
				var ey: float = 3.68
				# Deep cylindrical stone/slate socket sleeve embedding into the Moai head (zero floating gap!)
				add_cylinder(root, 0.49, 0.51, 0.68, Vector3(ex, ey, 1.58), eye_bezel_mat, Vector3(90, 0, 0))
				# Thick circular blue-slate porthole outer ring (facing +Z via X=90 rot)
				add_torus(root, 0.30, 0.50, Vector3(ex, ey, 1.92), eye_rim_mat, Vector3(90, 0, 0))
				# Inner dark metallic bezel ring
				add_torus(root, 0.28, 0.34, Vector3(ex, ey, 1.95), eye_bezel_mat, Vector3(90, 0, 0))
				# Glowing sky-blue glass window disc
				add_cylinder(root, 0.32, 0.32, 0.06, Vector3(ex, ey, 1.92), eye_glass_mat, Vector3(90, 0, 0))
				# Bright inner cyan-white specular reflection highlight matching cartoon reference
				add_cylinder(root, 0.16, 0.16, 0.06, Vector3(ex + 0.05, ey + 0.04, 1.94), eye_glint_mat, Vector3(90, 0, 0))

			# 4. Tapered Trapezoidal Moai Nose (Narrow bridge between eyes y=4.28 widening to broad nostrils y=2.14)
			var nose_steps: int = 22
			var nose_y_bot: float = 2.14
			var nose_y_top: float = 4.28
			var step_h: float = (nose_y_top - nose_y_bot) / float(nose_steps) + 0.02
			for ni: int in range(nose_steps):
				var nt: float = float(ni) / float(nose_steps - 1)
				var ny: float = lerpf(nose_y_bot + 0.05, nose_y_top - 0.05, nt)
				var nw: float = lerpf(0.98, 0.36, nt)
				var nz_front: float = lerpf(2.48, 2.04, nt)
				var nz_back: float = 1.35
				var nd: float = nz_front - nz_back
				add_box(root, Vector3(nw, step_h, nd), Vector3(0.0, ny, (nz_front + nz_back) * 0.5), moai_stone_mat)

			# Smooth sunlit front nose ridge plate & angled side cheek plates for crisp trapezoidal edges
			add_box(root, Vector3(0.34, 2.18, 0.14), Vector3(0.0, 3.21, 2.21), moai_light_mat, Vector3(-11.6, 0, 0))
			for n_side: float in [-1.0, 1.0]:
				add_box(root, Vector3(0.24, 2.16, 0.55), Vector3(n_side * 0.24, 3.20, 2.00), moai_stone_mat, Vector3(-11.6, 0, n_side * 8.2))
			# Shadowed nose underside ledge & nostril indentations at y = 2.14
			add_box(root, Vector3(0.96, 0.08, 0.82), Vector3(0.0, 2.14, 2.04), moai_dark_mat)
			add_sphere(root, 0.14, 0.08, Vector3(-0.22, 2.12, 2.24), moai_cavity_mat)
			add_sphere(root, 0.14, 0.08, Vector3(0.22, 2.12, 2.24), moai_cavity_mat)

			# 5. Sculpted Rectangular Slab Ears on Left & Right Sides (y = 1.96 to 4.24)
			for ear_side: float in [-1.0, 1.0]:
				var ear_x: float = ear_side * 1.84
				# Main rectangular stone ear slab
				add_box(root, Vector3(0.54, 2.28, 0.92), Vector3(ear_x, 3.10, 0.05), moai_stone_mat)
				# Outer sunlit stone edge ridge
				add_box(root, Vector3(0.16, 2.30, 0.96), Vector3(ear_x + ear_side * 0.22, 3.10, 0.05), moai_light_mat)
				# Carved inner vertical ear recess
				add_box(root, Vector3(0.12, 1.82, 0.44), Vector3(ear_x + ear_side * 0.14, 3.10, 0.18), moai_dark_mat)

			# 6. Recessed Stone Archway & Arched Vertical-Planked Wooden Door (y = 0.0 to 1.82, proud at z = 2.10!)
			var d_arch_y: float = 1.20
			var d_arch_r: float = 0.56
			# Deep carved dark-stone archway surround (embeds from z=1.65 to z=2.10 so zero cylinder clipping!)
			for d_side: float in [-1.0, 1.0]:
				add_box(root, Vector3(0.16, d_arch_y, 0.46), Vector3(d_side * (d_arch_r - 0.04), d_arch_y * 0.5, 1.87), moai_dark_mat)
			for dai: int in range(15):
				var da_deg: float = -84.0 + float(dai) * 12.0
				var da_rad: float = deg_to_rad(da_deg)
				var dax: float = sin(da_rad) * (d_arch_r - 0.04)
				var day: float = d_arch_y + cos(da_rad) * (d_arch_r - 0.04)
				add_box(root, Vector3(0.18, 0.16, 0.46), Vector3(dax, day, 1.87), moai_dark_mat, Vector3(0, 0, -da_deg))

			# Dark recessed doorway shadow cavity backing (at z = 2.05)
			add_box(root, Vector3(1.00, d_arch_y, 0.10), Vector3(0, d_arch_y * 0.5, 2.04), moai_cavity_mat)
			add_cylinder(root, 0.50, 0.50, 0.10, Vector3(0, d_arch_y, 2.04), moai_cavity_mat, Vector3(90, 0, 0))

			# Warm Golden-Brown Arched Wooden Door (at z = 2.09, 100% proud of the Moai cylinder surface!)
			var door_r: float = 0.46
			add_box(root, Vector3(door_r * 2.0, d_arch_y - 0.02, 0.08), Vector3(0, (d_arch_y + 0.02) * 0.5, 2.09), door_wood_mat)
			add_cylinder(root, door_r, door_r, 0.08, Vector3(0, d_arch_y, 2.09), door_wood_mat, Vector3(90, 0, 0))

			# Vertical wood plank strips & dark plank seam grooves across the arched door (matching reference!)
			for pi: int in range(-3, 4):
				var px: float = float(pi) * 0.125
				var dy_arch: float = sqrt(maxf(0.0, door_r * door_r - px * px))
				var p_top: float = d_arch_y + dy_arch - 0.02
				var p_h: float = p_top - 0.02
				if pi % 2 == 0 and abs(pi) < 3:
					add_box(root, Vector3(0.10, p_h, 0.084), Vector3(px, 0.02 + p_h * 0.5, 2.092), door_plank_alt)
				if pi > -3:
					var sx_seam: float = px - 0.0625
					var s_dy: float = sqrt(maxf(0.0, door_r * door_r - sx_seam * sx_seam))
					var s_h: float = (d_arch_y + s_dy - 0.03) - 0.02
					add_box(root, Vector3(0.022, s_h, 0.09), Vector3(sx_seam, 0.02 + s_h * 0.5, 2.098), door_seam_mat)

			# Round Brass Doorknob & Escutcheon Plate on the right side of the door
			add_cylinder(root, 0.055, 0.055, 0.04, Vector3(0.28, 0.78, 2.13), door_seam_mat, Vector3(90, 0, 0))
			add_sphere(root, 0.055, 0.11, Vector3(0.28, 0.78, 2.17), brass_knob_mat)
			# Stone threshold step & stepping slabs at the base of the door (strictly clear of the pad!)
			var step_slab_mat := make_mat(Color("#8B9AA8"), 0.72, 0.10)
			add_box(root, Vector3(1.24, 0.08, 0.34), Vector3(0, 0.045, 2.16), moai_light_mat)
			for si_step: int in range(2):
				add_box(root, Vector3(1.08, 0.036, 0.26), Vector3(0, 0.048, 2.54 + float(si_step) * 0.42), step_slab_mat)

		"rock", "patrick", "patrickrock":
			# Cartoon-accurate materials matching Patrick's Rock reference (media_1790519657076.jpg)
			var rock_mat := get_patrick_rock_material()
			var rock_shadow_mat := make_mat(Color("#471D0C"), 0.88, 0.0)
			var sand_rim_mat := make_mat(Color("#C9BF97"), 0.85, 0.0)
			var sand_groove_mat := make_mat(Color("#8E8462"), 0.88, 0.0)
			var vane_wood_mat := make_mat(Color("#C89D48"), 0.65, 0.10)
			var vane_dark_mat := make_mat(Color("#5E3D16"), 0.75, 0.05)

			# 1. Sculpted Circular Sand Mound Bed & Radial Creases Around the Base (matching reference!)
			add_cylinder(root, 2.76, 2.96, 0.14, Vector3(0, 0.07, 0), sand_rim_mat)
			add_torus(root, 2.48, 2.86, Vector3(0, 0.12, 0), sand_rim_mat)
			for s_idx: int in range(18):
				var s_deg: float = float(s_idx) * 20.0
				var s_rad: float = deg_to_rad(s_deg)
				var sx_m: float = sin(s_rad) * 2.68
				var sz_m: float = cos(s_rad) * 2.68
				add_sphere(root, 0.42, 0.22, Vector3(sx_m, 0.12, sz_m), sand_rim_mat)
				# Subtle radial sand crease line between mounds
				var g_rad: float = deg_to_rad(s_deg + 10.0)
				add_box(root, Vector3(0.05, 0.06, 0.34), Vector3(sin(g_rad) * 2.75, 0.13, cos(g_rad) * 2.75), sand_groove_mat, Vector3(12, s_deg + 10.0, 0))

			# 2. True Hemisphere Terracotta-Brown Rock Dome (y = 0.08 to 2.58, r = 2.62m)
			var rock_inst := MeshInstance3D.new()
			var rock_sph := SphereMesh.new()
			rock_sph.is_hemisphere = true
			rock_sph.radius = 2.62
			rock_sph.height = 2.50
			rock_sph.radial_segments = 48
			rock_sph.rings = 24
			rock_inst.mesh = rock_sph
			rock_inst.position = Vector3(0, 0.08, 0)
			rock_inst.material_override = rock_mat
			root.add_child(rock_inst)

			# Subtle dark lower rim shadow collar where the rock meets the sand bed
			add_torus(root, 2.50, 2.64, Vector3(0, 0.15, 0), rock_shadow_mat)

			# 3. Iconic Bamboo/Wood Weather-Vane Arrow Antenna on Top (matching reference media_1790519657076.jpg!)
			var vane_root := Node3D.new()
			# Since West Conch St buildings are rotated Y=+90 deg, rotating vane Y=-90 deg aligns the arrow horizontally facing the street/camera!
			vane_root.position = Vector3(0, 2.56, 0)
			vane_root.rotation_degrees = Vector3(0, -90, 0)
			root.add_child(vane_root)

			# Vertical wooden mast post with dark joint bindings
			add_cylinder(vane_root, 0.055, 0.068, 0.72, Vector3(0, 0.32, 0), vane_wood_mat)
			add_torus(vane_root, 0.055, 0.082, Vector3(0, 0.06, 0), vane_dark_mat)
			add_torus(vane_root, 0.050, 0.078, Vector3(0, 0.54, 0), vane_dark_mat)

			# Horizontal main arrow shaft (along X at y = 0.54)
			add_cylinder(vane_root, 0.042, 0.042, 1.56, Vector3(0, 0.54, 0), vane_wood_mat, Vector3(0, 0, 90))

			# Left Pointed Arrowhead (< shape at x = -0.78) + vertical cross-tick behind tip
			add_box(vane_root, Vector3(0.32, 0.06, 0.05), Vector3(-0.68, 0.63, 0), vane_wood_mat, Vector3(0, 0, 32))
			add_box(vane_root, Vector3(0.32, 0.06, 0.05), Vector3(-0.68, 0.45, 0), vane_wood_mat, Vector3(0, 0, -32))
			add_box(vane_root, Vector3(0.05, 0.28, 0.05), Vector3(-0.46, 0.54, 0), vane_dark_mat)

			# Right Tail Fletching Feathers (3 parallel angled slats top & bottom at x = 0.36..0.72)
			for fi_t: int in range(3):
				var fx_t: float = 0.36 + float(fi_t) * 0.16
				add_box(vane_root, Vector3(0.24, 0.048, 0.045), Vector3(fx_t, 0.63, 0), vane_wood_mat, Vector3(0, 0, -38))
				add_box(vane_root, Vector3(0.24, 0.048, 0.045), Vector3(fx_t, 0.45, 0), vane_wood_mat, Vector3(0, 0, 38))
			add_box(vane_root, Vector3(0.045, 0.32, 0.05), Vector3(0.52, 0.54, 0), vane_dark_mat)


		"summonaltar", "summon", "altar":
			# Detailed Wooden Merchant Kiosk with Crates/Chests & 4-Armed Fox Mystic Merchant (matching media_1790521357292.jpg)
			var kiosk_wood_dark := make_mat(Color("#3D2314"), 0.80, 0.05)
			var kiosk_wood_mid := make_mat(Color("#6E4224"), 0.75, 0.05)
			var kiosk_wood_light := make_mat(Color("#9C6438"), 0.72, 0.05)
			var crate_wood_mat := make_mat(Color("#B87B42"), 0.74, 0.04)
			var crate_dark_mat := make_mat(Color("#7A4B22"), 0.78, 0.04)
			var iron_band_mat := make_mat(Color("#2B343B"), 0.42, 0.75)
			var gold_trim_mat := make_mat(Color("#E5B52B"), 0.28, 0.85, Color("#B7860B") * 0.25)
			var awning_teal_mat := make_mat(Color("#2F7680"), 0.68, 0.05)
			var awning_cream_mat := make_mat(Color("#F0DFC4"), 0.70, 0.05)
			var cyan_crystal_mat := make_mat(Color("#2CE6FF"), 0.08, 0.15, Color("#00D8FF") * 1.85)
			var cyan_core_mat := make_mat(Color("#B8FCFF"), 0.05, 0.10, Color("#70F3FF") * 2.20)
			var cyan_glass_mat := make_mat(Color("#45D9F5"), 0.12, 0.20, Color("#19B5FE") * 0.95, 0.72)

			# ------------------------------------------------------------------
			# 1. WOODEN KIOSK PAVILION STRUCTURE (Raised Deck, 4 Posts, Counters, Shelves & Striped Roof)
			# ------------------------------------------------------------------
			# Raised wooden plank floor platform (6.4m wide x 4.6m deep, y = 0.0..0.24)
			add_box(root, Vector3(6.40, 0.22, 4.60), Vector3(0, 0.11, 0), kiosk_wood_dark)
			add_box(root, Vector3(6.16, 0.04, 4.36), Vector3(0, 0.23, 0), kiosk_wood_mid)
			for f_idx: int in range(-7, 8):
				add_box(root, Vector3(0.38, 0.02, 4.32), Vector3(float(f_idx) * 0.40, 0.25, 0), kiosk_wood_light if f_idx % 2 == 0 else kiosk_wood_mid)
			# Front step threshold
			add_box(root, Vector3(2.80, 0.12, 0.46), Vector3(0, 0.06, 2.48), kiosk_wood_mid)

			# 4 Heavy Carved Corner Timber Posts & Diagonal Roof Braces
			for px_s: float in [-1.0, 1.0]:
				for pz_s: float in [-1.0, 1.0]:
					var post_x: float = px_s * 2.85
					var post_z: float = pz_s * 1.95
					add_box(root, Vector3(0.30, 4.10, 0.30), Vector3(post_x, 2.25, post_z), kiosk_wood_dark)
					add_box(root, Vector3(0.36, 0.24, 0.36), Vector3(post_x, 0.36, post_z), iron_band_mat)
					add_box(root, Vector3(0.34, 0.20, 0.34), Vector3(post_x, 4.15, post_z), iron_band_mat)
					add_box(root, Vector3(0.55, 0.14, 0.14), Vector3(post_x - px_s * 0.32, 3.82, post_z), kiosk_wood_mid, Vector3(0, 0, px_s * 42.0))

			# Back Timber Wall & Multi-Tier Crate Display Shelving (z = -1.95)
			add_box(root, Vector3(5.70, 3.85, 0.18), Vector3(0, 2.15, -1.95), kiosk_wood_dark)
			for w_slat: int in range(6):
				add_box(root, Vector3(5.56, 0.56, 0.06), Vector3(0, 0.62 + float(w_slat) * 0.60, -1.84), kiosk_wood_mid if w_slat % 2 == 0 else kiosk_wood_dark)
			# Rear wooden shelf ledges at y = 1.45 and y = 2.65
			add_box(root, Vector3(5.40, 0.12, 0.95), Vector3(0, 1.45, -1.40), kiosk_wood_light)
			add_box(root, Vector3(5.40, 0.12, 0.85), Vector3(0, 2.65, -1.45), kiosk_wood_light)

			# Side Half-Walls & Split Front Wooden Service Counters (leaving center x = [-1.18, 1.18] open so the Merchant is 100% visible!)
			for side_s: float in [-1.0, 1.0]:
				# Side counter wall
				add_box(root, Vector3(0.22, 1.15, 3.90), Vector3(side_s * 2.85, 0.82, 0.0), kiosk_wood_mid)
				add_box(root, Vector3(0.32, 0.10, 4.02), Vector3(side_s * 2.85, 1.42, 0.0), kiosk_wood_light)
				# Front L-wing counter bay (x = 1.18..2.85 and -2.85..-1.18, z = 1.62..2.12)
				var cw_x: float = side_s * 2.02
				add_box(root, Vector3(1.68, 1.08, 0.68), Vector3(cw_x, 0.78, 1.82), kiosk_wood_mid)
				add_box(root, Vector3(1.78, 0.10, 0.82), Vector3(cw_x, 1.35, 1.82), kiosk_wood_light)
				add_box(root, Vector3(1.62, 0.86, 0.06), Vector3(cw_x, 0.78, 2.17), kiosk_wood_dark)

			# Slanted Striped Market Kiosk Canopy Roof (y = 4.18..4.95)
			add_box(root, Vector3(6.60, 0.18, 5.10), Vector3(0, 4.48, 0.10), kiosk_wood_dark, Vector3(8.5, 0, 0))
			var stripe_count: int = 9
			var stripe_w: float = 6.48 / float(stripe_count)
			for st_i: int in range(stripe_count):
				var st_x: float = -3.24 + (float(st_i) + 0.5) * stripe_w
				var st_mat: StandardMaterial3D = awning_teal_mat if st_i % 2 == 0 else awning_cream_mat
				add_box(root, Vector3(stripe_w + 0.02, 0.10, 5.18), Vector3(st_x, 4.58, 0.12), st_mat, Vector3(8.5, 0, 0))
				# Front scalloped awning valance flap
				add_box(root, Vector3(stripe_w - 0.02, 0.34, 0.08), Vector3(st_x, 4.06, 2.66), st_mat)
				add_cylinder(root, stripe_w * 0.48, stripe_w * 0.48, 0.08, Vector3(st_x, 3.89, 2.66), st_mat, Vector3(90, 0, 0))

			# Carved Wooden Kiosk Header Signboard
			add_box(root, Vector3(4.30, 0.68, 0.16), Vector3(0, 4.58, 2.58), kiosk_wood_dark)
			add_box(root, Vector3(4.12, 0.52, 0.18), Vector3(0, 4.58, 2.59), kiosk_wood_mid)
			var kiosk_lbl := Label3D.new()
			kiosk_lbl.text = "MYSTIC CRATES KIOSK"
			kiosk_lbl.font = UIThemeBuilder.get_title_font()
			kiosk_lbl.font_size = 50
			kiosk_lbl.pixel_size = 0.0055
			kiosk_lbl.outline_size = 14
			kiosk_lbl.modulate = Color("#FFE066")
			kiosk_lbl.outline_modulate = Color("#1F1108")
			kiosk_lbl.position = Vector3(0, 4.58, 2.70)
			kiosk_lbl.no_depth_test = true
			kiosk_lbl.render_priority = 10
			root.add_child(kiosk_lbl)

			# ------------------------------------------------------------------
			# 2. STACKED WOODEN CRATES & TREASURE CHESTS INSIDE THE KIOSK (Storage Crates)
			# ------------------------------------------------------------------
			var crate_configs: Array[Dictionary] = [
				# Floor stacks on Left & Right inside the kiosk
				{"pos": Vector3(-2.15, 0.66, -0.45), "sz": Vector3(0.84, 0.84, 0.84), "rot": 12.0},
				{"pos": Vector3(-2.22, 1.40, -0.50), "sz": Vector3(0.66, 0.66, 0.66), "rot": -18.0},
				{"pos": Vector3(-1.38, 0.58, -0.78), "sz": Vector3(0.70, 0.70, 0.70), "rot": 6.0},
				{"pos": Vector3(2.15, 0.66, -0.45), "sz": Vector3(0.84, 0.84, 0.84), "rot": -10.0},
				{"pos": Vector3(2.20, 1.40, -0.48), "sz": Vector3(0.66, 0.66, 0.66), "rot": 22.0},
				{"pos": Vector3(1.42, 0.58, -0.82), "sz": Vector3(0.70, 0.70, 0.70), "rot": -8.0},
				# Back lower shelf crates (y = 1.51)
				{"pos": Vector3(-2.05, 1.88, -1.38), "sz": Vector3(0.74, 0.74, 0.74), "rot": 8.0},
				{"pos": Vector3(2.05, 1.88, -1.38), "sz": Vector3(0.74, 0.74, 0.74), "rot": -14.0},
				# Back upper shelf crates (y = 2.71)
				{"pos": Vector3(-1.95, 3.06, -1.42), "sz": Vector3(0.62, 0.62, 0.62), "rot": -6.0},
				{"pos": Vector3(-1.15, 3.02, -1.44), "sz": Vector3(0.54, 0.54, 0.54), "rot": 15.0},
				{"pos": Vector3(1.18, 3.02, -1.44), "sz": Vector3(0.54, 0.54, 0.54), "rot": -12.0},
				{"pos": Vector3(1.98, 3.06, -1.42), "sz": Vector3(0.62, 0.62, 0.62), "rot": 9.0},
				# Front counter crates
				{"pos": Vector3(-2.32, 1.70, 1.78), "sz": Vector3(0.60, 0.60, 0.60), "rot": 18.0},
				{"pos": Vector3(2.34, 1.68, 1.80), "sz": Vector3(0.56, 0.56, 0.56), "rot": -16.0}
			]
			for cc: Dictionary in crate_configs:
				var c_root := Node3D.new()
				c_root.position = cc["pos"]
				c_root.rotation_degrees = Vector3(0, float(cc["rot"]), 0)
				root.add_child(c_root)
				var cs: Vector3 = cc["sz"]
				# Inner planked box
				add_box(c_root, cs * 0.92, Vector3.ZERO, crate_wood_mat)
				# Outer slatted corner frame & diagonal cross braces
				for cx_s: float in [-1.0, 1.0]:
					for cy_s: float in [-1.0, 1.0]:
						add_box(c_root, Vector3(cs.x, cs.y * 0.14, cs.z * 0.14), Vector3(0, cy_s * cs.y * 0.43, cx_s * cs.z * 0.43), crate_dark_mat)
						add_box(c_root, Vector3(cs.x * 0.14, cs.y, cs.z * 0.14), Vector3(cx_s * cs.x * 0.43, 0, cy_s * cs.z * 0.43), crate_dark_mat)
						add_box(c_root, Vector3(cs.x * 0.14, cs.y * 0.14, cs.z), Vector3(cx_s * cs.x * 0.43, cy_s * cs.y * 0.43, 0), crate_dark_mat)
				add_box(c_root, Vector3(cs.x * 0.96, cs.y * 0.12, cs.z * 0.96), Vector3.ZERO, crate_dark_mat, Vector3(0, 0, 42))

			# Ornate Banded Treasure / Summon Chests on Counters & Shelves
			var chest_configs: Array[Dictionary] = [
				{"pos": Vector3(-1.58, 1.40, 1.82), "rot": 10.0, "open": true},
				{"pos": Vector3(1.62, 1.40, 1.82), "rot": -12.0, "open": false},
				{"pos": Vector3(-1.18, 1.51, -1.36), "rot": 4.0, "open": false},
				{"pos": Vector3(1.18, 1.51, -1.36), "rot": -5.0, "open": true},
				{"pos": Vector3(0.0, 2.71, -1.42), "rot": 0.0, "open": false}
			]
			for ch_cfg: Dictionary in chest_configs:
				var ch_node := Node3D.new()
				ch_node.position = ch_cfg["pos"]
				ch_node.rotation_degrees = Vector3(0, float(ch_cfg["rot"]), 0)
				root.add_child(ch_node)
				add_box(ch_node, Vector3(0.68, 0.34, 0.46), Vector3(0, 0.17, 0), kiosk_wood_dark)
				add_box(ch_node, Vector3(0.70, 0.32, 0.06), Vector3(0, 0.17, 0.21), gold_trim_mat)
				add_box(ch_node, Vector3(0.10, 0.36, 0.48), Vector3(-0.24, 0.17, 0), gold_trim_mat)
				add_box(ch_node, Vector3(0.10, 0.36, 0.48), Vector3(0.24, 0.17, 0), gold_trim_mat)
				if bool(ch_cfg["open"]):
					add_cylinder(ch_node, 0.22, 0.22, 0.68, Vector3(0, 0.42, -0.14), kiosk_wood_mid, Vector3(-35, 0, 90))
					add_sphere(ch_node, 0.16, 0.22, Vector3(-0.12, 0.36, 0.04), cyan_crystal_mat)
					add_sphere(ch_node, 0.14, 0.18, Vector3(0.12, 0.35, 0.05), gold_trim_mat)
				else:
					add_cylinder(ch_node, 0.23, 0.23, 0.68, Vector3(0, 0.34, 0), kiosk_wood_mid, Vector3(0, 0, 90))
					add_box(ch_node, Vector3(0.12, 0.16, 0.06), Vector3(0, 0.30, 0.24), gold_trim_mat)

			# ------------------------------------------------------------------
			# 3. THE 4-ARMED FOX-FENNEC MYSTIC TRAVELER MERCHANT INSIDE THE KIOSK
			#    (100% faithful to media_1790521357292.jpg!)
			# ------------------------------------------------------------------
			var merch := Node3D.new()
			merch.name = "MysticFoxMerchant"
			merch.position = Vector3(0.0, 0.25, 0.38)
			merch.scale = Vector3(1.08, 1.08, 1.08)
			root.add_child(merch)

			# Character Palette Materials matching media_1790521357292.jpg
			var fur_gold_mat := make_mat(Color("#DF9E52"), 0.62, 0.02)
			var fur_cream_mat := make_mat(Color("#F6E2C4"), 0.60, 0.02)
			var fur_orange_mat := make_mat(Color("#CC6A1E"), 0.65, 0.02)
			var ear_tip_mat := make_mat(Color("#21150D"), 0.75, 0.02)
			var coat_dark_mat := make_mat(Color("#382012"), 0.74, 0.06)
			var coat_trim_mat := make_mat(Color("#7C431E"), 0.68, 0.08)
			var satchel_leather_mat := make_mat(Color("#B26226"), 0.58, 0.10)
			var satchel_flap_mat := make_mat(Color("#C87533"), 0.54, 0.10)
			var pack_tan_mat := make_mat(Color("#9E6B3B"), 0.72, 0.05)
			var scarf_teal_mat := make_mat(Color("#3C848C"), 0.64, 0.05)
			var scarf_light_mat := make_mat(Color("#54A2AB"), 0.60, 0.05)
			var shirt_cream_mat := make_mat(Color("#DEDAD0"), 0.70, 0.02)
			var pants_olive_mat := make_mat(Color("#6E532B"), 0.75, 0.03)
			var glove_brown_mat := make_mat(Color("#7A5330"), 0.68, 0.06)
			var cuff_cyan_mat := make_mat(Color("#4CA5B0"), 0.50, 0.12)
			var buckle_silver_mat := make_mat(Color("#C8D4D8"), 0.25, 0.85)
			var copper_ring_mat := make_mat(Color("#C87A28"), 0.30, 0.78)
			var lantern_teal_mat := make_mat(Color("#247482"), 0.35, 0.55)
			var staff_wood_mat := make_mat(Color("#6A3D1E"), 0.76, 0.05)
			var halo_sun_mat := make_mat(Color("#FFF0D2"), 0.20, 0.0, Color("#F5CBA7") * 0.55, 0.38)

			# Subtle Sunlit Halo Disc Backdrop behind Merchant's head/shoulders (matching reference illustration)
			add_cylinder(merch, 1.18, 1.18, 0.04, Vector3(0.0, 2.15, -0.52), halo_sun_mat, Vector3(90, 0, 0))

			# --- A. STANCE, BAGGY TROUSERS & 4-TOED CLAWED FEET ---
			for leg_s: float in [-1.0, 1.0]:
				var lx: float = leg_s * 0.40
				# Baggy olive-brown thigh & knee
				add_sphere(merch, 0.28, 0.58, Vector3(lx, 0.62, 0.04), pants_olive_mat, Vector3(0, 0, -leg_s * 10.0))
				# Dark brown leather open-toed foot-wrap & ankle cuff
				add_cylinder(merch, 0.15, 0.18, 0.34, Vector3(lx * 1.05, 0.24, 0.06), coat_dark_mat, Vector3(8, 0, -leg_s * 6.0))
				add_box(merch, Vector3(0.28, 0.14, 0.36), Vector3(lx * 1.06, 0.09, 0.16), coat_dark_mat, Vector3(0, -leg_s * 12.0, 0))
				# 4 distinct sandy-tan furry toes with dark claws sticking out the front!
				for toe_i: int in range(4):
					var toe_off_x: float = (float(toe_i) - 1.5) * 0.062
					var toe_pos := Vector3(lx * 1.06 + toe_off_x, 0.055, 0.35)
					add_sphere(merch, 0.036, 0.07, toe_pos, fur_gold_mat)
					add_cylinder(merch, 0.006, 0.020, 0.05, toe_pos + Vector3(0, -0.01, 0.04), ear_tip_mat, Vector3(75, 0, 0))

			# --- B. BUSHY GOLDEN-ORANGE & CREAM FOX TAIL (Sweeping out to viewer's left) ---
			var tail_root := Node3D.new()
			tail_root.position = Vector3(-0.32, 0.72, -0.22)
			tail_root.rotation_degrees = Vector3(10, -18, 52)
			merch.add_child(tail_root)
			add_sphere(tail_root, 0.22, 0.56, Vector3(-0.22, -0.18, 0), fur_orange_mat, Vector3(0, 0, -35))
			add_sphere(tail_root, 0.24, 0.62, Vector3(-0.52, -0.32, 0.04), fur_orange_mat, Vector3(0, 0, -55))
			add_sphere(tail_root, 0.19, 0.52, Vector3(-0.84, -0.34, 0.08), fur_cream_mat, Vector3(0, 0, -72))

			# --- C. TORSO, OPEN DARK LEATHER COAT, PLEATED SASH & FRONT LEATHER WAIST SATCHEL ---
			# Core torso & cream pleated shirt with teal V-collar
			add_cylinder(merch, 0.48, 0.44, 1.16, Vector3(0, 1.38, 0.02), shirt_cream_mat)
			add_box(merch, Vector3(0.32, 0.34, 0.14), Vector3(0, 1.72, 0.38), shirt_cream_mat)
			add_box(merch, Vector3(0.10, 0.26, 0.15), Vector3(-0.08, 1.76, 0.40), scarf_teal_mat, Vector3(0, 0, 22))
			add_box(merch, Vector3(0.10, 0.26, 0.15), Vector3(0.08, 1.76, 0.40), scarf_teal_mat, Vector3(0, 0, -22))
			# Brown leather chest armor plate & diagonal harness straps
			add_sphere(merch, 0.26, 0.32, Vector3(0.0, 1.56, 0.34), satchel_leather_mat)
			add_box(merch, Vector3(0.11, 0.78, 0.10), Vector3(-0.14, 1.54, 0.40), coat_trim_mat, Vector3(0, 0, -28))
			add_box(merch, Vector3(0.11, 0.78, 0.10), Vector3(0.22, 1.54, 0.38), coat_trim_mat, Vector3(0, 0, 16))
			# Teal pleated waist sash
			for sash_i: int in range(3):
				add_torus(merch, 0.38, 0.48, Vector3(0, 1.22 + float(sash_i) * 0.07, 0.04), scarf_teal_mat)

			# Flared Open Dark-Brown Traveler Coat (Left & Right panels with saddle-brown trim & silver buckles)
			for c_side: float in [-1.0, 1.0]:
				var panel_node := Node3D.new()
				panel_node.position = Vector3(c_side * 0.42, 1.12, 0.0)
				panel_node.rotation_degrees = Vector3(0, c_side * 14.0, -c_side * 16.0)
				merch.add_child(panel_node)
				add_box(panel_node, Vector3(0.36, 1.38, 0.68), Vector3(0, 0, 0), coat_dark_mat)
				# Saddle-brown front coat lapel & bottom border trim
				add_box(panel_node, Vector3(0.09, 1.40, 0.12), Vector3(-c_side * 0.16, 0, 0.32), coat_trim_mat)
				add_box(panel_node, Vector3(0.38, 0.09, 0.70), Vector3(0, -0.66, 0), coat_trim_mat)
				# 3 silver belt-strap buckles along each front coat edge
				for bk_i: int in range(3):
					var bky: float = -0.46 + float(bk_i) * 0.42
					add_box(panel_node, Vector3(0.14, 0.06, 0.08), Vector3(-c_side * 0.16, bky, 0.35), coat_trim_mat)
					add_box(panel_node, Vector3(0.08, 0.09, 0.09), Vector3(-c_side * 0.18, bky, 0.36), buckle_silver_mat)
			# Rear coat back panel
			add_box(merch, Vector3(0.92, 1.42, 0.18), Vector3(0, 1.18, -0.32), coat_dark_mat, Vector3(8, 0, 0))

			# Prominent Front Brown Leather Waist Satchel / Pouch (matching center-front of reference!)
			var satchel_node := Node3D.new()
			satchel_node.position = Vector3(0.03, 1.02, 0.48)
			merch.add_child(satchel_node)
			add_box(satchel_node, Vector3(0.56, 0.38, 0.22), Vector3(0, 0, 0), satchel_leather_mat)
			add_box(satchel_node, Vector3(0.52, 0.22, 0.24), Vector3(0.02, 0.07, 0.02), satchel_flap_mat)
			add_box(satchel_node, Vector3(0.12, 0.24, 0.18), Vector3(-0.28, -0.02, 0.02), satchel_flap_mat)
			add_box(satchel_node, Vector3(0.06, 0.04, 0.04), Vector3(0.04, -0.01, 0.14), buckle_silver_mat)

			# --- D. GIANT LEATHER BACKPACK & ROLLED TEAL BEDROLL ON RIGHT SHOULDER ---
			add_sphere(merch, 0.48, 0.96, Vector3(-0.46, 1.45, -0.34), pack_tan_mat, Vector3(0, 0, 14))
			add_box(merch, Vector3(0.56, 0.18, 0.48), Vector3(-0.44, 1.82, -0.30), coat_trim_mat, Vector3(0, 0, 14))
			# Rolled-up teal sleeping mat / bedroll perched atop his upper-right shoulder
			var bedroll := Node3D.new()
			bedroll.position = Vector3(-0.46, 2.08, -0.14)
			bedroll.rotation_degrees = Vector3(12, 18, 78)
			merch.add_child(bedroll)
			add_cylinder(bedroll, 0.17, 0.17, 0.68, Vector3.ZERO, scarf_teal_mat)
			add_torus(bedroll, 0.09, 0.16, Vector3(0, 0.34, 0), coat_dark_mat)
			add_torus(bedroll, 0.05, 0.09, Vector3(0, 0.35, 0), scarf_light_mat)

			# --- E. THICK DRAPED TEAL SCARF WRAPPED AROUND NECK & SHOULDERS ---
			add_torus(merch, 0.36, 0.56, Vector3(0.0, 1.96, 0.06), scarf_teal_mat, Vector3(8, 0, -4))
			add_torus(merch, 0.32, 0.50, Vector3(0.02, 2.06, 0.08), scarf_light_mat, Vector3(10, 0, 5))
			add_box(merch, Vector3(0.88, 0.18, 0.46), Vector3(-0.06, 1.98, 0.14), scarf_teal_mat, Vector3(12, 0, -8))

			# --- F. FOX/FENNEC HEAD, MUZZLE, EYES, LONG EARS & BUCKLED TRAVELER HAT ---
			var head_node := Node3D.new()
			head_node.position = Vector3(0.0, 2.28, 0.12)
			merch.add_child(head_node)
			# Golden-tan furry head & fluffy cheek ruffs
			add_sphere(head_node, 0.34, 0.56, Vector3(0, 0, 0), fur_gold_mat)
			for ch_s: float in [-1.0, 1.0]:
				add_sphere(head_node, 0.22, 0.26, Vector3(ch_s * 0.24, -0.04, 0.12), fur_cream_mat)
			# Cream muzzle & dark triangular fox nose
			add_sphere(head_node, 0.17, 0.22, Vector3(0, -0.06, 0.26), fur_cream_mat)
			add_sphere(head_node, 0.055, 0.075, Vector3(0, -0.02, 0.38), ear_tip_mat)
			# Warm amber-brown eyes, dark pupils & furrowed brow ridges
			for eye_s: float in [-1.0, 1.0]:
				add_sphere(head_node, 0.048, 0.08, Vector3(eye_s * 0.12, 0.06, 0.29), coat_trim_mat)
				add_sphere(head_node, 0.028, 0.05, Vector3(eye_s * 0.12, 0.06, 0.32), ear_tip_mat)
				add_box(head_node, Vector3(0.13, 0.035, 0.06), Vector3(eye_s * 0.12, 0.11, 0.30), fur_gold_mat, Vector3(0, 0, -eye_s * 12.0))

			# Long Horizontal Pointed Fennec Ears sticking out beneath the hat brim!
			for ear_s: float in [-1.0, 1.0]:
				var ear_pivot := Node3D.new()
				ear_pivot.position = Vector3(ear_s * 0.28, 0.06, 0.04)
				ear_pivot.rotation_degrees = Vector3(0, -ear_s * 10.0, ear_s * 102.0)
				head_node.add_child(ear_pivot)
				add_cylinder(ear_pivot, 0.04, 0.13, 0.44, Vector3(0, 0.22, 0), fur_gold_mat)
				add_cylinder(ear_pivot, 0.02, 0.09, 0.36, Vector3(0, 0.20, 0.03), fur_cream_mat)
				add_cylinder(ear_pivot, 0.005, 0.045, 0.14, Vector3(0, 0.48, 0), ear_tip_mat)

			# Wide-Brimmed Dark Leather Hat with Teal Hatband & Silver Front Buckle
			var hat_node := Node3D.new()
			hat_node.position = Vector3(0, 0.18, 0.0)
			hat_node.rotation_degrees = Vector3(-5, 0, -3)
			head_node.add_child(hat_node)
			# Wide curved brim
			add_cylinder(hat_node, 0.68, 0.74, 0.05, Vector3(0, 0, 0.02), coat_dark_mat)
			add_torus(hat_node, 0.58, 0.72, Vector3(0, -0.01, 0.02), coat_dark_mat)
			# Tapered leather hat crown
			add_cylinder(hat_node, 0.22, 0.38, 0.38, Vector3(0, 0.19, 0.0), coat_dark_mat)
			add_sphere(hat_node, 0.23, 0.18, Vector3(0.02, 0.36, -0.02), coat_dark_mat)
			# Teal hatband ribbon
			add_cylinder(hat_node, 0.35, 0.39, 0.11, Vector3(0, 0.07, 0.0), scarf_teal_mat)
			# Prominent Silver Rectangular Front Hat Buckle
			add_box(hat_node, Vector3(0.18, 0.13, 0.05), Vector3(-0.02, 0.08, 0.37), buckle_silver_mat, Vector3(-12, 0, -4))
			add_box(hat_node, Vector3(0.11, 0.07, 0.06), Vector3(-0.02, 0.08, 0.375), scarf_teal_mat, Vector3(-12, 0, -4))

			# --- G. ALL FOUR GLOVED ARMS (All 4 Arms) WITH TURQUOISE WRIST CUFFS ---
			# 1) Upper-Right Arm (Viewer's Left Foreground): Extended forward holding the Glowing Cyan Magic Lantern!
			var arm_ur := Node3D.new()
			arm_ur.position = Vector3(-0.46, 1.72, 0.22)
			merch.add_child(arm_ur)
			add_cylinder(arm_ur, 0.14, 0.16, 0.38, Vector3(0, 0, 0.16), coat_dark_mat, Vector3(82, 0, 0))
			add_torus(arm_ur, 0.11, 0.15, Vector3(0, 0.02, 0.34), cuff_cyan_mat, Vector3(85, 0, 0))
			add_sphere(arm_ur, 0.13, 0.22, Vector3(0, 0.04, 0.44), glove_brown_mat)
			# Copper-gold lantern suspension ring & Hexagonal Glowing Cyan Magic Lantern
			add_torus(arm_ur, 0.15, 0.19, Vector3(0, -0.11, 0.46), copper_ring_mat, Vector3(90, 0, 0))
			var lantern_node := Node3D.new()
			lantern_node.position = Vector3(0, -0.48, 0.46)
			arm_ur.add_child(lantern_node)
			# Top dome & bottom base of teal lantern
			add_cylinder(lantern_node, 0.14, 0.21, 0.09, Vector3(0, 0.22, 0), copper_ring_mat)
			add_cylinder(lantern_node, 0.20, 0.20, 0.06, Vector3(0, 0.16, 0), lantern_teal_mat)
			add_cylinder(lantern_node, 0.21, 0.19, 0.08, Vector3(0, -0.22, 0), lantern_teal_mat)
			# Glowing cyan glass chamber & bright crystal core inside lantern
			add_cylinder(lantern_node, 0.16, 0.16, 0.34, Vector3(0, -0.03, 0), cyan_glass_mat)
			add_sphere(lantern_node, 0.11, 0.22, Vector3(0, -0.03, 0), cyan_core_mat)
			for l_strut: int in range(6):
				var ls_rad: float = deg_to_rad(float(l_strut) * 60.0)
				add_cylinder(lantern_node, 0.018, 0.018, 0.36, Vector3(sin(ls_rad) * 0.175, -0.03, cos(ls_rad) * 0.175), lantern_teal_mat)

			# 2) Lower-Right Arm (Viewer's Left Inner): Bent across chest gripping leather harness strap!
			var arm_lr := Node3D.new()
			arm_lr.position = Vector3(-0.34, 1.48, 0.24)
			merch.add_child(arm_lr)
			add_cylinder(arm_lr, 0.13, 0.15, 0.34, Vector3(0.08, 0.04, 0.10), glove_brown_mat, Vector3(65, 28, -45))
			add_torus(arm_lr, 0.10, 0.14, Vector3(0.16, 0.08, 0.18), cuff_cyan_mat, Vector3(70, 40, 0))
			add_sphere(arm_lr, 0.12, 0.20, Vector3(0.24, 0.10, 0.22), glove_brown_mat)

			# 3) Upper-Left Arm (Viewer's Right Upper): Raised holding the Wooden Smoking Pipe!
			var arm_ul := Node3D.new()
			arm_ul.position = Vector3(0.46, 1.76, 0.18)
			merch.add_child(arm_ul)
			add_cylinder(arm_ul, 0.13, 0.15, 0.38, Vector3(0.12, 0.08, 0.10), coat_dark_mat, Vector3(45, -25, -48))
			add_torus(arm_ul, 0.10, 0.14, Vector3(0.22, 0.18, 0.18), cuff_cyan_mat, Vector3(35, -20, -40))
			add_sphere(arm_ul, 0.12, 0.20, Vector3(0.28, 0.28, 0.22), glove_brown_mat)
			# Long slender wooden smoking pipe angling from hand toward muzzle
			add_cylinder(arm_ul, 0.016, 0.022, 0.44, Vector3(0.14, 0.39, 0.24), kiosk_wood_dark, Vector3(0, 0, 68))
			add_cylinder(arm_ul, 0.052, 0.038, 0.14, Vector3(0.34, 0.34, 0.24), satchel_leather_mat, Vector3(0, 0, -18))
			add_sphere(arm_ul, 0.038, 0.03, Vector3(0.35, 0.41, 0.24), fur_orange_mat)

			# 4) Lower-Left Arm (Viewer's Right Lower): Extended outward gripping the Tall Gnarled Crystal Magic Staff!
			var arm_ll := Node3D.new()
			arm_ll.position = Vector3(0.46, 1.46, 0.16)
			merch.add_child(arm_ll)
			add_cylinder(arm_ll, 0.12, 0.14, 0.42, Vector3(0.18, 0.02, 0.08), coat_dark_mat, Vector3(20, -15, -78))
			add_torus(arm_ll, 0.10, 0.14, Vector3(0.34, 0.04, 0.12), cuff_cyan_mat, Vector3(0, 0, 90))
			add_sphere(arm_ll, 0.12, 0.21, Vector3(0.44, 0.05, 0.14), glove_brown_mat)

			# Tall Gnarled Wooden Magic Staff with Glowing Cyan Crystal Head (matching right side of reference!)
			var staff_node := Node3D.new()
			staff_node.position = Vector3(0.92, 0.0, 0.30)
			staff_node.rotation_degrees = Vector3(0, 0, -6.5)
			merch.add_child(staff_node)
			# Multi-segment gnarled root-wood shaft (y = 0.0..2.95)
			add_cylinder(staff_node, 0.048, 0.032, 0.95, Vector3(0.0, 0.47, 0), staff_wood_mat, Vector3(0, 0, 3))
			add_cylinder(staff_node, 0.054, 0.046, 1.05, Vector3(-0.02, 1.42, 0), staff_wood_mat, Vector3(0, 0, -4))
			add_cylinder(staff_node, 0.062, 0.052, 0.95, Vector3(0.01, 2.38, 0), staff_wood_mat, Vector3(0, 0, 5))
			# Sculpted wooden hood/claw cradle at top of staff (y = 2.82..3.36)
			add_box(staff_node, Vector3(0.14, 0.46, 0.16), Vector3(-0.08, 3.05, 0), staff_wood_mat, Vector3(0, 0, -28))
			add_box(staff_node, Vector3(0.38, 0.15, 0.18), Vector3(-0.14, 3.26, 0), staff_wood_mat, Vector3(0, 0, 18))
			add_box(staff_node, Vector3(0.12, 0.38, 0.15), Vector3(0.14, 3.04, 0), staff_wood_mat, Vector3(0, 0, 32))
			# Brilliant Glowing Faceted Cyan Magic Crystal nested inside the staff head!
			add_box(staff_node, Vector3(0.24, 0.28, 0.22), Vector3(0.02, 3.04, 0.02), cyan_crystal_mat, Vector3(25, 35, 40))
			add_sphere(staff_node, 0.14, 0.24, Vector3(0.02, 3.04, 0.04), cyan_core_mat)
			add_torus(staff_node, 0.16, 0.20, Vector3(0.02, 3.04, 0.02), cyan_crystal_mat, Vector3(45, 30, 0))


		"treedome", "afkchamber", "afk", "sandy":
			# Cartoon-accurate materials matching Sandy's Treedome reference (media_1790515476802.jpg)
			var glass_mat = make_mat(Color("#D4F1F9"), 0.06, 0.15, Color("#7AD7F0") * 0.20, 0.28)
			glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			var base_ring_mat = make_mat(Color("#546E7A"), 0.38, 0.65)
			var grass_mat = make_mat(Color("#55AB29"), 0.78, 0.0)
			var grass_mound_mat = make_mat(Color("#479620"), 0.80, 0.0)
			var grass_light_mat = make_mat(Color("#66C236"), 0.75, 0.0)
			var trunk_mat = make_mat(Color("#6D441E"), 0.82, 0.0)
			var bark_dark_mat = make_mat(Color("#4C2E11"), 0.86, 0.0)
			var leaf_dark_mat = make_mat(Color("#24681A"), 0.68, 0.0)
			var leaf_mid_mat = make_mat(Color("#378D28"), 0.64, 0.0)
			var leaf_light_mat = make_mat(Color("#4EB03A"), 0.60, 0.0)
			var table_white_mat = make_mat(Color("#F0F4F7"), 0.45, 0.05)
			var table_shadow_mat = make_mat(Color("#B0BEC5"), 0.55, 0.1)
			var airlock_blue_mat = make_mat(Color("#5B7794"), 0.42, 0.50)
			var airlock_rib_mat = make_mat(Color("#3F5770"), 0.46, 0.58)
			var airlock_dark_mat = make_mat(Color("#283848"), 0.50, 0.65)
			var rivet_mat = make_mat(Color("#90A4AE"), 0.30, 0.75)
			var brass_mat = make_mat(Color("#D4AC0D"), 0.30, 0.80)

			# 1. Sealed Base Foundation Collar & Lush Green Grass Lawn Floor Inside the Dome
			add_cylinder(root, 3.74, 3.82, 0.14, Vector3(0, 0.07, 0), base_ring_mat)
			add_torus(root, 3.55, 3.80, Vector3(0, 0.13, 0), base_ring_mat)
			add_cylinder(root, 3.58, 3.62, 0.16, Vector3(0, 0.09, 0), grass_mat)

			# Subtle rolling grassy mounds & lawn details inside the dome
			add_sphere(root, 1.45, 0.22, Vector3(-0.20, 0.16, -0.20), grass_mound_mat)
			add_sphere(root, 1.10, 0.16, Vector3(1.25, 0.15, 0.80), grass_light_mat)
			add_sphere(root, 0.95, 0.15, Vector3(-1.45, 0.15, 0.70), grass_light_mat)
			add_sphere(root, 1.05, 0.16, Vector3(0.85, 0.15, -1.35), grass_mound_mat)

			# 2. Giant Texas Oak Tree (Gnarled roots, textured trunk, spreading branches & multi-layered canopy)
			var tree_root = Node3D.new()
			tree_root.position = Vector3(-0.18, 0.0, -0.22)
			root.add_child(tree_root)

			# Flaring root buttresses at base of trunk
			for ri in range(6):
				var rang = deg_to_rad(ri * 60.0 + 15.0)
				var rx = sin(rang) * 0.52
				var rz = cos(rang) * 0.52
				add_cylinder(tree_root, 0.12, 0.26, 0.68, Vector3(rx, 0.34, rz), trunk_mat, Vector3(-cos(rang) * 34.0, 0, sin(rang) * 34.0))

			# Main sturdy sculpted oak trunk
			add_cylinder(tree_root, 0.46, 0.62, 1.65, Vector3(0, 0.92, 0), trunk_mat)
			# Vertical bark groove ridges
			for bi in range(8):
				var bang = deg_to_rad(bi * 45.0)
				add_box(tree_root, Vector3(0.07, 1.45, 0.09), Vector3(sin(bang) * 0.49, 0.92, cos(bang) * 0.49), bark_dark_mat, Vector3(0, bi * 45.0, 0))

			# Small wooden tree-trunk door & brass knob at base
			add_box(tree_root, Vector3(0.38, 0.62, 0.08), Vector3(0.0, 0.48, 0.54), bark_dark_mat)
			add_sphere(tree_root, 0.04, 0.04, Vector3(0.11, 0.48, 0.59), brass_mat)

			# Spreading forked upper wooden branches visibly supporting the canopy (matching reference!)
			var branch_defs = [
				{"pos": Vector3(-0.48, 1.92, 0.18), "rot": Vector3(12, 0, 38), "r1": 0.16, "r2": 0.28, "h": 1.15},
				{"pos": Vector3(0.50, 1.95, 0.22), "rot": Vector3(14, 0, -36), "r1": 0.16, "r2": 0.26, "h": 1.10},
				{"pos": Vector3(0.10, 1.98, -0.46), "rot": Vector3(-35, 0, -8), "r1": 0.15, "r2": 0.25, "h": 1.05},
				{"pos": Vector3(-0.22, 2.02, 0.48), "rot": Vector3(34, 0, 14), "r1": 0.14, "r2": 0.24, "h": 1.00},
				{"pos": Vector3(0.0, 2.10, 0.0), "rot": Vector3(4, 0, -4), "r1": 0.22, "r2": 0.34, "h": 0.95}
			]
			for bd in branch_defs:
				add_cylinder(tree_root, bd["r1"], bd["r2"], bd["h"], bd["pos"], trunk_mat, bd["rot"])

			# Multi-layered cloud-like Oak Foliage Canopy (Strictly inside dome: max_y <= 3.92m vs dome 4.49m!)
			var canopy_puffs = [
				# Lower dark shadow foliage layer
				{"pos": Vector3(-1.15, 2.42, 0.45), "r": 0.88, "h": 1.05, "mat": leaf_dark_mat},
				{"pos": Vector3(1.15, 2.40, 0.42), "r": 0.86, "h": 1.02, "mat": leaf_dark_mat},
				{"pos": Vector3(-0.85, 2.45, -0.85), "r": 0.90, "h": 1.05, "mat": leaf_dark_mat},
				{"pos": Vector3(0.95, 2.44, -0.80), "r": 0.88, "h": 1.04, "mat": leaf_dark_mat},
				{"pos": Vector3(0.0, 2.38, 1.05), "r": 0.86, "h": 1.00, "mat": leaf_dark_mat},
				# Middle vibrant main foliage puffs
				{"pos": Vector3(0.0, 2.88, 0.0), "r": 1.45, "h": 1.55, "mat": leaf_mid_mat},
				{"pos": Vector3(-1.05, 2.82, 0.15), "r": 1.02, "h": 1.25, "mat": leaf_mid_mat},
				{"pos": Vector3(1.05, 2.80, 0.18), "r": 1.00, "h": 1.22, "mat": leaf_mid_mat},
				{"pos": Vector3(0.0, 2.82, -0.92), "r": 1.05, "h": 1.26, "mat": leaf_mid_mat},
				{"pos": Vector3(0.0, 2.78, 0.85), "r": 0.98, "h": 1.18, "mat": leaf_mid_mat},
				# Upper sunlit crown puffs
				{"pos": Vector3(0.0, 3.28, -0.05), "r": 1.15, "h": 1.18, "mat": leaf_light_mat},
				{"pos": Vector3(-0.68, 3.16, 0.25), "r": 0.85, "h": 0.95, "mat": leaf_light_mat},
				{"pos": Vector3(0.68, 3.14, 0.22), "r": 0.82, "h": 0.92, "mat": leaf_light_mat},
				{"pos": Vector3(0.0, 3.18, -0.62), "r": 0.86, "h": 0.94, "mat": leaf_light_mat}
			]
			for cp in canopy_puffs:
				add_sphere(tree_root, cp["r"], cp["h"], cp["pos"], cp["mat"])

			# 3. Interior Lawn Props Matching Cartoon Reference (White Picnic Table & Rear Wheel)
			# White Picnic Table on front-right lawn (x = 1.25, z = 0.85)
			var pt_pos := Vector3(1.25, 0.17, 0.85)
			add_box(root, Vector3(0.96, 0.05, 0.52), pt_pos + Vector3(0, 0.36, 0), table_white_mat)
			add_box(root, Vector3(0.96, 0.04, 0.18), pt_pos + Vector3(0, 0.20, -0.42), table_white_mat)
			add_box(root, Vector3(0.96, 0.04, 0.18), pt_pos + Vector3(0, 0.20, 0.42), table_white_mat)
			for lx in [-0.34, 0.34]:
				add_box(root, Vector3(0.05, 0.38, 0.05), pt_pos + Vector3(lx, 0.18, -0.16), table_shadow_mat, Vector3(22, 0, 0))
				add_box(root, Vector3(0.05, 0.38, 0.05), pt_pos + Vector3(lx, 0.18, 0.16), table_shadow_mat, Vector3(-22, 0, 0))
				add_box(root, Vector3(0.05, 0.05, 0.92), pt_pos + Vector3(lx, 0.18, 0), table_shadow_mat)

			# Exercise Wheel on back-left lawn (x = -1.75, z = -0.95)
			var wh_pos := Vector3(-1.75, 0.62, -0.95)
			add_torus(root, 0.38, 0.45, wh_pos, airlock_blue_mat, Vector3(90, 20, 0))
			add_box(root, Vector3(0.04, 0.80, 0.04), wh_pos, airlock_rib_mat, Vector3(0, 20, 0))
			add_box(root, Vector3(0.80, 0.04, 0.04), wh_pos, airlock_rib_mat, Vector3(0, 20, 0))
			add_cylinder(root, 0.04, 0.06, 0.55, Vector3(-1.75, 0.35, -1.05), airlock_rib_mat)

			# 4. Seamless True Hemisphere Polyurethane Glass Dome (y = 0.12 to 4.47, r = 3.65m)
			var dome_inst = MeshInstance3D.new()
			var dome_sph = SphereMesh.new()
			dome_sph.is_hemisphere = true
			dome_sph.radius = 3.65
			dome_sph.height = 4.35
			dome_sph.radial_segments = 48
			dome_sph.rings = 24
			dome_inst.mesh = dome_sph
			dome_inst.position = Vector3(0, 0.12, 0)
			dome_inst.material_override = glass_mat
			root.add_child(dome_inst)

			# 5. Vaulted Blue-Grey Steel Airlock Tunnel & Arched Door (Protruding along +Z)
			var al_w := 1.48 # half-width = 0.74m
			var al_r := 0.74
			var al_y := 1.02
			var al_z := 3.52
			var al_len := 1.44

			# Flat-bottomed vaulted tunnel hull (rectangular lower walls + semicircular top roof)
			add_box(root, Vector3(al_w, al_y - 0.06, al_len), Vector3(0, (al_y + 0.06) * 0.5, al_z), airlock_blue_mat)
			add_cylinder(root, al_r, al_r, al_len, Vector3(0, al_y, al_z), airlock_blue_mat, Vector3(90, 0, 0))

			# Horizontal corrugated metal seam lines on the airlock sides
			for sy in [0.35, 0.65, 0.95]:
				add_box(root, Vector3(al_w + 0.04, 0.04, al_len - 0.10), Vector3(0, sy, al_z), airlock_rib_mat)

			# Two Heavy Raised Structural Arch Ribs (Inner Dome Collar z=2.92 & Outer Front Collar z=4.16)
			for rz in [2.92, 4.16]:
				# Left & right vertical rib columns
				for sx in [-1.0, 1.0]:
					add_box(root, Vector3(0.16, al_y - 0.04, 0.22), Vector3(sx * (al_r + 0.03), (al_y + 0.04) * 0.5, rz), airlock_rib_mat)
					for rv_y in [0.28, 0.58, 0.88]:
						add_sphere(root, 0.035, 0.035, Vector3(sx * (al_r + 0.10), rv_y, rz), rivet_mat)
				# Semicircular top rib arch (13 segments from -90 deg to +90 deg)
				for ai in range(13):
					var aang = -82.5 + ai * 13.75
					var arad = deg_to_rad(aang)
					var ax = sin(arad) * (al_r + 0.03)
					var ay = al_y + cos(arad) * (al_r + 0.03)
					add_box(root, Vector3(0.22, 0.16, 0.22), Vector3(ax, ay, rz), airlock_rib_mat, Vector3(0, 0, -aang))
					if ai % 2 == 0:
						var rx_rv = sin(arad) * (al_r + 0.10)
						var ry_rv = al_y + cos(arad) * (al_r + 0.10)
						add_sphere(root, 0.035, 0.035, Vector3(rx_rv, ry_rv, rz), rivet_mat)

			# Front Bulkhead Wall & Recessed Arched Submarine Door (z = 4.25)
			var dz := 4.25
			var dr_r := 0.48
			# Dark recessed door frame border
			add_box(root, Vector3(dr_r * 2.0 + 0.12, al_y - 0.10, 0.06), Vector3(0, (al_y + 0.10) * 0.5, dz), airlock_dark_mat)
			add_cylinder(root, dr_r + 0.06, dr_r + 0.06, 0.06, Vector3(0, al_y, dz), airlock_dark_mat, Vector3(90, 0, 0))
			# Inner Steel Arched Door Panel
			add_box(root, Vector3(dr_r * 2.0, al_y - 0.12, 0.06), Vector3(0, (al_y + 0.12) * 0.5, dz + 0.02), airlock_blue_mat)
			add_cylinder(root, dr_r, dr_r, 0.06, Vector3(0, al_y, dz + 0.02), airlock_blue_mat, Vector3(90, 0, 0))
			# Vertical center seam & submarine turn-handle latch (matching cartoon reference!)
			add_box(root, Vector3(0.03, 1.32, 0.04), Vector3(0, 0.78, dz + 0.05), airlock_dark_mat)
			add_cylinder(root, 0.05, 0.05, 0.08, Vector3(0, 0.82, dz + 0.07), rivet_mat, Vector3(90, 0, 0))
			add_box(root, Vector3(0.06, 0.34, 0.04), Vector3(0, 0.82, dz + 0.10), rivet_mat)
			add_box(root, Vector3(0.24, 0.05, 0.04), Vector3(0, 0.82, dz + 0.10), rivet_mat)

		"dutchman", "flyingdutchman", "trading":
			# Cartoon-accurate materials matching The Flying Dutchman's Ghost Ship (media_1790519577181.jpg)
			# Solid emissive spectral wood prevents internal alpha-sorting artifacts while glowing eerie green!
			var hull_plank_mat := make_mat(Color("#1E7845"), 0.55, 0.05, Color("#2ECC71") * 0.32)
			var hull_light_mat := make_mat(Color("#2E9B5B"), 0.50, 0.05, Color("#58D68D") * 0.38)
			var hull_seam_mat := make_mat(Color("#09331B"), 0.75, 0.05, Color("#0E4D29") * 0.15)
			var ecto_rail_mat := make_mat(Color("#8BF568"), 0.25, 0.0, Color("#76E852") * 0.75)
			var mast_wood_mat := make_mat(Color("#165A33"), 0.65, 0.05, Color("#27AE60") * 0.25)
			var sail_mat := make_mat(Color("#A8F5D2"), 0.35, 0.0, Color("#68E8AC") * 0.55)
			var sail_shadow_mat := make_mat(Color("#6EC9A2"), 0.45, 0.0, Color("#45B386") * 0.40)
			var emblem_green_mat := make_mat(Color("#7CE84B"), 0.25, 0.0, Color("#62D936") * 0.70)
			var emblem_dark_mat := make_mat(Color("#174F32"), 0.60, 0.05, Color("#113D26") * 0.20)
			var aura_glow_mat := make_mat(Color("#58F568"), 0.10, 0.0, Color("#3EE850") * 0.90, 0.22)

			# Ship Pivot tilted slightly dynamically like a floating spectral galleon
			var ship := Node3D.new()
			ship.position = Vector3(0, 0.35, 0)
			ship.rotation_degrees = Vector3(-4.0, 0.0, 3.0)
			root.add_child(ship)

			# Soft ghostly ectoplasmic green aura pool beneath the ship
			add_cylinder(root, 2.6, 2.9, 0.08, Vector3(0, 0.08, 0), aura_glow_mat)

			# 1. Curved Clinker-Planked Galleon Hull (Tapered from narrow keel y=0.45 to wide deck y=2.05)
			add_box(ship, Vector3(0.28, 0.36, 4.80), Vector3(0, 0.42, -0.10), hull_seam_mat)
			var strake_count: int = 6
			for st_i: int in range(strake_count):
				var st_t: float = float(st_i) / float(strake_count - 1)
				var sy_h: float = lerpf(0.66, 1.92, st_t)
				var sw_h: float = lerpf(1.15, 2.44, sqrt(st_t))
				var sl_h: float = lerpf(4.30, 5.10, st_t)
				var s_mat: StandardMaterial3D = hull_light_mat if (st_i % 2 == 1) else hull_plank_mat
				add_box(ship, Vector3(sw_h, 0.24, sl_h), Vector3(0, sy_h, -0.10), s_mat)
				# Dark horizontal clinker plank seam line
				add_box(ship, Vector3(sw_h + 0.04, 0.035, sl_h + 0.02), Vector3(0, sy_h - 0.11, -0.10), hull_seam_mat)

				# Tapered curved bow wedge sections forward (+Z) so the prow curves cleanly without alpha seams
				var bw_len: float = lerpf(0.95, 1.35, st_t)
				var bw_z: float = -0.10 + sl_h * 0.5 + bw_len * 0.35
				for b_side: float in [-1.0, 1.0]:
					add_box(ship, Vector3(sw_h * 0.42, 0.23, bw_len), Vector3(b_side * sw_h * 0.22, sy_h, bw_z), s_mat, Vector3(0, -b_side * 28.0, 0))

			# Curved Prow Cutwater Stem at the front of the bow
			add_box(ship, Vector3(0.24, 1.85, 0.48), Vector3(0, 1.55, 2.95), ecto_rail_mat, Vector3(-24, 0, 0))
			add_box(ship, Vector3(0.28, 1.65, 0.36), Vector3(0, 1.45, 2.82), hull_seam_mat, Vector3(-24, 0, 0))

			# Main Weather Deck & Glowing Lime-Green Sweeping Gunwale Trim Rails
			add_box(ship, Vector3(2.36, 0.12, 5.00), Vector3(0, 2.04, -0.10), hull_seam_mat)
			for g_side: float in [-1.0, 1.0]:
				add_box(ship, Vector3(0.14, 0.22, 5.15), Vector3(g_side * 1.22, 2.15, -0.10), ecto_rail_mat)
				# Curved bow scroll rails
				add_box(ship, Vector3(0.14, 0.20, 1.35), Vector3(g_side * 0.62, 2.38, 2.48), ecto_rail_mat, Vector3(-12, -g_side * 28.0, 0))
				# 4 Cannon Ports along each side of the hull
				for cp_i: int in range(4):
					var cp_z: float = -1.45 + float(cp_i) * 0.95
					add_box(ship, Vector3(0.12, 0.22, 0.24), Vector3(g_side * 1.21, 1.56, cp_z), hull_seam_mat)
					add_cylinder(ship, 0.05, 0.06, 0.26, Vector3(g_side * 1.28, 1.56, cp_z), hull_seam_mat, Vector3(0, 0, 90))

			# 2. Raised Bow Forecastle & Tall Multi-Tiered Stern Poop Deck / Captain's Cabin
			# Bow Forecastle Deck (z = 1.45..2.55)
			add_box(ship, Vector3(2.10, 0.45, 1.25), Vector3(0, 2.28, 1.90), hull_plank_mat)
			add_box(ship, Vector3(2.22, 0.12, 1.32), Vector3(0, 2.52, 1.90), ecto_rail_mat)

			# Stern Quarterdeck & Poop Deck Castle (z = -1.25..-2.85)
			add_box(ship, Vector3(2.38, 0.72, 1.65), Vector3(0, 2.40, -1.90), hull_plank_mat)
			add_box(ship, Vector3(2.48, 0.12, 1.74), Vector3(0, 2.78, -1.90), ecto_rail_mat)
			add_box(ship, Vector3(2.16, 0.62, 1.15), Vector3(0, 3.05, -2.18), hull_light_mat)
			add_box(ship, Vector3(2.28, 0.12, 1.24), Vector3(0, 3.38, -2.18), ecto_rail_mat)
			# Glowing spectral cabin windows on the stern & side galleries
			for sw_x: float in [-0.55, 0.0, 0.55]:
				add_box(ship, Vector3(0.32, 0.42, 0.08), Vector3(sw_x, 2.45, -2.74), ecto_rail_mat)
			# Glowing Green Stern Lantern
			add_sphere(ship, 0.24, 0.36, Vector3(0, 3.72, -2.78), ecto_rail_mat)

			# 3. Long Angled Bowsprit Spar Jutting from the Prow (matching reference media_1790519577181.jpg!)
			add_cylinder(ship, 0.06, 0.13, 2.65, Vector3(0, 2.96, 3.65), mast_wood_mat, Vector3(60, 0, 0))
			for bs_i: int in range(3):
				var bs_t: float = float(bs_i) * 0.65
				add_torus(ship, 0.08, 0.13, Vector3(0, 2.58 + bs_t * 0.50, 3.00 + bs_t * 0.86), hull_seam_mat, Vector3(60, 0, 0))

			# 4. Three Tall Masts with Billowing Spectral Sails, Crow's Nest & Iconic Skull Emblem
			# --- FOREMAST (Front: z = 1.45) ---
			add_cylinder(ship, 0.08, 0.13, 3.40, Vector3(0, 3.85, 1.45), mast_wood_mat)
			add_cylinder(ship, 0.05, 0.05, 2.20, Vector3(0, 4.85, 1.45), mast_wood_mat, Vector3(0, 0, 90))
			add_cylinder(ship, 0.05, 0.05, 2.20, Vector3(0, 3.25, 1.55), mast_wood_mat, Vector3(0, 0, 90))
			# Billowing Fore Sail (curved via 5 horizontal strips)
			for fs_i: int in range(5):
				var fs_t: float = float(fs_i) / 4.0
				var fs_y: float = lerpf(3.40, 4.70, fs_t)
				var fs_belly: float = sin(fs_t * PI) * 0.24
				add_box(ship, Vector3(2.05, 0.36, 0.07), Vector3(0, fs_y, 1.55 + fs_belly), sail_mat)

			# --- MAINMAST (Center: z = -0.05, Tallest with Crow's Nest & Iconic Green Skull Emblem!) ---
			add_cylinder(ship, 0.09, 0.16, 4.50, Vector3(0, 4.25, -0.05), mast_wood_mat)
			# Upper & Lower Main Yardarms
			add_cylinder(ship, 0.06, 0.06, 2.85, Vector3(0, 5.35, -0.05), mast_wood_mat, Vector3(0, 0, 90))
			add_cylinder(ship, 0.06, 0.06, 2.85, Vector3(0, 3.35, 0.08), mast_wood_mat, Vector3(0, 0, 90))
			# Billowing Main Square Sail
			for ms_i: int in range(6):
				var ms_t: float = float(ms_i) / 5.0
				var ms_y: float = lerpf(3.52, 5.18, ms_t)
				var ms_belly: float = sin(ms_t * PI) * 0.28
				add_box(ship, Vector3(2.68, 0.36, 0.08), Vector3(0, ms_y, 0.05 + ms_belly), sail_mat)

			# Iconic Green Circular Skull/Ghost Emblem & Crossed Blades on Main Sail (matching reference!)
			var emb_z: float = 0.36
			add_cylinder(ship, 0.44, 0.44, 0.05, Vector3(0, 4.58, emb_z), emblem_green_mat, Vector3(90, 0, 0))
			add_torus(ship, 0.38, 0.46, Vector3(0, 4.58, emb_z + 0.01), emblem_dark_mat, Vector3(90, 0, 0))
			# Two dark ghost eye sockets inside the green emblem circle
			add_sphere(ship, 0.09, 0.12, Vector3(-0.14, 4.62, emb_z + 0.03), emblem_dark_mat)
			add_sphere(ship, 0.09, 0.12, Vector3(0.14, 4.62, emb_z + 0.03), emblem_dark_mat)
			# Crossed dark-teal crescent blades/bones beneath the green skull circle
			add_box(ship, Vector3(0.95, 0.14, 0.05), Vector3(0, 3.98, emb_z - 0.02), emblem_dark_mat, Vector3(0, 0, 24))
			add_box(ship, Vector3(0.95, 0.14, 0.05), Vector3(0, 3.98, emb_z - 0.02), emblem_dark_mat, Vector3(0, 0, -24))

			# Crow's Nest Lookout Basket & Spectral Pennant Flag at top of Mainmast (y = 5.95..6.55)
			add_cylinder(ship, 0.36, 0.24, 0.42, Vector3(0, 5.95, -0.05), mast_wood_mat)
			add_torus(ship, 0.28, 0.38, Vector3(0, 6.15, -0.05), ecto_rail_mat)
			add_box(ship, Vector3(0.05, 0.28, 0.75), Vector3(0, 6.42, -0.45), ecto_rail_mat)

			# --- MIZZENMAST (Stern: z = -1.65) ---
			add_cylinder(ship, 0.07, 0.12, 3.10, Vector3(0, 4.15, -1.65), mast_wood_mat)
			add_cylinder(ship, 0.05, 0.05, 1.95, Vector3(0, 4.95, -1.65), mast_wood_mat, Vector3(0, 0, 90))
			add_cylinder(ship, 0.05, 0.05, 1.95, Vector3(0, 3.55, -1.55), mast_wood_mat, Vector3(0, 0, 90))
			for zs_i: int in range(4):
				var zs_t: float = float(zs_i) / 3.0
				var zs_y: float = lerpf(3.70, 4.80, zs_t)
				var zs_belly: float = sin(zs_t * PI) * 0.20
				add_box(ship, Vector3(1.80, 0.38, 0.07), Vector3(0, zs_y, -1.58 + zs_belly), sail_shadow_mat)

			# 5. Rigging Shrouds & Hanging Glowing Green Anchor Line (matching reference!)
			for r_side: float in [-1.0, 1.0]:
				add_cylinder(ship, 0.02, 0.02, 3.60, Vector3(r_side * 0.65, 3.80, -0.05), ecto_rail_mat, Vector3(0, 0, -r_side * 18.0))
			# Glowing green anchor line dropping from the bow to the seabed
			add_cylinder(ship, 0.035, 0.035, 2.45, Vector3(0.85, 0.95, 1.65), ecto_rail_mat, Vector3(10, 0, -14))
			add_torus(ship, 0.14, 0.22, Vector3(1.12, -0.15, 1.85), ecto_rail_mat, Vector3(90, 0, 0))


		"leaderboards", "leaderboard", "spatula", "trophy":
			var marble_mat = make_mat(Color("#EAEDED"), 0.2, 0.1)
			var gold_mat = make_mat(Color("#F1C40F"), 0.2, 0.85, Color("#B7950B"))
			# Marble pedestal
			add_box(root, Vector3(3.6, 0.5, 3.6), Vector3(0, 0.25, 0), marble_mat)
			add_cylinder(root, 1.0, 1.2, 2.6, Vector3(0, 1.7, 0), marble_mat)
			# Golden Spatula Statue
			add_cylinder(root, 0.12, 0.12, 2.6, Vector3(0, 3.8, 0), gold_mat)
			add_box(root, Vector3(1.3, 1.6, 0.12), Vector3(0, 5.4, 0), gold_mat)
			add_torus(root, 0.9, 1.15, Vector3(0, 5.4, 0), gold_mat, Vector3(90, 0, 0))

		"portal", "battleportal":
			var portal_mat = make_mat(Color("#00FFFF"), 0.1, 0.0, Color("#00BFFF") * 1.3, 0.85)
			var core_mat = make_mat(Color("#B2FFFF"), 0.05, 0.0, Color("#66FFFF") * 1.6, 0.92)
			var ring_mat = make_mat(Color("#E74C3C"), 0.35, 0.25, Color("#C0392B") * 0.35)
			var base_stone_mat = make_mat(Color("#2C3E50"), 0.65, 0.35)
			var gold_trim_mat = make_mat(Color("#F1C40F"), 0.25, 0.8, Color("#D4AC0D") * 0.45)
			# Grounded Portal Pedestal Plinth & Side Pylons
			add_box(root, Vector3(3.8, 0.36, 1.3), Vector3(0, 0.18, 0), base_stone_mat)
			add_box(root, Vector3(3.5, 0.12, 1.0), Vector3(0, 0.40, 0), gold_trim_mat)
			for px_s: float in [-1.55, 1.55]:
				add_cylinder(root, 0.24, 0.32, 1.1, Vector3(px_s, 0.72, 0), base_stone_mat)
				add_torus(root, 0.20, 0.28, Vector3(px_s, 1.25, 0), gold_trim_mat)
			# Main Portal Ring & Glowing Swirling Vortex Disk (facing +Z in local space)
			add_torus(root, 1.75, 2.35, Vector3(0, 2.35, 0), ring_mat, Vector3(90, 0, 0))
			add_torus(root, 1.62, 1.78, Vector3(0, 2.35, 0.06), gold_trim_mat, Vector3(90, 0, 0))
			add_torus(root, 1.62, 1.78, Vector3(0, 2.35, -0.06), gold_trim_mat, Vector3(90, 0, 0))
			add_cylinder(root, 1.72, 1.72, 0.14, Vector3(0, 2.35, 0), portal_mat, Vector3(90, 0, 0))
			add_torus(root, 0.85, 1.02, Vector3(0, 2.35, 0.08), core_mat, Vector3(90, 0, 0))
			add_sphere(root, 0.45, 0.18, Vector3(0, 2.35, 0.08), core_mat, Vector3(90, 0, 0))

	return root

func build_thematic_cylinder_pad(pad_id: String, base_color: Color) -> Dictionary:
	var root := Node3D.new()
	root.name = "ThematicPad_" + pad_id
	
	var norm_id := pad_id.to_lower().replace("_", "").strip_edges()
	var orbit_items: Array = []
	var ring_items: Array = []
	var particles: Array = []
	var emblem_root: Node3D = null
	var emblem_base_y: float = 0.65
	
	# Common Standardized PBR Materials
	var stone_mat := make_mat(Color("#222831"), 0.75, 0.2)
	var gold_metal := make_mat(Color("#F1C40F"), 0.25, 0.85, Color("#D4AC0D") * 0.4)
	var silver_metal := make_mat(Color("#D5D8DC"), 0.2, 0.9)
	var accent_glow := make_mat(base_color, 0.2, 0.1, base_color * 1.5, 0.95)
	
	# Solid Base Platform Plinth (r = 1.35 to 1.48, height = 0.16)
	var base_cyl := MeshInstance3D.new()
	var c_mesh := CylinderMesh.new()
	c_mesh.top_radius = 1.36
	c_mesh.bottom_radius = 1.46
	c_mesh.height = 0.16
	base_cyl.mesh = c_mesh
	base_cyl.position = Vector3(0, 0.08, 0)
	base_cyl.material_override = make_mat(Color(0.08, 0.14, 0.22), 0.35, 0.2, base_color * 0.45)
	root.add_child(base_cyl)
	
	# Glowing Outer Ring
	var outer_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.25
	torus.outer_radius = 1.48
	outer_ring.mesh = torus
	outer_ring.position = Vector3(0, 0.12, 0)
	outer_ring.material_override = accent_glow
	root.add_child(outer_ring)
	ring_items.append({
		"node": outer_ring,
		"speed": 1.2,
		"base_scale": Vector3.ONE,
		"pulse_amp": 0.06,
		"pulse_spd": 0.005
	})
	
	# Translucent Vertical Holographic Beacon
	var beacon := MeshInstance3D.new()
	var b_mesh := CylinderMesh.new()
	b_mesh.top_radius = 0.92
	b_mesh.bottom_radius = 0.92
	b_mesh.height = 0.85
	beacon.mesh = b_mesh
	beacon.position = Vector3(0, 0.50, 0)
	beacon.material_override = make_mat(base_color, 0.1, 0.0, base_color * 0.85, 0.22)
	root.add_child(beacon)

	# -------------------------------------------------------------
	# Thematic Architecture & Expressive 3D Emblems Per Building
	# -------------------------------------------------------------
	match norm_id:
		"krustykrab", "krab", "burger":
			# THE KRUSTY KRAB: Golden Krabby Patty, Crossed Silver Spatulas & Sizzling Heat Embers!
			emblem_base_y = 0.65
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_KrabbyPatty"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var bun_mat := make_mat(Color("#E59866"), 0.65)
			var patty_mat := make_mat(Color("#6E2C00"), 0.8)
			var lettuce_mat := make_mat(Color("#2ECC71"), 0.5)
			var tomato_mat := make_mat(Color("#E74C3C"), 0.4)
			var wood_mat := make_mat(Color("#873600"), 0.7)
			var sesame_mat := make_mat(Color("#FDFEFE"), 0.4)
			
			# 1. Crossed Silver Spatulas behind Patty
			for s_side: float in [-1.0, 1.0]:
				var sp_root := Node3D.new()
				sp_root.rotation_degrees = Vector3(0, 0, s_side * 36.0)
				emblem_root.add_child(sp_root)
				add_cylinder(sp_root, 0.03, 0.03, 0.36, Vector3(0, -0.22, -0.04), wood_mat)
				add_cylinder(sp_root, 0.02, 0.02, 0.38, Vector3(0, 0.12, -0.04), silver_metal)
				add_box(sp_root, Vector3(0.24, 0.32, 0.025), Vector3(0, 0.42, -0.04), silver_metal)
				for sl_x: float in [-0.06, 0.0, 0.06]:
					add_box(sp_root, Vector3(0.02, 0.18, 0.03), Vector3(sl_x, 0.42, -0.04), stone_mat)
					
			# 2. Golden Krabby Patty
			add_cylinder(emblem_root, 0.32, 0.32, 0.07, Vector3(0, -0.10, 0), bun_mat)
			add_cylinder(emblem_root, 0.34, 0.34, 0.08, Vector3(0, -0.02, 0), patty_mat)
			add_cylinder(emblem_root, 0.36, 0.33, 0.04, Vector3(0, 0.04, 0), lettuce_mat)
			add_cylinder(emblem_root, 0.33, 0.33, 0.04, Vector3(0, 0.08, 0), tomato_mat)
			add_sphere(emblem_root, 0.34, 0.22, Vector3(0, 0.16, 0), bun_mat)
			for si: int in range(6):
				var s_ang: float = deg_to_rad(float(si) * 60.0 + 15.0)
				add_sphere(emblem_root, 0.025, 0.035, Vector3(cos(s_ang) * 0.20, 0.24, sin(s_ang) * 0.20), sesame_mat)
				
			# 3. 4 Sizzling Flame Embers / Heat Motes Orbiting
			var ember_mat := make_mat(Color("#F39C12"), 0.15, 0.0, Color("#E67E22") * 1.8)
			for i: int in range(4):
				var e_mesh := add_sphere(root, 0.07, 0.14, Vector3.ZERO, ember_mat)
				orbit_items.append({
					"node": e_mesh,
					"radius": 0.82,
					"speed": 1.6 + float(i) * 0.15,
					"base_y": 0.58 + float(i) * 0.10,
					"wave_spd": 2.2,
					"wave_amp": 0.16,
					"self_rot": Vector3(0.0, 2.5, 0.0),
					"angle": float(i) * (TAU / 4.0)
				})

		"planktonlab", "chumbucket", "lab":
			# CHUM BUCKET LAB: Glowing Toxic Chemical Flask, DNA Helix & Bubbling Slime Orbs!
			emblem_base_y = 0.70
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_ToxicLab"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var toxic_mat := make_mat(Color("#2ECC71"), 0.1, 0.0, Color("#00FFAA") * 1.8, 0.90)
			var glass_mat := make_mat(Color("#D4EFDF"), 0.15, 0.1, Color.BLACK, 0.38)
			var cork_mat := make_mat(Color("#873600"), 0.8)
			
			# Chemical Laboratory Flask & Liquid
			add_cylinder(emblem_root, 0.14, 0.44, 0.55, Vector3(0, -0.05, 0), glass_mat)
			add_cylinder(emblem_root, 0.12, 0.40, 0.32, Vector3(0, -0.14, 0), toxic_mat)
			add_cylinder(emblem_root, 0.12, 0.12, 0.28, Vector3(0, 0.30, 0), glass_mat)
			add_cylinder(emblem_root, 0.14, 0.14, 0.06, Vector3(0, 0.45, 0), glass_mat)
			add_cylinder(emblem_root, 0.10, 0.12, 0.10, Vector3(0, 0.48, 0), cork_mat)
			# Bubbling froth on liquid surface
			for bi: int in range(4):
				var bang = deg_to_rad(float(bi) * 90.0 + 20.0)
				add_sphere(emblem_root, 0.06, 0.08, Vector3(cos(bang) * 0.18, 0.02, sin(bang) * 0.18), toxic_mat)
				
			# Rotating Glowing DNA Helix Strand around flask
			for hi: int in range(6):
				var h_ang: float = float(hi) * 45.0
				var h_rad: float = deg_to_rad(h_ang)
				var h_y: float = -0.22 + float(hi) * 0.11
				add_sphere(emblem_root, 0.045, 0.06, Vector3(sin(h_rad) * 0.38, h_y, cos(h_rad) * 0.38), toxic_mat)
				add_sphere(emblem_root, 0.045, 0.06, Vector3(-sin(h_rad) * 0.38, h_y, -cos(h_rad) * 0.38), accent_glow)
				add_cylinder(emblem_root, 0.015, 0.015, 0.72, Vector3(0, h_y, 0), silver_metal, Vector3(0, -h_ang, 90))
				
			# 4 Bubbling Toxic Sludge Orbs Orbiting
			for i: int in range(4):
				var orb := add_sphere(root, 0.08, 0.12, Vector3.ZERO, toxic_mat)
				orbit_items.append({
					"node": orb,
					"radius": 0.84,
					"speed": -1.4 - float(i) * 0.2,
					"base_y": 0.60 + float(i) * 0.08,
					"wave_spd": 2.8,
					"wave_amp": 0.18,
					"self_rot": Vector3(1.5, 2.0, 0.0),
					"angle": float(i) * (TAU / 4.0)
				})

		"summonaltar", "summon":
			# MYSTIC CRATES KIOSK: Gilded Mystic Chest, Radiant Rainbow Pearl & Orbiting Star Shards!
			emblem_base_y = 0.65
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_MysticChest"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var chest_wood := make_mat(Color("#512E5F"), 0.75)
			var chest_gold := make_mat(Color("#F4D03F"), 0.2, 0.85, Color("#D4AC0D") * 0.6)
			var pearl_glow := make_mat(Color("#FFFDF5"), 0.05, 0.0, Color("#FFEAA7") * 2.2)
			
			# Mini Ornate Chest Base & Open Lid
			add_box(emblem_root, Vector3(0.55, 0.28, 0.42), Vector3(0, -0.06, 0), chest_wood)
			add_box(emblem_root, Vector3(0.58, 0.04, 0.45), Vector3(0, 0.08, 0), chest_gold)
			add_cylinder(emblem_root, 0.21, 0.21, 0.54, Vector3(0, 0.18, -0.10), chest_wood, Vector3(0, 0, 90))
			# Radiant Rainbow Pearl glowing inside
			add_sphere(emblem_root, 0.13, 0.24, Vector3(0, 0.12, 0.04), pearl_glow)
			add_torus(emblem_root, 0.10, 0.16, Vector3(0, 0.12, 0.04), chest_gold, Vector3(90, 0, 0))
			
			# 4 Multi-Faceted Orbiting Star Shards (Ruby, Sapphire, Amethyst, Topaz)
			var shard_colors = [Color("#E74C3C"), Color("#3498DB"), Color("#9B59B6"), Color("#F1C40F")]
			for i: int in range(4):
				var s_col: Color = shard_colors[i]
				var s_mat = make_mat(s_col, 0.15, 0.1, s_col * 1.7)
				var shard := add_sphere(root, 0.07, 0.14, Vector3.ZERO, s_mat)
				shard.scale = Vector3(0.8, 1.6, 0.8) # faceted gem silhouette
				orbit_items.append({
					"node": shard,
					"radius": 0.88,
					"speed": 1.35 + float(i) * 0.15,
					"base_y": 0.58 + float(i) * 0.09,
					"wave_spd": 2.2,
					"wave_amp": 0.15,
					"self_rot": Vector3(2.5, 3.2, 1.5),
					"angle": float(i) * (TAU / 4.0)
				})

		"pineapple", "inventory", "units":
			# SPONGEBOB'S HOUSE: Golden Tropical Pineapple, Spatula & Oceanic Bubbles!
			emblem_base_y = 0.66
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_Pineapple"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var p_skin := make_mat(Color("#F39C12"), 0.65, 0.0, Color("#D68910") * 0.3)
			var p_leaf := make_mat(Color("#27AE60"), 0.5)
			var p_leaf_dk := make_mat(Color("#196F3D"), 0.6)
			
			# Oval Pineapple Body
			var p_mesh := add_sphere(emblem_root, 0.28, 0.54, Vector3(0, 0.04, 0), p_skin)
			p_mesh.scale = Vector3(0.88, 1.18, 0.88)
			# 7 Crown Leaves
			for li: int in range(7):
				var lang: float = deg_to_rad(float(li) * (360.0 / 7.0))
				var l_mesh := add_cylinder(emblem_root, 0.02, 0.06, 0.35, Vector3(sin(lang) * 0.11, 0.38, cos(lang) * 0.11), p_leaf if li % 2 == 0 else p_leaf_dk, Vector3(18 * cos(lang), 0, -18 * sin(lang)))
				l_mesh.scale = Vector3(0.4, 1.0, 1.0)
			# Mini Golden Spatula at side
			add_cylinder(emblem_root, 0.02, 0.02, 0.38, Vector3(0.32, 0.12, 0.0), silver_metal, Vector3(0, 0, -18))
			add_box(emblem_root, Vector3(0.14, 0.18, 0.02), Vector3(0.38, 0.34, 0.0), silver_metal, Vector3(0, 0, -18))
			
			# 5 Iridescent Bubbles Orbiting & Rising
			var bubble_mat := make_mat(Color(0.85, 0.95, 1.0), 0.1, 0.2, Color(0.4, 0.85, 1.0) * 1.1, 0.65)
			for i: int in range(5):
				var bub := add_sphere(root, 0.08, 0.16, Vector3.ZERO, bubble_mat)
				orbit_items.append({
					"node": bub,
					"radius": 0.82,
					"speed": 1.25 + float(i) * 0.18,
					"base_y": 0.55 + float(i) * 0.12,
					"wave_spd": 2.4,
					"wave_amp": 0.20,
					"self_rot": Vector3(0.5, 1.2, 0.8),
					"angle": float(i) * (TAU / 5.0)
				})

		"moai", "squidward", "settings":
			# SQUIDWARD'S MOAI: Sculpted Black Clarinet, Treble Clef & Dancing 3D Musical Notes!
			emblem_base_y = 0.70
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_ClarinetMusic"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var cl_mat := make_mat(Color("#17202A"), 0.3, 0.4)
			var note_mat := make_mat(Color("#5DADE2"), 0.15, 0.0, Color("#3498DB") * 1.6)
			var note_gold := make_mat(Color("#F4D03F"), 0.2, 0.5, Color("#F1C40F") * 1.4)
			
			# Sculpted Clarinet Tube, Bell & Keys
			add_cylinder(emblem_root, 0.038, 0.038, 0.72, Vector3(0, 0.08, 0), cl_mat)
			add_cylinder(emblem_root, 0.09, 0.04, 0.14, Vector3(0, -0.32, 0), cl_mat) # Bell flare
			add_cylinder(emblem_root, 0.032, 0.038, 0.12, Vector3(0, 0.48, 0), gold_metal) # Mouthpiece
			for ki: int in range(6):
				var ky: float = -0.15 + float(ki) * 0.09
				add_box(emblem_root, Vector3(0.02, 0.03, 0.05), Vector3(0, ky, 0.05), silver_metal)
				add_sphere(emblem_root, 0.025, 0.025, Vector3(0, ky, 0.07), silver_metal)
				
			# 4 Dancing 3D Musical Notes (♪, ♫) Orbiting
			for i: int in range(4):
				var n_root := Node3D.new()
				var n_mat = note_gold if i % 2 == 0 else note_mat
				add_sphere(n_root, 0.07, 0.09, Vector3(0, 0, 0), n_mat)
				add_cylinder(n_root, 0.015, 0.015, 0.24, Vector3(0.06, 0.12, 0), n_mat)
				add_box(n_root, Vector3(0.08, 0.03, 0.015), Vector3(0.10, 0.22, 0), n_mat)
				root.add_child(n_root)
				orbit_items.append({
					"node": n_root,
					"radius": 0.84,
					"speed": -1.35 - float(i) * 0.22,
					"base_y": 0.56 + float(i) * 0.11,
					"wave_spd": 2.5,
					"wave_amp": 0.22,
					"self_rot": Vector3(0.8, 1.8, 0.5),
					"angle": float(i) * (TAU / 4.0)
				})

		"rock", "patrick", "infinity":
			# PATRICK'S ROCK: Glowing 3D Neon Infinity Symbol (∞), Dual Tilted Orbit Rings & Void Sparks!
			emblem_base_y = 0.68
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_InfinityVoid"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var inf_glow := make_mat(Color("#FF1493"), 0.08, 0.0, Color("#FF007F") * 2.5)
			var void_core := make_mat(Color("#4A0E4E"), 0.2, 0.8, Color("#880E4F") * 1.5)
			
			# 3D Double-Loop Neon Infinity Symbol (∞)
			add_torus(emblem_root, 0.20, 0.32, Vector3(-0.25, 0.0, 0.0), inf_glow, Vector3(0, 0, 90))
			add_torus(emblem_root, 0.20, 0.32, Vector3(0.25, 0.0, 0.0), inf_glow, Vector3(0, 0, 90))
			add_sphere(emblem_root, 0.12, 0.18, Vector3(0.0, 0.0, 0.0), void_core)
			
			# Dual Tilted Quantum / Nether Vortex Rings
			var q_ring1 := add_torus(emblem_root, 0.62, 0.68, Vector3.ZERO, inf_glow, Vector3(45, 0, 0))
			var q_ring2 := add_torus(emblem_root, 0.62, 0.68, Vector3.ZERO, accent_glow, Vector3(-45, 0, 0))
			ring_items.append({
				"node": q_ring1,
				"speed": 2.2,
				"base_scale": Vector3.ONE,
				"pulse_amp": 0.08,
				"pulse_spd": 0.007
			})
			ring_items.append({
				"node": q_ring2,
				"speed": -2.2,
				"base_scale": Vector3.ONE,
				"pulse_amp": 0.08,
				"pulse_spd": 0.007
			})
			
			# 4 Ethereal Magenta Sparks Orbiting
			for i: int in range(4):
				var spk := add_sphere(root, 0.065, 0.11, Vector3.ZERO, inf_glow)
				orbit_items.append({
					"node": spk,
					"radius": 0.88,
					"speed": 2.4 + float(i) * 0.35,
					"base_y": 0.58 + float(i) * 0.10,
					"wave_spd": 3.4,
					"wave_amp": 0.24,
					"self_rot": Vector3(3.0, 4.0, 1.0),
					"angle": float(i) * (TAU / 4.0)
				})

		"treedome", "sandy", "afk":
			# SANDY'S TREEDOME: Giant Golden Oak Acorn, Orbiting Spinning Gold Coins (🪙) & Prismatic Gems (💎)!
			emblem_base_y = 0.64
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_AcornRichResort"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var acorn_nut := make_mat(Color("#F39C12"), 0.5, 0.1, Color("#D68910") * 0.35)
			var acorn_cap := make_mat(Color("#5D4037"), 0.8)
			var gem_pink := make_mat(Color("#FF69B4"), 0.1, 0.1, Color("#FF1493") * 1.8)
			var gem_cyan := make_mat(Color("#00FFFF"), 0.1, 0.1, Color("#00BFFF") * 1.8)
			
			# Giant Sculpted Golden Oak Acorn
			var nut := add_sphere(emblem_root, 0.26, 0.44, Vector3(0, -0.06, 0), acorn_nut)
			nut.scale = Vector3(1.0, 1.35, 1.0)
			add_cylinder(emblem_root, 0.28, 0.24, 0.16, Vector3(0, 0.14, 0), acorn_cap)
			add_cylinder(emblem_root, 0.04, 0.05, 0.16, Vector3(0, 0.26, 0), acorn_cap)
			
			# 3 Orbiting Spinning 3D Gold Coins (🪙)
			for ci: int in range(3):
				var coin := add_cylinder(root, 0.14, 0.14, 0.04, Vector3.ZERO, gold_metal, Vector3(90, 0, 0))
				orbit_items.append({
					"node": coin,
					"radius": 0.86,
					"speed": 1.5 + float(ci) * 0.2,
					"base_y": 0.56 + float(ci) * 0.12,
					"wave_spd": 2.2,
					"wave_amp": 0.18,
					"self_rot": Vector3(0.0, 3.5, 1.5),
					"angle": float(ci) * (TAU / 3.0)
				})
				
			# 2 Orbiting Cut Prismatic Gems (💎)
			for gi: int in range(2):
				var gem := add_sphere(root, 0.09, 0.18, Vector3.ZERO, gem_pink if gi == 0 else gem_cyan)
				gem.scale = Vector3(0.85, 1.45, 0.85)
				orbit_items.append({
					"node": gem,
					"radius": 0.96,
					"speed": -1.8 - float(gi) * 0.3,
					"base_y": 0.65 + float(gi) * 0.14,
					"wave_spd": 2.8,
					"wave_amp": 0.20,
					"self_rot": Vector3(2.5, 3.0, 1.8),
					"angle": float(gi) * PI + 0.5
				})

		"flyingdutchman", "dutchman", "trading":
			# DUTCHMAN GHOST SHIP: Spectral Pirate Lantern with Soul Flame & Ectoplasmic Ghost Wisps!
			emblem_base_y = 0.66
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_SpectralLantern"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var brass_mat := make_mat(Color("#4A6572"), 0.4, 0.5)
			var ecto_glow := make_mat(Color("#2ECC71"), 0.1, 0.0, Color("#58D68D") * 2.2, 0.90)
			var flame_glow := make_mat(Color("#76FF03"), 0.05, 0.0, Color("#64DD17") * 2.6)
			
			# 4-Sided Antique Pirate Lantern
			add_box(emblem_root, Vector3(0.38, 0.06, 0.38), Vector3(0, -0.22, 0), brass_mat)
			add_box(emblem_root, Vector3(0.38, 0.06, 0.38), Vector3(0, 0.22, 0), brass_mat)
			add_cylinder(emblem_root, 0.06, 0.14, 0.16, Vector3(0, 0.32, 0), brass_mat)
			add_torus(emblem_root, 0.08, 0.12, Vector3(0, 0.44, 0), brass_mat, Vector3(90, 0, 0))
			# Glowing Ectoplasmic Glass Core & Inner Soul Flame
			add_cylinder(emblem_root, 0.15, 0.15, 0.36, Vector3(0, 0.0, 0), ecto_glow)
			add_sphere(emblem_root, 0.07, 0.14, Vector3(0, 0.0, 0), flame_glow)
			
			# 4 Orbiting Ectoplasmic Ghost Wisps
			for i: int in range(4):
				var wisp := add_sphere(root, 0.08, 0.14, Vector3.ZERO, ecto_glow)
				orbit_items.append({
					"node": wisp,
					"radius": 0.86,
					"speed": -1.45 - float(i) * 0.2,
					"base_y": 0.58 + float(i) * 0.10,
					"wave_spd": 2.4,
					"wave_amp": 0.22,
					"self_rot": Vector3(1.2, 2.5, 0.0),
					"angle": float(i) * (TAU / 4.0)
				})

		"leaderboards", "leaderboard", "trophy":
			# HALL OF FAME: Grand Champion Gold Trophy Cup & Orbiting 3D Golden Stars (★ ★ ★)!
			emblem_base_y = 0.70
			emblem_root = Node3D.new()
			emblem_root.name = "Emblem_ChampionTrophy"
			emblem_root.position = Vector3(0, emblem_base_y, 0)
			root.add_child(emblem_root)
			
			var trophy_gold := make_mat(Color("#F1C40F"), 0.18, 0.90, Color("#F39C12") * 0.8)
			var star_glow := make_mat(Color("#FFF176"), 0.1, 0.2, Color("#FBC02D") * 2.0)
			
			# Sculpted Golden Trophy Chalice & Spatula
			add_cylinder(emblem_root, 0.26, 0.12, 0.22, Vector3(0, -0.22, 0), trophy_gold)
			add_cylinder(emblem_root, 0.05, 0.05, 0.20, Vector3(0, -0.06, 0), trophy_gold)
			add_cylinder(emblem_root, 0.32, 0.12, 0.38, Vector3(0, 0.20, 0), trophy_gold)
			# Two trophy handles
			for h_side: float in [-1.0, 1.0]:
				add_torus(emblem_root, 0.08, 0.14, Vector3(h_side * 0.32, 0.22, 0.0), trophy_gold, Vector3(0, 0, 90))
			# Golden Spatula rising from the cup
			add_box(emblem_root, Vector3(0.16, 0.24, 0.02), Vector3(0, 0.44, 0), trophy_gold)
			
			# 3 Orbiting 3D Golden Stars (★ ★ ★)
			for i: int in range(3):
				var s_root := Node3D.new()
				# 5-pointed star made from intersecting prisms
				add_box(s_root, Vector3(0.18, 0.18, 0.04), Vector3.ZERO, star_glow, Vector3(0, 0, 0))
				add_box(s_root, Vector3(0.18, 0.18, 0.04), Vector3.ZERO, star_glow, Vector3(0, 0, 45))
				root.add_child(s_root)
				orbit_items.append({
					"node": s_root,
					"radius": 0.86,
					"speed": 1.4 + float(i) * 0.25,
					"base_y": 0.62 + float(i) * 0.12,
					"wave_spd": 2.2,
					"wave_amp": 0.16,
					"self_rot": Vector3(2.5, 3.5, 1.5),
					"angle": float(i) * (TAU / 3.0)
				})

	return {
		"root": root,
		"ring_node": outer_ring,
		"beacon_node": beacon,
		"emblem_node": emblem_root,
		"emblem_base_y": emblem_base_y,
		"orbit_items": orbit_items,
		"ring_items": ring_items,
		"particles": particles
	}
