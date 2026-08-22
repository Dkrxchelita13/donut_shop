class_name PlatformAdapter
extends Node

signal adapter_ready(success: bool)
signal cloud_load_completed(data: String, success: bool)
signal cloud_save_completed(success: bool)

func initialize() -> void:
	adapter_ready.emit(true)

func get_platform_id() -> StringName:
	return &"base"

func save_to_cloud(data: String) -> void:
	cloud_save_completed.emit(false)

func load_from_cloud() -> void:
	cloud_load_completed.emit("", false)

func notify_first_frame_ready() -> void:
	pass

func notify_game_ready() -> void:
	pass
