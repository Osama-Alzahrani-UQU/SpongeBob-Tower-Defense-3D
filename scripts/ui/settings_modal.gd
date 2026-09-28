extends Panel

## SettingsModal - Screen-Bounded Settings & Promo Code Chips

@onready var title_label: Label = $VBox/Title
@onready var lag_check: CheckBox = $VBox/SettingsHBox/LagCheck
@onready var sfx_slider: HSlider = $VBox/SettingsHBox/SFXSlider
@onready var music_slider: HSlider = $VBox/SettingsHBox/MusicSlider

@onready var code_input: LineEdit = $VBox/CodesBox/HBox/CodeInput
@onready var redeem_btn: Button = $VBox/CodesBox/HBox/RedeemBtn
@onready var code_status_lbl: Label = $VBox/CodesBox/StatusLbl
@onready var code_lock_msg: Label = $VBox/CodesBox/LockMsg
@onready var close_btn: Button = $VBox/CloseBtn

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(1.0, 0.82, 0.22), Vector2(580, 460))
	$VBox.add_theme_constant_override("separation", 8)
	$VBox/SettingsHBox.add_theme_constant_override("separation", 4)
	$VBox/CodesBox.add_theme_constant_override("separation", 6)
	$VBox/CodesBox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	title_label.text = "⚙️ SETTINGS & SECRET PROMO CODES"
	UIThemeBuilder.style_label(title_label, 20, Color(1.0, 0.86, 0.22), 4)
	UIThemeBuilder.style_label($VBox/SettingsHBox/SFXLabel, 13, Color(0.85, 0.95, 1.0), 2)
	UIThemeBuilder.style_label($VBox/SettingsHBox/MusicLabel, 13, Color(0.85, 0.95, 1.0), 2)
	UIThemeBuilder.style_label(code_status_lbl, 13, Color(0.35, 0.95, 0.55), 2)
	code_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var input_sb = UIThemeBuilder.make_panel_style(Color(0.03, 0.08, 0.15, 0.95), Color(0.28, 0.78, 1.0), 12, 2, 0, 12, 4)
	code_input.add_theme_stylebox_override("normal", input_sb)
	code_input.add_theme_stylebox_override("focus", input_sb)
	code_input.add_theme_stylebox_override("read_only", input_sb)
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_input.custom_minimum_size = Vector2(0, 36)
	
	UIThemeBuilder.style_slider(sfx_slider)
	UIThemeBuilder.style_slider(music_slider)
	UIThemeBuilder.style_button(lag_check, "nav", 13)
	
	redeem_btn.text = "🎁 Redeem"
	close_btn.text = "✖ Close"
	redeem_btn.custom_minimum_size = Vector2(110, 36)
	close_btn.custom_minimum_size = Vector2(120, 32)
	UIThemeBuilder.style_button(redeem_btn, "success", 13)
	UIThemeBuilder.style_button(close_btn, "danger", 13)
	
	# Compact One-Click Promo Code Chips Row (fits inside 536px inner width)
	var chips_row = HBoxContainer.new()
	chips_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	chips_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chips_row.add_theme_constant_override("separation", 6)
	for code_str in ["BIKINIBOTTOM", "SECRETFORMULA", "SPONGEBOB2026", "KRUSTYKRAB"]:
		var chip = Button.new()
		chip.text = "🎟️ " + code_str
		chip.custom_minimum_size = Vector2(118, 28)
		UIThemeBuilder.style_button(chip, "nav", 10)
		chip.pressed.connect(func():
			code_input.text = code_str
			_on_redeem_pressed()
		)
		chips_row.add_child(chip)
	$VBox/CodesBox.add_child(chips_row)
	
	close_btn.pressed.connect(func():
		visible = false
		if AudioManager: AudioManager.play_sfx("ui_close")
	)
	redeem_btn.pressed.connect(_on_redeem_pressed)
	lag_check.toggled.connect(_on_lag_toggled)
	
	sfx_slider.value = PlayerData.sfx_volume
	music_slider.value = PlayerData.music_volume
	lag_check.button_pressed = PlayerData.lag_reducer_enabled

	sfx_slider.value_changed.connect(func(val: float):
		PlayerData.sfx_volume = val
		if AudioManager: AudioManager.set_sfx_volume(val)
	)
	music_slider.value_changed.connect(func(val: float):
		PlayerData.music_volume = val
		if AudioManager: AudioManager.set_music_volume(val)
	)

func refresh_view() -> void:
	code_input.text = ""
	if PlayerData.level < 10:
		code_lock_msg.visible = true
		code_lock_msg.text = "🔒 PROMO CODES LOCKED UNTIL LEVEL 10! (Current: %d)" % PlayerData.level
		code_input.editable = false
		redeem_btn.disabled = true
	else:
		code_lock_msg.visible = false
		code_input.editable = true
		redeem_btn.disabled = false
		code_status_lbl.text = "💡 Click any promo code chip below or type a code to claim rewards!"
		code_status_lbl.modulate = Color(0.45, 0.92, 1.0)

func _on_lag_toggled(toggled: bool) -> void:
	PlayerData.lag_reducer_enabled = toggled
	PlayerData.save_game()

func _on_redeem_pressed() -> void:
	var code = code_input.text.strip_edges()
	if code.is_empty():
		return
		
	var res = PlayerData.redeem_code(code)
	if res.get("success", false):
		var r = res.get("reward", {})
		code_status_lbl.text = "🎉 REDEEMED! +%d Gold, +%d Gems, +%d Trait Dice!" % [
			r.get("gold", 0), r.get("gems", 0), r.get("rerolls", 0)
		]
		code_status_lbl.modulate = Color(0.25, 0.98, 0.5)
		if AudioManager: AudioManager.play_sfx("gems")
	else:
		code_status_lbl.text = "⚠️ %s" % res.get("message", "Invalid or already redeemed code")
		code_status_lbl.modulate = Color(1.0, 0.45, 0.45)
