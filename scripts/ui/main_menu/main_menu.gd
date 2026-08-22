class_name MainMenu
extends Control

const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay/gameplay.tscn"

@onready var coins_label: Label = %CoinsLabel
@onready var level_label: Label = %LevelLabel
@onready var start_button: Button = %StartButton
@onready var save_manager: Node = get_node("/root/SaveManager")
@onready var platform_manager: PlatformManagerService = (
	get_node("/root/PlatformManager") as PlatformManagerService
)

func _ready() -> void:
	_refresh_progress()
	start_button.pressed.connect(_on_start_pressed)
	platform_manager.notify_game_ready()

func _refresh_progress() -> void:
	var total_coins: int = int(save_manager.get("total_coins"))
	var current_level: int = int(save_manager.get("current_level"))
	coins_label.text = "Monedas: %d" % total_coins
	level_label.text = "Nivel: %d" % current_level

func _on_start_pressed() -> void:
	start_button.disabled = true
	var error: Error = get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)
	if error != OK:
		start_button.disabled = false
		push_error(
			"No se pudo iniciar Gameplay. Error: %s" % error_string(error)
		)
