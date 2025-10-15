extends Area2D

@export var HEAL: int = 1				# how much HP to restore
@export var ONE_SHOT: bool = true			# disappear after pickup
@export var RESPAWN_MS: int = 0			# if not one-shot, time to re-enable
@export var CONSUME_ON_FULL_HP: bool = false	# if false, ignore when already full

@onready var respawn_timer: Timer = null

func _ready() -> void:
	monitoring = true
	set_deferred("monitorable", true)
	connect("body_entered", Callable(self, "_on_body_entered"))
	if not ONE_SHOT and RESPAWN_MS > 0:
		respawn_timer = Timer.new()
		respawn_timer.one_shot = true
		add_child(respawn_timer)
		respawn_timer.timeout.connect(_on_respawn_timeout)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# apply heal (heals should NOT be blocked by i-frames)
	if body.has_method("apply_heal"):
		var healed: bool = body.apply_heal(HEAL, CONSUME_ON_FULL_HP)
		if not healed:
			return	# do nothing if player at full HP and we chose not to consume

	# consume or temporarily disable
	if ONE_SHOT:
		queue_free()
	else:
		# disable until respawn
		monitoring = false
		visible = false
		if respawn_timer and RESPAWN_MS > 0:
			respawn_timer.start(float(RESPAWN_MS) / 1000.0)

func _on_respawn_timeout() -> void:
	visible = true
	monitoring = true
