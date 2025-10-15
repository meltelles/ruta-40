extends Area2D

@export var DAMAGE: int = 1
@export var DAMAGE_INTERVAL_MS: int = 0	# 0 => only on enter
@export var INSTANT_KILL: bool = false

@export var START_SLOWMO_ON_ENTER: bool = false
@export var SLOWMO_SCALE: float = 0.5

@onready var timer: Timer = get_node_or_null("Timer") as Timer

var _overlapping := {}	# body -> last_hit_ms

func _ready() -> void:
	monitoring = true
	set_deferred("monitorable", true)
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _physics_process(_delta: float) -> void:
	if DAMAGE_INTERVAL_MS <= 0:
		return
	var now := Time.get_ticks_msec()
	for body in _overlapping.keys():
		if not is_instance_valid(body):
			_overlapping.erase(body)
			continue
		var last_hit: int = _overlapping[body]
		if now - last_hit >= DAMAGE_INTERVAL_MS:
			_apply_to(body)
			_overlapping[body] = now

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_signal("death_finished"):
		body.death_finished.connect(_on_player_death_finished, CONNECT_ONE_SHOT)

	if START_SLOWMO_ON_ENTER:
		Engine.time_scale = SLOWMO_SCALE
	

	if INSTANT_KILL and body.has_method("die"):
		body.call_deferred("die")
	else:
		_apply_to(body)
		_overlapping[body] = Time.get_ticks_msec()

func _on_body_exited(body: Node2D) -> void:
	_overlapping.erase(body)

func _apply_to(body: Node) -> void:
	if not is_instance_valid(body):
		return
	if not body.is_in_group("player"):
		return

	if INSTANT_KILL and body.has_method("die"):
		body.call_deferred("die")
		return

	if body.has_method("apply_damage"):
		body.call_deferred("apply_damage", DAMAGE)

func _on_player_death_finished() -> void:
	Engine.time_scale = 1.0
	if is_inside_tree():
		get_tree().call_deferred("reload_current_scene")
