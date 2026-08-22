class_name YouTubeAdapter
extends PlatformAdapter

var _ytgame: JavaScriptObject = null
var _load_success_callback: JavaScriptObject = null
var _load_error_callback: JavaScriptObject = null
var _save_success_callback: JavaScriptObject = null
var _save_error_callback: JavaScriptObject = null

func initialize() -> void:
	if not OS.has_feature("web"):
		adapter_ready.emit(false)
		return

	_ytgame = JavaScriptBridge.get_interface("ytgame")
	if _ytgame == null:
		adapter_ready.emit(false)
		return

	_load_success_callback = JavaScriptBridge.create_callback(_on_load_success)
	_load_error_callback = JavaScriptBridge.create_callback(_on_load_error)
	_save_success_callback = JavaScriptBridge.create_callback(_on_save_success)
	_save_error_callback = JavaScriptBridge.create_callback(_on_save_error)
	adapter_ready.emit(true)

func get_platform_id() -> StringName:
	return &"youtube_playables"

func load_from_cloud() -> void:
	if _ytgame == null:
		cloud_load_completed.emit("", false)
		return
	var promise: JavaScriptObject = _ytgame.game.loadData()
	promise.then(_load_success_callback, _load_error_callback)

func save_to_cloud(data: String) -> void:
	if _ytgame == null:
		cloud_save_completed.emit(false)
		return
	var promise: JavaScriptObject = _ytgame.game.saveData(data)
	promise.then(_save_success_callback, _save_error_callback)

func notify_first_frame_ready() -> void:
	if _ytgame == null:
		return
	JavaScriptBridge.eval(
		"if (typeof ytgame !== 'undefined' && "
		+ "typeof ytgame.firstFrameReady === 'function') "
		+ "{ ytgame.firstFrameReady(); }",
		true
	)

func notify_game_ready() -> void:
	if _ytgame == null:
		return
	JavaScriptBridge.eval(
		"if (typeof ytgame !== 'undefined' && "
		+ "typeof ytgame.gameReady === 'function') "
		+ "{ ytgame.gameReady(); }",
		true
	)

func _on_load_success(arguments: Array) -> void:
	var data: String = ""
	if not arguments.is_empty():
		data = str(arguments[0])
	cloud_load_completed.emit(data, true)

func _on_load_error(_arguments: Array) -> void:
	cloud_load_completed.emit("", false)

func _on_save_success(_arguments: Array) -> void:
	cloud_save_completed.emit(true)

func _on_save_error(_arguments: Array) -> void:
	cloud_save_completed.emit(false)
