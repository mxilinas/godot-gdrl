# COGS 402 Godot Project

Train RL Agents to interact with humans through haptics in socially intelligent
ways.

## Observations

Observations include:

- Agent's position and velocity.
- Interaction partner's position and velocity.
- Whether the agent is colliding with another physics object.

Additionally, we have given the agents a form of short-term memory by including 
n-previous observations.

## Rewards

- Synchronicity

    Behavioral synchrony is a phenomenon where individuals subconsciously 
    coordinate their movements and actions; synchronicity is believed to play 
    a critical role in effective communication and cooperation. When 
    interactions lack smoothness due to poor synchrony, people often become 
    frustrated. In the context of human-robot interaction (HRI), low synchrony 
    may contribute to the uncanny valley effect (Lorenz et al., 2016).

    We have incooporated a reward function that is designed to maximize 
    synchronicity measured through the methods described by Lorenz et al., 2016.


<br>

- Force Exchanges
    

- Avoid Boundaries


## References

Lorenz, T., Weiss, A., & Hirche, S. (2016). Synchrony and reciprocity: Key 
mechanisms for social companion robots in therapy and care. International 
Journal of Social Robotics, 8(1), 
125-143. https://doi.org/10.1007/s12369-015-0325-8

Beeching, E., Debangoye, J., Simonin, O., & Wolf, C. (2021). Godot reinforcement 
learning agents. arXiv preprint arXiv:2112.03636.
