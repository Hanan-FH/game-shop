extends StaticBody2D
class_name RestockCrate

## Modern Minimarket - Distribution Restock Container Entity
## Modern logistics carton with shipping labels, barcode decals, product stamp, and wholesale restocking.

const ItemData = preload("res://scripts/components/item_data.gd")

@export var item_type: String = "soda"

var is_player_near: bool = false
var player_ref: CharacterBody2D = null
var pop_scale: float = 1.0

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
		if body.has_method("set_active_restock"):
			body.set_active_restock(self)
		_update_prompt()
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_near = false
		if player_ref and player_ref.has_method("clear_active_restock"):
			player_ref.clear_active_restock(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false
		queue_redraw()

func _process(_delta: float) -> void:
	if is_player_near:
		_update_prompt()

func _get_wholesale_cost() -> int:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_wholesale_price"):
		return gm.get_wholesale_price(item_type)
	return 5

func _update_prompt() -> void:
	if not prompt_container or not prompt_label:
		return
	
	prompt_container.visible = is_player_near
	if not is_player_near:
		return

	var item_info := ItemData.get_item(item_type)
	var item_name: String = item_info.get("name", "Barang")
	var cost := _get_wholesale_cost()

	if player_ref and "held_items" in player_ref:
		var held_count: int = player_ref.held_items.size()
		var max_cap: int = player_ref.max_carry_capacity

		if held_count >= max_cap:
			prompt_label.text = "Tas Penuh! (" + str(held_count) + "/" + str(max_cap) + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.70, 0.35))
			return

		var gm = get_node_or_null("/root/GameManager")
		var can_afford: bool = gm.can_afford(cost) if gm else true

		if can_afford:
			prompt_label.text = "[E] Beli " + item_name + " (-$" + str(cost) + ") [Tas: " + str(held_count) + "/" + str(max_cap) + "]"
			prompt_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
		else:
			prompt_label.text = "Uang Tidak Cukup ($" + str(cost) + ")"
			prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.45, 0.45))

## Called when player interacts to purchase stock
func interact(player: CharacterBody2D) -> bool:
	if player.has_method("can_pick_up") and not player.can_pick_up():
		_trigger_pop(0.95)
		return false

	var cost := _get_wholesale_cost()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if not gm.can_afford(cost):
			_trigger_pop(0.95)
			return false
		gm.spend_money(cost)
		if gm.has_method("record_wholesale_purchase"):
			gm.record_wholesale_purchase(cost)

	# Give item to player
	var item_info := ItemData.get_item(item_type)
	player.pick_up_item(item_info)

	# Feedback
	_trigger_pop(1.12)
	_spawn_floating_cost_text("-$" + str(cost))
	_update_prompt()
	queue_redraw()
	return true

func _trigger_pop(target_scale: float = 1.1) -> void:
	var tween := create_tween()
	pop_scale = target_scale
	tween.tween_property(self, "pop_scale", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_redraw)

func _spawn_floating_cost_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.set("theme_override_colors/font_color", Color(0.95, 0.48, 0.48))
	float_label.set("theme_override_font_sizes/font_size", 15)
	float_label.position = Vector2(-20, -42)
	add_child(float_label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(float_label, "position:y", -68.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.75).set_delay(0.2)
	tween.chain().tween_callback(float_label.queue_free)

func _draw() -> void:
	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop_scale, pop_scale))

	# 1. Floor Shadow
	var shadow_rect := Rect2(-30, 8, 60, 12)
	draw_rect(shadow_rect, Color(0.08, 0.10, 0.14, 0.22), true)

	# 2. Plastic Pallet Base
	draw_rect(Rect2(-28, 12, 56, 4), Color(0.24, 0.27, 0.32), true)
	draw_rect(Rect2(-22, 16, 6, 3), Color(0.18, 0.20, 0.24), true)
	draw_rect(Rect2(16, 16, 6, 3), Color(0.18, 0.20, 0.24), true)

	# 3. Minimarket Distribution Carton
	var box_w := 52.0
	var box_h := 36.0
	var box_rect := Rect2(-box_w * 0.5, -box_h + 12.0, box_w, box_h)
	
	draw_rect(box_rect, Color(0.82, 0.68, 0.52), true)
	draw_line(Vector2(box_rect.position.x, box_rect.position.y), Vector2(box_rect.position.x + box_w, box_rect.position.y), Color(0.70, 0.56, 0.40), 1.5)
	draw_line(Vector2(box_rect.position.x, box_rect.position.y + box_h), Vector2(box_rect.position.x + box_w, box_rect.position.y + box_h), Color(0.70, 0.56, 0.40), 1.5)

	# Commercial packaging seal tape
	draw_rect(Rect2(-box_w * 0.5, box_rect.position.y + 14, box_w, 6), Color(0.96, 0.85, 0.55), true)

	# 4. White Shipping Manifest Label with Barcode
	var label_rect := Rect2(-box_w * 0.5 + 4, box_rect.position.y + 3, 18, 10)
	draw_rect(label_rect, Color(0.98, 0.98, 1.0), true)
	for i in range(5):
		var bar_x := label_rect.position.x + 3 + i * 3
		draw_line(Vector2(bar_x, label_rect.position.y + 2), Vector2(bar_x, label_rect.position.y + 8), Color(0.15, 0.15, 0.18), 1.0)

	# 5. Product Stamped Icon on Box Front
	ItemData.draw_procedural_item(self, Vector2(10, -2), item_type, 0.8)

	# 6. Selection Glow when Player is Near
	if is_player_near:
		draw_rect(Rect2(box_rect.position.x - 2, box_rect.position.y - 2, box_w + 4, box_h + 4), Color(0.98, 0.82, 0.35, 0.85), false, 2.0)

	if pop_scale != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
