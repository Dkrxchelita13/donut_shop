extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/menus/main_menu/main_menu.tscn"

func _ready() -> void:
	var platform_manager: PlatformManagerService = (
		get_node("/root/PlatformManager") as PlatformManagerService
	)
	if not platform_manager.is_initialized():
		await platform_manager.platform_ready
	platform_manager.notify_first_frame_ready()

	var save_manager: Node = get_node("/root/SaveManager")
	await save_manager.call(&"load_game")
	_open_main_menu.call_deferred()

func _open_main_menu() -> void:
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error(
			"No se pudo abrir el menú principal. Error: %s" % error_string(error)
		)
