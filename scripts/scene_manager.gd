extends Node2D
class_name SceneManager


# Variables

@export_group("Agents")
@onready var player : Agent = $Player
@onready var cpu : Agent = $CPU


# Engine Functions

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.interaction_partner = cpu
	cpu.interaction_partner = player


func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("quit"):
			get_tree().quit()
		if event.is_action_pressed("release_mouse"):
			toggle_capture_mouse()


func _physics_process(delta):
	queue_redraw()


func _draw():
	debug_distance_reward(player)
	debug_distance_reward(cpu)


# Helper Functions

## If the mouse is captured, release the mouse.
## If the mouse is released, capture the mouse.
func toggle_capture_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Draw circle around the agents corresponding to their minimum and maximum
## reward distances.
func debug_distance_reward(agent : Agent) -> void:
	var min_color = Color.GREEN
	var max_color = Color.RED
	max_color.a = 0.25
	if agent.debug:
		draw_circle(agent.position, agent.max_distance, min_color)
		draw_circle(agent.position, agent.min_distance, max_color)
