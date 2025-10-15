extends Area2D

@export var main_menu_path: String = "res://scenes/levels/menu.tscn"
@export var SLOWMO_SCALE: float = 0.5

@onready var sfx = $AudioStreamPlayer2D

var _ended := false

func _ready() -> void:
	monitoring = true
	set_deferred("monitorable", true)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node2D) -> void:
	if _ended:
		return
	if not body.is_in_group("player"):
		return
	_ended = true

	# slow-mo immediately
	Engine.time_scale = SLOWMO_SCALE

	# play ending SFX if present; go to menu when it finishes

	sfx.finished.connect(_on_sfx_finished, CONNECT_ONE_SHOT)
	sfx.play()


func _on_sfx_finished() -> void:
	_go_to_menu()

func _go_to_menu() -> void:
	Engine.time_scale = 1.0
	if not is_inside_tree():
		return
	if main_menu_path != "":
		get_tree().call_deferred("change_scene_to_file", main_menu_path)
	else:
		push_warning("EndingZone: 'main_menu_path' is empty; staying in current scene.")
