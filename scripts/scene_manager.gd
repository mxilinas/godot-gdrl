extends Node2D
class_name SceneManager

signal end_episode


# Variables

@export_category("Agents")
@export var player : Agent;
@export var cpu : Agent;
var n_steps = 0

# Engine Functions

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	end_episode.connect(_end_episode)

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("quit"):
			get_tree().quit()
		if event.is_action_pressed("release_mouse"):
			toggle_capture_mouse()

func _physics_process(delta):
	queue_redraw()

	n_steps += 1
	if n_steps > Constants.episode_length:
		end_episode.emit()
		n_steps = 0

func _draw():
	debug_distance_reward(player)
	debug_distance_reward(cpu)

func _end_episode() -> void:
	player.ai_controller.reset()
	cpu.ai_controller.reset()

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
		pass

