extends AIController2D
class_name AgentController


# Variables

@onready var agent : Agent = get_parent()
var move_action := Vector2.ZERO


# Reinforcment Learning Functions

# Observations include:
# - the relative position and velocity of this agent's interaction partner.
# - whether or not this agent is colliding with another physics body.
func get_obs() -> Dictionary:
	var partner = agent.interaction_partner
	var partner_position = to_local(partner.position)
	var partner_velocity = to_local(partner.linear_velocity)
	var observations : Array[float] = [
		partner_position.x,
		partner_position.y,
		partner_velocity.x,
		partner_velocity.y,
		agent.is_colliding,
	]
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
		var mouse_velocity = Input.get_last_mouse_velocity()
		mouse_velocity *= _player.mouse_velocity_scale
		move_action = mouse_velocity.limit_length(1.0)


func get_action():
	return [move_action.x, move_action.y]
