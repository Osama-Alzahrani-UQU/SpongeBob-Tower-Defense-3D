extends Panel

## StageSelectModal - Interactive Campaign Expedition Stage Selector (Levels 1 to 15 Across 3 Distinct Undersea Zones)

signal stage_chosen(stage_id: int)

var current_zone_id: int = 1
var zone_tabs_container: HBoxContainer = null
var zone_banner: Panel = null
var zone_banner_lbl: Label = null
var zone_desc_en_lbl: Label = null
var zone_desc_ar_lbl: Label = null
var cards_container: HBoxContainer = null
var cards_scroll: ScrollContainer = null
var zone_buttons: Dictionary = {}

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color("#38BDF8"), Vector2(1200, 640))
	UIThemeBuilder.enforce_ltr_recursive(self)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	UIThemeBuilder.fit_inner_container(self, vbox, 14.0, 10.0)
	
	# 1. Header with Title & Subtitle (Close button is cleanly managed by TopCloseBtn in UIThemeBuilder)
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)
	
	var title_lbl := Label.new()
	title_lbl.text = "🗺️ BIKINI BOTTOM EXPEDITION — SELECT STAGE"
	UIThemeBuilder.style_label(title_lbl, 18, Color(1.0, 0.90, 0.25), 4)
	title_vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "⚓ Defend Bikini Bottom across 3 Zones: Outskirts (1-5), Krusty Krab (6-10), and Squidward's Moai (11-15)!"
	UIThemeBuilder.style_label(sub_lbl, 11, Color(0.80, 0.92, 1.0), 2)
	title_vbox.add_child(sub_lbl)
	
	# Spacer to avoid any overlap with the top-right [X] close button
	var right_pad := Control.new()
	right_pad.custom_minimum_size = Vector2(50, 10)
	header_hbox.add_child(right_pad)
	
	# 2. Zone Selection Tabs (3 Nautical Tabs)
	zone_tabs_container = HBoxContainer.new()
	zone_tabs_container.add_theme_constant_override("separation", 8)
	vbox.add_child(zone_tabs_container)
	
	for z_id in [1, 2, 3]:
		var z_info: Dictionary = GameData.ZONES[z_id]
		var tab_btn := Button.new()
		tab_btn.name = "ZoneTab%d" % z_id
		tab_btn.text = "%s Zone %d: %s (%d-%d)" % [
			z_info["icon"],
			z_id,
			z_info["name"].replace("Inside ", ""),
			z_info["stage_range"][0],
			z_info["stage_range"][1]
		]
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size = Vector2(0, 32)
		UIThemeBuilder.style_button(tab_btn, "nav", 11)
		UIThemeBuilder.bind_button_anim(tab_btn)
		var zid_val: int = z_id
		tab_btn.pressed.connect(func(): _switch_zone(zid_val))
		zone_tabs_container.add_child(tab_btn)
		zone_buttons[z_id] = tab_btn
		
	# 3. Zone Details Banner
	zone_banner = Panel.new()
	var zb_sb := UIThemeBuilder.make_panel_style(Color(0.04, 0.14, 0.24, 0.95), Color(0.24, 0.78, 0.98, 0.8), 12, 2, 0, 10, 4)
	zone_banner.add_theme_stylebox_override("panel", zb_sb)
	zone_banner.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(zone_banner)
	
	var zb_vbox := VBoxContainer.new()
	zb_vbox.add_theme_constant_override("separation", 1)
	zone_banner.add_child(zb_vbox)
	UIThemeBuilder.fit_inner_container(zone_banner, zb_vbox, 10.0, 4.0)
	
	zone_banner_lbl = Label.new()
	UIThemeBuilder.style_label(zone_banner_lbl, 12, Color(1.0, 0.88, 0.25), 3)
	zb_vbox.add_child(zone_banner_lbl)
	
	var desc_hbox := HBoxContainer.new()
	desc_hbox.add_theme_constant_override("separation", 16)
	zb_vbox.add_child(desc_hbox)
	
	zone_desc_en_lbl = Label.new()
	zone_desc_en_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeBuilder.style_label(zone_desc_en_lbl, 10, Color(0.85, 0.94, 1.0), 2)
	desc_hbox.add_child(zone_desc_en_lbl)
	
	zone_desc_ar_lbl = Label.new()
	UIThemeBuilder.style_label(zone_desc_ar_lbl, 10, Color(1.0, 0.85, 0.35), 2)
	desc_hbox.add_child(zone_desc_ar_lbl)
	
	# 4. Stage Cards Container (Centered HBox with 5 Perfectly Sized Cards, Zero Horizontal Overflow)
	cards_scroll = ScrollContainer.new()
	cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(cards_scroll)
	
	cards_container = HBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 8)
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_scroll.add_child(cards_container)
	
	refresh_view()

func refresh_view() -> void:
	var active_st: int = PlayerData.selected_stage_id
	if not PlayerData.is_stage_unlocked(active_st):
		active_st = PlayerData.get_calculated_highest_unlocked_stage()
		PlayerData.selected_stage_id = active_st
		
	if active_st >= 11:
		current_zone_id = 3
	elif active_st >= 6:
		current_zone_id = 2
	else:
		current_zone_id = 1
		
	_switch_zone(current_zone_id)

func _switch_zone(zone_id: int) -> void:
	current_zone_id = zone_id
	var z_info: Dictionary = GameData.ZONES.get(zone_id, GameData.ZONES[1])
	var is_current_zone_unlocked: bool = PlayerData.is_zone_unlocked(zone_id)
	
	# Update Tab Highlights
	for zid in zone_buttons.keys():
		var btn: Button = zone_buttons[zid]
		var is_z_unlocked: bool = PlayerData.is_zone_unlocked(zid)
		var z_inf: Dictionary = GameData.ZONES.get(zid, {})
		var lock_prefix: String = "" if is_z_unlocked else "🔒 "
		btn.text = "%s%s Zone %d: %s (%d-%d)" % [
			lock_prefix,
			z_inf.get("icon", ""),
			zid,
			z_inf.get("name", "").replace("Inside ", ""),
			z_inf["stage_range"][0],
			z_inf["stage_range"][1]
		]
		if zid == zone_id:
			UIThemeBuilder.style_button(btn, "gold" if zone_id == 2 else ("purple" if zone_id == 3 else "action"), 11)
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			UIThemeBuilder.style_button(btn, "nav", 11)
			btn.modulate = Color(0.75, 0.85, 0.95, 0.75) if is_z_unlocked else Color(0.6, 0.65, 0.75, 0.55)
			
	# Update Zone Banner
	var border_c: Color = z_info.get("accent_color", Color("#38BDF8"))
	var bg_c: Color = z_info.get("bg_color", Color("#0369A1")).lerp(Color("#0B132B"), 0.55)
	var new_sb := UIThemeBuilder.make_panel_style(bg_c, border_c, 10, 2, 0, 10, 4)
	zone_banner.add_theme_stylebox_override("panel", new_sb)
	
	if not is_current_zone_unlocked:
		var prev_zone_id = zone_id - 1
		var req_stage: int = 5 if zone_id == 2 else 10
		zone_banner_lbl.text = "🔒 ZONE %d IS LOCKED — Complete Stage %d to Unlock!" % [zone_id, req_stage]
		zone_banner_lbl.modulate = Color(1.0, 0.45, 0.45)
		zone_desc_en_lbl.text = "Complete previous zone with at least 1 star to open this zone."
		zone_desc_ar_lbl.text = "Locked until previous zone is cleared."
	else:
		zone_banner_lbl.text = "%s ZONE %d: %s (STAGES %d - %d)" % [
			z_info["icon"],
			zone_id,
			z_info["name"].to_upper(),
			z_info["stage_range"][0],
			z_info["stage_range"][1]
		]
		zone_banner_lbl.modulate = border_c
		zone_desc_en_lbl.text = z_info.get("description", "")
		zone_desc_ar_lbl.text = z_info.get("subtitle", "")
	
	# Build 5 Stage Cards for this Zone
	for c in cards_container.get_children():
		cards_container.remove_child(c)
		c.queue_free()
		
	var st_start: int = int(z_info["stage_range"][0])
	var st_end: int = int(z_info["stage_range"][1])
	
	for s_id in range(st_start, st_end + 1):
		var st_data: Dictionary = GameData.STAGES.get(s_id, {})
		var card := _build_stage_card(s_id, st_data, border_c)
		cards_container.add_child(card)

func _build_stage_card(s_id: int, data: Dictionary, accent_col: Color) -> Panel:
	var card := Panel.new()
	card.name = "StageCard_%d" % s_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 0)
	
	var is_unlocked: bool = PlayerData.is_stage_unlocked(s_id)
	var is_selected: bool = (s_id == PlayerData.selected_stage_id)
	var stars: int = PlayerData.get_stage_stars(s_id)
	
	var card_bg = Color(0.04, 0.11, 0.20, 0.96) if is_unlocked else Color(0.06, 0.08, 0.12, 0.88)
	var card_border = accent_col if (is_selected or is_unlocked) else Color(0.3, 0.35, 0.42, 0.5)
	var border_w = 3 if is_selected else 2
	var c_sb = UIThemeBuilder.make_panel_style(card_bg, card_border, 12, border_w, 0, 8, 6)
	card.add_theme_stylebox_override("panel", c_sb)
	
	var cvbox := VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 4)
	card.add_child(cvbox)
	UIThemeBuilder.fit_inner_container(card, cvbox, 6.0, 6.0)
	
	# 1. Level Number & Stars Header (Pill Style)
	var top_hdr := HBoxContainer.new()
	top_hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hdr.add_theme_constant_override("separation", 4)
	cvbox.add_child(top_hdr)
	
	var top_badge := Label.new()
	top_badge.text = "⭐ STAGE %d" % s_id
	UIThemeBuilder.style_label(top_badge, 12, Color(1.0, 0.90, 0.25), 3)
	top_hdr.add_child(top_badge)
	
	var stars_lbl := Label.new()
	if stars >= 3:
		stars_lbl.text = "⭐⭐⭐"
	elif stars == 2:
		stars_lbl.text = "⭐⭐"
	elif stars == 1:
		stars_lbl.text = "⭐"
	else:
		stars_lbl.text = "NEW" if is_unlocked else "🔒 LOCKED"
	UIThemeBuilder.style_label(stars_lbl, 10, Color(1.0, 0.82, 0.25) if is_unlocked else Color(0.6, 0.65, 0.7), 2)
	top_hdr.add_child(stars_lbl)
	
	# 2. Stage Title
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", "Stage %d" % s_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(0, 30)
	UIThemeBuilder.style_label(name_lbl, 11, Color(0.92, 0.97, 1.0), 3)
	cvbox.add_child(name_lbl)
	
	# 3. Wave & Theme Info Pill
	var wave_pill := Panel.new()
	var w_sb := UIThemeBuilder.make_pill_style(Color(0.03, 0.16, 0.28, 0.9), accent_col, 6)
	wave_pill.add_theme_stylebox_override("panel", w_sb)
	wave_pill.custom_minimum_size = Vector2(0, 20)
	cvbox.add_child(wave_pill)
	
	var wave_lbl := Label.new()
	wave_lbl.text = "🌊 %d Waves" % int(data.get("waves", 10))
	wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(wave_lbl, 10, Color(0.75, 0.95, 1.0), 2)
	wave_pill.add_child(wave_lbl)
	UIThemeBuilder.fit_inner_container(wave_pill, wave_lbl, 4.0, 1.0)
	
	# 4. Enemy Bots Roster Badges (Structured in a clean, scroll-safe container with ellipsis clipping)
	var enemy_scroll := ScrollContainer.new()
	enemy_scroll.custom_minimum_size = Vector2(0, 85)
	enemy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	enemy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cvbox.add_child(enemy_scroll)
	
	var enemy_box := VBoxContainer.new()
	enemy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_box.add_theme_constant_override("separation", 2)
	enemy_scroll.add_child(enemy_box)
	
	var enemies_list: Array = data.get("enemies", [])
	var boss_id: String = str(data.get("boss", ""))
	for e_id in enemies_list:
		var edata: Dictionary = GameData.ENEMIES.get(e_id, {})
		var e_name: String = str(edata.get("name", e_id))
		var is_b: bool = bool(edata.get("is_boss", false)) or (e_id == boss_id)
		
		var epill := Panel.new()
		var epill_bg := Color(0.45, 0.25, 0.05, 0.85) if is_b else Color(0.06, 0.14, 0.24, 0.8)
		var epill_border := Color(1.0, 0.82, 0.25, 0.9) if is_b else Color(0.25, 0.55, 0.80, 0.6)
		epill.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(epill_bg, epill_border, 5))
		epill.custom_minimum_size = Vector2(0, 19)
		epill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemy_box.add_child(epill)
		
		var e_badge := Label.new()
		e_badge.text = "👑 %s" % e_name if is_b else "👾 %s" % e_name
		e_badge.clip_text = true
		e_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		e_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var e_col = Color(1.0, 0.90, 0.35) if is_b else Color(0.82, 0.92, 1.0)
		UIThemeBuilder.style_label(e_badge, 9, e_col, 2)
		epill.add_child(e_badge)
		UIThemeBuilder.fit_inner_container(epill, e_badge, 3.0, 1.0)
		
	# Flexible Spacer to balance card height
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(0, 6)
	cvbox.add_child(spacer)
	
	# 5. Rewards Readout Pill (Cleanly formatted: 🪙 +Gold   💎 +Gems)
	var rew_pill := Panel.new()
	rew_pill.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(Color(0.05, 0.12, 0.20, 0.9), Color(0.85, 0.72, 0.25, 0.8), 6))
	rew_pill.custom_minimum_size = Vector2(0, 22)
	cvbox.add_child(rew_pill)
	
	var rew_lbl := Label.new()
	var g_amt: int = int(data.get("gold_reward", data.get("reward_gold", 300)))
	var gem_amt: int = int(data.get("gems_reward", data.get("reward_gems", 25)))
	rew_lbl.text = "🪙 +%d   💎 +%d" % [g_amt, gem_amt]
	rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(rew_lbl, 10, Color(1.0, 0.92, 0.40), 2)
	rew_pill.add_child(rew_lbl)
	UIThemeBuilder.fit_inner_container(rew_pill, rew_lbl, 4.0, 1.0)
	
	# 6. Action Button (Play / Select)
	var play_btn := Button.new()
	play_btn.name = "PlayStageBtn"
	play_btn.custom_minimum_size = Vector2(0, 34)
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_unlocked:
		play_btn.text = "▶ ENTER"
		UIThemeBuilder.style_button(play_btn, "success" if is_selected else "action", 11)
		UIThemeBuilder.bind_button_anim(play_btn)
		var chosen_id: int = s_id
		play_btn.pressed.connect(func(): _on_stage_selected(chosen_id))
	else:
		play_btn.text = "🔒 LOCKED"
		play_btn.disabled = true
		UIThemeBuilder.style_button(play_btn, "danger", 11)
		play_btn.modulate = Color(0.6, 0.6, 0.6, 0.7)
	cvbox.add_child(play_btn)
	
	return card

func _on_stage_selected(stage_id: int) -> void:
	PlayerData.selected_stage_id = stage_id
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	emit_signal("stage_chosen", stage_id)

func _on_close_pressed() -> void:
	visible = false
	if AudioManager:
		AudioManager.play_sfx("ui_close")
