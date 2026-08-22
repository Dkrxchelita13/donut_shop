class_name Donut
extends Node3D

const REPEATED_TANGENTIAL_OFFSET: float = 0.025
const REPEATED_MAX_TILT_DEGREES: float = 7.0
const GLAZE_TWEEN_DURATION: float = 0.25
const DELIVERY_SPIN_DURATION: float = 0.45
const DELIVERY_EXIT_DURATION: float = 0.18

@onready var donut_pivot: Node3D = $DonutPivot
@onready var glaze_mesh: MeshInstance3D = $DonutPivot/DonutModel/Glaze
@onready var topping_sockets: Node3D = $DonutPivot/DonutModel/ToppingSockets
@onready var repeated_toppings: Node3D = $DonutPivot/ToppingContainer/RepeatedToppings
@onready var unique_toppings: Node3D = $DonutPivot/ToppingContainer/UniqueToppings

var current_glaze: GlazeData = null
var applied_toppings: Array[ToppingData] = []
var _glaze_tween: Tween = null
var _delivery_tween: Tween = null

var glaze_material: StandardMaterial3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _repeated_topping_nodes: Dictionary[StringName, MultiMeshInstance3D] = {}
var _unique_topping_counter: int = 0

func _ready() -> void:
	_rng.randomize()
	_prepare_glaze_material()

func _prepare_glaze_material() -> void:
	var source_material: Material = glaze_mesh.get_active_material(0)
	if source_material == null or not source_material is StandardMaterial3D:
		return
	glaze_material = source_material.duplicate() as StandardMaterial3D
	glaze_mesh.set_surface_override_material(0, glaze_material)

func apply_glaze(glaze_data: GlazeData) -> void:
	if glaze_data == null:
		return
	if glaze_material == null:
		return

	current_glaze = glaze_data
	glaze_material.roughness = clampf(glaze_data.roughness, 0.0, 1.0)

	if _glaze_tween != null and _glaze_tween.is_valid():
		_glaze_tween.kill()

	_glaze_tween = create_tween()
	_glaze_tween.bind_node(self)
	_glaze_tween.tween_property(
		glaze_material,
		"albedo_color",
		glaze_data.color,
		GLAZE_TWEEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	get_node("/root/AudioManager").call(&"play_sfx", &"glaze")

func play_delivery_animation(callable_callback: Callable) -> void:
	if _delivery_tween != null and _delivery_tween.is_valid():
		return

	get_node("/root/AudioManager").call(&"play_sfx", &"delivery")

	var target_rotation: Vector3 = donut_pivot.rotation
	target_rotation.y += TAU
	var target_position: Vector3 = donut_pivot.position + Vector3.UP * 0.35

	_delivery_tween = create_tween()
	_delivery_tween.bind_node(self)
	_delivery_tween.tween_property(
		donut_pivot,
		"rotation",
		target_rotation,
		DELIVERY_SPIN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_delivery_tween.parallel().tween_property(
		donut_pivot,
		"position",
		target_position,
		DELIVERY_SPIN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_delivery_tween.tween_property(
		donut_pivot,
		"scale",
		Vector3.ZERO,
		DELIVERY_EXIT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if callable_callback.is_valid():
		_delivery_tween.tween_callback(callable_callback)

func add_topping(topping_data: ToppingData) -> void:
	if topping_data == null or topping_data.mesh == null: return
	if _has_topping(topping_data.id): return # Evita duplicados lógicos
	
	var was_added: bool = false
	if topping_data.is_repeated:
		_add_repeated_topping(topping_data)
		was_added = true
	else:
		_add_unique_topping(topping_data)
		was_added = true
		
	if was_added:
		applied_toppings.append(topping_data)

func _has_topping(topping_id: StringName) -> bool:
	for topping: ToppingData in applied_toppings:
		if topping != null and topping.id == topping_id: return true
	return false

func _add_repeated_topping(data: ToppingData) -> void:
	var sockets: Array[Node3D] = _get_topping_sockets()
	if sockets.is_empty(): return

	var multimesh_instance: MultiMeshInstance3D = _get_or_create_repeated_topping_node(data)
	var multimesh: MultiMesh = multimesh_instance.multimesh
	if multimesh == null:
		multimesh = MultiMesh.new()
		multimesh_instance.multimesh = multimesh

	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false
	multimesh.use_custom_data = false
	multimesh.mesh = data.mesh
	multimesh.instance_count = sockets.size()

	for index: int in range(sockets.size()):
		var socket: Node3D = sockets[index]
		multimesh.set_instance_transform(index, _create_repeated_topping_transform(socket))

func _get_or_create_repeated_topping_node(data: ToppingData) -> MultiMeshInstance3D:
	if _repeated_topping_nodes.has(data.id):
		var existing = _repeated_topping_nodes[data.id]
		existing.material_override = data.material
		return existing

	var multimesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	multimesh_instance.name = "%s_MultiMesh" % String(data.id)
	multimesh_instance.transform = Transform3D.IDENTITY
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multimesh_instance.material_override = data.material
	multimesh_instance.multimesh = MultiMesh.new()
	repeated_toppings.add_child(multimesh_instance)
	_repeated_topping_nodes[data.id] = multimesh_instance
	return multimesh_instance

func _create_repeated_topping_transform(socket: Node3D) -> Transform3D:
	var result: Transform3D = _get_socket_transform_in_space(socket, repeated_toppings)
	var tangent_basis: Basis = result.basis.orthonormalized()
	
	var offset_x: float = _rng.randf_range(-REPEATED_TANGENTIAL_OFFSET, REPEATED_TANGENTIAL_OFFSET)
	var offset_z: float = _rng.randf_range(-REPEATED_TANGENTIAL_OFFSET, REPEATED_TANGENTIAL_OFFSET)
	result.origin += (tangent_basis.x * offset_x + tangent_basis.z * offset_z)
	
	var random_yaw: float = _rng.randf_range(0.0, TAU)
	var max_tilt: float = deg_to_rad(REPEATED_MAX_TILT_DEGREES)
	var tilt_x: float = _rng.randf_range(-max_tilt, max_tilt)
	var tilt_z: float = _rng.randf_range(-max_tilt, max_tilt)
	
	var random_rotation: Basis = Basis(Vector3.UP, random_yaw)
	random_rotation *= Basis(Vector3.RIGHT, tilt_x)
	random_rotation *= Basis(Vector3.BACK, tilt_z)
	
	result.basis = result.basis * random_rotation
	return result

func _add_unique_topping(data: ToppingData) -> void:
	var sockets: Array[Node3D] = _get_topping_sockets()
	if sockets.is_empty(): return

	var socket: Node3D = sockets[_rng.randi_range(0, sockets.size() - 1)]
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	_unique_topping_counter += 1
	mesh_instance.name = "%s_%03d" % [String(data.id), _unique_topping_counter]
	mesh_instance.mesh = data.mesh
	mesh_instance.material_override = data.material
	unique_toppings.add_child(mesh_instance)

	var instance_transform: Transform3D = _get_socket_transform_in_space(socket, unique_toppings)
	instance_transform.basis *= Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
	mesh_instance.transform = instance_transform

func _get_topping_sockets() -> Array[Node3D]:
	var sockets: Array[Node3D] = []
	if topping_sockets == null: return sockets
	for child: Node in topping_sockets.get_children():
		if child is Node3D: sockets.append(child as Node3D)
	return sockets

func _get_socket_transform_in_space(socket: Node3D, target_space: Node3D) -> Transform3D:
	return target_space.global_transform.affine_inverse() * socket.global_transform
