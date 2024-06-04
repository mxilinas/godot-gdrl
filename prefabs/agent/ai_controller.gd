extends AIController2D
class_name AIController


# Variables

var move_action := Vector2.ZERO

@export_range(0, 100) var history_length : int = 1
const observations_n = 9

var observations : Array[float] = []
var prev_observations : Array[Array] = []


# Engine Functions

func _ready():
	reset_after = Constants.episode_length

	# Initialize prev_observations with zeros.
	var empty : Array[float] = []
	empty.resize(observations_n)
	empty.fill(0.0)
	prev_observations.resize(history_length)
	prev_observations.fill(empty)


# Reinforcment Learning Functions


# Observations include:
# - the relative position and velocity of this agent's interaction partner.
# - whether or not this agent is colliding with another physics body.
func get_obs() -> Dictionary:
	var partner = _player.interaction_partner
	var partner_position = to_local(partner.position)
	var partner_velocity = to_local(partner.linear_velocity)

	var new_observations : Array[float] = [
		_player.position.x,
		_player.position.y,
		_player.linear_velocity.x,
		_player.linear_velocity.y,
		partner_position.x,
		partner_position.y,
		partner_velocity.x,
		partner_velocity.y,
		_player.is_colliding,
	]

	prev_observations.push_front(new_observations)
	prev_observations.pop_back()

	observations = []
	for obs in prev_observations:
		for ob in obs:
			observations.append(ob)

	return {"obs": observations}


# Rewards include:
# - this agent's proximity to its interaction partner.
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
