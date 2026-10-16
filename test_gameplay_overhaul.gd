extends SceneTree

func _init() -> void:
	print("[TEST] Memulai verifikasi otomatis Gameplay Overhaul & Pre-Open Cycle...")

	# 1. Verify GameManager & Initial DayState
	var gm = root.get_node_or_null("/root/GameManager")
	if not gm:
		# If running standalone SceneTree without autoload, load GameManager
		var gm_script = load("res://scripts/autoload/game_manager.gd")
		gm = gm_script.new()
		gm.name = "GameManager"
		root.add_child(gm)

	if gm.day_state != gm.DayState.PRE_OPEN:
		print("[FAIL] Initial day_state bukan PRE_OPEN")
		quit(1)
		return
	print("[PASS] GameManager DayState awal terverifikasi PRE_OPEN (Toko Tutup)")

	# 2. Verify Carry Capacity Default
	if gm.get_carry_capacity() != 2:
		print("[FAIL] Default carry capacity bukan 2")
		quit(1)
		return
	print("[PASS] Kapasitas bawaan awal terverifikasi 2 barang")

	# 3. Verify Carry Capacity Upgrade
	gm.add_money(200)
	var up_carry1 = gm.buy_carry_capacity_upgrade()
	if not up_carry1 or gm.get_carry_capacity() != 4:
		print("[FAIL] Gagal upgrade carry capacity ke level 2 (4 barang)")
		quit(1)
		return
	print("[PASS] Upgrade kapasitas tas ke level 2 (4 barang) sukses")

	var up_carry2 = gm.buy_carry_capacity_upgrade()
	if not up_carry2 or gm.get_carry_capacity() != 6:
		print("[FAIL] Gagal upgrade carry capacity ke level 3 (6 barang)")
		quit(1)
		return
	print("[PASS] Upgrade kapasitas tas ke level 3 (6 barang) sukses")

	# 4. Verify Cashier Helper Hire & Speed Upgrade
	if gm.has_cashier_npc:
		print("[FAIL] has_cashier_npc sudah true sebelum direkrut")
		quit(1)
		return

	var hire_success = gm.hire_cashier_npc()
	if not hire_success or not gm.has_cashier_npc or gm.cashier_speed_level != 1:
		print("[FAIL] Gagal merekrut karyawan kasir")
		quit(1)
		return
	print("[PASS] Perekrutan karyawan kasir sukses (Level 1, kecepatan awal 2.5s)")

	var up_speed1 = gm.upgrade_cashier_speed()
	if not up_speed1 or gm.cashier_speed_level != 2:
		print("[FAIL] Gagal upgrade kecepatan kasir ke level 2")
		quit(1)
		return
	print("[PASS] Upgrade kecepatan kasir ke level 2 sukses (1.4s)")

	# 5. Verify Main scene instantiation and HUD nodes
	var main_scene = load("res://scenes/shop/Main.tscn")
	if not main_scene:
		print("[FAIL] Gagal memuat Main.tscn")
		quit(1)
		return

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	print("[PASS] Main.tscn berhasil di-instantiate")

	# Verify OpenButton & StatusLabel
	var open_btn = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/OpenButton")
	var status_lbl = main_inst.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/StatusContainer/StatusLabel")
	if not open_btn or not status_lbl:
		print("[FAIL] OpenButton atau StatusLabel tidak ditemukan di HUD")
		quit(1)
		return

	if not open_btn.visible or status_lbl.text != "PERSIAPAN":
		print("[FAIL] StatusLabel bukan PERSIAPAN atau OpenButton tidak tampil saat PRE_OPEN")
		quit(1)
		return
	print("[PASS] HUD status PERSIAPAN dan tombol Buka Toko terverifikasi tampil saat toko tutup")

	# 6. Verify Store Opening Trigger
	var opened = gm.open_store()
	if not opened or gm.day_state != gm.DayState.OPEN:
		print("[FAIL] Gagal membuka toko via gm.open_store()")
		quit(1)
		return
	print("[PASS] Mekanisme buka toko (PRE_OPEN -> OPEN) terverifikasi sukses")

	# 7. Verify Player Multi-Item Carry logic
	var player = main_inst.get_node_or_null("Player")
	if not player:
		print("[FAIL] Player tidak ditemukan di Main.tscn")
		quit(1)
		return

	player.held_items.clear()
	var test_item1 = {"id": "soda", "name": "Soda Kaleng", "price": 12}
	var test_item2 = {"id": "apple", "name": "Apel Segar", "price": 8}
	player.pick_up_item(test_item1)
	player.pick_up_item(test_item2)

	if player.held_items.size() != 2:
		print("[FAIL] Player held_items tidak menyimpan 2 item")
		quit(1)
		return

	if not player.has_item("soda") or not player.has_item("apple"):
		print("[FAIL] Player has_item gagal mengenali item dalam tas")
		quit(1)
		return

	var popped = player.pop_item("soda")
	if popped.get("id") != "soda" or player.held_items.size() != 1:
		print("[FAIL] Player pop_item gagal mengeluarkan soda secara tepat")
		quit(1)
		return
	print("[PASS] Sistem tas bawaan multi-item player (pick up, search, pop) terverifikasi 100%")

	# 8. Verify Automated Cashier Helper processing
	var cashier = main_inst.get_node_or_null("CashierCounter")
	if not cashier:
		print("[FAIL] CashierCounter tidak ditemukan di Main.tscn")
		quit(1)
		return

	if not cashier.has_cashier_npc:
		print("[FAIL] CashierCounter has_cashier_npc tidak sinkron dengan GameManager")
		quit(1)
		return
	print("[PASS] Karyawan kasir otomatis terverifikasi aktif pada kounter kasir")

	print("[PASS] SELURUH PENGUJIAN GAMEPLAY OVERHAUL BERHASIL 100%!")
	quit(0)
