class_name Gameplay
extends Node

const DONUT_SCENE: PackedScene = preload("res://scenes/gameplay/donut/donut.tscn")
const UNLIMITED_TIME_PERCENTAGE: float = -1.0

@onready var order_manager: OrderManager = $OrderManager as OrderManager
@onready var donut_host: Node3D = $DonutHost
@onready var gameplay_ui: GameplayUI = $InterfaceLayer/GameplayUI as GameplayUI
@onready var donut: Donut = $DonutHost/Donut as Donut

var current_order: OrderData = null
var session_coins: int = 0
var order_time_left: float = 0.0
var order_time_total: float = 0.0
var _delivery_time_percentage: float = UNLIMITED_TIME_PERCENTAGE
var _delivery_in_progress: bool = false

func _ready() -> void:
	if order_manager == null or gameplay_ui == null or donut == null: return
	_connect_ui_signals()
	session_coins = 0
	gameplay_ui.update_coins(session_coins)
	_start_next_order()

func _process(delta: float) -> void:
	if current_order == null:
		return
	if _delivery_in_progress:
		return
	if order_time_total <= 0.0:
		return

	order_time_left = maxf(order_time_left - delta, 0.0)
	gameplay_ui.update_time(order_time_left, order_time_total)

	if order_time_left <= 0.0:
		_on_deliver_requested()

func _connect_ui_signals() -> void:
	gameplay_ui.glaze_selected.connect(_on_glaze_selected)
	gameplay_ui.topping_selected.connect(_on_topping_selected)
	gameplay_ui.reset_requested.connect(_on_reset_requested)
	gameplay_ui.deliver_requested.connect(_on_deliver_requested)

func _start_next_order() -> void:
	if not order_manager.has_orders():
		_finish_day()
		return

	var next_order: OrderData = order_manager.get_next_order()
	if next_order == null:
		_finish_day()
		return

	current_order = next_order
	order_time_total = maxf(current_order.time_limit, 0.0)
	order_time_left = order_time_total
	gameplay_ui.display_order(current_order)
	gameplay_ui.update_time(order_time_left, order_time_total)
	print("[PEDIDO INICIADO] %s" % String(current_order.id))

func _finish_day() -> void:
	current_order = null
	order_time_left = 0.0
	order_time_total = 0.0
	gameplay_ui.update_time(0.0, 0.0)
	gameplay_ui.display_order(null)
	var save_manager: Node = get_node("/root/SaveManager")
	save_manager.call(&"add_coins", session_coins)
	save_manager.call(&"save_game")
	var saved_total_coins: int = int(save_manager.get("total_coins"))
	var summary_template: String = (
		"[FIN DEL DÍA] "
		+ "Ganancia de la sesión: %d | "
		+ "Total guardado: %d"
	)
	print(summary_template % [session_coins, saved_total_coins])

func _on_glaze_selected(glaze_data: GlazeData) -> void:
	if _delivery_in_progress:
		return
	if current_order != null and is_instance_valid(donut): donut.apply_glaze(glaze_data)

func _on_topping_selected(topping_data: ToppingData) -> void:
	if _delivery_in_progress:
		return
	if current_order != null and is_instance_valid(donut): donut.add_topping(topping_data)

func _on_deliver_requested() -> void:
	if _delivery_in_progress:
		return
	if current_order == null:
		return
	if not is_instance_valid(donut):
		return

	if order_time_total > 0.0:
		_delivery_time_percentage = clampf(
			order_time_left / order_time_total,
			0.0,
			1.0
		)
	else:
		_delivery_time_percentage = UNLIMITED_TIME_PERCENTAGE

	_delivery_in_progress = true
	donut.play_delivery_animation(_complete_delivery)

func _complete_delivery() -> void:
	if current_order == null or not is_instance_valid(donut):
		_delivery_in_progress = false
		return

	var accuracy: float = OrderEvaluator.evaluate_order(current_order, donut)
	var payout: int = EconomyCalculator.calculate_order_payout(
		current_order,
		accuracy,
		_delivery_time_percentage
	)

	session_coins += payout
	gameplay_ui.update_coins(session_coins)

	var accuracy_percentage: int = roundi(accuracy * 100.0)
	print("[PEDIDO ENTREGADO] Pedido: %s | Precisión: %d%% | Ganancia: +%d | Total: %d" % [String(current_order.id), accuracy_percentage, payout, session_coins])

	_replace_donut()
	_delivery_in_progress = false
	_delivery_time_percentage = UNLIMITED_TIME_PERCENTAGE

	if order_manager.has_orders():
		_start_next_order()
	else:
		_finish_day()

func _on_reset_requested() -> void:
	if _delivery_in_progress:
		return
	if current_order != null: _replace_donut()

func _replace_donut() -> void:
	var scene_instance: Node = DONUT_SCENE.instantiate()
	if not scene_instance is Donut:
		scene_instance.queue_free()
		return
	
	var new_donut: Donut = scene_instance as Donut
	if is_instance_valid(donut):
		donut_host.remove_child(donut)
		donut.queue_free()
		
	new_donut.name = "Donut"
	donut_host.add_child(new_donut)
	donut = new_donut
