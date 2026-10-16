extends SceneTree

func _init() -> void:
	print("[TEST] Memulai verifikasi otomatis Feature Expansion & Bug Fix...")
	
	# Load and instance Main
	var main_scene = load("res://scenes/shop/Main.tscn")
	if not main_scene:
		print("[FAIL] Gagal memuat Main.tscn")
		quit(1)
		return
	
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	print("[PASS] Main.tscn berhasil di-instantiate ke scene tree")

	# Verify Bench
	var bench = main_instance.get_node_or_null("Bench")
	if not bench:
		print("[FAIL] Node Bench tidak ditemukan di Main.tscn")
		quit(1)
		return
	print("[PASS] Node Bench ditemukan pada koordinat: ", bench.position)

	# Verify Customer HUD counter
	var cust_label = main_instance.get_node_or_null("UI/HUDMargin/PanelContainer/HBoxContainer/CustomerContainer/CustomerLabel")
	if not cust_label:
		print("[FAIL] CustomerLabel tidak ditemukan di HUD")
		quit(1)
		return
	print("[PASS] CustomerLabel HUD aktif: ", cust_label.text)

	# Verify Customer variations
	var cust_scene = load("res://scenes/entities/Customer.tscn")
	var cust1 = cust_scene.instantiate()
	main_instance.add_child(cust1)
	cust1.set_customer_type(cust1.CustomerType.REGULAR)

	var cust2 = cust_scene.instantiate()
	main_instance.add_child(cust2)
	cust2.set_customer_type(cust2.CustomerType.IMPATIENT)

	var cust3 = cust_scene.instantiate()
	main_instance.add_child(cust3)
	cust3.set_customer_type(cust3.CustomerType.VIP)

	if cust1.move_speed != 130.0 or cust2.move_speed != 175.0 or cust3.move_speed != 105.0:
		print("[FAIL] Kecepatan variasi pelanggan tidak sesuai")
		quit(1)
		return
	print("[PASS] Kecepatan variasi pelanggan terverifikasi (Regular: 130, Impatient: 175, VIP: 105)")

	# Verify Bench Comfort
	cust1.set_near_bench(true)
	if not cust1.is_near_bench:
		print("[FAIL] is_near_bench tidak bernilai true")
		quit(1)
		return
	cust1.set_near_bench(false)
	if cust1.is_near_bench:
		print("[FAIL] is_near_bench tidak bernilai false")
		quit(1)
		return
	print("[PASS] Pengaruh bangku tunggu (is_near_bench toggle) terverifikasi")

	# Verify Customer Despawn on doorway
	cust1.current_state = cust1.State.LEAVING
	cust1.current_destination = cust1.EXIT_POINT
	cust1.global_position = Vector2(576.0, 600.0)
	cust1._physics_process(0.1)
	if not cust1.is_queued_for_deletion():
		print("[FAIL] Customer di ambang pintu keluar Y>=595 tidak melakukan queue_free")
		quit(1)
		return
	print("[PASS] Despawn pintu keluar (threshold Y>=595) terverifikasi berjalan lancar")

	# Verify Cashier Queue Spacing
	var cashier = main_instance.get_node_or_null("CashierCounter")
	if not cashier:
		print("[FAIL] CashierCounter tidak ditemukan di Main.tscn")
		quit(1)
		return
	if cashier.QUEUE_SPACING != 48.0:
		print("[FAIL] Cashier QUEUE_SPACING tidak 48.0")
		quit(1)
		return
	print("[PASS] Jarak antrean kasir (QUEUE_SPACING = 48.0) terverifikasi rapi")

	print("[PASS] SELURUH PENGUJIAN OTOMATIS BERHASIL 100%!")
	quit(0)
