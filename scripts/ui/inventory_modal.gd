extends Panel

## InventoryModal - Interactive Unit Loadout, Visual Equipments Tray Beside Picture, Feed Selection & Unit Selling

@onready var title_label: Label = $VBox/Title
@onready var scroll_container: ScrollContainer = $VBox/Scroll
@onready var grid_container: GridContainer = $VBox/Scroll/Grid
@onready var detail_panel: Panel = $VBox/DetailPanel

# Visual Character Portrait Frame (Portrait)
@onready var detail_hbox: HBoxContainer = $VBox/DetailPanel/DetailHBox
@onready var portrait_box: VBoxContainer = $VBox/DetailPanel/DetailHBox/PortraitBox
@onready var portrait_frame: PanelContainer = $VBox/DetailPanel/DetailHBox/PortraitBox/PortraitFrame
@onready var portrait_texture: TextureRect = $VBox/DetailPanel/DetailHBox/PortraitBox/PortraitFrame/PortraitTexture
@onready var portrait_lvl: Label = $VBox/DetailPanel/DetailHBox/PortraitBox/PortraitLvl

# Equipments Tray Directly Beside the Picture (Equipped Units Hotbar)
@onready var equipments_box: VBoxContainer = $VBox/DetailPanel/DetailHBox/EquipmentsBox
@onready var equipments_title: Label = $VBox/DetailPanel/DetailHBox/EquipmentsBox/EquipmentsTitle
@onready var equipments_slots: HBoxContainer = $VBox/DetailPanel/DetailHBox/EquipmentsBox/EquipmentsSlots

# Unit Details & Action Buttons
@onready var info_vbox: VBoxContainer = $VBox/DetailPanel/DetailHBox/InfoVBox
@onready var unit_name_label: Label = $VBox/DetailPanel/DetailHBox/InfoVBox/UnitName
@onready var unit_stats_label: Label = $VBox/DetailPanel/DetailHBox/InfoVBox/Stats
@onready var unit_trait_label: Label = $VBox/DetailPanel/DetailHBox/InfoVBox/Trait
@onready var action_hbox: HBoxContainer = $VBox/DetailPanel/DetailHBox/InfoVBox/HBox
@onready var equip_btn: Button = $VBox/DetailPanel/DetailHBox/InfoVBox/HBox/EquipBtn
@onready var feed_btn: Button = $VBox/DetailPanel/DetailHBox/InfoVBox/HBox/FeedBtn
@onready var close_btn: Button = $VBox/CloseBtn

var sell_btn: Button = null
var lock_btn: Button = null
var selected_unit_uid: int = -1
var is_feed_mode: bool = false
var feed_selected_uids: Array = []
var status_banner_text: String = ""

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(0.25, 0.82, 1.0), Vector2(960, 560))
	$VBox.add_theme_constant_override("separation", 8)
	UIThemeBuilder.style_label(title_label, 20, Color(0.35, 0.92, 1.0), 4)
	
	# Scroll area & grid configuration
	var scroll_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.09, 0.16, 0.92), Color(0.18, 0.52, 0.82, 0.70), 16, 2, 0, 10, 8)
	scroll_container.add_theme_stylebox_override("panel", scroll_sb)
	scroll_container.custom_minimum_size = Vector2(0, 268)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	grid_container.columns = 5
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.add_theme_constant_override("h_separation", 14)
	grid_container.add_theme_constant_override("v_separation", 10)
	
	# DetailPanel & Inner HBox configuration (Strict bounds, no overflow, no negative shift)
	detail_panel.clip_contents = false
	detail_panel.custom_minimum_size = Vector2(0, 146)
	var detail_sb = UIThemeBuilder.make_panel_style(Color(0.06, 0.17, 0.29, 0.98), Color(1.0, 0.82, 0.22, 0.95), 16, 2, 0, 10, 8)
	detail_panel.add_theme_stylebox_override("panel", detail_sb)
	
	detail_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_hbox.offset_left = 10.0
	detail_hbox.offset_top = 8.0
	detail_hbox.offset_right = -10.0
	detail_hbox.offset_bottom = -8.0
	detail_hbox.grow_horizontal = Control.GROW_DIRECTION_END
	detail_hbox.grow_vertical = Control.GROW_DIRECTION_END
	detail_hbox.add_theme_constant_override("separation", 10)
	
	# 1. Selected Character Portrait Frame (Portrait)
	portrait_box.custom_minimum_size = Vector2(80, 126)
	portrait_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	portrait_frame.custom_minimum_size = Vector2(76, 76)
	portrait_frame.clip_contents = true
	var port_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.10, 0.18, 0.96), Color(0.28, 0.78, 1.0), 12, 2, 0, 4, 4)
	portrait_frame.add_theme_stylebox_override("panel", port_sb)
	
	portrait_texture.custom_minimum_size = Vector2(66, 66)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIThemeBuilder.style_label(portrait_lvl, 11, Color(1.0, 0.88, 0.25), 3)
	
	# 2. Equipments Tray Beside Picture (Equipped Units Hotbar)
	equipments_box.custom_minimum_size = Vector2(230, 126)
	equipments_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	equipments_box.add_theme_constant_override("separation", 4)
	UIThemeBuilder.style_label(equipments_title, 11, Color(0.35, 0.92, 1.0), 3)
	equipments_slots.add_theme_constant_override("separation", 4)
	
	# 3. Unit Info Labels & Action Buttons
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	unit_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	unit_stats_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	unit_trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	unit_name_label.clip_text = true
	unit_stats_label.clip_text = true
	unit_trait_label.clip_text = true
	UIThemeBuilder.style_label(unit_name_label, 12, Color(1.0, 0.88, 0.25), 3)
	UIThemeBuilder.style_label(unit_stats_label, 11, Color(0.92, 0.97, 1.0), 3)
	UIThemeBuilder.style_label(unit_trait_label, 10, Color(0.38, 0.92, 1.0), 3)
	
	action_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	action_hbox.add_theme_constant_override("separation", 6)
	
	# Create Lock & Sell Buttons dynamically inside action_hbox
	if lock_btn == null:
		lock_btn = Button.new()
		lock_btn.name = "LockBtn"
		action_hbox.add_child(lock_btn)
		
	if sell_btn == null:
		sell_btn = Button.new()
		sell_btn.name = "SellBtn"
		action_hbox.add_child(sell_btn)
	
	equip_btn.custom_minimum_size = Vector2(95, 28)
	feed_btn.custom_minimum_size = Vector2(105, 28)
	lock_btn.custom_minimum_size = Vector2(85, 28)
	sell_btn.custom_minimum_size = Vector2(138, 28)
	close_btn.custom_minimum_size = Vector2(140, 34)
	
	UIThemeBuilder.style_button(equip_btn, "success", 11)
	UIThemeBuilder.style_button(feed_btn, "primary", 11)
	UIThemeBuilder.style_button(lock_btn, "nav", 11)
	UIThemeBuilder.style_button(sell_btn, "danger", 11)
	UIThemeBuilder.style_button(close_btn, "danger", 13)
	close_btn.text = "✖ Close"
	
	close_btn.pressed.connect(func():
		is_feed_mode = false
		feed_selected_uids.clear()
		visible = false
	)
	equip_btn.pressed.connect(_on_equip_or_auto_pressed)
	feed_btn.pressed.connect(_on_feed_pressed)
	lock_btn.pressed.connect(_on_lock_pressed)
	sell_btn.pressed.connect(_on_sell_or_cancel_pressed)
	
	# Listen to loadout changes to keep the equipments tray in sync
	PlayerData.loadout_changed.connect(refresh_view)

func refresh_view() -> void:
	for c in grid_container.get_children():
		c.queue_free()
		
	PlayerData.cleanup_equipped_uids()
	var eq_count = PlayerData.equipped_uids.size()
	var inv_count = PlayerData.get_inventory_count()
	var inv_max = PlayerData.MAX_INVENTORY_CAPACITY
	if is_feed_mode:
		title_label.text = "🔥 SELECT SPARE UNITS TO FEED  (%d Selected)" % feed_selected_uids.size()
		UIThemeBuilder.style_label(title_label, 20, Color(1.0, 0.62, 0.20), 4)
	else:
		title_label.text = "🎒 INVENTORY: %d/%d UNITS  •  (%d / 5 Equipped)" % [inv_count, inv_max, eq_count]
		var col = Color(1.0, 0.35, 0.35) if inv_count >= inv_max else Color(0.35, 0.92, 1.0)
		UIThemeBuilder.style_label(title_label, 20, col, 4)
	
	if selected_unit_uid == -1 or PlayerData.get_tower_by_uid(selected_unit_uid).is_empty():
		if not PlayerData.inventory.is_empty():
			selected_unit_uid = PlayerData.inventory[0]["uid"]
		else:
			selected_unit_uid = -1
			
	for unit in PlayerData.inventory:
		var uid: int = int(unit["uid"])
		var t_id: String = unit["tower_id"]
		var is_eq = PlayerData.is_equipped(uid)
		
		var sel_mode := ""
		var badge_txt := ""
		if is_feed_mode:
			if uid == selected_unit_uid:
				sel_mode = "feed_target"
			elif uid in feed_selected_uids:
				sel_mode = "feed_material"
				if is_eq:
					badge_txt = "🔥 SACRIFICE (UNEQUIPS)"
			elif is_eq:
				badge_txt = "⚠️ EQUIPPED (CLICK TO SACRIFICE)"
			else:
				badge_txt = "➕ CLICK TO FEED"
		else:
			if uid == selected_unit_uid:
				sel_mode = "selected"
				
		var is_locked: bool = PlayerData.is_unit_locked(uid)
		# Card width 160 perfectly distributes across the 5 columns without empty void!
		var card = UIThemeBuilder.create_unit_card(
			t_id,
			unit.get("level", 1),
			unit.get("trait_id", "none"),
			is_eq,
			-1,
			Vector2(160, 126),
			sel_mode,
			badge_txt,
			is_locked
		)
		card.pressed.connect(func(): _on_card_clicked(uid, card))
		grid_container.add_child(card)
		
	_refresh_equipments_bar()
	_update_detail_panel()

## Populates the 5 loadout equipment slots directly next to the unit's portrait (Equipped Units Hotbar)
func _refresh_equipments_bar() -> void:
	for c in equipments_slots.get_children():
		c.queue_free()
		
	var eq_uids = PlayerData.equipped_uids
	for slot_idx in range(5):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(42, 64)
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot_btn.clip_contents = true
		
		var slot_vbox = VBoxContainer.new()
		slot_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_vbox.add_theme_constant_override("separation", 2)
		slot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(slot_vbox)
		
		if slot_idx < eq_uids.size():
			var eq_uid: int = int(eq_uids[slot_idx])
			var eq_unit = PlayerData.get_tower_by_uid(eq_uid)
			var t_id: String = eq_unit.get("tower_id", "")
			var t_data = GameData.TOWERS.get(t_id, {})
			var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
			var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color.WHITE)
			var is_selected: bool = (eq_uid == selected_unit_uid)
			
			var bg_color = Color(0.12, 0.28, 0.44, 0.95) if is_selected else Color(0.04, 0.12, 0.20, 0.92)
			var border_color = Color(1.0, 0.88, 0.22) if is_selected else r_col
			var border_w = 2 if is_selected else 1
			var sb = UIThemeBuilder.make_panel_style(bg_color, border_color, 8, border_w, 0, 2, 2)
			slot_btn.add_theme_stylebox_override("normal", sb)
			var h_sb = UIThemeBuilder.make_panel_style(bg_color.lightened(0.15), border_color.lightened(0.2), 8, border_w, 0, 2, 2)
			slot_btn.add_theme_stylebox_override("hover", h_sb)
			slot_btn.add_theme_stylebox_override("pressed", sb)
			slot_btn.add_theme_stylebox_override("focus", h_sb)
			
			var mini_icon = TextureRect.new()
			mini_icon.custom_minimum_size = Vector2(28, 28)
			mini_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mini_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mini_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var asset_p = "res://assets/%s.svg" % t_id
			if ResourceLoader.exists(asset_p):
				mini_icon.texture = load(asset_p)
			slot_vbox.add_child(mini_icon)
			
			var lvl_lbl = Label.new()
			lvl_lbl.text = "Lv.%d" % int(eq_unit.get("level", 1))
			lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIThemeBuilder.style_label(lvl_lbl, 9, Color(1.0, 0.9, 0.3) if is_selected else Color.WHITE, 2)
			slot_vbox.add_child(lvl_lbl)
			
			slot_btn.tooltip_text = "%s (Lv.%d) - Click to view/unequip" % [t_data.get("name", "Unit"), int(eq_unit.get("level", 1))]
			slot_btn.pressed.connect(func():
				selected_unit_uid = eq_uid
				status_banner_text = ""
				refresh_view()
			)
		else:
			# Empty loadout slot
			var sb = UIThemeBuilder.make_panel_style(Color(0.02, 0.06, 0.12, 0.65), Color(0.22, 0.40, 0.58, 0.45), 8, 1, 0, 2, 2)
			slot_btn.add_theme_stylebox_override("normal", sb)
			var h_sb = UIThemeBuilder.make_panel_style(Color(0.04, 0.10, 0.18, 0.85), Color(0.35, 0.65, 0.90, 0.8), 8, 1, 0, 2, 2)
			slot_btn.add_theme_stylebox_override("hover", h_sb)
			slot_btn.add_theme_stylebox_override("pressed", sb)
			slot_btn.add_theme_stylebox_override("focus", h_sb)
			
			var plus_lbl = Label.new()
			plus_lbl.text = "➕"
			plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIThemeBuilder.style_label(plus_lbl, 12, Color(0.4, 0.7, 0.9, 0.7), 2)
			slot_vbox.add_child(plus_lbl)
			
			var emp_lbl = Label.new()
			emp_lbl.text = "Empty"
			emp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIThemeBuilder.style_label(emp_lbl, 8, Color(0.5, 0.65, 0.8, 0.6), 1)
			slot_vbox.add_child(emp_lbl)
			
			slot_btn.tooltip_text = "Empty Equipment Slot - Click with an unequipped bot selected to equip"
			slot_btn.pressed.connect(func():
				if selected_unit_uid != -1 and not PlayerData.is_equipped(selected_unit_uid):
					_on_equip_or_auto_pressed()
			)
			
		equipments_slots.add_child(slot_btn)

func _on_card_clicked(uid: int, card_btn: Button) -> void:
	UIThemeBuilder.play_pulse_anim(card_btn, 1.09)
	status_banner_text = ""
	if is_feed_mode:
		if uid == selected_unit_uid:
			status_banner_text = "👑 This is the Target Unit being upgraded! Select other spare units to feed into it."
			_update_detail_panel()
			return
		if PlayerData.is_unit_locked(uid):
			status_banner_text = "🔒 Unit is LOCKED! Unlock it first if you wish to use it as feed material."
			_update_detail_panel()
			return
		if uid in feed_selected_uids:
			feed_selected_uids.erase(uid)
		else:
			feed_selected_uids.append(uid)
			if PlayerData.is_equipped(uid):
				status_banner_text = "⚠️ Notice: Selected unit is currently equipped. Sacrificing it will cleanly unequip it and free its slot!"
		refresh_view()
	else:
		selected_unit_uid = uid
		refresh_view()

func _update_detail_panel() -> void:
	if selected_unit_uid == -1:
		detail_panel.visible = false
		return
	var unit = PlayerData.get_tower_by_uid(selected_unit_uid)
	if unit.is_empty():
		detail_panel.visible = false
		return
		
	detail_panel.visible = true
	var t_id: String = unit.get("tower_id", "")
	var t_data = GameData.TOWERS.get(t_id, {})
	var trait_data = GameData.TRAITS.get(unit.get("trait_id", "none"), GameData.TRAITS["none"])
	var r_enum = t_data.get("rarity", GameData.Rarity.COMMON)
	var r_name = GameData.RARITY_NAMES.get(r_enum, "Common")
	var r_col: Color = GameData.RARITY_COLORS.get(r_enum, Color.WHITE)
	var is_eq = PlayerData.is_equipped(selected_unit_uid)
	
	# Update Selected Unit Portrait (Portrait)
	var port_asset = "res://assets/%s.svg" % t_id
	if ResourceLoader.exists(port_asset):
		portrait_texture.texture = load(port_asset)
	else:
		portrait_texture.texture = null
		
	portrait_lvl.text = "★ Lv.%d" % int(unit.get("level", 1))
	UIThemeBuilder.style_label(portrait_lvl, 11, Color(0.25, 0.96, 0.55) if is_eq else Color(1.0, 0.88, 0.22), 3)
	
	var port_sb = UIThemeBuilder.make_panel_style(
		Color(0.04, 0.10, 0.18, 0.96),
		Color(0.25, 0.96, 0.55) if is_eq else r_col,
		12, 2, 0, 4, 4
	)
	portrait_frame.add_theme_stylebox_override("panel", port_sb)
	
	var cur_xp = int(unit.get("xp", 0))
	var req_xp = int(unit.get("level", 1)) * 200
	
	var base_dmg = t_data.get("base_damage", 10.0) * (1.0 + (unit["level"] - 1) * 0.05) * trait_data.get("damage_mult", 1.0)
	var spa = t_data.get("base_spa", 1.5) * trait_data.get("spa_mult", 1.0)
	var rng = t_data.get("base_range", 8.0) * trait_data.get("range_mult", 1.0)
	
	if is_feed_mode:
		var total_xp := 0
		for f_uid in feed_selected_uids:
			var f_unit = PlayerData.get_tower_by_uid(f_uid)
			if not f_unit.is_empty():
				total_xp += int(f_unit.get("level", 1)) * 120
		unit_name_label.text = "👑 UPGRADING: %s (Lv.%d)  •  Fuel: %d Units (+%d XP)" % [
			t_data.get("name", ""), unit["level"], feed_selected_uids.size(), total_xp
		]
		unit_stats_label.text = "🔥 Current XP: %d / %d   |   After Feed: %d XP   |   DPS: %.1f" % [
			cur_xp, req_xp, cur_xp + total_xp, base_dmg / spa
		]
		if status_banner_text != "":
			unit_trait_label.text = status_banner_text
		else:
			unit_trait_label.text = "💡 Click any unit card above to mark it for feeding. Equipped bots will be cleanly unequipped!"
			
		equip_btn.text = "✨ Auto-Pick"
		UIThemeBuilder.style_button(equip_btn, "nav", 11)
		
		feed_btn.text = "⚡ Feed (+%d XP)" % total_xp
		UIThemeBuilder.style_button(feed_btn, "feed", 11)
		
		sell_btn.text = "✖ Cancel"
		UIThemeBuilder.style_button(sell_btn, "danger", 11)
		if lock_btn:
			lock_btn.visible = false
	else:
		var p_class = GameData.POWER_CLASSES.get(t_data.get("power_class", "brawler"), {})
		var p_short = p_class.get("short", "⚡ Power")
		var p_rating = int(t_data.get("power_rating", 150))
		unit_name_label.text = "⭐ %s  •  Lv.%d [%s • %s • ⚡%d]" % [
			t_data.get("name", ""), unit["level"], r_name, p_short, p_rating
		]
		unit_stats_label.text = "🔥 DPS: %.1f  |  ⚔️ DMG: %.1f  |  ⚡ SPD: %.2fs  |  🎯 RNG: %.1fm" % [
			base_dmg / spa, base_dmg, spa, rng
		]
		if status_banner_text != "":
			unit_trait_label.text = status_banner_text
		else:
			unit_trait_label.text = "🧬 Trait: [%s] — %s" % [trait_data.get("name", "None"), trait_data.get("desc", "")]
			
		# Dynamic Unequip vs Equip button display (Shows Unequip when unit is already equipped)
		if is_eq:
			equip_btn.text = "✖ Unequip"
			UIThemeBuilder.style_button(equip_btn, "danger", 11)
		else:
			equip_btn.text = "★ Equip"
			UIThemeBuilder.style_button(equip_btn, "success", 11)
			
		feed_btn.text = "🍖 Feed Units"
		UIThemeBuilder.style_button(feed_btn, "primary", 11)
		
		var is_locked: bool = PlayerData.is_unit_locked(selected_unit_uid)
		if lock_btn:
			lock_btn.visible = true
			if is_locked:
				lock_btn.text = "🔒 Unlock"
				UIThemeBuilder.style_button(lock_btn, "danger", 11)
			else:
				lock_btn.text = "🔓 Lock"
				UIThemeBuilder.style_button(lock_btn, "nav", 11)
		
		var sell_rew = PlayerData.get_unit_sell_reward(selected_unit_uid)
		sell_btn.text = "💰 Sell (+%d🪙 +%d💎)" % [sell_rew["gold"], sell_rew["gems"]]
		UIThemeBuilder.style_button(sell_btn, "danger", 11)
		if is_locked:
			sell_btn.disabled = true
			sell_btn.tooltip_text = "🔒 Unit is locked! Unlock it first to sell."
		else:
			sell_btn.disabled = (PlayerData.inventory.size() <= 1)
			sell_btn.tooltip_text = ""

func _on_lock_pressed() -> void:
	if selected_unit_uid == -1:
		return
	var new_lock = PlayerData.toggle_unit_lock(selected_unit_uid)
	if new_lock:
		status_banner_text = "🔒 Unit LOCKED! It cannot be sold or sacrificed."
	else:
		status_banner_text = "🔓 Unit UNLOCKED."
	UIThemeBuilder.play_pulse_anim(detail_panel, 1.04)
	refresh_view()

func _on_equip_or_auto_pressed() -> void:
	if selected_unit_uid == -1:
		return
	if is_feed_mode:
		# Auto-pick up to 4 spare units (preferring unequipped, unlocked units)
		feed_selected_uids.clear()
		for u in PlayerData.inventory:
			var u_uid: int = int(u["uid"])
			if u_uid != selected_unit_uid and not PlayerData.is_equipped(u_uid) and not PlayerData.is_unit_locked(u_uid):
				feed_selected_uids.append(u_uid)
				if feed_selected_uids.size() >= 4:
					break
		if feed_selected_uids.is_empty():
			status_banner_text = "⚠️ No unequipped, unlocked spare units available! Unlock or pick units manually."
		else:
			status_banner_text = "✨ Auto-selected %d spare unit(s)! Click 'Confirm Feed' to upgrade!" % feed_selected_uids.size()
		refresh_view()
		return
		
	# Dynamic Equip / Unequip handling
	if PlayerData.is_equipped(selected_unit_uid):
		PlayerData.unequip_tower(selected_unit_uid)
		status_banner_text = "📦 Unit unequipped from battle loadout! Hotbar slot is now vacant."
	else:
		if PlayerData.equip_tower(selected_unit_uid):
			status_banner_text = "★ Unit equipped to battle loadout!"
		else:
			status_banner_text = "⚠️ Hotbar is full (5/5)! Unequip a unit first."
	UIThemeBuilder.play_pulse_anim(detail_panel, 1.03)
	refresh_view()

func _on_feed_pressed() -> void:
	if selected_unit_uid == -1:
		return
	if not is_feed_mode:
		is_feed_mode = true
		feed_selected_uids.clear()
		status_banner_text = "🔥 Click spare unit cards above to mark them for feeding, then click Confirm!"
		UIThemeBuilder.play_pulse_anim(detail_panel, 1.03)
		refresh_view()
		return
		
	# In Feed Mode -> Confirm Feed!
	if feed_selected_uids.is_empty():
		status_banner_text = "⚠️ Click at least 1 unit card above (or click Auto-Pick Spares)!"
		_update_detail_panel()
		return
		
	var res = PlayerData.feed_unit(selected_unit_uid, feed_selected_uids.duplicate())
	is_feed_mode = false
	feed_selected_uids.clear()
	if res.get("success", false):
		if AudioManager: AudioManager.play_sfx("tower_upgrade")
		status_banner_text = "🎉 FEED SUCCESS! +%d XP Gained -> Unit is now Level %d! Any equipped sacrifices were cleanly freed." % [
			res.get("xp_gained", 0), res.get("new_level", 1)
		]
		UIThemeBuilder.play_pulse_anim(detail_panel, 1.06)
	else:
		status_banner_text = "⚠️ " + res.get("message", "Feed failed.")
	refresh_view()

func _on_sell_or_cancel_pressed() -> void:
	if is_feed_mode:
		is_feed_mode = false
		feed_selected_uids.clear()
		status_banner_text = "Feed mode cancelled."
		refresh_view()
		return
		
	if selected_unit_uid == -1:
		return
	var u_data = PlayerData.get_tower_by_uid(selected_unit_uid)
	var t_name = GameData.TOWERS.get(u_data.get("tower_id", ""), {}).get("name", "Unit")
	var was_eq = PlayerData.is_equipped(selected_unit_uid)
	var res = PlayerData.sell_unit(selected_unit_uid)
	if res.get("success", false):
		if AudioManager: AudioManager.play_sfx("coins")
		selected_unit_uid = PlayerData.inventory[0]["uid"] if not PlayerData.inventory.is_empty() else -1
		status_banner_text = "💰 SOLD %s for +%d Gold 🪙 & +%d Gems 💎!%s" % [
			t_name, res.get("gold", 0), res.get("gems", 0),
			" (Freed from battle loadout)" if was_eq else ""
		]
		UIThemeBuilder.play_pulse_anim(detail_panel, 1.05)
	else:
		status_banner_text = "⚠️ " + res.get("message", "Cannot sell unit.")
	refresh_view()
