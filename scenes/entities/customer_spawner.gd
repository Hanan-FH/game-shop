extends Node2D
class_name CustomerSpawner

## Mini Shop - Customer Spawner
## Manages dynamic customer traffic density based on store operating state (Pre-Open, Open, Closing).

signal customer_count_changed(active: int, max_cap: int)

const CustomerScene = preload("res://scenes/entities/Customer.tscn")

@export var base_spawn_interval: float = 4.5
@export var spawn_enabled: bool = true

var spawn_timer: float = 0.0

@onready var customers_container: Node2D = $CustomersContainer

var shelves_list: Array = []
var cashier_counter: Node2D = null

func _ready() -> void:
	spawn_timer = 1.5
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.new_day_started.connect(_on_new_day_started)

func _on_new_day_started(_day: int) -> void:
	spawn_timer = 1.5
	if customers_container:
		for child in customers_container.get_children():
			if is_instance_valid(child):
				child.queue_free()

func configure(shelves: Array, counter: Node2D) -> void:
	shelves_list = shelves
	cashier_counter = counter

func get_max_customers() -> int:
	var gm = get_node_or_null("/root/GameManager")
	var day: int = gm.current_day if gm else 1
	return clampi(3 + day, 4, 8)

func get_active_customer_count() -> int:
	if not customers_container:
		return 0
	var count := 0
	for child in customers_container.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			count += 1
	return count

func _process(delta: float) -> void:
	var active_count := get_active_customer_count()
	var max_cap := get_max_customers()
	emit_signal("customer_count_changed", active_count, max_cap)

	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	# Handle closing phase completion: when all active customers have left, finalize day
	if gm.day_state == gm.DayState.CLOSING:
		gm.check_closing_completion(active_count)
		return

	if not spawn_enabled or gm.day_state != gm.DayState.OPEN:
		return

	var current_interval := maxf(2.8, base_spawn_interval - (float(gm.current_day) * 0.25))

	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_try_spawn_customer()

func _try_spawn_customer() -> void:
	if not customers_container:
		return

	var current_customers := get_active_customer_count()
	if current_customers >= get_max_customers():
		return

	var new_customer = CustomerScene.instantiate()
	new_customer.global_position = Vector2(576.0, 565.0)
	customers_container.add_child(new_customer)
	new_customer.setup(shelves_list, cashier_counter)
