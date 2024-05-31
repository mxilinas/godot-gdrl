extends RigidBody2D
class_name Agent
signal debug_message(message : String)


# Settings

@export var movement_speed : float = 2500.0
@export var should_vibrate := false
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

@export_group("Haptic Feedback Settings")
@export_range(0, 1, 0.01) var collision_vibration_duration : float = 0.1
@export_range(0, 1, 0.01) var collision_vibtation_strength : float = 1.0


# Member Variables

@onready var agent_controller : AgentController = $AgentController
@onready var max_velocity = movement_speed / self.linear_damp
@onready var timer : Timer = $Timer
var is_colliding := false
var target_position : Vector2
var is_vibrating := false


# Engine Functions

func _ready():
	self.debug_message.connect(_on_debug_message)
	agent_controller.init(self)


func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("release_mouse"):
			if should_vibrate:
				should_vibrate = false


func _physics_process(_delta):
	agent_controller.reward += distance_reward()
	movement_vibration()

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

	if body.is_in_group("Walls"):
		agent_controller.reward -= 1
		collision_vibration(collision_vibtation_strength)

	if body.is_in_group("Agents"):
		agent_controller.reward += velocity_reward(body)
		collision_vibration(collision_vibtation_strength)


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
func distance_reward(strength = 0.001) -> float:
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


## Apply a reward based on the difference in velocity of two colliding agents.
func velocity_reward(rb : RigidBody2D) -> float:
	var diff = abs(rb.linear_velocity.length() - linear_velocity.length()) 
	var reward = diff * velocity_reward_strength
	agent_controller.reward += reward

	if velocity_reward_debug:
		print(reward)

	return reward


## Return a random position inside the given area.
func random_position(area: Rect2) -> Vector2: 
	var random_x = randf_range(area.position.x, area.position.x + area.size.x)
	var random_y = randf_range(area.position.y, area.position.y + area.size.y)
	return Vector2(random_x, random_y)


## Prevent new vibrations from playing for the given length of time.
func inhibit_vibrations(duration: float) -> void:
	is_vibrating = true
	await get_tree().create_timer(duration).timeout
	is_vibrating = false


## Vibrate the weak motor in the controller while the agent is moving [br].
## Intensity is controlled by the magnitude of the agent's linear velocity.
func movement_vibration() -> void:
	if should_vibrate and not is_vibrating:
		Input.start_joy_vibration(0,
			remap(abs(linear_velocity.length()), 0, max_velocity, 0, 1),
			0, 0)


## Play a vibration on collion with another physics object.
## Uses the strong motor.
func collision_vibration(strength: float) -> void:
	if should_vibrate:
		Input.stop_joy_vibration(0)
		Input.start_joy_vibration(0, 0.0,
		strength, collision_vibration_duration)
		inhibit_vibrations(collision_vibration_duration)
