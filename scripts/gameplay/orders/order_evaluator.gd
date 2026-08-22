class_name OrderEvaluator
extends RefCounted

const GLAZE_WEIGHT: float = 0.30
const TOPPINGS_WEIGHT: float = 0.70

static func evaluate_order(order: OrderData, donut_state: Donut) -> float:
	if order == null or donut_state == null: return 0.0
	
	var accuracy: float = 0.0
	if _glaze_matches(order.required_glaze, donut_state.current_glaze):
		accuracy += GLAZE_WEIGHT
		
	if _toppings_match_exactly(order.required_toppings, donut_state.applied_toppings):
		accuracy += TOPPINGS_WEIGHT
		
	return clampf(accuracy, 0.0, 1.0)

static func _glaze_matches(required: GlazeData, applied: GlazeData) -> bool:
	if required == null: return applied == null
	if applied == null or required.id == &"" or applied.id == &"": return false
	return required.id == applied.id

static func _toppings_match_exactly(required: Array[ToppingData], applied: Array[ToppingData]) -> bool:
	var required_ids: Array[StringName] = _get_unique_topping_ids(required)
	var applied_ids: Array[StringName] = _get_unique_topping_ids(applied)
	
	if required_ids.size() != applied_ids.size(): return false
	for topping_id: StringName in required_ids:
		if not applied_ids.has(topping_id): return false
	return true

static func _get_unique_topping_ids(toppings: Array[ToppingData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for topping: ToppingData in toppings:
		if topping != null and topping.id != &"" and not ids.has(topping.id):
			ids.append(topping.id)
	return ids
