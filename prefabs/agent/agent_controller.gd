extends AIController2D
class_name AgentController


# Variables

@onready var agent : Agent = get_parent()
var move_action := Vector2.ZERO

@export_group("Observations")
@export_range(0, 100) var history_length : int = 2
const observations_n = 5
var observations : Array[float] = []
var obs_hist : Array[Array] = []


# Engine Functions

func _ready():

	var empty : Array[float]
	empty.resize(observations_n)
	empty.fill(0.0)

	obs_hist.resize(history_length)
	obs_hist.fill(empty)


# Reinforcment Learning Functions


# Observations include:
# - the relative position and velocity of this agent's interaction partner.
# - whether or not this agent is colliding with another physics body.
func get_obs() -> Dictionary:
	var partner = agent.interaction_partner
	var partner_position = to_local(partner.position)
	var partner_velocity = to_local(partner.linear_velocity)

	var new_observations : Array[float] = [
		partner_position.x,
		partner_position.y,
		partner_velocity.x,
		partner_velocity.y,
		agent.is_colliding,
	]

	obs_hist.push_front(new_observations)
	obs_hist.pop_back()

	observations = []
	for obs in obs_hist:
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
		move_action = Input.get_vector("left", "right", "up", "down").limit_length(1.0)


func get_action():
	return [move_action.x, move_action.y]
