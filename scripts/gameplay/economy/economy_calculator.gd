class_name EconomyCalculator
extends RefCounted

const FAST_MULTIPLIER: float = 1.20
const NORMAL_MULTIPLIER: float = 1.00
const SLOW_MULTIPLIER: float = 0.50

static func calculate_order_payout(
	order: OrderData,
	accuracy: float,
	time_percentage: float
) -> int:
	if order == null:
		return 0

	var safe_accuracy: float = clampf(accuracy, 0.0, 1.0)
	if is_zero_approx(safe_accuracy):
		return 0

	var base_value: int = 0
	if order.required_glaze != null:
		base_value += order.required_glaze.base_price

	for topping: ToppingData in order.required_toppings:
		if topping != null:
			base_value += topping.base_price

	var time_multiplier: float = NORMAL_MULTIPLIER
	if time_percentage >= 0.0:
		var safe_time_percentage: float = clampf(time_percentage, 0.0, 1.0)
		if safe_time_percentage > 0.50:
			time_multiplier = FAST_MULTIPLIER
		elif safe_time_percentage <= 0.20:
			time_multiplier = SLOW_MULTIPLIER

	return roundi(float(base_value) * safe_accuracy * time_multiplier)
