extends Panel

## TradingModal - Visual Unit Card Spectral Trading Hub & Unblocked Close Handler

@onready var title_label: Label = $TradeContent/Title
@onready var lock_gate_label: Label = $LockGateLabel
@onready var trade_content: VBoxContainer = $TradeContent

@onready var my_panel: VBoxContainer = $TradeContent/HBox/MyPanel
@onready var partner_panel: VBoxContainer = $TradeContent/HBox/PartnerPanel
@onready var my_offer_list: ItemList = $TradeContent/HBox/MyPanel/MyList
@onready var partner_offer_list: ItemList = $TradeContent/HBox/PartnerPanel/PartnerList

@onready var action_hbox: HBoxContainer = $TradeContent/ActionHBox
@onready var lock_btn: Button = $TradeContent/ActionHBox/LockBtn
@onready var confirm_btn: Button = $TradeContent/ActionHBox/ConfirmBtn
@onready var status_lbl: Label = $TradeContent/StatusLbl
@onready var close_btn: Button = $CloseBtn

var bottom_close_btn: Button = null
var my_grid: GridContainer = null
var partner_grid: GridContainer = null

var is_locked: bool = false
var offered_uids: Array = []
var selected_bounty_idx: int = 0

const DUTCHMAN_BOUNTIES = [
	{"tower_id": "flying_dutchman", "level": 8, "trait_id": "secret_formula", "gold": 800, "gems": 120, "badge": "🧪 FORMULA +120💎"},
	{"tower_id": "man_ray", "level": 10, "trait_id": "strike_3", "gold": 1200, "gems": 80, "badge": "🪨 STRIKE III +80💎"},
	{"tower_id": "mermaid_man", "level": 12, "trait_id": "vortex", "gold": 1500, "gems": 90, "badge": "⚡ VORTEX +1500🪙"},
	{"tower_id": "hash_slinging_slasher", "level": 9, "trait_id": "sea_bear", "gold": 1400, "gems": 110, "badge": "👻 SEA BEAR +110💎"},
	{"tower_id": "king_neptune", "level": 15, "trait_id": "neptunes_crown", "gold": 2500, "gems": 150, "badge": "👑 CROWN +150💎"},
	{"tower_id": "doodlebob", "level": 14, "trait_id": "secret_formula", "gold": 3000, "gems": 180, "badge": "✏️ FORMULA +180💎"}
]

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(0.25, 0.98, 0.68), Vector2(760, 500))
	UIThemeBuilder.fit_inner_container(self, trade_content, 22.0, 16.0)
	UIThemeBuilder.fit_inner_container(self, lock_gate_label, 22.0, 16.0)
	trade_content.add_theme_constant_override("separation", 8)
	
	title_label.text = "👻 FLYING DUTCHMAN SPECTRAL TRADING"
	UIThemeBuilder.style_label(title_label, 20, Color(0.32, 1.0, 0.68), 4)
	
	var my_hdr: Label = $TradeContent/HBox/MyPanel/Label
	var pt_hdr: Label = $TradeContent/HBox/PartnerPanel/Label
	my_hdr.text = "📦 YOUR UNITS (Click Cards to Offer)"
	pt_hdr.text = "👻 DUTCHMAN'S BOUNTY (Click Reward Card)"
	my_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pt_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(my_hdr, 14, Color(0.45, 0.92, 1.0), 3)
	UIThemeBuilder.style_label(pt_hdr, 14, Color(1.0, 0.86, 0.25), 3)
	UIThemeBuilder.style_label(status_lbl, 13, Color(0.88, 0.96, 1.0), 3)
	UIThemeBuilder.style_label(lock_gate_label, 18, Color(1.0, 0.4, 0.4), 4)
	
	# Hide legacy text ItemLists and build visual Unit Card grids inside ScrollContainers
	my_offer_list.visible = false
	partner_offer_list.visible = false
	
	$TradeContent/HBox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$TradeContent/HBox.add_theme_constant_override("separation", 14)
	
	var box_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.09, 0.16, 0.94), Color(0.22, 0.78, 0.62, 0.85), 16, 2, 0, 10, 8)
	
	var my_scroll = ScrollContainer.new()
	my_scroll.add_theme_stylebox_override("panel", box_sb)
	my_scroll.custom_minimum_size = Vector2(0, 250)
	my_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	my_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	my_panel.add_child(my_scroll)
	
	my_grid = GridContainer.new()
	my_grid.columns = 3
	my_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_grid.add_theme_constant_override("h_separation", 8)
	my_grid.add_theme_constant_override("v_separation", 8)
	my_scroll.add_child(my_grid)
	
	var partner_scroll = ScrollContainer.new()
	partner_scroll.add_theme_stylebox_override("panel", box_sb)
	partner_scroll.custom_minimum_size = Vector2(0, 250)
	partner_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	partner_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partner_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	partner_panel.add_child(partner_scroll)
	
	partner_grid = GridContainer.new()
	partner_grid.columns = 3
	partner_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partner_grid.add_theme_constant_override("h_separation", 8)
	partner_grid.add_theme_constant_override("v_separation", 8)
	partner_scroll.add_child(partner_grid)
	
	# Add Bottom Close Button in ActionHBox in addition to the Top-Right '✖' Button
	bottom_close_btn = Button.new()
	bottom_close_btn.name = "BottomCloseBtn"
	bottom_close_btn.text = "✖ Close"
	bottom_close_btn.custom_minimum_size = Vector2(130, 38)
	UIThemeBuilder.style_button(bottom_close_btn, "danger", 13)
	bottom_close_btn.pressed.connect(func(): visible = false)
	action_hbox.add_child(bottom_close_btn)
	
	UIThemeBuilder.style_button(lock_btn, "primary", 14)
	UIThemeBuilder.style_button(confirm_btn, "success", 14)
	lock_btn.custom_minimum_size = Vector2(165, 38)
	confirm_btn.custom_minimum_size = Vector2(175, 38)
	
	# Ensure Top-Right '✖' button is front-most, large (44x38), and unblocked
	UIThemeBuilder.ensure_top_close_button(self, 740.0)
	
	lock_btn.pressed.connect(_on_lock_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)

func refresh_view() -> void:
	is_locked = false
	offered_uids.clear()
	if not PlayerData.inventory.is_empty():
		for u in PlayerData.inventory:
			if not PlayerData.is_equipped(u["uid"]):
				offered_uids.append(u["uid"])
				break
		if offered_uids.is_empty():
			offered_uids.append(PlayerData.inventory[0]["uid"])
			
	confirm_btn.disabled = true
	lock_btn.text = "🔒 1. Lock Offer"
	confirm_btn.text = "✅ 2. Accept Trade"
	lock_btn.disabled = false
	status_lbl.text = "💡 Click your unit cards on the left to offer, and pick a Dutchman Bounty card on the right!"
	
	UIThemeBuilder.ensure_top_close_button(self, size.x)
	
	if PlayerData.level < 15:
		lock_gate_label.visible = true
		trade_content.visible = false
		lock_gate_label.text = "🔒 LEVEL 15 REQUIRED TO TRADE!\n(Current Level: %d)" % PlayerData.level
	else:
		lock_gate_label.visible = false
		trade_content.visible = true
		_populate_trade_cards()

func _populate_trade_cards() -> void:
	if not my_grid or not partner_grid:
		return
	for c in my_grid.get_children():
		c.queue_free()
	for c in partner_grid.get_children():
		c.queue_free()
		
	for u in PlayerData.inventory:
		var uid = u["uid"]
		var is_eq = PlayerData.is_equipped(uid)
		var is_off = (uid in offered_uids)
		var sel_mode = "trade_selected" if is_off else ""
		var card = UIThemeBuilder.create_unit_card(
			u["tower_id"],
			u.get("level", 1),
			u.get("trait_id", "none"),
			is_eq,
			-1,
			Vector2(98, 108),
			sel_mode
		)
		card.pressed.connect(func():
			if is_locked:
				return
			UIThemeBuilder.play_pulse_anim(card, 1.09)
			if uid in offered_uids:
				offered_uids.erase(uid)
			else:
				offered_uids.append(uid)
			_populate_trade_cards()
		)
		my_grid.add_child(card)
		
	for idx in range(DUTCHMAN_BOUNTIES.size()):
		var b = DUTCHMAN_BOUNTIES[idx]
		var is_sel = (idx == selected_bounty_idx)
		var sel_mode = "bounty_selected" if is_sel else ""
		var badge_txt = "🎯 SELECTED" if is_sel else b["badge"]
		var b_card = UIThemeBuilder.create_unit_card(
			b["tower_id"],
			b["level"],
			b["trait_id"],
			false,
			-1,
			Vector2(98, 108),
			sel_mode,
			badge_txt
		)
		b_card.pressed.connect(func():
			if is_locked:
				return
			UIThemeBuilder.play_pulse_anim(b_card, 1.09)
			selected_bounty_idx = idx
			var t_name = GameData.TOWERS.get(b["tower_id"], {}).get("name", "Unit")
			status_lbl.text = "🎯 Selected Bounty: %s (Lv.%d) + %d Gold & %d Gems!" % [
				t_name, b["level"], b["gold"], b["gems"]
			]
			_populate_trade_cards()
		)
		partner_grid.add_child(b_card)

func _on_lock_pressed() -> void:
	if offered_uids.is_empty():
		status_lbl.text = "⚠️ Click at least 1 unit card in 'Your Units' on the left to lock your offer!"
		return
	is_locked = true
	lock_btn.disabled = true
	status_lbl.text = "⏳ Spectral contract locked (%d unit(s) offered)! Verifying (1.2s)..." % offered_uids.size()
	
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree() and visible and is_locked:
		confirm_btn.disabled = false
		status_lbl.text = "✅ Spectral contract verified! Click 'Accept Trade' to claim your Bounty!"

func _on_confirm_pressed() -> void:
	var b = DUTCHMAN_BOUNTIES[selected_bounty_idx]
	# Remove up to 1 unequipped offered unit if player has >1 units
	for uid in offered_uids:
		if PlayerData.inventory.size() > 1 and not PlayerData.is_equipped(uid):
			var u = PlayerData.get_tower_by_uid(uid)
			if not u.is_empty():
				PlayerData.inventory.erase(u)
				break
				
	PlayerData.add_gold(b["gold"])
	PlayerData.add_gems(b["gems"])
	var new_unit = PlayerData.add_tower(b["tower_id"], b["trait_id"])
	new_unit["level"] = b["level"]
	PlayerData.save_game()
	
	var t_name = GameData.TOWERS.get(b["tower_id"], {}).get("name", "Unit")
	status_lbl.text = "🎉 TRADE COMPLETE! Received %s (Lv.%d) + %d🪙 & %d💎!" % [
		t_name, b["level"], b["gold"], b["gems"]
	]
	confirm_btn.disabled = true
	is_locked = false
	offered_uids.clear()
	_populate_trade_cards()
	UIThemeBuilder.play_pulse_anim(self, 1.03)
