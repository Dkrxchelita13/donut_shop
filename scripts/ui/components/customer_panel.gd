class_name CustomerPanel
extends PanelContainer

const INGREDIENT_ICON_SIZE: Vector2 = Vector2(44.0, 44.0)

@onready var portrait: TextureRect = %Portrait
@onready var ingredient_grid: GridContainer = %IngredientGrid
@onready var patience_bar: ProgressBar = %PatienceBar

func display_order(order: OrderData) -> void:
	clear_order()

	if order == null:
		visible = false
		return

	visible = true
	if order.customer != null and order.customer.portrait != null:
		portrait.texture = order.customer.portrait

	if order.required_glaze != null:
		_add_ingredient_icon(
			order.required_glaze.icon,
			order.required_glaze.display_name
		)

	for topping: ToppingData in order.required_toppings:
		if topping == null:
			continue
		_add_ingredient_icon(topping.icon, topping.display_name)

func clear_order() -> void:
	portrait.texture = null
	patience_bar.visible = false
	patience_bar.value = 1.0
	for child: Node in ingredient_grid.get_children():
		ingredient_grid.remove_child(child)
		child.queue_free()

func update_time(time_left: float, time_total: float) -> void:
	if time_total <= 0.0:
		patience_bar.visible = false
		patience_bar.value = 1.0
		return

	patience_bar.visible = true
	var percentage: float = clampf(time_left / time_total, 0.0, 1.0)
	patience_bar.value = percentage

func _add_ingredient_icon(texture: Texture2D, accessible_name: String) -> void:
	if texture == null:
		return

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = INGREDIENT_ICON_SIZE
	icon_rect.texture = texture
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.tooltip_text = accessible_name
	ingredient_grid.add_child(icon_rect)
