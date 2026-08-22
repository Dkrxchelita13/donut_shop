class_name WebAdapter
extends PlatformAdapter

const PLATFORM_DATA_PATH: String = "user://platform_data.json"

func get_platform_id() -> StringName:
	return &"web"

func save_to_cloud(data: String) -> void:
	var file: FileAccess = FileAccess.open(PLATFORM_DATA_PATH, FileAccess.WRITE)
	if file == null:
		cloud_save_completed.emit(false)
		return
	file.store_string(data)
	file.close()
	cloud_save_completed.emit(true)

func load_from_cloud() -> void:
	if not FileAccess.file_exists(PLATFORM_DATA_PATH):
		cloud_load_completed.emit("", true)
		return

	var file: FileAccess = FileAccess.open(PLATFORM_DATA_PATH, FileAccess.READ)
	if file == null:
		cloud_load_completed.emit("", false)
		return
	var data: String = file.get_as_text()
	file.close()
	cloud_load_completed.emit(data, true)
