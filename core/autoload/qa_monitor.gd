extends CanvasLayer

var _label: Label = null

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	layer = 128
	_label = Label.new()
	_label.name = "QALabel"
	_label.add_theme_color_override("font_color", Color.GREEN)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

func _process(_delta: float) -> void:
	if _label == null:
		return

	var fps: float = Engine.get_frames_per_second()
	var memory_mb: float = float(OS.get_static_memory_usage()) / 1048576.0
	_label.text = "QA | FPS: %d | Mem: %.1f MB" % [roundi(fps), memory_mb]
