extends Panel

## SummonModal - Grand Oyster Summon Shop, 24-Character Power Index & Interactive Treasure Chest Pack Opening Cinematic
## Sequence on 1x / 10x Summon:
## 1. SummonModal closes with a smooth cartoon shrink+fade animation.
## 2. Pirate Treasure Chest drops in, shakes with golden light, and its lid swings open.
## 3. 1 or 10 Bikini Bottom Fish swim out of the chest in curved arcs with tail-wagging motion.
## 4. Each Fish swells, flashes, and explodes into a starburst + bubbles, and the Character pops out!
## 5. After all characters appear, the Character Specifications Summary Modal opens with portraits, full stats,
##    and a live 10.0-second auto-close countdown timer (or immediate manual close by the player).

@onready var title_label: Label = $VBox/Title
@onready var pity_label: Label = $VBox/PityLabel
@onready var result_scroll: ScrollContainer = $VBox/ResultScroll
@onready var result_container: Control = $VBox/ResultScroll/ResultContainer
@onready var single_btn: Button = $VBox/BtnHBox/SingleBtn
@onready var multi_btn: Button = $VBox/BtnHBox/MultiBtn
@onready var close_btn: Button = $VBox/CloseBtn

var pity_bar: ProgressBar = null
var odds_label: Label = null
var filter_bar: HBoxContainer = null
var filter_buttons: Dictionary = {}
var info_banner: Label = null
var cards_grid: GridContainer = null
var auto_sell_btn: Button = null
var auto_sell_modal: Panel = null
var auto_sell_rarity_buttons: Dictionary = {}
var auto_sell_tower_grid: GridContainer = null

var active_power_filter: String = "all"
var selected_inspect_tid: String = ""
var last_pulled_counts: Dictionary = {}
var last_pulled_units: Array = []

# Pack Opening Cinematic & 10s Summary Modal Nodes
var cinematic_overlay: Control = null
var stage_layer: Control = null
var stage_title_lbl: Label = null
var chest_root: Control = null
var chest_glow: Panel = null
var chest_beam: Panel = null
var chest_base_tex: TextureRect = null
var chest_lid_tex: TextureRect = null
var skip_anim_btn: Button = null

var summary_modal: Panel = null
var summary_countdown_lbl: Label = null
var summary_countdown_bar: ProgressBar = null
var summary_specs_grid: GridContainer = null
var summary_close_btn: Button = null
var summary_reopen_shop_btn: Button = null

var is_playing_cinematic: bool = false
var is_summary_open: bool = false
var summary_time_left: float = 0.0
const SUMMARY_AUTO_CLOSE_SECONDS: float = 10.0
var cinematic_run_id: int = 0
var time_Scale_fast_for_test: float = 1.0

var tex_chest_base: Texture2D = null
var tex_chest_lid: Texture2D = null
var tex_mystery_fish: Texture2D = null
var tex_explosion_star: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/chest_base.svg"):
		tex_chest_base = load("res://assets/chest_base.svg")
	if ResourceLoader.exists("res://assets/chest_lid.svg"):
		tex_chest_lid = load("res://assets/chest_lid.svg")
	if ResourceLoader.exists("res://assets/mystery_fish.svg"):
		tex_mystery_fish = load("res://assets/mystery_fish.svg")
	if ResourceLoader.exists("res://assets/explosion_star.svg"):
		tex_explosion_star = load("res://assets/explosion_star.svg")
		
	UIThemeBuilder.style_modal(self, Color(1.0, 0.82, 0.22), Vector2(760, 526))
	UIThemeBuilder.fit_inner_container(self, $VBox, 20.0, 14.0)
	$VBox.add_theme_constant_override("separation", 5)
	
	title_label.text = "🐚 GRAND OYSTER SHOP & CHARACTER INDEX ✨"
	UIThemeBuilder.style_label(title_label, 19, Color(1.0, 0.88, 0.22), 4)
	UIThemeBuilder.style_label(pity_label, 13, Color(0.45, 0.92, 1.0), 3)
	
	# Pity Progress Bar
	pity_bar = ProgressBar.new()
	pity_bar.custom_minimum_size = Vector2(380, 10)
	pity_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pity_bar.max_value = PlayerData.PITY_THRESHOLD
	pity_bar.show_percentage = false
	UIThemeBuilder.style_progress_bar(pity_bar, Color(1.0, 0.78, 0.15))
	$VBox.add_child(pity_bar)
	$VBox.move_child(pity_bar, 2)
	
	# Compact Odds Legend across all 6 Rarity Tiers
	odds_label = Label.new()
	odds_label.text = "RATES: Common 52% • Rare 26% • Epic 13% • Legendary 6.5% • Mythic 2% • Secret 0.5%"
	odds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(odds_label, 11, Color(0.78, 0.88, 0.98), 3)
	$VBox.add_child(odds_label)
	$VBox.move_child(odds_label, 3)
	
	# Power Classification Filter Tabs (Filter by Power Class)
	filter_bar = HBoxContainer.new()
	filter_bar.name = "PowerFilterBar"
	filter_bar.layout_direction = Control.LAYOUT_DIRECTION_LTR
	filter_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_bar.add_theme_constant_override("separation", 5)
	filter_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	for cid in GameData.POWER_CLASS_ORDER:
		var cdata = GameData.POWER_CLASSES[cid]
		var fbtn = Button.new()
		fbtn.text = cdata["short"]
		fbtn.custom_minimum_size = Vector2(82, 26)
		var captured_cid: String = cid
		fbtn.pressed.connect(func():
			active_power_filter = captured_cid
			_refresh_filter_buttons()
			_populate_shop_roster()
		)
		filter_bar.add_child(fbtn)
		filter_buttons[cid] = fbtn
	$VBox.add_child(filter_bar)
	$VBox.move_child(filter_bar, 4)
	_refresh_filter_buttons()
	
	# Configure ResultScroll to hold the 5-column Character Roster Grid
	var scroll_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.15, 0.92), Color(0.22, 0.58, 0.88, 0.70), 16, 2, 0, 10, 8)
	result_scroll.add_theme_stylebox_override("panel", scroll_sb)
	result_scroll.custom_minimum_size = Vector2(0, 210)
	result_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	result_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	result_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if result_container is HBoxContainer:
		result_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_grid = GridContainer.new()
	cards_grid.name = "RosterGrid"
	cards_grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
	cards_grid.columns = 5
	cards_grid.add_theme_constant_override("h_separation", 10)
	cards_grid.add_theme_constant_override("v_separation", 8)
	cards_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	result_container.add_child(cards_grid)
	
	# Inspector / Discovery Banner
	info_banner = Label.new()
	info_banner.name = "InfoBanner"
	info_banner.text = "💡 Click any character card to inspect its Power Class & Stats! Summon to reveal Mystery Silhouettes (???)."
	info_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UIThemeBuilder.style_label(info_banner, 11, Color(1.0, 0.88, 0.32), 3)
	$VBox.add_child(info_banner)
	$VBox.move_child(info_banner, $VBox.get_child_count() - 3)
	
	single_btn.text = "🐚 1x Summon (50 💎)"
	multi_btn.text = "✨ 10x Summon (450 💎)"
	close_btn.text = "✖ Close"
	
	single_btn.custom_minimum_size = Vector2(185, 36)
	multi_btn.custom_minimum_size = Vector2(205, 36)
	close_btn.custom_minimum_size = Vector2(120, 30)
	
	UIThemeBuilder.style_button(single_btn, "nav", 13)
	UIThemeBuilder.style_button(multi_btn, "primary", 13)
	UIThemeBuilder.style_button(close_btn, "danger", 12)
	
	if auto_sell_btn == null and has_node("VBox/BtnHBox"):
		auto_sell_btn = Button.new()
		auto_sell_btn.name = "AutoSellBtn"
		auto_sell_btn.text = "⚙️ Auto-Sell"
		auto_sell_btn.custom_minimum_size = Vector2(145, 36)
		UIThemeBuilder.style_button(auto_sell_btn, "magic", 12)
		$VBox/BtnHBox.add_child(auto_sell_btn)
		auto_sell_btn.pressed.connect(_open_auto_sell_modal)
	
	single_btn.pressed.connect(_on_single_summon)
	multi_btn.pressed.connect(_on_multi_summon)
	close_btn.pressed.connect(func(): visible = false)
	
	call_deferred("_build_pack_opening_cinematic_ui")
	PlayerData.inventory_changed.connect(refresh_view)
	refresh_view()

func _process(delta: float) -> void:
	if is_summary_open and summary_modal and summary_modal.visible:
		summary_time_left -= delta
		var clamped_t = maxf(0.0, summary_time_left)
		if summary_countdown_bar:
			summary_countdown_bar.value = clamped_t
		if summary_countdown_lbl:
			summary_countdown_lbl.text = "⏱️ Auto-Closing in %.1fs   •   🎉 %d Character(s) Unlocked & Added!" % [
				clamped_t, last_pulled_units.size()
			]
		if summary_close_btn:
			summary_close_btn.text = "✖ Close Now (%.0fs)" % ceilf(clamped_t)
		if summary_time_left <= 0.0:
			close_pack_summary(false)

func is_cinematic_or_summary_active() -> bool:
	return is_playing_cinematic or is_summary_open

func _build_pack_opening_cinematic_ui() -> void:
	var hud_parent = get_parent()
	if not hud_parent:
		return
		
	cinematic_overlay = Control.new()
	cinematic_overlay.name = "PackOpeningOverlay"
	cinematic_overlay.visible = false
	cinematic_overlay.z_index = 45
	cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_parent.add_child(cinematic_overlay)
	UIThemeBuilder.place_rect(cinematic_overlay, 0.0, 0.0, 1280.0, 720.0)
	
	var dark_bg = ColorRect.new()
	dark_bg.color = Color(0.01, 0.05, 0.12, 0.88)
	dark_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	cinematic_overlay.add_child(dark_bg)
	UIThemeBuilder.place_rect(dark_bg, 0.0, 0.0, 1280.0, 720.0)
	
	# Stage Layer for Chest + Swimming Fish + Explosions + Emerging Characters
	stage_layer = Control.new()
	stage_layer.name = "StageLayer"
	stage_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	cinematic_overlay.add_child(stage_layer)
	UIThemeBuilder.place_rect(stage_layer, 0.0, 0.0, 1280.0, 720.0)
	
	stage_title_lbl = Label.new()
	stage_title_lbl.name = "StageTitle"
	stage_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_layer.add_child(stage_title_lbl)
	UIThemeBuilder.place_rect(stage_title_lbl, 190.0, 68.0, 900.0, 38.0)
	UIThemeBuilder.style_label(stage_title_lbl, 22, Color(1.0, 0.90, 0.25), 5)
	
	# Pirate Treasure Chest Assembly (Bottom Center)
	chest_root = Control.new()
	chest_root.name = "TreasureChestRoot"
	chest_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(chest_root)
	UIThemeBuilder.place_rect(chest_root, 550.0, 488.0, 180.0, 160.0)
	
	chest_glow = Panel.new()
	chest_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb = UIThemeBuilder.make_panel_style(Color(1.0, 0.82, 0.18, 0.28), Color(1.0, 0.92, 0.42, 0.75), 60, 2, 0, 0, 0)
	chest_glow.add_theme_stylebox_override("panel", glow_sb)
	chest_root.add_child(chest_glow)
	UIThemeBuilder.place_rect(chest_glow, -25.0, 15.0, 230.0, 135.0)
	
	chest_beam = Panel.new()
	chest_beam.visible = false
	chest_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var beam_sb = UIThemeBuilder.make_panel_style(Color(1.0, 0.95, 0.45, 0.48), Color(0.35, 0.98, 1.0, 0.85), 35, 2, 0, 0, 0)
	chest_beam.add_theme_stylebox_override("panel", beam_sb)
	chest_root.add_child(chest_beam)
	UIThemeBuilder.place_rect(chest_beam, 15.0, -70.0, 150.0, 130.0)
	
	chest_base_tex = TextureRect.new()
	chest_base_tex.name = "ChestBase"
	chest_base_tex.texture = tex_chest_base
	chest_base_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_base_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_base_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_root.add_child(chest_base_tex)
	UIThemeBuilder.place_rect(chest_base_tex, 0.0, 48.0, 180.0, 110.0)
	
	chest_lid_tex = TextureRect.new()
	chest_lid_tex.name = "ChestLid"
	chest_lid_tex.texture = tex_chest_lid
	chest_lid_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_lid_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_lid_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_root.add_child(chest_lid_tex)
	UIThemeBuilder.place_rect(chest_lid_tex, 0.0, 0.0, 180.0, 72.0)
	chest_lid_tex.pivot_offset = Vector2(90.0, 66.0)
	
	skip_anim_btn = Button.new()
	skip_anim_btn.name = "SkipAnimBtn"
	skip_anim_btn.text = "⏭️ Skip to Specs"
	stage_layer.add_child(skip_anim_btn)
	UIThemeBuilder.style_button(skip_anim_btn, "nav", 13)
	UIThemeBuilder.place_rect(skip_anim_btn, 1080.0, 650.0, 168.0, 40.0)
	skip_anim_btn.pressed.connect(func():
		if is_playing_cinematic:
			cinematic_run_id += 1
			_open_summary_specs_modal()
	)
	
	# 5. Pulled Characters & Specifications Modal (10-Second Auto-Close + Manual Close)
	summary_modal = Panel.new()
	summary_modal.name = "PackSummaryModal"
	summary_modal.visible = false
	cinematic_overlay.add_child(summary_modal)
	
	var sum_vbox = VBoxContainer.new()
	sum_vbox.name = "VBox"
	sum_vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	sum_vbox.add_theme_constant_override("separation", 6)
	summary_modal.add_child(sum_vbox)
	
	UIThemeBuilder.style_modal(summary_modal, Color(1.0, 0.86, 0.22), Vector2(780, 524))
	UIThemeBuilder.fit_inner_container(summary_modal, sum_vbox, 22.0, 16.0)
	
	# Wire summary_modal's TopCloseBtn to close_pack_summary
	var top_x: Button = summary_modal.get_node_or_null("TopCloseBtn")
	if top_x:
		top_x.pressed.connect(func(): close_pack_summary(false))
		
	var sum_title = Label.new()
	sum_title.name = "Title"
	sum_title.text = "🎁 TREASURE PACK UNBOXED — CHARACTER SPECS ✨"
	sum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(sum_title, 19, Color(1.0, 0.90, 0.24), 4)
	sum_vbox.add_child(sum_title)
	
	summary_countdown_lbl = Label.new()
	summary_countdown_lbl.name = "CountdownLabel"
	summary_countdown_lbl.text = "⏱️ Auto-Closing in 10.0s"
	summary_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(summary_countdown_lbl, 13, Color(0.38, 0.98, 0.68), 3)
	sum_vbox.add_child(summary_countdown_lbl)
	
	summary_countdown_bar = ProgressBar.new()
	summary_countdown_bar.name = "CountdownBar"
	summary_countdown_bar.custom_minimum_size = Vector2(460, 10)
	summary_countdown_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary_countdown_bar.max_value = SUMMARY_AUTO_CLOSE_SECONDS
	summary_countdown_bar.value = SUMMARY_AUTO_CLOSE_SECONDS
	summary_countdown_bar.show_percentage = false
	UIThemeBuilder.style_progress_bar(summary_countdown_bar, Color(0.22, 0.92, 0.55))
	sum_vbox.add_child(summary_countdown_bar)
	
	var specs_scroll = ScrollContainer.new()
	specs_scroll.name = "SpecsScroll"
	specs_scroll.layout_direction = Control.LAYOUT_DIRECTION_LTR
	specs_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	specs_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	specs_scroll.custom_minimum_size = Vector2(0, 340)
	specs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var specs_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.15, 0.94), Color(0.22, 0.62, 0.92, 0.72), 14, 2, 0, 10, 8)
	specs_scroll.add_theme_stylebox_override("panel", specs_sb)
	sum_vbox.add_child(specs_scroll)
	
	var specs_center = HBoxContainer.new()
	specs_center.layout_direction = Control.LAYOUT_DIRECTION_LTR
	specs_center.alignment = BoxContainer.ALIGNMENT_CENTER
	specs_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	specs_center.mouse_filter = Control.MOUSE_FILTER_PASS
	specs_scroll.add_child(specs_center)
	
	summary_specs_grid = GridContainer.new()
	summary_specs_grid.name = "SpecsGrid"
	summary_specs_grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
	summary_specs_grid.columns = 2
	summary_specs_grid.add_theme_constant_override("h_separation", 10)
	summary_specs_grid.add_theme_constant_override("v_separation", 8)
	summary_specs_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	specs_center.add_child(summary_specs_grid)
	
	var bot_row = HBoxContainer.new()
	bot_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 16)
	bot_row.mouse_filter = Control.MOUSE_FILTER_PASS
	sum_vbox.add_child(bot_row)
	
	summary_reopen_shop_btn = Button.new()
	summary_reopen_shop_btn.name = "ReopenShopBtn"
	summary_reopen_shop_btn.text = "🐚 Back to Summon Shop"
	summary_reopen_shop_btn.custom_minimum_size = Vector2(210, 38)
	UIThemeBuilder.style_button(summary_reopen_shop_btn, "primary", 13)
	summary_reopen_shop_btn.pressed.connect(func():
		close_pack_summary(true)
		refresh_view()
		UIThemeBuilder.animate_modal_open(self)
	)
	bot_row.add_child(summary_reopen_shop_btn)
	
	summary_close_btn = Button.new()
	summary_close_btn.name = "CloseSummaryBtn"
	summary_close_btn.text = "✖ Close Now (10s)"
	summary_close_btn.custom_minimum_size = Vector2(190, 38)
	UIThemeBuilder.style_button(summary_close_btn, "danger", 13)
	summary_close_btn.pressed.connect(func():
		close_pack_summary(false)
	)
	bot_row.add_child(summary_close_btn)
	
	UIThemeBuilder.ensure_top_close_button(summary_modal, 780.0)

func _refresh_filter_buttons() -> void:
	for cid in filter_buttons.keys():
		var btn: Button = filter_buttons[cid]
		var variant = "gold" if cid == active_power_filter else "nav"
		UIThemeBuilder.style_button(btn, variant, 11)

func refresh_view() -> void:
	var unlocked_cnt = PlayerData.get_unlocked_count()
	var total_cnt = GameData.TOWER_ORDER.size()
	var inv_cnt = PlayerData.get_inventory_count()
	var inv_max = PlayerData.MAX_INVENTORY_CAPACITY
	pity_label.text = "🔥 Pity: %d / %d   •   🎒 Capacity: %d / %d   •   📖 Index: %d / %d   •   💎 Gems: %d" % [
		PlayerData.pity_counter, PlayerData.PITY_THRESHOLD, inv_cnt, inv_max, unlocked_cnt, total_cnt, PlayerData.gems
	]
	if pity_bar:
		pity_bar.value = PlayerData.pity_counter
	_populate_shop_roster()

func _populate_shop_roster(animate_pulls: bool = false) -> void:
	if not cards_grid:
		return
	for c in cards_grid.get_children():
		cards_grid.remove_child(c)
		c.queue_free()
		
	var ordered_ids: Array = []
	if animate_pulls and not last_pulled_counts.is_empty():
		for tid in GameData.TOWER_ORDER:
			if last_pulled_counts.has(tid) and _matches_filter(tid):
				ordered_ids.append(tid)
		for tid in GameData.TOWER_ORDER:
			if not last_pulled_counts.has(tid) and _matches_filter(tid):
				ordered_ids.append(tid)
	else:
		for tid in GameData.TOWER_ORDER:
			if _matches_filter(tid):
				ordered_ids.append(tid)
				
	cards_grid.columns = 5
	var delay := 0.0
	for tid in ordered_ids:
		var is_unlocked: bool = PlayerData.is_tower_unlocked(tid)
		var owned_cnt: int = PlayerData.get_owned_count(tid)
		var pulled_cnt: int = int(last_pulled_counts.get(tid, 0))
		var is_sel: bool = (tid == selected_inspect_tid)
		
		var card = UIThemeBuilder.create_shop_roster_card(
			tid,
			is_unlocked,
			owned_cnt,
			pulled_cnt,
			is_sel,
			Vector2(124, 116)
		)
		var captured_tid: String = tid
		card.pressed.connect(func():
			selected_inspect_tid = captured_tid
			_inspect_character(captured_tid)
			_populate_shop_roster(false)
		)
		cards_grid.add_child(card)
		
		if animate_pulls and pulled_cnt > 0:
			card.scale = Vector2(0.2, 0.2)
			var tw = card.create_tween()
			tw.tween_interval(delay)
			tw.tween_property(card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += 0.04

func _matches_filter(tower_id: String) -> bool:
	if active_power_filter == "all":
		return true
	var t_data = GameData.TOWERS.get(tower_id, {})
	return t_data.get("power_class", "") == active_power_filter

func _inspect_character(tower_id: String) -> void:
	if not info_banner:
		return
	var t_data = GameData.TOWERS.get(tower_id, {})
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var r_name = GameData.RARITY_NAMES.get(r_enum, "Common")
	var p_class = GameData.POWER_CLASSES.get(t_data.get("power_class", "brawler"), {})
	var p_name = p_class.get("short", "⚡ Power")
	var p_rating = int(t_data.get("power_rating", 150))
	
	if PlayerData.is_tower_unlocked(tower_id):
		info_banner.text = "🔓 %s [%s • %s • ⚡%d] — DMG: %d | SPA: %.2fs | RNG: %.1fm — %s" % [
			t_data.get("name", tower_id),
			r_name,
			p_name,
			p_rating,
			int(t_data.get("base_damage", 10)),
			float(t_data.get("base_spa", 1.0)),
			float(t_data.get("base_range", 7.0)),
			t_data.get("description", "")
		]
		UIThemeBuilder.style_label(info_banner, 11, Color(0.35, 1.0, 0.65), 3)
	else:
		info_banner.text = "🔒 ??? [MYSTERY %s • %s • ⚡%d] — Summon this character to reveal its portrait and true name!" % [
			r_name.to_upper(),
			p_name,
			p_rating
		]
		UIThemeBuilder.style_label(info_banner, 11, Color(0.78, 0.84, 0.96), 3)

func _on_single_summon() -> void:
	if PlayerData.gems < 50:
		_show_message("⚠️ Not enough Gems! Need 50 💎.")
		return
	if PlayerData.is_inventory_full():
		_show_message("🚫 Inventory Full (50/50 Units)! Sell or feed units, or enable Auto-Sell.")
		return
	PlayerData.add_gems(-50)
	last_pulled_counts.clear()
	var unit = _do_summon()
	var tid: String = unit["tower_id"]
	last_pulled_counts[tid] = 1
	last_pulled_units = [unit]
	selected_inspect_tid = tid
	active_power_filter = "all"
	_refresh_filter_buttons()
	_populate_shop_roster(false)
	_show_pull_summary([unit])
	_play_pack_opening_sequence([unit])

func _on_multi_summon() -> void:
	if PlayerData.gems < 450:
		_show_message("⚠️ Not enough Gems! Need 450 💎.")
		return
	if PlayerData.is_inventory_full():
		_show_message("🚫 Inventory Full (50/50 Units)! Sell or feed units, or enable Auto-Sell.")
		return
	PlayerData.add_gems(-450)
	last_pulled_counts.clear()
	var units = []
	for i in range(10):
		var u = _do_summon()
		units.append(u)
		var tid: String = u["tower_id"]
		last_pulled_counts[tid] = int(last_pulled_counts.get(tid, 0)) + 1
	last_pulled_units = units
	if not units.is_empty():
		selected_inspect_tid = units[0]["tower_id"]
	active_power_filter = "all"
	_refresh_filter_buttons()
	_populate_shop_roster(false)
	_show_pull_summary(units)
	_play_pack_opening_sequence(units)

func _clear_dynamic_stage_nodes() -> void:
	if not stage_layer:
		return
	for c in stage_layer.get_children():
		if c != stage_title_lbl and c != chest_root and c != skip_anim_btn:
			c.queue_free()

func _play_pack_opening_sequence(units: Array) -> void:
	if not cinematic_overlay:
		_build_pack_opening_cinematic_ui()
	cinematic_run_id += 1
	var my_run_id := cinematic_run_id
	is_playing_cinematic = true
	is_summary_open = false
	var spd := maxf(0.05, time_Scale_fast_for_test)
	
	# 1. Smoothly animate SummonModal closing (scale down + fade out)
	pivot_offset = size * 0.5
	var close_tw = create_tween().set_parallel(true)
	close_tw.tween_property(self, "scale", Vector2(0.80, 0.80), 0.22 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	close_tw.tween_property(self, "modulate:a", 0.0, 0.20 * spd)
	await close_tw.finished
	visible = false
	scale = Vector2.ONE
	modulate.a = 1.0
	if my_run_id != cinematic_run_id:
		return
		
	# 2. Show Cinematic Stage & Drop in the Pirate Treasure Chest
	_clear_dynamic_stage_nodes()
	summary_modal.visible = false
	stage_layer.visible = true
	cinematic_overlay.visible = true
	stage_title_lbl.text = "🏴‍☠️ OPENING BIKINI BOTTOM TREASURE CHEST... ✨"
	
	chest_beam.visible = false
	UIThemeBuilder.place_rect(chest_lid_tex, 0.0, 0.0, 180.0, 72.0)
	chest_lid_tex.rotation_degrees = 0.0
	chest_lid_tex.scale = Vector2.ONE
	
	UIThemeBuilder.place_rect(chest_root, 550.0, 320.0, 180.0, 160.0)
	chest_root.scale = Vector2(0.4, 0.4)
	var drop_tw = chest_root.create_tween()
	drop_tw.tween_property(chest_root, "position", Vector2(550.0, 488.0), 0.24 * spd).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop_tw.parallel().tween_property(chest_root, "scale", Vector2(1.12, 0.88), 0.16 * spd)
	drop_tw.tween_property(chest_root, "scale", Vector2.ONE, 0.10 * spd)
	
	# Shake Chest with anticipation
	drop_tw.tween_property(chest_root, "rotation_degrees", -7.0, 0.05 * spd)
	drop_tw.tween_property(chest_root, "rotation_degrees", 7.0, 0.05 * spd)
	drop_tw.tween_property(chest_root, "rotation_degrees", -9.0, 0.05 * spd)
	drop_tw.tween_property(chest_root, "rotation_degrees", 9.0, 0.05 * spd)
	drop_tw.tween_property(chest_root, "rotation_degrees", 0.0, 0.04 * spd)
	await drop_tw.finished
	if my_run_id != cinematic_run_id:
		return
		
	# 3. Open the Treasure Chest Lid & Burst Light Beam
	chest_beam.visible = true
	chest_beam.scale = Vector2(0.3, 0.1)
	chest_beam.pivot_offset = Vector2(75.0, 120.0)
	var lid_tw = create_tween().set_parallel(true)
	lid_tw.tween_property(chest_lid_tex, "position:y", -48.0, 0.22 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lid_tw.tween_property(chest_lid_tex, "scale:y", 0.62, 0.22 * spd)
	lid_tw.tween_property(chest_lid_tex, "rotation_degrees", -14.0, 0.22 * spd)
	lid_tw.tween_property(chest_beam, "scale", Vector2(1.25, 1.15), 0.22 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await lid_tw.finished
	if AudioManager:
		AudioManager.play_sfx("summon_pull")
	if my_run_id != cinematic_run_id:
		return
		
	# 4. Spawn Swimming Fish from inside the Open Chest
	stage_title_lbl.text = "🐟 MYSTERY FISH SWIMMING OUT OF THE CHEST! 🌊"
	var count = units.size()
	var fish_nodes: Array = []
	var target_positions: Array = []
	
	for i in range(count):
		var t_pos := Vector2(640.0, 265.0)
		if count > 1:
			var r: int = i / 5
			var c: int = i % 5
			t_pos = Vector2(248.0 + c * 196.0, 188.0 + r * 150.0)
		target_positions.append(t_pos)
		
		var u = units[i]
		var t_data = GameData.TOWERS.get(u["tower_id"], {})
		var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
		var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color.CYAN)
		
		var fish_holder = Control.new()
		fish_holder.name = "MysteryFish_%d" % i
		fish_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_layer.add_child(fish_holder)
		var f_sz := 112.0 if count == 1 else 86.0
		var start_pos := Vector2(640.0 - f_sz * 0.5, 505.0 - f_sz * 0.5)
		UIThemeBuilder.place_rect(fish_holder, start_pos.x, start_pos.y, f_sz, f_sz)
		
		var aura = Panel.new()
		aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var aura_sb = UIThemeBuilder.make_panel_style(Color(r_col.r, r_col.g, r_col.b, 0.26), r_col.lightened(0.25), int(f_sz * 0.5), 2, 0, 0, 0)
		aura.add_theme_stylebox_override("panel", aura_sb)
		fish_holder.add_child(aura)
		UIThemeBuilder.place_rect(aura, 4.0, 4.0, f_sz - 8.0, f_sz - 8.0)
		
		var f_tex = TextureRect.new()
		f_tex.texture = tex_mystery_fish
		f_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fish_holder.add_child(f_tex)
		UIThemeBuilder.place_rect(f_tex, 0.0, 0.0, f_sz, f_sz)
		
		fish_holder.scale = Vector2(0.15, 0.15)
		fish_nodes.append(fish_holder)
		
		var dest_tl := t_pos - Vector2(f_sz * 0.5, f_sz * 0.5)
		var mid_tl := Vector2(lerpf(start_pos.x, dest_tl.x, 0.5) + (randf() - 0.5) * 90.0, minf(start_pos.y, dest_tl.y) - 55.0)
		var swim_tw = fish_holder.create_tween()
		swim_tw.tween_interval(i * 0.035 * spd)
		swim_tw.tween_property(fish_holder, "scale", Vector2.ONE, 0.14 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		swim_tw.parallel().tween_property(fish_holder, "position", mid_tl, 0.18 * spd).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		swim_tw.parallel().tween_property(fish_holder, "rotation_degrees", -16.0, 0.09 * spd)
		swim_tw.tween_property(fish_holder, "position", dest_tl, 0.18 * spd).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		swim_tw.parallel().tween_property(fish_holder, "rotation_degrees", 14.0, 0.09 * spd)
		swim_tw.tween_property(fish_holder, "rotation_degrees", 0.0, 0.06 * spd)
		
	await get_tree().create_timer((0.44 + count * 0.035) * spd).timeout
	if my_run_id != cinematic_run_id:
		return
		
	# 5. Each Fish Swells, Explodes & Reveals the Character!
	stage_title_lbl.text = "💥 FISH EXPLODING — CHARACTERS REVEALED! 🌟"
	var card_sz := Vector2(142, 138) if count == 1 else Vector2(124, 118)
	
	for i in range(count):
		var fish_node: Control = fish_nodes[i]
		var center_pos: Vector2 = target_positions[i]
		var u = units[i]
		var tid: String = u["tower_id"]
		
		# Swell & Flash before explosion
		var swell_tw = fish_node.create_tween()
		swell_tw.tween_property(fish_node, "scale", Vector2(1.42, 1.42), 0.10 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		swell_tw.parallel().tween_property(fish_node, "modulate", Color(2.2, 2.0, 1.2, 1.0), 0.10 * spd)
		await swell_tw.finished
		if my_run_id != cinematic_run_id:
			return
			
		fish_node.visible = false
		
		# Spawn Explosion Starburst FX
		var exp_fx = TextureRect.new()
		exp_fx.name = "FishExplosion_%d" % i
		exp_fx.texture = tex_explosion_star
		exp_fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		exp_fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		exp_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_layer.add_child(exp_fx)
		var exp_sz := 148.0 if count == 1 else 118.0
		UIThemeBuilder.place_rect(exp_fx, center_pos.x - exp_sz * 0.5, center_pos.y - exp_sz * 0.5, exp_sz, exp_sz)
		exp_fx.scale = Vector2(0.25, 0.25)
		var exp_tw = exp_fx.create_tween().set_parallel(true)
		exp_tw.tween_property(exp_fx, "scale", Vector2(1.55, 1.55), 0.24 * spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		exp_tw.tween_property(exp_fx, "rotation_degrees", 35.0, 0.24 * spd)
		exp_tw.tween_property(exp_fx, "modulate:a", 0.0, 0.24 * spd)
		
		# Pop out the Character Card from the center of the fish explosion!
		var rev_card = UIThemeBuilder.create_shop_roster_card(
			tid,
			true,
			PlayerData.get_owned_count(tid),
			1,
			false,
			card_sz
		)
		rev_card.name = "RevealedUnit_%d" % i
		stage_layer.add_child(rev_card)
		UIThemeBuilder.place_rect(rev_card, center_pos.x - card_sz.x * 0.5, center_pos.y - card_sz.y * 0.5, card_sz.x, card_sz.y)
		rev_card.scale = Vector2(0.1, 0.1)
		var pop_tw = rev_card.create_tween()
		pop_tw.tween_property(rev_card, "scale", Vector2(1.16, 1.16), 0.14 * spd).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tw.tween_property(rev_card, "scale", Vector2.ONE, 0.08 * spd)
		
	await get_tree().create_timer(0.55 * spd).timeout
	if my_run_id != cinematic_run_id:
		return
		
	# 6. Open the Pulled Characters & Specifications Modal with 10-Second Auto-Close Timer
	_open_summary_specs_modal()

func _open_summary_specs_modal() -> void:
	is_playing_cinematic = false
	is_summary_open = true
	summary_time_left = SUMMARY_AUTO_CLOSE_SECONDS
	
	if stage_layer:
		stage_layer.visible = false
	if cinematic_overlay:
		cinematic_overlay.visible = true
		
	_populate_summary_specs_cards(last_pulled_units)
	
	if summary_modal:
		UIThemeBuilder.animate_modal_open(summary_modal)

func _populate_summary_specs_cards(units: Array) -> void:
	if not summary_specs_grid:
		return
	for c in summary_specs_grid.get_children():
		c.queue_free()
		
	var is_single := (units.size() == 1)
	summary_specs_grid.columns = 1 if is_single else 2
	var card_w := 680.0 if is_single else 352.0
	var card_h := 136.0 if is_single else 98.0
	
	for i in range(units.size()):
		var u: Dictionary = units[i]
		var tid: String = u.get("tower_id", "spongebob")
		var tr_id: String = u.get("trait_id", "none")
		var lvl: int = int(u.get("level", 1))
		var t_data: Dictionary = GameData.TOWERS.get(tid, {})
		var tr_data: Dictionary = GameData.TRAITS.get(tr_id, GameData.TRAITS["none"])
		var r_enum: int = t_data.get("rarity", GameData.Rarity.COMMON)
		var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color.CYAN)
		var r_name: String = GameData.RARITY_NAMES.get(r_enum, "Common")
		var p_cls: Dictionary = GameData.POWER_CLASSES.get(t_data.get("power_class", "brawler"), {})
		var p_short: String = p_cls.get("short", "⚡ Power")
		var p_rating: int = int(t_data.get("power_rating", 150))
		
		var is_auto_sold: bool = bool(u.get("auto_sold", false))
		var spec_panel = PanelContainer.new()
		spec_panel.name = "SpecCard_%d" % i
		spec_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
		spec_panel.custom_minimum_size = Vector2(card_w, card_h)
		var sp_sb = UIThemeBuilder.make_panel_style(
			Color(0.24, 0.16, 0.05, 0.98) if is_auto_sold else Color(0.06, 0.16, 0.28, 0.98),
			Color(1.0, 0.85, 0.25) if is_auto_sold else r_col,
			14, 2, 0, 8, 6
		)
		spec_panel.add_theme_stylebox_override("panel", sp_sb)
		
		var hbox = HBoxContainer.new()
		hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
		hbox.add_theme_constant_override("separation", 10)
		spec_panel.add_child(hbox)
		
		# Portrait Box
		var icon_sz := 76.0 if is_single else 60.0
		var icon_frame = PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(icon_sz + 10, icon_sz + 10)
		icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var f_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.15, 0.95), r_col.lightened(0.2), 10, 2, 0, 4, 4)
		icon_frame.add_theme_stylebox_override("panel", f_sb)
		
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(icon_sz, icon_sz)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var asset_p = "res://assets/%s.svg" % tid
		if ResourceLoader.exists(asset_p):
			icon.texture = load(asset_p)
		icon_frame.add_child(icon)
		hbox.add_child(icon_frame)
		
		# Specifications Column
		var info_vbox = VBoxContainer.new()
		info_vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(info_vbox)
		
		var name_lbl = Label.new()
		if is_auto_sold:
			name_lbl.text = "💰 AUTO-SOLD: %s  (+%d🪙 +%d💎)" % [t_data.get("name", tid), int(u.get("sell_gold", 150)), int(u.get("sell_gems", 15))]
			UIThemeBuilder.style_label(name_lbl, 13 if is_single else 11, Color(1.0, 0.88, 0.25), 4)
		else:
			name_lbl.text = "⭐ %s   [%s • Lv.%d]" % [t_data.get("name", tid), r_name.to_upper(), lvl]
			UIThemeBuilder.style_label(name_lbl, 13 if is_single else 11, r_col.lightened(0.22), 3)
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_vbox.add_child(name_lbl)
		
		var class_lbl = Label.new()
		class_lbl.text = "🏷️ Class: %s   •   Power: ⚡%d   •   Trait: [%s]" % [
			p_short, p_rating, tr_data.get("name", "None")
		]
		class_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UIThemeBuilder.style_label(class_lbl, 11 if is_single else 10, Color(1.0, 0.88, 0.30), 3)
		info_vbox.add_child(class_lbl)
		
		var stats_lbl = Label.new()
		stats_lbl.text = "⚔️ DMG: %d   |   ⚡ SPA: %.2fs   |   🎯 RNG: %.1fm   |   💰 Cost: $%d" % [
			int(t_data.get("base_damage", 15)),
			float(t_data.get("base_spa", 1.0)),
			float(t_data.get("base_range", 7.0)),
			int(t_data.get("cost", 150))
		]
		stats_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UIThemeBuilder.style_label(stats_lbl, 11 if is_single else 9, Color(0.55, 0.95, 1.0), 3)
		info_vbox.add_child(stats_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = "✨ %s" % t_data.get("description", "")
		desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UIThemeBuilder.style_label(desc_lbl, 10 if is_single else 9, Color(0.82, 0.90, 0.98), 2)
		info_vbox.add_child(desc_lbl)
		
		summary_specs_grid.add_child(spec_panel)

func close_pack_summary(immediate: bool = false) -> void:
	cinematic_run_id += 1
	is_playing_cinematic = false
	is_summary_open = false
	summary_time_left = 0.0
	_clear_dynamic_stage_nodes()
	if immediate or not summary_modal or not summary_modal.visible:
		if summary_modal:
			summary_modal.visible = false
		if cinematic_overlay:
			cinematic_overlay.visible = false
		return
	summary_modal.pivot_offset = summary_modal.size * 0.5
	var tw = summary_modal.create_tween().set_parallel(true)
	tw.tween_property(summary_modal, "scale", Vector2(0.85, 0.85), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(summary_modal, "modulate:a", 0.0, 0.16)
	await tw.finished
	if summary_modal:
		summary_modal.visible = false
		summary_modal.scale = Vector2.ONE
		summary_modal.modulate.a = 1.0
	if cinematic_overlay:
		cinematic_overlay.visible = false

func _do_summon() -> Dictionary:
	PlayerData.pity_counter += 1
	var target_rarity: int = GameData.Rarity.COMMON
	
	if PlayerData.pity_counter >= PlayerData.PITY_THRESHOLD:
		target_rarity = GameData.Rarity.SECRET if randf() < 0.25 else GameData.Rarity.MYTHIC
		PlayerData.pity_counter = 0
	else:
		var roll = randf()
		if roll <= 0.005:
			target_rarity = GameData.Rarity.SECRET
			PlayerData.pity_counter = 0
		elif roll <= 0.025:
			target_rarity = GameData.Rarity.MYTHIC
			PlayerData.pity_counter = 0
		elif roll <= 0.090:
			target_rarity = GameData.Rarity.LEGENDARY
		elif roll <= 0.220:
			target_rarity = GameData.Rarity.EPIC
		elif roll <= 0.480:
			target_rarity = GameData.Rarity.RARE
		else:
			target_rarity = GameData.Rarity.COMMON
			
	var pool: Array = GameData.get_towers_by_rarity(target_rarity)
	if pool.is_empty():
		pool = ["spongebob"]
	var chosen_tower: String = pool[randi() % pool.size()]
	
	var rand_t = randf()
	var chosen_trait := "none"
	if rand_t < 0.005:
		chosen_trait = "neptunes_crown"
	elif rand_t < 0.020:
		chosen_trait = "secret_formula"
	elif rand_t < 0.060:
		chosen_trait = "surge_3"
	elif rand_t < 0.140:
		chosen_trait = "strike_3"
	elif rand_t < 0.220:
		chosen_trait = "wealth"
		
	# Check Auto-Sell
	var is_auto_sold: bool = PlayerData.is_tower_auto_sold(chosen_tower)
	if is_auto_sold:
		var sell_val = PlayerData.get_tower_sell_value(chosen_tower, 1)
		PlayerData.add_gold(sell_val["gold"])
		PlayerData.add_gems(sell_val["gems"])
		if chosen_tower not in PlayerData.unlocked_towers:
			PlayerData.unlocked_towers.append(chosen_tower)
		PlayerData.save_game()
		return {
			"uid": -1,
			"tower_id": chosen_tower,
			"level": 1,
			"trait_id": chosen_trait,
			"xp": 0,
			"auto_sold": true,
			"sell_gold": sell_val["gold"],
			"sell_gems": sell_val["gems"]
		}
	else:
		var unit = PlayerData.add_tower(chosen_tower, chosen_trait)
		return unit

func _show_pull_summary(units: Array) -> void:
	var unlocked_cnt = PlayerData.get_unlocked_count()
	var total_cnt = GameData.TOWER_ORDER.size()
	var inv_cnt = PlayerData.get_inventory_count()
	var inv_max = PlayerData.MAX_INVENTORY_CAPACITY
	pity_label.text = "🔥 Pity: %d / %d   •   🎒 Capacity: %d / %d   •   📖 Index: %d / %d   •   💎 Gems: %d" % [
		PlayerData.pity_counter, PlayerData.PITY_THRESHOLD, inv_cnt, inv_max, unlocked_cnt, total_cnt, PlayerData.gems
	]
	if pity_bar:
		pity_bar.value = PlayerData.pity_counter
		
	var names: Array = []
	var auto_sold_gold := 0
	var auto_sold_gems := 0
	for u in units:
		if u.get("auto_sold", false):
			auto_sold_gold += int(u.get("sell_gold", 0))
			auto_sold_gems += int(u.get("sell_gems", 0))
			
	for tid in last_pulled_counts.keys():
		var t_name = GameData.TOWERS.get(tid, {}).get("name", tid)
		var cnt = int(last_pulled_counts[tid])
		names.append("%s x%d" % [t_name, cnt] if cnt > 1 else t_name)
	if info_banner:
		if auto_sold_gold > 0:
			info_banner.text = "🎉 PULLED: %s  •  💰 Auto-Sold (+%d Gold 🪙, +%d Gems 💎)" % [", ".join(names), auto_sold_gold, auto_sold_gems]
		else:
			info_banner.text = "🎉 PULLED & REVEALED: %s!" % ", ".join(names)
		UIThemeBuilder.style_label(info_banner, 11, Color(1.0, 0.90, 0.25), 3)

func _show_message(msg: String) -> void:
	if info_banner:
		info_banner.text = msg
		UIThemeBuilder.style_label(info_banner, 11, Color(1.0, 0.45, 0.45), 3)

# =========================================================================
# AUTO-SELL CONFIGURATION MODAL
# =========================================================================
func _open_auto_sell_modal() -> void:
	if not auto_sell_modal:
		_build_auto_sell_modal()
	_refresh_auto_sell_ui()
	auto_sell_modal.visible = true
	auto_sell_modal.move_to_front()
	UIThemeBuilder.animate_modal_open(auto_sell_modal)

func _build_auto_sell_modal() -> void:
	var hud = get_parent()
	if not hud:
		return
	auto_sell_modal = Panel.new()
	auto_sell_modal.name = "AutoSellModal"
	auto_sell_modal.visible = false
	auto_sell_modal.z_index = 50
	hud.add_child(auto_sell_modal)
	
	UIThemeBuilder.style_modal(auto_sell_modal, Color(1.0, 0.75, 0.20), Vector2(680, 500))
	UIThemeBuilder.ensure_top_close_button(auto_sell_modal, 680.0)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vbox.add_theme_constant_override("separation", 8)
	auto_sell_modal.add_child(vbox)
	UIThemeBuilder.fit_inner_container(auto_sell_modal, vbox, 20.0, 16.0)
	
	var title = Label.new()
	title.text = "⚙️ AUTO-SELL CONFIGURATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(title, 18, Color(1.0, 0.85, 0.25), 4)
	vbox.add_child(title)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "Units matching these rules will be automatically converted to Gold & Gems on pull."
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(sub_lbl, 11, Color(0.80, 0.90, 0.98), 2)
	vbox.add_child(sub_lbl)
	
	# Tier Toggles Row
	var tier_box = HBoxContainer.new()
	tier_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_box.add_theme_constant_override("separation", 10)
	vbox.add_child(tier_box)
	
	for r_enum in [GameData.Rarity.COMMON, GameData.Rarity.RARE, GameData.Rarity.EPIC]:
		var r_name = GameData.RARITY_NAMES[r_enum]
		var r_btn = Button.new()
		r_btn.custom_minimum_size = Vector2(190, 34)
		tier_box.add_child(r_btn)
		auto_sell_rarity_buttons[r_enum] = r_btn
		var captured_r = r_enum
		r_btn.pressed.connect(func():
			var cur = bool(PlayerData.auto_sell_config.get("rarities", {}).get(captured_r, false))
			PlayerData.set_auto_sell_rarity(captured_r, not cur)
			_refresh_auto_sell_ui()
		)
		
	# Individual Character Toggles Scroll
	var roster_label = Label.new()
	roster_label.text = "📋 Character-Specific Auto-Sell Toggles (24 Units):"
	UIThemeBuilder.style_label(roster_label, 12, Color(0.4, 0.85, 1.0), 3)
	vbox.add_child(roster_label)
	
	var scroll = ScrollContainer.new()
	var s_sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.08, 0.15, 0.95), Color(0.18, 0.45, 0.70, 0.6), 12, 1, 0, 8, 6)
	scroll.add_theme_stylebox_override("panel", s_sb)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	auto_sell_tower_grid = GridContainer.new()
	auto_sell_tower_grid.columns = 4
	auto_sell_tower_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_sell_tower_grid.add_theme_constant_override("h_separation", 8)
	auto_sell_tower_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(auto_sell_tower_grid)
	
	# Bottom Action Buttons
	var bottom_row = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 14)
	vbox.add_child(bottom_row)
	
	var preset_all_btn = Button.new()
	preset_all_btn.text = "✓ Commons & Rares"
	preset_all_btn.custom_minimum_size = Vector2(170, 32)
	UIThemeBuilder.style_button(preset_all_btn, "nav", 11)
	preset_all_btn.pressed.connect(func():
		PlayerData.set_auto_sell_rarity(GameData.Rarity.COMMON, true)
		PlayerData.set_auto_sell_rarity(GameData.Rarity.RARE, true)
		PlayerData.set_auto_sell_rarity(GameData.Rarity.EPIC, false)
		_refresh_auto_sell_ui()
	)
	bottom_row.add_child(preset_all_btn)
	
	var clear_btn = Button.new()
	clear_btn.text = "✖ Disable All"
	clear_btn.custom_minimum_size = Vector2(130, 32)
	UIThemeBuilder.style_button(clear_btn, "danger", 11)
	clear_btn.pressed.connect(func():
		PlayerData.set_auto_sell_rarity(GameData.Rarity.COMMON, false)
		PlayerData.set_auto_sell_rarity(GameData.Rarity.RARE, false)
		PlayerData.set_auto_sell_rarity(GameData.Rarity.EPIC, false)
		PlayerData.auto_sell_config["towers"] = {}
		PlayerData.save_game()
		_refresh_auto_sell_ui()
	)
	bottom_row.add_child(clear_btn)
	
	var done_btn = Button.new()
	done_btn.text = "💾 Save & Close"
	done_btn.custom_minimum_size = Vector2(150, 32)
	UIThemeBuilder.style_button(done_btn, "primary", 12)
	done_btn.pressed.connect(func():
		auto_sell_modal.visible = false
	)
	bottom_row.add_child(done_btn)

func _refresh_auto_sell_ui() -> void:
	if not auto_sell_modal:
		return
		
	# Refresh Rarity Tier Buttons
	for r_enum in auto_sell_rarity_buttons.keys():
		var btn: Button = auto_sell_rarity_buttons[r_enum]
		var is_on = bool(PlayerData.auto_sell_config.get("rarities", {}).get(r_enum, false))
		var r_name = GameData.RARITY_NAMES[r_enum]
		if is_on:
			btn.text = "✓ %s (Auto-Sold)" % r_name
			UIThemeBuilder.style_button(btn, "feed", 11)
		else:
			btn.text = "○ %s (Keep)" % r_name
			UIThemeBuilder.style_button(btn, "nav", 11)
			
	# Refresh Character Grid
	if auto_sell_tower_grid:
		for c in auto_sell_tower_grid.get_children():
			c.queue_free()
		for tid in GameData.TOWER_ORDER:
			var t_data = GameData.TOWERS.get(tid, {})
			var t_name = t_data.get("name", tid)
			var is_sold = PlayerData.is_tower_auto_sold(tid)
			var c_btn = Button.new()
			c_btn.custom_minimum_size = Vector2(148, 28)
			c_btn.clip_contents = true
			if is_sold:
				c_btn.text = "✓ %s" % t_name
				UIThemeBuilder.style_button(c_btn, "feed", 10)
			else:
				c_btn.text = "%s" % t_name
				UIThemeBuilder.style_button(c_btn, "nav", 10)
			var captured_tid = tid
			c_btn.pressed.connect(func():
				var cur = bool(PlayerData.auto_sell_config.get("towers", {}).get(captured_tid, false))
				PlayerData.set_auto_sell_tower(captured_tid, not cur)
				_refresh_auto_sell_ui()
			)
			auto_sell_tower_grid.add_child(c_btn)
