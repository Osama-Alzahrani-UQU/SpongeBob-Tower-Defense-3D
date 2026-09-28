extends Panel

## CreditsModal - Official Game Credits, Creator Attribution & Ownership Rights
## Owner & Creator: Osama-Alzahrani-UQU (https://github.com/Osama-Alzahrani-UQU)

const OWNER_GITHUB_USER: String = "Osama-Alzahrani-UQU"
const OWNER_GITHUB_URL: String = "https://github.com/Osama-Alzahrani-UQU"

var status_lbl: Label = null
var open_github_btn: Button = null
var copy_github_btn: Button = null
var close_btn: Button = null
var github_name_lbl: Label = null
var github_url_lbl: Label = null

func _ready() -> void:
	UIThemeBuilder.style_modal(self, Color(1.0, 0.84, 0.22), Vector2(640, 480))
	UIThemeBuilder.enforce_ltr_recursive(self)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	UIThemeBuilder.fit_inner_container(self, vbox, 20.0, 14.0)

	# 1. Header Banner
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.text = "👑 OFFICIAL CREDITS & OWNERSHIP"
	UIThemeBuilder.style_label(title_lbl, 20, Color(1.0, 0.90, 0.22), 4)
	title_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "🌊 SPONGEBOB TOWER DEFENSE 3D — OFFICIAL EDITION 🌊"
	UIThemeBuilder.style_label(sub_lbl, 11, Color(0.45, 0.92, 1.0), 2)
	title_vbox.add_child(sub_lbl)

	var right_pad := Control.new()
	right_pad.custom_minimum_size = Vector2(52, 10)
	header_hbox.add_child(right_pad)

	# 2. Golden Creator & Owner Showcase Card
	var owner_card := Panel.new()
	owner_card.name = "OwnerCard"
	owner_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	owner_card.clip_contents = false
	var card_sb = UIThemeBuilder.make_panel_style(
		Color(0.04, 0.11, 0.20, 0.96),
		Color(1.0, 0.84, 0.22, 0.95),
		16, 2, 0, 14, 10
	)
	owner_card.add_theme_stylebox_override("panel", card_sb)
	vbox.add_child(owner_card)

	var card_vbox := VBoxContainer.new()
	card_vbox.name = "CardVBox"
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 6)
	owner_card.add_child(card_vbox)
	UIThemeBuilder.fit_inner_container(owner_card, card_vbox, 14.0, 10.0)

	# Official Ownership Badge Pill
	var badge_pill := Panel.new()
	badge_pill.custom_minimum_size = Vector2(0, 26)
	badge_pill.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_pill_style(Color(0.18, 0.12, 0.02, 0.92), Color(1.0, 0.84, 0.22), 8)
	)
	card_vbox.add_child(badge_pill)

	var badge_lbl := Label.new()
	badge_lbl.text = "⭐ CREATED, DEVELOPED & OWNED BY ⭐"
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(badge_lbl, 11, Color(1.0, 0.92, 0.35), 2)
	badge_pill.add_child(badge_lbl)
	UIThemeBuilder.fit_inner_container(badge_pill, badge_lbl, 8.0, 2.0)

	# Prominent GitHub Account Handle
	github_name_lbl = Label.new()
	github_name_lbl.name = "GitHubAccountLbl"
	github_name_lbl.text = "🐙 GitHub: " + OWNER_GITHUB_USER
	github_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(github_name_lbl, 22, Color(0.28, 0.96, 0.65), 4)
	card_vbox.add_child(github_name_lbl)

	# Direct GitHub URL
	github_url_lbl = Label.new()
	github_url_lbl.name = "GitHubUrlLbl"
	github_url_lbl.text = OWNER_GITHUB_URL
	github_url_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(github_url_lbl, 13, Color(0.55, 0.88, 1.0), 2)
	card_vbox.add_child(github_url_lbl)

	# Credits Roles Breakdown
	var roles_panel := Panel.new()
	roles_panel.custom_minimum_size = Vector2(0, 88)
	roles_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.02, 0.07, 0.14, 0.90), Color(0.22, 0.68, 0.95, 0.75), 12, 1, 0, 10, 6)
	)
	card_vbox.add_child(roles_panel)

	var roles_lbl := Label.new()
	roles_lbl.name = "RolesLbl"
	roles_lbl.text = (
		"🛠️ Lead Game Developer & Architect: " + OWNER_GITHUB_USER + "\n" +
		"🎨 3D Procedural Models & Shaders: " + OWNER_GITHUB_USER + "\n" +
		"⚔️ Combat, Waves, Gacha & UI Systems: " + OWNER_GITHUB_USER + "\n" +
		"🔒 Full Project Ownership & Rights: © 2026 " + OWNER_GITHUB_USER
	)
	roles_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roles_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(roles_lbl, 11, Color(0.90, 0.96, 1.0), 2)
	roles_panel.add_child(roles_lbl)
	UIThemeBuilder.fit_inner_container(roles_panel, roles_lbl, 8.0, 4.0)

	# Status feedback label
	status_lbl = Label.new()
	status_lbl.name = "StatusLbl"
	status_lbl.text = "✅ Official Verified Project Owner: " + OWNER_GITHUB_USER
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIThemeBuilder.style_label(status_lbl, 11, Color(1.0, 0.88, 0.32), 2)
	card_vbox.add_child(status_lbl)

	# 3. Interactive Action Buttons Row
	var btn_hbox := HBoxContainer.new()
	btn_hbox.name = "ActionButtons"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_hbox)

	open_github_btn = Button.new()
	open_github_btn.name = "OpenGitHubBtn"
	open_github_btn.text = "🌐 Open GitHub Profile"
	open_github_btn.custom_minimum_size = Vector2(200, 38)
	UIThemeBuilder.style_button(open_github_btn, "success", 13)
	UIThemeBuilder.bind_button_anim(open_github_btn)
	open_github_btn.pressed.connect(_on_open_github_pressed)
	btn_hbox.add_child(open_github_btn)

	copy_github_btn = Button.new()
	copy_github_btn.name = "CopyGitHubBtn"
	copy_github_btn.text = "📋 Copy GitHub Link"
	copy_github_btn.custom_minimum_size = Vector2(185, 38)
	UIThemeBuilder.style_button(copy_github_btn, "gold", 13)
	UIThemeBuilder.bind_button_anim(copy_github_btn)
	copy_github_btn.pressed.connect(_on_copy_github_pressed)
	btn_hbox.add_child(copy_github_btn)

	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✖ Close"
	close_btn.custom_minimum_size = Vector2(120, 38)
	UIThemeBuilder.style_button(close_btn, "danger", 13)
	UIThemeBuilder.bind_button_anim(close_btn)
	close_btn.pressed.connect(func():
		visible = false
		if AudioManager:
			AudioManager.play_sfx("ui_close")
	)
	btn_hbox.add_child(close_btn)

	var top_x: Button = get_node_or_null("TopCloseBtn")
	if top_x:
		move_child(top_x, -1)

func refresh_view() -> void:
	if status_lbl:
		status_lbl.text = "✅ Official Verified Project Owner: " + OWNER_GITHUB_USER
		status_lbl.modulate = Color(1.0, 0.88, 0.32)

func _on_open_github_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	DisplayServer.clipboard_set(OWNER_GITHUB_URL)
	OS.shell_open(OWNER_GITHUB_URL)
	if status_lbl:
		status_lbl.text = "🌐 Opened GitHub: " + OWNER_GITHUB_URL
		status_lbl.modulate = Color(0.35, 1.0, 0.65)

func _on_copy_github_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	DisplayServer.clipboard_set(OWNER_GITHUB_URL)
	if status_lbl:
		status_lbl.text = "📋 Copied to Clipboard: " + OWNER_GITHUB_URL
		status_lbl.modulate = Color(0.35, 0.95, 1.0)
