
extends Area2D
class_name Trash

## Modern Minimarket - Floor Trash & Cleaning Entity
## Procedural convenience store litter (thermal receipts, crushed drink cans, snack wrappers).
## Cleaned by player for store cleanliness, cash bonus, and reputation.

var is_player_near: bool = false
var player_ref: CharacterBody2D = null

@onready var prompt_container: PanelContainer = $PromptAnchor/PromptContainer
@onready var prompt_label: Label = $PromptAnchor/PromptContainer/PromptLabel

var trash_variant: int = 0

func _ready() -> void:
	trash_variant = randi() % 3
	if prompt_container:
		prompt_container.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		is_player_near = true
		player_ref = body
		if body.has_method("set_active_trash"):
			body.set_active_trash(self)
		if prompt_container:
			prompt_container.visible = true
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_near = false
		if player_ref and player_ref.has_method("clear_active_trash"):
			player_ref.clear_active_trash(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false
		queue_redraw()

func clean_up() -> void:
	if player_ref and player_ref.has_method("clear_active_trash"):
		player_ref.clear_active_trash(self)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_money(2)
		if gm.has_method("add_reputation_bonus"):
			gm.add_reputation_bonus(0.1)

	_spawn_floating_text("Lantai Bersih! (+$2)")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _spawn_floating_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
	float_label.set("theme_override_font_sizes/font_size", 14)
	float_label.position = Vector2(-40, -30)
	get_parent().add_child(float_label)
	float_label.global_position = global_position + Vector2(-40, -30)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(float_label, "position:y", float_label.position.y - 25.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(float_label.queue_free)

func _draw() -> void:
	# 1. Floor shadow
	draw_circle(Vector2(0, 3), 6.5, Color(0.08, 0.10, 0.14, 0.2))

	match trash_variant:
		0:
			# Crumpled White Thermal Cashier Receipt Strip
			var receipt_pts := PackedVector2Array([
				Vector2(-6, -4),
				Vector2(4, -6),
				Vector2(7, 2),
				Vector2(1, 6),
				Vector2(-5, 3)
			])
			draw_colored_polygon(receipt_pts, Color(0.96, 0.97, 0.99))
			# Thermal barcode / text stripes
			draw_line(Vector2(-3, -2), Vector2(3, -3), Color(0.40, 0.45, 0.52), 1.0)
			draw_line(Vector2(-2, 0), Vector2(4, -1), Color(0.40, 0.45, 0.52), 1.0)
			draw_line(Vector2(-3, 3), Vector2(1, 2), Color(0.40, 0.45, 0.52), 1.0)

		1:
			# Crushed Aluminum Soda Can
			draw_rect(Rect2(-5, -4, 10, 7), Color(0.85, 0.28, 0.25), true)
			draw_rect(Rect2(-4, -6, 8, 2), Color(0.78, 0.82, 0.88), true) # Can rim
			draw_line(Vector2(-5, 0), Vector2(5, 0), Color.WHITE, 1.2) # White soda stripe
			draw_circle(Vector2(0, -5), 1.0, Color(0.45, 0.48, 0.55)) # Pull tab hole

		2:
			# Crumpled Snack Foil Wrapper
			var foil_pts := PackedVector2Array([
				Vector2(-7, -2),
				Vector2(-1, -6),
				Vector2(6, -3),
				Vector2(5, 4),
				Vector2(-3, 5)
			])
			draw_colored_polygon(foil_pts, Color(0.95, 0.65, 0.20))
			draw_line(Vector2(-4, 0), Vector2(4, 1), Color(0.98, 0.88, 0.40), 1.5)

	# Selection glow if player is near
	if is_player_near:
		draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 16, Color(0.98, 0.82, 0.35, 0.85), 1.5)
