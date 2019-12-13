tool
extends Spatial
class_name ScatterSimple
"""
Custom node to fill a space with many instances of a Mesh.
First, it looks for a MeshInstance in the user provided path and if one was found, it sets up a
MultimeshInstance node that takes care of the actual instancing.
The ScatterSimple node simply provides a new random Transform for each instances.
"""

onready var _rng := RandomNumberGenerator.new()

export(String, FILE) var mesh_path := "" setget set_mesh_path
export var amount := 50 setget set_amount
export var area_dimensions := Vector2(5.0, 5.0) setget set_area_dimensions
export var random_seed := 0 setget set_random_seed


func _update() -> void:
	"""
	Set up the multimesh and randomly place all the instances. This is the main function of this
	script and should be called when a parameter changes to see the result in real time.
	"""

	if not get_tree():
		# The tool is not completely ready yet, trying to update now will cause errors.
		return

	# Reset the RNG so we get the same result for each seed
	_ensure_rng_exists()
	_rng.set_seed(random_seed)

	# Retrieve the MultiMeshInstance node
	var mmi := _initialize_multimesh_instance()

	for i in range(amount):
		# For each instance, get a random transform and feed it to the multimesh
		var t := _get_random_transform()
		mmi.multimesh.set_instance_transform(i, t)


func _initialize_multimesh_instance() -> MultiMeshInstance:
	"""
	The MultiMeshInstance node is made of two parts : The node you see in the node tree and the
	multimesh resource it holds. Both of them needs to be initialized to be useful
	"""
	var mmi = _get_or_create_multimesh_instance()
	# The mesh_instance is the mesh used to create instances and fill the area with
	var mesh_instance = _get_mesh_instance_from_path()

	# Setting up the multimesh itself. It needs to know how many instances, the mesh and material
	# used, and whether the instances are placed using 2D or 3D transforms
	mmi.material_override = mesh_instance.get_surface_material(0)
	mmi.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	mmi.multimesh.mesh = mesh_instance.mesh
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.instance_count = amount

	return mmi


func _get_or_create_multimesh_instance() -> MultiMeshInstance:
	"""
	If the node already exists, returns it. Otherwise, create a new node and add it to the
	scene tree
	"""
	var instance: MultiMeshInstance
	if has_node("MultiMeshInstance"):
		# Only calling get_node after checking the result of has_node prevents a warning if the
		# node doesn't exist
		instance = get_node("MultiMeshInstance")
	else:
		# The node doesn't exist so we create a new one.
		instance = MultiMeshInstance.new()
		instance.set_name("MultiMeshInstance")

		# If the node owner is not set, or set to anything else, it will not appear in the scene
		# tree on the left.
		add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())

	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()

	return instance


func _get_mesh_instance_from_path() -> MeshInstance:
	"""
	Opens the scene located in 'mesh_path' and returns the first MeshInstance it can find
	"""
	var scene = load(mesh_path).instance()
	for child in scene.get_children():
		if child is MeshInstance:
			scene.queue_free()
			return child
	return null


func _get_random_transform() -> Transform:
	"""
	Generates a random transform constrained in the area defined by the user
	"""

	# Generate a random position in a square centered around the node's origin
	var px := _rng.randf_range(-0.5, 0.5) * area_dimensions.x
	var py := 0.0
	var pz := _rng.randf_range(-0.5, 0.5) * area_dimensions.y
	var position = Vector3(px, py, pz)

	# Generate random rotation in radian around the vertical axis
	var rx := 0.0
	var ry := _rng.randf_range(-PI, PI)
	var rz := 0.0

	# Generate a random scale
	var sx := _rng.randf_range(0.5, 1.5)
	var sy := _rng.randf_range(0.5, 1.5)
	var sz := _rng.randf_range(0.5, 1.5)
	var scale := Vector3(sx, sy, sz)

	# Create the transform and apply the three operations
	var t := Transform()
	t.scaled(scale)
	t = t.rotated(Vector3.RIGHT, rx)
	t = t.rotated(Vector3.UP, ry)
	t = t.rotated(Vector3.BACK, rz)
	t.origin = position

	return t

func _ensure_rng_exists() -> void:
	if not _rng:
		_rng = RandomNumberGenerator.new()

func set_mesh_path(val: String) -> void:
	mesh_path = val
	_update()


func set_amount(val: int) -> void:
	if val > 0:
		amount = val
		_update()


func set_area_dimensions(val: Vector2) -> void:
	if val.x >= 0 and val.y >= 0:
		area_dimensions = val
		_update()


func set_random_seed(val: int) -> void:
	random_seed = val
	_ensure_rng_exists()
	_rng.set_seed(random_seed)
	_update()
