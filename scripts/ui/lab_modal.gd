extends Panel

## LabModal - Plankton & Karen's Visual Specimen Chamber, Trait FX Showcase, Trait Reroller & Trait Appearance Rates List

@onready var title_label: Label = $VBox/Title
@onready var unit_option: OptionButton = $VBox/UnitOption
@onready var current_trait_lbl: Label = $VBox/CurrentTraitLbl
@onready var trait_desc_lbl: Label = $VBox/TraitDescLbl
@onready var reroll_btn: Button = $VBox/RerollBtn
@onready var dice_count_lbl: Label = $VBox/DiceCountLbl
@onready var close_btn: Button = $VBox/CloseBtn

var selected_uid: int = -1
var unit_scroll: ScrollContainer = null
var unit_grid: GridContainer = null
var chamber_panel: Panel = null
var chamber_card_holder: CenterContainer = null
var chamber_trait_badge: PanelContainer = null
var chamber_trait_icon: TextureRect = null
var stats_preview_lbl: Label = null

# Segmented Views: Chamber vs Trait Appearance Rates List
var current_tab: String = "chamber"
var tab_bar_hbox: HBoxContainer = null
var tab_chamber_btn: Button = null
var tab_rates_btn: Button = null

var chamber_view: VBoxContainer = null
var rates_view: VBoxContainer = null

# Rates View controls
var odds_summary_bar: PanelContainer = null
var chamber_view_rates_btn: Button = null
var rates_scroll: ScrollContainer = null
var rates_grid: GridContainer = null
var rates_back_btn: Button = null
var rates_reroll_btn: Button = null
var rates_close_btn: Button = null

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(0.25, 0.96, 0.55), Vector2(700, 516))
	$VBox.add_theme_constant_override("separation", 6)
	
	title_label.text = "🧪 PLANKTON & KAREN'S TRAIT LABORATORY"
	UIThemeBuilder.style_label(title_label, 19, Color(0.30, 0.98, 0.58), 4)
	UIThemeBuilder.style_label(dice_count_lbl, 13, Color(1.0, 0.88, 0.25), 3)
	
	# Hide legacy text-only OptionButton dropdown
	unit_option.visible = false
	
	# -------------------------------------------------------------
	# 0. Navigation Tab Bar: [ 🧪 MUTATION CHAMBER ] vs [ 📊 TRAIT RATES (10) ]
	# -------------------------------------------------------------
	tab_bar_hbox = HBoxContainer.new()
	tab_bar_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar_hbox.add_theme_constant_override("separation", 12)
	$VBox.add_child(tab_bar_hbox)
	$VBox.move_child(tab_bar_hbox, 2)
	
	tab_chamber_btn = Button.new()
	tab_chamber_btn.text = "🧪 MUTATION CHAMBER"
	tab_chamber_btn.custom_minimum_size = Vector2(230, 32)
	tab_bar_hbox.add_child(tab_chamber_btn)
	
	tab_rates_btn = Button.new()
	tab_rates_btn.text = "📊 TRAIT RATES & ODDS (10)"
	tab_rates_btn.custom_minimum_size = Vector2(250, 32)
	tab_bar_hbox.add_child(tab_rates_btn)
	
	tab_chamber_btn.pressed.connect(func(): _show_tab("chamber"))
	tab_rates_btn.pressed.connect(func(): _show_tab("rates"))
	
	# -------------------------------------------------------------
	# 1. Chamber View Container
	# -------------------------------------------------------------
	chamber_view = VBoxContainer.new()
	chamber_view.name = "ChamberView"
	chamber_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chamber_view.add_theme_constant_override("separation", 6)
	$VBox.add_child(chamber_view)
	$VBox.move_child(chamber_view, 3)
	
	# Visual Unit Card Tray (Click any Unit Card to place it into the Laboratory Chamber)
	var tray_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.09, 0.16, 0.92), Color(0.20, 0.75, 0.52, 0.75), 16, 2, 0, 12, 6)
	unit_scroll = ScrollContainer.new()
	unit_scroll.add_theme_stylebox_override("panel", tray_sb)
	unit_scroll.custom_minimum_size = Vector2(0, 136)
	unit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	unit_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chamber_view.add_child(unit_scroll)
	
	unit_grid = GridContainer.new()
	unit_grid.columns = 5
	unit_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_grid.add_theme_constant_override("h_separation", 10)
	unit_grid.add_theme_constant_override("v_separation", 6)
	unit_scroll.add_child(unit_grid)
	
	# Plankton's Bio-Chamber Panel (Shows Placed Unit Card on Left + Large Trait Emblem + Readout on Right)
	chamber_panel = Panel.new()
	chamber_panel.clip_contents = false
	var ch_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.16, 0.22, 0.98), Color(0.30, 0.98, 0.58, 0.95), 16, 2, 0, 14, 8)
	chamber_panel.add_theme_stylebox_override("panel", ch_sb)
	chamber_panel.custom_minimum_size = Vector2(0, 140)
	chamber_view.add_child(chamber_panel)
	
	var ch_hbox = HBoxContainer.new()
	chamber_panel.add_child(ch_hbox)
	UIThemeBuilder.fit_inner_container(chamber_panel, ch_hbox, 16.0, 8.0)
	ch_hbox.add_theme_constant_override("separation", 14)
	
	chamber_card_holder = CenterContainer.new()
	chamber_card_holder.custom_minimum_size = Vector2(130, 124)
	ch_hbox.add_child(chamber_card_holder)
	
	# Large Glowing Trait Emblem Medallion inside the Chamber
	chamber_trait_badge = PanelContainer.new()
	chamber_trait_badge.name = "ChamberTraitEmblem"
	chamber_trait_badge.custom_minimum_size = Vector2(52, 52)
	chamber_trait_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tb_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.16, 0.96), Color(0.30, 0.98, 0.58), 16, 2, 0, 6, 6)
	chamber_trait_badge.add_theme_stylebox_override("panel", tb_sb)
	
	chamber_trait_icon = TextureRect.new()
	chamber_trait_icon.name = "ChamberTraitIcon"
	chamber_trait_icon.custom_minimum_size = Vector2(40, 40)
	chamber_trait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chamber_trait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chamber_trait_badge.add_child(chamber_trait_icon)
	ch_hbox.add_child(chamber_trait_badge)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 5)
	ch_hbox.add_child(info_vbox)
	
	# Reparent current_trait_lbl and trait_desc_lbl into the Chamber's right readout panel
	current_trait_lbl.get_parent().remove_child(current_trait_lbl)
	trait_desc_lbl.get_parent().remove_child(trait_desc_lbl)
	info_vbox.add_child(current_trait_lbl)
	info_vbox.add_child(trait_desc_lbl)
	
	stats_preview_lbl = Label.new()
	info_vbox.add_child(stats_preview_lbl)
	
	current_trait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	trait_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	current_trait_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trait_desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats_preview_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	current_trait_lbl.clip_text = true
	trait_desc_lbl.clip_text = true
	stats_preview_lbl.clip_text = true
	current_trait_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trait_desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_preview_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeBuilder.style_label(current_trait_lbl, 14, Color(0.38, 0.98, 0.68), 4)
	UIThemeBuilder.style_label(trait_desc_lbl, 12, Color(0.92, 0.97, 1.0), 3)
	UIThemeBuilder.style_label(stats_preview_lbl, 11, Color(1.0, 0.86, 0.25), 3)
	
	# Clickable Quick Odds Ticker Bar in Chamber View
	odds_summary_bar = PanelContainer.new()
	odds_summary_bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	odds_summary_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var os_sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.08, 0.14, 0.92), Color(0.20, 0.70, 0.90, 0.65), 10, 1, 0, 8, 4)
	odds_summary_bar.add_theme_stylebox_override("panel", os_sb)
	var os_lbl = Label.new()
	os_lbl.text = "📊 Mutation Odds: 👑 0.5% • 🧪 1.5% • 🛡️ 4% • 🌀 7% • 🐾 10% • 💰 12% • ⚡ 16% • 🎯 17% • ⚔️ 20% • 💀 12% [Details]"
	os_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	os_lbl.clip_text = true
	os_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeBuilder.style_label(os_lbl, 11, Color(0.38, 0.92, 1.0), 2)
	odds_summary_bar.add_child(os_lbl)
	chamber_view.add_child(odds_summary_bar)
	odds_summary_bar.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_tab("rates")
	)
	
	# Chamber Bottom Action Buttons Row (Reroll + View Rates + Close)
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	chamber_view.add_child(btn_row)
	
	reroll_btn.get_parent().remove_child(reroll_btn)
	close_btn.get_parent().remove_child(close_btn)
	
	chamber_view_rates_btn = Button.new()
	chamber_view_rates_btn.text = "📊 TRAIT RATES"
	chamber_view_rates_btn.custom_minimum_size = Vector2(160, 38)
	UIThemeBuilder.style_button(chamber_view_rates_btn, "secondary", 13)
	chamber_view_rates_btn.pressed.connect(func(): _show_tab("rates"))
	
	btn_row.add_child(reroll_btn)
	btn_row.add_child(chamber_view_rates_btn)
	btn_row.add_child(close_btn)
	
	reroll_btn.text = "🎲 REROLL TRAIT (1 Die)"
	close_btn.text = "✖ Close"
	reroll_btn.custom_minimum_size = Vector2(230, 38)
	close_btn.custom_minimum_size = Vector2(110, 38)
	
	UIThemeBuilder.style_button(reroll_btn, "magic", 14)
	UIThemeBuilder.style_button(close_btn, "danger", 13)
	
	# -------------------------------------------------------------
	# 2. Rates View Container (List of all 10 Traits with Appearance Odds)
	# -------------------------------------------------------------
	rates_view = VBoxContainer.new()
	rates_view.name = "RatesView"
	rates_view.visible = false
	rates_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rates_view.add_theme_constant_override("separation", 6)
	$VBox.add_child(rates_view)
	$VBox.move_child(rates_view, 4)
	
	var rates_subtitle_lbl = Label.new()
	rates_subtitle_lbl.text = "📊 ALL 10 OBTAINABLE TRAITS & MUTATION ODDS (Sum: 100.0%)"
	rates_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rates_subtitle_lbl.clip_text = true
	rates_subtitle_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeBuilder.style_label(rates_subtitle_lbl, 13, Color(1.0, 0.88, 0.25), 3)
	rates_view.add_child(rates_subtitle_lbl)
	
	# Scrollable Grid for 10 Trait Cards (2 Columns x 5 Rows)
	var rates_sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.08, 0.14, 0.94), Color(0.20, 0.70, 0.50, 0.70), 14, 2, 0, 10, 8)
	rates_scroll = ScrollContainer.new()
	rates_scroll.add_theme_stylebox_override("panel", rates_sb)
	rates_scroll.custom_minimum_size = Vector2(0, 290)
	rates_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rates_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rates_view.add_child(rates_scroll)
	
	rates_grid = GridContainer.new()
	rates_grid.columns = 2
	rates_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rates_grid.add_theme_constant_override("h_separation", 10)
	rates_grid.add_theme_constant_override("v_separation", 6)
	rates_scroll.add_child(rates_grid)
	
	# Rates View Action Buttons Row
	var rates_btn_row = HBoxContainer.new()
	rates_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rates_btn_row.add_theme_constant_override("separation", 14)
	rates_view.add_child(rates_btn_row)
	
	rates_back_btn = Button.new()
	rates_back_btn.text = "🧪 Back to Chamber"
	rates_back_btn.custom_minimum_size = Vector2(190, 38)
	UIThemeBuilder.style_button(rates_back_btn, "primary", 13)
	rates_back_btn.pressed.connect(func(): _show_tab("chamber"))
	rates_btn_row.add_child(rates_back_btn)
	
	rates_reroll_btn = Button.new()
	rates_reroll_btn.text = "🎲 Reroll Trait (1 Die)"
	rates_reroll_btn.custom_minimum_size = Vector2(210, 38)
	UIThemeBuilder.style_button(rates_reroll_btn, "magic", 13)
	rates_reroll_btn.pressed.connect(_on_reroll_pressed)
	rates_btn_row.add_child(rates_reroll_btn)
	
	rates_close_btn = Button.new()
	rates_close_btn.text = "✖ Close"
	rates_close_btn.custom_minimum_size = Vector2(110, 38)
	UIThemeBuilder.style_button(rates_close_btn, "danger", 13)
	rates_close_btn.pressed.connect(func(): visible = false)
	rates_btn_row.add_child(rates_close_btn)
	
	# Connect base buttons
	reroll_btn.pressed.connect(_on_reroll_pressed)
	close_btn.pressed.connect(func(): visible = false)
	
	# Ensure top-right X button exists and is in front
	UIThemeBuilder.ensure_top_close_button(self, 700.0)
	var top_x = get_node_or_null("TopCloseBtn")
	if top_x:
		top_x.move_to_front()
		
	_show_tab("chamber")

func _style_tab_button(btn: Button, active: bool, accent_color: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	if active:
		sb.bg_color = Color(0.06, 0.22, 0.28, 0.98)
		sb.border_color = accent_color
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		btn.add_theme_color_override("font_color", accent_color.lightened(0.25))
	else:
		sb.bg_color = Color(0.03, 0.08, 0.14, 0.85)
		sb.border_color = Color(0.18, 0.35, 0.45, 0.60)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		btn.add_theme_color_override("font_color", Color(0.65, 0.78, 0.88))
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if UIThemeBuilder.get_title_font():
		btn.add_theme_font_override("font", UIThemeBuilder.get_title_font())
	btn.add_theme_font_size_override("font_size", 12)

func _show_tab(tab_name: String) -> void:
	current_tab = tab_name
	if tab_name == "chamber":
		chamber_view.visible = true
		rates_view.visible = false
		_style_tab_button(tab_chamber_btn, true, Color(0.30, 0.98, 0.58))
		_style_tab_button(tab_rates_btn, false, Color(1.0, 0.82, 0.20))
	else:
		chamber_view.visible = false
		rates_view.visible = true
		_style_tab_button(tab_chamber_btn, false, Color(0.30, 0.98, 0.58))
		_style_tab_button(tab_rates_btn, true, Color(1.0, 0.82, 0.20))
		_populate_rates_grid()

func _populate_rates_grid() -> void:
	if not rates_grid:
		return
	for c in rates_grid.get_children():
		c.queue_free()
		
	var pool: Array = GameData.TRAIT_REROLL_POOL
	for trait_info in pool:
		var tr_id: String = trait_info.get("id", "")
		var tr_data: Dictionary = GameData.TRAITS.get(tr_id, {})
		var tr_name: String = tr_data.get("name", tr_id)
		var tr_sym: String = tr_data.get("symbol", "✨")
		var tr_col: Color = tr_data.get("color", Color.WHITE)
		var tr_glow: Color = tr_data.get("glow_color", Color.YELLOW)
		var tr_icon_p: String = tr_data.get("icon", "")
		var tr_pct: String = trait_info.get("chance_pct", "0.0%")
		var tr_tier: String = trait_info.get("tier", "Trait")
		var tr_tier_col: Color = trait_info.get("tier_color", tr_col)
		var tr_summary: String = trait_info.get("summary", tr_data.get("desc", ""))
		
		# Individual Trait Card Container
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(295, 48)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.10, 0.17, 0.96), tr_col, 10, 1, 0, 8, 4)
		card.add_theme_stylebox_override("panel", card_sb)
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 8)
		card.add_child(hbox)
		
		# Left: 36x36 Trait Emblem Badge
		var icon_badge = PanelContainer.new()
		icon_badge.custom_minimum_size = Vector2(36, 36)
		icon_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var b_sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.06, 0.12, 0.98), tr_glow, 8, 1, 0, 3, 3)
		icon_badge.add_theme_stylebox_override("panel", b_sb)
		
		var icon_tex = TextureRect.new()
		icon_tex.custom_minimum_size = Vector2(28, 28)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if tr_icon_p != "" and ResourceLoader.exists(tr_icon_p):
			icon_tex.texture = load(tr_icon_p)
		icon_badge.add_child(icon_tex)
		hbox.add_child(icon_badge)
		
		# Center Info VBox
		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.alignment = BoxContainer.ALIGNMENT_CENTER
		info_box.add_theme_constant_override("separation", 2)
		hbox.add_child(info_box)
		
		# Top Line: Name + Tier
		var top_line = HBoxContainer.new()
		top_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_line.add_theme_constant_override("separation", 6)
		info_box.add_child(top_line)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s %s" % [tr_sym, tr_name]
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIThemeBuilder.style_label(name_lbl, 12, tr_col.lightened(0.20), 3)
		top_line.add_child(name_lbl)
		
		var tier_badge = Label.new()
		tier_badge.text = "[%s]" % tr_tier.to_upper()
		UIThemeBuilder.style_label(tier_badge, 9, tr_tier_col, 2)
		top_line.add_child(tier_badge)
		
		# Bottom Line: Stat Summary
		var desc_lbl = Label.new()
		desc_lbl.text = tr_summary
		desc_lbl.clip_text = true
		desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIThemeBuilder.style_label(desc_lbl, 10, Color(0.85, 0.92, 0.98), 2)
		info_box.add_child(desc_lbl)
		
		# Right: Glowing Percentage Pill Badge
		var pill_badge = PanelContainer.new()
		pill_badge.custom_minimum_size = Vector2(56, 26)
		pill_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var p_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.16, 0.20, 0.98), tr_glow, 8, 2, 0, 5, 2)
		pill_badge.add_theme_stylebox_override("panel", p_sb)
		
		var pct_lbl = Label.new()
		pct_lbl.text = tr_pct
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIThemeBuilder.style_label(pct_lbl, 12, tr_glow.lightened(0.25), 3)
		pill_badge.add_child(pct_lbl)
		hbox.add_child(pill_badge)
		
		rates_grid.add_child(card)

func refresh_view() -> void:
	dice_count_lbl.text = "🎲 Available Trait Dice: %d   •   Click Any Unit Card Below to Place in Chamber!" % PlayerData.reroll_dice
	if rates_reroll_btn:
		rates_reroll_btn.text = "🎲 Reroll Trait (%d Dice)" % PlayerData.reroll_dice
		
	if PlayerData.inventory.is_empty():
		current_trait_lbl.text = "No units available."
		return
		
	if selected_uid == -1 or PlayerData.get_tower_by_uid(selected_uid).is_empty():
		selected_uid = PlayerData.inventory[0]["uid"]
		
	_populate_lab_units()
	_update_chamber_display(false)
	_show_tab("chamber")

func _populate_lab_units() -> void:
	if not unit_grid:
		return
	for c in unit_grid.get_children():
		c.queue_free()
		
	for u in PlayerData.inventory:
		var uid = u["uid"]
		var is_sel = (uid == selected_uid)
		var sel_mode = "lab_selected" if is_sel else ""
		var card = UIThemeBuilder.create_unit_card(
			u["tower_id"],
			u.get("level", 1),
			u.get("trait_id", "none"),
			PlayerData.is_equipped(uid),
			-1,
			Vector2(118, 118),
			sel_mode
		)
		card.pressed.connect(func():
			selected_uid = uid
			UIThemeBuilder.play_pulse_anim(card, 1.09)
			_populate_lab_units()
			_update_chamber_display(true)
		)
		unit_grid.add_child(card)

func _update_chamber_display(animate_specimen: bool = false) -> void:
	if not chamber_card_holder:
		return
	for c in chamber_card_holder.get_children():
		chamber_card_holder.remove_child(c)
		c.queue_free()
		
	var unit = PlayerData.get_tower_by_uid(selected_uid)
	if unit.is_empty():
		return
		
	var t_data = GameData.TOWERS.get(unit["tower_id"], {})
	var trait_id: String = str(unit.get("trait_id", "none"))
	var trait_data: Dictionary = GameData.TRAITS.get(trait_id, GameData.TRAITS["none"])
	var tr_col: Color = trait_data.get("color", Color(0.30, 0.98, 0.58))
	var tr_glow: Color = trait_data.get("glow_color", Color(1.0, 0.88, 0.25))
	var tr_symbol: String = str(trait_data.get("symbol", "🧬"))
	var tr_icon_p: String = str(trait_data.get("icon", ""))
	
	# Create the Placed Specimen Card inside Plankton's Chamber (with full Trait FX & Emblem!)
	var specimen_card = UIThemeBuilder.create_unit_card(
		unit["tower_id"],
		unit.get("level", 1),
		trait_id,
		false,
		-1,
		Vector2(120, 120),
		"lab_selected"
	)
	chamber_card_holder.add_child(specimen_card)
	
	# Update Chamber Border & Large Trait Emblem Medallion
	var ch_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.14, 0.22, 0.98), tr_col, 16, 2, 0, 14, 8)
	chamber_panel.add_theme_stylebox_override("panel", ch_sb)
	
	if chamber_trait_badge:
		var has_tr_icon := (tr_icon_p != "" and ResourceLoader.exists(tr_icon_p))
		chamber_trait_badge.visible = has_tr_icon
		if has_tr_icon:
			chamber_trait_icon.texture = load(tr_icon_p)
			var tb_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.16, 0.98), tr_glow, 16, 2, 0, 6, 6)
			chamber_trait_badge.add_theme_stylebox_override("panel", tb_sb)
			
	if animate_specimen:
		UIThemeBuilder.play_pulse_anim(specimen_card, 1.14)
		if chamber_trait_badge and chamber_trait_badge.visible:
			UIThemeBuilder.play_pulse_anim(chamber_trait_badge, 1.22)
		UIThemeBuilder.play_pulse_anim(chamber_panel, 1.03)
		
	current_trait_lbl.text = "%s Active Trait: [%s]  —  %s (Lv.%d)" % [
		tr_symbol, trait_data.get("name", "None"), t_data.get("name", ""), unit.get("level", 1)
	]
	UIThemeBuilder.style_label(current_trait_lbl, 14, tr_col.lightened(0.22), 4)
	trait_desc_lbl.text = "⚡ Bonus Effect: %s" % trait_data.get("desc", "")
	
	var base_dmg = t_data.get("base_damage", 10.0) * (1.0 + (unit["level"] - 1) * 0.05) * trait_data.get("damage_mult", 1.0)
	var spa = t_data.get("base_spa", 1.5) * trait_data.get("spa_mult", 1.0)
	var rng = t_data.get("base_range", 8.0) * trait_data.get("range_mult", 1.0)
	stats_preview_lbl.text = "🔥 DPS: %.1f   |   ⚔️ DMG: %.1f   |   ⚡ Speed: %.2fs   |   🎯 Range: %.1fm" % [
		base_dmg / spa, base_dmg, spa, rng
	]

func _on_reroll_pressed() -> void:
	if selected_uid == -1:
		return
	if PlayerData.reroll_dice <= 0:
		trait_desc_lbl.text = "⚠️ Out of Trait Dice! Win waves or redeem promo codes."
		return
		
	var res = PlayerData.reroll_unit_trait(selected_uid)
	if res.get("success", false):
		if AudioManager:
			AudioManager.play_sfx("trait_reroll")
		dice_count_lbl.text = "🎲 Available Trait Dice: %d   •   ✨ Trait Mutated Successfully!" % PlayerData.reroll_dice
		if rates_reroll_btn:
			rates_reroll_btn.text = "🎲 Reroll Trait (%d Dice)" % PlayerData.reroll_dice
		_populate_lab_units()
		_update_chamber_display(true)
		var t_data: Dictionary = res.get("trait_data", {})
		var sym: String = str(t_data.get("symbol", "✨"))
		current_trait_lbl.text = "%s NEW TRAIT UNLOCKED: [%s]!" % [sym, t_data.get("name", "")]
		UIThemeBuilder.play_pulse_anim(current_trait_lbl, 1.10)
	else:
		trait_desc_lbl.text = res.get("message", "Reroll failed.")
