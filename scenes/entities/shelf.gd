extends StaticBody2D
class_name Shelf

## Modern Minimarket - Steel Gondola Shelf Entity
## Powder-coated white steel frame, vibrant price channels, procedural items, and multi-item carry interaction.

const ItemData = preload("res://scripts/components/item_data.gd")
const AssetMgr = preload("res://scripts/autoload/asset_manager.gd")

@export var item_type: String = "soda"
@export var max_stock: int = 5
@export var current_stock: int = 3

var is_player_near: bool = false
var player_ref: Node2D = null
var pop_scale: float = 1.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_container: PanelContainer = $PromptAnchor/PromptContainer
@onready var prompt_label: Label = $PromptAnchor/PromptContainer/PromptLabel

func _ready() -> void:
	add_to_group("shelves")
	if prompt_container:
		prompt_container.visible = false
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player":
		is_player_near = true
		player_ref = body
		if body.has_method("set_active_shelf"):
			body.set_active_shelf(self)
		_update_prompt()
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_near = false
		if player_ref and player_ref.has_method("clear_active_shelf"):
			player_ref.clear_active_shelf(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false
		queue_redraw()

func _process(_delta: float) -> void:
	if is_player_near:
		_update_prompt()

func _update_prompt() -> void:
	if not prompt_container or not prompt_label:
		return
	
	prompt_container.visible = is_player_near
	if not is_player_near:
		return

	var item_info := ItemData.get_item(item_type)
	var item_name: String = item_info.get("name", "Barang")

	if player_ref and "held_items" in player_ref:
		var held_count: int = player_ref.held_items.size()
		var max_cap: int = player_ref.max_carry_capacity
		var has_matching: bool = player_ref.has_item(item_type)

		if has_matching and current_stock < max_stock:
			prompt_label.text = "[E] Letakkan " + item_name + " (" + str(current_stock) + "/" + str(max_stock) + ") [Tas: " + str(held_count) + "/" + str(max_cap) + "]"
			prompt_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
		elif held_count < max_cap and current_stock > 0:
			prompt_label.text = "[E] Ambil " + item_name + " (" + str(current_stock) + "/" + str(max_stock) + ") [Tas: " + str(held_count) + "/" + str(max_cap) + "]"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.95, 0.98))
		elif held_count >= max_cap and not has_matching:
			prompt_label.text = "Tas Penuh! (" + str(held_count) + "/" + str(max_cap) + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.70, 0.35))
		elif current_stock >= max_stock and has_matching:
			prompt_label.text = "Rak Penuh! (" + str(max_stock) + "/" + str(max_stock) + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.75, 0.35))
		elif current_stock <= 0:
			prompt_label.text = "Rak Kosong! (" + item_name + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.45, 0.45))
		else:
			prompt_label.text = "[E] Ambil " + item_name + " (" + str(current_stock) + "/" + str(max_stock) + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.95, 0.98))

## Called when player presses interact key while near this shelf
func interact(player: CharacterBody2D) -> bool:
	var item_info := ItemData.get_item(item_type)

	# 1. First priority: if player carries matching item and shelf has room, place it on shelf
	if player.has_item(item_type) and current_stock < max_stock:
		player.pop_item(item_type)
		current_stock += 1
		AssetMgr.play_sfx("place")
		_trigger_pop()
		_update_prompt()
		queue_redraw()
		return true

	# 2. Second priority: if player has carry capacity and shelf has stock, pick up 1 item
	if player.can_pick_up() and current_stock > 0:
		current_stock -= 1
		player.pick_up_item(item_info)
		AssetMgr.play_sfx("pickup")
		_trigger_pop()
		_update_prompt()
		queue_redraw()
		return true

	AssetMgr.play_sfx("error")
	_trigger_pop(0.95)
	return false

func _trigger_pop(target_scale: float = 1.08) -> void:
	var tween := create_tween()
	pop_scale = target_scale
	tween.tween_property(self, "pop_scale", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_redraw)

func _draw() -> void:
	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop_scale, pop_scale))

	var shelf_tex: Texture2D = AssetMgr.get_texture("shelf_" + item_type)
	if shelf_tex != null:
		draw_texture_rect(shelf_tex, Rect2(-48, -32, 96, 64), false)
	else:
		# 1. Floor shadow beneath gondola
		var shadow_rect := Rect2(-44, 10, 88, 14)
		draw_rect(shadow_rect, Color(0.08, 0.10, 0.14, 0.24), true)

		# 2. Modern Steel Gondola Structure
		draw_rect(Rect2(-42, 16, 84, 6), Color(0.25, 0.28, 0.35), true)
		draw_rect(Rect2(-44, 20, 88, 3), Color(0.18, 0.20, 0.25), true)

		# Powder-coated white steel pegboard
		draw_rect(Rect2(-40, -24, 80, 42), Color(0.90, 0.92, 0.95), true)

		for r in range(4):
			var py := -20.0 + r * 10.0
			for c in range(7):
				var px := -30.0 + c * 10.0
				draw_circle(Vector2(px, py), 0.8, Color(0.78, 0.80, 0.85))

		# Upright posts
		draw_rect(Rect2(-42, -26, 6, 44), Color(0.75, 0.78, 0.84), true)
		draw_rect(Rect2(36, -26, 6, 44), Color(0.75, 0.78, 0.84), true)

		for i in range(5):
			var slot_y := -22.0 + i * 8.0
			draw_line(Vector2(-41, slot_y), Vector2(-38, slot_y), Color(0.50, 0.54, 0.60), 1.0)
			draw_line(Vector2(37, slot_y), Vector2(40, slot_y), Color(0.50, 0.54, 0.60), 1.0)

		# Top header crown
		draw_rect(Rect2(-44, -28, 88, 5), Color(0.82, 0.85, 0.90), true)

		# Shelf plates
		draw_rect(Rect2(-40, -4, 80, 4), Color(0.96, 0.97, 0.99), true)
		draw_rect(Rect2(-40, 14, 80, 4), Color(0.96, 0.97, 0.99), true)

		# 3. Gondola Price Tag Rails
		var rail_color: Color = Color(0.12, 0.44, 0.84)
		if item_type == "snack":
			rail_color = Color(0.90, 0.32, 0.22)
		elif item_type == "apple":
			rail_color = Color(0.16, 0.68, 0.38)

		draw_rect(Rect2(-32, -27, 64, 3), rail_color, true)
		draw_rect(Rect2(-40, -2, 80, 3), rail_color, true)
		draw_rect(Rect2(-40, 16, 80, 3), rail_color, true)

		for i in range(3):
			var tag_x := -26.0 + i * 26.0
			draw_rect(Rect2(tag_x, -2, 12, 3), Color.WHITE, true)
			draw_rect(Rect2(tag_x, 16, 12, 3), Color.WHITE, true)

		draw_rect(Rect2(-40, -5, 80, 2), Color(0.85, 0.92, 0.98, 0.6), true)
		draw_rect(Rect2(-40, 13, 80, 2), Color(0.85, 0.92, 0.98, 0.6), true)

	# 4. Stored Items
	var slots := [
		Vector2(-22, -11),
		Vector2(0, -11),
		Vector2(22, -11),
		Vector2(-14, 7),
		Vector2(14, 7)
	]

	var display_count := mini(current_stock, slots.size())
	for i in range(display_count):
		ItemData.draw_procedural_item(self, slots[i], item_type, 0.95)

	# 5. Selection Glow
	if is_player_near:
		draw_rect(Rect2(-46, -30, 92, 54), Color(0.98, 0.82, 0.35, 0.85), false, 2.0)

	# 6. LED Stock Indicators
	for i in range(max_stock):
		var dot_x := -16.0 + i * 8.0
		var dot_col := Color(0.20, 0.85, 0.45) if i < current_stock else Color(0.35, 0.38, 0.45, 0.45)
		draw_circle(Vector2(dot_x, 26), 2.2, dot_col)

	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
