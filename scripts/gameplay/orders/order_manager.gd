class_name OrderManager
extends Node

@export var order_queue: Array[OrderData] = []
var _current_index: int = 0

func has_orders() -> bool:
	for index: int in range(_current_index, order_queue.size()):
		if order_queue[index] != null: return true
	return false

func get_next_order() -> OrderData:
	while _current_index < order_queue.size():
		var order: OrderData = order_queue[_current_index]
		_current_index += 1
		if order != null: return order
	return null
