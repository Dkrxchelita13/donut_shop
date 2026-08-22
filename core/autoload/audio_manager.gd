extends Node

const SFX_PLAYER_COUNT: int = 4

const SFX_PATHS: Dictionary[StringName, String] = {
	&"glaze": "res://assets/audio/sfx/decorating/glaze_apply.wav",
	&"topping_pop": "res://assets/audio/sfx/decorating/topping_pop.wav",
	&"sprinkles": "res://assets/audio/sfx/decorating/sprinkles.wav",
	&"delivery": "res://assets/audio/sfx/customers/delivery.wav",
}

var _players: Array[AudioStreamPlayer] = []
var _sound_cache: Dictionary[StringName, AudioStream] = {}
var _fallback_player_index: int = 0

func _ready() -> void:
	for index: int in range(SFX_PLAYER_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%02d" % index
		player.autoplay = false
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

func play_sfx(sound_id: StringName) -> void:
	var stream: AudioStream = _get_sound(sound_id)
	if stream == null:
		return

	var player: AudioStreamPlayer = _get_available_player()
	player.stream = stream
	player.play()

func _get_sound(sound_id: StringName) -> AudioStream:
	if _sound_cache.has(sound_id):
		return _sound_cache[sound_id]

	if not SFX_PATHS.has(sound_id):
		return null

	var path: String = SFX_PATHS[sound_id]
	if not ResourceLoader.exists(path):
		return null

	var resource: Resource = ResourceLoader.load(path)
	if not resource is AudioStream:
		return null

	var stream: AudioStream = resource as AudioStream
	_sound_cache[sound_id] = stream
	return stream

func _get_available_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player

	var fallback: AudioStreamPlayer = _players[_fallback_player_index]
	_fallback_player_index = (_fallback_player_index + 1) % _players.size()
	fallback.stop()
	return fallback
