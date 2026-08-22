class_name GameplayUI
extends Control

signal glaze_selected(glaze_data: GlazeData)
signal topping_selected(topping_data: ToppingData)
signal reset_requested()
signal deliver_requested()

const LANDSCAPE_ASPECT_THRESHOLD: float = 1.15

@export_category("Glazes")
@export var strawberry_glaze: GlazeData
@export var chocolate_glaze: GlazeData

@export_category("Toppings")
@export var sprinkles_topping: ToppingData
@export var oreo_topping: ToppingData

@onready var portrait_layout: VBoxContainer = %PortraitLayout
@onready var landscape_layout: HBoxContainer = %LandscapeLayout
@onready var portrait_panel_host: MarginContainer = %PortraitPanelHost
@onready var landscape_panel_host: MarginContainer = %LandscapePanelHost
@onready var controls_panel: PanelContainer = %ControlsPanel

@onready var customer_panel: CustomerPanel = %CustomerPanel as CustomerPanel
@onready var coins_label: Label = %CoinsLabel
@onready var deliver_button: Button = %DeliverButton

@onready var strawberry_button: Button = %StrawberryButton
@onready var chocolate_button: Button = %ChocolateButton
@onready var sprinkles_button: Button = %SprinklesButton
@onready var oreo_button: Button = %OreoButton
@onready var reset_button: Button = %ResetButton

var _is_landscape: bool = false

func _ready() -> void:
	_connect_buttons()
	resized.connect(_update_responsive_layout)
	_update_responsive_layout()

func display_order(order: OrderData) -> void:
	if order == null:
		customer_panel.clear_order()
		customer_panel.visible = false
		deliver_button.disabled = true
		return

	customer_panel.visible = true
	customer_panel.display_order(order)
	deliver_button.disabled = false

func _connect_buttons() -> void:
	strawberry_button.pressed.connect(func(): _emit_glaze(strawberry_glaze))
	chocolate_button.pressed.connect(func(): _emit_glaze(chocolate_glaze))
	sprinkles_button.pressed.connect(func(): _emit_topping(sprinkles_topping))
	oreo_button.pressed.connect(func(): _emit_topping(oreo_topping))
	reset_button.pressed.connect(func(): reset_requested.emit())
	deliver_button.pressed.connect(func(): deliver_requested.emit())

func _update_responsive_layout() -> void:
	if size.y <= 0.0: return
	var should_use_landscape: bool = (size.x / size.y) >= LANDSCAPE_ASPECT_THRESHOLD
	if should_use_landscape == _is_landscape and controls_panel.get_parent() != null: return
	
	_is_landscape = should_use_landscape
	var target_host = landscape_panel_host if _is_landscape else portrait_panel_host
	
	if controls_panel.get_parent() != target_host:
		if controls_panel.get_parent() != null:
			controls_panel.get_parent().remove_child(controls_panel)
		target_host.add_child(controls_panel)
		
	portrait_layout.visible = not _is_landscape
	landscape_layout.visible = _is_landscape

func _emit_glaze(glaze_data: GlazeData) -> void:
	if glaze_data != null: glaze_selected.emit(glaze_data)

func _emit_topping(topping_data: ToppingData) -> void:
	if topping_data != null: topping_selected.emit(topping_data)

func update_coins(amount: int) -> void:
	var safe_amount: int = maxi(amount, 0)
	coins_label.text = "Monedas: %d" % safe_amount

func update_time(time_left: float, time_total: float) -> void:
	customer_panel.update_time(time_left, time_total)
