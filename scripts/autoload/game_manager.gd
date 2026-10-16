extends Node

## Mini Shop - Global Game, Economy, Day Cycle & Upgrade Manager
## Manages economy, Pre-Open Preparation phase, carry capacity, automated cashier NPC, and day summaries.

enum DayState {
	PRE_OPEN,
	OPEN,
	CLOSING,
	SUMMARY,
	CLOSED = 3
}

signal money_changed(new_amount: int)
signal customer_served(total_count: int, sale_amount: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal time_updated(hour: int, minute: int, time_str: String)
signal day_state_changed(new_state: DayState)
signal day_ended(day_number: int, stats: Dictionary)
signal new_day_started(day_number: int)
signal reputation_changed(rating: float)
signal carry_capacity_changed(new_capacity: int)
signal cashier_hired_changed(is_hired: bool, speed_level: int)

# Economy
var money: int = 50
var total_served: int = 0
var total_revenue: int = 0

# Upgrade System
var speed_level: int = 0          # 0 = normal (210), 1 = boosted (285)
var capacity_level: int = 0       # 0 = normal (5), 1 = expanded (8)
var carry_level: int = 1          # 1 = 2 items, 2 = 4 items, 3 = 6 items
var has_cashier_npc: bool = false # Automated cashier helper
var cashier_speed_level: int = 1  # 1 = slow (2.5s), 2 = medium (1.4s), 3 = fast (0.5s)

const SPEED_UPGRADE_COST: int = 40
const CAPACITY_UPGRADE_COST: int = 60
const CARRY_UPGRADE_COSTS := {2: 50, 3: 80}
const CARRY_CAPACITIES := {1: 2, 2: 4, 3: 6}

const CASHIER_HIRE_COST: int = 75
const CASHIER_DAILY_WAGE: int = 15
const CASHIER_SPEED_COSTS := {2: 45, 3: 70}

# Wholesale restock costs
const WHOLESALE_PRICES := {
	"soda": 5,
	"snack": 6,
	"apple": 3
}

# Day Cycle (08:00 to 21:00 = 13 Store Hours = 780 minutes)
@export var day_duration: float = 65.0
var current_day: int = 1
var day_count: int:
	get:
		return current_day
	set(value):
		current_day = value

var day_time: float = 0.0
var day_state: DayState = DayState.PRE_OPEN
var closing_timer: float = 0.0

# Daily Performance Metrics
var daily_revenue: int = 0
var daily_expenses: int = 0
var daily_wages: int = 0
var daily_served: int = 0
var satisfied_customers: int = 0
var unsatisfied_customers: int = 0
var bonus_reputation: float = 0.0

func _ready() -> void:
	emit_signal("money_changed", money)
	emit_signal("reputation_changed", get_reputation_rating())
	emit_signal("carry_capacity_changed", get_carry_capacity())
	emit_signal("day_state_changed", day_state)
	_emit_current_time()

func _process(delta: float) -> void:
	if day_state == DayState.OPEN:
		day_time += delta
		_emit_current_time()

		if day_time >= day_duration:
			set_closing()

	elif day_state == DayState.CLOSING:
		closing_timer += delta
		_evaluate_closing_state()

func _evaluate_closing_state() -> void:
	var active_customers := 0
	for node in get_tree().get_nodes_in_group("customers"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			active_customers += 1

	# Transition to SUMMARY when all customers left, or upon 15.0s fail-safe timeout
	if active_customers == 0 or closing_timer >= 15.0:
		if closing_timer >= 15.0 and active_customers > 0:
			for node in get_tree().get_nodes_in_group("customers"):
				if is_instance_valid(node) and not node.is_queued_for_deletion():
					node.queue_free()
		_end_day()

func _emit_current_time() -> void:
	if day_state == DayState.PRE_OPEN:
		emit_signal("time_updated", 8, 0, "08:00")
		return

	var progress := clampf(day_time / day_duration, 0.0, 1.0)
	var total_store_minutes := int(progress * 780.0) # 08:00 to 21:00
	var hour := 8 + int(total_store_minutes / 60)
	var minute := total_store_minutes % 60
	var time_str := "%02d:%02d" % [hour, minute]
	emit_signal("time_updated", hour, minute, time_str)

func open_store() -> bool:
	if day_state == DayState.PRE_OPEN:
		day_state = DayState.OPEN
		emit_signal("day_state_changed", day_state)
		return true
	return false

func set_closing() -> void:
	if day_state == DayState.OPEN:
		day_state = DayState.CLOSING
		closing_timer = 0.0
		emit_signal("day_state_changed", day_state)

func check_closing_completion(active_customers: int) -> void:
	if day_state == DayState.CLOSING and active_customers == 0:
		_end_day()

func _end_day() -> void:
	day_state = DayState.SUMMARY
	emit_signal("day_state_changed", day_state)

	# Deduct employee wages if cashier is hired
	daily_wages = CASHIER_DAILY_WAGE if has_cashier_npc else 0
	if daily_wages > 0:
		money = maxi(0, money - daily_wages)
		emit_signal("money_changed", money)

	var stats := {
		"day": current_day,
		"revenue": daily_revenue,
		"expenses": daily_expenses,
		"wages": daily_wages,
		"profit": daily_revenue - daily_expenses - daily_wages,
		"served": daily_served,
		"missed": unsatisfied_customers,
		"reputation": get_reputation_rating(),
		"ending_balance": money,
		"has_cashier": has_cashier_npc
	}
	emit_signal("day_ended", current_day, stats)

## Core Day Cycle Reset & Advance
func next_day() -> void:
	current_day += 1
	day_time = 0.0
	daily_revenue = 0
	daily_expenses = 0
	daily_wages = 0
	daily_served = 0
	unsatisfied_customers = 0
	bonus_reputation = 0.0
	closing_timer = 0.0
	day_state = DayState.PRE_OPEN

	emit_signal("new_day_started", current_day)
	emit_signal("day_state_changed", day_state)
	_emit_current_time()

## Alias for backward compatibility
func start_next_day() -> void:
	next_day()

func get_reputation_rating() -> float:
	var total := satisfied_customers + unsatisfied_customers
	var base_score := 5.0
	if total > 0:
		var ratio := float(satisfied_customers) / float(total)
		base_score = ratio * 5.0
	return snappedf(clampf(base_score + bonus_reputation, 1.0, 5.0), 0.1)

func add_reputation_bonus(bonus: float) -> void:
	bonus_reputation += bonus
	emit_signal("reputation_changed", get_reputation_rating())

func add_money(amount: int) -> void:
	money += amount
	total_revenue += amount
	emit_signal("money_changed", money)

func can_afford(amount: int) -> bool:
	return money >= amount

func spend_money(amount: int) -> bool:
	if can_afford(amount):
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false

func record_checkout(sale_price: int) -> void:
	total_served += 1
	daily_served += 1
	daily_revenue += sale_price
	satisfied_customers += 1
	add_money(sale_price)
	emit_signal("customer_served", total_served, sale_price)
	emit_signal("reputation_changed", get_reputation_rating())

func record_wholesale_purchase(cost: int) -> void:
	daily_expenses += cost

func record_unsatisfied_customer() -> void:
	unsatisfied_customers += 1
	emit_signal("reputation_changed", get_reputation_rating())

func get_wholesale_price(item_id: String) -> int:
	return WHOLESALE_PRICES.get(item_id, 5)

func get_carry_capacity() -> int:
	return CARRY_CAPACITIES.get(carry_level, 2)

func buy_speed_upgrade() -> bool:
	if speed_level >= 1:
		return false
	if spend_money(SPEED_UPGRADE_COST):
		speed_level = 1
		emit_signal("upgrade_purchased", "speed", speed_level)
		return true
	return false

func buy_capacity_upgrade() -> bool:
	if capacity_level >= 1:
		return false
	if spend_money(CAPACITY_UPGRADE_COST):
		capacity_level = 1
		emit_signal("upgrade_purchased", "capacity", capacity_level)
		return true
	return false

func buy_carry_capacity_upgrade() -> bool:
	var next_level := carry_level + 1
	if next_level > 3:
		return false
	var cost: int = CARRY_UPGRADE_COSTS.get(next_level, 50)
	if spend_money(cost):
		carry_level = next_level
		emit_signal("carry_capacity_changed", get_carry_capacity())
		emit_signal("upgrade_purchased", "carry_capacity", carry_level)
		return true
	return false

func hire_cashier_npc() -> bool:
	if has_cashier_npc:
		return false
	if spend_money(CASHIER_HIRE_COST):
		has_cashier_npc = true
		cashier_speed_level = 1
		emit_signal("cashier_hired_changed", has_cashier_npc, cashier_speed_level)
		emit_signal("upgrade_purchased", "hire_cashier", 1)
		return true
	return false

func upgrade_cashier_speed() -> bool:
	if not has_cashier_npc:
		return false
	var next_level := cashier_speed_level + 1
	if next_level > 3:
		return false
	var cost: int = CASHIER_SPEED_COSTS.get(next_level, 45)
	if spend_money(cost):
		cashier_speed_level = next_level
		emit_signal("cashier_hired_changed", has_cashier_npc, cashier_speed_level)
		emit_signal("upgrade_purchased", "cashier_speed", cashier_speed_level)
		return true
	return false

func get_cashier_process_duration() -> float:
	match cashier_speed_level:
		1:
			return 2.5
		2:
			return 1.4
		3:
			return 0.5
		_:
			return 2.5
