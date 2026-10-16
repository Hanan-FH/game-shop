extends Node2D
class_name ShopEnvironment

## Modern Minimarket Shop Environment
## 100% Procedural Ceramic Tile Floor, Clean Commercial Walls, Accent Stripes, Welcome Mat, and Door Trigger.

# Boundary Constants (Aligned with 1152 x 648 resolution)
const SHOP_LEFT := 136.0
const SHOP_RIGHT := 1016.0
const SHOP_TOP := 76.0
const SHOP_BOTTOM := 572.0

const WALL_THICKNESS := 24.0
const TOP_WALL_HEIGHT := 36.0

# Modern Minimarket Color Palette
const COLOR_BG := Color(0.10, 0.12, 0.15)                  # Dark exterior void
const COLOR_TILE_BASE := Color(0.93, 0.95, 0.97)            # Bright ceramic tile floor
const COLOR_TILE_ALT := Color(0.90, 0.92, 0.95)             # Subtle checkerboard tile tone
const COLOR_TILE_GROUT := Color(0.80, 0.83, 0.87, 0.85)     # Thin grout seam lines
const COLOR_TILE_SHEEN := Color(1.0, 1.0, 1.0, 0.35)        # Clean waxed floor reflection
const COLOR_SHADOW := Color(0.08, 0.10, 0.14, 0.18)         # Soft ambient wall occlusion

# Modern Wall & Accent Palette
const COLOR_WALL_FACE := Color(0.86, 0.88, 0.92)            # Modern light grey interior wall
const COLOR_WALL_TOP := Color(0.20, 0.24, 0.30)             # Charcoal roof cap
const COLOR_KICKER_TRIM := Color(0.28, 0.32, 0.38)          # Baseboard kicker plate
const COLOR_STRIPE_BLUE := Color(0.12, 0.44, 0.84)          # Convenience store blue stripe
const COLOR_STRIPE_ORANGE := Color(0.95, 0.54, 0.18)        # Convenience store orange stripe
const COLOR_STRIPE_GREEN := Color(0.18, 0.72, 0.45)         # Fresh green accent

# Modern Entrance & Commercial Mat
const COLOR_MAT_BASE := Color(0.22, 0.24, 0.28)             # Charcoal heavy-duty rubber mat
const COLOR_MAT_BORDER := Color(0.82, 0.85, 0.90)           # Beveled aluminum edge
const COLOR_MAT_TREAD := Color(0.32, 0.35, 0.40)            # Slip-resistant ribbed tread
const COLOR_DOOR_FRAME := Color(0.25, 0.28, 0.34)
const COLOR_GLASS := Color(0.70, 0.86, 0.95, 0.40)

@onready var door_trigger: Area2D = get_node_or_null("DoorTrigger")
@onready var prompt_container: PanelContainer = get_node_or_null("PromptAnchor/PromptContainer")
@onready var prompt_label: Label = get_node_or_null("PromptAnchor/PromptContainer/PromptLabel")

var is_player_at_door: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	if prompt_container:
		prompt_container.visible = false
	if door_trigger:
		door_trigger.body_entered.connect(_on_door_body_entered)
		door_trigger.body_exited.connect(_on_door_body_exited)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.day_state_changed.connect(_on_day_state_changed)

	queue_redraw()

func _on_day_state_changed(_new_state) -> void:
	_update_door_prompt()
	queue_redraw()

func _on_door_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		is_player_at_door = true
		player_ref = body
		if body.has_method("set_active_door"):
			body.set_active_door(self)
		_update_door_prompt()

func _on_door_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_at_door = false
		if player_ref and player_ref.has_method("clear_active_door"):
			player_ref.clear_active_door(self)
		player_ref = null
		if prompt_container:
			prompt_container.visible = false

func _update_door_prompt() -> void:
	if not prompt_container or not prompt_label:
		return

	var gm = get_node_or_null("/root/GameManager")
	if not is_player_at_door or not gm:
		prompt_container.visible = false
		return

	if gm.day_state == gm.DayState.PRE_OPEN:
		prompt_container.visible = true
		prompt_label.text = "[E] Buka Toko (Mulai Jam Operasional)"
		prompt_label.set("theme_override_colors/font_color", Color(0.98, 0.85, 0.35))
	elif gm.day_state == gm.DayState.OPEN:
		prompt_container.visible = true
		prompt_label.text = "Toko Sedang Buka (08:00 - 21:00)"
		prompt_label.set("theme_override_colors/font_color", Color(0.45, 0.95, 0.65))
	elif gm.day_state == gm.DayState.CLOSING:
		prompt_container.visible = true
		prompt_label.text = "Toko Sedang Menutup..."
		prompt_label.set("theme_override_colors/font_color", Color(0.95, 0.65, 0.25))
	else:
		prompt_container.visible = false

func open_store() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.day_state == gm.DayState.PRE_OPEN:
		gm.open_store()
		_update_door_prompt()
		queue_redraw()
		return true
	return false

func _draw() -> void:
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var shop_width := SHOP_RIGHT - SHOP_LEFT
	var shop_height := SHOP_BOTTOM - SHOP_TOP

	# 1. Outer Void / Ambient Background
	draw_rect(Rect2(0, 0, 1152, 648), COLOR_BG, true)

	# 2. Base Shop Floor & Ceramic Tile Grid Asset
	var floor_rect := Rect2(SHOP_LEFT, SHOP_TOP, shop_width, shop_height)
	draw_rect(floor_rect, COLOR_TILE_BASE, true)

	var floor_tex: Texture2D = AssetMgr.get_texture("floor_tile")
	if floor_tex != null:
		draw_texture_rect(floor_tex, floor_rect, true)
	else:
		# 3. Procedural Ceramic Tile Grid
		var tile_size := 36.0
		var cols := int(shop_width / tile_size) + 1
		var rows := int(shop_height / tile_size) + 1

		for r in range(rows):
			var y: float = SHOP_TOP + r * tile_size
			if y >= SHOP_BOTTOM:
				break
			var h := minf(tile_size, SHOP_BOTTOM - y)

			for c in range(cols):
				var x: float = SHOP_LEFT + c * tile_size
				if x >= SHOP_RIGHT:
					break
				var w := minf(tile_size, SHOP_RIGHT - x)

				if (r + c) % 2 == 1:
					draw_rect(Rect2(x, y, w, h), COLOR_TILE_ALT, true)

				if (r + c * 3) % 7 == 0 and w >= 20.0 and h >= 20.0:
					draw_line(Vector2(x + 6, y + 4), Vector2(x + w - 6, y + 4), COLOR_TILE_SHEEN, 1.2)

		# Horizontal grout lines
		for r in range(rows + 1):
			var gy: float = SHOP_TOP + r * tile_size
			if gy <= SHOP_BOTTOM:
				draw_line(Vector2(SHOP_LEFT, gy), Vector2(SHOP_RIGHT, gy), COLOR_TILE_GROUT, 1.0)

		# Vertical grout lines
		for c in range(cols + 1):
			var gx: float = SHOP_LEFT + c * tile_size
			if gx <= SHOP_RIGHT:
				draw_line(Vector2(gx, SHOP_TOP), Vector2(gx, SHOP_BOTTOM), COLOR_TILE_GROUT, 1.0)

	# 4. Modern Entrance Welcome Mat
	var mat_w := 154.0
	var mat_h := 40.0
	var mat_x := (SHOP_LEFT + SHOP_RIGHT - mat_w) * 0.5
	var mat_y := SHOP_BOTTOM - mat_h - 4.0
	var mat_rect := Rect2(mat_x, mat_y, mat_w, mat_h)

	var mat_tex: Texture2D = AssetMgr.get_texture("welcome_mat")
	if mat_tex != null:
		draw_texture_rect(mat_tex, Rect2(mat_x - 3, mat_y - 3, mat_w + 6, mat_h + 6), false)
	else:
		draw_rect(Rect2(mat_x - 3, mat_y - 3, mat_w + 6, mat_h + 6), COLOR_MAT_BORDER, true)
		draw_rect(mat_rect, COLOR_MAT_BASE, true)

		for i in range(6):
			var tread_y := mat_y + 5.0 + i * 5.5
			draw_line(Vector2(mat_x + 8, tread_y), Vector2(mat_x + mat_w - 8, tread_y), COLOR_MAT_TREAD, 1.5)

		# Welcome Mat Center Decal
		var banner_w := 76.0
		var banner_x := mat_x + (mat_w - banner_w) * 0.5
		draw_rect(Rect2(banner_x, mat_y + 11.0, banner_w, 18.0), Color(0.16, 0.18, 0.22), true)
		draw_rect(Rect2(banner_x, mat_y + 11.0, banner_w, 18.0), COLOR_STRIPE_BLUE, false, 1.2)
		draw_line(Vector2(banner_x + 8, mat_y + 20), Vector2(banner_x + banner_w - 8, mat_y + 20), Color(0.92, 0.94, 0.98), 1.5)

	# 5. Ambient Wall Occlusion
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP, shop_width, 10.0), COLOR_SHADOW, true)
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP, 8.0, shop_height), COLOR_SHADOW, true)
	draw_rect(Rect2(SHOP_RIGHT - 8.0, SHOP_TOP, 8.0, shop_height), COLOR_SHADOW, true)

	# 6. Modern Solid Walls
	var top_wall_rect := Rect2(SHOP_LEFT - WALL_THICKNESS, SHOP_TOP - TOP_WALL_HEIGHT, shop_width + (WALL_THICKNESS * 2.0), TOP_WALL_HEIGHT)
	draw_rect(top_wall_rect, COLOR_WALL_FACE, true)
	draw_rect(Rect2(top_wall_rect.position.x, top_wall_rect.position.y, top_wall_rect.size.x, 8.0), COLOR_WALL_TOP, true)

	# Minimarket Brand Header Stripes
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP - 18.0, shop_width, 3.5), COLOR_STRIPE_BLUE, true)
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP - 14.5, shop_width, 2.5), COLOR_STRIPE_ORANGE, true)
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP - 12.0, shop_width, 3.5), COLOR_STRIPE_GREEN, true)
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP - 4.0, shop_width, 4.0), COLOR_KICKER_TRIM, true)

	# Left Wall
	var left_wall_rect := Rect2(SHOP_LEFT - WALL_THICKNESS, SHOP_TOP, WALL_THICKNESS, shop_height)
	draw_rect(left_wall_rect, COLOR_WALL_FACE, true)
	draw_line(Vector2(SHOP_LEFT, SHOP_TOP), Vector2(SHOP_LEFT, SHOP_BOTTOM), COLOR_KICKER_TRIM, 2.5)

	# Right Wall
	var right_wall_rect := Rect2(SHOP_RIGHT, SHOP_TOP, WALL_THICKNESS, shop_height)
	draw_rect(right_wall_rect, COLOR_WALL_FACE, true)
	draw_line(Vector2(SHOP_RIGHT, SHOP_TOP), Vector2(SHOP_RIGHT, SHOP_BOTTOM), COLOR_KICKER_TRIM, 2.5)

	# Bottom Wall & Entrance Doorway
	var door_w := 148.0
	var door_start_x := (SHOP_LEFT + SHOP_RIGHT - door_w) * 0.5
	var door_end_x := door_start_x + door_w

	draw_rect(Rect2(SHOP_LEFT - WALL_THICKNESS, SHOP_BOTTOM, (door_start_x - SHOP_LEFT) + WALL_THICKNESS, WALL_THICKNESS), COLOR_WALL_FACE, true)
	draw_line(Vector2(SHOP_LEFT, SHOP_BOTTOM), Vector2(door_start_x, SHOP_BOTTOM), COLOR_KICKER_TRIM, 2.5)

	draw_rect(Rect2(door_end_x, SHOP_BOTTOM, (SHOP_RIGHT - door_end_x) + WALL_THICKNESS, WALL_THICKNESS), COLOR_WALL_FACE, true)
	draw_line(Vector2(door_end_x, SHOP_BOTTOM), Vector2(SHOP_RIGHT, SHOP_BOTTOM), COLOR_KICKER_TRIM, 2.5)

	# Glass Automatic Sliding Door Threshold
	draw_rect(Rect2(door_start_x, SHOP_BOTTOM, door_w, WALL_THICKNESS), COLOR_DOOR_FRAME, true)
	draw_rect(Rect2(door_start_x + 4, SHOP_BOTTOM + 4, door_w - 8, WALL_THICKNESS - 8), COLOR_GLASS, true)
	draw_line(Vector2(door_start_x, SHOP_BOTTOM + 2), Vector2(door_end_x, SHOP_BOTTOM + 2), Color(0.85, 0.88, 0.94), 1.5)

	# 7. Illuminated Store Status Signboard [ BUKA ] / [ TUTUP ]
	var gm = get_node_or_null("/root/GameManager")
	var is_open: bool = (gm != null and gm.day_state == gm.DayState.OPEN)
	_draw_store_signboard(Vector2(door_start_x - 38, SHOP_BOTTOM - 20), is_open)

	# Illuminated Door Threshold LED
	var status_col := Color(0.95, 0.25, 0.25)
	if is_open:
		status_col = Color(0.25, 0.95, 0.50)
	elif gm and gm.day_state == gm.DayState.CLOSING:
		status_col = Color(0.95, 0.70, 0.25)

	var center_x := (door_start_x + door_end_x) * 0.5
	draw_circle(Vector2(center_x, SHOP_BOTTOM + 6), 3.0, status_col)
	draw_arc(Vector2(center_x, SHOP_BOTTOM + 6), 4.5, 0.0, TAU, 12, status_col, 1.0)

func _draw_store_signboard(pos: Vector2, is_open: bool) -> void:
	var AssetMgr = preload("res://scripts/autoload/asset_manager.gd")
	var sign_tex: Texture2D = AssetMgr.get_texture("sign_open" if is_open else "sign_closed")
	if sign_tex != null:
		draw_texture_rect(sign_tex, Rect2(pos.x - 30.0, pos.y - 14.0, 60.0, 36.0), false)
		return

	# Signboard stand
	draw_rect(Rect2(pos.x - 10, pos.y + 14, 20, 4), Color(0.24, 0.26, 0.32), true) # Base
	draw_rect(Rect2(pos.x - 2, pos.y + 8, 4, 8), Color(0.35, 0.38, 0.45), true)   # Post

	# Main signboard housing
	var board_w := 54.0
	var board_h := 20.0
	var board_rect := Rect2(pos.x - board_w * 0.5, pos.y - board_h * 0.5, board_w, board_h)

	var bg_col := Color(0.08, 0.20, 0.12) if is_open else Color(0.22, 0.08, 0.08)
	var border_col := Color(0.25, 0.95, 0.50) if is_open else Color(0.95, 0.25, 0.25)
	var text_col := Color(0.40, 0.98, 0.65) if is_open else Color(0.98, 0.40, 0.40)

	draw_rect(board_rect, bg_col, true)
	draw_rect(board_rect, border_col, false, 1.5)

	# Brackets [ ]
	draw_line(Vector2(board_rect.position.x + 4, board_rect.position.y + 4), Vector2(board_rect.position.x + 2, board_rect.position.y + 4), text_col, 1.2)
	draw_line(Vector2(board_rect.position.x + 2, board_rect.position.y + 4), Vector2(board_rect.position.x + 2, board_rect.position.y + board_h - 4), text_col, 1.2)
	draw_line(Vector2(board_rect.position.x + 2, board_rect.position.y + board_h - 4), Vector2(board_rect.position.x + 4, board_rect.position.y + board_h - 4), text_col, 1.2)

	var right_x := board_rect.position.x + board_w
	draw_line(Vector2(right_x - 4, board_rect.position.y + 4), Vector2(right_x - 2, board_rect.position.y + 4), text_col, 1.2)
	draw_line(Vector2(right_x - 2, board_rect.position.y + 4), Vector2(right_x - 2, board_rect.position.y + board_h - 4), text_col, 1.2)
	draw_line(Vector2(right_x - 2, board_rect.position.y + board_h - 4), Vector2(right_x - 4, board_rect.position.y + board_h - 4), text_col, 1.2)

	if is_open:
		# BUKA
		# B
		draw_line(Vector2(pos.x - 17, pos.y - 5), Vector2(pos.x - 17, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 17, pos.y - 5), Vector2(pos.x - 13, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 13, pos.y - 5), Vector2(pos.x - 13, pos.y), text_col, 1.2)
		draw_line(Vector2(pos.x - 17, pos.y), Vector2(pos.x - 13, pos.y), text_col, 1.2)
		draw_line(Vector2(pos.x - 13, pos.y), Vector2(pos.x - 13, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 17, pos.y + 5), Vector2(pos.x - 13, pos.y + 5), text_col, 1.2)
		# U
		draw_line(Vector2(pos.x - 9, pos.y - 5), Vector2(pos.x - 9, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 9, pos.y + 5), Vector2(pos.x - 4, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 4, pos.y - 5), Vector2(pos.x - 4, pos.y + 5), text_col, 1.2)
		# K
		draw_line(Vector2(pos.x + 0, pos.y - 5), Vector2(pos.x + 0, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 0, pos.y), Vector2(pos.x + 5, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 0, pos.y), Vector2(pos.x + 5, pos.y + 5), text_col, 1.2)
		# A
		draw_line(Vector2(pos.x + 9, pos.y + 5), Vector2(pos.x + 12, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 12, pos.y - 5), Vector2(pos.x + 15, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 10, pos.y + 1), Vector2(pos.x + 14, pos.y + 1), text_col, 1.2)
	else:
		# TUTUP
		# T
		draw_line(Vector2(pos.x - 19, pos.y - 5), Vector2(pos.x - 13, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 16, pos.y - 5), Vector2(pos.x - 16, pos.y + 5), text_col, 1.2)
		# U
		draw_line(Vector2(pos.x - 10, pos.y - 5), Vector2(pos.x - 10, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 10, pos.y + 5), Vector2(pos.x - 6, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x - 6, pos.y - 5), Vector2(pos.x - 6, pos.y + 5), text_col, 1.2)
		# T
		draw_line(Vector2(pos.x - 3, pos.y - 5), Vector2(pos.x + 3, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x, pos.y - 5), Vector2(pos.x, pos.y + 5), text_col, 1.2)
		# U
		draw_line(Vector2(pos.x + 6, pos.y - 5), Vector2(pos.x + 6, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 6, pos.y + 5), Vector2(pos.x + 10, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 10, pos.y - 5), Vector2(pos.x + 10, pos.y + 5), text_col, 1.2)
		# P
		draw_line(Vector2(pos.x + 13, pos.y - 5), Vector2(pos.x + 13, pos.y + 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 13, pos.y - 5), Vector2(pos.x + 18, pos.y - 5), text_col, 1.2)
		draw_line(Vector2(pos.x + 18, pos.y - 5), Vector2(pos.x + 18, pos.y), text_col, 1.2)
		draw_line(Vector2(pos.x + 13, pos.y), Vector2(pos.x + 18, pos.y), text_col, 1.2)
