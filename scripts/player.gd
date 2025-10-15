extends CharacterBody2D

@export var SPEED := 230.0
@export var JUMP_VELOCITY := -360.0
@export var DASH_VELOCITY := 400.0
@export var DASH_DURATION_MS := 300
@export var DASH_COOLDOWN_MS := 1000

@export var MAX_HP := 3
@export var INVULN_MS := 500

var HP := MAX_HP

signal death_finished
signal hp_changed(current: int, max: int)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var death_sfx: AudioStreamPlayer2D = $DeathSfx
@onready var heal_sfx: AudioStreamPlayer2D = $HealSfx
@onready var jump_sfx: AudioStreamPlayer2D = $JumpSfx

# collision shapes
@onready var standing_shape: CollisionShape2D = $StandingCollisionShape
@onready var dashing_shape: CollisionShape2D = $DashingCollisionShape

var is_dashing := false
var last_dash := 0
var _dead := false

var _dash_until_ms := 0
var _can_dash := true
var _dash_started_on_floor := false
var _invulnerable_until_ms := 0

func _ready() -> void:
	_use_standing_shape()
	emit_signal("hp_changed", HP, MAX_HP)

func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invulnerable_until_ms

func apply_damage(amount: int) -> void:
	if _dead:
		return
	if is_invulnerable():
		return
	var prev := HP
	HP = max(HP - amount, 0)
	_invulnerable_until_ms = Time.get_ticks_msec() + INVULN_MS
	if HP != prev:
		emit_signal("hp_changed", HP, MAX_HP)
	if HP <= 0:
		die()
	else:
		if hurt_sfx:
			hurt_sfx.play()
		animated_sprite.play("hurt")
		
func apply_heal(amount: int, consume_on_full_hp: bool = false) -> bool:
	if _dead:
		return false
	if amount <= 0:
		return false
	if HP >= MAX_HP and not consume_on_full_hp:
		return false
	var prev := HP
	HP = clamp(HP + amount, 0, MAX_HP)
	if HP != prev:
		emit_signal("hp_changed", HP, MAX_HP)
	if HP > prev and heal_sfx:
		heal_sfx.play()
	# you could play a small "heal" animation or flash here
	return true

func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	if death_sfx:
		death_sfx.play()
	animated_sprite.play("die")
	await animated_sprite.animation_finished
	emit_signal("death_finished")

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if is_on_floor():
		_can_dash = true

	var now := Time.get_ticks_msec()

	# dash update
	if is_dashing:
		animated_sprite.play("dash")
		if _dash_started_on_floor and Input.is_action_just_pressed("jump"):
			_end_dash()
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
		elif now >= _dash_until_ms:
			_end_dash()
		else:
			move_and_slide()
			return

	# horizontal move (no dash)
	if Input.is_action_pressed("move_left"):
		velocity.x = -SPEED
		animated_sprite.flip_h = true
		animated_sprite.play("walk")
	elif Input.is_action_pressed("move_right"):
		velocity.x = SPEED
		animated_sprite.flip_h = false
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
		velocity.x = 0

	# jump / gravity
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			jump_sfx.play()
	else:
		velocity += get_gravity() * delta
		animated_sprite.play("jump")

	# start dash (left/right only)
	if Input.is_action_just_pressed("dash") and _can_start_dash(now):
		_start_dash(now)

	move_and_slide()

func _can_start_dash(now: int) -> bool:
	if not _can_dash:
		return false
	if now - last_dash < DASH_COOLDOWN_MS:
		return false
	return true

func _start_dash(now: int) -> void:
	var dir_x := 0.0
	if Input.is_action_pressed("move_left"):
		dir_x = -1.0
	elif Input.is_action_pressed("move_right"):
		dir_x = 1.0
	else:
		dir_x = -1.0 if animated_sprite.flip_h else 1.0

	velocity = Vector2(dir_x * float(DASH_VELOCITY), 0.0)

	is_dashing = true
	_dash_started_on_floor = is_on_floor()
	_dash_until_ms = now + int(DASH_DURATION_MS)
	last_dash = now
	_can_dash = false

	_use_dashing_shape()
	animated_sprite.play("dash")

func _end_dash() -> void:
	is_dashing = false
	_dash_started_on_floor = false
	_use_standing_shape()

func _use_standing_shape() -> void:
	if standing_shape:
		standing_shape.set_deferred("disabled", false)
	if dashing_shape:
		dashing_shape.set_deferred("disabled", true)

func _use_dashing_shape() -> void:
	if standing_shape:
		standing_shape.set_deferred("disabled", true)
	if dashing_shape:
		dashing_shape.set_deferred("disabled", false)
