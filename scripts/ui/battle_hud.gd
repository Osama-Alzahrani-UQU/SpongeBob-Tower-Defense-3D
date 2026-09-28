extends CanvasLayer

## BattleHUD - Screen-Bounded 3D Tactical Overlay, Loadout Dock, and Unit Inspector

@onready var battle_ctrl = get_parent()

# Top Bar
@onready var top_bar: Panel = $TopBar
@onready var top_hbox: HBoxContainer = $TopBar/HBox
@onready var hp_label: Label = $TopBar/HBox/HPLabel
@onready var hp_bar: ProgressBar = $TopBar/HBox/HPBar
@onready var cash_label: Label = $TopBar/HBox/CashLabel
@onready var wave_label: Label = $TopBar/HBox/WaveLabel
@onready var speed_btn: Button = $TopBar/HBox/SpeedBtn
@onready var start_wave_btn: Button = $TopBar/HBox/StartWaveBtn
@onready var lobby_btn: Button = $TopBar/HBox/LobbyBtn

# Bottom Placement Bar
@onready var bottom_bar: Panel = $BottomBar
@onready var tower_buttons_container: HBoxContainer = $BottomBar/HBox

# Side Inspector Panel
@onready var inspector_panel: Panel = $InspectorPanel
@onready var tower_name_label: Label = $InspectorPanel/VBox/TowerName
@onready var trait_label: Label = $InspectorPanel/VBox/TraitLabel
@onready var stats_label: Label = $InspectorPanel/VBox/StatsLabel
@onready var target_mode_btn: Button = $InspectorPanel/VBox/TargetModeBtn
@onready var upgrade_btn: Button = $InspectorPanel/VBox/UpgradeBtn
@onready var sell_btn: Button = $InspectorPanel/VBox/SellBtn
@onready var close_inspector_btn: Button = $InspectorPanel/VBox/CloseBtn

# End Game Dialog
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/VBox/TitleLabel
@onready var game_over_desc: Label = $GameOverPanel/VBox/DescLabel
@onready var game_over_btn: Button = $GameOverPanel/VBox/LobbyBtn

# Placement Warning Toast Banner
var warning_banner: Panel = null
var warning_label: Label = null
var warning_tween: Tween = null

# Wave Auto-Skip Countdown Banner & Action Buttons
var wave_countdown_banner: Panel = null
var countdown_timer_label: Label = null
var countdown_skip_btn: Button = null
var countdown_wait_btn: Button = null
var countdown_anim_tween: Tween = null

var speeds = [1.0, 2.0, 3.0]
var current_speed_idx = 0

func _ready() -> void:
	_apply_battle_hud_theme()
	_setup_wave_countdown_banner()
	_setup_warning_banner()
	
	battle_ctrl.base_hp_changed.connect(_on_hp_changed)
	battle_ctrl.cash_changed.connect(_on_cash_changed)
	battle_ctrl.wave_started.connect(_on_wave_started)
	battle_ctrl.wave_completed.connect(_on_wave_completed)
	battle_ctrl.game_over.connect(_on_game_over)
	if battle_ctrl.has_signal("enemy_killed_updated"):
		battle_ctrl.enemy_killed_updated.connect(_on_enemy_killed_updated)
	if battle_ctrl.has_signal("wave_countdown_started"):
		battle_ctrl.wave_countdown_started.connect(show_wave_countdown)
	if battle_ctrl.has_signal("wave_countdown_updated"):
		battle_ctrl.wave_countdown_updated.connect(update_wave_countdown)
	if battle_ctrl.has_signal("wave_countdown_cancelled"):
		battle_ctrl.wave_countdown_cancelled.connect(hide_wave_countdown)
	
	speed_btn.pressed.connect(_on_speed_pressed)
	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	lobby_btn.pressed.connect(_on_lobby_pressed)
	
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	sell_btn.pressed.connect(_on_sell_pressed)
	target_mode_btn.pressed.connect(_on_target_mode_pressed)
	close_inspector_btn.pressed.connect(_on_close_inspector)
	game_over_btn.pressed.connect(_on_lobby_pressed)
	
	inspector_panel.visible = false
	game_over_panel.visible = false
	
	_populate_tower_placement_bar()
	PlayerData.loadout_changed.connect(_populate_tower_placement_bar)
	_update_hud_labels()

func _apply_battle_hud_theme() -> void:
	UIThemeBuilder.enforce_ltr_recursive(self)
	
	# Floating Top Tactical Bar inside screen margins (x=16..1264, y=10..60)
	var top_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.12, 0.22, 0.96), Color(0.25, 0.78, 1.0), 18, 2, 0, 12, 6)
	top_bar.clip_contents = false
	top_bar.add_theme_stylebox_override("panel", top_sb)
	UIThemeBuilder.place_rect(top_bar, 16.0, 10.0, 1248.0, 50.0)
	UIThemeBuilder.fit_inner_container(top_bar, top_hbox, 16.0, 4.0)
	top_hbox.add_theme_constant_override("separation", 16)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	UIThemeBuilder.style_label(hp_label, 15, Color(0.35, 0.96, 0.55), 3)
	UIThemeBuilder.style_progress_bar(hp_bar, Color(0.22, 0.90, 0.46))
	hp_bar.custom_minimum_size = Vector2(125, 16)
	UIThemeBuilder.style_label(cash_label, 16, Color(1.0, 0.86, 0.22), 3)
	UIThemeBuilder.style_label(wave_label, 16, Color(0.45, 0.90, 1.0), 3)
	
	speed_btn.custom_minimum_size = Vector2(96, 34)
	start_wave_btn.custom_minimum_size = Vector2(130, 36)
	lobby_btn.custom_minimum_size = Vector2(105, 34)
	UIThemeBuilder.style_button(speed_btn, "nav", 13)
	UIThemeBuilder.style_button(start_wave_btn, "action", 14)
	UIThemeBuilder.style_button(lobby_btn, "primary", 13)
	speed_btn.text = "⏩ 1x Speed"
	start_wave_btn.text = "⚔️ START WAVE"
	lobby_btn.text = "🏠 Lobby"
	
	# Centered Bottom Loadout Dock (strictly inside screen margins: x=290..990, y=582..708)
	var bot_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.12, 0.22, 0.96), Color(1.0, 0.82, 0.22), 20, 2, 0, 14, 8)
	bottom_bar.clip_contents = false
	bottom_bar.add_theme_stylebox_override("panel", bot_sb)
	UIThemeBuilder.place_rect(bottom_bar, 290.0, 582.0, 700.0, 126.0)
	UIThemeBuilder.fit_inner_container(bottom_bar, tower_buttons_container, 14.0, 6.0)
	tower_buttons_container.add_theme_constant_override("separation", 12)
	
	# Right-Side Tactical Unit Inspector (smooth 18px rounded corners, zero clip_contents artifacts, x=1012..1264, y=136..520)
	var insp_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.12, 0.22, 0.98), Color(0.28, 0.85, 1.0), 18, 3, 0, 14, 12)
	inspector_panel.clip_contents = false
	inspector_panel.add_theme_stylebox_override("panel", insp_sb)
	UIThemeBuilder.place_rect(inspector_panel, 1012.0, 136.0, 252.0, 384.0)
	
	var insp_vbox: VBoxContainer = $InspectorPanel/VBox
	UIThemeBuilder.fit_inner_container(inspector_panel, insp_vbox, 16.0, 16.0)
	insp_vbox.add_theme_constant_override("separation", 6)
	
	tower_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tower_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeBuilder.style_label(tower_name_label, 15, Color(1.0, 0.88, 0.25), 3)
	UIThemeBuilder.style_label(trait_label, 12, Color(0.38, 0.92, 1.0), 2)
	UIThemeBuilder.style_label(stats_label, 13, Color(0.92, 0.97, 1.0), 2)
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	for b in [target_mode_btn, upgrade_btn, sell_btn, close_inspector_btn]:
		b.custom_minimum_size = Vector2(0, 32)
	UIThemeBuilder.style_button(target_mode_btn, "nav", 12)
	UIThemeBuilder.style_button(upgrade_btn, "success", 13)
	UIThemeBuilder.style_button(sell_btn, "danger", 12)
	UIThemeBuilder.style_button(close_inspector_btn, "primary", 12)
	close_inspector_btn.text = "✖ Deselect"
	
	# Game Over Modal
	UIThemeBuilder.style_modal(game_over_panel, Color(1.0, 0.82, 0.22), Vector2(540, 290))
	UIThemeBuilder.fit_inner_container(game_over_panel, $GameOverPanel/VBox, 18.0, 14.0)
	$GameOverPanel/VBox.add_theme_constant_override("separation", 8)
	UIThemeBuilder.style_label(game_over_title, 18, Color(1.0, 0.88, 0.22), 4)
	UIThemeBuilder.style_label(game_over_desc, 13, Color(0.9, 0.96, 1.0), 3)
	game_over_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeBuilder.style_button(game_over_btn, "primary", 14)

func _setup_wave_countdown_banner() -> void:
	if wave_countdown_banner:
		return
	wave_countdown_banner = Panel.new()
	wave_countdown_banner.name = "WaveCountdownBanner"
	var sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.14, 0.26, 0.98), Color(0.25, 0.85, 1.0), 16, 2, 0, 12, 6)
	wave_countdown_banner.add_theme_stylebox_override("panel", sb)
	UIThemeBuilder.place_rect(wave_countdown_banner, 320.0, 66.0, 640.0, 50.0)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	wave_countdown_banner.add_child(hbox)
	UIThemeBuilder.fit_inner_container(wave_countdown_banner, hbox, 14.0, 4.0)
	
	countdown_timer_label = Label.new()
	countdown_timer_label.name = "TimerLabel"
	countdown_timer_label.text = "⏱️ Next Wave in: 10s"
	UIThemeBuilder.style_label(countdown_timer_label, 15, Color(1.0, 0.88, 0.28), 3)
	hbox.add_child(countdown_timer_label)
	
	countdown_skip_btn = Button.new()
	countdown_skip_btn.name = "SkipBtn"
	countdown_skip_btn.text = "⏩ Skip Now"
	countdown_skip_btn.custom_minimum_size = Vector2(120, 36)
	UIThemeBuilder.style_button(countdown_skip_btn, "action", 13)
	UIThemeBuilder.bind_button_anim(countdown_skip_btn)
	countdown_skip_btn.pressed.connect(func():
		if battle_ctrl:
			battle_ctrl.skip_to_next_wave()
	)
	hbox.add_child(countdown_skip_btn)
	
	countdown_wait_btn = Button.new()
	countdown_wait_btn.name = "WaitBtn"
	countdown_wait_btn.text = "⏳ Wait +10s"
	countdown_wait_btn.custom_minimum_size = Vector2(125, 36)
	UIThemeBuilder.style_button(countdown_wait_btn, "nav", 13)
	UIThemeBuilder.bind_button_anim(countdown_wait_btn)
	countdown_wait_btn.pressed.connect(func():
		if battle_ctrl:
			battle_ctrl.extend_wave_countdown(10.0)
	)
	hbox.add_child(countdown_wait_btn)
	
	wave_countdown_banner.visible = false
	wave_countdown_banner.modulate.a = 0.0
	wave_countdown_banner.pivot_offset = Vector2(320.0, 25.0)
	add_child(wave_countdown_banner)

func show_wave_countdown(duration: float = 10.0) -> void:
	if not wave_countdown_banner:
		_setup_wave_countdown_banner()
	update_wave_countdown(duration)
	
	if countdown_anim_tween and countdown_anim_tween.is_valid():
		countdown_anim_tween.kill()
		
	wave_countdown_banner.visible = true
	wave_countdown_banner.scale = Vector2(0.85, 0.85)
	wave_countdown_banner.modulate.a = 0.0
	
	countdown_anim_tween = create_tween()
	countdown_anim_tween.set_parallel(true)
	countdown_anim_tween.tween_property(wave_countdown_banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	countdown_anim_tween.tween_property(wave_countdown_banner, "modulate:a", 1.0, 0.18)

func update_wave_countdown(seconds: float) -> void:
	if countdown_timer_label:
		var s_int = int(ceilf(maxf(0.0, seconds)))
		countdown_timer_label.text = "⏱️ Next Wave in: %ds" % s_int
		if s_int <= 3:
			countdown_timer_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			countdown_timer_label.modulate = Color(1.0, 0.88, 0.28)

func on_countdown_extended(_extra_seconds: float, new_total: float) -> void:
	update_wave_countdown(new_total)
	if countdown_wait_btn:
		var tw = create_tween()
		tw.tween_property(countdown_wait_btn, "scale", Vector2(1.15, 1.15), 0.08)
		tw.tween_property(countdown_wait_btn, "scale", Vector2.ONE, 0.12)
	show_placement_warning("⏳ Next wave postponed +10 seconds!")

func hide_wave_countdown() -> void:
	if not wave_countdown_banner or not wave_countdown_banner.visible:
		return
	if countdown_anim_tween and countdown_anim_tween.is_valid():
		countdown_anim_tween.kill()
	countdown_anim_tween = create_tween()
	countdown_anim_tween.set_parallel(true)
	countdown_anim_tween.tween_property(wave_countdown_banner, "scale", Vector2(0.9, 0.9), 0.15)
	countdown_anim_tween.tween_property(wave_countdown_banner, "modulate:a", 0.0, 0.15)
	countdown_anim_tween.chain().tween_callback(func():
		if is_instance_valid(wave_countdown_banner):
			wave_countdown_banner.visible = false
	)

func _setup_warning_banner() -> void:
	if warning_banner:
		return
	warning_banner = Panel.new()
	warning_banner.name = "WarningBanner"
	var sb = UIThemeBuilder.make_panel_style(Color(0.18, 0.03, 0.05, 0.96), Color(1.0, 0.28, 0.28), 14, 2, 0, 16, 6)
	warning_banner.add_theme_stylebox_override("panel", sb)
	UIThemeBuilder.place_rect(warning_banner, 350.0, 120.0, 580.0, 42.0)
	
	warning_label = Label.new()
	warning_label.name = "WarningLabel"
	warning_label.text = "🚫 Cannot place unit here!"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(warning_label, 15, Color(1.0, 0.90, 0.40), 3)
	warning_banner.add_child(warning_label)
	UIThemeBuilder.fit_inner_container(warning_banner, warning_label, 10.0, 4.0)
	
	warning_banner.visible = false
	warning_banner.modulate.a = 0.0
	warning_banner.pivot_offset = Vector2(290.0, 21.0)
	add_child(warning_banner)

func show_placement_warning(msg: String) -> void:
	if not warning_banner:
		_setup_warning_banner()
	if warning_label:
		warning_label.text = msg
		
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
		
	warning_banner.visible = true
	warning_banner.scale = Vector2(0.85, 0.85)
	warning_banner.modulate.a = 0.0
	
	warning_tween = create_tween()
	warning_tween.set_parallel(true)
	warning_tween.tween_property(warning_banner, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	warning_tween.tween_property(warning_banner, "modulate:a", 1.0, 0.15)
	
	var hide_tw = warning_banner.create_tween()
	hide_tw.tween_interval(2.2)
	hide_tw.tween_property(warning_banner, "modulate:a", 0.0, 0.35)
	hide_tw.tween_callback(func():
		if is_instance_valid(warning_banner):
			warning_banner.visible = false
	)

func _update_hud_labels() -> void:
	hp_bar.value = battle_ctrl.base_hp
	hp_label.text = "❤️ HP: %d/%d" % [battle_ctrl.base_hp, battle_ctrl.MAX_BASE_HP]
	cash_label.text = "💵 $%d" % battle_ctrl.cash
	if battle_ctrl.get("is_infinity_mode") or PlayerData.current_battle_mode == "infinity":
		wave_label.text = "♾️ Wave %d/∞ • 💀 %d" % [battle_ctrl.current_wave, battle_ctrl.killed_bots_total]
	else:
		var st_id: int = PlayerData.selected_stage_id
		var st_info: Dictionary = GameData.get_stage(st_id)
		wave_label.text = "⭐ Lvl %d: %s • Wave %d/%d" % [st_id, st_info.get("name", ""), battle_ctrl.current_wave, battle_ctrl.max_waves]
	_update_placement_cards_affordability()

func _populate_tower_placement_bar() -> void:
	for child in tower_buttons_container.get_children():
		child.queue_free()
		
	var equipped = PlayerData.get_equipped_towers()
	if equipped.is_empty():
		equipped = [
			{"tower_id": "spongebob", "level": 1, "trait_id": "none"},
			{"tower_id": "patrick", "level": 1, "trait_id": "none"},
			{"tower_id": "squidward", "level": 1, "trait_id": "none"},
			{"tower_id": "mr_krabs", "level": 1, "trait_id": "none"}
		]
		
	for unit in equipped:
		var t_id = unit["tower_id"]
		var data = GameData.TOWERS.get(t_id, {})
		var cost = data.get("cost", 100)
		var card = UIThemeBuilder.create_unit_card(
			t_id,
			unit.get("level", 1),
			unit.get("trait_id", "none"),
			false,
			cost,
			Vector2(112, 114)
		)
		card.set_meta("tower_id", t_id)
		card.set_meta("placement_cost", cost)
		card.pressed.connect(func(): _on_select_placement_tower(t_id))
		tower_buttons_container.add_child(card)
		
	_update_placement_cards_affordability()

func _update_placement_cards_affordability() -> void:
	var cur_cash = battle_ctrl.cash if battle_ctrl else 0
	var sel_tid = battle_ctrl.selected_tower_to_place if battle_ctrl else ""
	for card in tower_buttons_container.get_children():
		if not is_instance_valid(card):
			continue
		var t_id: String = card.get_meta("tower_id", "")
		var cost: int = card.get_meta("placement_cost", 100)
		var can_afford: bool = (cur_cash >= cost)
		var is_armed: bool = (sel_tid != "" and sel_tid == t_id)
		
		var cost_badge: PanelContainer = card.get_node_or_null("CostBadge")
		var cost_lbl: Label = card.get_node_or_null("CostBadge/CostHBox/CostLabel") if cost_badge else null
		var cost_icon: Label = card.get_node_or_null("CostBadge/CostHBox/Label") if cost_badge else null
		
		if can_afford:
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if cost_badge:
				var ok_sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.12, 0.08, 0.98), Color(0.35, 1.0, 0.55), 10, 2, 0, 4, 1)
				cost_badge.add_theme_stylebox_override("panel", ok_sb)
			if cost_lbl:
				cost_lbl.text = "$%d" % cost
				UIThemeBuilder.style_label(cost_lbl, 11, Color(1.0, 0.92, 0.35), 3)
			if cost_icon:
				cost_icon.text = "💵"
		else:
			card.modulate = Color(0.85, 0.85, 0.85, 0.92)
			if cost_badge:
				var no_sb = UIThemeBuilder.make_panel_style(Color(0.18, 0.04, 0.06, 0.98), Color(1.0, 0.35, 0.35), 10, 2, 0, 4, 1)
				cost_badge.add_theme_stylebox_override("panel", no_sb)
			if cost_lbl:
				cost_lbl.text = "$%d" % cost
				UIThemeBuilder.style_label(cost_lbl, 11, Color(1.0, 0.55, 0.55), 3)
			if cost_icon:
				cost_icon.text = "🔒"
				
		card.pivot_offset = card.size * 0.5
		if is_armed:
			card.scale = Vector2(1.06, 1.06)
		else:
			card.scale = Vector2.ONE

func _on_select_placement_tower(t_id: String) -> void:
	if battle_ctrl.selected_tower_to_place == t_id:
		battle_ctrl.set_selected_tower_to_place("")
	else:
		battle_ctrl.set_selected_tower_to_place(t_id)
	_update_placement_cards_affordability()

func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.value = hp
	hp_label.text = "❤️ HP: %d/%d" % [hp, max_hp]

func _on_cash_changed(cash: int) -> void:
	cash_label.text = "💵 $%d" % cash
	_update_inspector()
	_update_placement_cards_affordability()

func _on_wave_started(wave: int) -> void:
	if battle_ctrl.get("is_infinity_mode"):
		wave_label.text = "♾️ Wave %d/∞ • 💀 %d" % [wave, battle_ctrl.killed_bots_total]
	else:
		wave_label.text = "🌊 Wave %d/%d" % [wave, battle_ctrl.max_waves]
	start_wave_btn.disabled = true
	start_wave_btn.text = "⚔️ ACTIVE"

func _on_enemy_killed_updated(_total_kills: int) -> void:
	if battle_ctrl.get("is_infinity_mode"):
		wave_label.text = "♾️ Wave %d/∞ • 💀 %d" % [battle_ctrl.current_wave, battle_ctrl.killed_bots_total]

func _on_wave_completed(_wave: int) -> void:
	start_wave_btn.disabled = false
	start_wave_btn.text = "⚔️ NEXT WAVE"
	_update_hud_labels()

func _on_speed_pressed() -> void:
	current_speed_idx = (current_speed_idx + 1) % speeds.size()
	var spd = speeds[current_speed_idx]
	speed_btn.text = "⏩ %dx Speed" % int(spd)
	battle_ctrl.set_game_speed(spd)

func _on_start_wave_pressed() -> void:
	battle_ctrl.start_next_wave()

func _on_lobby_pressed() -> void:
	battle_ctrl.return_to_lobby()

var _last_inspected_tower: Node3D = null

func _process(_delta: float) -> void:
	if battle_ctrl.selected_active_tower != _last_inspected_tower:
		_last_inspected_tower = battle_ctrl.selected_active_tower
		if _last_inspected_tower:
			_show_inspector(_last_inspected_tower)
		else:
			inspector_panel.visible = false

func _show_inspector(tower: Node3D) -> void:
	_update_inspector_details(tower)
	if not inspector_panel.visible:
		UIThemeBuilder.animate_modal_open(inspector_panel)

func _update_inspector() -> void:
	if battle_ctrl.selected_active_tower:
		_update_inspector_details(battle_ctrl.selected_active_tower)

func _update_inspector_details(tower: Node3D) -> void:
	var data = GameData.TOWERS.get(tower.tower_id, {})
	var trait_data = GameData.TRAITS.get(tower.trait_id, GameData.TRAITS["none"])
	var p_class = tower.get("power_class") if "power_class" in tower else data.get("power_class", "control")
	
	if p_class == "economy":
		tower_name_label.text = "💰 %s (Lv.%d)" % [data.get("name", ""), tower.unit_level]
		trait_label.text = "🧬 Trait: [%s]\n🏦 Role: Dedicated Bank" % trait_data.get("name", "None")
		stats_label.text = "💵 Wave Income: +$%d\n🪙 Total Made: $%d\n🎯 Range: %.1fm\n🚫 Dedicated Cash Generator" % [
			tower.current_income if "current_income" in tower else 0,
			tower.total_cash_generated if "total_cash_generated" in tower else 0,
			tower.current_range
		]
		target_mode_btn.disabled = true
		target_mode_btn.text = "🏦 Role: Dedicated Bank"
	else:
		target_mode_btn.disabled = false
		target_mode_btn.text = "🎯 Target: %s" % tower.targeting_mode
		
		var perk_name = ""
		match p_class:
			"control": perk_name = "❄️ Freeze Stun & Slow"
			"brawler": perk_name = "💥 25% Crit & Shred"
			"aoe": perk_name = "🎵 4.2m AoE & Field"
			"marksman": perk_name = "🎯 Hyper-Laser Stacks"
			"spectral": perk_name = "👻 Soul Burn & Boom"
			"cosmic": perk_name = "👑 Orbital Smite"
			_: perk_name = "⚔️ Tactical Strike"
			
		tower_name_label.text = "⭐ %s (Lv.%d)" % [data.get("name", ""), tower.unit_level]
		trait_label.text = "🧬 Trait: [%s]\n%s" % [trait_data.get("name", "None"), perk_name]
		
		var dps = tower.current_damage / maxf(0.01, tower.current_spa)
		stats_label.text = "🔥 DPS: %.1f\n⚔️ Dmg: %.1f | ⚡ SPD: %.2fs\n🎯 Rng: %.1fm | 💥 Hit: %.0f" % [
			dps, tower.current_damage, tower.current_spa, tower.current_range, tower.total_damage_dealt
		]
	
	var next_cost = tower.get_next_upgrade_cost()
	if next_cost > 0:
		upgrade_btn.disabled = (battle_ctrl.cash < next_cost)
		upgrade_btn.text = "⬆️ Upgrade ($%d)" % next_cost
	else:
		upgrade_btn.disabled = true
		upgrade_btn.text = "🌟 MAX UPGRADED"
		
	sell_btn.text = "💰 Sell (+$%d)" % tower.get_sell_value()

func _on_upgrade_pressed() -> void:
	battle_ctrl.upgrade_selected_tower()
	_update_inspector()

func _on_sell_pressed() -> void:
	battle_ctrl.sell_selected_tower()
	inspector_panel.visible = false

func _on_target_mode_pressed() -> void:
	if battle_ctrl.selected_active_tower:
		var modes = ["First", "Last", "Strongest", "Closest"]
		var idx = modes.find(battle_ctrl.selected_active_tower.targeting_mode)
		idx = (idx + 1) % modes.size()
		battle_ctrl.selected_active_tower.targeting_mode = modes[idx]
		target_mode_btn.text = "🎯 Target: %s" % modes[idx]

func _on_close_inspector() -> void:
	battle_ctrl.select_tower(null)
	inspector_panel.visible = false

func _on_game_over(victory: bool) -> void:
	UIThemeBuilder.animate_modal_open(game_over_panel)
	if battle_ctrl.get("is_infinity_mode"):
		var rw: Dictionary = battle_ctrl.last_infinity_rewards
		var kills: int = int(rw.get("total_kills", battle_ctrl.killed_bots_total))
		var wv: int = int(rw.get("wave_reached", battle_ctrl.current_wave))
		game_over_title.text = "♾️ INFINITY WAVES OVER — BASE DESTROYED!"
		game_over_title.modulate = Color(1.0, 0.78, 0.25)
		if kills > 0:
			var bonus_txt: String = ""
			if str(rw.get("bonus_unit", "")) != "":
				bonus_txt = "\n🎁 Bonus Unit Earned: [%s]!" % str(rw.get("bonus_unit", ""))
			game_over_desc.text = "Reached Wave %d • Defeated %d Enemy Bots!\nKilled-Bot Rewards: +🪙 %d Gold | +💎 %d Gems | +🎲 %d Dice | +⭐ %d XP%s" % [
				wv, kills, int(rw.get("gold", 0)), int(rw.get("gems", 0)), int(rw.get("dice", 0)), int(rw.get("xp", 0)), bonus_txt
			]
		else:
			game_over_desc.text = "Reached Wave %d • Defeated 0 Enemy Bots.\nNo bots killed — defeat enemy bots to earn Gold, Gems, Dice & Units!" % wv
	elif victory:
		var st_id: int = PlayerData.selected_stage_id
		var st_info: Dictionary = GameData.get_stage(st_id)
		var stars: int = 1
		if battle_ctrl.base_hp >= battle_ctrl.MAX_BASE_HP:
			stars = 3
		elif battle_ctrl.base_hp >= 50:
			stars = 2
		var stars_str := ""
		for s in range(stars):
			stars_str += "⭐"
		for s in range(3 - stars):
			stars_str += "☆"
		
		game_over_title.text = "🏆 %s CLEARED!" % str(st_info.get("name", "STAGE")).to_upper()
		game_over_title.modulate = Color(0.25, 0.98, 0.5)
		game_over_desc.text = "Stage %d • Rating: %s (%d/3 Stars)\nBase Health Remaining: %d/%d HP\nRewards: +🪙 %d Gold | +💎 %d Gems | +🎲 1 Dice!" % [
			st_id,
			stars_str,
			stars,
			battle_ctrl.base_hp,
			battle_ctrl.MAX_BASE_HP,
			int(st_info.get("reward_gold", 200)),
			int(st_info.get("reward_gems", 25))
		]
	else:
		var st_id: int = PlayerData.selected_stage_id
		var st_info: Dictionary = GameData.get_stage(st_id)
		game_over_title.text = "💥 DEFEAT — STAGE %d FAILED!" % st_id
		game_over_title.modulate = Color(1.0, 0.35, 0.35)
		game_over_desc.text = "The base was overrun in %s.\nUpgrade your units in the Lobby and try again!" % str(st_info.get("name", "Bikini Bottom"))

