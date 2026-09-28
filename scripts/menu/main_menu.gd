extends Node3D

## MainMenu - Vibrant 3D Undersea SpongeBob Tower Defense Main Menu

@onready var camera_3d: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD

# 3D Atmosphere & Decorations
var animated_bubbles: Array = []
var player_avatar: Node3D = null
var cam_time: float = 0.0
var spongebob_anim_time: float = 0.0

# 2D UI Controls
var top_bar: Panel = null
var title_box: VBoxContainer = null
var menu_container: VBoxContainer = null
var bottom_hint: Panel = null
var level_lbl: Label = null
var xp_bar: ProgressBar = null
var gold_lbl: Label = null
var gems_lbl: Label = null
var dice_lbl: Label = null
var afk_quick_btn: Button = null
var is_transitioning: bool = false

# Modals
var modal_backdrop: ColorRect = null
var afk_modal: Panel = null
var settings_modal: Panel = null
var infinity_select_modal: Panel = null
var credits_modal: Panel = null

func _ready() -> void:
	if AudioManager:
		AudioManager.play_bgm("main_menu")
	PlayerData.currencies_changed.connect(_update_currencies)
	PlayerData.afk_rewards_updated.connect(_on_afk_updated)
	
	_build_3d_undersea_world()
	_setup_main_menu_ui()
	_update_currencies()
	_update_afk_quick_pill()

func _build_3d_undersea_world() -> void:
	# 1. Environment & Lighting
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.28, 0.48)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.75, 0.95)
	env.ambient_light_energy = 1.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.35, 0.54)
	env.fog_density = 0.006
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.94, 0.98, 1.0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-42, 38, 0)
	add_child(sun)

	# 2. Seabed Sand Floor with procedural texture
	var floor_mesh := MeshInstance3D.new()
	var f_box := BoxMesh.new()
	f_box.size = Vector3(90.0, 0.6, 80.0)
	floor_mesh.mesh = f_box
	floor_mesh.position = Vector3(0, -0.3, 0)
	floor_mesh.material_override = ModelBuilder3D.get_seabed_sand_material()
	add_child(floor_mesh)

	# 3. 3D Bikini Bottom Landmarks Showcase in the Vista
	var landmarks := [
		{"type": "pineapple", "pos": Vector3(-7.5, 0.0, -4.0), "rot": Vector3(0, 35, 0), "scale": 1.15},
		{"type": "moai", "pos": Vector3(-13.5, 0.0, -1.0), "rot": Vector3(0, 55, 0), "scale": 1.0},
		{"type": "rock", "pos": Vector3(-18.5, 0.0, 2.5), "rot": Vector3(0, 70, 0), "scale": 1.05},
		{"type": "krustykrab", "pos": Vector3(8.5, 0.0, -8.0), "rot": Vector3(0, -25, 0), "scale": 0.85},
		{"type": "treedome", "pos": Vector3(14.5, 0.0, -2.0), "rot": Vector3(0, -50, 0), "scale": 0.88}
	]

	var vista_root := Node3D.new()
	vista_root.name = "VistaLandmarks"
	add_child(vista_root)

	for lm in landmarks:
		var model = ModelBuilder3D.build_landmark_model(lm["type"])
		model.position = lm["pos"]
		model.rotation_degrees = lm["rot"]
		var sc: float = float(lm["scale"])
		model.scale = Vector3(sc, sc, sc)
		vista_root.add_child(model)

	# 4. Animated 3D SpongeBob Avatar Greeting the Player
	player_avatar = ModelBuilder3D.build_player_spongebob_model()
	player_avatar.position = Vector3(2.6, 0.0, 2.2)
	player_avatar.scale = Vector3(1.35, 1.35, 1.35)
	player_avatar.rotation_degrees = Vector3(0, -28, 0)
	add_child(player_avatar)

	# 5. Rising 3D Sea Bubbles
	var bubble_mat = ModelBuilder3D.make_mat(Color(0.85, 0.95, 1.0), 0.1, 0.2, Color(0.4, 0.85, 1.0) * 1.2, 0.55)
	for i in range(32):
		var b_mesh := MeshInstance3D.new()
		var s := SphereMesh.new()
		var r := randf_range(0.12, 0.38)
		s.radius = r
		s.height = r * 2.0
		b_mesh.mesh = s
		var bx := randf_range(-24.0, 24.0)
		var bz := randf_range(-16.0, 16.0)
		var by := randf_range(0.4, 14.0)
		b_mesh.position = Vector3(bx, by, bz)
		b_mesh.material_override = bubble_mat
		add_child(b_mesh)
		animated_bubbles.append({
			"node": b_mesh,
			"speed": randf_range(0.9, 2.4),
			"base_x": bx,
			"base_z": bz,
			"wobble": randf() * 6.28
		})

	# 6. Sky Flower Clouds
	var flower_colors = [Color(0.4, 0.7, 0.95, 0.45), Color(0.9, 0.5, 0.7, 0.4), Color(0.5, 0.9, 0.6, 0.4), Color(1.0, 0.75, 0.3, 0.4)]
	for i in range(6):
		var fl_root := Node3D.new()
		var f_col: Color = flower_colors[i % flower_colors.size()]
		var f_mat = ModelBuilder3D.make_mat(f_col, 0.5, 0.0, f_col * 0.4, 0.42)
		for p in range(5):
			var a := float(p) * (360.0 / 5.0)
			var rad := deg_to_rad(a)
			var petal := MeshInstance3D.new()
			var p_sphere := SphereMesh.new()
			p_sphere.radius = 1.35
			p_sphere.height = 0.65
			petal.mesh = p_sphere
			petal.material_override = f_mat
			petal.position = Vector3(sin(rad) * 1.6, 0, cos(rad) * 1.6)
			fl_root.add_child(petal)
		var fx := -26.0 + (float(i) * 11.0)
		var fz := -20.0 - (float(i % 2) * 4.0)
		fl_root.position = Vector3(fx, 15.0 + (float(i) * 0.9), fz)
		fl_root.rotation_degrees = Vector3(40, 15.0 * float(i), 0)
		add_child(fl_root)

	# 7. Initial Camera Framing
	if camera_3d:
		camera_3d.position = Vector3(0.0, 3.8, 8.8)
		camera_3d.look_at(Vector3(-1.5, 2.2, 0.0), Vector3.UP)

func _setup_main_menu_ui() -> void:
	UIThemeBuilder.enforce_ltr_recursive(hud)

	# 1. Top Bar Profile & Currencies Header (x=16, y=10, w=1248, h=52)
	top_bar = Panel.new()
	top_bar.name = "TopBar"
	top_bar.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.03, 0.10, 0.18, 0.92), Color(0.24, 0.78, 0.98), 16, 2, 0, 14, 4)
	)
	hud.add_child(top_bar)
	UIThemeBuilder.place_rect(top_bar, 16.0, 10.0, 1248.0, 52.0)

	var top_hbox := HBoxContainer.new()
	top_hbox.name = "HBox"
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 18)
	top_bar.add_child(top_hbox)
	UIThemeBuilder.fit_inner_container(top_bar, top_hbox, 16.0, 4.0)

	# Player Avatar Icon & Level
	var profile_hbox := HBoxContainer.new()
	profile_hbox.add_theme_constant_override("separation", 8)
	top_hbox.add_child(profile_hbox)

	var avatar_icon := TextureRect.new()
	avatar_icon.custom_minimum_size = Vector2(38, 38)
	avatar_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/spongebob.svg"):
		avatar_icon.texture = load("res://assets/spongebob.svg")
	profile_hbox.add_child(avatar_icon)

	var name_lbl := Label.new()
	name_lbl.text = "SPONGEBOB (YOU)"
	UIThemeBuilder.style_label(name_lbl, 14, Color(1.0, 0.92, 0.35), 3)
	profile_hbox.add_child(name_lbl)

	level_lbl = Label.new()
	level_lbl.text = "⭐ Lv.15"
	UIThemeBuilder.style_label(level_lbl, 14, Color(0.35, 0.95, 0.85), 3)
	profile_hbox.add_child(level_lbl)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(100, 14)
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.show_percentage = false
	var xp_bg = UIThemeBuilder.make_pill_style(Color(0.08, 0.16, 0.25), Color(0.2, 0.5, 0.7), 7)
	var xp_fg = UIThemeBuilder.make_pill_style(Color(0.2, 0.85, 0.55), Color(0.4, 1.0, 0.7), 7)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_bar.add_theme_stylebox_override("fill", xp_fg)
	profile_hbox.add_child(xp_bar)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	# AFK Quick Pill (clickable to open AFK modal directly)
	afk_quick_btn = Button.new()
	afk_quick_btn.name = "AfkQuickBtn"
	afk_quick_btn.text = "💤 AFK Bank: +0🪙 [Claim]"
	afk_quick_btn.custom_minimum_size = Vector2(210, 36)
	UIThemeBuilder.style_button(afk_quick_btn, "gold", 12)
	UIThemeBuilder.bind_button_anim(afk_quick_btn)
	afk_quick_btn.pressed.connect(_open_afk_modal)
	top_hbox.add_child(afk_quick_btn)

	# Currencies Pill
	var cur_panel := PanelContainer.new()
	cur_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_pill_style(Color(0.02, 0.08, 0.15, 0.95), Color(0.22, 0.75, 0.95), 16)
	)
	top_hbox.add_child(cur_panel)

	var cur_hbox := HBoxContainer.new()
	cur_hbox.add_theme_constant_override("separation", 14)
	cur_panel.add_child(cur_hbox)

	gold_lbl = Label.new()
	gold_lbl.text = "🪙 5000"
	UIThemeBuilder.style_label(gold_lbl, 14, Color(1.0, 0.88, 0.28), 3)
	cur_hbox.add_child(gold_lbl)

	gems_lbl = Label.new()
	gems_lbl.text = "💎 600"
	UIThemeBuilder.style_label(gems_lbl, 14, Color(0.85, 0.52, 1.0), 3)
	cur_hbox.add_child(gems_lbl)

	dice_lbl = Label.new()
	dice_lbl.text = "🎲 12"
	UIThemeBuilder.style_label(dice_lbl, 14, Color(0.35, 0.95, 0.75), 3)
	cur_hbox.add_child(dice_lbl)

	# 2. Grand SpongeBob Title Banner (Left-aligned or Center-left)
	title_box = VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override("separation", 4)
	hud.add_child(title_box)
	UIThemeBuilder.place_rect(title_box, 60.0, 85.0, 520.0, 185.0)

	var nick_lbl := Label.new()
	nick_lbl.text = "🌊 BIKINI BOTTOM TOWER DEFENSE 🌊"
	UIThemeBuilder.style_label(nick_lbl, 13, Color(0.35, 0.92, 1.0), 3)
	title_box.add_child(nick_lbl)

	var main_title := Label.new()
	main_title.text = "SPONGEBOB"
	UIThemeBuilder.style_label(main_title, 48, Color(1.0, 0.90, 0.15), 8)
	main_title.modulate = Color(1.0, 0.95, 0.25)
	title_box.add_child(main_title)

	var sub_title := Label.new()
	sub_title.text = "TOWER DEFENSE 3D"
	UIThemeBuilder.style_label(sub_title, 32, Color(0.18, 0.86, 0.48), 6)
	title_box.add_child(sub_title)

	var tag_lbl := Label.new()
	tag_lbl.text = "⚓ Defend the Secret Formula from Plankton's Robot Army! ⚓"
	UIThemeBuilder.style_label(tag_lbl, 12, Color(0.82, 0.92, 1.0), 2)
	title_box.add_child(tag_lbl)

	var ver_badge := Label.new()
	ver_badge.text = "⭐ Full 3D Edition • Continuous Global AFK • Infinity Waves ⭐"
	UIThemeBuilder.style_label(ver_badge, 11, Color(1.0, 0.82, 0.35), 2)
	title_box.add_child(ver_badge)

	# 3. Main Navigation Menu Buttons (Vertical Stack at x=60, y=278, w=360, h=370)
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuButtons"
	menu_container.add_theme_constant_override("separation", 8)
	hud.add_child(menu_container)
	UIThemeBuilder.place_rect(menu_container, 60.0, 278.0, 360.0, 370.0)

	# Play / Enter Lobby (Huge Primary Button)
	var play_btn := Button.new()
	play_btn.name = "PlayBtn"
	play_btn.text = "▶ ENTER BIKINI BOTTOM (LOBBY)"
	play_btn.custom_minimum_size = Vector2(360, 48)
	UIThemeBuilder.style_button(play_btn, "success", 16)
	UIThemeBuilder.bind_button_anim(play_btn)
	play_btn.pressed.connect(_on_play_pressed)
	menu_container.add_child(play_btn)

	# Infinite Waves Mode (Direct Challenge Launch)
	var inf_btn := Button.new()
	inf_btn.name = "InfinityBtn"
	inf_btn.text = "♾️ INFINITY WAVES (ENDLESS BATTLE)"
	inf_btn.custom_minimum_size = Vector2(360, 42)
	UIThemeBuilder.style_button(inf_btn, "purple", 13)
	UIThemeBuilder.bind_button_anim(inf_btn)
	inf_btn.pressed.connect(_on_infinity_pressed)
	menu_container.add_child(inf_btn)

	# Sandy's AFK Resort (Passive Harvester & Boost)
	var afk_btn := Button.new()
	afk_btn.name = "AfkResortBtn"
	afk_btn.text = "🐿️ SANDY'S AFK RESORT (PASSIVE REWARDS)"
	afk_btn.custom_minimum_size = Vector2(360, 42)
	UIThemeBuilder.style_button(afk_btn, "gold", 13)
	UIThemeBuilder.bind_button_anim(afk_btn)
	afk_btn.pressed.connect(_open_afk_modal)
	menu_container.add_child(afk_btn)

	# Settings & Secret Codes
	var settings_btn := Button.new()
	settings_btn.name = "SettingsBtn"
	settings_btn.text = "⚙️ SETTINGS & PROMO CODES"
	settings_btn.custom_minimum_size = Vector2(360, 40)
	UIThemeBuilder.style_button(settings_btn, "nav", 13)
	UIThemeBuilder.bind_button_anim(settings_btn)
	settings_btn.pressed.connect(_open_settings_modal)
	menu_container.add_child(settings_btn)

	# Official Credits & GitHub Ownership Button
	var credits_btn := Button.new()
	credits_btn.name = "CreditsBtn"
	credits_btn.text = "👑 CREDITS (Osama-Alzahrani-UQU)"
	credits_btn.custom_minimum_size = Vector2(360, 40)
	UIThemeBuilder.style_button(credits_btn, "gold", 13)
	UIThemeBuilder.bind_button_anim(credits_btn)
	credits_btn.pressed.connect(_open_credits_modal)
	menu_container.add_child(credits_btn)

	# Exit Game
	var quit_btn := Button.new()
	quit_btn.name = "QuitBtn"
	quit_btn.text = "🚪 QUIT GAME"
	quit_btn.custom_minimum_size = Vector2(360, 36)
	UIThemeBuilder.style_button(quit_btn, "danger", 12)
	UIThemeBuilder.bind_button_anim(quit_btn)
	quit_btn.pressed.connect(_on_quit_pressed)
	menu_container.add_child(quit_btn)

	# 4. Bottom Hint Bar (x=240, y=672, w=800, h=36)
	bottom_hint = Panel.new()
	bottom_hint.name = "BottomHint"
	bottom_hint.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_pill_style(Color(0.03, 0.10, 0.18, 0.92), Color(0.24, 0.78, 0.98), 16)
	)
	hud.add_child(bottom_hint)
	UIThemeBuilder.place_rect(bottom_hint, 240.0, 672.0, 800.0, 36.0)

	var hint_lbl := Label.new()
	hint_lbl.text = "🌊 Click [ENTER BIKINI BOTTOM] or Press [SPACE] to Explore the 3D City & Place Towers!"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(hint_lbl, 12, Color(0.85, 0.95, 1.0), 2)
	bottom_hint.add_child(hint_lbl)
	UIThemeBuilder.fit_inner_container(bottom_hint, hint_lbl, 16.0, 2.0)

	# 5. Modals Setup
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalBackdrop"
	modal_backdrop.color = Color(0.01, 0.04, 0.09, 0.75)
	modal_backdrop.visible = false
	hud.add_child(modal_backdrop)
	UIThemeBuilder.place_rect(modal_backdrop, 0.0, 0.0, 1280.0, 720.0)

	_setup_modals()

func _setup_modals() -> void:
	# AFK Modal Instance
	var afk_script = load("res://scripts/ui/afk_modal.gd")
	afk_modal = Panel.new()
	afk_modal.name = "AFKModal"
	afk_modal.visible = false
	afk_modal.set_script(afk_script)
	
	var afk_vbox := VBoxContainer.new()
	afk_vbox.name = "VBox"
	afk_modal.add_child(afk_vbox)
	
	var afk_title := Label.new()
	afk_title.name = "Title"
	afk_vbox.add_child(afk_title)
	
	var afk_gold := Label.new()
	afk_gold.name = "GoldAccumLbl"
	afk_vbox.add_child(afk_gold)
	
	var afk_gems := Label.new()
	afk_gems.name = "GemsAccumLbl"
	afk_vbox.add_child(afk_gems)
	
	var afk_claim := Button.new()
	afk_claim.name = "ClaimBtn"
	afk_vbox.add_child(afk_claim)
	
	var afk_close := Button.new()
	afk_close.name = "CloseBtn"
	afk_vbox.add_child(afk_close)
	
	hud.add_child(afk_modal)
	UIThemeBuilder.place_rect(afk_modal, 390.0, 170.0, 500.0, 380.0)
	UIThemeBuilder.fit_inner_container(afk_modal, afk_vbox, 20.0, 14.0)

	# Settings Modal Instance
	var settings_script = load("res://scripts/ui/settings_modal.gd")
	settings_modal = Panel.new()
	settings_modal.name = "SettingsModal"
	settings_modal.visible = false
	settings_modal.set_script(settings_script)
	
	var set_vbox := VBoxContainer.new()
	set_vbox.name = "VBox"
	settings_modal.add_child(set_vbox)
	
	var set_title := Label.new()
	set_title.name = "Title"
	set_vbox.add_child(set_title)
	
	var set_hbox := HBoxContainer.new()
	set_hbox.name = "SettingsHBox"
	set_vbox.add_child(set_hbox)
	
	var sfx_lbl := Label.new()
	sfx_lbl.name = "SFXLabel"
	sfx_lbl.text = "SFX Volume"
	set_hbox.add_child(sfx_lbl)
	
	var sfx_slider := HSlider.new()
	sfx_slider.name = "SFXSlider"
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_hbox.add_child(sfx_slider)
	
	var mus_lbl := Label.new()
	mus_lbl.name = "MusicLabel"
	mus_lbl.text = "Music Volume"
	set_hbox.add_child(mus_lbl)
	
	var mus_slider := HSlider.new()
	mus_slider.name = "MusicSlider"
	mus_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_hbox.add_child(mus_slider)
	
	var lag_chk := CheckBox.new()
	lag_chk.name = "LagCheck"
	lag_chk.text = "Lag Reducer"
	set_hbox.add_child(lag_chk)
	
	var codes_box := VBoxContainer.new()
	codes_box.name = "CodesBox"
	set_vbox.add_child(codes_box)
	
	var codes_hbox := HBoxContainer.new()
	codes_hbox.name = "HBox"
	codes_box.add_child(codes_hbox)
	
	var code_inp := LineEdit.new()
	code_inp.name = "CodeInput"
	code_inp.placeholder_text = "ENTER PROMO CODE (e.g. BIKINIBOTTOM)"
	codes_hbox.add_child(code_inp)
	
	var redeem_b := Button.new()
	redeem_b.name = "RedeemBtn"
	redeem_b.text = "Redeem"
	codes_hbox.add_child(redeem_b)
	
	var status_l := Label.new()
	status_l.name = "StatusLbl"
	codes_box.add_child(status_l)
	
	var lock_m := Label.new()
	lock_m.name = "LockMsg"
	codes_box.add_child(lock_m)
	
	var set_close := Button.new()
	set_close.name = "CloseBtn"
	set_vbox.add_child(set_close)
	
	hud.add_child(settings_modal)
	UIThemeBuilder.place_rect(settings_modal, 350.0, 130.0, 580.0, 460.0)
	UIThemeBuilder.fit_inner_container(settings_modal, set_vbox, 20.0, 16.0)

	# 7. Infinity Waves Map & Difficulty Selection Modal
	var inf_modal_script = load("res://scripts/ui/infinity_select_modal.gd")
	infinity_select_modal = Panel.new()
	infinity_select_modal.name = "InfinitySelectModal"
	infinity_select_modal.visible = false
	infinity_select_modal.set_script(inf_modal_script)
	hud.add_child(infinity_select_modal)
	infinity_select_modal.map_chosen.connect(func(theme_id: String):
		PlayerData.current_battle_mode = "infinity"
		PlayerData.selected_infinity_map = theme_id
		var map_names = {
			"outskirts": "OUTSKIRTS",
			"krusty_interior": "KRUSTY KRAB",
			"squidward_interior": "MOAI ART SALON"
		}
		var m_title: String = map_names.get(theme_id, "ARENA")
		_play_scene_transition("res://scenes/game/battle.tscn", "♾️ ENTERING INFINITY WAVES: %s... ♾️" % m_title)
	)

	# 8. Official Credits & Ownership Modal
	var credits_script = load("res://scripts/ui/credits_modal.gd")
	credits_modal = Panel.new()
	credits_modal.name = "CreditsModal"
	credits_modal.visible = false
	credits_modal.set_script(credits_script)
	hud.add_child(credits_modal)

func _process(delta: float) -> void:
	if not is_transitioning:
		cam_time += delta * 0.22
		spongebob_anim_time += delta * 3.5

		# Smooth Cinematic Camera Sway across Bikini Bottom Vista
		if camera_3d:
			camera_3d.position.x = sin(cam_time) * 1.8
			camera_3d.position.y = 3.8 + sin(cam_time * 1.5) * 0.25
			camera_3d.look_at(Vector3(-1.8 + sin(cam_time * 0.5) * 0.6, 2.2, 0.0), Vector3.UP)

		# SpongeBob Avatar Greeting Animation (enthusiastic wave on free left hand & proud spatula stance on right hand)
		if player_avatar:
			player_avatar.position.y = absf(sin(spongebob_anim_time * 0.8)) * 0.08
			# Left hand (free of spatula) waves high and clear on the left side
			if player_avatar.has_node("LeftArmPivot"):
				var wave := -1.35 + sin(spongebob_anim_time * 2.4) * 0.45
				player_avatar.get_node("LeftArmPivot").rotation.z = wave
				player_avatar.get_node("LeftArmPivot").rotation.x = -0.25
				player_avatar.get_node("LeftArmPivot").rotation.y = 0.0
			# Right hand holds spatula proudly outward to the side with subtle chef wrist bounce
			if player_avatar.has_node("RightArmPivot"):
				player_avatar.get_node("RightArmPivot").rotation.z = 0.24 # angled 14 degrees outward
				player_avatar.get_node("RightArmPivot").rotation.x = -0.28 + sin(spongebob_anim_time * 1.6) * 0.05
				player_avatar.get_node("RightArmPivot").rotation.y = -0.10

	# Animate Rising 3D Sea Bubbles (always active for undersea ambiance)
	for elem in animated_bubbles:
		var b: MeshInstance3D = elem["node"]
		b.position.y += elem["speed"] * delta
		elem["wobble"] += delta * 2.2
		b.position.x = elem["base_x"] + sin(elem["wobble"]) * 0.3
		b.position.z = elem["base_z"] + cos(elem["wobble"]) * 0.3
		if b.position.y > 14.0:
			b.position.y = 0.4

	# Update modal backdrop visibility
	if modal_backdrop:
		modal_backdrop.visible = (
			(afk_modal and afk_modal.visible)
			or (settings_modal and settings_modal.visible)
			or (infinity_select_modal and infinity_select_modal.visible)
			or (credits_modal and credits_modal.visible)
		)

func _update_currencies() -> void:
	if level_lbl:
		level_lbl.text = "⭐ Lv.%d" % PlayerData.level
	if xp_bar:
		xp_bar.max_value = PlayerData.get_xp_for_next_level()
		xp_bar.value = PlayerData.xp
	if gold_lbl:
		gold_lbl.text = "🪙 %d" % PlayerData.gold
	if gems_lbl:
		gems_lbl.text = "💎 %d" % PlayerData.gems
	if dice_lbl:
		dice_lbl.text = "🎲 %d" % PlayerData.reroll_dice

func _on_afk_updated(g: int, _gm: int, _xp: int) -> void:
	_update_afk_quick_pill()

func _update_afk_quick_pill() -> void:
	if afk_quick_btn:
		var stat := PlayerData.get_afk_status()
		afk_quick_btn.text = "💤 AFK Bank: +%d🪙 +%d💎 [CLAIM]" % [stat["gold"], stat["gems"]]

func _open_afk_modal() -> void:
	if is_transitioning:
		return
	if afk_modal:
		if AudioManager: AudioManager.play_sfx("ui_open")
		afk_modal.call("refresh_view")
		UIThemeBuilder.animate_modal_open(afk_modal)

func _open_settings_modal() -> void:
	if is_transitioning:
		return
	if settings_modal:
		if AudioManager: AudioManager.play_sfx("ui_open")
		settings_modal.call("refresh_view")
		UIThemeBuilder.animate_modal_open(settings_modal)

func _open_credits_modal() -> void:
	if is_transitioning:
		return
	if credits_modal:
		if AudioManager: AudioManager.play_sfx("ui_open")
		credits_modal.call("refresh_view")
		UIThemeBuilder.animate_modal_open(credits_modal)

func _on_play_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	_play_scene_transition("res://scenes/lobby/lobby.tscn", "🌊 DIVING INTO BIKINI BOTTOM... 🌊")

func _on_infinity_pressed() -> void:
	if is_transitioning:
		return
	if AudioManager: AudioManager.play_sfx("ui_click")
	if infinity_select_modal:
		infinity_select_modal.refresh_view()
		UIThemeBuilder.animate_modal_open(infinity_select_modal)
	else:
		PlayerData.current_battle_mode = "infinity"
		_play_scene_transition("res://scenes/game/battle.tscn", "♾️ ENTERING INFINITY WAVES ARENA... ♾️")

func _play_scene_transition(target_scene: String, banner_text: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if AudioManager:
		AudioManager.play_sfx("stage_enter")

	# 1. Overlay container blocking input
	var trans_overlay := Control.new()
	trans_overlay.name = "SceneTransitionOverlay"
	trans_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(trans_overlay)
	UIThemeBuilder.place_rect(trans_overlay, 0.0, 0.0, 1280.0, 720.0)

	# 2. Oceanic Blue Curtain
	var curtain := ColorRect.new()
	curtain.color = Color(0.03, 0.32, 0.58, 0.0)
	trans_overlay.add_child(curtain)
	UIThemeBuilder.place_rect(curtain, 0.0, 0.0, 1280.0, 720.0)

	# 3. Flurry of Rising 2D Sea Bubbles
	var bubble_container := Control.new()
	bubble_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trans_overlay.add_child(bubble_container)

	var bubble_data_list: Array = []
	for i in range(28):
		var b_panel := Panel.new()
		var b_sz := randf_range(32.0, 90.0)
		var sb := StyleBoxFlat.new()
		var r_rad := int(b_sz * 0.5)
		sb.corner_radius_top_left = r_rad
		sb.corner_radius_top_right = r_rad
		sb.corner_radius_bottom_left = r_rad
		sb.corner_radius_bottom_right = r_rad
		sb.bg_color = Color(0.65, 0.90, 1.0, randf_range(0.35, 0.70))
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(1.0, 1.0, 1.0, 0.85)
		b_panel.add_theme_stylebox_override("panel", sb)
		bubble_container.add_child(b_panel)

		var start_x := randf_range(20.0, 1240.0)
		var start_y := randf_range(720.0, 920.0)
		b_panel.position = Vector2(start_x, start_y)
		b_panel.size = Vector2(b_sz, b_sz)
		b_panel.modulate.a = 0.0
		bubble_data_list.append({
			"node": b_panel,
			"target_y": randf_range(-140.0, 150.0),
			"target_x": start_x + randf_range(-50.0, 50.0),
			"duration": randf_range(0.55, 0.88),
			"delay": randf_range(0.02, 0.22)
		})

	# 4. Center Nautical Banner
	var banner := Label.new()
	banner.text = banner_text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(banner, 26, Color(1.0, 0.92, 0.22), 6)
	banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	trans_overlay.add_child(banner)
	UIThemeBuilder.place_rect(banner, 140.0, 310.0, 1000.0, 80.0)

	# 5. Parallel Tween Animation
	var tw := create_tween().set_parallel(true)

	# Fade out 2D UI
	if top_bar:
		tw.tween_property(top_bar, "modulate:a", 0.0, 0.22)
	if title_box:
		tw.tween_property(title_box, "modulate:a", 0.0, 0.22)
	if menu_container:
		tw.tween_property(menu_container, "modulate:a", 0.0, 0.22)
	if bottom_hint:
		tw.tween_property(bottom_hint, "modulate:a", 0.0, 0.22)

	# SpongeBob Jump & Victory Cheer
	if player_avatar:
		tw.tween_property(player_avatar, "position:y", 1.85, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(player_avatar, "scale", Vector3(1.48, 1.48, 1.48), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(player_avatar, "rotation_degrees:y", -5.0, 0.45)
		if player_avatar.has_node("LeftArmPivot"):
			tw.tween_property(player_avatar.get_node("LeftArmPivot"), "rotation:z", -2.4, 0.4)
		if player_avatar.has_node("RightArmPivot"):
			tw.tween_property(player_avatar.get_node("RightArmPivot"), "rotation:z", 2.2, 0.4)
			tw.tween_property(player_avatar.get_node("RightArmPivot"), "rotation:x", -0.8, 0.4)

	# 3D Camera Swoop Forward into Bikini Bottom Vista
	if camera_3d:
		var forward_cam_pos := camera_3d.position + (camera_3d.transform.basis.z * -5.2) + Vector3(0, -1.0, 0)
		tw.tween_property(camera_3d, "position", forward_cam_pos, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade in curtain & nautical banner
	tw.tween_property(curtain, "color:a", 1.0, 0.65).set_delay(0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(banner, "modulate:a", 1.0, 0.35).set_delay(0.20)

	# Animate rising 2D bubbles
	for b_info in bubble_data_list:
		var b_ctrl: Panel = b_info["node"]
		var b_tw := create_tween().set_parallel(true)
		b_tw.tween_property(b_ctrl, "position:y", b_info["target_y"], b_info["duration"]).set_delay(b_info["delay"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		b_tw.tween_property(b_ctrl, "position:x", b_info["target_x"], b_info["duration"]).set_delay(b_info["delay"])
		b_tw.tween_property(b_ctrl, "modulate:a", 1.0, 0.18).set_delay(b_info["delay"])
		b_tw.tween_property(b_ctrl, "modulate:a", 0.0, 0.22).set_delay(b_info["delay"] + b_info["duration"] - 0.22)

	await get_tree().create_timer(0.92).timeout
	get_tree().change_scene_to_file(target_scene)

func _on_quit_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# 1. Overlay container blocking input
	var trans_overlay := Control.new()
	trans_overlay.name = "QuitTransitionOverlay"
	trans_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(trans_overlay)
	UIThemeBuilder.place_rect(trans_overlay, 0.0, 0.0, 1280.0, 720.0)

	# 2. Deep Undersea Midnight Blue Curtain
	var curtain := ColorRect.new()
	curtain.color = Color(0.015, 0.05, 0.12, 0.0)
	trans_overlay.add_child(curtain)
	UIThemeBuilder.place_rect(curtain, 0.0, 0.0, 1280.0, 720.0)

	# 3. Farewell Message Card
	var farewell_box := VBoxContainer.new()
	farewell_box.alignment = BoxContainer.ALIGNMENT_CENTER
	farewell_box.add_theme_constant_override("separation", 10)
	trans_overlay.add_child(farewell_box)
	UIThemeBuilder.place_rect(farewell_box, 140.0, 260.0, 1000.0, 200.0)

	var farewell_title := Label.new()
	farewell_title.text = "⚓ SEE YOU NEXT TIME IN BIKINI BOTTOM! ⚓"
	farewell_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(farewell_title, 28, Color(1.0, 0.88, 0.25), 8)
	farewell_box.add_child(farewell_title)

	var farewell_sub := Label.new()
	farewell_sub.text = "🧽 SpongeBob & the Krusty Krab crew salute you! Farewell, sailor! 🌊"
	farewell_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(farewell_sub, 16, Color(0.65, 0.90, 1.0), 4)
	farewell_box.add_child(farewell_sub)

	farewell_box.modulate.a = 0.0

	# 4. Parallel Tween Animation
	var tw := create_tween().set_parallel(true)

	# Fade out 2D UI
	if top_bar:
		tw.tween_property(top_bar, "modulate:a", 0.0, 0.25)
	if title_box:
		tw.tween_property(title_box, "modulate:a", 0.0, 0.25)
	if menu_container:
		tw.tween_property(menu_container, "modulate:a", 0.0, 0.25)
	if bottom_hint:
		tw.tween_property(bottom_hint, "modulate:a", 0.0, 0.25)

	# SpongeBob Farewell Bow and Goodbye Wave
	if player_avatar:
		tw.tween_property(player_avatar, "rotation_degrees:y", -18.0, 0.6)
		tw.tween_property(player_avatar, "rotation_degrees:x", 8.0, 0.6)
		if player_avatar.has_node("LeftArmPivot"):
			var arm_node: Node3D = player_avatar.get_node("LeftArmPivot")
			var arm_tw := create_tween()
			arm_tw.tween_property(arm_node, "rotation:z", -1.9, 0.25)
			arm_tw.tween_property(arm_node, "rotation:z", -1.1, 0.25)
			arm_tw.tween_property(arm_node, "rotation:z", -1.9, 0.25)

	# Camera tilts upward toward the surface sunlight
	if camera_3d:
		tw.tween_property(camera_3d, "position:y", camera_3d.position.y + 1.2, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera_3d, "rotation_degrees:x", camera_3d.rotation_degrees.x + 8.0, 0.95)

	# Fade in curtain & farewell card
	tw.tween_property(curtain, "color:a", 1.0, 0.80).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(farewell_box, "modulate:a", 1.0, 0.50).set_delay(0.22)

	await get_tree().create_timer(1.25).timeout
	get_tree().quit(0)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not (afk_modal and afk_modal.visible) and not (settings_modal and settings_modal.visible) and not (credits_modal and credits_modal.visible) and not (infinity_select_modal and infinity_select_modal.visible):
				_on_play_pressed()
		elif event.keycode == KEY_ESCAPE:
			if afk_modal and afk_modal.visible:
				afk_modal.visible = false
			elif settings_modal and settings_modal.visible:
				settings_modal.visible = false
			elif credits_modal and credits_modal.visible:
				credits_modal.visible = false
			elif infinity_select_modal and infinity_select_modal.visible:
				infinity_select_modal.visible = false
