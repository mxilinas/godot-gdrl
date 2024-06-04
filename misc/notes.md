# Notes and Implementation Details

## Synchronicity Reward
Reward the agent based on a measure of behavioral synchronicity (0-1) at the end 
of each episode.

1. During the episode, calculate and store the position and velocity of both 
   agents at each timestep.

   Altneratively, just calculate the positions and derive the velocities.

    1. Record positions and velocities at each timestep.
        Velocity is measured in pixels per second by Godot. Updates to the 
        velocity occur at the same frequency as the physics process loop but may 
        run in another thread.

    ```GDScript
    var velocities : Array[Vector2] = []
    var positions : Array[Vector2] = []
    func _physics_process(delta):
        velocities.append(self.linear_velocity)
        positions.append(self.position)
    ```

    2. Record the positions and derive the velocities.
        This is slightly more involved. At the end of the episode, we need to 
        calculate the velocities at each timestep given the position data.

        The naive approach would be to iterate through the positions and 
        calculate the difference between consecutive positions.

        $\Delta x = x(t) - x(t - 1)$

        $\dot{x}(t) = \Delta x / \Delta t$

        Delta time will always be 1 since position is recorded at each physics 
        step.

        ```GDScript
        var positions : Array[Vector2] = []
        func _physics_process(delta):
            positions.append(self.position)

        func _on_episode_end():
            velocities = []
            for i in range(1, positions.size()):
                velocities.append(positions[i] - positions[i - 1])
        ```

        The problem is that this method results in an array of velocities that 
        is shorter than the array of positions since each *pair* of elements is 
        compared in a sliding window.

        A better way to get the velocities is by calculating the gradient of the 
        positions array.

        https://stackoverflow.com/questions/24633618/what-does-numpy-gradient-do
        
        ```GDScript
        func gradient(positions : Array[Vector2]) -> Array[Vector2]:
            var velocities = []
            var n = positions.size()

            # Forward difference for the first element
            velocities.append(positions[1] - positions[0]))

            # Central differences for the middle elements
            for i in range(1, n - 1):
                velocities.append((positions[i + 1] - positions[i - 1]) / 2)

            # Backwards difference for the last element.
            velocities.append(positions[n - 1] - positions[n - 2]))

            return velocities
        ```

2. Next we need functions to normalize the positions and velocities by magnitude 
   of the longest observed vector.

    ```GDscript
    func max_norm(vectors : Array[Vector2]) -> float:
        var max_norm : float = 0.0
        for v in vectors:
            max_norm = max(max_norm, v.length())
        return max_norm

    func normalize_vectors(vectors : Array[Vector2]) -> Array[Vector2]:
        var max_norm := max_norm(vectors)
        var normalized_vectors = []
        for i in vectors:
            if max_norm == 0:
                normalize_vectors.append(v)
            else:
                normalize_vectors.append(v / max_norm)
        return normalize_vectors

3. Compute the individual phase for both agents.
        
    ```GDScript
    func individual_phases(velocities, positions):
        var phases = []
        var normalized_velocities = normalize_vectors(velocities)
        var normalized_positions = normalize_vectors(velocities)
        for i in range(normalized_positions.size()):
            phases.append(atan2(
                normalized_velocities[i].x),
                -normalized_positions[i].y
            )

    ```



3. Calculate the relative phases from both agent's individual_phases.

    ```GDScript
    var relative_phases = player.individual_phases - cpu.individual_phases
    ```

4. Compute reward as the cross-spectral coherence.

    ```GDScript
    func synchronicity(relative_phases: Array[float]) -> float:
        var N = phases.size() # or steps_per_episode
        var sum_complex := Vector2.ZERO # Sum of the complex exponents.
        
        for phase in relative_phases:
            sum_complex += Vector2(cos(phase), sin(phase))

        var average_magnitude = (sum_complex / N).length()
        return 1.0 - average_magnitude
    ```
