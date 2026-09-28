extends Panel

## AFKModal - Screen-Bounded Sandy's Treedome AFK Resort Passive Harvester

@onready var lobby = get_node_or_null("/root/Lobby")
@onready var title_label: Label = $VBox/Title
@onready var gold_accum_lbl: Label = $VBox/GoldAccumLbl
@onready var gems_accum_lbl: Label = $VBox/GemsAccumLbl
@onready var claim_btn: Button = $VBox/ClaimBtn
@onready var close_btn: Button = $VBox/CloseBtn

var xp_accum_lbl: Label = null
var status_badge: Label = null
var rates_lbl: Label = null
var zen_btn: Button = null
var top_close_btn: Button = null

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(1.0, 0.84, 0.22), Vector2(500, 380))
	$VBox.add_theme_constant_override("separation", 6)
	title_label.text = "🐿️ SANDY'S AFK RESORT"
	UIThemeBuilder.style_label(title_label, 18, Color(1.0, 0.86, 0.22), 4)
	
	status_badge = Label.new()
	status_badge.name = "StatusBadge"
	status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(status_badge, 11, Color(0.25, 0.95, 0.85), 3)
	$VBox.add_child(status_badge)
	$VBox.move_child(status_badge, 1)
	
	xp_accum_lbl = Label.new()
	xp_accum_lbl.name = "XpAccumLbl"
	xp_accum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(xp_accum_lbl, 14, Color(0.35, 0.85, 1.0), 3)
	$VBox.add_child(xp_accum_lbl)
	$VBox.move_child(xp_accum_lbl, 4)
	
	rates_lbl = Label.new()
	rates_lbl.name = "RatesLbl"
	rates_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(rates_lbl, 11, Color(0.75, 0.82, 0.92), 2)
	$VBox.add_child(rates_lbl)
	$VBox.move_child(rates_lbl, 5)
	
	zen_btn = Button.new()
	zen_btn.name = "ZenModeBtn"
	zen_btn.text = "🌴 Toggle Treedome 2.5x Boost"
	zen_btn.custom_minimum_size = Vector2(230, 30)
	zen_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIThemeBuilder.style_button(zen_btn, "cyan", 11)
	UIThemeBuilder.bind_button_anim(zen_btn)
	zen_btn.pressed.connect(_on_zen_btn_pressed)
	$VBox.add_child(zen_btn)
	$VBox.move_child(zen_btn, 6)

	UIThemeBuilder.style_label(gold_accum_lbl, 15, Color(1.0, 0.88, 0.28), 3)
	UIThemeBuilder.style_label(gems_accum_lbl, 15, Color(0.85, 0.52, 1.0), 3)
	
	claim_btn.text = "💰 Claim All Passive Rewards"
	close_btn.text = "✖ Close"
	claim_btn.custom_minimum_size = Vector2(230, 34)
	close_btn.custom_minimum_size = Vector2(100, 26)
	
	UIThemeBuilder.style_button(claim_btn, "success", 13)
	UIThemeBuilder.style_button(close_btn, "danger", 12)
	UIThemeBuilder.bind_button_anim(claim_btn)
	UIThemeBuilder.bind_button_anim(close_btn)
	
	# Top right corner close button for tester compatibility
	top_close_btn = Button.new()
	top_close_btn.name = "TopCloseBtn"
	top_close_btn.text = "✖"
	top_close_btn.custom_minimum_size = Vector2(44, 38)
	top_close_btn.size = Vector2(44, 38)
	top_close_btn.position = Vector2(size.x - 52, 10)
	UIThemeBuilder.style_button(top_close_btn, "danger", 14)
	UIThemeBuilder.bind_button_anim(top_close_btn)
	top_close_btn.pressed.connect(func(): visible = false)
	add_child(top_close_btn)
	move_child(top_close_btn, get_child_count() - 1)
	
	close_btn.pressed.connect(func(): visible = false)
	claim_btn.pressed.connect(_on_claim_pressed)
	
	PlayerData.afk_rewards_updated.connect(func(_g, _gm, _xp):
		if visible:
			refresh_view()
	)

func refresh_view() -> void:
	if not is_inside_tree():
		return
	var stat: Dictionary = PlayerData.get_afk_status()
	gold_accum_lbl.text = "🪙 Accumulated Gold: +%d" % stat["gold"]
	gems_accum_lbl.text = "💎 Accumulated Gems: +%d" % stat["gems"]
	if xp_accum_lbl:
		xp_accum_lbl.text = "⭐ Accumulated XP: +%d" % stat["xp"]
	if status_badge:
		if stat["is_boosted"]:
			status_badge.text = "🔥 2.5X TREEDOME RESORT BOOST: ACTIVE! 🔥"
			status_badge.modulate = Color(1.0, 0.85, 0.25)
		else:
			status_badge.text = "⚡ PASSIVE HARVEST ACTIVE EVERYWHERE (Battles, Menus, Offline)"
			status_badge.modulate = Color(0.3, 0.9, 0.95)
	if rates_lbl:
		rates_lbl.text = "Harvest Rates: %d Gold/min • %d Gems/min • %d XP/min" % [stat["gold_per_min"], stat["gems_per_min"], stat["xp_per_min"]]
	if zen_btn:
		zen_btn.text = "🌴 Treedome 2.5x Boost: " + ("ON" if stat["is_boosted"] else "OFF")

func _on_zen_btn_pressed() -> void:
	PlayerData.is_afk_boosted = not PlayerData.is_afk_boosted
	refresh_view()

func _on_claim_pressed() -> void:
	var claimed: Dictionary = PlayerData.claim_afk_rewards()
	if lobby:
		lobby.accumulated_gold = 0
		lobby.accumulated_gems = 0
	refresh_view()
	
	if claimed["gold"] > 0 or claimed["gems"] > 0 or claimed["xp"] > 0:
		if AudioManager: AudioManager.play_sfx("coins")
		var prev_text = claim_btn.text
		claim_btn.text = "✨ CLAIMED +%dG +%d💎! ✨" % [claimed["gold"], claimed["gems"]]
		var tw = create_tween()
		tw.tween_interval(1.4)
		tw.tween_callback(func():
			if is_instance_valid(claim_btn):
				claim_btn.text = prev_text
		)
