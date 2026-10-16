extends Node2D

## Mini Shop - Main Game Loop Entry Point
## Coordinates environment, shelves, cashier counter, customers, player, day cycle, and HUD.

const AssetMgr = preload("res://scripts/autoload/asset_manager.gd")

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var shelves: Node2D = $Shelves
@onready var cashier_counter: Node2D = $CashierCounter
@onready var customer_spawner: Node2D = $CustomerSpawner

# HUD Badge Labels & Controls
@onready var status_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/StatusContainer/StatusLabel
@onready var open_button: Button = $UI/HUDMargin/PanelContainer/HBoxContainer/OpenButton
@onready var day_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/DayContainer/DayLabel
@onready var time_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/TimeContainer/TimeLabel
@onready var customer_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/CustomerContainer/CustomerLabel
@onready var money_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/MoneyContainer/MoneyLabel
@onready var served_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/ServedContainer/ServedLabel
@onready var reputation_label: Label = $UI/HUDMargin/PanelContainer/HBoxContainer/ReputationContainer/ReputationLabel

func _ready() -> void:
	if camera:
		camera.position = Vector2(576, 324)

	_setup_hud_icons()

	# Link shelves and cashier counter to customer spawner
	if customer_spawner and shelves and cashier_counter:
		customer_spawner.configure(shelves.get_children(), cashier_counter)
	
	if customer_spawner:
		customer_spawner.customer_count_changed.connect(_on_customer_count_changed)

	if open_button:
		open_button.pressed.connect(_on_open_button_pressed)

	# Connect economy and day cycle signals from GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.money_changed.connect(_on_money_changed)
		gm.customer_served.connect(_on_customer_served)
		gm.time_updated.connect(_on_time_updated)
		gm.reputation_changed.connect(_on_reputation_changed)
		gm.new_day_started.connect(_on_new_day_started)
		gm.day_state_changed.connect(_on_day_state_changed)
		
		_on_money_changed(gm.money)
		_on_customer_served(gm.total_served, 0)
		_on_reputation_changed(gm.get_reputation_rating())
		_on_new_day_started(gm.current_day)
		_on_day_state_changed(gm.day_state)

func _setup_hud_icons() -> void:
	if open_button:
		var check_tex: Texture2D = AssetMgr.get_texture("icon_check")
		if check_tex:
			open_button.icon = check_tex
			open_button.expand_icon = true

	var badge_icons := {
		"UI/HUDMargin/PanelContainer/HBoxContainer/DayContainer": "icon_day",
		"UI/HUDMargin/PanelContainer/HBoxContainer/TimeContainer": "icon_clock",
		"UI/HUDMargin/PanelContainer/HBoxContainer/CustomerContainer": "icon_customer",
		"UI/HUDMargin/PanelContainer/HBoxContainer/ReputationContainer": "icon_star",
		"UI/HUDMargin/PanelContainer/HBoxContainer/ServedContainer": "icon_check",
		"UI/HUDMargin/PanelContainer/HBoxContainer/MoneyContainer": "icon_money"
	}

	for node_path: String in badge_icons.keys():
		var container := get_node_or_null(node_path) as PanelContainer
		var tex: Texture2D = AssetMgr.get_texture(badge_icons[node_path])
		if container and tex:
			var base_style := container.get_theme_stylebox("panel")
			if base_style is StyleBoxFlat:
				var custom_style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
				custom_style.content_margin_left = 26.0
				container.add_theme_stylebox_override("panel", custom_style)
			container.draw.connect(_draw_badge_icon.bind(container, tex))
			container.queue_redraw()

func _draw_badge_icon(container: PanelContainer, tex: Texture2D) -> void:
	if is_instance_valid(container) and tex != null:
		var icon_y := (container.size.y - 16.0) * 0.5
		container.draw_texture_rect(tex, Rect2(6.0, icon_y, 16.0, 16.0), false)

func _on_open_button_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.open_store()

func _on_day_state_changed(new_state: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm or not status_label:
		return

	if new_state == gm.DayState.PRE_OPEN:
		status_label.text = "STATUS: PERSIAPAN (TUTUP)"
		status_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
		if open_button:
			open_button.visible = true
	elif new_state == gm.DayState.OPEN:
		status_label.text = "STATUS: BUKA (08:00 - 21:00)"
		status_label.set("theme_override_colors/font_color", Color(0.40, 0.95, 0.55))
		if open_button:
			open_button.visible = false
	elif new_state == gm.DayState.CLOSING:
		status_label.text = "STATUS: MENUTUP TOKO"
		status_label.set("theme_override_colors/font_color", Color(0.95, 0.65, 0.25))
		if open_button:
			open_button.visible = false
	elif new_state == gm.DayState.SUMMARY:
		status_label.text = "STATUS: REKAP HARIAN"
		status_label.set("theme_override_colors/font_color", Color(0.45, 0.85, 0.95))
		if open_button:
			open_button.visible = false

func _on_customer_count_changed(active: int, max_cap: int) -> void:
	if customer_label:
		customer_label.text = "Toko: " + str(active) + "/" + str(max_cap)

func _on_money_changed(new_amount: int) -> void:
	if money_label:
		money_label.text = "$" + str(new_amount)

func _on_customer_served(total_count: int, _sale: int) -> void:
	if served_label:
		served_label.text = "Selesai: " + str(total_count)

func _on_time_updated(_hour: int, _minute: int, time_str: String) -> void:
	if time_label:
		time_label.text = time_str

func _on_reputation_changed(rating: float) -> void:
	if reputation_label:
		reputation_label.text = "Rating: " + str(rating)

func _on_new_day_started(day_num: int) -> void:
	if day_label:
		day_label.text = "Hari " + str(day_num)
	if time_label:
		time_label.text = "08:00"
	if served_label:
		var gm = get_node_or_null("/root/GameManager")
		served_label.text = "Selesai: " + str(gm.total_served if gm else 0)
	if status_label:
		status_label.text = "STATUS: PERSIAPAN (TUTUP)"
		status_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
	if open_button:
		open_button.visible = true
