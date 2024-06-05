extends RigidBody2D

class_name Agent

signal debug_message(message : String, type: int)

enum Debug {
	REWARD = 0b001,
	COLLISION = 0b010,
	ACTION = 0b100,
	}

enum Mode {
	MANUAL,
	RANDOM,
	DISABLED,
	}

# Editor Settings

@export_category("References")
@export var ai_controller : AIController
@export var other_agent : Agent
@export var timer : Timer;

@export_category("Controls")
@export var movement_speed : float = 3000
@export_enum("Manual", "Random Walk", "Disabled") var mode: int = 0

@export_category("Debugging")
@export var debug := false
@export_flags("Rewards", "Collisions", "Actions") var flags = 0

@export_category("Haptics")
@export var vibrate := false
@export_range(0, 1, 0.01) var collision_vib_duration : float = 0.1
@export_range(0, 1, 0.01) var collision_vib_strength : float = 1.0

@export_category("Rewards")
@export_group("Collisions")
@export var wall_collision_reward : float = -1.0
@export var agent_collision_reward : float = 1.0

# Member Variables

var max_velocity : float = movement_speed / self.linear_damp
var walk_target : Vector2
var just_collided := false
var is_vibrating := false

# Engine Functions

func _ready():
	self.debug_message.connect(_on_debug_message)
	ai_controller.init(self)

func _physics_process(_delta):

	friction_vibration()

	if ai_controller.heuristic == "human":
		match mode:
			Mode.MANUAL:
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					return
				ai_controller.set_action()
			Mode.RANDOM:
				var dir_to_target = position.direction_to(walk_target)
				apply_force(dir_to_target.limit_length(1.0) * movement_speed)
			Mode.DISABLED:
				return

	var move_action : Vector2 = ai_controller.move_action
	debug_message.emit(self.name + str(move_action), Debug.ACTION)
	apply_force(move_action * movement_speed)

func _on_body_entered(body : PhysicsBody2D):
	debug_message.emit(self.name + " Entered: " + str(body.name), Debug.COLLISION)
	just_collided = true
	if body.is_in_group("WALL"):
		ai_controller.reward += wall_collision_reward
		collision_vibration()

	if body.is_in_group("CIRCLE"):
		ai_controller.reward += agent_collision_reward
		collision_vibration()

func _on_body_exited(_body):
	just_collided = false

func _on_debug_message(message : String, type : Debug):
	if debug:
		if type & flags:
			print(message)

func _on_walk_timer_timeout():
	walk_target = random_position(get_viewport_rect())
	timer.wait_time = randf_range(0.0, 3.0)

# Helper Functions

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
func friction_vibration() -> void:
	if vibrate and not is_vibrating:
		var strength = inverse_lerp(0, max_velocity, abs(linear_velocity.length()))
		Input.start_joy_vibration(0, strength, 0, 0.1)

## Play a vibration on collision with another physics object using
## the strong motor.
func collision_vibration() -> void:
	if vibrate:
		Input.stop_joy_vibration(0)
		Input.start_joy_vibration(0, 0.0,
		collision_vib_strength, collision_vib_duration)
		inhibit_vibrations(collision_vib_duration)
