extends Node

## Mini Shop - Centralized Asset & Audio Manager
## Manages all 2D Sprite Textures (SVG/PNG) and Audio Streams (SFX & BGM) from res://assets/
## without altering core gameplay mechanics or state logic.

const TEXTURE_PATHS := {
	"icon": "res://assets/icon.svg",
	# Items
	"item_soda": "res://assets/sprites/items/item_soda.svg",
	"item_snack": "res://assets/sprites/items/item_snack.svg",
	"item_apple": "res://assets/sprites/items/item_apple.svg",
	# Characters
	"player_clerk": "res://assets/sprites/characters/player_clerk.svg",
	"cashier_npc": "res://assets/sprites/characters/cashier_npc.svg",
	"customer_regular": "res://assets/sprites/characters/customer_regular.svg",
	"customer_impatient": "res://assets/sprites/characters/customer_impatient.svg",
	"customer_vip": "res://assets/sprites/characters/customer_vip.svg",
	# Entities
	"shelf_soda": "res://assets/sprites/entities/shelf_soda.svg",
	"shelf_snack": "res://assets/sprites/entities/shelf_snack.svg",
	"shelf_apple": "res://assets/sprites/entities/shelf_apple.svg",
	"cashier_counter": "res://assets/sprites/entities/cashier_counter.svg",
	"restock_crate_soda": "res://assets/sprites/entities/restock_crate_soda.svg",
	"restock_crate_snack": "res://assets/sprites/entities/restock_crate_snack.svg",
	"restock_crate_apple": "res://assets/sprites/entities/restock_crate_apple.svg",
	"upgrade_station": "res://assets/sprites/entities/upgrade_station.svg",
	"bench": "res://assets/sprites/entities/bench.svg",
	"trash_receipt": "res://assets/sprites/entities/trash_receipt.svg",
	"trash_can": "res://assets/sprites/entities/trash_can.svg",
	"trash_wrapper": "res://assets/sprites/entities/trash_wrapper.svg",
	# Environment
	"floor_tile": "res://assets/sprites/environment/floor_tile.svg",
	"welcome_mat": "res://assets/sprites/environment/welcome_mat.svg",
	"sign_open": "res://assets/sprites/environment/sign_open.svg",
	"sign_closed": "res://assets/sprites/environment/sign_closed.svg",
	"queue_marker": "res://assets/sprites/environment/queue_marker.svg",
	# UI & HUD Icons
	"icon_money": "res://assets/sprites/ui/icon_money.svg",
	"icon_clock": "res://assets/sprites/ui/icon_clock.svg",
	"icon_day": "res://assets/sprites/ui/icon_day.svg",
	"icon_customer": "res://assets/sprites/ui/icon_customer.svg",
	"icon_star": "res://assets/sprites/ui/icon_star.svg",
	"icon_check": "res://assets/sprites/ui/icon_check.svg",
	"bubble_frame": "res://assets/sprites/ui/bubble_frame.svg",
	"status_angry": "res://assets/sprites/ui/status_angry.svg",
	"status_empty": "res://assets/sprites/ui/status_empty.svg"
}

const AUDIO_PATHS := {
	"pickup": "res://assets/audio/sfx/sfx_pickup.wav",
	"place": "res://assets/audio/sfx/sfx_place.wav",
	"cash_register": "res://assets/audio/sfx/sfx_cash_register.wav",
	"upgrade": "res://assets/audio/sfx/sfx_upgrade.wav",
	"restock_buy": "res://assets/audio/sfx/sfx_restock_buy.wav",
	"clean_trash": "res://assets/audio/sfx/sfx_clean_trash.wav",
	"store_open": "res://assets/audio/sfx/sfx_store_open.wav",
	"store_close": "res://assets/audio/sfx/sfx_store_close.wav",
	"error": "res://assets/audio/sfx/sfx_error.wav",
	"customer_angry": "res://assets/audio/sfx/sfx_customer_angry.wav",
	"bgm_minimarket": "res://assets/audio/bgm/bgm_minimarket.wav"
}

static var _texture_cache: Dictionary = {}
static var _audio_cache: Dictionary = {}
static var _instance: Node = null

var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	_instance = self
	preload_all_assets()
	_setup_audio_players()
	_connect_game_manager_signals()

func _exit_tree() -> void:
	if bgm_player:
		bgm_player.stop()
	for p in sfx_players:
		if is_instance_valid(p):
			p.stop()
	_texture_cache.clear()
	_audio_cache.clear()
	if _instance == self:
		_instance = null

static func preload_all_assets() -> void:
	for key: String in TEXTURE_PATHS.keys():
		get_texture(key)
	for key: String in AUDIO_PATHS.keys():
		get_audio(key)

static func get_texture(key: String) -> Texture2D:
	if _texture_cache.has(key):
		return _texture_cache[key]

	var path: String = TEXTURE_PATHS.get(key, "")
	if path.is_empty():
		return null

	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = ResourceLoader.load(path) as Texture2D

	if tex == null:
		var png_path: String = path.replace(".svg", ".png")
		if ResourceLoader.exists(png_path):
			tex = ResourceLoader.load(png_path) as Texture2D

	if tex == null:
		var img := Image.new()
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path) and img.load(abs_path) == OK:
			tex = ImageTexture.create_from_image(img)

	if tex != null and _instance != null:
		_texture_cache[key] = tex
	return tex

static func get_audio(key: String) -> AudioStream:
	if _audio_cache.has(key):
		return _audio_cache[key]

	var path: String = AUDIO_PATHS.get(key, "")
	if path.is_empty():
		return null

	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = ResourceLoader.load(path) as AudioStream

	if stream is AudioStreamWAV and key == "bgm_minimarket":
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.data.size() / 2)

	if stream != null and _instance != null:
		_audio_cache[key] = stream
	return stream

static func play_sfx(key: String, volume_db: float = -4.0) -> void:
	if _instance != null and is_instance_valid(_instance) and _instance.has_method("_play_sfx_internal"):
		_instance._play_sfx_internal(key, volume_db)

func _setup_audio_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = -12.0
	add_child(bgm_player)

	var bgm_stream := get_audio("bgm_minimarket")
	if bgm_stream:
		bgm_player.stream = bgm_stream
		bgm_player.finished.connect(_on_bgm_finished)
		bgm_player.play()

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		add_child(p)
		sfx_players.append(p)

func _on_bgm_finished() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func _play_sfx_internal(key: String, volume_db: float = -4.0) -> void:
	var stream := get_audio(key)
	if stream == null or sfx_players.is_empty():
		return

	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return

	var fallback := sfx_players[0]
	fallback.stream = stream
	fallback.volume_db = volume_db
	fallback.play()

func _connect_game_manager_signals() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if gm.has_signal("customer_served"):
		gm.customer_served.connect(_on_customer_served)
	if gm.has_signal("upgrade_purchased"):
		gm.upgrade_purchased.connect(_on_upgrade_purchased)
	if gm.has_signal("day_state_changed"):
		gm.day_state_changed.connect(_on_day_state_changed)

func _on_customer_served(_total: int, _sale: int) -> void:
	_play_sfx_internal("cash_register", -3.0)

func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_play_sfx_internal("upgrade", -3.0)

func _on_day_state_changed(new_state: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	if new_state == gm.DayState.OPEN:
		_play_sfx_internal("store_open", -3.0)
	elif new_state == gm.DayState.CLOSING:
		_play_sfx_internal("store_close", -3.0)
