extends CanvasLayer
class_name DaySummaryModal

## Mini Shop - End-of-Day Summary Modal Overlay
## Displays daily performance, revenue, wholesale costs, employee wages, satisfaction rating, and next-day progression.

@onready var modal_panel: PanelContainer = $CenterContainer/ModalPanel
@onready var day_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/HeaderBox/DayLabel
@onready var revenue_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/RevenueRow/Value
@onready var expenses_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/ExpensesRow/Value
@onready var wages_row: HBoxContainer = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/WagesRow
@onready var wages_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/WagesRow/Value
@onready var profit_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/ProfitRow/Value
@onready var served_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/ServedRow/Value
@onready var missed_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/MissedRow/Value
@onready var rating_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/RatingRow/Value
@onready var balance_label: Label = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/StatsBox/BalanceRow/Value
@onready var next_day_button: Button = $CenterContainer/ModalPanel/MarginContainer/VBoxContainer/NextDayButton

func _ready() -> void:
	visible = false
	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_pressed)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.day_ended.connect(_on_day_ended)

func _on_day_ended(day_number: int, stats: Dictionary) -> void:
	if day_label:
		day_label.text = "Hari Ke-" + str(day_number) + " Telah Ditutup (21:00)"
	
	if revenue_label:
		revenue_label.text = "+$" + str(stats.get("revenue", 0))
	if expenses_label:
		expenses_label.text = "-$" + str(stats.get("expenses", 0))

	var wages: int = stats.get("wages", 0)
	if wages_row and wages_label:
		wages_row.visible = wages > 0
		wages_label.text = "-$" + str(wages)
	
	var profit: int = stats.get("profit", 0)
	if profit_label:
		profit_label.text = ("+$" if profit >= 0 else "-$") + str(abs(profit))
		profit_label.set("theme_override_colors/font_color", Color(0.4, 0.95, 0.6) if profit >= 0 else Color(0.95, 0.45, 0.45))
	
	if served_label:
		served_label.text = str(stats.get("served", 0)) + " orang"
	if missed_label:
		missed_label.text = str(stats.get("missed", 0)) + " orang"
	if rating_label:
		var rep: float = stats.get("reputation", 5.0)
		rating_label.text = str(rep) + " / 5.0"
	if balance_label:
		balance_label.text = "$" + str(stats.get("ending_balance", 0))

	if next_day_button:
		next_day_button.text = "Lanjut ke Hari Ke-" + str(day_number + 1) + " (Fase Persiapan)"

	visible = true
	if modal_panel:
		modal_panel.scale = Vector2(0.85, 0.85)
		var tween := create_tween()
		tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_next_day_pressed() -> void:
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_method("next_day"):
			gm.next_day()
		elif gm.has_method("start_next_day"):
			gm.start_next_day()
