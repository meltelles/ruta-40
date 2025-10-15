extends Control

@export var first_level: PackedScene

@onready var play_btn: Button = $Buttons/PlayButton
@onready var quit_btn: Button = $Buttons/QuitButton

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	if first_level:
		get_tree().change_scene_to_packed(first_level)
	else:
		push_warning("MainMenu: 'first_level' is not assigned.")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	# Optional: Enter = Play, Esc = Quit
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
