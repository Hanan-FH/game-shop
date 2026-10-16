extends StaticBody2D
class_name Bench

## Modern Minimarket - Customer Waiting Bench Entity
## Ergonomic molded composite waiting bench with tubular steel frame. Slows customer patience depletion by 30%.

@onready var comfort_area: Area2D = $ComfortArea

func _ready() -> void:
	if comfort_area:
		comfort_area.body_entered.connect(_on_body_entered)
		comfort_area.body_exited.connect(_on_body_exited)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_bench"):
		body.set_near_bench(true)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_bench"):
		body.set_near_bench(false)

func _draw() -> void:
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var bench_tex: Texture2D = AssetMgr.get_texture("bench")
	if bench_tex != null:
		draw_texture_rect(bench_tex, Rect2(-38, -18, 76, 40), false)
		return

	# 1. Floor Shadow
	var shadow_rect := Rect2(-36, 8, 72, 12)
	draw_rect(shadow_rect, Color(0.08, 0.10, 0.14, 0.22), true)

	# 2. Tubular Stainless Steel Frame & Legs
	# Front legs
	draw_rect(Rect2(-30, 2, 4, 14), Color(0.72, 0.76, 0.82), true)
	draw_rect(Rect2(26, 2, 4, 14), Color(0.72, 0.76, 0.82), true)
	# Rubber foot pads
	draw_rect(Rect2(-31, 14, 6, 3), Color(0.20, 0.22, 0.26), true)
	draw_rect(Rect2(25, 14, 6, 3), Color(0.20, 0.22, 0.26), true)
	# Steel stretcher bar
	draw_rect(Rect2(-30, 8, 60, 3), Color(0.65, 0.70, 0.76), true)

	# 3. Modern Ergonomic Molded Composite Seat (Teal / Cyan commercial finish)
	# Seat cushion base
	var seat_rect := Rect2(-34, -4, 68, 12)
	draw_rect(seat_rect, Color(0.18, 0.52, 0.62), true)
	# Seat front highlight
	draw_line(Vector2(-34, -4), Vector2(34, -4), Color(0.35, 0.72, 0.82), 1.5)

	# 4. Modern Contoured Backrest Slats
	var backrest_rect := Rect2(-34, -14, 68, 8)
	draw_rect(backrest_rect, Color(0.15, 0.46, 0.55), true)
	draw_line(Vector2(-34, -14), Vector2(34, -14), Color(0.30, 0.65, 0.75), 1.2)

	# Seat seat divider grooves
	for i in range(1, 3):
		var div_x := -34.0 + i * 22.6
		draw_line(Vector2(div_x, -14), Vector2(div_x, 7), Color(0.12, 0.38, 0.46), 1.2)

	# 5. Stainless Armrests
	draw_line(Vector2(-33, -12), Vector2(-33, 4), Color(0.78, 0.82, 0.88), 2.5)
	draw_line(Vector2(33, -12), Vector2(33, 4), Color(0.78, 0.82, 0.88), 2.5)
