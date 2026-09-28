extends Node

## UIThemeBuilder - Custom Bikini Bottom Cartoon Typography, Interactive Animations & 1280x720 UI System

const SCREEN_W := 1280.0
const SCREEN_H := 720.0

const COLOR_NAVY_DARK := Color(0.04, 0.11, 0.20, 0.96)
const COLOR_NAVY_PANEL := Color(0.05, 0.14, 0.25, 0.97)
const COLOR_NAVY_CARD := Color(0.08, 0.20, 0.34, 0.96)
const COLOR_CYAN_BORDER := Color(0.24, 0.78, 0.98, 1.0)
const COLOR_GOLD := Color(1.0, 0.82, 0.18, 1.0)
const COLOR_CORAL := Color(0.98, 0.36, 0.28, 1.0)
const COLOR_EMERALD := Color(0.18, 0.86, 0.48, 1.0)
const COLOR_PURPLE := Color(0.68, 0.32, 0.96, 1.0)

var title_font: Font = null
var body_font: Font = null
var global_theme: Theme = null

func _ready() -> void:
	_init_game_fonts()

func _init_game_fonts() -> void:
	if title_font and body_font:
		return
	var base_cartoon: Font = null
	var base_arcade: Font = null
	if ResourceLoader.exists("res://assets/fonts/cartoon_bold.ttf"):
		base_cartoon = load("res://assets/fonts/cartoon_bold.ttf")
	if not base_cartoon and FileAccess.file_exists("res://assets/fonts/cartoon_bold.ttf"):
		var ff1 = FontFile.new()
		if ff1.load_dynamic_font("res://assets/fonts/cartoon_bold.ttf") == OK:
			base_cartoon = ff1
			
	if ResourceLoader.exists("res://assets/fonts/arcade_black.ttf"):
		base_arcade = load("res://assets/fonts/arcade_black.ttf")
	if not base_arcade and FileAccess.file_exists("res://assets/fonts/arcade_black.ttf"):
		var ff2 = FontFile.new()
		if ff2.load_dynamic_font("res://assets/fonts/arcade_black.ttf") == OK:
			base_arcade = ff2
		
	if not base_cartoon:
		var sf = SystemFont.new()
		sf.font_names = PackedStringArray(["Comic Sans MS", "Segoe UI Black", "Trebuchet MS", "Arial Black"])
		sf.font_weight = 900
		base_cartoon = sf
	if not base_arcade:
		base_arcade = base_cartoon
		
	var tv = FontVariation.new()
	tv.base_font = base_arcade
	tv.variation_embolden = 0.22
	tv.spacing_glyph = 1
	tv.spacing_space = 2
	title_font = tv
	
	var bv = FontVariation.new()
	bv.base_font = base_cartoon
	bv.variation_embolden = 0.16
	bv.spacing_glyph = 1
	body_font = bv
	
	global_theme = Theme.new()
	global_theme.default_font = body_font
	global_theme.default_font_size = 14
	if get_tree() and get_tree().root:
		get_tree().root.theme = global_theme

func get_title_font() -> Font:
	_init_game_fonts()
	return title_font

func get_body_font() -> Font:
	_init_game_fonts()
	return body_font

func make_panel_style(
	bg: Color = COLOR_NAVY_PANEL,
	border: Color = COLOR_CYAN_BORDER,
	radius: int = 18,
	border_w: int = 2,
	_shadow: int = 0,
	pad_h: int = 12,
	pad_v: int = 8
) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 16
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.25
	sb.shadow_size = 0
	sb.shadow_color = Color(0, 0, 0, 0)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb

func make_pill_style(bg: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 16
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.25
	sb.shadow_size = 0
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

## Forces LTR layout direction and ensures Containers/Labels never block button clicks
func enforce_ltr_recursive(node: Node) -> void:
	if not node:
		return
	_init_game_fonts()
	if node is Control:
		node.layout_direction = Control.LAYOUT_DIRECTION_LTR
		if node is Label:
			style_label(node, node.get_theme_font_size("font_size") if node.has_theme_font_size_override("font_size") else 14, node.get_theme_color("font_color") if node.has_theme_color_override("font_color") else Color.WHITE, 4)
		elif node is Container and not (node is ScrollContainer):
			node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		enforce_ltr_recursive(child)

## Places a Control at exact pixel coordinates (x, y, w, h) within the 1280x720 canvas
func place_rect(ctrl: Control, x: float, y: float, w: float, h: float) -> void:
	if not ctrl:
		return
	ctrl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ctrl.grow_horizontal = Control.GROW_DIRECTION_END
	ctrl.grow_vertical = Control.GROW_DIRECTION_END
	ctrl.custom_minimum_size = Vector2(w, h)
	ctrl.anchor_left = 0.0
	ctrl.anchor_top = 0.0
	ctrl.anchor_right = 0.0
	ctrl.anchor_bottom = 0.0
	ctrl.offset_left = x
	ctrl.offset_top = y
	ctrl.offset_right = x + w
	ctrl.offset_bottom = y + h
	ctrl.position = Vector2(x, y)
	ctrl.size = Vector2(w, h)
	ctrl.pivot_offset = Vector2(w * 0.5, h * 0.5)

## Fits an inner container (like VBox) inside a parent Panel with exact pixel padding
func fit_inner_container(parent_panel: Control, inner: Control, pad_x: float = 20.0, pad_y: float = 16.0) -> void:
	if not parent_panel or not inner:
		return
	if inner.get_parent() != parent_panel:
		if inner.get_parent():
			inner.get_parent().remove_child(inner)
		parent_panel.add_child(inner)
	parent_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	parent_panel.clip_contents = false
	inner.layout_direction = Control.LAYOUT_DIRECTION_LTR
	if inner is Container and not (inner is ScrollContainer):
		inner.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.grow_horizontal = Control.GROW_DIRECTION_END
	inner.grow_vertical = Control.GROW_DIRECTION_END
	inner.anchor_left = 0.0
	inner.anchor_top = 0.0
	inner.anchor_right = 1.0
	inner.anchor_bottom = 1.0
	inner.offset_left = pad_x
	inner.offset_top = pad_y
	inner.offset_right = -pad_x
	inner.offset_bottom = -pad_y

## Binds tactile cartoon press/release/hover animations to any Button or Unit Card
func bind_button_anim(btn: Button) -> void:
	if not btn or btn.has_meta("anim_bound"):
		return
	btn.set_meta("anim_bound", true)
	btn.resized.connect(func():
		btn.pivot_offset = btn.size * 0.5
	)
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			btn.pivot_offset = btn.size * 0.5
			var tw = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)

func play_pulse_anim(ctrl: Control, peak_scale: float = 1.08) -> void:
	if not ctrl:
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tw = ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2(peak_scale, peak_scale), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func style_button(btn: Button, variant: String = "nav", font_sz: int = 13) -> void:
	if not btn:
		return
	_init_game_fonts()
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.clip_contents = false
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg := Color(0.10, 0.26, 0.42, 0.96)
	var border := Color(0.28, 0.72, 0.96, 1.0)
	var font_col := Color(0.95, 0.98, 1.0, 1.0)
	
	match variant:
		"primary", "gold":
			bg = Color(0.85, 0.58, 0.08, 0.98)
			border = Color(1.0, 0.90, 0.38, 1.0)
			font_col = Color(1.0, 0.99, 0.92, 1.0)
		"action", "battle":
			bg = Color(0.86, 0.22, 0.18, 0.98)
			border = Color(1.0, 0.62, 0.32, 1.0)
			font_col = Color(1.0, 0.98, 0.95, 1.0)
		"success", "emerald":
			bg = Color(0.12, 0.62, 0.34, 0.98)
			border = Color(0.35, 0.95, 0.60, 1.0)
			font_col = Color(0.95, 1.0, 0.96, 1.0)
		"magic", "purple":
			bg = Color(0.44, 0.18, 0.75, 0.98)
			border = Color(0.80, 0.52, 1.0, 1.0)
			font_col = Color(0.98, 0.95, 1.0, 1.0)
		"danger":
			bg = Color(0.72, 0.16, 0.20, 0.98)
			border = Color(1.0, 0.45, 0.48, 1.0)
			font_col = Color(1.0, 0.95, 0.95, 1.0)
		"feed":
			bg = Color(0.82, 0.32, 0.08, 0.98)
			border = Color(1.0, 0.72, 0.25, 1.0)
			font_col = Color(1.0, 0.98, 0.90, 1.0)
		"nav":
			bg = Color(0.10, 0.25, 0.40, 0.96)
			border = Color(0.26, 0.70, 0.94, 1.0)
			font_col = Color(0.92, 0.97, 1.0, 1.0)
			
	var normal_sb = make_panel_style(bg, border, 12, 2, 0, 10, 4)
	normal_sb.border_width_bottom = 3
	
	var hover_sb = make_panel_style(bg.lightened(0.14), border.lightened(0.2), 12, 2, 0, 10, 4)
	hover_sb.border_width_bottom = 3
	
	var pressed_sb = make_panel_style(bg.darkened(0.15), border, 12, 2, 0, 10, 4)
	pressed_sb.border_width_top = 3
	pressed_sb.border_width_bottom = 2
	
	var disabled_sb = make_panel_style(Color(0.14, 0.17, 0.22, 0.82), Color(0.32, 0.38, 0.44, 0.6), 12, 2, 0, 10, 4)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", hover_sb)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	
	btn.add_theme_font_override("font", title_font if font_sz >= 14 else body_font)
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.60, 0.66))
	btn.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.10, 0.95))
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bind_button_anim(btn)
	
	if btn is OptionButton:
		var popup: PopupMenu = btn.get_popup()
		if popup:
			var pop_sb = make_panel_style(Color(0.04, 0.12, 0.22, 0.98), COLOR_CYAN_BORDER, 12, 2, 0, 10, 8)
			var pop_hov = make_panel_style(Color(0.12, 0.30, 0.48, 0.98), COLOR_GOLD, 8, 1, 0, 6, 4)
			popup.add_theme_stylebox_override("panel", pop_sb)
			popup.add_theme_stylebox_override("hover", pop_hov)

func style_slider(slider: HSlider) -> void:
	if not slider:
		return
	slider.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var track_sb = make_panel_style(Color(0.03, 0.08, 0.15, 0.95), Color(0.20, 0.55, 0.80, 0.8), 8, 1, 0, 4, 6)
	var fill_sb = make_panel_style(Color(0.22, 0.78, 0.98, 0.95), Color(0.45, 0.92, 1.0, 1.0), 8, 1, 0, 4, 6)
	slider.add_theme_stylebox_override("slider", track_sb)
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)

## Ensures a large, front-most, unblocked Top-Right Corner '✖' Button exists on every modal
func ensure_top_close_button(panel: Panel, modal_w: float) -> Button:
	var top_x_btn: Button = null
	if panel.has_node("CloseBtn") and panel.get_node("CloseBtn").get_parent() == panel:
		top_x_btn = panel.get_node("CloseBtn")
	elif panel.has_node("TopCloseBtn"):
		top_x_btn = panel.get_node("TopCloseBtn")
	else:
		top_x_btn = Button.new()
		top_x_btn.name = "TopCloseBtn"
		panel.add_child(top_x_btn)
		
	top_x_btn.text = "✖"
	style_button(top_x_btn, "danger", 16)
	place_rect(top_x_btn, modal_w - 54.0, 10.0, 44.0, 38.0)
	top_x_btn.z_index = 60
	top_x_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.move_child(top_x_btn, panel.get_child_count() - 1)
	
	if not top_x_btn.has_meta("close_wired"):
		top_x_btn.set_meta("close_wired", true)
		top_x_btn.pressed.connect(func():
			panel.visible = false
		)
	return top_x_btn

## Styles a modal Panel with smooth 20px rounded corners, custom game fonts, and unblocked Close buttons
func style_modal(panel: Panel, accent_color: Color = COLOR_CYAN_BORDER, desired_size: Vector2 = Vector2(640, 460)) -> void:
	if not panel:
		return
	_init_game_fonts()
	enforce_ltr_recursive(panel)
	panel.clip_contents = false
	var sb = make_panel_style(Color(0.04, 0.12, 0.22, 0.98), accent_color, 20, 3, 0, 16, 12)
	panel.add_theme_stylebox_override("panel", sb)
	
	var w = clampf(desired_size.x, 320.0, 1220.0)
	var h = clampf(desired_size.y, 220.0, 660.0)
	
	var x = roundf((SCREEN_W - w) * 0.5)
	var y = roundf((SCREEN_H - h) * 0.5) if h > 540.0 else roundf(62.0 + (610.0 - h) * 0.5)
	place_rect(panel, x, y, w, h)
	
	if panel.has_node("VBox"):
		var vbox: VBoxContainer = panel.get_node("VBox")
		fit_inner_container(panel, vbox, 22.0, 18.0)
		vbox.add_theme_constant_override("separation", 8)
		if vbox.has_node("CloseBtn"):
			var bot_close: Button = vbox.get_node("CloseBtn")
			bot_close.custom_minimum_size = Vector2(140, 36)
			bot_close.mouse_filter = Control.MOUSE_FILTER_STOP
			if not bot_close.has_meta("close_wired"):
				bot_close.set_meta("close_wired", true)
				bot_close.pressed.connect(func(): panel.visible = false)
				
	ensure_top_close_button(panel, w)

func animate_modal_open(panel: Control) -> void:
	if not panel:
		return
	panel.visible = true
	if panel is Panel:
		ensure_top_close_button(panel, panel.size.x)
	panel.scale = Vector2.ONE
	panel.modulate.a = 0.0
	var tw = panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.12)

func style_progress_bar(bar: ProgressBar, fill_col: Color, bg_col: Color = Color(0.02, 0.07, 0.13, 0.92)) -> void:
	if not bar:
		return
	bar.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = bg_col
	bg_sb.border_color = fill_col.darkened(0.35)
	bg_sb.set_border_width_all(1)
	bg_sb.set_corner_radius_all(8)
	bg_sb.corner_detail = 12
	bg_sb.anti_aliasing = true
	
	var fill_sb = StyleBoxFlat.new()
	fill_sb.bg_color = fill_col
	fill_sb.set_corner_radius_all(7)
	fill_sb.corner_detail = 12
	fill_sb.anti_aliasing = true
	
	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fill_sb)

func style_label(lbl: Label, size: int = 15, col: Color = Color.WHITE, outline: int = 4) -> void:
	if not lbl:
		return
	_init_game_fonts()
	lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lbl.structured_text_bidi_override = TextServer.STRUCTURED_TEXT_DEFAULT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", title_font if size >= 17 else body_font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.10, 0.96))
	lbl.add_theme_constant_override("outline_size", maxi(outline, 3))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_constant_override("shadow_outline_size", 3)

func create_unit_card(
	tower_id: String,
	level: int = 1,
	trait_id: String = "none",
	is_equipped: bool = false,
	cost_override: int = -1,
	card_size: Vector2 = Vector2(116, 122),
	selection_mode: String = "",
	badge_override: String = "",
	is_locked: bool = false
) -> Button:
	_init_game_fonts()
	var t_data = GameData.TOWERS.get(tower_id, {})
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color(0.4, 0.75, 1.0))
	var r_name: String = GameData.RARITY_NAMES.get(r_enum, "Common")
	var trait_data: Dictionary = GameData.TRAITS.get(trait_id, GameData.TRAITS["none"])
	var has_trait: bool = (trait_id != "none" and trait_id != "" and GameData.TRAITS.has(trait_id))
	var tr_col: Color = trait_data.get("color", Color(0.48, 0.88, 1.0))
	var tr_glow: Color = trait_data.get("glow_color", Color(1.0, 0.90, 0.30))
	var tr_icon_path: String = str(trait_data.get("icon", ""))
	
	var btn = Button.new()
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.custom_minimum_size = card_size
	btn.pivot_offset = card_size * 0.5
	btn.clip_contents = false
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var bg_col = Color(0.06, 0.16, 0.28, 0.96)
	var border_col = r_col
	var border_w = 2
	
	if has_trait:
		bg_col = bg_col.lerp(Color(tr_col.r * 0.32, tr_col.g * 0.32, tr_col.b * 0.32, 0.98), 0.45)
		border_col = r_col.lerp(tr_col, 0.55)
		
	if is_equipped:
		bg_col = Color(0.06, 0.24, 0.22, 0.98)
		border_col = Color(0.25, 0.96, 0.55)
		
	match selection_mode:
		"selected":
			bg_col = Color(0.11, 0.28, 0.46, 0.99)
			border_col = Color(1.0, 0.88, 0.22)
			border_w = 3
		"feed_target":
			bg_col = Color(0.16, 0.26, 0.12, 0.99)
			border_col = Color(1.0, 0.88, 0.20)
			border_w = 3
		"feed_material":
			bg_col = Color(0.36, 0.11, 0.08, 0.99)
			border_col = Color(1.0, 0.45, 0.16)
			border_w = 3
		"trade_selected":
			bg_col = Color(0.08, 0.32, 0.24, 0.99)
			border_col = Color(0.25, 1.0, 0.65)
			border_w = 3
		"bounty_selected":
			bg_col = Color(0.24, 0.18, 0.06, 0.99)
			border_col = Color(1.0, 0.86, 0.22)
			border_w = 3
		"lab_selected":
			bg_col = Color(0.08, 0.28, 0.22, 0.99)
			border_col = Color(0.30, 1.0, 0.58)
			border_w = 3
	
	var normal_sb = make_panel_style(bg_col, border_col, 14, border_w, 0, 6, 4)
	normal_sb.border_width_bottom = border_w + 1
	var hover_sb = make_panel_style(bg_col.lightened(0.14), border_col.lightened(0.22), 14, border_w, 0, 6, 4)
	hover_sb.border_width_bottom = border_w + 1
	var pressed_sb = make_panel_style(bg_col.darkened(0.12), border_col, 14, border_w, 0, 6, 4)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", hover_sb)
	bind_button_anim(btn)
	
	# Trait Layer 1: Elegant Radiant Aura Glow (Steady, rich, non-distracting prestige glow)
	if has_trait:
		var aura_glow = Panel.new()
		aura_glow.name = "TraitAuraGlow"
		aura_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var aura_sb = make_panel_style(
			Color(tr_col.r, tr_col.g, tr_col.b, 0.12),
			Color(tr_glow.r, tr_glow.g, tr_glow.b, 0.90),
			12, 2, 0, 0, 0
		)
		aura_sb.border_blend = true
		aura_glow.add_theme_stylebox_override("panel", aura_sb)
		btn.add_child(aura_glow)
		place_rect(aura_glow, 2.0, 2.0, card_size.x - 4.0, card_size.y - 4.0)
		aura_glow.ready.connect(func():
			var tw = aura_glow.create_tween().set_loops()
			tw.tween_property(aura_glow, "modulate:a", 0.82, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(aura_glow, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		)
	
	var margin = MarginContainer.new()
	margin.layout_direction = Control.LAYOUT_DIRECTION_LTR
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# 1. Top Rarity & Level Row
	var top_row = HBoxContainer.new()
	top_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r_lbl = Label.new()
	r_lbl.text = r_name.to_upper()
	r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	style_label(r_lbl, 9, r_col.lightened(0.15), 3)
	
	var lvl_lbl = Label.new()
	lvl_lbl.text = "★Lv.%d" % level if is_equipped else "Lv.%d" % level
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	style_label(lvl_lbl, 9, COLOR_EMERALD if is_equipped else COLOR_GOLD, 3)
	top_row.add_child(r_lbl)
	top_row.add_child(lvl_lbl)
	vbox.add_child(top_row)
	
	# 2. Portrait Icon Box + Animated Trait Portrait Aura Ring
	var icon_sz = clampf(card_size.y - 64.0, 26.0, 44.0)
	var icon_frame = PanelContainer.new()
	icon_frame.layout_direction = Control.LAYOUT_DIRECTION_LTR
	icon_frame.custom_minimum_size = Vector2(icon_sz + 8, icon_sz + 8)
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_sb = StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.03, 0.08, 0.15, 0.92).lerp(Color(tr_col.r * 0.4, tr_col.g * 0.4, tr_col.b * 0.4, 0.95), 0.45 if has_trait else 0.0)
	frame_sb.border_color = tr_col.lightened(0.15) if has_trait else border_col
	frame_sb.set_border_width_all(2 if (selection_mode != "" or has_trait) else 1)
	frame_sb.set_corner_radius_all(10)
	frame_sb.corner_detail = 12
	frame_sb.anti_aliasing = true
	icon_frame.add_theme_stylebox_override("panel", frame_sb)
	
	var portrait_stack = Control.new()
	portrait_stack.custom_minimum_size = Vector2(icon_sz, icon_sz)
	portrait_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(portrait_stack)
	
	if has_trait:
		var fx_ring = Panel.new()
		fx_ring.name = "TraitPortraitFX"
		fx_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ring_sb = make_panel_style(
			Color(tr_col.r, tr_col.g, tr_col.b, 0.18),
			tr_glow.lightened(0.15),
			int(icon_sz * 0.5), 1, 0, 0, 0
		)
		fx_ring.add_theme_stylebox_override("panel", ring_sb)
		portrait_stack.add_child(fx_ring)
		place_rect(fx_ring, 0.0, 0.0, icon_sz, icon_sz)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_sz, icon_sz)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset_p = "res://assets/%s.svg" % tower_id
	if ResourceLoader.exists(asset_p):
		icon.texture = load(asset_p)
	portrait_stack.add_child(icon)
	place_rect(icon, 0.0, 0.0, icon_sz, icon_sz)
	vbox.add_child(icon_frame)
	
	# 3. Unit Name
	var name_lbl = Label.new()
	name_lbl.text = t_data.get("name", tower_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	style_label(name_lbl, 11, Color.WHITE, 3)
	vbox.add_child(name_lbl)
	
	# 4. Trait Emblem + Name or Action State Footer
	var footer_hbox = HBoxContainer.new()
	footer_hbox.name = "FooterRow"
	footer_hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_hbox.add_theme_constant_override("separation", 3)
	footer_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(footer_hbox)
	
	var show_inline_trait_icon := false
	var footer_lbl = Label.new()
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if badge_override != "":
		footer_lbl.text = badge_override
		style_label(footer_lbl, 9, border_col.lightened(0.2), 3)
	elif selection_mode == "feed_material":
		footer_lbl.text = "🔥 FEED ✓ (+%d XP)" % (level * 120)
		style_label(footer_lbl, 9, Color(1.0, 0.62, 0.22), 3)
	elif selection_mode == "feed_target":
		footer_lbl.text = "👑 UPGRADE TARGET"
		style_label(footer_lbl, 9, COLOR_GOLD, 3)
	elif selection_mode == "trade_selected":
		footer_lbl.text = "✅ OFFERED"
		style_label(footer_lbl, 9, Color(0.35, 1.0, 0.68), 3)
	elif selection_mode == "bounty_selected":
		footer_lbl.text = "🎯 SELECTED"
		style_label(footer_lbl, 9, COLOR_GOLD, 3)
	elif has_trait:
		show_inline_trait_icon = true
		var tr_name = trait_data.get("name", "None")
		footer_lbl.text = tr_name
		style_label(footer_lbl, 9, tr_col.lightened(0.25), 3)
	elif selection_mode == "lab_selected":
		footer_lbl.text = "🧪 IN CHAMBER"
		style_label(footer_lbl, 9, Color(0.35, 1.0, 0.62), 3)
	elif is_equipped:
		footer_lbl.text = "★ EQUIPPED"
		style_label(footer_lbl, 9, COLOR_EMERALD, 3)
	elif cost_override > 0:
		footer_lbl.text = "$%d" % cost_override
		style_label(footer_lbl, 10, COLOR_GOLD, 3)
	else:
		footer_lbl.text = "[No Trait]"
		style_label(footer_lbl, 9, Color(0.62, 0.70, 0.78), 3)
		
	if show_inline_trait_icon and tr_icon_path != "" and ResourceLoader.exists(tr_icon_path):
		var mini_emblem = TextureRect.new()
		mini_emblem.name = "InlineTraitIcon"
		mini_emblem.texture = load(tr_icon_path)
		mini_emblem.custom_minimum_size = Vector2(13, 13)
		mini_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mini_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mini_emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mini_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer_hbox.add_child(mini_emblem)
	footer_hbox.add_child(footer_lbl)
	
	# Dedicated Pinned Placement Cost Pill (Guaranteed 100% visible, never cut off, never hidden)
	if cost_override > 0:
		var cost_badge = PanelContainer.new()
		cost_badge.name = "CostBadge"
		cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_badge.z_index = 8
		var cost_sb = make_panel_style(Color(0.02, 0.08, 0.16, 0.98), Color(1.0, 0.84, 0.22), 10, 2, 0, 4, 1)
		cost_badge.add_theme_stylebox_override("panel", cost_sb)
		
		var cost_box = HBoxContainer.new()
		cost_box.name = "CostHBox"
		cost_box.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_box.add_theme_constant_override("separation", 3)
		cost_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_badge.add_child(cost_box)
		
		var cost_icon = Label.new()
		cost_icon.text = "💵"
		style_label(cost_icon, 10, Color.WHITE, 2)
		cost_box.add_child(cost_icon)
		
		var cost_lbl = Label.new()
		cost_lbl.name = "CostLabel"
		cost_lbl.text = "$%d" % cost_override
		style_label(cost_lbl, 11, Color(1.0, 0.90, 0.25), 3)
		cost_box.add_child(cost_lbl)
		
		btn.add_child(cost_badge)
		var badge_w = clampf(card_size.x - 14.0, 60.0, 96.0)
		var badge_x = roundf((card_size.x - badge_w) * 0.5)
		place_rect(cost_badge, badge_x, card_size.y - 23.0, badge_w, 20.0)
		btn.set_meta("cost", cost_override)
		btn.set_meta("placement_cost", cost_override)
	
	# Trait Layer 3: Floating Custom SVG Trait Emblem Medallion on the Card
	if has_trait and tr_icon_path != "" and ResourceLoader.exists(tr_icon_path):
		var badge_panel = PanelContainer.new()
		badge_panel.name = "TraitEmblemBadge"
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.z_index = 6
		var b_sb = make_panel_style(Color(0.03, 0.08, 0.16, 0.96), tr_glow, 12, 2, 0, 2, 2)
		badge_panel.add_theme_stylebox_override("panel", b_sb)
		
		var badge_tex = TextureRect.new()
		badge_tex.name = "TraitEmblemIcon"
		badge_tex.texture = load(tr_icon_path)
		badge_tex.custom_minimum_size = Vector2(18, 18)
		badge_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_child(badge_tex)
		btn.add_child(badge_panel)
		place_rect(badge_panel, card_size.x - 28.0, 17.0, 22.0, 22.0)
		badge_panel.ready.connect(func():
			var btw = badge_panel.create_tween().set_loops()
			btw.tween_property(badge_panel, "modulate:a", 0.88, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			btw.tween_property(badge_panel, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		)
	
	if is_locked:
		var lock_panel = PanelContainer.new()
		lock_panel.name = "UnitLockBadge"
		lock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_panel.z_index = 7
		var lk_sb = make_panel_style(Color(0.18, 0.04, 0.04, 0.96), Color(1.0, 0.35, 0.35), 8, 1, 0, 2, 1)
		lock_panel.add_theme_stylebox_override("panel", lk_sb)
		var lk_lbl = Label.new()
		lk_lbl.text = "🔒"
		style_label(lk_lbl, 10, Color(1.0, 0.85, 0.35), 2)
		lock_panel.add_child(lk_lbl)
		btn.add_child(lock_panel)
		place_rect(lock_panel, 5.0, 18.0, 22.0, 22.0)
	
	btn.set_meta("is_locked", is_locked)
	btn.set_meta("trait_id", trait_id)
	btn.set_meta("has_trait_fx", has_trait)
	return btn

## Creates a Summon Shop Roster Card:
## - Locked (`is_unlocked == false`): Dark silhouette portrait + '?' mystery badge + '???' name + Power Class
## - Unlocked (`is_unlocked == true`): Full-color character portrait + clear character name + Power Class & Rating
func create_shop_roster_card(
	tower_id: String,
	is_unlocked: bool,
	owned_count: int = 0,
	just_pulled_count: int = 0,
	is_selected: bool = false,
	card_size: Vector2 = Vector2(120, 122)
) -> Button:
	_init_game_fonts()
	var t_data = GameData.TOWERS.get(tower_id, {})
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color(0.4, 0.75, 1.0))
	var r_name: String = GameData.RARITY_NAMES.get(r_enum, "Common")
	var p_class_id: String = t_data.get("power_class", "brawler")
	var p_class_data: Dictionary = GameData.POWER_CLASSES.get(p_class_id, GameData.POWER_CLASSES["brawler"])
	var p_short: String = p_class_data.get("short", "⚡ Power")
	var p_col: Color = p_class_data.get("color", Color.WHITE)
	var p_rating: int = int(t_data.get("power_rating", 150))
	
	var btn = Button.new()
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.custom_minimum_size = card_size
	btn.pivot_offset = card_size * 0.5
	btn.clip_contents = false
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var bg_col := Color(0.06, 0.17, 0.30, 0.97) if is_unlocked else Color(0.03, 0.06, 0.12, 0.96)
	var border_col := r_col if is_unlocked else r_col.darkened(0.38)
	var border_w := 2
	
	if just_pulled_count > 0:
		bg_col = Color(0.16, 0.28, 0.14, 0.99)
		border_col = Color(1.0, 0.90, 0.22)
		border_w = 3
	elif is_selected:
		bg_col = Color(0.11, 0.26, 0.44, 0.99)
		border_col = Color(0.35, 0.95, 1.0)
		border_w = 3
		
	var normal_sb = make_panel_style(bg_col, border_col, 14, border_w, 0, 6, 4)
	normal_sb.border_width_bottom = border_w + 1
	var hover_sb = make_panel_style(bg_col.lightened(0.14), border_col.lightened(0.22), 14, border_w, 0, 6, 4)
	hover_sb.border_width_bottom = border_w + 1
	var pressed_sb = make_panel_style(bg_col.darkened(0.12), border_col, 14, border_w, 0, 6, 4)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", hover_sb)
	bind_button_anim(btn)
	
	var margin = MarginContainer.new()
	margin.layout_direction = Control.LAYOUT_DIRECTION_LTR
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# 1. Top Row: Rarity & Power Score / Owned Count
	var top_row = HBoxContainer.new()
	top_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r_lbl = Label.new()
	r_lbl.text = r_name.to_upper()
	r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	style_label(r_lbl, 9, r_col.lightened(0.18), 3)
	
	var pwr_lbl = Label.new()
	if is_unlocked and owned_count > 1:
		pwr_lbl.text = "x%d" % owned_count
		style_label(pwr_lbl, 9, COLOR_EMERALD, 3)
	else:
		pwr_lbl.text = "⚡%d" % p_rating
		style_label(pwr_lbl, 9, COLOR_GOLD if is_unlocked else Color(0.60, 0.68, 0.78), 3)
	pwr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(r_lbl)
	top_row.add_child(pwr_lbl)
	vbox.add_child(top_row)
	
	# 2. Center Portrait Frame (Mystery Silhouette vs Full Color)
	var icon_sz = clampf(card_size.y - 64.0, 28.0, 44.0)
	var icon_frame = PanelContainer.new()
	icon_frame.layout_direction = Control.LAYOUT_DIRECTION_LTR
	icon_frame.custom_minimum_size = Vector2(icon_sz + 10, icon_sz + 8)
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_sb = StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.04, 0.10, 0.18, 0.94) if is_unlocked else Color(0.02, 0.04, 0.08, 0.98)
	frame_sb.border_color = border_col
	frame_sb.set_border_width_all(2 if (just_pulled_count > 0 or is_selected) else 1)
	frame_sb.set_corner_radius_all(10)
	frame_sb.corner_detail = 12
	frame_sb.anti_aliasing = true
	icon_frame.add_theme_stylebox_override("panel", frame_sb)
	
	var icon = TextureRect.new()
	icon.name = "PortraitIcon"
	icon.custom_minimum_size = Vector2(icon_sz, icon_sz)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset_p = "res://assets/%s.svg" % tower_id
	if ResourceLoader.exists(asset_p):
		icon.texture = load(asset_p)
	if is_unlocked:
		icon.self_modulate = Color.WHITE
	else:
		# Dark mysterious silhouette of the character's shape
		icon.self_modulate = Color(0.02, 0.03, 0.06, 0.96)
	icon_frame.add_child(icon)
	
	if not is_unlocked:
		var q_lbl = Label.new()
		q_lbl.name = "MysteryMark"
		q_lbl.text = "?"
		q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		q_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		style_label(q_lbl, 20, r_col.lightened(0.25), 4)
		icon_frame.add_child(q_lbl)
		
	vbox.add_child(icon_frame)
	
	# 3. Character Name ('???' when locked, Clear Name when unlocked)
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	var disp_name: String = t_data.get("name", tower_id) if is_unlocked else "???"
	name_lbl.text = disp_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	style_label(name_lbl, 11, Color.WHITE if is_unlocked else Color(0.62, 0.70, 0.84), 3)
	vbox.add_child(name_lbl)
	
	# 4. Power Classification / Pull Status Footer
	var footer_lbl = Label.new()
	footer_lbl.name = "ClassFooter"
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if just_pulled_count > 0:
		footer_lbl.text = "✨ NEW x%d! %s" % [just_pulled_count, p_short] if just_pulled_count > 1 else "✨ PULLED! %s" % p_short
		style_label(footer_lbl, 9, COLOR_GOLD, 3)
	elif is_unlocked:
		footer_lbl.text = "✅ %s" % p_short
		style_label(footer_lbl, 9, p_col.lightened(0.15), 3)
	else:
		footer_lbl.text = "🔒 %s" % p_short
		style_label(footer_lbl, 9, p_col.darkened(0.05), 3)
	vbox.add_child(footer_lbl)
	
	btn.set_meta("tower_id", tower_id)
	btn.set_meta("is_unlocked", is_unlocked)
	btn.set_meta("display_name", disp_name)
	btn.set_meta("power_class", p_class_id)
	return btn

