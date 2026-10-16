extends StaticBody2D
class_name UpgradeStation

## Modern Minimarket - Store Operations Management Kiosk Entity
## Provides upgrades: Player Carry Capacity (Tas), Automated Cashier Helper (Hire & Speed), Speed Boost, and Gondola Expansion.

var is_player_near: bool = false
var player_ref: CharacterBody2D = null
var pop_scale: float = 1.0

var selected_index: int = 0

@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_container: PanelContainer = $PromptAnchor/PromptContainer
@onready var prompt_label: Label = $PromptAnchor/PromptContainer/PromptLabel

func _ready() -> void:
	if prompt_container:
		prompt_container.visible = false
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		is_player_near = true
		player_ref = body
		if body.has_method("set_active_upgrade"):
			body.set_active_upgrade(self)
		_update_prompt()
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_near = false
		if player_ref and player_ref.has_method("clear_active_upgrade"):
			player_ref.clear_active_upgrade(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false
		queue_redraw()

func _process(_delta: float) -> void:
	if is_player_near:
		_update_prompt()

func _get_available_upgrades() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return list

	# 1. Carry Capacity Upgrade (Tas Bawaan)
	if gm.carry_level == 1:
		list.append({
			"id": "carry_2",
			"name": "Upgrade Tas (Kapasitas: 4)",
			"cost": 50,
			"desc": "Bawa 4 barang sekaligus"
		})
	elif gm.carry_level == 2:
		list.append({
			"id": "carry_3",
			"name": "Upgrade Tas (Kapasitas: 6)",
			"cost": 80,
			"desc": "Bawa 6 barang sekaligus"
		})

	# 2. Automated Cashier Helper (Hire / Upgrade Speed)
	if not gm.has_cashier_npc:
		list.append({
			"id": "hire_cashier",
			"name": "Hire Karyawan Kasir",
			"cost": 75,
			"desc": "Kasir otomatis (Gaji $15/hari)"
		})
	elif gm.cashier_speed_level == 1:
		list.append({
			"id": "cashier_speed_2",
			"name": "Pelatihan Kasir (Level 2)",
			"cost": 45,
			"desc": "Proses kasir lebih cepat"
		})
	elif gm.cashier_speed_level == 2:
		list.append({
			"id": "cashier_speed_3",
			"name": "Pelatihan Kasir (Level 3)",
			"cost": 70,
			"desc": "Proses kasir kilat"
		})

	# 3. Clerk Movement Speed Upgrade
	if gm.speed_level == 0:
		list.append({
			"id": "speed",
			"name": "Sepatu Kerja (+35% Lari)",
			"cost": 40,
			"desc": "Kecepatan jalan meningkat"
		})

	# 4. Gondola Shelf Expansion
	if gm.capacity_level == 0:
		list.append({
			"id": "gondola",
			"name": "Ekspansi Rak Gondola (Stok: 8)",
			"cost": 60,
			"desc": "Kapasitas rak menjadi 8"
		})

	return list

func _update_prompt() -> void:
	if not prompt_container or not prompt_label:
		return
	
	prompt_container.visible = is_player_near
	if not is_player_near:
		return

	var upgrades := _get_available_upgrades()
	if upgrades.is_empty():
		prompt_label.text = "[MAX] Semua Upgrade Toko Lengkap!"
		prompt_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
		return

	if selected_index >= upgrades.size():
		selected_index = 0

	var up: Dictionary = upgrades[selected_index]
	var cost: int = up.get("cost", 50)
	var uname: String = up.get("name", "Upgrade")
	var gm = get_node_or_null("/root/GameManager")
	var can_afford: bool = gm.can_afford(cost) if gm else true

	var cycle_hint := ""
	if upgrades.size() > 1:
		cycle_hint = " (1/" + str(upgrades.size()) + ")"

	if can_afford:
		prompt_label.text = "[E] Beli " + uname + " ($" + str(cost) + ")" + cycle_hint
		prompt_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
	else:
		prompt_label.text = uname + " ($" + str(cost) + ") [Uang Kurang]" + cycle_hint
		prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.45, 0.45))

## Process upgrade purchase
func interact(player: CharacterBody2D) -> bool:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return false

	var upgrades := _get_available_upgrades()
	if upgrades.is_empty():
		_trigger_pop(0.95)
		return false

	if selected_index >= upgrades.size():
		selected_index = 0

	var up: Dictionary = upgrades[selected_index]
	var up_id: String = up.get("id", "")
	var cost: int = up.get("cost", 50)

	if not gm.can_afford(cost):
		var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
		AssetMgr.play_sfx("error")
		# If cannot afford current choice, cycle to next available upgrade
		if upgrades.size() > 1:
			selected_index = (selected_index + 1) % upgrades.size()
			_update_prompt()
		_trigger_pop(0.95)
		return false

	var success: bool = false
	match up_id:
		"carry_2", "carry_3":
			success = gm.buy_carry_capacity_upgrade()
			if success:
				_spawn_floating_text("Kapasitas Tas Naik (" + str(gm.get_carry_capacity()) + ")!")
		"hire_cashier":
			success = gm.hire_cashier_npc()
			if success:
				_spawn_floating_text("Karyawan Kasir Direkrut!")
		"cashier_speed_2", "cashier_speed_3":
			success = gm.upgrade_cashier_speed()
			if success:
				_spawn_floating_text("Kecepatan Kasir Naik (Lvl " + str(gm.cashier_speed_level) + ")!")
		"speed":
			success = gm.buy_speed_upgrade()
			if success:
				player.move_speed = 285.0
				_spawn_floating_text("Kecepatan Lari Naik (+35%)!")
		"gondola":
			success = gm.buy_capacity_upgrade()
			if success:
				_apply_shelf_capacity_upgrade()
				_spawn_floating_text("Kapasitas Gondola Naik (8)!")

	if success:
		_trigger_pop(1.15)
		_update_prompt()
		queue_redraw()
		return true

	_trigger_pop(0.95)
	return false

func _apply_shelf_capacity_upgrade() -> void:
	for s in get_tree().get_nodes_in_group("shelves"):
		s.set("max_stock", 8)
		if s.has_method("_update_prompt"):
			s._update_prompt()
		s.queue_redraw()

	var root_node := get_tree().root
	var shelves := root_node.find_children("Shelf*", "", true, false)
	for s in shelves:
		if "max_stock" in s:
			s.set("max_stock", 8)
			if s.has_method("_update_prompt"):
				s._update_prompt()
			s.queue_redraw()

func _trigger_pop(target_scale: float = 1.1) -> void:
	var tween := create_tween()
	pop_scale = target_scale
	tween.tween_property(self, "pop_scale", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_redraw)

func _spawn_floating_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
	float_label.set("theme_override_font_sizes/font_size", 16)
	float_label.position = Vector2(-70, -48)
	add_child(float_label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(float_label, "position:y", -76.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.85).set_delay(0.25)
	tween.chain().tween_callback(float_label.queue_free)

func _draw() -> void:
	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop_scale, pop_scale))

	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var kiosk_tex: Texture2D = AssetMgr.get_texture("upgrade_station")
	if kiosk_tex != null:
		draw_texture_rect(kiosk_tex, Rect2(-38, -28, 76, 52), false)
	else:
		# 1. Floor Shadow
		var shadow_rect := Rect2(-34, 10, 68, 14)
		draw_rect(shadow_rect, Color(0.08, 0.10, 0.14, 0.22), true)

		# 2. Modern Management Desk / Kiosk Body
		draw_rect(Rect2(-32, 12, 64, 5), Color(0.22, 0.25, 0.30), true)
		draw_rect(Rect2(-30, -16, 60, 28), Color(0.88, 0.90, 0.94), true)
		draw_rect(Rect2(-34, -20, 68, 7), Color(0.25, 0.28, 0.35), true)

		# 3. Operations Tablet / Dashboard Display Screen
		var tablet_rect := Rect2(-24, -21, 28, 18)
		draw_rect(tablet_rect, Color(0.12, 0.14, 0.18), true)
		draw_rect(tablet_rect, Color(0.35, 0.40, 0.48), false, 1.0)

		var screen_rect := Rect2(-22, -19, 24, 14)
		draw_rect(screen_rect, Color(0.15, 0.45, 0.75), true)
		draw_rect(Rect2(-19, -9, 3, 3), Color(0.40, 0.85, 0.55), true)
		draw_rect(Rect2(-14, -13, 3, 7), Color(0.40, 0.85, 0.55), true)
		draw_rect(Rect2(-9, -16, 3, 10), Color(0.98, 0.85, 0.35), true)

		# 4. Service Indicator Cog Emblem
		var gear_center := Vector2(16, -11)
		draw_circle(gear_center, 6.5, Color(0.12, 0.44, 0.84))
		draw_circle(gear_center, 4.0, Color(0.95, 0.96, 0.98))
		for i in range(4):
			var angle := i * PI * 0.25
			draw_line(gear_center + Vector2(cos(angle), sin(angle)) * 3.5, gear_center + Vector2(cos(angle), sin(angle)) * 7.5, Color(0.12, 0.44, 0.84), 2.0)

	# 5. Selection Glow
	if is_player_near:
		draw_rect(Rect2(-36, -24, 72, 44), Color(0.98, 0.82, 0.35, 0.85), false, 2.0)

	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
