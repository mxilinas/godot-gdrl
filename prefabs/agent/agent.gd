extends RigidBody2D
class_name Agent
signal debug_message(message : String)


# Settings

@export var movement_speed : float = 2500.0
@export var vibrate := false
@export var debug := false
@export var auto := false

@export_group("Nodes")
@export var interaction_partner : Agent

@export_group("Distance Reward Settings")
@export var min_distance : float = 100
@export var max_distance : float = 500
@export_range(0, 1) var distance_reward_strength : float = 0.001

@export_group("Velocity Reward Settings")
@export var velocity_reward_strength: float = 0.001
@export var velocity_reward_debug := false

# Member Variables

@onready var agent_controller : AgentController = $AgentController
@onready var timer : Timer = $Timer
var is_colliding := false
var target_position : Vector2


# Engine Functions

func _ready():
	self.debug_message.connect(_on_debug_message)
	agent_controller.init(self)


func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("release_mouse"):
			if vibrate:
				vibrate = false
			else:
				vibrate = true


func _physics_process(_delta):

	agent_controller.reward += distance_reward()

	if auto:
		var dir_to_target = (target_position - position).limit_length(1.0)
		apply_force(dir_to_target * movement_speed)
		return

	if agent_controller.needs_reset:
		agent_controller.done = true
		agent_controller.reset()
		debug_message.emit("reset!")

	if agent_controller.heuristic == "human":
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			return
		agent_controller.set_action()

	var move_action : Vector2 = agent_controller.move_action
	debug_message.emit(str(move_action))
	apply_force(move_action * movement_speed)


func _on_body_entered(body : PhysicsBody2D):
	is_colliding = true

	if body.name == "Walls":
		agent_controller.reward -= 1
		if vibrate:
			Input.start_joy_vibration(0, 0.0, 1.0, 0.1)

	if body.name == "CPU" or body.name == "Player":
		agent_controller.reward += velocity_reward(body)


func _on_body_exited(_body):
	is_colliding = false


func _on_debug_message(message : String):
	if debug:
		print(message)


## Change the automatic target position when the timer runs out.
## Assigns a new randomized timeout.
func _on_timer_timeout():
	target_position = random_position(get_viewport_rect())
	timer.wait_time = randf_range(0.0, 3.0)


# Helper Functions

## Positive when the agent is further than [param max_distance] to its
## interaction partner and negative when the agent is closer than
## [param min_distance].
func distance_reward(strength = 0.001):
	var reward : float = 0.0
	var distance = global_position.distance_to(interaction_partner.global_position)
	if distance > max_distance:
		reward -= strength
	elif distance < min_distance:
		reward -= strength
	else:
		reward += strength
		debug_message.emit(self.name + " rewarded for distance")
	return reward


## Apply a reward based on the similarity in velocity of the agents colliding.
func velocity_reward(rb : RigidBody2D):
	var diff = abs(rb.linear_velocity.length() - linear_velocity.length()) 
	var reward = diff * velocity_reward_strength
	if velocity_reward_debug:
		print(reward)
	agent_controller.reward += reward
	if vibrate:
		Input.start_joy_vibration(0, 1.0, 0.0, 0.1)
	return reward


func synchrony_reward():
	pass


## Return a random position inside the given play area.
func random_position(area : Rect2) -> Vector2: 
	var random_x = randf_range(area.position.x, area.position.x + area.size.x)
	var random_y = randf_range(area.position.y, area.position.y + area.size.y)
	return Vector2(random_x, random_y)
