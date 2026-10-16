class_name ItemData
extends RefCounted

## Mini Shop - Item Definitions & Procedural Drawing Utilities (Phase 2)
## Pure code procedural rendering for shop items (soda, snack, apple).

const ITEMS := {
	"soda": {
		"id": "soda",
		"name": "Soda Dingin",
		"price": 12,
		"color": Color(0.24, 0.70, 0.82),       # Refreshing cyan
		"accent": Color(0.95, 0.95, 0.95),      # White band
		"shape": "can"
	},
	"snack": {
		"id": "snack",
		"name": "Keripik Kentang",
		"price": 15,
		"color": Color(0.94, 0.65, 0.22),      # Golden cheddar orange
		"accent": Color(0.85, 0.25, 0.20),      # Red label stripe
		"shape": "pouch"
	},
	"apple": {
		"id": "apple",
		"name": "Apel Segar",
		"price": 8,
		"color": Color(0.88, 0.26, 0.24),       # Crisp crimson red
		"accent": Color(0.38, 0.68, 0.28),      # Leaf green
		"shape": "fruit"
	}
}

static func get_item(item_id: String) -> Dictionary:
	if ITEMS.has(item_id):
		return ITEMS[item_id]
	return {}

## Procedural rendering of an item into any CanvasItem node
static func draw_procedural_item(ci: CanvasItem, center: Vector2, item_id: String, item_scale: float = 1.0) -> void:
	var data := get_item(item_id)
	if data.is_empty():
		return

	var main_col: Color = data["color"]
	var acc_col: Color = data["accent"]
	var shape: String = data["shape"]

	match shape:
		"can":
			# Soda Can: Cylindrical body with top lid and label band
			var w := 10.0 * item_scale
			var h := 14.0 * item_scale
			var rect := Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h)
			# Shadow border
			ci.draw_rect(Rect2(rect.position.x - 1, rect.position.y - 1, rect.size.x + 2, rect.size.y + 2), Color(0.1, 0.1, 0.15, 0.4), true)
			# Can base body
			ci.draw_rect(rect, main_col, true)
			# Top silver lid
			ci.draw_rect(Rect2(rect.position.x, rect.position.y, w, 2.5 * item_scale), Color(0.85, 0.88, 0.92), true)
			# Middle logo stripe
			ci.draw_rect(Rect2(rect.position.x, rect.position.y + 4.5 * item_scale, w, 4.0 * item_scale), acc_col, true)
			# Vertical highlight shine
			ci.draw_line(Vector2(rect.position.x + 2 * item_scale, rect.position.y + 3 * item_scale), Vector2(rect.position.x + 2 * item_scale, rect.position.y + h - 2 * item_scale), Color(1, 1, 1, 0.55), 1.2 * item_scale)

		"pouch":
			# Snack Bag / Pouch: Tapered packet with zigzag edge and bold label
			var w := 12.0 * item_scale
			var h := 14.0 * item_scale
			var pouch_pts := PackedVector2Array([
				center + Vector2(-w * 0.4, -h * 0.5),
				center + Vector2(w * 0.4, -h * 0.5),
				center + Vector2(w * 0.5, h * 0.5),
				center + Vector2(-w * 0.5, h * 0.5)
			])
			# Bag body
			ci.draw_colored_polygon(pouch_pts, main_col)
			# Crimson header crimp
			ci.draw_line(center + Vector2(-w * 0.4, -h * 0.45), center + Vector2(w * 0.4, -h * 0.45), acc_col, 2.0 * item_scale)
			# Bottom crimp
			ci.draw_line(center + Vector2(-w * 0.48, h * 0.45), center + Vector2(w * 0.48, h * 0.45), acc_col, 2.0 * item_scale)
			# Central flavor emblem
			ci.draw_circle(center + Vector2(0, 1.0 * item_scale), 3.0 * item_scale, acc_col)
			ci.draw_circle(center + Vector2(0, 1.0 * item_scale), 1.8 * item_scale, Color.WHITE)

		"fruit":
			# Fresh Apple: Round silhouette with cute stem & green leaf
			var radius := 6.5 * item_scale
			# Apple body shadow
			ci.draw_circle(center + Vector2(0, 1 * item_scale), radius, Color(0.15, 0.1, 0.1, 0.25))
			# Apple body
			ci.draw_circle(center, radius, main_col)
			# Apple cheek highlight
			ci.draw_circle(center + Vector2(-2 * item_scale, -2 * item_scale), 2.2 * item_scale, Color(1, 0.6, 0.6, 0.6))
			# Little brown stem
			ci.draw_line(center + Vector2(0, -radius), center + Vector2(1 * item_scale, -radius - 3.5 * item_scale), Color(0.42, 0.28, 0.16), 1.5 * item_scale)
			# Little green leaf
			var leaf_pts := PackedVector2Array([
				center + Vector2(1 * item_scale, -radius - 1.5 * item_scale),
				center + Vector2(4 * item_scale, -radius - 3.5 * item_scale),
				center + Vector2(3 * item_scale, -radius - 0.5 * item_scale)
			])
			ci.draw_colored_polygon(leaf_pts, acc_col)
