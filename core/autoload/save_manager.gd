extends Node

const SAVE_PATH: String = "user://save_data.sav"
const SAVE_VERSION: int = 1
const DEFAULT_TOTAL_COINS: int = 0
const DEFAULT_CURRENT_LEVEL: int = 1

var total_coins: int = DEFAULT_TOTAL_COINS
var current_level: int = DEFAULT_CURRENT_LEVEL

func load_game() -> void:
	_reset_to_defaults()
	var platform_manager: PlatformManagerService = (
		get_node("/root/PlatformManager") as PlatformManagerService
	)
	if not platform_manager.is_initialized():
		await platform_manager.platform_ready

	if platform_manager.is_youtube_playables():
		platform_manager.load_from_cloud()
		var result: Array = await platform_manager.cloud_load_completed
		var data: String = str(result[0])
		var success: bool = bool(result[1])
		if success and not data.is_empty():
			_deserialize_save(data)
		return

	_load_local()

func save_game() -> void:
	var platform_manager: PlatformManagerService = (
		get_node("/root/PlatformManager") as PlatformManagerService
	)
	if platform_manager.is_youtube_playables():
		var data: String = _serialize_save()
		platform_manager.save_to_cloud(data)
		return

	_save_local()

func _load_local() -> void:

	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		save_game()
		return

	if error != OK:
		push_warning(
			"No se pudo cargar el progreso. Error: %s" % error_string(error)
		)
		return

	total_coins = maxi(
		int(config.get_value("progress", "total_coins", DEFAULT_TOTAL_COINS)),
		0
	)
	current_level = maxi(
		int(config.get_value("progress", "current_level", DEFAULT_CURRENT_LEVEL)),
		1
	)

func _save_local() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "total_coins", total_coins)
	config.set_value("progress", "current_level", current_level)

	var error: Error = config.save(SAVE_PATH)
	if error != OK:
		push_error(
			"No se pudo guardar el progreso. Error: %s" % error_string(error)
		)

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	total_coins += amount

func is_glaze_unlocked(glaze_data: GlazeData) -> bool:
	if glaze_data == null:
		return false
	return current_level >= maxi(glaze_data.unlock_level, 1)

func is_topping_unlocked(topping_data: ToppingData) -> bool:
	if topping_data == null:
		return false
	return current_level >= maxi(topping_data.unlock_level, 1)

func _reset_to_defaults() -> void:
	total_coins = DEFAULT_TOTAL_COINS
	current_level = DEFAULT_CURRENT_LEVEL

func _serialize_save() -> String:
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"total_coins": total_coins,
		"current_level": current_level,
	}
	return JSON.stringify(save_data)

func _deserialize_save(data: String) -> bool:
	if data.is_empty():
		return false

	var parsed: Variant = JSON.parse_string(data)
	if not parsed is Dictionary:
		return false

	var save_data: Dictionary = parsed as Dictionary
	total_coins = maxi(
		int(save_data.get("total_coins", DEFAULT_TOTAL_COINS)),
		0
	)
	current_level = maxi(
		int(save_data.get("current_level", DEFAULT_CURRENT_LEVEL)),
		1
	)
	return true
