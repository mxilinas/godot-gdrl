extends Node2D
## Measure synchronicity over a period of time. Assign a reward to each agent
## based on circular variance.
##
## The period of interaction is defined as the number of steps per episode.

@export var player : Agent
@export var cpu : Agent

var player_positions : Array[Vector2] = []
var cpu_positions : Array[Vector2] = []

var relative_phases : Array[float] = []

var steps : int = 0

signal end_episode

@export_group("Visualize")
@export var visualize : bool = false
@export var bins : int = 9
@onready var bin_colors : Array[Color] = random_colors(bins)

# Engine Functions

func _ready():
	end_episode.connect(_on_end_episode)

func _draw():
	var bin_width = 2 * PI / bins
	var hist = circular_histogram(relative_phases, bins, 2 * PI / bins)
	draw_circular_histogram(hist, bin_width)

func _physics_process(_delta):

	queue_redraw()

	steps += 1

	if steps > Constants.episode_length:
		end_episode.emit()
		steps = 0
		return

	player_positions.append(player.position)
	cpu_positions.append(cpu.position)

func _on_end_episode():

	var player_velocities := gradient(player_positions)
	var cpu_velocities := gradient(cpu_positions)

	var player_phases := thetas(player_positions, player_velocities)
	var cpu_phases := thetas(cpu_positions, cpu_velocities)

	relative_phases = compute_relative_phases(player_phases, cpu_phases)
	var reward := coherence(relative_phases)

	cpu.ai_controller.reward += reward
	player.ai_controller.reward += reward

	player_positions = []
	cpu_positions = []

# Helper Functions

## Compute the gradient of a 2d position array.
func gradient(positions : Array[Vector2]) -> Array[Vector2]:
	var velocities : Array[Vector2] = []
	var n := positions.size()

	# Forward difference for the first element
	velocities.append(positions[1] - positions[0])

	# Central differences for the middle elements
	for i in range(1, n - 1):
		velocities.append((positions[i + 1] - positions[i - 1]) / 2)

	# Backwards difference for the last element.
	velocities.append(positions[n - 1] - positions[n - 2])

	assert(positions.size() == velocities.size())
	return velocities

## Compute the individual phases for an agent given its position and velocity
## over a period of time.
func thetas(velocities, positions) -> Array[float]:
	var phases : Array[float] = []
	var normalized_positions = normalize_vectors(positions)
	var normalized_velocities = normalize_vectors(velocities)
	for i in range(normalized_positions.size()):
		var phase = theta(normalized_positions[i], normalized_velocities[i])
		phases.append(phase)
	return phases

## Compute the individual phase given a velocity [vel], position
## [pos].
func theta(pos : Vector2, vel : Vector2) -> float:
	var phase = (vel / -pos)
	if is_nan(phase.x) || is_nan(phase.y):
		return 0
	return atan2(phase.y, phase.x)

func compute_relative_phases(p_indiv : Array[float], cpu_indiv : Array[float]) -> Array[float]:
	var phases : Array[float] = []
	for i in range(Constants.episode_length):
		phases.append(p_indiv[i] - cpu_indiv[i])
	return phases

## Compute the circular variance from an array of relative phases.
func coherence(phases: Array[float]) -> float:
	var sum_complex := Vector2.ZERO
	for relative_phase in phases:
		sum_complex += Vector2(cos(relative_phase), sin(relative_phase))
	var cv = (sum_complex / phases.size()).length()
	return lerp(1, 0, 1.0 - cv)

## Find the magnitude of the longest vector in an array of vectors.
func get_extrema(vectors : Array[Vector2]) -> float:
	var extrema : float = 0.0
	for v in vectors:
		extrema = max(extrema, v.length())
	return extrema

## Normalize a single vector by the extrema of the longest vector.
func normalize_vector(vector : Vector2, extrema : float) -> Vector2:
	if extrema == 0:
		return vector
	else:
		return vector / extrema

## Normalize an array of vectors by the extrema of the longest vector.
func normalize_vectors(vectors : Array[Vector2]) -> Array[Vector2]:
	var longest := get_extrema(vectors)
	var normalized_vectors : Array[Vector2] = []
	for v in vectors:
		normalized_vectors.append(normalize_vector(v, longest))
	return normalized_vectors

## Generate a circular histogram from an array of phases.
func circular_histogram(phases : Array[float], bins : int, bin_width : float) -> Array[int]:
	var hist : Array[int] = []
	hist.resize(bins)

	for angle in phases:
		var index := int(angle / bin_width) % bins
		hist[index] += 1

	return hist

func draw_circular_histogram(hist : Array[int], bin_width) -> void:
	for i in range(hist.size()):
		var radius = hist[i]
		draw_arc(Vector2.ZERO, radius, i, i + bin_width, 64, bin_colors[i], radius)

func random_color() -> Color:
	var color : Color = Color.WHITE
	color.r = randf()
	color.g = randf()
	color.b = randf()
	return color

func random_colors(n) -> Array[Color]:
	var colors : Array[Color] = []
	for i in range(n):
		colors.append(random_color())
	return colors

