extends CharacterBody2D
class_name Customer

## Modern Minimarket - Procedural Humanized Customer AI
## Finite State Machine with Customer Variations, Patience System, and Smooth Navigation.

const ItemData = preload("res://scripts/components/item_data.gd")
const TrashScene = preload("res://scenes/entities/Trash.tscn")

enum State {
	ENTERING,
	DECIDING,
	WALKING_TO_SHELF,
	BROWSING_SHELF,
	GOING_TO_CASHIER,
	QUEUEING,
	LEAVING
}

enum CustomerType {
	REGULAR,
	IMPATIENT,
	VIP
}

@export var customer_type: CustomerType = CustomerType.REGULAR
@export var move_speed: float = 130.0

var current_state: State = State.ENTERING
var wanted_item_type: String = "soda"
var held_item: Dictionary = {}
var target_shelf: Node2D = null
var cashier_counter: Node2D = null
var current_destination: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

# Patience Meter System
var max_patience: float = 30.0
var current_patience: float = 30.0
var is_near_bench: bool = false
var has_lost_patience: bool = false

# Movement & Animation
var facing_direction: Vector2 = Vector2.UP
var is_moving: bool = false
var walk_anim_timer: float = 0.0

# Procedural Appearance Colors
var shirt_color: Color
var hair_color: Color
var skin_color: Color
var pants_color: Color
var bubble_text_type: String = "item" # "item", "dots", "check", "empty", "queue", "angry"

# Navigation Waypoints
const LOBBY_POINT := Vector2(576, 440)
const DOOR_POINT := Vector2(576, 560)
const EXIT_POINT := Vector2(576, 615)

func _ready() -> void:
	add_to_group("customers")
	collision_layer = 4
	collision_mask = 1 # Only collides with static furniture/walls, never blocks other customers
	_setup_customer_type_attributes()
	current_destination = LOBBY_POINT
	current_state = State.ENTERING
	queue_redraw()

func _setup_customer_type_attributes() -> void:
	var roll := randf()
	if roll < 0.25:
		set_customer_type(CustomerType.IMPATIENT)
	elif roll < 0.40:
		set_customer_type(CustomerType.VIP)
	else:
		set_customer_type(CustomerType.REGULAR)

func set_customer_type(type: CustomerType) -> void:
	customer_type = type
	match customer_type:
		CustomerType.IMPATIENT:
			move_speed = 175.0
			max_patience = 15.0
		CustomerType.VIP:
			move_speed = 105.0
			max_patience = 42.0
		CustomerType.REGULAR:
			move_speed = 130.0
			max_patience = 30.0
	current_patience = max_patience
	_randomize_appearance()
	queue_redraw()

func _randomize_appearance() -> void:
	var hairs := [
		Color(0.22, 0.16, 0.14),
		Color(0.70, 0.50, 0.32),
		Color(0.55, 0.25, 0.18),
		Color(0.12, 0.12, 0.15)
	]
	var skins := [
		Color(0.98, 0.86, 0.74),
		Color(0.92, 0.78, 0.64),
		Color(0.80, 0.62, 0.48)
	]
	var pants := [
		Color(0.18, 0.22, 0.28),
		Color(0.24, 0.32, 0.42),
		Color(0.28, 0.26, 0.24),
		Color(0.14, 0.16, 0.20)
	]
	hair_color = hairs[randi() % hairs.size()]
	skin_color = skins[randi() % skins.size()]
	pants_color = pants[randi() % pants.size()]

	match customer_type:
		CustomerType.IMPATIENT:
			shirt_color = Color(0.90, 0.30, 0.26) # Fiery athletic coral
		CustomerType.VIP:
			shirt_color = Color(0.46, 0.26, 0.68) # Royal purple blazer
		CustomerType.REGULAR:
			var regular_shirts := [
				Color(0.25, 0.62, 0.54),
				Color(0.22, 0.45, 0.72),
				Color(0.86, 0.68, 0.32),
				Color(0.50, 0.64, 0.70)
			]
			shirt_color = regular_shirts[randi() % regular_shirts.size()]

func setup(shelves: Array, counter: Node2D) -> void:
	cashier_counter = counter
	if shelves.is_empty():
		wanted_item_type = "soda"
	else:
		var stocked_shelves := shelves.filter(func(s): return s.get("current_stock") > 0)
		if not stocked_shelves.is_empty():
			target_shelf = stocked_shelves[randi() % stocked_shelves.size()]
		else:
			target_shelf = shelves[randi() % shelves.size()]
		wanted_item_type = target_shelf.get("item_type")

func set_near_bench(near: bool) -> void:
	is_near_bench = near

func _physics_process(delta: float) -> void:
	state_timer += delta

	# Process patience depletion while waiting
	if current_state in [State.BROWSING_SHELF, State.GOING_TO_CASHIER, State.QUEUEING]:
		var decay_multiplier := 0.7 if is_near_bench else 1.0
		current_patience -= delta * decay_multiplier
		if current_patience <= 0.0 and not has_lost_patience:
			_handle_patience_depleted()

	match current_state:
		State.ENTERING:
			_move_towards_destination(delta)
			if _has_reached_destination():
				_transition_to(State.DECIDING)

		State.DECIDING:
			bubble_text_type = "item"
			if state_timer >= 0.5:
				if target_shelf and is_instance_valid(target_shelf):
					current_destination = target_shelf.global_position + Vector2(0.0, 36.0)
					_transition_to(State.WALKING_TO_SHELF)
				else:
					_transition_to(State.LEAVING)

		State.WALKING_TO_SHELF:
			_move_towards_destination(delta)
			if _has_reached_destination():
				facing_direction = Vector2.UP
				_transition_to(State.BROWSING_SHELF)

		State.BROWSING_SHELF:
			bubble_text_type = "dots"
			var browse_time: float = 0.8 if customer_type == CustomerType.IMPATIENT else 1.2
			if state_timer >= browse_time:
				_evaluate_shelf_interaction()

		State.GOING_TO_CASHIER:
			_move_towards_destination(delta)
			if _has_reached_destination():
				facing_direction = Vector2.DOWN
				_transition_to(State.QUEUEING)

		State.QUEUEING:
			bubble_text_type = "queue"
			velocity = Vector2.ZERO
			is_moving = false

		State.LEAVING:
			_move_towards_destination(delta)
			if global_position.y >= 590.0 or state_timer >= 6.0:
				_finalize_despawn()
			elif _has_reached_destination():
				if current_destination == LOBBY_POINT:
					current_destination = EXIT_POINT
				else:
					_finalize_despawn()

	queue_redraw()

func _handle_patience_depleted() -> void:
	has_lost_patience = true
	bubble_text_type = "angry"
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	AssetMgr.play_sfx("customer_angry")
	
	if cashier_counter and cashier_counter.has_method("leave_queue"):
		cashier_counter.leave_queue(self)

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("record_unsatisfied_customer"):
		gm.record_unsatisfied_customer()

	current_destination = LOBBY_POINT
	_transition_to(State.LEAVING)

func _finalize_despawn() -> void:
	if cashier_counter and cashier_counter.has_method("leave_queue"):
		cashier_counter.leave_queue(self)

	# 25% chance to drop modern convenience litter upon exit
	if randf() < 0.25:
		_drop_trash()

	queue_free()

func _drop_trash() -> void:
	var trash = TrashScene.instantiate()
	trash.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-8, 8))
	var parent_node := get_parent()
	if parent_node:
		parent_node.add_child(trash)

func _evaluate_shelf_interaction() -> void:
	if not target_shelf or not is_instance_valid(target_shelf):
		_leave_dissatisfied()
		return

	var stock: int = target_shelf.get("current_stock")
	if stock > 0:
		target_shelf.set("current_stock", stock - 1)
		held_item = ItemData.get_item(wanted_item_type)
		if target_shelf.has_method("_trigger_pop"):
			target_shelf._trigger_pop()
		if target_shelf.has_method("_update_prompt"):
			target_shelf._update_prompt()
		target_shelf.queue_redraw()

		bubble_text_type = "check"

		if cashier_counter and cashier_counter.has_method("join_queue"):
			current_destination = cashier_counter.join_queue(self)
			_transition_to(State.GOING_TO_CASHIER)
		else:
			_transition_to(State.LEAVING)
	else:
		_leave_dissatisfied()

func _leave_dissatisfied() -> void:
	bubble_text_type = "empty"
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("record_unsatisfied_customer"):
		gm.record_unsatisfied_customer()

	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		current_destination = LOBBY_POINT
		_transition_to(State.LEAVING)
	)

func _move_towards_destination(delta: float) -> void:
	var diff := current_destination - global_position
	if diff.length() > 6.0:
		facing_direction = diff.normalized()
		walk_anim_timer += delta * (14.0 if customer_type == CustomerType.IMPATIENT else 10.0)
		velocity = facing_direction * move_speed
		is_moving = true
		if is_inside_tree() and get_world_2d() and get_world_2d().space.is_valid():
			move_and_slide()
		else:
			global_position += velocity * delta
	else:
		velocity = Vector2.ZERO
		is_moving = false

func _has_reached_destination() -> bool:
	return global_position.distance_to(current_destination) <= 10.0

func _transition_to(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0

func update_queue_destination(new_pos: Vector2) -> void:
	current_destination = new_pos
	if current_state == State.QUEUEING or current_state == State.GOING_TO_CASHIER:
		if global_position.distance_to(new_pos) > 8.0:
			_transition_to(State.GOING_TO_CASHIER)

func complete_checkout() -> void:
	if cashier_counter and cashier_counter.has_method("leave_queue"):
		cashier_counter.leave_queue(self)
	bubble_text_type = "check"
	current_destination = LOBBY_POINT
	_transition_to(State.LEAVING)

func _draw() -> void:
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var walk_cycle: float = sin(walk_anim_timer) if is_moving else 0.0
	var bob_offset: float = absf(walk_cycle) * 1.8
	var char_center := Vector2(0.0, -8.0 + bob_offset)

	# 1. Ground Drop Shadow
	var shadow_points := PackedVector2Array()
	const SHADOW_SEGMENTS := 12
	for i in range(SHADOW_SEGMENTS):
		var angle := i * TAU / SHADOW_SEGMENTS
		shadow_points.append(Vector2(cos(angle) * 14.0, 7.5 + sin(angle) * 6.0))
	draw_colored_polygon(shadow_points, Color(0.08, 0.10, 0.14, 0.25))

	# VIP Golden Aura
	if customer_type == CustomerType.VIP:
		draw_circle(char_center + Vector2(0, 2), 18.0, Color(0.95, 0.82, 0.35, 0.22))
		draw_arc(char_center + Vector2(0, 2), 18.0, 0.0, TAU, 16, Color(0.95, 0.82, 0.35, 0.55), 1.2)

	# 2. Legs & Shoes
	var leg_swing := walk_cycle * 3.5
	var left_shoe := Vector2(-4.5, 7.0 - leg_swing)
	var right_shoe := Vector2(4.5, 7.0 + leg_swing)

	draw_rect(Rect2(-6, 1, 4.5, 6), pants_color, true)
	draw_rect(Rect2(1.5, 1, 4.5, 6), pants_color, true)
	draw_circle(left_shoe, 2.8, Color(0.15, 0.16, 0.18))
	draw_circle(right_shoe, 2.8, Color(0.15, 0.16, 0.18))

	# 3. Customer Sprite Asset Base + Randomized Appearance Layer
	var cust_tex_key := "customer_regular"
	if customer_type == CustomerType.IMPATIENT:
		cust_tex_key = "customer_impatient"
	elif customer_type == CustomerType.VIP:
		cust_tex_key = "customer_vip"
	var cust_tex: Texture2D = AssetMgr.get_texture(cust_tex_key)
	if cust_tex != null:
		var mod_col := shirt_color if customer_type == CustomerType.REGULAR else Color.WHITE
		draw_texture_rect(cust_tex, Rect2(-20.0, char_center.y - 24.0, 40.0, 42.0), false, mod_col)

	var torso_rect := Rect2(-10, char_center.y - 4, 20, 14)
	draw_rect(torso_rect, shirt_color, true)

	# Clothing Details
	if customer_type == CustomerType.VIP:
		# Tailored lapel and gold brooch
		draw_line(Vector2(-4, char_center.y - 4), Vector2(0, char_center.y + 3), Color(0.95, 0.95, 0.98), 1.5)
		draw_line(Vector2(4, char_center.y - 4), Vector2(0, char_center.y + 3), Color(0.95, 0.95, 0.98), 1.5)
		draw_circle(Vector2(-4, char_center.y + 1), 1.5, Color(0.98, 0.85, 0.35))
	elif customer_type == CustomerType.IMPATIENT:
		# Athletic dual racing stripes
		draw_line(Vector2(-10, char_center.y + 2), Vector2(10, char_center.y + 2), Color.WHITE, 1.2)
		draw_line(Vector2(-10, char_center.y + 5), Vector2(10, char_center.y + 5), Color.WHITE, 1.2)
	else:
		# Casual collar line
		draw_line(Vector2(-4, char_center.y - 4), Vector2(0, char_center.y), Color(1, 1, 1, 0.6), 1.2)
		draw_line(Vector2(4, char_center.y - 4), Vector2(0, char_center.y), Color(1, 1, 1, 0.6), 1.2)

	# 4. Head & Face
	var head_pos := char_center + Vector2(0.0, -11.0)
	draw_circle(head_pos, 11.0, hair_color)

	var face_pos := head_pos + facing_direction * 2.0
	draw_circle(face_pos, 9.2, skin_color)

	# Modern styled bangs
	var bangs := PackedVector2Array([
		head_pos + Vector2(-9, -6),
		head_pos + Vector2(9, -6),
		head_pos + Vector2(7, 0),
		head_pos + Vector2(-7, 0)
	])
	draw_colored_polygon(bangs, hair_color)

	# Impatient Red Athletic Headband
	if customer_type == CustomerType.IMPATIENT:
		draw_line(head_pos + Vector2(-9, -4), head_pos + Vector2(9, -4), Color(0.95, 0.20, 0.20), 2.4)

	# VIP Golden Crown Accent
	if customer_type == CustomerType.VIP:
		var crown_pts := PackedVector2Array([
			head_pos + Vector2(-6, -11),
			head_pos + Vector2(-3, -15),
			head_pos + Vector2(0, -12),
			head_pos + Vector2(3, -15),
			head_pos + Vector2(6, -11)
		])
		draw_polyline(crown_pts, Color(0.98, 0.85, 0.35), 2.0)

	# 5. Eyes with Emotion Expression
	if facing_direction.y > -0.65:
		var eye_offset := facing_direction * 3.2
		var eye_l := head_pos + eye_offset + Vector2(-3.2, 0.5)
		var eye_r := head_pos + eye_offset + Vector2(3.2, 0.5)

		# Eyebrows based on patience status
		var brow_slant: float = 0.0
		if current_patience < max_patience * 0.3 or has_lost_patience:
			brow_slant = 1.8 # Angled inward when angry

		draw_line(eye_l + Vector2(-1.5, -2.5 + brow_slant), eye_l + Vector2(1.5, -2.5), hair_color, 1.2)
		draw_line(eye_r + Vector2(-1.5, -2.5), eye_r + Vector2(1.5, -2.5 + brow_slant), hair_color, 1.2)

		draw_circle(eye_l, 1.6, Color(0.12, 0.12, 0.16))
		draw_circle(eye_r, 1.6, Color(0.12, 0.12, 0.16))
		draw_circle(eye_l + Vector2(0.4, -0.4), 0.5, Color.WHITE)
		draw_circle(eye_r + Vector2(0.4, -0.4), 0.5, Color.WHITE)

	# 6. Held Item
	if not held_item.is_empty():
		var hold_hover := sin(walk_anim_timer * 1.5) * 1.2 if is_moving else 0.0
		var item_pos := char_center + Vector2(0.0, -26.0 + hold_hover)
		draw_circle(char_center + Vector2(-8, -12 + hold_hover * 0.5), 2.8, skin_color)
		draw_circle(char_center + Vector2(8, -12 + hold_hover * 0.5), 2.8, skin_color)
		ItemData.draw_procedural_item(self, item_pos, held_item.get("id", ""), 1.0)

	# 7. Procedural Overhead Patience Meter Bar
	if current_state in [State.BROWSING_SHELF, State.GOING_TO_CASHIER, State.QUEUEING]:
		_draw_patience_bar(char_center + Vector2(0.0, -45.0))

	# 8. Status Thought Bubble
	var bubble_pos := char_center + Vector2(0.0, -32.0 if current_state in [State.BROWSING_SHELF, State.GOING_TO_CASHIER, State.QUEUEING] else -36.0)
	_draw_thought_bubble(bubble_pos)

func _draw_patience_bar(pos: Vector2) -> void:
	var bar_w := 26.0
	var bar_h := 4.0
	var ratio := clampf(current_patience / max_patience, 0.0, 1.0)
	var rect_bg := Rect2(pos.x - bar_w * 0.5, pos.y, bar_w, bar_h)

	# Border and background
	draw_rect(Rect2(rect_bg.position.x - 1, rect_bg.position.y - 1, bar_w + 2, bar_h + 2), Color(0.10, 0.12, 0.16, 0.85), true)
	draw_rect(rect_bg, Color(0.20, 0.22, 0.26), true)

	# Dynamic Fill Bar Color: Green -> Yellow -> Red
	var fill_color: Color
	if ratio > 0.5:
		fill_color = Color(0.30, 0.85, 0.45) # Green (Patient)
	elif ratio > 0.25:
		fill_color = Color(0.95, 0.80, 0.25) # Yellow (Agitated)
	else:
		fill_color = Color(0.95, 0.28, 0.25) # Red (Angry)

	draw_rect(Rect2(rect_bg.position.x, rect_bg.position.y, bar_w * ratio, bar_h), fill_color, true)

func _draw_thought_bubble(pos: Vector2) -> void:
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var bubble_tex: Texture2D = AssetMgr.get_texture("bubble_frame")
	if bubble_tex != null:
		draw_texture_rect(bubble_tex, Rect2(pos.x - 16, pos.y - 12, 32, 28), false)
	else:
		var bubble_rect := Rect2(pos.x - 14, pos.y - 10, 28, 20)
		var tail := PackedVector2Array([
			Vector2(pos.x - 2, pos.y + 10),
			Vector2(pos.x + 2, pos.y + 10),
			Vector2(pos.x, pos.y + 13)
		])
		draw_rect(Rect2(bubble_rect.position.x - 1, bubble_rect.position.y - 1, bubble_rect.size.x + 2, bubble_rect.size.y + 2), Color(0.10, 0.12, 0.16, 0.35), true)
		draw_colored_polygon(tail, Color.WHITE)
		draw_rect(bubble_rect, Color(0.98, 0.98, 1.0), true)
		draw_rect(bubble_rect, Color(0.75, 0.78, 0.85), false, 1.0)

	match bubble_text_type:
		"item":
			ItemData.draw_procedural_item(self, pos + Vector2(0, -1), wanted_item_type, 0.75)
		"dots":
			for i in range(3):
				var dot_x := pos.x - 5.0 + i * 5.0
				var dot_y := pos.y - 1.0 + sin(state_timer * 6.0 + i * 1.5) * 1.2
				draw_circle(Vector2(dot_x, dot_y), 1.5, Color(0.35, 0.4, 0.48))
		"check":
			var check_tex: Texture2D = AssetMgr.get_texture("icon_check")
			if check_tex != null:
				draw_texture_rect(check_tex, Rect2(pos.x - 7, pos.y - 8, 14, 14), false)
			else:
				var pts := PackedVector2Array([
					pos + Vector2(-5, 0),
					pos + Vector2(-2, 4),
					pos + Vector2(5, -4)
				])
				draw_polyline(pts, Color(0.20, 0.68, 0.32), 2.0)
		"empty":
			var empty_tex: Texture2D = AssetMgr.get_texture("status_empty")
			if empty_tex != null:
				draw_texture_rect(empty_tex, Rect2(pos.x - 7, pos.y - 8, 14, 14), false)
			else:
				draw_line(pos + Vector2(0, -5), pos + Vector2(0, 1), Color(0.85, 0.25, 0.25), 2.0)
				draw_circle(pos + Vector2(0, 4), 1.2, Color(0.85, 0.25, 0.25))
		"queue":
			ItemData.draw_procedural_item(self, pos + Vector2(-3, -1), wanted_item_type, 0.65)
			var coin_tex: Texture2D = AssetMgr.get_texture("icon_money")
			if coin_tex != null:
				draw_texture_rect(coin_tex, Rect2(pos.x + 2, pos.y - 3, 9, 9), false)
			else:
				draw_circle(pos + Vector2(6, 2), 2.8, Color(0.95, 0.78, 0.25))
		"angry":
			var angry_tex: Texture2D = AssetMgr.get_texture("status_angry")
			if angry_tex != null:
				draw_texture_rect(angry_tex, Rect2(pos.x - 7, pos.y - 8, 14, 14), false)
			else:
				var zigzag := PackedVector2Array([
					pos + Vector2(-6, -4),
					pos + Vector2(-2, 3),
					pos + Vector2(2, -4),
					pos + Vector2(6, 3)
				])
				draw_polyline(zigzag, Color(0.95, 0.25, 0.25), 2.2)
