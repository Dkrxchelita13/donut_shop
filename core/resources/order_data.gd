class_name OrderData
extends Resource

@export var id: StringName = &""
@export var required_glaze: GlazeData = null
@export var required_toppings: Array[ToppingData] = []
@export var time_limit: float = 0.0
@export var customer: CustomerData = null
