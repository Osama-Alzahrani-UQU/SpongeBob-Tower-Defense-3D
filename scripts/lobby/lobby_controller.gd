extends Node3D

## LobbyController 3D - Bikini Bottom 3D Open Hub with Screen-Bounded Responsive UI

@onready var top_bar: Panel = $HUD/TopBar
@onready var top_hbox: HBoxContainer = $HUD/TopBar/HBox
@onready var level_label: Label = $HUD/TopBar/HBox/LevelLabel
@onready var xp_bar: ProgressBar = $HUD/TopBar/HBox/XPBar
@onready var gold_label: Label = $HUD/TopBar/HBox/GoldLabel
@onready var gems_label: Label = $HUD/TopBar/HBox/GemsLabel
@onready var dice_label: Label = $HUD/TopBar/HBox/DiceLabel

# Modals
@onready var summon_modal: Panel = $HUD/SummonModal
@onready var inventory_modal: Panel = $HUD/InventoryModal
@onready var lab_modal: Panel = $HUD/LabModal
@onready var trade_modal: Panel = $HUD/TradeModal
@onready var afk_modal: Panel = $HUD/AFKModal
@onready var settings_modal: Panel = $HUD/SettingsModal
@onready var leaderboards_modal: Panel = $HUD/LeaderboardModal
var stage_select_modal: Panel = null
var infinity_select_modal: Panel = null
var credits_modal: Panel = null
var credits_btn: Button = null
var is_transitioning: bool = false

@onready var camera_3d: Camera3D = $Camera3D
@onready var landmarks_3d: Node3D = $Landmarks3D

signal teleport_started(pad_id: String)
signal teleport_finished(pad_id: String)

var modal_backdrop: ColorRect = null
var bottom_hint: Panel = null
var player_avatar: Node3D = null
var player_walk_anim: float = 0.0
var landmark_zones: Array = []
var cylinder_pads: Array = []
var building_barriers: Array = []
var standing_pad_id: String = ""
var pad_trigger_cooldown: float = 0.0
var animated_decorations: Array = []

var is_teleporting: bool = false
var teleport_time_scale: float = 1.0
var active_teleport_tween: Tween = null
var teleport_vfx_container: Node3D = null
var _teleport_start_pos: Vector3 = Vector3.ZERO
var _teleport_target_pos: Vector3 = Vector3.ZERO
var _teleport_bldg_pos: Vector3 = Vector3.ZERO
var _teleport_pad_color: Color = Color(0.3, 0.9, 1.0)
var _teleport_start_yaw: float = 0.0
var _teleport_target_yaw: float = 0.0
var _teleport_arc_height: float = 4.2
var _teleport_last_trail_t: float = 0.0
var _teleport_cam_start_pos: Vector3 = Vector3.ZERO
var _teleport_cam_target_pos: Vector3 = Vector3.ZERO

# AFK Accumulator (Backed by PlayerData global continuous engine)
var afk_time: float:
	get: return PlayerData.afk_tick_timer
	set(v): PlayerData.afk_tick_timer = v
var accumulated_gold: int:
	get: return PlayerData.afk_accumulated_gold
	set(v): PlayerData.afk_accumulated_gold = v
var accumulated_gems: int:
	get: return PlayerData.afk_accumulated_gems
	set(v): PlayerData.afk_accumulated_gems = v

func _ready() -> void:
	if AudioManager:
		AudioManager.play_bgm("lobby")
	PlayerData.currencies_changed.connect(_update_currency_display)
	PlayerData.level_up.connect(_on_level_up)
	_setup_modern_hud_theme()
	_update_currency_display()
	_close_all_modals()
	_wire_buttons()
	_build_3d_bikini_bottom()

func _setup_modern_hud_theme() -> void:
	UIThemeBuilder.enforce_ltr_recursive($HUD)
	
	# Darkened backdrop behind modals (add to tree BEFORE place_rect so parent size is 1280x720)
	modal_backdrop = ColorRect.new()
	modal_backdrop.color = Color(0.01, 0.04, 0.09, 0.72)
	modal_backdrop.visible = false
	$HUD.add_child(modal_backdrop)
	$HUD.move_child(modal_backdrop, 0)
	UIThemeBuilder.place_rect(modal_backdrop, 0.0, 0.0, 1280.0, 720.0)
	modal_backdrop.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_all_modals()
	)
	
	# Stage Selection Modal (Campaign Expedition Levels 1 to 15 Across 3 Zones)
	var stage_modal_script = load("res://scripts/ui/stage_select_modal.gd")
	stage_select_modal = Panel.new()
	stage_select_modal.name = "StageSelectModal"
	stage_select_modal.visible = false
	stage_select_modal.set_script(stage_modal_script)
	$HUD.add_child(stage_select_modal)
	stage_select_modal.stage_chosen.connect(_launch_stage_entrance_animation)
	
	# Infinity Map Selection Modal (Endless Waves Across 3 Undersea Themed Maps)
	var inf_modal_script = load("res://scripts/ui/infinity_select_modal.gd")
	infinity_select_modal = Panel.new()
	infinity_select_modal.name = "InfinitySelectModal"
	infinity_select_modal.visible = false
	infinity_select_modal.set_script(inf_modal_script)
	$HUD.add_child(infinity_select_modal)
	infinity_select_modal.map_chosen.connect(_launch_infinity_entrance_animation)
	
	# Official Credits & Ownership Modal
	var credits_script = load("res://scripts/ui/credits_modal.gd")
	credits_modal = Panel.new()
	credits_modal.name = "CreditsModal"
	credits_modal.visible = false
	credits_modal.set_script(credits_script)
	$HUD.add_child(credits_modal)
	
	# TopBar Floating Glass Header (strictly inside screen margins: x=16..1264, y=10..60)
	var top_sb = UIThemeBuilder.make_panel_style(
		Color(0.04, 0.12, 0.22, 0.96),
		Color(0.25, 0.78, 1.0, 0.98),
		18, 2, 0, 12, 6
	)
	top_bar.clip_contents = false
	top_bar.add_theme_stylebox_override("panel", top_sb)
	UIThemeBuilder.place_rect(top_bar, 16.0, 10.0, 1248.0, 50.0)
	UIThemeBuilder.fit_inner_container(top_bar, top_hbox, 12.0, 4.0)
	top_hbox.add_theme_constant_override("separation", 8)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Compact Currency Labels & XP Bar so everything fits with generous margins
	UIThemeBuilder.style_label(level_label, 14, Color(0.35, 0.92, 1.0), 3)
	UIThemeBuilder.style_label(gold_label, 13, Color(1.0, 0.85, 0.22), 3)
	UIThemeBuilder.style_label(gems_label, 13, Color(0.82, 0.48, 1.0), 3)
	UIThemeBuilder.style_label(dice_label, 13, Color(0.30, 0.96, 0.58), 3)
	UIThemeBuilder.style_progress_bar(xp_bar, Color(0.22, 0.85, 1.0))
	xp_bar.custom_minimum_size = Vector2(72, 14)
	
	# Compact & Balanced TopBar Navigation Buttons
	var inv_btn: Button = $HUD/TopBar/HBox/InvBtn
	var sum_btn: Button = $HUD/TopBar/HBox/SummonBtn
	var lab_btn: Button = $HUD/TopBar/HBox/LabBtn
	var trd_btn: Button = $HUD/TopBar/HBox/TradeBtn
	var set_btn: Button = $HUD/TopBar/HBox/SettingsBtn
	var bat_btn: Button = $HUD/TopBar/HBox/BattleBtn
	
	if not top_hbox.has_node("CreditsBtn"):
		credits_btn = Button.new()
		credits_btn.name = "CreditsBtn"
		top_hbox.add_child(credits_btn)
		top_hbox.move_child(credits_btn, bat_btn.get_index())
	else:
		credits_btn = top_hbox.get_node("CreditsBtn")
	
	inv_btn.text = "🎒 Units"
	sum_btn.text = "🐚 Summon"
	lab_btn.text = "🧪 Lab"
	trd_btn.text = "👻 Trade"
	set_btn.text = "⚙️ Codes"
	credits_btn.text = "👑 Credits"
	bat_btn.text = "⚔️ PLAY BATTLE"
	
	for b in [inv_btn, sum_btn, lab_btn, trd_btn, set_btn, credits_btn]:
		b.custom_minimum_size = Vector2(78, 34)
	bat_btn.custom_minimum_size = Vector2(120, 36)
	
	UIThemeBuilder.style_button(inv_btn, "nav", 12)
	UIThemeBuilder.style_button(sum_btn, "magic", 12)
	UIThemeBuilder.style_button(lab_btn, "success", 12)
	UIThemeBuilder.style_button(trd_btn, "nav", 12)
	UIThemeBuilder.style_button(set_btn, "primary", 12)
	UIThemeBuilder.style_button(credits_btn, "gold", 12)
	UIThemeBuilder.bind_button_anim(credits_btn)
	UIThemeBuilder.style_button(bat_btn, "action", 13)
	
	# Style & Bound Leaderboards Modal
	UIThemeBuilder.style_modal(leaderboards_modal, Color(1.0, 0.84, 0.22), Vector2(540, 340))
	UIThemeBuilder.style_label($HUD/LeaderboardModal/VBox/Title, 20, Color(1.0, 0.86, 0.22), 4)
	UIThemeBuilder.style_label($HUD/LeaderboardModal/VBox/Scores, 15, Color(0.9, 0.96, 1.0), 3)
	$HUD/LeaderboardModal/VBox/Scores.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$HUD/LeaderboardModal/VBox/Scores.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$HUD/LeaderboardModal/VBox/Scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_button($HUD/LeaderboardModal/VBox/CloseBtn, "danger", 13)
	$HUD/LeaderboardModal/VBox/CloseBtn.text = "✖ Close"
	
	# Sleek Centered Bottom Status Pill (centered horizontally at x=250..1030, y=674..710)
	bottom_hint = Panel.new()
	bottom_hint.clip_contents = true
	bottom_hint.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_pill_style(Color(0.04, 0.12, 0.22, 0.94), Color(0.25, 0.78, 0.98, 0.95), 18)
	)
	$HUD.add_child(bottom_hint)
	$HUD.move_child(bottom_hint, 1)
	UIThemeBuilder.place_rect(bottom_hint, 250.0, 674.0, 780.0, 36.0)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "🌊 BIKINI BOTTOM 3D HUB   •   [WASD / Arrows] Walk   •   [Step Inside Cylinder] Open Menu"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(hint_lbl, 12, Color(0.88, 0.96, 1.0), 3)
	bottom_hint.add_child(hint_lbl)
	UIThemeBuilder.fit_inner_container(bottom_hint, hint_lbl, 20.0, 2.0)

func _wire_buttons() -> void:
	$HUD/TopBar/HBox/InvBtn.pressed.connect(func(): teleport_to_pad_and_open("Pineapple"))
	$HUD/TopBar/HBox/SummonBtn.pressed.connect(func(): teleport_to_pad_and_open("SummonAltar"))
	$HUD/TopBar/HBox/LabBtn.pressed.connect(func(): teleport_to_pad_and_open("PlanktonLab"))
	$HUD/TopBar/HBox/TradeBtn.pressed.connect(func(): teleport_to_pad_and_open("FlyingDutchman"))
	$HUD/TopBar/HBox/SettingsBtn.pressed.connect(func(): teleport_to_pad_and_open("Moai"))
	if credits_btn:
		credits_btn.pressed.connect(open_credits_menu)
	$HUD/TopBar/HBox/BattleBtn.pressed.connect(func(): teleport_to_pad_and_open("KrustyKrab"))
	$HUD/LeaderboardModal/VBox/CloseBtn.pressed.connect(_close_all_modals)

func teleport_to_pad_and_open(pad_id: String) -> void:
	var pad: Dictionary = _get_pad_by_id(pad_id)
	if pad.is_empty():
		return
	_close_all_modals()
	if active_teleport_tween and active_teleport_tween.is_valid():
		active_teleport_tween.kill()
	if not teleport_vfx_container or not is_instance_valid(teleport_vfx_container):
		teleport_vfx_container = Node3D.new()
		teleport_vfx_container.name = "TeleportVFXContainer"
		add_child(teleport_vfx_container)

	standing_pad_id = pad_id
	pad_trigger_cooldown = 2.5
	is_teleporting = true
	emit_signal("teleport_started", pad_id)

	var target_pos: Vector3 = pad["pos"]
	var bldg_pos: Vector3 = pad["bldg_pos"]
	var pad_col: Color = pad.get("color", Color(0.3, 0.9, 1.0))
	_teleport_pad_color = pad_col
	_teleport_target_pos = target_pos
	_teleport_bldg_pos = bldg_pos

	if player_avatar:
		_teleport_start_pos = Vector3(player_avatar.position.x, 0.0, player_avatar.position.z)
		_teleport_start_yaw = player_avatar.rotation.y
		var to_bldg: Vector3 = bldg_pos - target_pos
		_teleport_target_yaw = atan2(to_bldg.x, to_bldg.z) if Vector2(to_bldg.x, to_bldg.z).length() > 0.1 else 0.0
		var flat_dist: float = Vector2(_teleport_start_pos.x, _teleport_start_pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
		_teleport_arc_height = clampf(flat_dist * 0.24, 3.2, 6.8)
		_teleport_last_trail_t = -0.2
		player_walk_anim = 0.0

	if camera_3d:
		_teleport_cam_start_pos = camera_3d.position
		_teleport_cam_target_pos = Vector3(target_pos.x * 0.45, 14.5, target_pos.z * 0.45 + 19.5)

	# 1. Spawn Departure 3D Bubble Vortex & Golden Shockwave Rings at Start Position
	_spawn_teleport_vfx_burst(_teleport_start_pos, pad_col, false)
	if AudioManager:
		AudioManager.play_sfx("teleport", 0.04, -2.0)

	var ts: float = maxf(0.02, teleport_time_scale)
	active_teleport_tween = create_tween()

	# Phase 1: Energetic Cartoon Squash & Stretch Launch Wind-Up
	if player_avatar:
		active_teleport_tween.tween_property(player_avatar, "scale", Vector3(1.50, 0.88, 1.50), 0.05 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		active_teleport_tween.tween_property(player_avatar, "scale", Vector3(0.96, 1.54, 0.96), 0.05 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Phase 2: Parabolic 3D Sky-Arc + 360 Hero Spin + Bubble/Starlight Trail + Smooth Camera Glide
	active_teleport_tween.tween_method(_update_teleport_arc, 0.0, 1.0, 0.42 * ts).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Phase 3: Touchdown on Cylinder Pad + Arrival Neon Shockwave + Pad Beacon Flash + Landing Rebound
	active_teleport_tween.tween_callback(func():
		if player_avatar:
			player_avatar.position = _teleport_target_pos
			player_avatar.rotation = Vector3(0.0, _teleport_target_yaw, 0.0)
			_update_player_limb_swing(0.0)
		if camera_3d and camera_3d.is_inside_tree():
			camera_3d.position = _teleport_cam_target_pos
			camera_3d.fov = 75.0
			camera_3d.look_at(Vector3(_teleport_target_pos.x * 0.25, 1.5, _teleport_target_pos.z * 0.25), Vector3.UP)
		_spawn_teleport_vfx_burst(_teleport_target_pos, pad_col, true)
		_pulse_pad_on_arrival(pad)
	)
	if player_avatar:
		active_teleport_tween.tween_property(player_avatar, "scale", Vector3(1.52, 0.86, 1.52), 0.06 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		active_teleport_tween.tween_property(player_avatar, "scale", Vector3(1.25, 1.25, 1.25), 0.08 * ts).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	active_teleport_tween.tween_callback(func():
		is_teleporting = false
		standing_pad_id = pad_id
		pad_trigger_cooldown = 1.8
		call(pad["action"])
		emit_signal("teleport_finished", pad_id)
	)

func _update_teleport_arc(t: float) -> void:
	if player_avatar:
		var flat_pos: Vector3 = _teleport_start_pos.lerp(_teleport_target_pos, t)
		var y_arc: float = 4.0 * _teleport_arc_height * t * (1.0 - t)
		player_avatar.position = Vector3(flat_pos.x, y_arc, flat_pos.z)
		# Hero 360 spin mid-air that lands facing the building (+Z forward) at t = 1.0
		var base_yaw: float = lerp_angle(_teleport_start_yaw, _teleport_target_yaw, t)
		var spin_offset: float = sin(t * PI) * TAU
		player_avatar.rotation.y = base_yaw + spin_offset
		player_avatar.rotation.x = (0.5 - t) * 0.36 * sin(t * PI)
		var stretch: float = 1.25 + sin(t * PI) * 0.14
		var squeeze: float = 1.25 - sin(t * PI) * 0.08
		player_avatar.scale = Vector3(squeeze, stretch, squeeze)
		# Joyful mid-air jump pose on SpongeBob's arms & legs
		var jump_pose: float = sin(t * PI)
		if player_avatar.has_node("LeftArmPivot"):
			player_avatar.get_node("LeftArmPivot").rotation.x = -1.8 * jump_pose
			player_avatar.get_node("LeftArmPivot").rotation.z = -0.45 * jump_pose
		if player_avatar.has_node("RightArmPivot"):
			player_avatar.get_node("RightArmPivot").rotation.x = -1.2 * jump_pose
			player_avatar.get_node("RightArmPivot").rotation.z = 0.55 * jump_pose
		if player_avatar.has_node("LeftLegPivot"):
			player_avatar.get_node("LeftLegPivot").rotation.x = 0.65 * jump_pose
		if player_avatar.has_node("RightLegPivot"):
			player_avatar.get_node("RightLegPivot").rotation.x = -0.50 * jump_pose
		# Spawn trailing 3D bubbles & starlight rings along the flight arc
		if t - _teleport_last_trail_t >= 0.11 and t < 0.95:
			_teleport_last_trail_t = t
			_spawn_teleport_trail_drop(player_avatar.position + Vector3(0.0, 0.85, 0.0), _teleport_pad_color)

	if camera_3d and camera_3d.is_inside_tree():
		camera_3d.position = _teleport_cam_start_pos.lerp(_teleport_cam_target_pos, t)
		camera_3d.fov = 75.0 - sin(t * PI) * 5.5
		var look_pos: Vector3 = _teleport_start_pos.lerp(_teleport_target_pos, t)
		camera_3d.look_at(Vector3(look_pos.x * 0.25, 1.5 + sin(t * PI) * 0.8, look_pos.z * 0.25), Vector3.UP)

func _spawn_teleport_vfx_burst(center_pos: Vector3, accent_col: Color, is_arrival: bool) -> void:
	if not teleport_vfx_container or not is_instance_valid(teleport_vfx_container):
		return
	var burst_root := Node3D.new()
	burst_root.name = "TeleportBurstVFX"
	burst_root.position = center_pos
	teleport_vfx_container.add_child(burst_root)

	var gold_col := Color(1.0, 0.90, 0.25)
	var ring_mat_1 := ModelBuilder3D.make_mat(accent_col, 0.15, 0.1, accent_col * 1.8, 0.90)
	var ring_mat_2 := ModelBuilder3D.make_mat(gold_col, 0.15, 0.2, gold_col * 1.6, 0.85)
	var beam_mat := ModelBuilder3D.make_mat(accent_col, 0.10, 0.0, accent_col * 1.5, 0.38)
	var bubble_mat := ModelBuilder3D.make_mat(Color(0.82, 0.96, 1.0), 0.08, 0.2, Color(0.45, 0.88, 1.0) * 1.2, 0.72)

	# 1. Dual Expanding Neon Shockwave Torus Rings
	var shock_1 := ModelBuilder3D.add_torus(burst_root, 0.85, 1.15, Vector3(0, 0.16, 0), ring_mat_1)
	shock_1.scale = Vector3(0.25, 1.0, 0.25)
	var shock_2 := ModelBuilder3D.add_torus(burst_root, 0.55, 0.78, Vector3(0, 0.32, 0), ring_mat_2)
	shock_2.scale = Vector3(0.20, 1.0, 0.20)

	# 2. Vertical Holographic Warp Beam Column
	var warp_beam := ModelBuilder3D.add_cylinder(burst_root, 0.95, 1.15, 3.6, Vector3(0, 1.8, 0), beam_mat)
	warp_beam.scale = Vector3(0.35, 0.2, 0.35) if not is_arrival else Vector3(1.15, 1.0, 1.15)

	var ts: float = maxf(0.05, teleport_time_scale)
	var vfx_tw := create_tween().set_parallel(true)
	vfx_tw.tween_property(shock_1, "scale", Vector3(2.35, 1.0, 2.35), 0.42 * ts).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	vfx_tw.tween_property(shock_1, "position:y", 0.55, 0.42 * ts)
	vfx_tw.tween_property(shock_2, "scale", Vector3(2.05, 1.0, 2.05), 0.38 * ts).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	vfx_tw.tween_property(shock_2, "position:y", 1.15, 0.38 * ts)
	vfx_tw.tween_property(warp_beam, "scale", Vector3(1.35, 1.15, 1.35) if not is_arrival else Vector3(0.08, 1.35, 0.08), 0.38 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. 12 Swirling Underwater Bubbles & Golden Starlight Orbs
	for i: int in range(12):
		var ang: float = deg_to_rad(float(i) * 30.0)
		var r_start: float = 0.35 + float(i % 3) * 0.15
		var r_end: float = 1.65 + float(i % 4) * 0.28
		var is_gold: bool = (i % 2 == 0)
		var orb_r: float = 0.14 if is_gold else 0.18
		var orb := ModelBuilder3D.add_sphere(
			burst_root,
			orb_r,
			orb_r * 2.0,
			Vector3(cos(ang) * r_start, 0.25 + float(i % 3) * 0.2, sin(ang) * r_start),
			ring_mat_2 if is_gold else bubble_mat
		)
		var target_orb_pos := Vector3(cos(ang + 0.9) * r_end, 1.85 + float(i % 4) * 0.45, sin(ang + 0.9) * r_end)
		vfx_tw.tween_property(orb, "position", target_orb_pos, 0.42 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		vfx_tw.tween_property(orb, "scale", Vector3(0.05, 0.05, 0.05), 0.42 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var cleanup_tw := create_tween()
	cleanup_tw.tween_interval(0.45 * ts)
	cleanup_tw.tween_callback(func():
		if is_instance_valid(burst_root):
			burst_root.queue_free()
	)

func _spawn_teleport_trail_drop(world_pos: Vector3, accent_col: Color) -> void:
	if not teleport_vfx_container or not is_instance_valid(teleport_vfx_container):
		return
	var trail_node := Node3D.new()
	trail_node.name = "TeleportTrailDrop"
	trail_node.position = world_pos
	teleport_vfx_container.add_child(trail_node)

	var trail_mat := ModelBuilder3D.make_mat(accent_col, 0.12, 0.1, accent_col * 1.6, 0.80)
	var bubble_mat := ModelBuilder3D.make_mat(Color(1.0, 0.92, 0.32), 0.12, 0.2, Color(1.0, 0.85, 0.2) * 1.4, 0.85)
	var ring := ModelBuilder3D.add_torus(trail_node, 0.22, 0.34, Vector3.ZERO, trail_mat)
	var bub := ModelBuilder3D.add_sphere(trail_node, 0.15, 0.30, Vector3(0, 0.15, 0), bubble_mat)

	var ts: float = maxf(0.05, teleport_time_scale)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(1.65, 1.0, 1.65), 0.28 * ts)
	tw.tween_property(bub, "position:y", 0.85, 0.28 * ts)
	tw.tween_property(bub, "scale", Vector3(0.05, 0.05, 0.05), 0.28 * ts)
	var clean_tw := create_tween()
	clean_tw.tween_interval(0.30 * ts)
	clean_tw.tween_callback(func():
		if is_instance_valid(trail_node):
			trail_node.queue_free()
	)

func _pulse_pad_on_arrival(pad: Dictionary) -> void:
	var ts: float = maxf(0.05, teleport_time_scale)
	var beacon: MeshInstance3D = pad.get("beacon_node", null)
	if beacon and is_instance_valid(beacon):
		var b_tw := create_tween()
		b_tw.tween_property(beacon, "scale", Vector3(1.38, 2.25, 1.38), 0.09 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		b_tw.tween_property(beacon, "scale", Vector3(1.0, 1.0, 1.0), 0.16 * ts).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var emblem: Node3D = pad.get("emblem_node", null)
	if emblem and is_instance_valid(emblem):
		var e_tw := create_tween()
		e_tw.tween_property(emblem, "scale", Vector3(1.35, 1.35, 1.35), 0.10 * ts).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		e_tw.tween_property(emblem, "scale", Vector3(1.0, 1.0, 1.0), 0.15 * ts).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_3d_bikini_bottom() -> void:
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.28, 0.48)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.72, 0.92)
	env.ambient_light_energy = 1.3
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.35, 0.54)
	env.fog_density = 0.005
	env_node.environment = env
	add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(0.92, 0.98, 1.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45, 35, 0)
	add_child(sun)
	
	# High-Resolution Textured Seabed Floor with Procedural Sand Ripples & Normal Map
	var floor_mesh = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(88.0, 0.6, 78.0)
	floor_mesh.mesh = f_box
	floor_mesh.position = Vector3(0, -0.3, 0)
	floor_mesh.material_override = ModelBuilder3D.get_seabed_sand_material()
	add_child(floor_mesh)
	
	# High-Detail Comprehensive Road & Pathway Network Connecting ALL Buildings
	_build_lobby_road_network()
	
	# Floating Underwater Bubbles
	var bubble_mat = ModelBuilder3D.make_mat(Color(0.85, 0.95, 1.0), 0.1, 0.2, Color(0.4, 0.8, 1.0), 0.45)
	for i in range(28):
		var b_mesh = MeshInstance3D.new()
		var s = SphereMesh.new()
		var r = randf_range(0.12, 0.35)
		s.radius = r
		s.height = r * 2.0
		b_mesh.mesh = s
		var bx = randf_range(-26.0, 26.0)
		var bz = randf_range(-22.0, 22.0)
		var by = randf_range(0.5, 12.0)
		b_mesh.position = Vector3(bx, by, bz)
		b_mesh.material_override = bubble_mat
		add_child(b_mesh)
		animated_decorations.append({
			"type": "bubble",
			"node": b_mesh,
			"speed": randf_range(0.8, 2.2),
			"base_x": bx,
			"base_z": bz,
			"wobble": randf() * 6.28
		})
	
	# Bikini Bottom Sky Flower Clouds
	var flower_colors = [Color(0.4, 0.7, 0.95, 0.45), Color(0.9, 0.5, 0.7, 0.4), Color(0.5, 0.9, 0.6, 0.4), Color(1.0, 0.75, 0.3, 0.4)]
	for i in range(5):
		var fl_root = Node3D.new()
		var f_col = flower_colors[i % flower_colors.size()]
		var f_mat = ModelBuilder3D.make_mat(f_col, 0.5, 0.0, f_col * 0.4, 0.42)
		for p in range(5):
			var a = p * (360.0 / 5.0)
			var rad = deg_to_rad(a)
			var petal = MeshInstance3D.new()
			var p_sphere = SphereMesh.new()
			p_sphere.radius = 1.3
			p_sphere.height = 0.65
			petal.mesh = p_sphere
			petal.material_override = f_mat
			petal.position = Vector3(sin(rad) * 1.6, 0, cos(rad) * 1.6)
			fl_root.add_child(petal)
		var fx = -28.0 + (i * 14.0)
		var fz = -26.0 - (i % 2) * 5.0
		fl_root.position = Vector3(fx, 16.0 + (i * 1.2), fz)
		fl_root.rotation_degrees = Vector3(40, 15.0 * i, 0)
		add_child(fl_root)
	
	var defs = [
		{
			"id": "KrustyKrab",
			"model_type": "krusty_krab",
			"title": "🍔 THE KRUSTY KRAB",
			"subtitle": "Select Stage (Levels 1-15)",
			"bldg_pos": Vector3(-15.0, 0.0, -22.7),
			"pad_pos": Vector3(-15.0, 0.0, -17.5),
			"bldg_rot": Vector3(0, 0, 0),
			"color": Color(1.0, 0.85, 0.2),
			"action": "open_stage_select_menu",
			"barrier_shape": "box",
			"barrier_center": Vector3(-15.1, 0.0, -22.7),
			"barrier_size": Vector2(8.8, 6.0)
		},
		{
			"id": "PlanktonLab",
			"model_type": "chum_bucket",
			"title": "🧪 CHUM BUCKET LAB",
			"subtitle": "Trait Rerolls & Upgrades",
			"bldg_pos": Vector3(15.0, 0.0, -22.5),
			"pad_pos": Vector3(15.0, 0.0, -17.5),
			"bldg_rot": Vector3(0, 0, 0),
			"color": Color(0.25, 1.0, 0.45),
			"action": "open_lab_menu",
			"barrier_shape": "circle",
			"barrier_center": Vector3(15.0, 0.0, -22.5),
			"barrier_radius": 2.65
		},
		{
			"id": "SummonAltar",
			"model_type": "summon_altar",
			"title": "📦 MYSTIC CRATES KIOSK",
			"subtitle": "Summon Chests & Mythic Bots",
			"bldg_pos": Vector3(0.0, 0.0, -22.8),
			"pad_pos": Vector3(0.0, 0.0, -17.5),
			"bldg_rot": Vector3(0, 0, 0),
			"color": Color(1.0, 0.82, 0.15),
			"action": "open_summon_menu",
			"barrier_shape": "box",
			"barrier_center": Vector3(0.0, 0.0, -22.8),
			"barrier_size": Vector2(6.8, 5.2)
		},
		{
			"id": "Pineapple",
			"model_type": "pineapple",
			"title": "🍍 SPONGEBOB'S HOUSE",
			"subtitle": "Unit Inventory & Loadout",
			"bldg_pos": Vector3(-24.2, 0.0, -5.0),
			"pad_pos": Vector3(-19.2, 0.0, -5.0),
			"bldg_rot": Vector3(0, 90, 0),
			"color": Color(1.0, 0.58, 0.12),
			"action": "open_inventory_menu",
			"barrier_shape": "circle",
			"barrier_center": Vector3(-24.2, 0.0, -5.0),
			"barrier_radius": 2.68
		},
		{
			"id": "Moai",
			"model_type": "moai",
			"title": "🗿 SQUIDWARD'S MOAI",
			"subtitle": "Codes & Audio Settings",
			"bldg_pos": Vector3(-24.2, 0.0, 3.5),
			"pad_pos": Vector3(-19.2, 0.0, 3.5),
			"bldg_rot": Vector3(0, 90, 0),
			"color": Color(0.4, 0.78, 1.0),
			"action": "open_settings_menu",
			"barrier_shape": "circle",
			"barrier_center": Vector3(-24.2, 0.0, 3.5),
			"barrier_radius": 2.45
		},
		{
			"id": "Rock",
			"model_type": "rock",
			"title": "🪨 PATRICK'S ROCK",
			"subtitle": "♾️ INFINITY WAVES MODE",
			"bldg_pos": Vector3(-24.4, 0.0, 12.0),
			"pad_pos": Vector3(-19.2, 0.0, 12.0),
			"bldg_rot": Vector3(0, 90, 0),
			"color": Color(1.0, 0.52, 0.65),
			"action": "enter_infinity_battle",
			"barrier_shape": "circle",
			"barrier_center": Vector3(-24.4, 0.0, 12.0),
			"barrier_radius": 3.02
		},
		{
			"id": "Treedome",
			"model_type": "treedome",
			"title": "🐿️ SANDY'S TREEDOME",
			"subtitle": "AFK Resort (Gold & Gems)",
			"bldg_pos": Vector3(26.8, 0.0, -5.0),
			"pad_pos": Vector3(19.2, 0.0, -5.0),
			"bldg_rot": Vector3(0, -90, 0),
			"color": Color(0.25, 0.92, 0.95),
			"action": "open_afk_menu",
			"barrier_shape": "circle",
			"barrier_center": Vector3(26.25, 0.0, -5.0),
			"barrier_radius": 4.45
		},
		{
			"id": "FlyingDutchman",
			"model_type": "dutchman",
			"title": "👻 DUTCHMAN GHOST SHIP",
			"subtitle": "Spectral Trading Market",
			"bldg_pos": Vector3(26.0, 0.0, 3.5),
			"pad_pos": Vector3(19.2, 0.0, 3.5),
			"bldg_rot": Vector3(0, -65, 0),
			"color": Color(0.2, 1.0, 0.6),
			"action": "open_trading_menu",
			"barrier_shape": "box",
			"barrier_center": Vector3(26.0, 0.0, 3.5),
			"barrier_size": Vector2(7.0, 5.4)
		},
		{
			"id": "Leaderboards",
			"model_type": "leaderboards",
			"title": "🏆 HALL OF FAME",
			"subtitle": "Infinite Mode Ranks",
			"bldg_pos": Vector3(25.2, 0.0, 12.0),
			"pad_pos": Vector3(19.2, 0.0, 12.0),
			"bldg_rot": Vector3(0, -90, 0),
			"color": Color(1.0, 0.9, 0.3),
			"action": "open_leaderboard_menu",
			"barrier_shape": "box",
			"barrier_center": Vector3(25.2, 0.0, 12.0),
			"barrier_size": Vector2(4.2, 4.2)
		}
	]
	
	cylinder_pads.clear()
	landmark_zones.clear()
	building_barriers.clear()
	
	for d in defs:
		# 1. Iconic 3D Building Landmark
		var bldg = ModelBuilder3D.build_landmark_model(d["model_type"])
		bldg.position = d["bldg_pos"]
		bldg.rotation_degrees = d.get("bldg_rot", Vector3.ZERO)
		landmarks_3d.add_child(bldg)
		
		# 2. Impassable Building Perimeter Barrier (Visual Nautical Stone Curb + Bollards & Physical StaticBody3D)
		# Strictly bounded around the building footprint so it NEVER covers or touches the cylinder pad!
		_build_building_barrier(d)
		
		# 3. Interactive Thematic Cylinder Pad in front of the building (Unique 3D architecture, animated props & effects)
		var pad_data: Dictionary = ModelBuilder3D.build_thematic_cylinder_pad(d["id"], d["color"])
		var pad_node: Node3D = pad_data["root"]
		pad_node.position = d["pad_pos"]
		landmarks_3d.add_child(pad_node)
		
		# Floating 3D Billboard Text (High-Visibility, Large Crisp Font, Zero Depth Clipping)
		var lbl = Label3D.new()
		lbl.name = "PadLabel3D"
		lbl.text = "%s\n%s\n▼ [ STEP INSIDE TO OPEN ] ▼" % [d["title"], d["subtitle"]]
		lbl.font = UIThemeBuilder.get_title_font()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.render_priority = 18
		lbl.font_size = 46
		lbl.pixel_size = 0.0056
		lbl.outline_size = 14
		lbl.outline_modulate = Color(0.02, 0.04, 0.08, 0.98)
		lbl.modulate = d["color"]
		lbl.line_spacing = 3.0
		lbl.position = Vector3(0, 1.65, 0)
		pad_node.add_child(lbl)
		
		var pad_info = {
			"id": d["id"],
			"pos": d["pad_pos"],
			"bldg_pos": d["bldg_pos"],
			"action": d["action"],
			"color": d["color"],
			"pad_node": pad_node,
			"ring_node": pad_data["ring_node"],
			"beacon_node": pad_data["beacon_node"],
			"emblem_node": pad_data.get("emblem_node", null),
			"pad_data": pad_data
		}
		cylinder_pads.append(pad_info)
		landmark_zones.append(pad_info)
		
		animated_decorations.append({
			"type": "thematic_pad",
			"pad_data": pad_data,
			"offset": randf() * 6.28
		})
		
	player_avatar = ModelBuilder3D.build_player_spongebob_model()
	player_avatar.position = Vector3(0.0, 0.0, 2.0)
	player_avatar.scale = Vector3(1.25, 1.25, 1.25)
	player_avatar.rotation.y = 0.0
	add_child(player_avatar)
	
	var player_lbl = Label3D.new()
	player_lbl.name = "PlayerLabel3D"
	player_lbl.text = "⭐ SPONGEBOB (YOU)\n[ WASD / Arrows to Walk ]"
	player_lbl.font = UIThemeBuilder.get_title_font()
	player_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player_lbl.no_depth_test = true
	player_lbl.render_priority = 22
	player_lbl.font_size = 48
	player_lbl.pixel_size = 0.0068
	player_lbl.outline_size = 16
	player_lbl.outline_modulate = Color(0.02, 0.05, 0.10, 0.98)
	player_lbl.modulate = Color(1.0, 0.95, 0.30)
	player_lbl.line_spacing = 2.0
	player_lbl.position = Vector3(0, 2.58, 0)
	player_avatar.add_child(player_lbl)
	
	if camera_3d:
		camera_3d.position = Vector3(0.0, 14.5, 20.0)
		camera_3d.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)

func _build_building_barrier(d: Dictionary) -> void:
	var b_shape: String = d.get("barrier_shape", "circle")
	var b_center: Vector3 = d.get("barrier_center", d["bldg_pos"])
	var b_col: Color = d.get("color", Color(0.3, 0.8, 1.0))
	
	var barrier_root := Node3D.new()
	barrier_root.name = "Barrier_" + str(d["id"])
	barrier_root.position = b_center
	landmarks_3d.add_child(barrier_root)
	
	var curb_mat := ModelBuilder3D.make_mat(Color("#263544"), 0.62, 0.32)
	var bollard_mat := ModelBuilder3D.make_mat(Color("#1A2632"), 0.45, 0.55)
	var accent_mat := ModelBuilder3D.make_mat(b_col, 0.25, 0.20, b_col * 0.65)
	
	var static_body := StaticBody3D.new()
	static_body.name = "BarrierCollider"
	barrier_root.add_child(static_body)
	var col_shape := CollisionShape3D.new()
	static_body.add_child(col_shape)
	
	if b_shape == "circle":
		var r: float = float(d.get("barrier_radius", 2.6))
		var cyl_shape := CylinderShape3D.new()
		cyl_shape.radius = r
		cyl_shape.height = 4.5
		col_shape.shape = cyl_shape
		col_shape.position = Vector3(0, 2.25, 0)
		
		# Raised circular stone/metal barrier curb ring & glowing top trim around the building perimeter
		ModelBuilder3D.add_torus(barrier_root, r - 0.14, r + 0.02, Vector3(0, 0.16, 0), curb_mat)
		ModelBuilder3D.add_torus(barrier_root, r - 0.09, r - 0.02, Vector3(0, 0.26, 0), accent_mat)
		
		# 12 Nautical Perimeter Bollards with glowing cap rings
		var bollard_count: int = 12
		for bi: int in range(bollard_count):
			var b_ang: float = deg_to_rad(float(bi) * (360.0 / float(bollard_count)) + 15.0)
			var bx: float = sin(b_ang) * (r - 0.06)
			var bz: float = cos(b_ang) * (r - 0.06)
			ModelBuilder3D.add_cylinder(barrier_root, 0.09, 0.11, 0.44, Vector3(bx, 0.22, bz), bollard_mat)
			ModelBuilder3D.add_sphere(barrier_root, 0.095, 0.10, Vector3(bx, 0.45, bz), bollard_mat)
			ModelBuilder3D.add_torus(barrier_root, 0.075, 0.11, Vector3(bx, 0.36, bz), accent_mat)
			
		building_barriers.append({
			"id": d["id"],
			"shape": "circle",
			"center": Vector2(b_center.x, b_center.z),
			"radius": r
		})
	else:
		var sz: Vector2 = d.get("barrier_size", Vector2(5.0, 5.0))
		var hx: float = sz.x * 0.5
		var hz: float = sz.y * 0.5
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(sz.x, 4.5, sz.y)
		col_shape.shape = box_shape
		col_shape.position = Vector3(0, 2.25, 0)
		
		# 4 Raised Rectangular Perimeter Barrier Curbs & Glowing Top Strips
		var curb_t: float = 0.20
		var curb_h: float = 0.26
		# North & South walls
		for z_side: float in [-1.0, 1.0]:
			var wz: float = z_side * (hz - curb_t * 0.5)
			ModelBuilder3D.add_box(barrier_root, Vector3(sz.x, curb_h, curb_t), Vector3(0, curb_h * 0.5, wz), curb_mat)
			ModelBuilder3D.add_box(barrier_root, Vector3(sz.x - 0.12, 0.04, 0.08), Vector3(0, curb_h + 0.02, wz), accent_mat)
		# West & East walls
		for x_side: float in [-1.0, 1.0]:
			var wx: float = x_side * (hx - curb_t * 0.5)
			ModelBuilder3D.add_box(barrier_root, Vector3(curb_t, curb_h, sz.y - curb_t * 2.0), Vector3(wx, curb_h * 0.5, 0), curb_mat)
			ModelBuilder3D.add_box(barrier_root, Vector3(0.08, 0.04, sz.y - 0.12), Vector3(wx, curb_h + 0.02, 0), accent_mat)
			
		# Corner & Midpoint Nautical Bollards around the rectangular barrier
		var bollard_pts: Array[Vector2] = [
			Vector2(-hx + 0.10, -hz + 0.10),
			Vector2(0.0, -hz + 0.10),
			Vector2(hx - 0.10, -hz + 0.10),
			Vector2(-hx + 0.10, 0.0),
			Vector2(hx - 0.10, 0.0),
			Vector2(-hx + 0.10, hz - 0.10),
			Vector2(0.0, hz - 0.10),
			Vector2(hx - 0.10, hz - 0.10)
		]
		for bp: Vector2 in bollard_pts:
			ModelBuilder3D.add_cylinder(barrier_root, 0.095, 0.115, 0.46, Vector3(bp.x, 0.23, bp.y), bollard_mat)
			ModelBuilder3D.add_sphere(barrier_root, 0.10, 0.10, Vector3(bp.x, 0.47, bp.y), bollard_mat)
			ModelBuilder3D.add_torus(barrier_root, 0.08, 0.115, Vector3(bp.x, 0.38, bp.y), accent_mat)
			
		building_barriers.append({
			"id": d["id"],
			"shape": "box",
			"center": Vector2(b_center.x, b_center.z),
			"half_extents": Vector2(hx, hz)
		})

func _resolve_building_collisions(next_pos: Vector3, player_radius: float = 0.50) -> Vector3:
	var p := Vector2(next_pos.x, next_pos.z)
	for b: Dictionary in building_barriers:
		var c: Vector2 = b["center"]
		if b["shape"] == "circle":
			var min_dist: float = float(b["radius"]) + player_radius
			var delta_v: Vector2 = p - c
			var dist: float = delta_v.length()
			if dist < min_dist:
				if dist < 0.001:
					p = c + Vector2(0.0, min_dist)
				else:
					p = c + (delta_v / dist) * min_dist
		else:
			var he: Vector2 = b["half_extents"]
			var rel: Vector2 = p - c
			var closest := Vector2(clampf(rel.x, -he.x, he.x), clampf(rel.y, -he.y, he.y))
			var diff: Vector2 = rel - closest
			var d_len: float = diff.length()
			if d_len < player_radius:
				if d_len > 0.0001:
					p = c + closest + (diff / d_len) * player_radius
				else:
					# Inside the box: push out along the shallowest penetration axis
					var pen_x: float = (he.x + player_radius) - absf(rel.x)
					var pen_y: float = (he.y + player_radius) - absf(rel.y)
					if pen_x < pen_y:
						var sx: float = 1.0 if rel.x >= 0.0 else -1.0
						p.x = c.x + sx * (he.x + player_radius)
					else:
						var sy: float = 1.0 if rel.y >= 0.0 else -1.0
						p.y = c.y + sy * (he.y + player_radius)
	return Vector3(p.x, next_pos.y, p.y)

func _get_pad_by_id(pad_id: String) -> Dictionary:
	for p in cylinder_pads:
		if p["id"] == pad_id:
			return p
	return {}

func _unhandled_input(_event: InputEvent) -> void:
	# Menus only open when the player avatar physically steps inside the cylinder pad!
	pass

func _is_any_modal_open() -> bool:
	var pack_active: bool = summon_modal.has_method("is_cinematic_or_summary_active") and summon_modal.is_cinematic_or_summary_active()
	return (
		summon_modal.visible or pack_active or inventory_modal.visible or lab_modal.visible
		or trade_modal.visible or afk_modal.visible or settings_modal.visible
		or leaderboards_modal.visible or (stage_select_modal and stage_select_modal.visible)
		or (infinity_select_modal and infinity_select_modal.visible)
		or (credits_modal and credits_modal.visible)
	)

func _process(delta: float) -> void:
	# Sandy's Treedome Proximity Boost check (within 4.5m of Sandy's Treedome pad or while modal open)
	if player_avatar:
		var p_flat := Vector2(player_avatar.position.x, player_avatar.position.z)
		var treedome_pad := Vector2(19.2, -5.0)
		if p_flat.distance_to(treedome_pad) <= 4.5 or (afk_modal and afk_modal.visible):
			PlayerData.is_afk_boosted = true
		elif standing_pad_id != "Treedome":
			PlayerData.is_afk_boosted = false
		
	if modal_backdrop:
		modal_backdrop.visible = _is_any_modal_open()
		
	# Animate underwater atmosphere & cylinder beacons
	for elem in animated_decorations:
		if elem["type"] == "bubble":
			var b: MeshInstance3D = elem["node"]
			b.position.y += elem["speed"] * delta
			elem["wobble"] += delta * 2.0
			b.position.x = elem["base_x"] + sin(elem["wobble"]) * 0.25
			b.position.z = elem["base_z"] + cos(elem["wobble"]) * 0.25
			if b.position.y > 12.0:
				b.position.y = 0.2
		elif elem["type"] == "pad_ring":
			var ring: MeshInstance3D = elem["node"]
			ring.rotation.y += delta * 1.5
			var scale_pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005 + elem["offset"]) * 0.07
			ring.scale = Vector3(scale_pulse, 1.0, scale_pulse)
		elif elem["type"] == "thematic_pad":
			var pdata: Dictionary = elem.get("pad_data", {})
			var emblem: Node3D = pdata.get("emblem_node", null)
			var base_y: float = float(pdata.get("emblem_base_y", 0.65))
			var cur_time: float = float(Time.get_ticks_msec()) * 0.001 + float(elem.get("offset", 0.0))
			
			# 1. Rotate & bob 3D Emblem
			if emblem and is_instance_valid(emblem):
				emblem.rotation.y += delta * 1.6
				emblem.position.y = base_y + sin(cur_time * 2.2) * 0.09
				
			# 2. Rotate & pulse rune rings
			var r_items: Array = pdata.get("ring_items", [])
			for r_item in r_items:
				var r_node: Node3D = r_item.get("node", null)
				if r_node and is_instance_valid(r_node):
					r_node.rotation.y += delta * float(r_item.get("speed", 1.2))
					var p_amp: float = float(r_item.get("pulse_amp", 0.06))
					var p_spd: float = float(r_item.get("pulse_spd", 0.005))
					var p_scale = 1.0 + sin(Time.get_ticks_msec() * p_spd + float(elem.get("offset", 0.0))) * p_amp
					r_node.scale = Vector3(p_scale, 1.0, p_scale)
					
			# 3. 3D Kinematic Orbiting props & thematic effects
			var o_items: Array = pdata.get("orbit_items", [])
			for o_item in o_items:
				var o_node: Node3D = o_item.get("node", null)
				if o_node and is_instance_valid(o_node):
					var ang_spd: float = float(o_item.get("speed", 1.5))
					o_item["angle"] = float(o_item.get("angle", 0.0)) + delta * ang_spd
					var ang: float = float(o_item["angle"])
					var rad: float = float(o_item.get("radius", 0.88))
					var by: float = float(o_item.get("base_y", 0.6))
					var w_spd: float = float(o_item.get("wave_spd", 2.5))
					var w_amp: float = float(o_item.get("wave_amp", 0.15))
					
					o_node.position.x = cos(ang) * rad
					o_node.position.z = sin(ang) * rad
					o_node.position.y = by + sin(cur_time * w_spd + ang) * w_amp
					
					var s_rot: Vector3 = o_item.get("self_rot", Vector3.ZERO)
					if s_rot != Vector3.ZERO:
						o_node.rotation.x += delta * s_rot.x
						o_node.rotation.y += delta * s_rot.y
						o_node.rotation.z += delta * s_rot.z

	if pad_trigger_cooldown > 0.0:
		pad_trigger_cooldown -= delta

	if player_avatar and not _is_any_modal_open() and not is_teleporting and not is_transitioning:
		var dir = Vector3.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			dir.z -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			dir.z += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1.0
			
		if dir.length_squared() > 0.0:
			dir = dir.normalized()
			var candidate_pos: Vector3 = player_avatar.position + dir * 9.5 * delta
			candidate_pos.x = clampf(candidate_pos.x, -26.5, 26.5)
			candidate_pos.z = clampf(candidate_pos.z, -24.5, 22.0)
			candidate_pos = _resolve_building_collisions(candidate_pos)
			player_avatar.position.x = candidate_pos.x
			player_avatar.position.z = candidate_pos.z
			var prev_step_phase: int = int(player_walk_anim / PI)
			player_walk_anim += delta * 12.0
			if int(player_walk_anim / PI) != prev_step_phase:
				if AudioManager: AudioManager.play_footstep()
			player_avatar.position.y = absf(sin(player_walk_anim)) * 0.22
			# SpongeBob's face is built on local +Z; atan2(dir.x, dir.z) aligns local +Z with dir!
			var target_yaw: float = atan2(dir.x, dir.z)
			player_avatar.rotation.y = lerp_angle(player_avatar.rotation.y, target_yaw, minf(1.0, delta * 22.0))
			_update_player_limb_swing(sin(player_walk_anim))
		else:
			player_avatar.position.y = lerpf(player_avatar.position.y, 0.0, delta * 10.0)
			_update_player_limb_swing(0.0)
			
		# Check if player stepped onto any cylinder pad in front of a building!
		var p_flat = Vector2(player_avatar.position.x, player_avatar.position.z)
		var on_any_pad := false
		for pad in cylinder_pads:
			var pad_flat = Vector2(pad["pos"].x, pad["pos"].z)
			var dist = p_flat.distance_to(pad_flat)
			if dist <= 1.45:
				on_any_pad = true
				if standing_pad_id != pad["id"] and pad_trigger_cooldown <= 0.0:
					standing_pad_id = pad["id"]
					pad_trigger_cooldown = 1.8
					call(pad["action"])
				break
				
		if not on_any_pad and standing_pad_id != "":
			var cur_pad = _get_pad_by_id(standing_pad_id)
			if cur_pad.is_empty() or p_flat.distance_to(Vector2(cur_pad["pos"].x, cur_pad["pos"].z)) > 2.0:
				standing_pad_id = ""
			
		if camera_3d and not is_teleporting and not is_transitioning:
			var target_cam = Vector3(player_avatar.position.x * 0.45, 14.5, player_avatar.position.z * 0.45 + 19.5)
			camera_3d.position = camera_3d.position.lerp(target_cam, delta * 3.5)
			camera_3d.look_at(Vector3(player_avatar.position.x * 0.25, 1.5, player_avatar.position.z * 0.25), Vector3.UP)

func orient_player_toward_dir(dir: Vector3) -> void:
	if player_avatar and Vector2(dir.x, dir.z).length() > 0.001:
		player_avatar.rotation.y = atan2(dir.x, dir.z)

func _update_player_limb_swing(swing: float) -> void:
	if not player_avatar:
		return
	if player_avatar.has_node("LeftLegPivot"):
		player_avatar.get_node("LeftLegPivot").rotation.x = swing * 0.55
	if player_avatar.has_node("RightLegPivot"):
		player_avatar.get_node("RightLegPivot").rotation.x = -swing * 0.55
	if player_avatar.has_node("LeftArmPivot"):
		player_avatar.get_node("LeftArmPivot").rotation.x = -swing * 0.45
		player_avatar.get_node("LeftArmPivot").rotation.z = -0.15
	if player_avatar.has_node("RightArmPivot"):
		# Spatula arm held proud and forward, angled 14 degrees outward so it never penetrates body
		player_avatar.get_node("RightArmPivot").rotation.x = -0.26 + swing * 0.35
		player_avatar.get_node("RightArmPivot").rotation.z = 0.25
		player_avatar.get_node("RightArmPivot").rotation.y = -0.10

func _update_currency_display() -> void:
	level_label.text = "⭐ Lv.%d" % PlayerData.level
	xp_bar.max_value = PlayerData.get_xp_for_next_level()
	xp_bar.value = PlayerData.xp
	gold_label.text = "🪙 %d" % PlayerData.gold
	gems_label.text = "💎 %d" % PlayerData.gems
	dice_label.text = "🎲 %d" % PlayerData.reroll_dice

func _on_level_up(_new_lvl: int) -> void:
	_update_currency_display()

func _close_all_modals() -> void:
	var was_open: bool = _is_any_modal_open()
	pad_trigger_cooldown = 1.2
	if summon_modal.has_method("close_pack_summary"):
		summon_modal.close_pack_summary(true)
	summon_modal.visible = false
	inventory_modal.visible = false
	lab_modal.visible = false
	trade_modal.visible = false
	afk_modal.visible = false
	settings_modal.visible = false
	leaderboards_modal.visible = false
	if stage_select_modal:
		stage_select_modal.visible = false
	if infinity_select_modal:
		infinity_select_modal.visible = false
	if credits_modal:
		credits_modal.visible = false
	if modal_backdrop:
		modal_backdrop.visible = false
	if was_open and AudioManager:
		AudioManager.play_sfx("ui_close")

func open_credits_menu() -> void:
	_close_all_modals()
	if AudioManager:
		AudioManager.play_sfx("ui_open")
	if credits_modal:
		credits_modal.call("refresh_view")
		UIThemeBuilder.animate_modal_open(credits_modal)

func open_summon_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	summon_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(summon_modal)

func open_inventory_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	inventory_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(inventory_modal)

func open_lab_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	lab_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(lab_modal)

func open_trading_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	trade_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(trade_modal)

func open_afk_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	afk_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(afk_modal)

func open_settings_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	settings_modal.call("refresh_view")
	UIThemeBuilder.animate_modal_open(settings_modal)

func open_leaderboard_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	if has_node("HUD/LeaderboardModal/VBox/Scores"):
		var scores_lbl: Label = $HUD/LeaderboardModal/VBox/Scores
		scores_lbl.text = "🥇 1. KingNeptune_99 — Wave 142 (2,480 Bots)\n🥈 2. SandyCheeks_TX — Wave 118 (1,920 Bots)\n🥉 3. LarryTheLobster — Wave 95 (1,410 Bots)\n4. FlyingDutchman — Wave 74 (980 Bots)\n⭐ YOU — Best Wave: %d (%d Bots Defeated)" % [
			PlayerData.highest_infinity_wave,
			PlayerData.highest_infinity_kills
		]
	UIThemeBuilder.animate_modal_open(leaderboards_modal)

func open_stage_select_menu() -> void:
	_close_all_modals()
	if AudioManager: AudioManager.play_sfx("ui_open")
	if stage_select_modal:
		stage_select_modal.call("refresh_view")
		UIThemeBuilder.animate_modal_open(stage_select_modal)

func enter_battle() -> void:
	open_stage_select_menu()

func _launch_stage_entrance_animation(stage_id: int) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_close_all_modals()
	if AudioManager:
		AudioManager.play_sfx("stage_enter")
	
	var stage_info: Dictionary = GameData.STAGES.get(stage_id, GameData.STAGES[1])
	var zone_id: int = int(stage_info.get("zone_id", 1))
	var zone_info: Dictionary = GameData.ZONES.get(zone_id, GameData.ZONES[1])
	var accent_col: Color = zone_info.get("accent_color", Color("#38BDF8"))
	
	# 1. 3D Ground Shockwave Ring beneath SpongeBob
	var shockwave := MeshInstance3D.new()
	var t_mesh := TorusMesh.new()
	t_mesh.inner_radius = 0.5
	t_mesh.outer_radius = 0.75
	shockwave.mesh = t_mesh
	if player_avatar:
		shockwave.position = player_avatar.position + Vector3(0, 0.05, 0)
	else:
		shockwave.position = Vector3(0, 0.05, 0)
	var sw_mat = ModelBuilder3D.make_mat(accent_col, 0.1, 0.0, accent_col * 2.0, 0.95)
	shockwave.material_override = sw_mat
	add_child(shockwave)
	
	var sw_tw := create_tween().set_parallel(true)
	sw_tw.tween_property(shockwave, "scale", Vector3(8.0, 1.0, 8.0), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sw_tw.tween_property(sw_mat, "albedo_color:a", 0.0, 0.75)
	sw_tw.chain().tween_callback(shockwave.queue_free)
	
	# 2. SpongeBob Jump & Victory Spin with Spatula
	if player_avatar:
		var sb_tw := create_tween().set_parallel(true)
		sb_tw.tween_property(player_avatar, "position:y", 2.2, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sb_tw.tween_property(player_avatar, "rotation_degrees:y", player_avatar.rotation_degrees.y + 360.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sb_tw.tween_property(player_avatar, "scale", Vector3(1.45, 1.45, 1.45), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if player_avatar.has_node("LeftArmPivot"):
			sb_tw.tween_property(player_avatar.get_node("LeftArmPivot"), "rotation:z", -2.4, 0.4)
		if player_avatar.has_node("RightArmPivot"):
			sb_tw.tween_property(player_avatar.get_node("RightArmPivot"), "rotation:z", 2.2, 0.4)
			sb_tw.tween_property(player_avatar.get_node("RightArmPivot"), "rotation:x", -0.8, 0.4)
			
	# 3. 3D Camera Dramatic Dive towards Krusty Krab Entrance Doors
	if camera_3d:
		var cam_target := Vector3(-15.0, 4.0, -14.0)
		var cam_tw := create_tween().set_parallel(true)
		cam_tw.tween_property(camera_3d, "position", cam_target, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		cam_tw.tween_property(camera_3d, "fov", 44.0, 0.95)
		
	# 4. 2D Full-Screen Oceanic Transition Vortex & Heroic Banner
	var trans_overlay := Control.new()
	trans_overlay.name = "StageEntranceOverlay"
	trans_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD.add_child(trans_overlay)
	UIThemeBuilder.place_rect(trans_overlay, 0.0, 0.0, 1280.0, 720.0)
	
	var vortex_curtain := ColorRect.new()
	var zone_bg_color: Color = zone_info.get("bg_color", Color("#0369A1")).lerp(Color("#0B132B"), 0.35)
	vortex_curtain.color = Color(zone_bg_color.r, zone_bg_color.g, zone_bg_color.b, 0.0)
	trans_overlay.add_child(vortex_curtain)
	UIThemeBuilder.place_rect(vortex_curtain, 0.0, 0.0, 1280.0, 720.0)
	
	# Radial bubble explosion
	var bubble_box := Control.new()
	bubble_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trans_overlay.add_child(bubble_box)
	
	for bi in range(32):
		var b := Panel.new()
		var b_rad := randf_range(28.0, 80.0)
		var b_sb := UIThemeBuilder.make_pill_style(Color(accent_col.r, accent_col.g, accent_col.b, 0.65), Color.WHITE, int(b_rad * 0.5))
		b.add_theme_stylebox_override("panel", b_sb)
		bubble_box.add_child(b)
		b.position = Vector2(640, 360)
		b.size = Vector2(b_rad, b_rad)
		var b_ang := randf() * 6.28
		var b_dist := randf_range(240.0, 720.0)
		var b_dest := Vector2(640 + cos(b_ang) * b_dist, 360 + sin(b_ang) * b_dist)
		
		var b_tw := create_tween().set_parallel(true)
		b_tw.tween_property(b, "position", b_dest, randf_range(0.65, 0.95)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		b_tw.tween_property(b, "modulate:a", 0.0, 0.85).set_delay(0.15)
		
	# Heroic Stage Entrance Banner
	var banner_box := VBoxContainer.new()
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.add_theme_constant_override("separation", 8)
	trans_overlay.add_child(banner_box)
	UIThemeBuilder.place_rect(banner_box, 140.0, 260.0, 1000.0, 200.0)
	
	var b_title := Label.new()
	b_title.text = "⚔️ ENTERING STAGE %d: %s ⚔️" % [stage_id, stage_info.get("name", "").to_upper()]
	b_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(b_title, 30, Color(1.0, 0.92, 0.25), 8)
	banner_box.add_child(b_title)
	
	var b_sub := Label.new()
	b_sub.text = "%s %s • %d WAVES • BOSS: %s" % [
		zone_info.get("icon", "🌊"),
		zone_info.get("name", "").to_upper(),
		int(stage_info.get("waves", 10)),
		str(stage_info.get("boss", "")).replace("_", " ").to_upper()
	]
	b_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(b_sub, 18, accent_col, 4)
	banner_box.add_child(b_sub)
	
	banner_box.modulate.a = 0.0
	banner_box.scale = Vector2(0.75, 0.75)
	banner_box.pivot_offset = Vector2(500.0, 100.0)
	
	var ui_tw := create_tween().set_parallel(true)
	ui_tw.tween_property(vortex_curtain, "color:a", 1.0, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ui_tw.tween_property(banner_box, "modulate:a", 1.0, 0.35).set_delay(0.15)
	ui_tw.tween_property(banner_box, "scale", Vector2(1.08, 1.08), 0.50).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.05).timeout
	PlayerData.selected_stage_id = stage_id
	PlayerData.current_battle_mode = "campaign"
	get_tree().change_scene_to_file("res://scenes/game/battle.tscn")

func open_infinity_menu() -> void:
	_close_all_modals()
	if AudioManager:
		AudioManager.play_sfx("ui_open")
	if infinity_select_modal:
		infinity_select_modal.refresh_view()
		UIThemeBuilder.animate_modal_open(infinity_select_modal)

func enter_infinity_battle() -> void:
	open_infinity_menu()

func _launch_infinity_entrance_animation(theme_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_close_all_modals()
	
	if AudioManager:
		AudioManager.play_sfx("stage_enter")
		
	var map_names = {
		"outskirts": "BIKINI BOTTOM OUTSKIRTS",
		"krusty_interior": "THE KRUSTY KRAB",
		"squidward_interior": "SQUIDWARD'S MOAI SALON"
	}
	var map_diffs = {
		"outskirts": "⭐ NORMAL • 1.0x REWARDS",
		"krusty_interior": "⭐⭐ HARD • 1.5x REWARDS",
		"squidward_interior": "⭐⭐⭐ NIGHTMARE • 2.0x REWARDS"
	}
	var map_name_str: String = map_names.get(theme_id, "INFINITY WAVES")
	var map_diff_str: String = map_diffs.get(theme_id, "ENDLESS WAVES")
	
	var trans_overlay := Control.new()
	trans_overlay.name = "InfinityTransitionOverlay"
	trans_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(trans_overlay)
	
	var vortex_curtain := ColorRect.new()
	vortex_curtain.color = Color(0.04, 0.08, 0.16, 0.0)
	vortex_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	trans_overlay.add_child(vortex_curtain)
	
	var bubble_box := Control.new()
	trans_overlay.add_child(bubble_box)
	for bi in range(24):
		var b := Panel.new()
		var b_rad := randf_range(16.0, 48.0)
		b.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(Color(0.4, 0.85, 1.0, 0.45), Color(0.8, 0.95, 1.0, 0.8), int(b_rad * 0.5)))
		bubble_box.add_child(b)
		b.position = Vector2(640, 360)
		b.size = Vector2(b_rad, b_rad)
		var b_ang := randf() * 6.28
		var b_dist := randf_range(240.0, 720.0)
		var b_dest := Vector2(640 + cos(b_ang) * b_dist, 360 + sin(b_ang) * b_dist)
		var b_tw := create_tween().set_parallel(true)
		b_tw.tween_property(b, "position", b_dest, randf_range(0.65, 0.95)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		b_tw.tween_property(b, "modulate:a", 0.0, 0.85).set_delay(0.15)
		
	var banner_box := VBoxContainer.new()
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.add_theme_constant_override("separation", 8)
	trans_overlay.add_child(banner_box)
	UIThemeBuilder.place_rect(banner_box, 140.0, 260.0, 1000.0, 200.0)
	
	var b_title := Label.new()
	b_title.text = "♾️ INFINITY EXPEDITION: %s ♾️" % map_name_str
	b_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(b_title, 28, Color(1.0, 0.55, 0.85), 6)
	banner_box.add_child(b_title)
	
	var b_sub := Label.new()
	b_sub.text = "%s • ENDLESS BOSSES EVERY 5 WAVES" % map_diff_str
	b_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(b_sub, 16, Color(1.0, 0.88, 0.35), 3)
	banner_box.add_child(b_sub)
	
	banner_box.modulate.a = 0.0
	banner_box.scale = Vector2(0.8, 0.8)
	banner_box.pivot_offset = Vector2(500.0, 100.0)
	
	var ui_tw := create_tween().set_parallel(true)
	ui_tw.tween_property(vortex_curtain, "color:a", 1.0, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ui_tw.tween_property(banner_box, "modulate:a", 1.0, 0.35).set_delay(0.15)
	ui_tw.tween_property(banner_box, "scale", Vector2(1.08, 1.08), 0.50).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.05).timeout
	PlayerData.current_battle_mode = "infinity"
	PlayerData.selected_infinity_map = theme_id
	get_tree().change_scene_to_file("res://scenes/game/battle.tscn")

func return_to_main_menu() -> void:
	_close_all_modals()
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _build_lobby_road_network() -> void:
	var roads_root = Node3D.new()
	roads_root.name = "RoadNetwork"
	add_child(roads_root)
	
	# PBR Materials for Paved Streets, Curbs & Promenade Pathways
	var road_asphalt = ModelBuilder3D.make_mat(Color("#262D33"), 0.82, 0.12)  # Dark asphalt street
	var curb_stone = ModelBuilder3D.make_mat(Color("#8E999B"), 0.70, 0.15)    # Concrete stone curb
	var plaza_pave = ModelBuilder3D.make_mat(Color("#7A6E59"), 0.78, 0.05)    # Warm plaza stone paving
	var plaza_ring_mat = ModelBuilder3D.make_mat(Color("#4A4235"), 0.75, 0.1) # Concentric decorative inlay
	var star_gold = ModelBuilder3D.make_mat(Color("#F1C40F"), 0.35, 0.45, Color("#D4AC0D") * 0.45) # Gold nautical inlay
	var road_line_mat = ModelBuilder3D.make_mat(Color("#F4D03F"), 0.45, 0.0, Color("#F1C40F") * 0.4) # Road markings
	var boardwalk_timber = ModelBuilder3D.make_mat(Color("#8E653A"), 0.75, 0.05) # Sandy's oak boardwalk
	var boardwalk_rail = ModelBuilder3D.make_mat(Color("#5C3A1E"), 0.80)      # Timber border beams
	var flagstone_mat = ModelBuilder3D.make_mat(Color("#7D878D"), 0.72)       # Conch street stone pavers
	
	# -------------------------------------------------------------
	# 1. CENTRAL ROUNDABOUT & PLAZA ISLAND (Encircling Center Cleanly)
	# -------------------------------------------------------------
	# Circular Roundabout Asphalt Roadway (r = 3.55m to 7.0m encircling the central island)
	ModelBuilder3D.add_cylinder(roads_root, 7.0, 7.0, 0.041, Vector3(0, 0.0205, 0), road_asphalt)
	
	# Circular Roundabout Dashed Yellow Centerline (at r = 5.25m)
	for ri in range(16):
		var r_deg = ri * 22.5
		var r_rad = deg_to_rad(r_deg)
		var l_pos = Vector3(sin(r_rad) * 5.25, 0.043, -cos(r_rad) * 5.25)
		ModelBuilder3D.add_box(roads_root, Vector3(0.95, 0.012, 0.16), l_pos, road_line_mat, Vector3(0, -r_deg, 0))
	
	# Curved Outer Roundabout Curbs (r = 7.125m) in the 4 inter-cardinal arcs between spoke openings
	for quad in range(4):
		var base_deg = quad * 90.0
		for seg in range(8):
			var a_deg = base_deg + 21.5 + seg * 6.714
			var a_rad = deg_to_rad(a_deg)
			var c_pos = Vector3(sin(a_rad) * 7.125, 0.035, -cos(a_rad) * 7.125)
			ModelBuilder3D.add_box(roads_root, Vector3(0.88, 0.06, 0.25), c_pos, curb_stone, Vector3(0, -a_deg, 0))
	
	# Central Stone Island Curbed Border (r = 3.55m) & Raised Stone Plaza (r = 3.30m)
	ModelBuilder3D.add_cylinder(roads_root, 3.55, 3.55, 0.060, Vector3(0, 0.030, 0), curb_stone)
	ModelBuilder3D.add_cylinder(roads_root, 3.30, 3.30, 0.066, Vector3(0, 0.033, 0), plaza_pave)
	ModelBuilder3D.add_cylinder(roads_root, 2.30, 2.30, 0.070, Vector3(0, 0.035, 0), plaza_ring_mat)
	ModelBuilder3D.add_cylinder(roads_root, 2.05, 2.05, 0.074, Vector3(0, 0.037, 0), plaza_pave)
	
	# Central Nautical Compass Star (Strictly inside the 2.05m inner stone island)
	for si in range(8):
		var s_ang = deg_to_rad(si * 45.0)
		var pt_pos = Vector3(sin(s_ang) * 0.78, 0.077, cos(s_ang) * 0.78)
		ModelBuilder3D.add_box(roads_root, Vector3(0.16, 0.012, 1.45), pt_pos, star_gold, Vector3(0, si * 45.0, 0))
	ModelBuilder3D.add_cylinder(roads_root, 0.42, 0.42, 0.018, Vector3(0, 0.079, 0), star_gold)
	
	# -------------------------------------------------------------
	# 2. THE 4 SPOKE AVENUES (Connecting Roundabout to Perimeter)
	# -------------------------------------------------------------
	# North Spoke (x = 0, connecting Roundabout z = -6.71 to North Blvd z = -11.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 4.29), Vector3(0, 0.02, -8.855), road_asphalt)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 3.95), Vector3(-2.125, 0.035, -8.775), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 3.95), Vector3(2.125, 0.035, -8.775), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.16, 0.012, 1.5), Vector3(0, 0.042, -8.9), road_line_mat)
		
	# South Spoke (x = 0, connecting Roundabout z = 6.71 to South Pkwy z = 12.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 5.29), Vector3(0, 0.02, 9.355), road_asphalt)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.95), Vector3(-2.125, 0.035, 9.275), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.95), Vector3(2.125, 0.035, 9.275), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.16, 0.012, 1.7), Vector3(0, 0.042, 9.4), road_line_mat)
		
	# West Spoke (z = 0, connecting Roundabout x = -6.71 to West Conch St x = -13.0)
	ModelBuilder3D.add_box(roads_root, Vector3(6.29, 0.04, 4.0), Vector3(-9.855, 0.02, 0), road_asphalt)
	ModelBuilder3D.add_box(roads_root, Vector3(5.95, 0.06, 0.25), Vector3(-9.775, 0.035, -2.125), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(5.95, 0.06, 0.25), Vector3(-9.775, 0.035, 2.125), curb_stone)
	for li in range(2):
		ModelBuilder3D.add_box(roads_root, Vector3(1.3, 0.012, 0.16), Vector3(-8.4 - li * 2.8, 0.042, 0), road_line_mat)
		
	# East Spoke (z = 0, connecting Roundabout x = 6.71 to East Harbor Blvd x = 13.0)
	ModelBuilder3D.add_box(roads_root, Vector3(6.29, 0.04, 4.0), Vector3(9.855, 0.02, 0), road_asphalt)
	ModelBuilder3D.add_box(roads_root, Vector3(5.95, 0.06, 0.25), Vector3(9.775, 0.035, -2.125), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(5.95, 0.06, 0.25), Vector3(9.775, 0.035, 2.125), curb_stone)
	for li in range(2):
		ModelBuilder3D.add_box(roads_root, Vector3(1.3, 0.012, 0.16), Vector3(8.4 + li * 2.8, 0.042, 0), road_line_mat)
		
	# -------------------------------------------------------------
	# 3. NORTH BOULEVARD (East-West Avenue along z = -13.0)
	# -------------------------------------------------------------
	# Continuous asphalt roadway from x = -17.0 to +17.0 (width 4.0m, from z = -15.0 to -11.0)
	ModelBuilder3D.add_box(roads_root, Vector3(34.0, 0.04, 4.0), Vector3(0, 0.02, -13.0), road_asphalt)
	for li in range(11):
		var lx = -15.0 + li * 3.0
		ModelBuilder3D.add_box(roads_root, Vector3(1.6, 0.012, 0.16), Vector3(lx, 0.042, -13.0), road_line_mat)
	# South curbs facing roundabout (z = -10.875) with North Spoke opening at x = [-2.25, 2.25]
	ModelBuilder3D.add_box(roads_root, Vector3(10.75, 0.06, 0.25), Vector3(-7.625, 0.035, -10.875), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(10.75, 0.06, 0.25), Vector3(7.625, 0.035, -10.875), curb_stone)
	# North curbs between Krusty Krab patio (x = -17..-13), Altar patio (x = -2.5..2.5), and Chum Bucket patio (x = 13..17)
	ModelBuilder3D.add_box(roads_root, Vector3(10.0, 0.06, 0.25), Vector3(-7.75, 0.035, -15.125), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(10.0, 0.06, 0.25), Vector3(7.75, 0.035, -15.125), curb_stone)
	
	# -------------------------------------------------------------
	# 4. SOUTH PARKWAY (East-West Avenue along z = 14.0)
	# -------------------------------------------------------------
	# Continuous asphalt roadway from x = -17.0 to +17.0 (width 4.0m, from z = 12.0 to 16.0)
	ModelBuilder3D.add_box(roads_root, Vector3(34.0, 0.04, 4.0), Vector3(0, 0.02, 14.0), road_asphalt)
	for li in range(11):
		var lx = -15.0 + li * 3.0
		ModelBuilder3D.add_box(roads_root, Vector3(1.6, 0.012, 0.16), Vector3(lx, 0.042, 14.0), road_line_mat)
	# North curbs facing roundabout (z = 11.875) with South Spoke opening at x = [-2.25, 2.25]
	ModelBuilder3D.add_box(roads_root, Vector3(10.75, 0.06, 0.25), Vector3(-7.625, 0.035, 11.875), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(10.75, 0.06, 0.25), Vector3(7.625, 0.035, 11.875), curb_stone)
	# South continuous outer curb (z = 16.125, spanning x = -17.0 to +17.0)
	ModelBuilder3D.add_box(roads_root, Vector3(34.0, 0.06, 0.25), Vector3(0, 0.035, 16.125), curb_stone)
	
	# -------------------------------------------------------------
	# 5. WEST CONCH STREET (North-South Avenue along x = -15.0)
	# -------------------------------------------------------------
	# Seamless asphalt roadway connecting North Boulevard to South Parkway (from z = -11.0 to 12.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 23.0), Vector3(-15.0, 0.02, 0.5), road_asphalt)
	for li in range(7):
		var lz = -9.0 + li * 3.0
		ModelBuilder3D.add_box(roads_root, Vector3(0.16, 0.012, 1.6), Vector3(-15.0, 0.042, lz), road_line_mat)
	# East curbs facing roundabout (x = -12.875) with West Spoke opening at z = [-2.25, 2.25]
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 8.50), Vector3(-12.875, 0.035, -6.50), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 9.50), Vector3(-12.875, 0.035, 7.00), curb_stone)
	# West outer curbs (x = -17.125) aligned flush with Krusty Krab patio and Conch St house patios
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 14.25), Vector3(-17.125, 0.035, -14.375), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.00), Vector3(-17.125, 0.035, -0.75), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.00), Vector3(-17.125, 0.035, 7.75), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 2.00), Vector3(-17.125, 0.035, 15.25), curb_stone)
	
	# -------------------------------------------------------------
	# 6. EAST HARBOR BOULEVARD (North-South Avenue along x = 15.0)
	# -------------------------------------------------------------
	# Seamless asphalt roadway connecting North Boulevard to South Parkway (from z = -11.0 to 12.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 23.0), Vector3(15.0, 0.02, 0.5), road_asphalt)
	for li in range(7):
		var lz = -9.0 + li * 3.0
		ModelBuilder3D.add_box(roads_root, Vector3(0.16, 0.012, 1.6), Vector3(15.0, 0.042, lz), road_line_mat)
	# West curbs facing roundabout (x = 12.875) with East Spoke opening at z = [-2.25, 2.25]
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 8.50), Vector3(12.875, 0.035, -6.50), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 9.50), Vector3(12.875, 0.035, 7.00), curb_stone)
	# East outer curbs (x = 17.125) aligned flush with Chum Bucket patio and East piers
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 14.25), Vector3(17.125, 0.035, -14.375), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.00), Vector3(17.125, 0.035, -0.75), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.00), Vector3(17.125, 0.035, 7.75), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 2.00), Vector3(17.125, 0.035, 15.25), curb_stone)
	
	# -------------------------------------------------------------
	# 7. DEDICATED BUILDING FORECOURTS & PATIOS (100% Aligned With Streets!)
	# -------------------------------------------------------------
	# Krusty Krab Stone Forecourt Patio (North-West: x = -17.0..-13.0, z = -15.0..-19.7, flush with barrier!)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 4.7), Vector3(-15.0, 0.02, -17.35), plaza_pave)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.45), Vector3(-12.875, 0.035, -17.475), curb_stone)
	
	# Chum Bucket Industrial Forecourt Yard (North-East: x = 13.0..17.0, z = -15.0..-19.85, flush with barrier!)
	ModelBuilder3D.add_box(roads_root, Vector3(4.0, 0.04, 4.85), Vector3(15.0, 0.02, -17.425), road_asphalt)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.60), Vector3(12.875, 0.035, -17.55), curb_stone)
	
	# Grand Summon Altar Ceremonial Court (North-Center: x = -2.5..2.5, z = -15.0..-19.65, flush with barrier!)
	ModelBuilder3D.add_box(roads_root, Vector3(5.0, 0.04, 4.65), Vector3(0.0, 0.02, -17.325), flagstone_mat)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.40), Vector3(-2.625, 0.035, -17.45), star_gold)
	ModelBuilder3D.add_box(roads_root, Vector3(0.25, 0.06, 4.40), Vector3(2.625, 0.035, -17.45), star_gold)
	
	# SpongeBob Pineapple Front Patio (West Conch St: x = -17.0..-21.5, z = -7.0..-3.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.5, 0.04, 4.0), Vector3(-19.25, 0.02, -5.0), plaza_pave)
	ModelBuilder3D.add_box(roads_root, Vector3(4.5, 0.06, 0.25), Vector3(-19.25, 0.035, -7.125), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(4.5, 0.06, 0.25), Vector3(-19.25, 0.035, -2.875), curb_stone)
	
	# Squidward Moai Front Patio (West Conch St: x = -17.0..-21.75, z = 1.5..5.5)
	ModelBuilder3D.add_box(roads_root, Vector3(4.75, 0.04, 4.0), Vector3(-19.375, 0.02, 3.5), flagstone_mat)
	ModelBuilder3D.add_box(roads_root, Vector3(4.75, 0.06, 0.25), Vector3(-19.375, 0.035, 1.375), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(4.75, 0.06, 0.25), Vector3(-19.375, 0.035, 5.625), curb_stone)
	
	# Patrick Rock Front Patio (West Conch St: x = -17.0..-21.4, z = 10.0..14.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.4, 0.04, 4.0), Vector3(-19.2, 0.02, 12.0), plaza_pave)
	ModelBuilder3D.add_box(roads_root, Vector3(4.4, 0.06, 0.25), Vector3(-19.2, 0.035, 9.875), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(4.4, 0.06, 0.25), Vector3(-19.2, 0.035, 14.125), curb_stone)
	
	# Sandy's Treedome Wooden Boardwalk Pier (East District: x = 17.0..21.8, z = -7.0..-3.0)
	ModelBuilder3D.add_box(roads_root, Vector3(4.8, 0.04, 4.0), Vector3(19.4, 0.02, -5.0), boardwalk_timber)
	ModelBuilder3D.add_box(roads_root, Vector3(4.8, 0.12, 0.22), Vector3(19.4, 0.07, -7.11), boardwalk_rail)
	ModelBuilder3D.add_box(roads_root, Vector3(4.8, 0.12, 0.22), Vector3(19.4, 0.07, -2.89), boardwalk_rail)
	for bi in range(3):
		ModelBuilder3D.add_cylinder(roads_root, 0.10, 0.12, 0.38, Vector3(17.7 + bi * 1.7, 0.19, -7.11), boardwalk_rail)
		ModelBuilder3D.add_cylinder(roads_root, 0.10, 0.12, 0.38, Vector3(17.7 + bi * 1.7, 0.19, -2.89), boardwalk_rail)
		
	# Flying Dutchman Ghost Dock Pier (East District: x = 17.0..22.4, z = 1.5..5.5)
	ModelBuilder3D.add_box(roads_root, Vector3(5.4, 0.04, 4.0), Vector3(19.7, 0.02, 3.5), boardwalk_timber)
	ModelBuilder3D.add_box(roads_root, Vector3(5.4, 0.12, 0.22), Vector3(19.7, 0.07, 1.39), boardwalk_rail)
	ModelBuilder3D.add_box(roads_root, Vector3(5.4, 0.12, 0.22), Vector3(19.7, 0.07, 5.61), boardwalk_rail)
	for bi in range(3):
		ModelBuilder3D.add_cylinder(roads_root, 0.10, 0.12, 0.38, Vector3(17.8 + bi * 1.9, 0.19, 1.39), boardwalk_rail)
		ModelBuilder3D.add_cylinder(roads_root, 0.10, 0.12, 0.38, Vector3(17.8 + bi * 1.9, 0.19, 5.61), boardwalk_rail)
		
	# Hall of Fame Marble Trophy Terrace (East District: x = 17.0..23.0, z = 10.0..14.0)
	ModelBuilder3D.add_box(roads_root, Vector3(6.0, 0.04, 4.0), Vector3(20.0, 0.02, 12.0), curb_stone)
	ModelBuilder3D.add_box(roads_root, Vector3(6.0, 0.08, 0.20), Vector3(20.0, 0.045, 9.9), star_gold)
	ModelBuilder3D.add_box(roads_root, Vector3(6.0, 0.08, 0.20), Vector3(20.0, 0.045, 14.1), star_gold)


