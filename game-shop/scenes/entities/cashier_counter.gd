extends StaticBody2D
class_name CashierCounter

## Modern Minimarket - POS Checkout Counter Entity with Automated Cashier NPC
## Modern laminate checkout counter, touch POS register, barcode scanner, EDC terminal, and Cashier Helper automation.

const ItemData = preload("res://scripts/components/item_data.gd")

var queue: Array[Node2D] = []

const QUEUE_SLOT_OFFSET := Vector2(0.0, -56.0)
const QUEUE_SPACING := 48.0

var is_player_near: bool = false
var player_ref: CharacterBody2D = null

var register_pop: float = 1.0
var screen_flash: float = 0.0

# Cashier NPC Automation
var has_cashier_npc: bool = false
var cashier_speed_level: int = 1
var auto_scan_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $CashierInteractionArea
@onready var prompt_container: PanelContainer = $PromptAnchor/PromptContainer
@onready var prompt_label: Label = $PromptAnchor/PromptContainer/PromptLabel

func _ready() -> void:
	if prompt_container:
		prompt_container.visible = false

	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		has_cashier_npc = gm.has_cashier_npc
		cashier_speed_level = gm.cashier_speed_level
		gm.cashier_hired_changed.connect(_on_cashier_hired_changed)

	queue_redraw()

func _on_cashier_hired_changed(hired: bool, speed_lvl: int) -> void:
	has_cashier_npc = hired
	cashier_speed_level = speed_lvl
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		is_player_near = true
		player_ref = body
		if body.has_method("set_active_cashier"):
			body.set_active_cashier(self)
		_update_prompt()
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_near = false
		if player_ref and player_ref.has_method("clear_active_cashier"):
			player_ref.clear_active_cashier(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false
		queue_redraw()

func _process(delta: float) -> void:
	if is_player_near:
		_update_prompt()

	# Process Automated Cashier Helper logic
	if has_cashier_npc and not queue.is_empty():
		_process_cashier_npc(delta)
	else:
		auto_scan_timer = 0.0

func _process_cashier_npc(delta: float) -> void:
	var front_customer = queue[0]
	if not front_customer or not is_instance_valid(front_customer):
		queue.remove_at(0)
		_notify_queue_shift()
		auto_scan_timer = 0.0
		return

	# Only scan when front customer has arrived and is actively queueing
	if front_customer.get("current_state") == 5: # QUEUEING state
		var gm = get_node_or_null("/root/GameManager")
		var target_duration: float = gm.get_cashier_process_duration() if gm else 2.0

		auto_scan_timer += delta
		queue_redraw()

		if auto_scan_timer >= target_duration:
			auto_scan_timer = 0.0
			serve_next_customer()
	else:
		auto_scan_timer = 0.0

func _update_prompt() -> void:
	if not prompt_container or not prompt_label:
		return

	prompt_container.visible = is_player_near
	if not is_player_near:
		return

	if queue.is_empty():
		if has_cashier_npc:
			prompt_label.text = "Karyawan Kasir Siaga (Otomatis)"
			prompt_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
		else:
			prompt_label.text = "Belum Ada Pembeli di Kasir"
			prompt_label.set("theme_override_colors/font_color", Color(0.75, 0.78, 0.84))
	else:
		var front_customer = queue[0]
		if front_customer and is_instance_valid(front_customer):
			if front_customer.get("current_state") == 5: # QUEUEING state
				var held: Dictionary = front_customer.get("held_item")
				var base_price: int = held.get("price", 10)
				var item_name: String = held.get("name", "Barang")
				var cust_type: int = front_customer.get("customer_type")
				
				var final_price := base_price
				var type_prefix := "Layani Kasir"
				if cust_type == 2: # VIP
					final_price = base_price * 2
					type_prefix = "Layani VIP"
				elif cust_type == 1: # IMPATIENT
					var p_ratio: float = front_customer.current_patience / front_customer.max_patience
					if p_ratio > 0.5:
						final_price = int(base_price * 1.25)
						type_prefix = "Layani Cepat"

				if has_cashier_npc:
					prompt_label.text = "[E] Bantu Karyawan: " + item_name + " (+$" + str(final_price) + ")"
				else:
					prompt_label.text = "[E] " + type_prefix + ": " + item_name + " (+$" + str(final_price) + ")"
				prompt_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
			else:
				prompt_label.text = "Pembeli Sedang Menuju Kasir..."
				prompt_label.set("theme_override_colors/font_color", Color(0.85, 0.88, 0.92))

func serve_next_customer() -> bool:
	if queue.is_empty():
		_trigger_pop(0.96)
		return false

	var front_customer = queue[0]
	if not front_customer or not is_instance_valid(front_customer):
		queue.remove_at(0)
		_notify_queue_shift()
		return false

	if front_customer.get("current_state") != 5:
		_trigger_pop(0.96)
		return false

	var held: Dictionary = front_customer.get("held_item")
	var base_price: int = held.get("price", 10)
	var cust_type: int = front_customer.get("customer_type")

	var final_price := base_price
	if cust_type == 2: # VIP
		final_price = base_price * 2
	elif cust_type == 1: # IMPATIENT
		var p_ratio: float = front_customer.current_patience / front_customer.max_patience
		if p_ratio > 0.5:
			final_price = int(base_price * 1.25)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.record_checkout(final_price)
		if cust_type == 2 and gm.has_method("add_reputation_bonus"):
			gm.add_reputation_bonus(0.2)

	leave_queue(front_customer)
	if front_customer.has_method("complete_checkout"):
		front_customer.complete_checkout()

	_trigger_pop(1.10)
	_flash_screen()
	_spawn_floating_cash_text("+$" + str(final_price))

	_update_prompt()
	queue_redraw()
	return true

func _trigger_pop(target_scale: float = 1.1) -> void:
	var tween := create_tween()
	register_pop = target_scale
	tween.tween_property(self, "register_pop", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_redraw)

func _flash_screen() -> void:
	var tween := create_tween()
	screen_flash = 1.0
	tween.tween_property(self, "screen_flash", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_redraw)

func _spawn_floating_cash_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.set("theme_override_colors/font_color", Color(0.42, 0.95, 0.55))
	float_label.set("theme_override_font_sizes/font_size", 16)
	float_label.position = Vector2(-24, -48)
	add_child(float_label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(float_label, "position:y", -78.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.85).set_delay(0.2)
	tween.chain().tween_callback(float_label.queue_free)

func join_queue(customer: Node2D) -> Vector2:
	if not queue.has(customer):
		queue.append(customer)
	_update_prompt()
	return get_customer_queue_pos(customer)

func leave_queue(customer: Node2D) -> void:
	if queue.has(customer):
		queue.erase(customer)
		_notify_queue_shift()
	_update_prompt()

func get_customer_queue_pos(customer: Node2D) -> Vector2:
	var index := queue.find(customer)
	if index == -1:
		index = queue.size()
	return global_position + QUEUE_SLOT_OFFSET + Vector2(0.0, -float(index) * QUEUE_SPACING)

func _notify_queue_shift() -> void:
	for i in range(queue.size()):
		var cust = queue[i]
		if cust and is_instance_valid(cust) and cust.has_method("update_queue_destination"):
			cust.update_queue_destination(get_customer_queue_pos(cust))

func _draw() -> void:
	if register_pop != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(register_pop, register_pop))

	# 1. Floor Shadow
	var shadow_rect := Rect2(-40, 10, 80, 14)
	draw_rect(shadow_rect, Color(0.08, 0.10, 0.14, 0.24), true)

	# 2. Automated Cashier Helper NPC (Stands behind counter when hired)
	if has_cashier_npc:
		_draw_cashier_npc()

	# 3. Modern Laminate Counter Body
	draw_rect(Rect2(-38, 12, 76, 5), Color(0.22, 0.25, 0.30), true)
	draw_rect(Rect2(-36, -18, 72, 30), Color(0.90, 0.92, 0.95), true)
	draw_rect(Rect2(-36, -6, 72, 3), Color(0.12, 0.44, 0.84), true)
	draw_rect(Rect2(-36, -3, 72, 1.5), Color(0.95, 0.54, 0.18), true)

	draw_rect(Rect2(-38, -22, 76, 8), Color(0.24, 0.28, 0.34), true)
	draw_line(Vector2(-38, -22), Vector2(38, -22), Color(0.40, 0.45, 0.52), 1.2)

	# 4. Touchscreen POS Register Terminal
	var reg_pos := Vector2(-8, -22)
	draw_rect(Rect2(reg_pos.x - 3, reg_pos.y - 4, 6, 4), Color(0.15, 0.17, 0.20), true)
	draw_rect(Rect2(reg_pos.x - 14, reg_pos.y - 22, 28, 18), Color(0.12, 0.14, 0.18), true)
	draw_rect(Rect2(reg_pos.x - 14, reg_pos.y - 22, 28, 18), Color(0.30, 0.34, 0.42), false, 1.0)

	var screen_col := Color(0.15, 0.55, 0.85).lerp(Color(0.98, 0.92, 0.45), screen_flash)
	draw_rect(Rect2(reg_pos.x - 12, reg_pos.y - 20, 24, 14), screen_col, true)

	draw_line(Vector2(reg_pos.x - 10, reg_pos.y - 17), Vector2(reg_pos.x + 4, reg_pos.y - 17), Color.WHITE, 1.0)
	draw_line(Vector2(reg_pos.x - 10, reg_pos.y - 14), Vector2(reg_pos.x + 2, reg_pos.y - 14), Color.WHITE, 1.0)
	draw_line(Vector2(reg_pos.x - 10, reg_pos.y - 10), Vector2(reg_pos.x + 8, reg_pos.y - 10), Color(0.98, 0.85, 0.35), 1.2)

	# 5. Barcode Flatbed Scanner
	var scanner_rect := Rect2(reg_pos.x + 16, reg_pos.y - 3, 14, 8)
	draw_rect(scanner_rect, Color(0.16, 0.18, 0.22), true)
	draw_rect(scanner_rect, Color(0.4, 0.45, 0.5), false, 1.0)
	draw_line(Vector2(scanner_rect.position.x + 2, scanner_rect.position.y + 4), Vector2(scanner_rect.position.x + 12, scanner_rect.position.y + 4), Color(1.0, 0.20, 0.20), 1.5)

	# Automated Scanning Beam Effect
	if auto_scan_timer > 0.0:
		var sweep := sin(auto_scan_timer * 12.0) * 4.0
		draw_line(Vector2(scanner_rect.position.x + 2, scanner_rect.position.y + 4 + sweep), Vector2(scanner_rect.position.x + 12, scanner_rect.position.y + 4 + sweep), Color(1.0, 0.95, 0.30), 1.5)

	# 6. EDC Terminal
	var edc_pos := Vector2(reg_pos.x - 26, reg_pos.y - 10)
	draw_rect(Rect2(edc_pos.x - 4, edc_pos.y - 6, 8, 12), Color(0.18, 0.20, 0.24), true)
	draw_rect(Rect2(edc_pos.x - 3, edc_pos.y - 5, 6, 4), Color(0.35, 0.75, 0.45), true)
	draw_circle(Vector2(edc_pos.x, edc_pos.y + 2), 1.0, Color.WHITE)

	# 7. Paper Slot
	draw_line(Vector2(reg_pos.x - 12, reg_pos.y - 3), Vector2(reg_pos.x - 6, reg_pos.y - 3), Color(0.95, 0.95, 0.95), 1.5)

	# 8. Queue Marker
	var queue_marker_pos := QUEUE_SLOT_OFFSET
	draw_rect(Rect2(queue_marker_pos.x - 14, queue_marker_pos.y - 6, 28, 12), Color(0.12, 0.44, 0.84, 0.22), true)
	draw_rect(Rect2(queue_marker_pos.x - 14, queue_marker_pos.y - 6, 28, 12), Color(0.12, 0.44, 0.84, 0.80), false, 1.2)
	var chevron := PackedVector2Array([
		queue_marker_pos + Vector2(-6, 2),
		queue_marker_pos + Vector2(0, -3),
		queue_marker_pos + Vector2(6, 2)
	])
	draw_polyline(chevron, Color(0.98, 0.85, 0.35), 1.8)

	# 9. Selection Glow
	if is_player_near:
		draw_rect(Rect2(-40, -24, 80, 44), Color(0.98, 0.82, 0.35, 0.85), false, 2.0)

	if register_pop != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_cashier_npc() -> void:
	var npc_pos := Vector2(16.0, -28.0)

	# Torso & Apron
	draw_rect(Rect2(npc_pos.x - 8, npc_pos.y, 16, 12), Color(0.12, 0.44, 0.84), true) # Polo shirt
	draw_rect(Rect2(npc_pos.x - 6, npc_pos.y + 2, 12, 10), Color(0.22, 0.25, 0.32), true) # Apron
	draw_line(Vector2(npc_pos.x - 6, npc_pos.y + 10), Vector2(npc_pos.x + 6, npc_pos.y + 10), Color(0.95, 0.54, 0.18), 1.5)

	# Head & Hair
	var head_pos := npc_pos + Vector2(0.0, -8.0)
	draw_circle(head_pos, 8.5, Color(0.22, 0.16, 0.14)) # Hair
	draw_circle(head_pos + Vector2(0, 1), 7.2, Color(0.98, 0.86, 0.74)) # Skin

	# Visor
	draw_rect(Rect2(head_pos.x - 7, head_pos.y - 5, 14, 4), Color(0.12, 0.44, 0.84), true)
	draw_line(Vector2(head_pos.x - 8, head_pos.y - 1), Vector2(head_pos.x + 8, head_pos.y - 1), Color(0.95, 0.54, 0.18), 1.2)

	# Eyes
	draw_circle(head_pos + Vector2(-2.5, 1.5), 1.2, Color(0.12, 0.14, 0.18))
	draw_circle(head_pos + Vector2(2.5, 1.5), 1.2, Color(0.12, 0.14, 0.18))

	# Automated Scanning Progress Bar above NPC
	if auto_scan_timer > 0.0:
		var gm = get_node_or_null("/root/GameManager")
		var target_duration: float = gm.get_cashier_process_duration() if gm else 2.0
		var progress: float = clampf(auto_scan_timer / target_duration, 0.0, 1.0)
		
		var bar_w := 24.0
		var bar_h := 3.5
		var bar_rect := Rect2(npc_pos.x - bar_w * 0.5, npc_pos.y - 24.0, bar_w, bar_h)
		draw_rect(Rect2(bar_rect.position.x - 1, bar_rect.position.y - 1, bar_w + 2, bar_h + 2), Color(0.10, 0.12, 0.16, 0.85), true)
		draw_rect(bar_rect, Color(0.20, 0.22, 0.26), true)
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, bar_w * progress, bar_h), Color(0.40, 0.95, 0.55), true)
