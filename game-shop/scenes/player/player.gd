extends CharacterBody2D
class_name Player

## Modern Minimarket - Player Store Clerk Controller
## Humanized clerk proportions, multi-item carry capacity system, overhead inventory indicators, and interactions.

const ItemData = preload("res://scripts/components/item_data.gd")

@export var move_speed: float = 210.0
@export var acceleration: float = 1400.0
@export var friction: float = 1200.0

var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var walk_anim_timer: float = 0.0

# Multi-Item Carry Inventory System
var held_items: Array[Dictionary] = []
var max_carry_capacity: int = 2

# Backward-compatibility accessor
var held_item: Dictionary:
	get:
		return held_items[0] if not held_items.is_empty() else {}

# Proximity Interaction Targets
var active_shelf: Node = null
var active_cashier: Node2D = null
var active_restock: Node2D = null
var active_upgrade: Node2D = null
var active_trash: Node2D = null
var active_door: Node2D = null

# Humanized Clerk Procedural Palette
const COLOR_SHADOW := Color(0.08, 0.10, 0.14, 0.28)
const COLOR_PANTS := Color(0.18, 0.22, 0.28)                # Dark navy work slacks
const COLOR_SHOES := Color(0.12, 0.14, 0.17)                # Black non-slip work shoes
const COLOR_SHIRT := Color(0.12, 0.44, 0.84)                # Convenience store blue polo
const COLOR_COLLAR := Color(0.95, 0.96, 0.98)               # Clean white polo collar
const COLOR_APRON := Color(0.22, 0.25, 0.32)                # Professional dark apron
const COLOR_APRON_TRIM := Color(0.95, 0.54, 0.18)           # Orange corporate accent strip
const COLOR_ID_BADGE := Color(0.95, 0.95, 0.98)             # Employee badge card
const COLOR_SKIN := Color(0.98, 0.86, 0.74)                 # Human skin tone
const COLOR_HAIR := Color(0.24, 0.18, 0.14)                 # Dark styled hair
const COLOR_CAP := Color(0.12, 0.44, 0.84)                  # Clerk uniform visor/cap
const COLOR_EYE := Color(0.14, 0.15, 0.18)
const COLOR_INDICATOR := Color(0.12, 0.44, 0.84, 0.75)
const COLOR_HOLD_GLOW := Color(1.0, 1.0, 1.0, 0.35)

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		max_carry_capacity = gm.get_carry_capacity()
		gm.carry_capacity_changed.connect(_on_carry_capacity_changed)
	queue_redraw()

func _on_carry_capacity_changed(new_capacity: int) -> void:
	max_carry_capacity = new_capacity
	queue_redraw()

# Target registration
func set_active_shelf(shelf: Node) -> void:
	active_shelf = shelf

func clear_active_shelf(shelf: Node) -> void:
	if active_shelf == shelf:
		active_shelf = null

func set_active_cashier(cashier: Node2D) -> void:
	active_cashier = cashier

func clear_active_cashier(cashier: Node2D) -> void:
	if active_cashier == cashier:
		active_cashier = null

func set_active_restock(crate: Node2D) -> void:
	active_restock = crate

func clear_active_restock(crate: Node2D) -> void:
	if active_restock == crate:
		active_restock = null

func set_active_upgrade(station: Node2D) -> void:
	active_upgrade = station

func clear_active_upgrade(station: Node2D) -> void:
	if active_upgrade == station:
		active_upgrade = null

func set_active_trash(trash: Node2D) -> void:
	active_trash = trash

func clear_active_trash(trash: Node2D) -> void:
	if active_trash == trash:
		active_trash = null

func set_active_door(door: Node2D) -> void:
	active_door = door

func clear_active_door(door: Node2D) -> void:
	if active_door == door:
		active_door = null

# Carry Inventory Methods
func can_pick_up() -> bool:
	return held_items.size() < max_carry_capacity

func is_carrying_full() -> bool:
	return held_items.size() >= max_carry_capacity

func pick_up_item(item: Dictionary) -> bool:
	if can_pick_up():
		held_items.append(item)
		queue_redraw()
		return true
	return false

func has_item(item_type: String) -> bool:
	for it in held_items:
		if it.get("id") == item_type:
			return true
	return false

func pop_item(item_type: String) -> Dictionary:
	for i in range(held_items.size() - 1, -1, -1):
		if held_items[i].get("id") == item_type:
			var popped = held_items[i]
			held_items.remove_at(i)
			queue_redraw()
			return popped
	return {}

func clear_held_item() -> void:
	if not held_items.is_empty():
		held_items.pop_back()
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var triggered: bool = false
	if event.is_action_pressed("interact"):
		triggered = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			triggered = true

	if triggered:
		# 1. Door / Open Store Trigger during PRE_OPEN
		if active_door != null and active_door.has_method("open_store"):
			var opened: bool = active_door.open_store()
			if opened:
				get_viewport().set_input_as_handled()
				return

		# 2. Floor Trash Cleaning
		if active_trash != null and active_trash.has_method("clean_up"):
			active_trash.clean_up()
			get_viewport().set_input_as_handled()
			return

		# 3. Cashier Serving (Manual Override)
		if active_cashier != null and active_cashier.has_method("serve_next_customer"):
			var handled: bool = active_cashier.serve_next_customer()
			if handled:
				get_viewport().set_input_as_handled()
				return
		
		# 4. Upgrade Kiosk Interaction
		if active_upgrade != null and active_upgrade.has_method("interact"):
			var handled: bool = active_upgrade.interact(self)
			if handled:
				get_viewport().set_input_as_handled()
				return

		# 5. Restock Purchasing
		if active_restock != null and active_restock.has_method("interact"):
			var handled: bool = active_restock.interact(self)
			if handled:
				get_viewport().set_input_as_handled()
				return

		# 6. Shelf Interaction (Deposit/Take)
		if active_shelf != null and active_shelf.has_method("interact"):
			active_shelf.interact(self)
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") and \
	   InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
		input_vector = input_vector.normalized()

	is_moving = input_vector.length_squared() > 0.01
	if is_moving:
		facing_direction = input_vector.normalized()
		walk_anim_timer += delta * 12.0
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
	else:
		walk_anim_timer = 0.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var walk_cycle: float = sin(walk_anim_timer) if is_moving else 0.0
	var bob_offset: float = absf(walk_cycle) * 2.0
	var char_center := Vector2(0.0, -8.0 + bob_offset)

	# 1. Soft Ground Drop Shadow
	var shadow_points := PackedVector2Array()
	const SHADOW_SEGMENTS := 14
	for i in range(SHADOW_SEGMENTS):
		var angle := i * TAU / SHADOW_SEGMENTS
		shadow_points.append(Vector2(cos(angle) * 15.0, 8.0 + sin(angle) * 6.5))
	draw_colored_polygon(shadow_points, COLOR_SHADOW)

	# 2. Legs & Work Shoes
	var leg_swing := walk_cycle * 4.0
	var left_shoe := Vector2(-5.0, 7.0 - leg_swing)
	var right_shoe := Vector2(5.0, 7.0 + leg_swing)

	draw_rect(Rect2(-7, 1, 5, 7), COLOR_PANTS, true)
	draw_rect(Rect2(2, 1, 5, 7), COLOR_PANTS, true)
	draw_circle(left_shoe, 3.2, COLOR_SHOES)
	draw_circle(right_shoe, 3.2, COLOR_SHOES)

	# 3. Torso & Minimarket Polo Uniform
	var torso_pos := char_center + Vector2(0, 3)
	draw_rect(Rect2(-11, torso_pos.y - 8, 22, 16), COLOR_SHIRT, true)

	# Collar
	var collar_pts := PackedVector2Array([
		Vector2(-5, torso_pos.y - 8),
		Vector2(0, torso_pos.y - 3),
		Vector2(5, torso_pos.y - 8)
	])
	draw_polyline(collar_pts, COLOR_COLLAR, 1.8)

	# 4. Work Apron
	var apron_points := PackedVector2Array([
		char_center + Vector2(-8, -3),
		char_center + Vector2(8, -3),
		char_center + Vector2(9, 11),
		char_center + Vector2(-9, 11)
	])
	draw_colored_polygon(apron_points, COLOR_APRON)
	draw_line(char_center + Vector2(-8, 9), char_center + Vector2(8, 9), COLOR_APRON_TRIM, 1.8)

	# ID Badge
	draw_rect(Rect2(char_center.x + 2, char_center.y - 1, 5, 6), COLOR_ID_BADGE, true)
	draw_circle(Vector2(char_center.x + 4.5, char_center.y + 1.5), 1.0, COLOR_SHIRT)

	# 5. Head, Hair & Cap
	var head_pos := char_center + Vector2(0.0, -12.0)
	draw_rect(Rect2(-3, head_pos.y + 7, 6, 4), COLOR_SKIN, true)
	draw_circle(head_pos, 11.5, COLOR_HAIR)

	var face_center := head_pos + facing_direction * 2.0
	draw_circle(face_center, 9.5, COLOR_SKIN)

	# Styled modern hair bangs
	var hair_front := PackedVector2Array([
		head_pos + Vector2(-10, -6),
		head_pos + Vector2(10, -6),
		head_pos + Vector2(8, 0),
		head_pos + Vector2(-4, -1),
		head_pos + Vector2(-8, 1)
	])
	draw_colored_polygon(hair_front, COLOR_HAIR)

	# Minimarket Clerk Visor Cap
	var visor_front := head_pos + facing_direction * 2.5 + Vector2(0, -6)
	draw_rect(Rect2(visor_front.x - 9, visor_front.y - 3, 18, 5), COLOR_CAP, true)
	draw_line(Vector2(visor_front.x - 10, visor_front.y + 2), Vector2(visor_front.x + 10, visor_front.y + 2), COLOR_APRON_TRIM, 1.5)

	# 6. Eyes with Dynamic Focus
	if facing_direction.y > -0.65:
		var eye_offset := facing_direction * 3.5
		var eye_left := head_pos + eye_offset + Vector2(-3.5, 0.5)
		var eye_right := head_pos + eye_offset + Vector2(3.5, 0.5)

		draw_line(eye_left + Vector2(-1.5, -2.5), eye_left + Vector2(1.5, -2.5), COLOR_HAIR, 1.2)
		draw_line(eye_right + Vector2(-1.5, -2.5), eye_right + Vector2(1.5, -2.5), COLOR_HAIR, 1.2)

		draw_circle(eye_left, 1.8, COLOR_EYE)
		draw_circle(eye_right, 1.8, COLOR_EYE)
		draw_circle(eye_left + Vector2(0.5, -0.5), 0.6, Color.WHITE)
		draw_circle(eye_right + Vector2(0.5, -0.5), 0.6, Color.WHITE)

	# 7. Directional Indicator
	var interact_pos := char_center + facing_direction * 28.0
	draw_circle(interact_pos, 3.5, COLOR_INDICATOR)
	draw_arc(interact_pos, 5.5, 0.0, TAU, 16, COLOR_INDICATOR, 1.2)

	# 8. Multi-Item Carrying Visuals & Overhead Inventory Meter
	if not held_items.is_empty():
		var hold_hover := sin(walk_anim_timer * 1.5) * 1.5 if is_moving else 0.0
		var item_pos := char_center + Vector2(0.0, -28.0 + hold_hover)

		# Hands raised to hold items
		draw_circle(char_center + Vector2(-9, -13 + hold_hover * 0.5), 3.2, COLOR_SKIN)
		draw_circle(char_center + Vector2(9, -13 + hold_hover * 0.5), 3.2, COLOR_SKIN)

		# Ambient soft aura
		draw_circle(item_pos, 12.0, COLOR_HOLD_GLOW)
		draw_arc(item_pos, 13.0, 0.0, TAU, 16, Color(1, 1, 1, 0.5), 1.0)

		# Render primary top item
		var top_item: Dictionary = held_items[held_items.size() - 1]
		var item_id: String = top_item.get("id", "")
		ItemData.draw_procedural_item(self, item_pos, item_id, 1.15)

		# Overhead Carry Capacity Badge: [held / max]
		_draw_carry_capacity_badge(char_center + Vector2(0.0, -46.0))

func _draw_carry_capacity_badge(pos: Vector2) -> void:
	var count := held_items.size()
	var pill_w := 28.0
	var pill_h := 11.0
	var pill_rect := Rect2(pos.x - pill_w * 0.5, pos.y - pill_h * 0.5, pill_w, pill_h)

	# Pill background
	draw_rect(pill_rect, Color(0.10, 0.12, 0.16, 0.85), true)
	var border_col := Color(0.40, 0.95, 0.55) if count < max_carry_capacity else Color(0.98, 0.75, 0.35)
	draw_rect(pill_rect, border_col, false, 1.0)

	# Mini inventory item slots
	for i in range(max_carry_capacity):
		var slot_x := (pos.x - (float(max_carry_capacity - 1) * 3.5)) + float(i) * 7.0
		var dot_col := Color(0.35, 0.85, 0.45) if i < count else Color(0.35, 0.38, 0.45, 0.6)
		draw_circle(Vector2(slot_x, pos.y), 2.0, dot_col)
