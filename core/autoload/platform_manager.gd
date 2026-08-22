class_name PlatformManagerService
extends Node

signal platform_ready(platform_id: StringName)
signal cloud_load_completed(data: String, success: bool)
signal cloud_save_completed(success: bool)

var _adapter: PlatformAdapter = null
var _platform_id: StringName = &"unknown"
var _initialized: bool = false
var _cloud_loaded_once: bool = false

func _ready() -> void:
	_activate_adapter(_select_adapter())

func is_initialized() -> bool:
	return _initialized

func get_platform_id() -> StringName:
	return _platform_id

func is_youtube_playables() -> bool:
	return _platform_id == &"youtube_playables"

func load_from_cloud() -> void:
	if not _initialized or _adapter == null:
		cloud_load_completed.emit("", false)
		return
	_adapter.load_from_cloud()

func save_to_cloud(data: String) -> void:
	if not _initialized or _adapter == null:
		cloud_save_completed.emit(false)
		return
	if is_youtube_playables() and not _cloud_loaded_once:
		cloud_save_completed.emit(false)
		return
	_adapter.save_to_cloud(data)

func notify_first_frame_ready() -> void:
	if _initialized and _adapter != null:
		_adapter.notify_first_frame_ready()

func notify_game_ready() -> void:
	if _initialized and _adapter != null:
		_adapter.notify_game_ready()

func _select_adapter() -> PlatformAdapter:
	if OS.has_feature("youtube_playables"):
		return YouTubeAdapter.new()

	if OS.has_feature("web"):
		var in_playables_environment: bool = bool(JavaScriptBridge.eval(
			"typeof ytgame !== 'undefined' "
			+ "&& ytgame.IN_PLAYABLES_ENV === true",
			true
		))
		if in_playables_environment:
			return YouTubeAdapter.new()

	return WebAdapter.new()

func _activate_adapter(adapter: PlatformAdapter) -> void:
	if _adapter != null:
		_adapter.queue_free()

	_adapter = adapter
	_initialized = false
	_cloud_loaded_once = false
	add_child(_adapter)
	_adapter.adapter_ready.connect(_on_adapter_ready)
	_adapter.cloud_load_completed.connect(_on_cloud_load_completed)
	_adapter.cloud_save_completed.connect(_on_cloud_save_completed)
	_adapter.initialize()

func _on_adapter_ready(success: bool) -> void:
	if not success:
		if _adapter is YouTubeAdapter:
			_fallback_to_web.call_deferred()
		else:
			platform_ready.emit(&"unknown")
		return

	_platform_id = _adapter.get_platform_id()
	_initialized = true
	platform_ready.emit(_platform_id)

func _fallback_to_web() -> void:
	_activate_adapter(WebAdapter.new())

func _on_cloud_load_completed(data: String, success: bool) -> void:
	if success:
		_cloud_loaded_once = true
	cloud_load_completed.emit(data, success)

func _on_cloud_save_completed(success: bool) -> void:
	cloud_save_completed.emit(success)
