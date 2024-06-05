extends AIController2D

class_name AIController

# Variables

var move_action := Vector2.ZERO

@export_range(0, 100) var history_length : int = 1
const observations_n = 10

var observations : Array[float] = []
var prev_observations : Array[Array] = []

# Engine Functions

func _physics_process(_delta):
	pass

func _ready():
	zero_previous_observations()

# Reinforcment Learning

# Observations:
# - the position and velocity of this agent.
# - the relative position and velocity of this agent's interaction partner.
# - whether or not this agent is colliding with another physics body.
# - The number of steps elapsed during the current episode.
func get_obs() -> Dictionary:
	var other = _player.other_agent
	var other_position = to_local(other.position)
	var other_velocity = to_local(other.linear_velocity)

	var new_observations : Array[float] = [
		_player.position.x,
		_player.position.y,
		_player.linear_velocity.x,
		_player.linear_velocity.y,
		other_position.x,
		other_position.y,
		other_velocity.x,
		other_velocity.y,
		_player.just_collided,
		n_steps,
	]

	prev_observations.push_front(new_observations)
	prev_observations.pop_back()

	observations = []
	for obs : Array[float] in prev_observations:
		for ob in obs:
			observations.append(ob)

	return {"obs": observations}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		"move": {"size": 2, "action_type": "continuous"},
	}

func set_action(action = null) -> void:
	if action:
		move_action = Vector2(
			action["move"][0],
			action["move"][1]
			).limit_length(1.0)
	else:
		var input = Input.get_vector("left", "right", "up", "down")
		move_action = input.limit_length(1.0)

func get_action():
	return [move_action.x, move_action.y]

## Initialize the previous observations with zeros.
func zero_previous_observations() -> void:
	var empty : Array[float] = []
	empty.resize(observations_n)
	empty.fill(0.0)
	prev_observations.resize(history_length)
	prev_observations.fill(empty)
