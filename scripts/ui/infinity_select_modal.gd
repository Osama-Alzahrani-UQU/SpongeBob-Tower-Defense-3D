extends Panel

## InfinitySelectModal - Interactive Map & Difficulty Selector for Endless Waves Mode

signal map_chosen(theme_id: String)

var map_cards_container: HBoxContainer = null
var record_labels: Dictionary = {}

const MAP_CONFIGS = [
	{
		"id": "outskirts",
		"icon": "🌊",
		"name": "Bikini Bottom Outskirts",
		"arabic_name": "Coastal Beachfront Highway",
		"subtitle": "Coastal Beachfront Highway",
		"difficulty_title": "⭐ NORMAL",
		"difficulty_color": Color("#38BDF8"),
		"multiplier_text": "🪙 +1.0x Gold & Gems",
		"layout_text": "🗺️ Winding Beach Trail (10 Turns)",
		"desc": "Wide open coastal highway, classic wave pacing, standard Plankton bot legions.",
		"accent": Color("#38BDF8"),
		"btn_style": "action"
	},
	{
		"id": "krusty_interior",
		"icon": "🍔",
		"name": "The Krusty Krab",
		"arabic_name": "Krusty Krab Dining Hall",
		"subtitle": "Krusty Krab Dining Hall",
		"difficulty_title": "⭐⭐ HARD",
		"difficulty_color": Color("#F59E0B"),
		"multiplier_text": "🪙 +1.5x Gold & Gems (+50% Loot)",
		"layout_text": "🗺️ Kitchen Pass & Dining Aisle (8 Turns)",
		"desc": "High-speed kitchen rush, tighter dining corridors, defending the Formula Safe!",
		"accent": Color("#F59E0B"),
		"btn_style": "gold"
	},
	{
		"id": "squidward_interior",
		"icon": "🗿",
		"name": "Squidward's Moai Salon",
		"arabic_name": "Moai Art Gallery Promenade",
		"subtitle": "Moai Art Gallery Promenade",
		"difficulty_title": "⭐⭐⭐ NIGHTMARE",
		"difficulty_color": Color("#EF4444"),
		"multiplier_text": "🪙 +2.0x Gold & Gems (DOUBLE LOOT!)",
		"layout_text": "🗺️ Grand Spiral Colonnade (12 Turns)",
		"desc": "Intricate VIP spiral promenade, relentless elite swarms, ruthless boss gauntlets!",
		"accent": Color("#C084FC"),
		"btn_style": "purple"
	}
]

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color("#EC4899"), Vector2(1120, 580))
	UIThemeBuilder.enforce_ltr_recursive(self)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	UIThemeBuilder.fit_inner_container(self, vbox, 16.0, 12.0)
	
	# 1. Header with Title & Subtitle
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)
	
	var title_lbl := Label.new()
	title_lbl.text = "♾️ PATRICK'S ROCK — INFINITY WAVES EXPEDITION"
	UIThemeBuilder.style_label(title_lbl, 20, Color(1.0, 0.92, 0.25), 4)
	title_vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "⚓ Choose your battlefield! Each map has a completely distinct layout, difficulty level, and loot multiplier!"
	UIThemeBuilder.style_label(sub_lbl, 11, Color(0.85, 0.92, 1.0), 2)
	title_vbox.add_child(sub_lbl)
	
	var right_pad := Control.new()
	right_pad.custom_minimum_size = Vector2(50, 10)
	header_hbox.add_child(right_pad)
	
	# 2. Map Cards Grid (3 Distinct Cards side by side)
	map_cards_container = HBoxContainer.new()
	map_cards_container.add_theme_constant_override("separation", 14)
	map_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(map_cards_container)
	
	for m_cfg in MAP_CONFIGS:
		var card := _build_map_card(m_cfg)
		map_cards_container.add_child(card)
		
	var top_x: Button = get_node_or_null("TopCloseBtn")
	if top_x:
		move_child(top_x, -1)
		
	refresh_view()

func refresh_view() -> void:
	for m_cfg in MAP_CONFIGS:
		var mid: String = m_cfg["id"]
		var best_w: int = int(PlayerData.highest_infinity_waves_by_map.get(mid, 0))
		if record_labels.has(mid):
			var r_lbl: Label = record_labels[mid]
			if best_w > 0:
				r_lbl.text = "🏆 RECORD: WAVE %d" % best_w
				r_lbl.modulate = Color(1.0, 0.90, 0.25)
			else:
				r_lbl.text = "🌱 NO RUN YET"
				r_lbl.modulate = Color(0.70, 0.80, 0.90)

func _build_map_card(cfg: Dictionary) -> Panel:
	var card := Panel.new()
	card.name = "InfinityMapCard_%s" % cfg["id"]
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var accent_col: Color = cfg["accent"]
	var c_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.11, 0.20, 0.96), accent_col, 14, 2, 0, 10, 8)
	card.add_theme_stylebox_override("panel", c_sb)
	
	var cvbox := VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 6)
	card.add_child(cvbox)
	UIThemeBuilder.fit_inner_container(card, cvbox, 10.0, 10.0)
	
	# Difficulty Badge Header
	var diff_pill := Panel.new()
	var d_col: Color = cfg["difficulty_color"]
	diff_pill.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(d_col.lerp(Color.BLACK, 0.65), d_col, 6))
	diff_pill.custom_minimum_size = Vector2(0, 24)
	cvbox.add_child(diff_pill)
	
	var diff_lbl := Label.new()
	diff_lbl.text = "%s %s" % [cfg["icon"], cfg["difficulty_title"]]
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(diff_lbl, 11, d_col, 2)
	diff_pill.add_child(diff_lbl)
	UIThemeBuilder.fit_inner_container(diff_pill, diff_lbl, 4.0, 2.0)
	
	# Map Name
	var name_lbl := Label.new()
	name_lbl.text = cfg["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(name_lbl, 13, Color(1.0, 0.96, 0.85), 3)
	cvbox.add_child(name_lbl)
	
	var ar_lbl := Label.new()
	ar_lbl.text = cfg["arabic_name"]
	ar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(ar_lbl, 11, Color(0.80, 0.90, 1.0), 2)
	cvbox.add_child(ar_lbl)
	
	# Multiplier Pill
	var mult_pill := Panel.new()
	mult_pill.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(Color(0.06, 0.16, 0.10, 0.9), Color(0.25, 0.95, 0.55), 6))
	mult_pill.custom_minimum_size = Vector2(0, 22)
	cvbox.add_child(mult_pill)
	
	var mult_lbl := Label.new()
	mult_lbl.text = cfg["multiplier_text"]
	mult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mult_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(mult_lbl, 10, Color(0.35, 1.0, 0.65), 2)
	mult_pill.add_child(mult_lbl)
	UIThemeBuilder.fit_inner_container(mult_pill, mult_lbl, 4.0, 1.0)
	
	# Layout Feature
	var layout_lbl := Label.new()
	layout_lbl.text = cfg["layout_text"]
	layout_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(layout_lbl, 10, Color(1.0, 0.85, 0.35), 2)
	cvbox.add_child(layout_lbl)
	
	# Description Box
	var desc_lbl := Label.new()
	desc_lbl.text = cfg["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIThemeBuilder.style_label(desc_lbl, 10, Color(0.80, 0.88, 0.95), 1)
	cvbox.add_child(desc_lbl)
	
	# Best Record Pill
	var rec_pill := Panel.new()
	rec_pill.add_theme_stylebox_override("panel", UIThemeBuilder.make_pill_style(Color(0.03, 0.12, 0.22, 0.85), accent_col.lerp(Color.WHITE, 0.3), 6))
	rec_pill.custom_minimum_size = Vector2(0, 24)
	cvbox.add_child(rec_pill)
	
	var rec_lbl := Label.new()
	rec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(rec_lbl, 10, Color(1.0, 0.92, 0.35), 2)
	rec_pill.add_child(rec_lbl)
	UIThemeBuilder.fit_inner_container(rec_pill, rec_lbl, 4.0, 2.0)
	record_labels[cfg["id"]] = rec_lbl
	
	# Enter Button
	var start_btn := Button.new()
	start_btn.name = "StartMapBtn"
	start_btn.text = "▶ ENTER %s" % cfg["icon"]
	start_btn.custom_minimum_size = Vector2(0, 36)
	UIThemeBuilder.style_button(start_btn, cfg.get("btn_style", "action"), 12)
	UIThemeBuilder.bind_button_anim(start_btn)
	var chosen_id: String = cfg["id"]
	start_btn.pressed.connect(func(): _on_map_chosen(chosen_id))
	cvbox.add_child(start_btn)
	
	return card

func _on_map_chosen(theme_id: String) -> void:
	PlayerData.selected_infinity_map = theme_id
	visible = false
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	emit_signal("map_chosen", theme_id)

func _on_close_pressed() -> void:
	visible = false
	if AudioManager:
		AudioManager.play_sfx("ui_close")
