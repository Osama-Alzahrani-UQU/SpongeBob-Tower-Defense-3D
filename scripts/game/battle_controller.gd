extends Node3D

## BattleController 3D - Main 3D tower defense loop, 3D environment, wave logic, and 3D raycast placement

signal base_hp_changed(current_hp, max_hp)
signal cash_changed(current_cash)
signal wave_started(wave_num)
signal wave_completed(wave_num)
signal game_over(victory)
signal enemy_killed_updated(total_kills)
signal wave_countdown_started(duration)
signal wave_countdown_updated(seconds_remaining)
signal wave_countdown_cancelled()

const MAX_BASE_HP: int = 100
var base_hp: int = 100
var cash: int = 500

var current_wave: int = 0
var max_waves: int = 15
var is_infinity_mode: bool = false
var is_game_over_triggered: bool = false
var killed_bots_total: int = 0
var killed_bots_by_type: Dictionary = {
	"jellyfish_pink": 0,
	"jellyfish_blue": 0,
	"robot_worker": 0,
	"robot_enforcer": 0,
	"mecha_plankton_boss": 0
}
var last_infinity_rewards: Dictionary = {}
var wave_in_progress: bool = false
var enemies_remaining_to_spawn: int = 0
var active_enemies_count: int = 0
var total_enemies_pending_spawn: int = 0
var last_awarded_wave: int = 0
var _watchdog_timer: float = 0.0

var is_wave_countdown_active: bool = false
var wave_countdown_remaining: float = 0.0

var game_speed: float = 1.0
var selected_tower_to_place: String = ""
var selected_active_tower: Node3D = null

var tower_scene = preload("res://scenes/towers/tower.tscn")
var enemy_scene = preload("res://scenes/enemies/enemy.tscn")

@onready var path_node: Path3D = $Path3D
@onready var towers_container: Node3D = $Towers
@onready var hud: CanvasLayer = $HUD
@onready var camera_3d: Camera3D = $Camera3D

const MIN_PATH_DISTANCE: float = 1.85
const MIN_TOWER_DISTANCE: float = 1.80

var placement_preview: Node3D = null
var preview_dome: Node3D = null
var preview_base_ring: MeshInstance3D = null
var preview_cost_label: Label3D = null
const RangeDome3DScript = preload("res://scripts/towers/range_dome_3d.gd")

func _ready() -> void:
	is_infinity_mode = (PlayerData.current_battle_mode == "infinity")
	is_game_over_triggered = false
	killed_bots_total = 0
	killed_bots_by_type.clear()
	for k in GameData.ENEMIES.keys():
		killed_bots_by_type[k] = 0
	last_infinity_rewards = {}
	base_hp = MAX_BASE_HP
	cash = 500
	
	if not is_infinity_mode:
		var st_id: int = PlayerData.selected_stage_id
		var st_data: Dictionary = GameData.get_stage(st_id)
		max_waves = int(st_data.get("waves", 10))
	else:
		max_waves = 999999
		
	emit_signal("base_hp_changed", base_hp, MAX_BASE_HP)
	emit_signal("cash_changed", cash)
	_setup_3d_environment()
	_setup_path()
	_build_3d_scenery()
	
	var active_theme = _get_active_theme_id()
	if AudioManager:
		if is_infinity_mode:
			AudioManager.play_bgm("infinity")
		else:
			if active_theme == "krusty_interior":
				AudioManager.play_bgm("zone2_krusty")
			elif active_theme == "squidward_interior":
				AudioManager.play_bgm("zone3_squidward")
			else:
				AudioManager.play_bgm("zone1_outskirts")
				
	if hud and hud.has_method("_update_hud_labels"):
		hud._update_hud_labels()

func _get_active_theme_id() -> String:
	if is_infinity_mode:
		var inf_theme: String = str(PlayerData.selected_infinity_map)
		return inf_theme if inf_theme != "" else "outskirts"
	var st_id: int = PlayerData.selected_stage_id
	var st_data: Dictionary = GameData.get_stage(st_id)
	return str(st_data.get("theme", "outskirts"))

func _setup_3d_environment() -> void:
	var theme_id = _get_active_theme_id()
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	
	var sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	
	if theme_id == "krusty_interior":
		# Warm restaurant timber interior atmosphere
		env.background_color = Color(0.12, 0.08, 0.05)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.96, 0.78, 0.52)
		env.ambient_light_energy = 1.35
		env.fog_enabled = true
		env.fog_light_color = Color(0.18, 0.12, 0.08)
		env.fog_density = 0.005
		
		sun.light_color = Color(1.0, 0.92, 0.76)
		sun.light_energy = 1.45
		sun.rotation_degrees = Vector3(-60, 30, 0)
	elif theme_id == "squidward_interior":
		# Refined Moai art gallery atmosphere
		env.background_color = Color(0.05, 0.12, 0.16)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.42, 0.76, 0.88)
		env.ambient_light_energy = 1.25
		env.fog_enabled = true
		env.fog_light_color = Color(0.06, 0.15, 0.20)
		env.fog_density = 0.006
		
		sun.light_color = Color(0.88, 0.94, 1.0)
		sun.light_energy = 1.40
		sun.rotation_degrees = Vector3(-55, 40, 0)
	else:
		# Ocean Sandy Outskirts atmosphere
		env.background_color = Color(0.06, 0.28, 0.48)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.35, 0.72, 0.92)
		env.ambient_light_energy = 1.15
		env.fog_enabled = true
		env.fog_light_color = Color(0.08, 0.35, 0.55)
		env.fog_density = 0.008
		
		sun.light_color = Color(0.95, 0.98, 1.0)
		sun.light_energy = 1.35
		sun.rotation_degrees = Vector3(-55, 35, 0)
		
	env_node.environment = env
	add_child(env_node)
	add_child(sun)
	
	if camera_3d:
		camera_3d.position = Vector3(0, 21.0, 17.5)
		camera_3d.look_at(Vector3(0, 0, 1.0), Vector3.UP)

func _setup_path() -> void:
	if not path_node:
		path_node = Path3D.new()
		path_node.name = "Path3D"
		add_child(path_node)
	var curve = Curve3D.new()
	var theme_id = _get_active_theme_id()
	
	var waypoints: Array[Vector3] = []
	var r_fillet: float = 1.35
	
	if theme_id == "krusty_interior":
		# Zone 2: Krusty Krab Restaurant Floor Plan (Kitchen pass, dining aisles, office vault safe)
		r_fillet = 1.20
		waypoints = [
			Vector3(-14.4, 0.0, -6.0),
			Vector3(2.5, 0.0, -6.0),
			Vector3(2.5, 0.0, -1.5),
			Vector3(13.0, 0.0, -1.5),
			Vector3(13.0, 0.0, 3.5),
			Vector3(-6.0, 0.0, 3.5),
			Vector3(-6.0, 0.0, 7.5),
			Vector3(-13.0, 0.0, 7.5)
		]
	elif theme_id == "squidward_interior":
		# Zone 3: Squidward Moai Art Salon (Grand Spiral Gallery Colonnade Promenade)
		r_fillet = 1.10
		waypoints = [
			Vector3(-14.4, 0.0, -7.5),
			Vector3(-7.5, 0.0, -7.5),
			Vector3(-7.5, 0.0, 1.0),
			Vector3(6.0, 0.0, 1.0),
			Vector3(6.0, 0.0, -6.5),
			Vector3(13.5, 0.0, -6.5),
			Vector3(13.5, 0.0, 7.0),
			Vector3(0.5, 0.0, 7.0),
			Vector3(0.5, 0.0, 3.5),
			Vector3(-4.0, 0.0, 3.5),
			Vector3(-4.0, 0.0, 8.0),
			Vector3(-13.0, 0.0, 8.0)
		]
	else:
		# Zone 1: Bikini Bottom Outskirts (Winding Coastal Serpentine Trail)
		r_fillet = 1.35
		waypoints = [
			Vector3(-14.4, 0.0, -7.0),
			Vector3(-5.0, 0.0, -7.0),
			Vector3(-5.0, 0.0, -1.0),
			Vector3(4.0, 0.0, -1.0),
			Vector3(4.0, 0.0, -6.5),
			Vector3(12.5, 0.0, -6.5),
			Vector3(12.5, 0.0, 4.5),
			Vector3(-2.0, 0.0, 4.5),
			Vector3(-2.0, 0.0, 8.0),
			Vector3(-13.0, 0.0, 8.0)
		]
	
	var k_bezier: float = r_fillet * 0.5522847
	
	# Start point (straight out from portal)
	curve.add_point(waypoints[0])
	
	# Add smooth circular fillet arcs at all interior 90-degree corners
	for i in range(1, waypoints.size() - 1):
		var p_prev: Vector3 = waypoints[i - 1]
		var p_curr: Vector3 = waypoints[i]
		var p_next: Vector3 = waypoints[i + 1]
		
		var d_in: Vector3 = (p_curr - p_prev).normalized()
		var d_out: Vector3 = (p_next - p_curr).normalized()
		
		var c_in: Vector3 = p_curr - d_in * r_fillet
		var c_out: Vector3 = p_curr + d_out * r_fillet
		
		curve.add_point(c_in, Vector3.ZERO, d_in * k_bezier)
		curve.add_point(c_out, -d_out * k_bezier, Vector3.ZERO)
		
	# End point (straight into base)
	curve.add_point(waypoints[waypoints.size() - 1])
	curve.bake_interval = 0.20
	path_node.curve = curve

func _build_3d_scenery() -> void:
	var scenery = Node3D.new()
	scenery.name = "Scenery3D"
	add_child(scenery)
	
	var theme_id = _get_active_theme_id()
	
	if theme_id == "krusty_interior":
		_build_krusty_interior_scenery(scenery)
	elif theme_id == "squidward_interior":
		_build_squidward_interior_scenery(scenery)
	else:
		_build_outskirts_scenery(scenery)
		
	_setup_placement_preview()

func _setup_placement_preview() -> void:
	if placement_preview:
		return
	placement_preview = Node3D.new()
	placement_preview.name = "PlacementPreview"
	
	preview_dome = RangeDome3DScript.new()
	preview_dome.name = "PreviewDome"
	placement_preview.add_child(preview_dome)
	
	preview_base_ring = MeshInstance3D.new()
	var b_torus = TorusMesh.new()
	b_torus.inner_radius = 0.75
	b_torus.outer_radius = 0.95
	preview_base_ring.mesh = b_torus
	preview_base_ring.position = Vector3(0, 0.05, 0)
	preview_base_ring.material_override = ModelBuilder3D.make_mat(Color(0.25, 0.95, 0.55), 0.2, 0.0, Color(0.25, 0.95, 0.55), 0.85)
	placement_preview.add_child(preview_base_ring)
	
	preview_cost_label = Label3D.new()
	preview_cost_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	preview_cost_label.font_size = 28
	preview_cost_label.outline_size = 8
	preview_cost_label.position = Vector3(0, 2.4, 0)
	placement_preview.add_child(preview_cost_label)
	
	placement_preview.visible = false
	add_child(placement_preview)

func _build_ribbon_path(scenery: Node3D, main_mat: Material, border_mat: Material, alt_mat: Material = null) -> void:
	if not path_node or not path_node.curve:
		return
	var curve: Curve3D = path_node.curve
	curve.bake_interval = 0.20
	var baked_len: float = curve.get_baked_length()
	if baked_len < 1.0:
		return
		
	var step: float = 0.20
	var d: float = 0.0
	var pts: Array[Vector3] = []
	while d < baked_len:
		pts.append(curve.sample_baked(d))
		d += step
	pts.append(curve.sample_baked(baked_len))
	
	if pts.size() < 2:
		return
		
	var road_hw := 1.05
	var border_hw := 1.25
	var y_road := 0.06
	var y_border := 0.045
	
	if main_mat is BaseMaterial3D:
		main_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if border_mat is BaseMaterial3D:
		border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if alt_mat and alt_mat is BaseMaterial3D:
		alt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var n_pts := pts.size()
	var left_road: Array[Vector3] = []
	var right_road: Array[Vector3] = []
	var left_curb: Array[Vector3] = []
	var right_curb: Array[Vector3] = []
	
	left_road.resize(n_pts)
	right_road.resize(n_pts)
	left_curb.resize(n_pts)
	right_curb.resize(n_pts)
	
	for i in range(n_pts):
		var fwd: Vector3
		if i == 0:
			fwd = (pts[1] - pts[0]).normalized()
		elif i == n_pts - 1:
			fwd = (pts[n_pts - 1] - pts[n_pts - 2]).normalized()
		else:
			var d_prev := (pts[i] - pts[i - 1]).normalized()
			var d_next := (pts[i + 1] - pts[i]).normalized()
			fwd = (d_prev + d_next).normalized()
			
		var side: Vector3 = fwd.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
			
		var p := pts[i]
		left_road[i] = p - side * road_hw + Vector3(0, y_road, 0)
		right_road[i] = p + side * road_hw + Vector3(0, y_road, 0)
		left_curb[i] = p - side * border_hw + Vector3(0, y_border, 0)
		right_curb[i] = p + side * border_hw + Vector3(0, y_border, 0)
	
	var st_road := SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var st_alt: SurfaceTool = null
	if alt_mat:
		st_alt = SurfaceTool.new()
		st_alt.begin(Mesh.PRIMITIVE_TRIANGLES)
		
	var st_border := SurfaceTool.new()
	st_border.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(n_pts - 1):
		# Left outer border curb (CCW upward normal)
		st_border.add_vertex(left_curb[i])
		st_border.add_vertex(left_curb[i + 1])
		st_border.add_vertex(left_road[i])
		
		st_border.add_vertex(left_road[i])
		st_border.add_vertex(left_curb[i + 1])
		st_border.add_vertex(left_road[i + 1])
		
		# Right outer border curb (CCW upward normal)
		st_border.add_vertex(right_road[i])
		st_border.add_vertex(right_road[i + 1])
		st_border.add_vertex(right_curb[i])
		
		st_border.add_vertex(right_curb[i])
		st_border.add_vertex(right_road[i + 1])
		st_border.add_vertex(right_curb[i + 1])
		
		# Road ribbon quad (CCW upward normal, sharing vertices seamlessly!)
		var active_st: SurfaceTool = st_road
		if alt_mat and (i % 2 == 1):
			active_st = st_alt
			
		active_st.add_vertex(left_road[i])
		active_st.add_vertex(left_road[i + 1])
		active_st.add_vertex(right_road[i])
		
		active_st.add_vertex(right_road[i])
		active_st.add_vertex(left_road[i + 1])
		active_st.add_vertex(right_road[i + 1])
		
	st_road.generate_normals()
	var m_road := MeshInstance3D.new()
	m_road.mesh = st_road.commit()
	m_road.material_override = main_mat
	scenery.add_child(m_road)
	
	if alt_mat and st_alt:
		st_alt.generate_normals()
		var m_alt := MeshInstance3D.new()
		m_alt.mesh = st_alt.commit()
		m_alt.material_override = alt_mat
		scenery.add_child(m_alt)
		
	st_border.generate_normals()
	var m_border := MeshInstance3D.new()
	m_border.mesh = st_border.commit()
	m_border.material_override = border_mat
	scenery.add_child(m_border)

func _build_outskirts_scenery(scenery: Node3D) -> void:
	# Ocean Sandy Floor
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(48.0, 0.6, 34.0)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0, -0.3, 0)
	floor_mesh.material_override = ModelBuilder3D.make_mat(Color(0.86, 0.76, 0.54), 0.95)
	scenery.add_child(floor_mesh)
	
	# Smooth continuous 3D coral stone road (Zero Overlap!)
	var road_mat = ModelBuilder3D.make_mat(Color(0.62, 0.52, 0.36), 0.9)
	var alt_road_mat = ModelBuilder3D.make_mat(Color(0.66, 0.55, 0.39), 0.9)
	var border_mat = ModelBuilder3D.make_mat(Color(0.45, 0.38, 0.26), 0.9)
	_build_ribbon_path(scenery, road_mat, border_mat, alt_road_mat)
		
	# Spawn Portal at Start of Path (-14, 0, -7) facing East (+X) down the starting road
	var start_portal = ModelBuilder3D.build_landmark_model("BattlePortal")
	start_portal.name = "StartPortal"
	start_portal.position = Vector3(-14.4, 0.0, -7.0)
	start_portal.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	start_portal.scale = Vector3(0.85, 0.85, 0.85)
	scenery.add_child(start_portal)
	
	# Krusty Krab Base at End of Path (-12, 0, 8) with front double doors facing East (+X) into the incoming road
	var krusty_base = ModelBuilder3D.build_landmark_model("KrustyKrab")
	krusty_base.name = "KrustyBase"
	krusty_base.position = Vector3(-14.6, 0.0, 8.0)
	krusty_base.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	krusty_base.scale = Vector3(0.9, 0.9, 0.9)
	if krusty_base.has_node("ClamSignPivot"):
		krusty_base.get_node("ClamSignPivot").rotation_degrees = Vector3(0.0, -55.0, 0.0)
	scenery.add_child(krusty_base)

func _build_krusty_interior_scenery(scenery: Node3D) -> void:
	# 1. Mahogany Ship Deck Floor
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(48.0, 0.6, 34.0)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0, -0.3, 0)
	var wood_floor_mat = ModelBuilder3D.make_mat(Color(0.46, 0.28, 0.16), 0.75)
	floor_mesh.material_override = wood_floor_mat
	scenery.add_child(floor_mesh)
	
	# Floor wood plank slats
	var dark_seam_mat = ModelBuilder3D.make_mat(Color(0.25, 0.14, 0.08), 0.9)
	for z_slat in range(-14, 15, 2):
		ModelBuilder3D.add_box(scenery, Vector3(46.0, 0.03, 0.08), Vector3(0, 0.015, float(z_slat)), dark_seam_mat)
		
	# 2. Checkered Restaurant Carpet / Walkway (Continuous Smooth Ribbon, Zero Overlap!)
	var red_check_mat = ModelBuilder3D.make_mat(Color(0.82, 0.20, 0.18), 0.8)
	var cream_check_mat = ModelBuilder3D.make_mat(Color(0.92, 0.88, 0.76), 0.8)
	var brass_trim_mat = ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.25), 0.35, 0.7)
	_build_ribbon_path(scenery, red_check_mat, brass_trim_mat, cream_check_mat)
		
	# 3. Perimeter Wooden Walls & Wooden Beams
	var wall_mat = ModelBuilder3D.make_mat(Color(0.38, 0.22, 0.12), 0.85)
	var beam_mat = ModelBuilder3D.make_mat(Color(0.24, 0.14, 0.07), 0.9)
	var buoy_white = ModelBuilder3D.make_mat(Color(0.95, 0.95, 0.95), 0.6)
	var buoy_red = ModelBuilder3D.make_mat(Color(0.85, 0.15, 0.15), 0.6)
	
	# North Back Wall (Z = -12)
	ModelBuilder3D.add_box(scenery, Vector3(44.0, 7.0, 0.8), Vector3(0, 3.5, -12.0), wall_mat)
	# South Low Half-Railing (Z = +12) - Low so camera sees inside
	ModelBuilder3D.add_box(scenery, Vector3(44.0, 1.4, 0.6), Vector3(0, 0.7, 12.0), beam_mat)
	# West Wall (X = -18)
	ModelBuilder3D.add_box(scenery, Vector3(0.8, 7.0, 24.0), Vector3(-18.0, 3.5, 0), wall_mat)
	# East Wall (X = +18)
	ModelBuilder3D.add_box(scenery, Vector3(0.8, 7.0, 24.0), Vector3(18.0, 3.5, 0), wall_mat)
	
	# Decorative Wall Beams & Lifesaver Buoys on North Wall
	for bx in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		ModelBuilder3D.add_box(scenery, Vector3(0.7, 7.2, 0.9), Vector3(bx, 3.5, -11.95), beam_mat)
		var buoy_pivot = Node3D.new()
		buoy_pivot.position = Vector3(bx, 4.2, -11.4)
		scenery.add_child(buoy_pivot)
		ModelBuilder3D.add_torus(buoy_pivot, 0.28, 0.46, Vector3.ZERO, buoy_white, Vector3(90, 0, 0))
		ModelBuilder3D.add_box(buoy_pivot, Vector3(0.12, 0.30, 0.10), Vector3(0, 0.35, 0), buoy_red)
		ModelBuilder3D.add_box(buoy_pivot, Vector3(0.12, 0.30, 0.10), Vector3(0, -0.35, 0), buoy_red)
		
	# 4. Authentic Krusty Krab Kitchen Service Entrance at Start of Path (-14.4, 0, -6)
	var kitchen_portal = Node3D.new()
	kitchen_portal.name = "StartPortal"
	kitchen_portal.position = Vector3(-14.4, 0, -6.0)
	kitchen_portal.rotation_degrees = Vector3.ZERO
	scenery.add_child(kitchen_portal)
	
	var door_wood_mat = ModelBuilder3D.make_mat(Color(0.52, 0.32, 0.18), 0.75)
	var glass_round_mat = ModelBuilder3D.make_mat(Color(0.65, 0.92, 1.0), 0.1, 0.0, Color.BLACK, 0.4)
	
	# Wooden Arch Frame flanking path along Z
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.6, 4.2, 0.4), Vector3(0, 2.1, -1.8), beam_mat)
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.6, 4.2, 0.4), Vector3(0, 2.1, 1.8), beam_mat)
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.6, 0.5, 4.0), Vector3(0, 4.2, 0), beam_mat)
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.15, 0.9, 3.2), Vector3(0, 3.55, 0), wall_mat)
	
	# Classic Krusty Krab Double Swinging Kitchen Doors with Round Porthole Windows
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.12, 2.8, 1.45), Vector3(0, 1.45, -0.75), door_wood_mat)
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.12, 2.8, 1.45), Vector3(0, 1.45, 0.75), door_wood_mat)
	# Brass Kickplates
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.14, 0.45, 1.45), Vector3(0, 0.25, -0.75), brass_trim_mat)
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.14, 0.45, 1.45), Vector3(0, 0.25, 0.75), brass_trim_mat)
	# Circular Porthole Windows with Brass Rings
	ModelBuilder3D.add_cylinder(kitchen_portal, 0.26, 0.26, 0.14, Vector3(0, 2.1, -0.75), glass_round_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_cylinder(kitchen_portal, 0.26, 0.26, 0.14, Vector3(0, 2.1, 0.75), glass_round_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(kitchen_portal, 0.22, 0.28, Vector3(0, 2.1, -0.75), brass_trim_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(kitchen_portal, 0.22, 0.28, Vector3(0, 2.1, 0.75), brass_trim_mat, Vector3(0, 0, 90))
	
	# Overhead Kitchen Sign
	ModelBuilder3D.add_box(kitchen_portal, Vector3(0.14, 0.65, 3.2), Vector3(0.1, 4.8, 0), ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.42), 0.75))
	var kitch_lbl = Label3D.new()
	kitch_lbl.text = "🍴 KRUSTY KRAB KITCHEN • ENTRANCE"
	kitch_lbl.font_size = 20
	kitch_lbl.modulate = Color(1.0, 0.90, 0.25)
	kitch_lbl.position = Vector3(0.2, 4.8, 0)
	kitch_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	kitch_lbl.no_depth_test = true
	kitchen_portal.add_child(kitch_lbl)
	
	# 5. Iconic Cartoon Mr. Krabs Iron Safe Base at End of Path (-14.0, 0, 7.5)
	var vault_group = Node3D.new()
	vault_group.name = "KrustyBase"
	vault_group.position = Vector3(-14.0, 0, 7.5)
	vault_group.rotation_degrees = Vector3.ZERO
	scenery.add_child(vault_group)
	
	var iron_mat = ModelBuilder3D.make_mat(Color(0.24, 0.28, 0.32), 0.4, 0.6)
	var iron_trim_mat = ModelBuilder3D.make_mat(Color(0.38, 0.42, 0.46), 0.35, 0.75)
	var gold_brass_mat = ModelBuilder3D.make_mat(Color(0.95, 0.80, 0.20), 0.20, 0.90)
	var dial_face_mat = ModelBuilder3D.make_mat(Color(0.12, 0.14, 0.16), 0.5)
	var glass_mat = ModelBuilder3D.make_mat(Color(0.70, 0.95, 1.0), 0.08, 0.1, Color.BLACK, 0.35)
	var formula_mat = ModelBuilder3D.make_mat(Color(0.96, 0.88, 0.65), 0.8)
	var bottle_glass_mat = ModelBuilder3D.make_mat(Color(0.25, 0.85, 0.45, 0.55), 0.1, 0.0, Color(0.2, 0.8, 0.4) * 0.4, 0.55)
	
	# Safe Pedestal & Main Body
	ModelBuilder3D.add_box(vault_group, Vector3(3.6, 0.3, 3.6), Vector3(0, 0.15, 0), iron_trim_mat)
	ModelBuilder3D.add_box(vault_group, Vector3(3.2, 3.2, 3.2), Vector3(0, 1.9, 0), iron_mat)
	
	# Top Armored Beveled Crown (Visually striking from top-down camera view!)
	ModelBuilder3D.add_box(vault_group, Vector3(3.4, 0.2, 3.4), Vector3(0, 3.6, 0), iron_trim_mat)
	ModelBuilder3D.add_cylinder(vault_group, 1.1, 1.3, 0.25, Vector3(0, 3.82, 0), iron_trim_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.75, 0.85, 0.15, Vector3(0, 3.98, 0), gold_brass_mat)
	# Golden Dollar Emblem on Top Roof
	ModelBuilder3D.add_box(vault_group, Vector3(0.16, 0.08, 0.85), Vector3(0, 4.10, 0), gold_brass_mat)
	ModelBuilder3D.add_box(vault_group, Vector3(0.65, 0.08, 0.16), Vector3(0, 4.10, 0.25), gold_brass_mat)
	ModelBuilder3D.add_box(vault_group, Vector3(0.65, 0.08, 0.16), Vector3(0, 4.10, -0.25), gold_brass_mat)
	
	# Riveted Corner Columns
	for cx in [-1.55, 1.55]:
		for cz in [-1.55, 1.55]:
			ModelBuilder3D.add_box(vault_group, Vector3(0.22, 3.4, 0.22), Vector3(cx, 1.9, cz), iron_trim_mat)
			ModelBuilder3D.add_sphere(vault_group, 0.14, 0.14, Vector3(cx, 3.65, cz), gold_brass_mat)
			
	# Heavy Circular Vault Door on Front Face (+X, facing incoming road)
	var door_x := 1.62
	ModelBuilder3D.add_cylinder(vault_group, 1.25, 1.25, 0.18, Vector3(door_x, 1.9, 0), iron_trim_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_cylinder(vault_group, 1.05, 1.05, 0.22, Vector3(door_x + 0.02, 1.9, 0), dial_face_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(vault_group, 0.95, 1.10, Vector3(door_x + 0.04, 1.9, 0), gold_brass_mat, Vector3(0, 0, 90))
	
	# Heavy Steel Door Hinges on North side (-Z)
	ModelBuilder3D.add_cylinder(vault_group, 0.12, 0.12, 0.45, Vector3(door_x - 0.05, 2.6, -1.15), iron_trim_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.12, 0.12, 0.45, Vector3(door_x - 0.05, 1.2, -1.15), iron_trim_mat)
	
	# Spoke Wheel Handle on Front Door
	var wheel_x := door_x + 0.16
	ModelBuilder3D.add_cylinder(vault_group, 0.18, 0.18, 0.22, Vector3(wheel_x, 1.9, 0), gold_brass_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(vault_group, 0.48, 0.60, Vector3(wheel_x + 0.02, 1.9, 0), gold_brass_mat, Vector3(0, 0, 90))
	for w_deg in [0, 45, 90, 135]:
		ModelBuilder3D.add_cylinder(vault_group, 0.035, 0.035, 1.10, Vector3(wheel_x + 0.02, 1.9, 0), gold_brass_mat, Vector3(w_deg, 0, 0))
	# Combination Dial
	ModelBuilder3D.add_cylinder(vault_group, 0.16, 0.16, 0.24, Vector3(door_x + 0.08, 2.5, 0.55), gold_brass_mat, Vector3(0, 0, 90))
	
	# Dedicated Krusty Krab Secret Formula Display Pedestal (Open floor at world (-13.5, 0, 4.3), ZERO wall overlap!)
	var ped_pos := Vector3(0.5, 0.0, -3.2)
	ModelBuilder3D.add_cylinder(vault_group, 0.45, 0.55, 0.90, ped_pos + Vector3(0, 0.45, 0), ModelBuilder3D.make_mat(Color(0.48, 0.30, 0.16), 0.8))
	ModelBuilder3D.add_torus(vault_group, 0.42, 0.52, ped_pos + Vector3(0, 0.88, 0), gold_brass_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.42, 0.42, 0.08, ped_pos + Vector3(0, 0.94, 0), ModelBuilder3D.make_mat(Color(0.72, 0.18, 0.16), 0.7))
	# Crystal Cloche Bell Jar & Glowing Secret Formula
	ModelBuilder3D.add_cylinder(vault_group, 0.30, 0.30, 0.65, ped_pos + Vector3(0, 1.30, 0), glass_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.09, 0.10, 0.36, ped_pos + Vector3(0, 1.22, 0), bottle_glass_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.04, 0.04, 0.14, ped_pos + Vector3(0, 1.45, 0), bottle_glass_mat)
	ModelBuilder3D.add_cylinder(vault_group, 0.045, 0.035, 0.08, ped_pos + Vector3(0, 1.54, 0), ModelBuilder3D.make_mat(Color(0.65, 0.42, 0.22), 0.9))
	ModelBuilder3D.add_cylinder(vault_group, 0.05, 0.05, 0.24, ped_pos + Vector3(0, 1.22, 0), formula_mat)
	
	var vault_lbl = Label3D.new()
	vault_lbl.text = "🔒 SECRET FORMULA VAULT"
	vault_lbl.font_size = 24
	vault_lbl.modulate = Color(1.0, 0.88, 0.25)
	vault_lbl.position = Vector3(0, 4.6, 0)
	vault_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vault_lbl.no_depth_test = true
	vault_group.add_child(vault_lbl)
	
	# 6. Restaurant Dining Sets (5 perfectly spaced positions, >= 3.5m from road and walls!)
	var table_positions = [
		Vector3(-10.5, 0.0, -1.8),
		Vector3(7.5, 0.0, -7.0),
		Vector3(7.5, 0.0, 7.5),
		Vector3(14.8, 0.0, 7.5),
		Vector3(1.5, 0.0, 7.5)
	]
	for t_pos in table_positions:
		_add_krusty_table_set(scenery, t_pos)
		
	# 7. Order Boat / Cashier Dinghy
	_add_cashier_boat(scenery, Vector3(-1.0, 0.0, 0.5))

func _add_krusty_table_set(parent: Node3D, pos: Vector3) -> void:
	var t_group = Node3D.new()
	t_group.position = pos
	parent.add_child(t_group)
	
	var barrel_mat = ModelBuilder3D.make_mat(Color(0.48, 0.30, 0.16), 0.8)
	var wheel_mat = ModelBuilder3D.make_mat(Color(0.36, 0.22, 0.12), 0.8)
	var brass_mat = ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.25), 0.35, 0.7)
	var ketchup_mat = ModelBuilder3D.make_mat(Color(0.88, 0.12, 0.12), 0.5)
	var mustard_mat = ModelBuilder3D.make_mat(Color(0.96, 0.82, 0.14), 0.5)
	var stool_seat = ModelBuilder3D.make_mat(Color(0.68, 0.22, 0.18), 0.7)
	
	# Table Barrel Pedestal
	ModelBuilder3D.add_cylinder(t_group, 0.40, 0.48, 0.78, Vector3(0, 0.39, 0), barrel_mat)
	ModelBuilder3D.add_torus(t_group, 0.41, 0.48, Vector3(0, 0.25, 0), brass_mat)
	ModelBuilder3D.add_torus(t_group, 0.41, 0.48, Vector3(0, 0.55, 0), brass_mat)
	# Ship Wheel Table Top
	ModelBuilder3D.add_cylinder(t_group, 1.15, 1.15, 0.08, Vector3(0, 0.82, 0), wheel_mat)
	ModelBuilder3D.add_torus(t_group, 1.05, 1.20, Vector3(0, 0.82, 0), brass_mat)
	for spoke_i in range(4):
		ModelBuilder3D.add_cylinder(t_group, 0.04, 0.04, 2.3, Vector3(0, 0.82, 0), wheel_mat, Vector3(0, float(spoke_i * 45), 90))
	# Ketchup & Mustard Bottles
	ModelBuilder3D.add_cylinder(t_group, 0.05, 0.06, 0.22, Vector3(-0.12, 0.97, 0.05), ketchup_mat)
	ModelBuilder3D.add_cylinder(t_group, 0.02, 0.04, 0.08, Vector3(-0.12, 1.10, 0.05), ketchup_mat)
	ModelBuilder3D.add_cylinder(t_group, 0.05, 0.06, 0.22, Vector3(0.12, 0.97, -0.05), mustard_mat)
	ModelBuilder3D.add_cylinder(t_group, 0.02, 0.04, 0.08, Vector3(0.12, 1.10, -0.05), mustard_mat)
	
	# 2 Stools around the table
	for angle_deg in [60.0, 240.0]:
		var rad = deg_to_rad(angle_deg)
		var stool_pos = Vector3(cos(rad) * 1.5, 0.0, sin(rad) * 1.5)
		ModelBuilder3D.add_cylinder(t_group, 0.28, 0.32, 0.46, stool_pos + Vector3(0, 0.23, 0), barrel_mat)
		ModelBuilder3D.add_cylinder(t_group, 0.32, 0.32, 0.06, stool_pos + Vector3(0, 0.49, 0), stool_seat)

func _add_cashier_boat(parent: Node3D, pos: Vector3) -> void:
	var boat_group = Node3D.new()
	boat_group.position = pos
	parent.add_child(boat_group)
	
	var boat_hull_mat = ModelBuilder3D.make_mat(Color(0.55, 0.32, 0.18), 0.8)
	var boat_trim_mat = ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.25), 0.4)
	var register_mat = ModelBuilder3D.make_mat(Color(0.72, 0.60, 0.25), 0.3, 0.8)
	
	# Wooden Dinghy Hull
	ModelBuilder3D.add_box(boat_group, Vector3(2.6, 0.8, 1.4), Vector3(0, 0.4, 0), boat_hull_mat)
	ModelBuilder3D.add_cylinder(boat_group, 0.05, 0.7, 1.0, Vector3(1.6, 0.4, 0), boat_hull_mat, Vector3(0, 0, -35))
	ModelBuilder3D.add_box(boat_group, Vector3(2.7, 0.12, 1.46), Vector3(0, 0.82, 0), boat_trim_mat)
	# Cash Register on counter
	ModelBuilder3D.add_box(boat_group, Vector3(0.5, 0.45, 0.5), Vector3(0, 1.05, 0), register_mat)
	ModelBuilder3D.add_cylinder(boat_group, 0.04, 0.04, 0.2, Vector3(0.28, 1.05, 0), register_mat, Vector3(0, 0, 90))
	var sign_lbl = Label3D.new()
	sign_lbl.text = "ORDER HERE"
	sign_lbl.font_size = 20
	sign_lbl.modulate = Color(1.0, 0.9, 0.3)
	sign_lbl.position = Vector3(0, 1.6, 0)
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	boat_group.add_child(sign_lbl)

func _build_squidward_interior_scenery(scenery: Node3D) -> void:
	# 1. High-Gloss Dark Teal & Jade Art Gallery Floor
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(48.0, 0.6, 34.0)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0, -0.3, 0)
	var jade_floor_mat = ModelBuilder3D.make_mat(Color(0.08, 0.18, 0.22), 0.25, 0.15)
	floor_mesh.material_override = jade_floor_mat
	scenery.add_child(floor_mesh)
	
	# Sleek gallery perimeter gold inlay frame along outer walls (clean and elegant, no messy mid-floor grid!)
	var gold_inlay_mat = ModelBuilder3D.make_mat(Color(0.92, 0.80, 0.28), 0.2, 0.8)
	ModelBuilder3D.add_box(scenery, Vector3(34.0, 0.02, 0.10), Vector3(0, 0.01, -11.2), gold_inlay_mat)
	ModelBuilder3D.add_box(scenery, Vector3(34.0, 0.02, 0.10), Vector3(0, 0.01, 11.2), gold_inlay_mat)
	ModelBuilder3D.add_box(scenery, Vector3(0.10, 0.02, 22.4), Vector3(-17.0, 0.01, 0), gold_inlay_mat)
	ModelBuilder3D.add_box(scenery, Vector3(0.10, 0.02, 22.4), Vector3(17.0, 0.01, 0), gold_inlay_mat)
		
	# 2. Crimson Red Velvet VIP Ribbon Path with Gleaming Brass Curbs
	var red_velvet_mat = ModelBuilder3D.make_mat(Color(0.72, 0.10, 0.20), 0.82)
	var stanchion_gold_mat = ModelBuilder3D.make_mat(Color(0.96, 0.84, 0.28), 0.20, 0.88)
	_build_ribbon_path(scenery, red_velvet_mat, stanchion_gold_mat)
		
	# 3. Perimeter Moai Slate Walls with Bamboo Screen Panels
	var slate_mat = ModelBuilder3D.make_mat(Color(0.16, 0.24, 0.30), 0.7)
	var bamboo_mat = ModelBuilder3D.make_mat(Color(0.72, 0.64, 0.40), 0.6)
	var frame_mat = ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.25), 0.25, 0.8)
	
	# North Back Wall (Z = -12)
	ModelBuilder3D.add_box(scenery, Vector3(44.0, 7.5, 0.8), Vector3(0, 3.75, -12.0), slate_mat)
	# South Low Jade Balustrade (Z = +12)
	ModelBuilder3D.add_box(scenery, Vector3(44.0, 1.4, 0.6), Vector3(0, 0.7, 12.0), slate_mat)
	# West Wall (X = -18)
	ModelBuilder3D.add_box(scenery, Vector3(0.8, 7.5, 24.0), Vector3(-18.0, 3.75, 0), slate_mat)
	# East Wall (X = +18)
	ModelBuilder3D.add_box(scenery, Vector3(0.8, 7.5, 24.0), Vector3(18.0, 3.75, 0), slate_mat)
	
	# Decorative Wall Bamboo Panels & Framed Art Silhouettes on North Wall
	for bx in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		ModelBuilder3D.add_box(scenery, Vector3(2.4, 4.2, 0.15), Vector3(bx, 4.0, -11.55), bamboo_mat)
		ModelBuilder3D.add_box(scenery, Vector3(2.5, 0.1, 0.18), Vector3(bx, 6.1, -11.55), frame_mat)
		ModelBuilder3D.add_box(scenery, Vector3(2.5, 0.1, 0.18), Vector3(bx, 1.9, -11.55), frame_mat)
		
	# 4. Architectural Moai Stone & Bronze Art Salon Entrance at Start of Path (-14.4, 0, -7)
	# Properly aligned facing East (+X) down the incoming path!
	var portal_group = Node3D.new()
	portal_group.name = "StartPortal"
	portal_group.position = Vector3(-14.4, 0, -7.5)
	portal_group.rotation_degrees = Vector3.ZERO
	scenery.add_child(portal_group)
	
	var art_gold_mat = ModelBuilder3D.make_mat(Color(0.92, 0.80, 0.25), 0.25, 0.85)
	var portal_vortex_mat = ModelBuilder3D.make_mat(Color(0.55, 0.15, 0.85), 0.1, 0.0, Color(0.65, 0.25, 0.95), 0.9)
	var portal_stone_mat = ModelBuilder3D.make_mat(Color(0.18, 0.26, 0.32), 0.6)
	var bronze_door_mat = ModelBuilder3D.make_mat(Color(0.58, 0.42, 0.22), 0.4, 0.6)
	
	# Flanking Moai Slate Stone Pillars on Z=-1.8 and Z=+1.8
	ModelBuilder3D.add_box(portal_group, Vector3(1.1, 4.6, 1.0), Vector3(0, 2.3, -1.8), portal_stone_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(1.1, 4.6, 1.0), Vector3(0, 2.3, 1.8), portal_stone_mat)
	# Gold Ornamental Capitals and Base Pedestals
	ModelBuilder3D.add_box(portal_group, Vector3(1.25, 0.35, 1.15), Vector3(0, 0.18, -1.8), art_gold_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(1.25, 0.35, 1.15), Vector3(0, 0.18, 1.8), art_gold_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(1.25, 0.35, 1.15), Vector3(0, 4.45, -1.8), art_gold_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(1.25, 0.35, 1.15), Vector3(0, 4.45, 1.8), art_gold_mat)
	# Architrave Lintel
	ModelBuilder3D.add_box(portal_group, Vector3(1.3, 0.85, 4.4), Vector3(0, 4.95, 0), portal_stone_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(1.35, 0.15, 4.5), Vector3(0, 5.42, 0), art_gold_mat)
	# Open Gateway Bronze Doors
	ModelBuilder3D.add_box(portal_group, Vector3(0.12, 4.2, 1.15), Vector3(-0.35, 2.2, -0.9), bronze_door_mat)
	ModelBuilder3D.add_box(portal_group, Vector3(0.12, 4.2, 1.15), Vector3(-0.35, 2.2, 0.9), bronze_door_mat)
	# Cosmic Portal Void Threshold
	ModelBuilder3D.add_cylinder(portal_group, 1.35, 1.35, 0.15, Vector3(0, 2.2, 0), portal_vortex_mat, Vector3(0, 0, 90))
	# Velvet Rope VIP Stanchions
	ModelBuilder3D.add_cylinder(portal_group, 0.05, 0.05, 1.1, Vector3(0.8, 0.55, -2.2), art_gold_mat)
	ModelBuilder3D.add_sphere(portal_group, 0.12, 0.12, Vector3(0.8, 1.15, -2.2), art_gold_mat)
	ModelBuilder3D.add_cylinder(portal_group, 0.05, 0.05, 1.1, Vector3(0.8, 0.55, 2.2), art_gold_mat)
	ModelBuilder3D.add_sphere(portal_group, 0.12, 0.12, Vector3(0.8, 1.15, 2.2), art_gold_mat)
	
	var portal_lbl = Label3D.new()
	portal_lbl.text = "🏛️ MOAI ART SALON"
	portal_lbl.font_size = 22
	portal_lbl.modulate = Color(0.9, 0.65, 1.0)
	portal_lbl.position = Vector3(0, 5.9, 0)
	portal_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	portal_lbl.no_depth_test = true
	portal_group.add_child(portal_lbl)
	
	# 5. Squidward's Masterpiece Clarinet on Elegant Mahogany Table at End of Path (-14.0, 0, 8.0)
	# Open, elevated, proudly illuminated — NO opaque box hiding it!
	var sanctum_group = Node3D.new()
	sanctum_group.name = "KrustyBase"
	sanctum_group.position = Vector3(-14.0, 0, 8.0)
	sanctum_group.rotation_degrees = Vector3.ZERO
	scenery.add_child(sanctum_group)
	
	var mahogany_mat = ModelBuilder3D.make_mat(Color(0.35, 0.16, 0.08), 0.35)
	var mahogany_gold_mat = ModelBuilder3D.make_mat(Color(0.95, 0.82, 0.26), 0.20, 0.85)
	var velvet_runner_mat = ModelBuilder3D.make_mat(Color(0.75, 0.10, 0.22), 0.85)
	var clarinet_body_mat = ModelBuilder3D.make_mat(Color(0.12, 0.12, 0.14), 0.30, 0.25)
	var clarinet_keys_mat = ModelBuilder3D.make_mat(Color(0.95, 0.97, 1.0), 0.10, 0.95)
	var glass_dome_mat = ModelBuilder3D.make_mat(Color(0.75, 0.95, 1.0), 0.05, 0.05, Color.BLACK, 0.18)
	
	# Elegant Red & Gold Persian Floor Carpet beneath the Exhibition Table
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.8, 0.02, 2.6), Vector3(0, 0.01, 0), velvet_runner_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.9, 0.03, 0.08), Vector3(0, 0.015, -1.3), mahogany_gold_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.9, 0.03, 0.08), Vector3(0, 0.015, 1.3), mahogany_gold_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(0.08, 0.03, 2.68), Vector3(-1.95, 0.015, 0), mahogany_gold_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(0.08, 0.03, 2.68), Vector3(1.95, 0.015, 0), mahogany_gold_mat)
	
	# Elegant Baroque / Cabriole Mahogany Exhibition Table
	# 4 Curved legs with gilded brass foot caps
	for lx in [-1.35, 1.35]:
		for lz in [-0.65, 0.65]:
			ModelBuilder3D.add_cylinder(sanctum_group, 0.07, 0.09, 0.85, Vector3(lx, 0.45, lz), mahogany_mat)
			ModelBuilder3D.add_cylinder(sanctum_group, 0.095, 0.105, 0.16, Vector3(lx, 0.10, lz), mahogany_gold_mat)
			ModelBuilder3D.add_sphere(sanctum_group, 0.11, 0.11, Vector3(lx, 0.86, lz), mahogany_gold_mat)
			
	# Table Apron & Polished Table Top
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.1, 0.16, 1.6), Vector3(0, 0.88, 0), mahogany_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.14, 0.04, 1.64), Vector3(0, 0.82, 0), mahogany_gold_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.3, 0.10, 1.8), Vector3(0, 0.99, 0), mahogany_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.34, 0.03, 1.84), Vector3(0, 1.02, 0), mahogany_gold_mat)
	# Royal Crimson Velvet Table Runner with Gold Fringes
	ModelBuilder3D.add_box(sanctum_group, Vector3(3.2, 0.02, 0.95), Vector3(0, 1.05, 0), velvet_runner_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(0.08, 0.03, 0.98), Vector3(-1.6, 1.05, 0), mahogany_gold_mat)
	ModelBuilder3D.add_box(sanctum_group, Vector3(0.08, 0.03, 0.98), Vector3(1.6, 1.05, 0), mahogany_gold_mat)
	
	# Twin Polished Brass Clarinet Cradle Saddles
	ModelBuilder3D.add_cylinder(sanctum_group, 0.035, 0.05, 0.22, Vector3(-0.45, 1.16, 0), mahogany_gold_mat)
	ModelBuilder3D.add_cylinder(sanctum_group, 0.035, 0.05, 0.22, Vector3(0.45, 1.16, 0), mahogany_gold_mat)
	ModelBuilder3D.add_torus(sanctum_group, 0.065, 0.095, Vector3(-0.45, 1.28, 0), mahogany_gold_mat, Vector3(0, 90, 0))
	ModelBuilder3D.add_torus(sanctum_group, 0.065, 0.095, Vector3(0.45, 1.28, 0), mahogany_gold_mat, Vector3(0, 90, 0))
	
	# SQUIDWARD'S CONCERT CLARINET (Proudly raised & clearly visible from above!)
	# Main Blackwood Cylindrical Body (spanning along X axis)
	ModelBuilder3D.add_cylinder(sanctum_group, 0.065, 0.065, 1.85, Vector3(0.0, 1.30, 0), clarinet_body_mat, Vector3(0, 0, 90))
	# Silver Joint Rings
	for r_x in [-0.75, -0.32, 0.25, 0.72]:
		ModelBuilder3D.add_torus(sanctum_group, 0.068, 0.084, Vector3(r_x, 1.30, 0), clarinet_keys_mat, Vector3(0, 0, 90))
	# Beveled Black Mouthpiece on Left (-X)
	ModelBuilder3D.add_cylinder(sanctum_group, 0.045, 0.065, 0.32, Vector3(-1.02, 1.30, 0), clarinet_body_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(sanctum_group, 0.055, 0.075, Vector3(-0.96, 1.30, 0), mahogany_gold_mat, Vector3(0, 0, 90)) # Gold ligature
	# Flared Bell Horn on Right (+X)
	ModelBuilder3D.add_cylinder(sanctum_group, 0.16, 0.065, 0.38, Vector3(1.05, 1.30, 0), clarinet_body_mat, Vector3(0, 0, 90))
	ModelBuilder3D.add_torus(sanctum_group, 0.155, 0.175, Vector3(1.22, 1.30, 0), clarinet_keys_mat, Vector3(0, 0, 90)) # Silver bell ring
	# Detailed Silver Keys and Rods along the Clarinet body
	for key_i in range(8):
		var kx := -0.60 + float(key_i) * 0.18
		ModelBuilder3D.add_cylinder(sanctum_group, 0.02, 0.02, 0.12, Vector3(kx, 1.38, 0.04), clarinet_keys_mat, Vector3(90, 0, 0))
		ModelBuilder3D.add_sphere(sanctum_group, 0.03, 0.03, Vector3(kx, 1.38, 0.10), clarinet_keys_mat)
	ModelBuilder3D.add_cylinder(sanctum_group, 0.012, 0.012, 1.35, Vector3(0.04, 1.37, -0.05), clarinet_keys_mat, Vector3(0, 0, 90)) # Key rod
	
	# Transparent Protective Glass Dome (Low alpha, NO opaque top cover!)
	ModelBuilder3D.add_box(sanctum_group, Vector3(2.8, 0.55, 0.8), Vector3(0.0, 1.35, 0), glass_dome_mat)
	# Elegant Brass Corner Posts
	for fx in [-1.4, 1.4]:
		for fz in [-0.4, 0.4]:
			ModelBuilder3D.add_cylinder(sanctum_group, 0.016, 0.016, 0.55, Vector3(fx, 1.35, fz), mahogany_gold_mat)
			
	# Engraved Museum Brass Plaque on Front of Table (+Z)
	ModelBuilder3D.add_box(sanctum_group, Vector3(0.85, 0.18, 0.02), Vector3(0.0, 0.95, 0.91), mahogany_gold_mat)
	var plaque_lbl = Label3D.new()
	plaque_lbl.text = "Squidward's Clarinet - Opus 1"
	plaque_lbl.font_size = 15
	plaque_lbl.modulate = Color(0.12, 0.08, 0.04)
	plaque_lbl.position = Vector3(0.0, 0.95, 0.93)
	plaque_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sanctum_group.add_child(plaque_lbl)
	
	var sanctum_lbl = Label3D.new()
	sanctum_lbl.text = "🎶 SQUIDWARD'S CLARINET"
	sanctum_lbl.font_size = 24
	sanctum_lbl.modulate = Color(0.4, 0.85, 1.0)
	sanctum_lbl.position = Vector3(0, 2.6, 0)
	sanctum_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sanctum_lbl.no_depth_test = true
	sanctum_group.add_child(sanctum_lbl)
	
	# 6. Art Exhibits: "Bold and Brash" Tripod Easels & Marble Statues (5 clean, non-overlapping spots)
	var easel_positions = [
		Vector3(-10.5, 0.0, -2.2),
		Vector3(7.0, 0.0, -1.0),
		Vector3(14.8, 0.0, -6.5)
	]
	for ep in easel_positions:
		_add_bold_and_brash_easel(scenery, ep)
		
	_add_marble_squidward_bust(scenery, Vector3(14.8, 0.0, 5.5))
	_add_gallery_bench(scenery, Vector3(5.5, 0.0, 8.2))

func _add_bold_and_brash_easel(parent: Node3D, pos: Vector3) -> void:
	var easel_group = Node3D.new()
	easel_group.position = pos
	parent.add_child(easel_group)
	
	var wood_mat = ModelBuilder3D.make_mat(Color(0.72, 0.55, 0.32), 0.8)
	var canvas_bg_mat = ModelBuilder3D.make_mat(Color(0.92, 0.88, 0.72), 0.85)
	var squid_art_mat = ModelBuilder3D.make_mat(Color(0.38, 0.68, 0.58), 0.6)
	var nose_art_mat = ModelBuilder3D.make_mat(Color(0.28, 0.55, 0.45), 0.6)
	var brass_label_mat = ModelBuilder3D.make_mat(Color(0.85, 0.72, 0.25), 0.3, 0.8)
	
	# Tripod wooden easel legs
	ModelBuilder3D.add_cylinder(easel_group, 0.03, 0.03, 2.2, Vector3(-0.4, 1.0, 0.2), wood_mat, Vector3(0, 0, 12))
	ModelBuilder3D.add_cylinder(easel_group, 0.03, 0.03, 2.2, Vector3(0.4, 1.0, 0.2), wood_mat, Vector3(0, 0, -12))
	ModelBuilder3D.add_cylinder(easel_group, 0.03, 0.03, 2.2, Vector3(0.0, 1.0, -0.45), wood_mat, Vector3(-18, 0, 0))
	# Horizontal shelf
	ModelBuilder3D.add_box(easel_group, Vector3(1.3, 0.06, 0.12), Vector3(0, 1.05, 0.22), wood_mat)
	# Canvas: "Bold and Brash"
	ModelBuilder3D.add_box(easel_group, Vector3(1.1, 1.3, 0.05), Vector3(0, 1.72, 0.2), canvas_bg_mat, Vector3(-8, 0, 0))
	# Abstract Squidward Art Silhouette on canvas
	ModelBuilder3D.add_sphere(easel_group, 0.22, 0.28, Vector3(0, 1.88, 0.24), squid_art_mat, Vector3(-8, 0, 0))
	ModelBuilder3D.add_cylinder(easel_group, 0.08, 0.14, 0.35, Vector3(0, 1.62, 0.27), nose_art_mat, Vector3(15, 0, 0))
	# Museum Brass Plaque
	ModelBuilder3D.add_box(easel_group, Vector3(0.5, 0.12, 0.02), Vector3(0, 0.92, 0.24), brass_label_mat)
	var plaque_lbl = Label3D.new()
	plaque_lbl.text = "Bold and Brash"
	plaque_lbl.font_size = 14
	plaque_lbl.modulate = Color(0.1, 0.1, 0.1)
	plaque_lbl.position = Vector3(0, 0.92, 0.26)
	plaque_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	easel_group.add_child(plaque_lbl)

func _add_marble_squidward_bust(parent: Node3D, pos: Vector3) -> void:
	var bust_group = Node3D.new()
	bust_group.position = pos
	parent.add_child(bust_group)
	
	var marble_mat = ModelBuilder3D.make_mat(Color(0.95, 0.95, 0.97), 0.25, 0.05)
	# Marble Plinth
	ModelBuilder3D.add_box(bust_group, Vector3(0.9, 1.1, 0.9), Vector3(0, 0.55, 0), marble_mat)
	# Sculpted Bust Torso
	ModelBuilder3D.add_cylinder(bust_group, 0.32, 0.24, 0.55, Vector3(0, 1.35, 0), marble_mat)
	# Head with Squidward's elongated nose and round cranium
	ModelBuilder3D.add_sphere(bust_group, 0.30, 0.38, Vector3(0, 1.82, 0), marble_mat)
	ModelBuilder3D.add_cylinder(bust_group, 0.10, 0.15, 0.42, Vector3(0, 1.70, 0.28), marble_mat, Vector3(25, 0, 0))
	var bust_lbl = Label3D.new()
	bust_lbl.text = "Squidward in Marble"
	bust_lbl.font_size = 14
	bust_lbl.modulate = Color(0.8, 0.9, 1.0)
	bust_lbl.position = Vector3(0, 2.2, 0)
	bust_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bust_group.add_child(bust_lbl)

func _add_gallery_bench(parent: Node3D, pos: Vector3) -> void:
	var bench_group = Node3D.new()
	bench_group.position = pos
	parent.add_child(bench_group)
	
	var mahogany_mat = ModelBuilder3D.make_mat(Color(0.32, 0.14, 0.08), 0.5)
	var velvet_seat_mat = ModelBuilder3D.make_mat(Color(0.70, 0.12, 0.22), 0.85)
	var gold_studs_mat = ModelBuilder3D.make_mat(Color(0.88, 0.74, 0.28), 0.25, 0.8)
	
	# Mahogany Bench Frame & 4 turned legs
	for bx in [-0.9, 0.9]:
		for bz in [-0.3, 0.3]:
			ModelBuilder3D.add_cylinder(bench_group, 0.045, 0.055, 0.44, Vector3(bx, 0.22, bz), mahogany_mat)
	ModelBuilder3D.add_box(bench_group, Vector3(2.1, 0.08, 0.85), Vector3(0, 0.44, 0), mahogany_mat)
	# Tufted Velvet Cushion
	ModelBuilder3D.add_box(bench_group, Vector3(2.0, 0.14, 0.8), Vector3(0, 0.53, 0), velvet_seat_mat)
	# Gold decorative corner studs
	for sx in [-0.95, 0.95]:
		for sz in [-0.35, 0.35]:
			ModelBuilder3D.add_sphere(bench_group, 0.03, 0.03, Vector3(sx, 0.48, sz), gold_studs_mat)



func _process(delta: float) -> void:
	# Camera pan/zoom with keyboard
	if camera_3d:
		var move = Vector3.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move.z -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move.z += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			move.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move.x += 1.0
		if move.length_squared() > 0:
			camera_3d.position += move.normalized() * 12.0 * delta
			camera_3d.position.x = clampf(camera_3d.position.x, -14.0, 14.0)
			camera_3d.position.z = clampf(camera_3d.position.z, 6.0, 26.0)
			
	# Periodic Wave Watchdog: Safely detect wave completion and prevent stalls
	_watchdog_timer += delta
	if _watchdog_timer >= 0.5:
		_watchdog_timer = 0.0
		if wave_in_progress and total_enemies_pending_spawn <= 0:
			if get_living_enemies_count() == 0:
				_finish_wave()
				
	# Wave Auto-Skip Countdown Timer (ticks down when penultimate enemy spawns)
	if is_wave_countdown_active:
		wave_countdown_remaining -= delta
		emit_signal("wave_countdown_updated", maxf(0.0, wave_countdown_remaining))
		if hud and hud.has_method("update_wave_countdown"):
			hud.update_wave_countdown(maxf(0.0, wave_countdown_remaining))
		if wave_countdown_remaining <= 0.0:
			skip_to_next_wave()
			
	if selected_tower_to_place != "" and placement_preview:
		var hit = _get_mouse_ground_pos()
		if hit != null:
			placement_preview.visible = true
			placement_preview.global_position = hit + Vector3(0, 0.06, 0)
			
			var chk: Dictionary = check_placement_validity(hit, selected_tower_to_place)
			var is_valid: bool = bool(chk.get("valid", false))
			
			if preview_dome and preview_dome.has_method("set_placement_validity"):
				preview_dome.set_placement_validity(is_valid)
				
			if preview_base_ring:
				if is_valid:
					preview_base_ring.material_override = ModelBuilder3D.make_mat(Color(0.25, 0.95, 0.55), 0.2, 0.0, Color(0.25, 0.95, 0.55), 0.85)
				else:
					preview_base_ring.material_override = ModelBuilder3D.make_mat(Color(1.0, 0.15, 0.15), 0.2, 0.0, Color(1.0, 0.25, 0.25), 0.95)
					
			if preview_cost_label:
				preview_cost_label.text = str(chk.get("message", ""))
				if is_valid:
					preview_cost_label.modulate = Color(0.35, 1.0, 0.55)
				else:
					preview_cost_label.modulate = Color(1.0, 0.35, 0.35)
	elif placement_preview:
		placement_preview.visible = false

func _get_mouse_ground_pos() -> Variant:
	if not camera_3d:
		return Vector3.ZERO
	var viewport = get_viewport()
	if not viewport:
		return Vector3.ZERO
	var mouse_pos = viewport.get_mouse_position()
	var ray_origin = camera_3d.project_ray_origin(mouse_pos)
	var ray_dir = camera_3d.project_ray_normal(mouse_pos)
	var ground_plane = Plane(Vector3.UP, 0.0)
	return ground_plane.intersects_ray(ray_origin, ray_dir)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			set_selected_tower_to_place("")
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var hit = _get_mouse_ground_pos()
			if hit == null:
				return
			if selected_tower_to_place != "":
				place_tower(hit)
			else:
				# Check if clicked on an existing 3D tower
				var clicked_tower: Node3D = null
				var best_dist = 1.6
				for t in towers_container.get_children():
					var d = t.global_position.distance_to(hit)
					if d < best_dist:
						best_dist = d
						clicked_tower = t
				select_tower(clicked_tower)

func get_living_enemies_count() -> int:
	var count = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and not e.get("is_dead"):
			count += 1
	return count

func start_next_wave(force_start: bool = false) -> void:
	if not is_infinity_mode and current_wave >= max_waves:
		return
	if is_game_over_triggered:
		return
	if wave_in_progress and not force_start and total_enemies_pending_spawn > 0:
		return
	
	cancel_wave_countdown()
	current_wave += 1
	wave_in_progress = true
	emit_signal("wave_started", current_wave)
	
	# Award economy and bonus for previous wave if not yet awarded
	if current_wave > 1:
		_award_wave_income(current_wave - 1)
	
	if AudioManager:
		if current_wave == max_waves or (is_infinity_mode and current_wave % 5 == 0):
			AudioManager.play_sfx("boss_alert")
		else:
			AudioManager.play_sfx("enemy_spawn")
	
	_spawn_wave_enemies(current_wave)

func _start_next_wave_countdown(duration: float = 10.0) -> void:
	if is_game_over_triggered:
		return
	if not is_infinity_mode and current_wave >= max_waves:
		return
	is_wave_countdown_active = true
	wave_countdown_remaining = duration
	emit_signal("wave_countdown_started", duration)
	if hud and hud.has_method("show_wave_countdown"):
		hud.show_wave_countdown(duration)
	if AudioManager:
		AudioManager.play_sfx("ui_open")

func extend_wave_countdown(extra_seconds: float = 10.0) -> void:
	if not is_wave_countdown_active:
		return
	wave_countdown_remaining += extra_seconds
	emit_signal("wave_countdown_updated", wave_countdown_remaining)
	if hud and hud.has_method("on_countdown_extended"):
		hud.on_countdown_extended(extra_seconds, wave_countdown_remaining)
	if AudioManager:
		AudioManager.play_sfx("ui_click")

func skip_to_next_wave() -> void:
	if not is_wave_countdown_active and (current_wave >= max_waves and not is_infinity_mode):
		return
	cancel_wave_countdown()
	if is_game_over_triggered:
		return
	if not is_infinity_mode and current_wave >= max_waves:
		return
	start_next_wave(true)

func cancel_wave_countdown() -> void:
	if not is_wave_countdown_active:
		return
	is_wave_countdown_active = false
	wave_countdown_remaining = 0.0
	emit_signal("wave_countdown_cancelled")
	if hud and hud.has_method("hide_wave_countdown"):
		hud.hide_wave_countdown()

func _spawn_wave_enemies(wave: int) -> void:
	var active_theme = _get_active_theme_id()
	var stage_info: Dictionary = GameData.get_stage(PlayerData.selected_stage_id) if not is_infinity_mode else {}

	var enemy_pool: Array = []
	var boss_type: String = "mecha_plankton_boss"
	
	if not is_infinity_mode:
		enemy_pool = stage_info.get("enemies", ["jellyfish_pink", "jellyfish_blue", "robot_worker", "robot_enforcer"])
		boss_type = str(stage_info.get("boss", "mecha_plankton_boss"))
	else:
		if active_theme == "krusty_interior":
			enemy_pool = ["robot_worker", "robot_enforcer", "chum_crawler", "patty_thief", "anchovy_swarmer"]
			boss_type = "doodle_bob_boss"
		elif active_theme == "squidward_interior":
			enemy_pool = ["robot_enforcer", "bubble_popper", "jelly_overlord", "chum_crawler", "anchovy_swarmer"]
			boss_type = "squidward_statue_boss"
		else:
			enemy_pool = ["jellyfish_pink", "jellyfish_blue", "robot_worker", "robot_enforcer"]
			boss_type = "mecha_plankton_boss"
	
	var total_count = 6 + wave * 4
	if not is_infinity_mode:
		var st_id: int = int(stage_info.get("id", stage_info.get("stage_id", 1)))
		total_count = 6 + st_id * 2 + wave * 3
		
	total_enemies_pending_spawn += total_count
	enemies_remaining_to_spawn = total_enemies_pending_spawn
	active_enemies_count = total_enemies_pending_spawn
	
	for i in range(total_count):
		if is_game_over_triggered or not is_inside_tree():
			return
			
		var e_candidate: String = enemy_pool[0]
		if not is_infinity_mode and wave == max_waves and i == total_count - 1:
			e_candidate = boss_type
		elif is_infinity_mode and wave % 5 == 0 and i == total_count - 1:
			e_candidate = boss_type
		elif enemy_pool.size() > 1:
			var ratio = float(i) / float(total_count)
			var wave_ratio = float(wave) / float(max_waves)
			var combined = (ratio + wave_ratio) * 0.5
			var p_idx = clampi(int(combined * enemy_pool.size()), 0, enemy_pool.size() - 1)
			e_candidate = enemy_pool[p_idx]
			
		var e_stat: Dictionary = GameData.ENEMIES.get(e_candidate, {})
		var e_spd: float = float(e_stat.get("speed", 4.0))
		var spawn_gap: float = 1.85 + (0.55 if e_spd >= 5.0 else 0.0)
		
		# If user skipped to a newer wave, spawn remaining bots faster so waves flow smoothly
		if wave < current_wave:
			spawn_gap *= 0.65
			
		await get_tree().create_timer(spawn_gap / maxf(0.5, game_speed)).timeout
		if not is_inside_tree() or is_game_over_triggered:
			return
		
		var hp_mult = 1.0 + (wave - 1) * 0.22
		if not is_infinity_mode:
			hp_mult += (int(stage_info.get("id", 1)) - 1) * 0.16
			
		var enemy_type = e_candidate
		if not is_infinity_mode and wave == max_waves and i == total_count - 1:
			hp_mult *= 1.8
		elif is_infinity_mode and wave % 5 == 0 and i == total_count - 1:
			hp_mult *= 1.5
			
		_spawn_single_enemy(enemy_type, hp_mult)
		total_enemies_pending_spawn = maxi(0, total_enemies_pending_spawn - 1)
		enemies_remaining_to_spawn = total_enemies_pending_spawn
		
		# When the penultimate enemy bot spawns for this wave, start 10s auto-skip countdown!
		var trigger_index = maxi(0, total_count - 2)
		if i == trigger_index:
			# Only trigger countdown if this is still the active current wave and there is a next wave
			if wave == current_wave and (is_infinity_mode or wave < max_waves):
				_start_next_wave_countdown(10.0)

func _spawn_single_enemy(enemy_id: String, hp_mult: float) -> void:
	if not path_node:
		return
		
	var path_follow = PathFollow3D.new()
	path_follow.loop = false
	path_follow.rotation_mode = PathFollow3D.ROTATION_Y
	path_node.add_child(path_follow)
	
	var enemy = enemy_scene.instantiate()
	path_follow.add_child(enemy)
	enemy.setup(enemy_id, hp_mult)
	
	enemy.enemy_defeated.connect(_on_enemy_defeated)
	enemy.enemy_escaped.connect(_on_enemy_escaped)

func _on_enemy_defeated(reward: int, enemy_node) -> void:
	cash += reward
	killed_bots_total += 1
	var e_id := "jellyfish_pink"
	if is_instance_valid(enemy_node) and "enemy_id" in enemy_node:
		e_id = str(enemy_node.get("enemy_id"))
	killed_bots_by_type[e_id] = int(killed_bots_by_type.get(e_id, 0)) + 1
	emit_signal("cash_changed", cash)
	emit_signal("enemy_killed_updated", killed_bots_total)
	if AudioManager:
		AudioManager.play_sfx("enemy_death")
		AudioManager.play_sfx("coins", 0.08, -3.0)
	_check_wave_completion()

func _on_enemy_escaped(damage: int, _enemy_node) -> void:
	base_hp = maxi(0, base_hp - damage)
	emit_signal("base_hp_changed", base_hp, MAX_BASE_HP)
	if AudioManager:
		AudioManager.play_sfx("base_damage")
	
	if base_hp <= 0:
		_trigger_game_over(false)
	else:
		_check_wave_completion()

func _check_wave_completion() -> void:
	if is_game_over_triggered:
		return
	if total_enemies_pending_spawn <= 0 and get_living_enemies_count() == 0 and wave_in_progress:
		_finish_wave()

func _award_wave_income(wave_num: int) -> void:
	if wave_num <= 0 or wave_num <= last_awarded_wave:
		return
	last_awarded_wave = wave_num
	
	var end_bonus = 100 + wave_num * 25
	var total_economy_payout = 0
	
	for tower in towers_container.get_children():
		if not is_instance_valid(tower):
			continue
		if tower.has_method("get_wave_income") and tower.get("power_class") == "economy":
			var inc = tower.get_wave_income()
			total_economy_payout += inc
			if tower.has_method("play_wave_end_cash_fountain"):
				tower.play_wave_end_cash_fountain(inc)
		elif "tower_id" in tower:
			var data = GameData.TOWERS.get(tower.tower_id, {})
			var base_inc = int(data.get("income_per_wave", 0))
			if base_inc > 0:
				var inc_bonus = base_inc + tower.current_upgrade_level * 120
				total_economy_payout += inc_bonus
				if tower.has_method("play_wave_end_cash_fountain"):
					tower.play_wave_end_cash_fountain(inc_bonus)
			
	cash += end_bonus + total_economy_payout
	emit_signal("cash_changed", cash)
	emit_signal("wave_completed", wave_num)
	
	if is_infinity_mode:
		PlayerData.highest_infinity_wave = maxi(PlayerData.highest_infinity_wave, wave_num)
		PlayerData.highest_infinity_kills = maxi(PlayerData.highest_infinity_kills, killed_bots_total)
		var inf_map = str(PlayerData.selected_infinity_map)
		if inf_map == "": inf_map = "outskirts"
		var prev_mw = int(PlayerData.highest_infinity_waves_by_map.get(inf_map, 0))
		PlayerData.highest_infinity_waves_by_map[inf_map] = maxi(prev_mw, wave_num)
		PlayerData.save_game()
	else:
		PlayerData.add_gold(40 + wave_num * 15)
		PlayerData.add_xp(60 + wave_num * 20)

func _finish_wave() -> void:
	if is_game_over_triggered:
		return
		
	_award_wave_income(current_wave)
	
	if not is_infinity_mode and current_wave >= max_waves:
		cancel_wave_countdown()
		wave_in_progress = false
		_trigger_game_over(true)
		return
		
	# If there are more waves, ensure countdown to next wave is running!
	if not is_wave_countdown_active and (is_infinity_mode or current_wave < max_waves):
		_start_next_wave_countdown(10.0)

func _calculate_and_grant_infinity_kill_rewards() -> Dictionary:
	var pink_k: int = int(killed_bots_by_type.get("jellyfish_pink", 0))
	var blue_k: int = int(killed_bots_by_type.get("jellyfish_blue", 0))
	var worker_k: int = int(killed_bots_by_type.get("robot_worker", 0))
	var enforcer_k: int = int(killed_bots_by_type.get("robot_enforcer", 0))
	var boss_k: int = int(killed_bots_by_type.get("mecha_plankton_boss", 0))
	
	var base_gold: int = pink_k * 15 + blue_k * 25 + worker_k * 40 + enforcer_k * 65 + boss_k * 200
	var base_gems: int = int(pink_k * 0.2 + blue_k * 0.4 + worker_k * 0.8 + enforcer_k * 1.5 + boss_k * 6)
	var base_xp: int = pink_k * 18 + blue_k * 28 + worker_k * 45 + enforcer_k * 70 + boss_k * 180
	
	for k in killed_bots_by_type.keys():
		if k not in ["jellyfish_pink", "jellyfish_blue", "robot_worker", "robot_enforcer", "mecha_plankton_boss"]:
			var count: int = int(killed_bots_by_type[k])
			if count > 0:
				var edata: Dictionary = GameData.ENEMIES.get(k, {})
				var is_b: bool = bool(edata.get("is_boss", false))
				base_gold += count * (250 if is_b else 50)
				base_gems += count * (8 if is_b else 1)
				base_xp += count * (220 if is_b else 60)
				if is_b:
					boss_k += count
	
	var mult: float = 1.0
	var inf_map := str(PlayerData.selected_infinity_map)
	if inf_map == "krusty_interior":
		mult = 1.5
	elif inf_map == "squidward_interior":
		mult = 2.0
		
	var gold_earned: int = int(base_gold * mult)
	var gems_earned: int = int(base_gems * mult)
	var xp_earned: int = int(base_xp * mult)
	
	var dice_earned: int = 0
	if killed_bots_total > 0:
		dice_earned = maxi(1, int(killed_bots_total / 4) + boss_k * 2)
		
	var bonus_unit_name: String = ""
	if killed_bots_total >= 8 or boss_k >= 1:
		var bonus_pool: Array[String] = ["larry", "flying_dutchman", "king_neptune", "man_ray", "dirty_bubble", "sandy"]
		var pick_tid: String = bonus_pool[killed_bots_total % bonus_pool.size()]
		PlayerData.add_tower(pick_tid, "surge_3")
		bonus_unit_name = str(GameData.TOWERS.get(pick_tid, {}).get("name", pick_tid))
		
	if gold_earned > 0:
		PlayerData.add_gold(gold_earned)
	if gems_earned > 0:
		PlayerData.add_gems(gems_earned)
	if dice_earned > 0:
		PlayerData.add_rerolls(dice_earned)
	if xp_earned > 0:
		PlayerData.add_xp(xp_earned)
		
	PlayerData.highest_infinity_wave = maxi(PlayerData.highest_infinity_wave, current_wave)
	PlayerData.highest_infinity_kills = maxi(PlayerData.highest_infinity_kills, killed_bots_total)
	var cur_map = str(PlayerData.selected_infinity_map)
	if cur_map == "": cur_map = "outskirts"
	var prev_m_wave = int(PlayerData.highest_infinity_waves_by_map.get(cur_map, 0))
	PlayerData.highest_infinity_waves_by_map[cur_map] = maxi(prev_m_wave, current_wave)
	PlayerData.save_game()
	
	last_infinity_rewards = {
		"total_kills": killed_bots_total,
		"wave_reached": current_wave,
		"gold": gold_earned,
		"gems": gems_earned,
		"dice": dice_earned,
		"xp": xp_earned,
		"bonus_unit": bonus_unit_name,
		"by_type": killed_bots_by_type.duplicate()
	}
	return last_infinity_rewards

func _trigger_game_over(victory: bool) -> void:
	cancel_wave_countdown()
	if is_game_over_triggered:
		return
	is_game_over_triggered = true
	wave_in_progress = false
	if is_infinity_mode and not victory:
		_calculate_and_grant_infinity_kill_rewards()
	elif victory and not is_infinity_mode:
		var stage_id: int = PlayerData.selected_stage_id
		var stage_info: Dictionary = GameData.get_stage(stage_id)
		var stars: int = 1
		if base_hp >= MAX_BASE_HP:
			stars = 3
		elif base_hp >= 50:
			stars = 2
		PlayerData.record_stage_clear(stage_id, stars)
		
		var rew_gold: int = int(stage_info.get("gold_reward", stage_info.get("reward_gold", 200)))
		var rew_gems: int = int(stage_info.get("gems_reward", stage_info.get("reward_gems", 10)))
		PlayerData.add_gold(rew_gold)
		PlayerData.add_gems(rew_gems)
		PlayerData.add_xp(150 + stage_id * 30)
		PlayerData.add_rerolls(1)
	if AudioManager:
		AudioManager.stop_bgm(0.2)
		if victory:
			AudioManager.play_fanfare("victory")
		else:
			AudioManager.play_fanfare("defeat")
	emit_signal("game_over", victory)

func set_selected_tower_to_place(t_id: String) -> void:
	selected_tower_to_place = t_id
	if selected_active_tower:
		selected_active_tower.set_selected_visual(false)
		selected_active_tower = null
	_update_placement_preview_visuals()
	if hud and hud.has_method("_update_placement_cards_affordability"):
		hud._update_placement_cards_affordability()

func _update_placement_preview_visuals() -> void:
	if not placement_preview:
		return
	if selected_tower_to_place == "":
		placement_preview.visible = false
		return
	var data = GameData.TOWERS.get(selected_tower_to_place, {})
	var cost = data.get("cost", 100)
	var p_unit = _find_player_unit(selected_tower_to_place)
	var trait_id = p_unit.get("trait_id", "none")
	var rng = data.get("base_range", 8.0)
	
	if preview_dome:
		preview_dome.setup(rng, selected_tower_to_place, trait_id)
		preview_dome.animate_show(false)
	if preview_cost_label:
		if cash >= cost:
			preview_cost_label.text = "✓ %s  •  [ 💵 $%d ]" % [data.get("name", selected_tower_to_place), cost]
			preview_cost_label.modulate = Color(0.35, 1.0, 0.55)
		else:
			preview_cost_label.text = "❌ %s  •  [ 🔒 Need $%d ]" % [data.get("name", selected_tower_to_place), cost]
			preview_cost_label.modulate = Color(1.0, 0.40, 0.40)

func select_tower(tower: Node3D) -> void:
	if selected_active_tower:
		selected_active_tower.set_selected_visual(false)
		
	selected_active_tower = tower
	if selected_active_tower:
		selected_active_tower.set_selected_visual(true)

func check_placement_validity(pos3d: Vector3, tower_id_to_check: String = "") -> Dictionary:
	var tid: String = tower_id_to_check if tower_id_to_check != "" else selected_tower_to_place
	if tid == "":
		return {"valid": false, "reason": "no_selection", "message": ""}
		
	# 1. Bounds check (Battlefield perimeter)
	if absf(pos3d.x) > 16.5 or absf(pos3d.z) > 9.5:
		return {
			"valid": false,
			"reason": "out_of_bounds",
			"message": "🚫 Location is outside battlefield bounds!"
		}
		
	# 2. Path distance check (Prevent placing on enemy paths)
	if path_node and path_node.curve:
		var closest_pt: Vector3 = path_node.curve.get_closest_point(pos3d)
		var dist_to_path: float = Vector2(pos3d.x, pos3d.z).distance_to(Vector2(closest_pt.x, closest_pt.z))
		if dist_to_path < MIN_PATH_DISTANCE:
			return {
				"valid": false,
				"reason": "on_path",
				"message": "🚫 Cannot place unit on enemy path!",
				"distance": dist_to_path
			}
			
		# Check Portal and Base endpoints
		var b_pts: PackedVector3Array = path_node.curve.get_baked_points()
		if b_pts.size() > 0:
			var portal_pos: Vector3 = b_pts[0]
			var base_pos: Vector3 = b_pts[b_pts.size() - 1]
			if Vector2(pos3d.x, pos3d.z).distance_to(Vector2(portal_pos.x, portal_pos.z)) < 2.4:
				return {
					"valid": false,
					"reason": "on_portal",
					"message": "🚫 Cannot place unit inside enemy portal!"
				}
			if Vector2(pos3d.x, pos3d.z).distance_to(Vector2(base_pos.x, base_pos.z)) < 2.4:
				return {
					"valid": false,
					"reason": "on_base",
					"message": "🚫 Cannot place unit inside base!"
				}
				
	# 3. Unit overlap check (Prevent placing bots on top of each other)
	for existing_tower in towers_container.get_children():
		if not is_instance_valid(existing_tower) or existing_tower.is_queued_for_deletion():
			continue
		var t_pos: Vector3 = existing_tower.global_position
		var dist_bot: float = Vector2(pos3d.x, pos3d.z).distance_to(Vector2(t_pos.x, t_pos.z))
		if dist_bot < MIN_TOWER_DISTANCE:
			return {
				"valid": false,
				"reason": "overlapping_unit",
				"message": "🚫 Cannot stack units on top of each other!",
				"distance": dist_bot
			}
			
	# 4. Scenery obstacles check (Krusty Krab & Squidward interiors)
	var theme_id = _get_active_theme_id()
	if theme_id == "krusty_interior":
		var tables: Array[Vector3] = [
			Vector3(-1.0, 0.0, 0.5), # Cashier boat
			Vector3(-9.0, 0.0, -1.8),
			Vector3(-2.0, 0.0, -2.0),
			Vector3(6.5, 0.0, -4.5),
			Vector3(9.0, 0.0, 1.0),
			Vector3(-10.0, 0.0, 4.0)
		]
		for tb in tables:
			if Vector2(pos3d.x, pos3d.z).distance_to(Vector2(tb.x, tb.z)) < 1.35:
				return {
					"valid": false,
					"reason": "on_scenery",
					"message": "🚫 Location blocked by furniture!"
				}
				
	# 5. Affordability check
	var data: Dictionary = GameData.TOWERS.get(tid, {})
	var cost: int = int(data.get("cost", 100))
	if cash < cost:
		return {
			"valid": false,
			"reason": "cant_afford",
			"message": "🔒 Not enough cash to deploy this unit!"
		}
		
	# 6. Placement limit check
	var count: int = 0
	for t in towers_container.get_children():
		if is_instance_valid(t) and t.tower_id == tid:
			count += 1
	var max_limit: int = int(data.get("placement_limit", 4))
	if count >= max_limit:
		return {
			"valid": false,
			"reason": "limit_reached",
			"message": "🚫 Reached placement limit for this unit (%d)!" % max_limit
		}
		
	return {
		"valid": true,
		"reason": "ok",
		"message": "✓ %s  •  [ 💵 $%d ]" % [data.get("name", tid), cost]
	}

func _trigger_placement_denied(msg: String, _denied_pos: Vector3) -> void:
	if hud and hud.has_method("show_placement_warning"):
		hud.show_placement_warning(msg)
	if AudioManager:
		AudioManager.play_sfx("base_damage")
	if placement_preview and is_instance_valid(placement_preview):
		var tw = create_tween()
		var orig_x = placement_preview.position.x
		tw.tween_property(placement_preview, "position:x", orig_x + 0.18, 0.04)
		tw.tween_property(placement_preview, "position:x", orig_x - 0.18, 0.08)
		tw.tween_property(placement_preview, "position:x", orig_x, 0.04)

func place_tower(world_pos: Variant) -> bool:
	if selected_tower_to_place == "":
		return false
		
	var pos3d: Vector3 = Vector3.ZERO
	if world_pos is Vector3:
		pos3d = world_pos
	elif world_pos is Vector2:
		pos3d = Vector3((world_pos.x - 640.0) / 45.0, 0.0, (world_pos.y - 360.0) / 45.0)
		
	var chk: Dictionary = check_placement_validity(pos3d, selected_tower_to_place)
	if not chk.get("valid", false):
		var warn_msg: String = str(chk.get("message", "🚫 Cannot place unit here!"))
		_trigger_placement_denied(warn_msg, pos3d)
		return false
		
	var data = GameData.TOWERS.get(selected_tower_to_place, {})
	var cost = data.get("cost", 100)
	
	cash -= cost
	emit_signal("cash_changed", cash)
	
	var new_tower = tower_scene.instantiate()
	towers_container.add_child(new_tower)
	new_tower.global_position = Vector3(pos3d.x, 0.0, pos3d.z)
	
	var p_unit = _find_player_unit(selected_tower_to_place)
	var lvl = p_unit.get("level", 1)
	var trait_id = p_unit.get("trait_id", "none")
	
	new_tower.setup(selected_tower_to_place, lvl, trait_id)
	new_tower.tower_selected.connect(select_tower)
	
	select_tower(new_tower)
	selected_tower_to_place = ""
	_update_placement_preview_visuals()
	if hud and hud.has_method("_update_placement_cards_affordability"):
		hud._update_placement_cards_affordability()
	if AudioManager:
		AudioManager.play_sfx("tower_place")
	return true

func _find_player_unit(t_id: String) -> Dictionary:
	for item in PlayerData.inventory:
		if item["tower_id"] == t_id:
			return item
	return {}

func upgrade_selected_tower() -> bool:
	if not selected_active_tower:
		return false
	var cost = selected_active_tower.get_next_upgrade_cost()
	if cost > 0 and cash >= cost:
		cash -= cost
		emit_signal("cash_changed", cash)
		selected_active_tower.upgrade()
		if AudioManager:
			AudioManager.play_sfx("tower_upgrade")
		return true
	return false

func sell_selected_tower() -> void:
	if not selected_active_tower:
		return
	var value = selected_active_tower.get_sell_value()
	cash += value
	emit_signal("cash_changed", cash)
	if AudioManager:
		AudioManager.play_sfx("tower_sell")
	selected_active_tower.queue_free()
	selected_active_tower = null

func set_game_speed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = speed

func return_to_lobby() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
