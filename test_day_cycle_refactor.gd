extends SceneTree

var _test_executed: bool = false

func _initialize() -> void:
	print("[TEST] Memulai verifikasi otomatis Day Cycle Fix & Store Management Refactor...")

func _process(_delta: float) -> bool:
	if _test_executed:
		return false
	_test_executed = true

	# 1. Setup GameManager
	var gm = root.get_node_or_null("GameManager")
	if not gm:
		var gm_script = load("res://scripts/autoload/game_manager.gd")
		gm = gm_script.new()
		gm.name = "GameManager"
		root.add_child(gm)

	# Verify Initial DayState & Properties
	if gm.day_state != gm.DayState.PRE_OPEN:
		print("[FAIL] Initial day_state bukan PRE_OPEN")
		quit(1)
		return false

	if gm.current_day != 1 or gm.day_count != 1:
		print("[FAIL] Initial day_count / current_day bukan 1")
		quit(1)
		return false
	print("[PASS] GameManager inisialisasi: Hari 1, DayState PRE_OPEN, jam 08:00")

	# 2. Instantiate Main Scene
	var main_scene = load("res://scenes/shop/Main.tscn")
	if not main_scene:
		print("[FAIL] Gagal load Main.tscn")
		quit(1)
		return false

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	print("[PASS] Main.tscn di-instantiate ke scene tree")

	var status_lbl = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/StatusContainer/StatusLabel")
	var open_btn = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/OpenButton")
	var day_lbl = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/DayContainer/DayLabel")
	var time_lbl = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/TimeContainer/TimeLabel")

	if not status_lbl or not open_btn or not day_lbl or not time_lbl:
		print("[FAIL] Komponen HUD tidak lengkap")
		quit(1)
		return false

	if not open_btn.visible or day_lbl.text != "Hari 1" or time_lbl.text != "08:00":
		print("[FAIL] State awal HUD tidak sinkron")
		quit(1)
		return false
	print("[PASS] State awal HUD sinkron: Hari 1, 08:00, Tombol Buka Toko tampil")

	# 3. Test Store Opening (PRE_OPEN -> OPEN)
	var opened = gm.open_store()
	if not opened or gm.day_state != gm.DayState.OPEN:
		print("[FAIL] Gagal membuka toko")
		quit(1)
		return false

	if open_btn.visible:
		print("[FAIL] Tombol Buka Toko masih terlihat saat toko OPEN")
		quit(1)
		return false
	print("[PASS] Toko berhasil dibuka: State OPEN, tombol buka toko tersembunyi")

	# 4. Test Store Closing (OPEN -> CLOSING)
	gm.set_closing()
	if gm.day_state != gm.DayState.CLOSING:
		print("[FAIL] Gagal beralih ke state CLOSING")
		quit(1)
		return false
	print("[PASS] Toko beralih ke state CLOSING (spawner dihentikan)")

	# 5. Test Transition to SUMMARY (CLOSING -> SUMMARY)
	gm.check_closing_completion(0)
	if gm.day_state != gm.DayState.SUMMARY:
		print("[FAIL] Gagal beralih ke state SUMMARY setelah pelanggan habis")
		quit(1)
		return false
	print("[PASS] Toko beralih ke state SUMMARY setelah pelanggan habis")

	# 6. Test Next Day Progression (SUMMARY -> PRE_OPEN on Day 2)
	gm.next_day()
	if gm.current_day != 2 or gm.day_count != 2:
		print("[FAIL] current_day / day_count tidak bertambah ke 2")
		quit(1)
		return false

	if gm.day_state != gm.DayState.PRE_OPEN:
		print("[FAIL] day_state tidak kembali ke PRE_OPEN setelah next_day()")
		quit(1)
		return false

	if gm.day_time != 0.0 or gm.daily_revenue != 0:
		print("[FAIL] Waktu atau metrik harian tidak ter-reset")
		quit(1)
		return false

	if day_lbl.text != "Hari 2" or time_lbl.text != "08:00":
		print("[FAIL] HUD tidak ter-update ke Hari 2, 08:00")
		quit(1)
		return false

	if not open_btn.visible:
		print("[FAIL] Tombol Buka Toko tidak muncul kembali di Hari 2")
		quit(1)
		return false
	print("[PASS] Siklus pergantian hari SUKSES: current_day=2, jam=08:00, state=PRE_OPEN, HUD ter-update!")

	# 7. Test Opening Store on Day 2
	var opened_day2 = gm.open_store()
	if not opened_day2 or gm.day_state != gm.DayState.OPEN:
		print("[FAIL] Gagal membuka toko di Hari 2")
		quit(1)
		return false
	print("[PASS] Pembukaan toko di Hari 2 SUKSES 100%!")

	print("[PASS] SELURUH PENGUJIAN DAY CYCLE FIX BERHASIL!")
	quit(0)
	return false
