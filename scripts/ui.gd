extends CanvasLayer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D			# optional; leave unset for blank slots
@export var heart_size: Vector2i = Vector2i(16, 16)
@export var spacing_px: int = 4
@export var player_path: NodePath

@onready var hearts_box: HBoxContainer = $Root/Hearts
var _max_hearts := 0

func _ready() -> void:
	hearts_box.add_theme_constant_override("separation", spacing_px)
	var player := _get_player()
	if player:
		player.hp_changed.connect(_on_hp_changed)
		_on_hp_changed(player.HP, player.MAX_HP)
	else:
		push_warning("HealthUI: Player not found; set player_path or add player to 'player' group.")

func _get_player() -> Node:
	if player_path != NodePath():
		return get_node_or_null(player_path)
	return get_tree().get_first_node_in_group("player")

func _on_hp_changed(current: int, max_hp: int) -> void:
	if max_hp != _max_hearts:
		_rebuild_hearts(max_hp)
	_max_hearts = max_hp
	_update_hearts(current)

func _rebuild_hearts(max_hp: int) -> void:
	for c in hearts_box.get_children():
		c.queue_free()
	for i in max_hp:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(heart_size.x, heart_size.y)
		# start as blank; _update_hearts will set textures
		tr.texture = null
		hearts_box.add_child(tr)

func _update_hearts(current: int) -> void:
	var idx := 0
	for c in hearts_box.get_children():
		var tr := c as TextureRect
		if idx < current:
			tr.texture = full_heart
		else:
			# If empty_heart is not provided, keep it blank (fixed size via custom_minimum_size)
			tr.texture = empty_heart if empty_heart != null else null
		idx += 1
