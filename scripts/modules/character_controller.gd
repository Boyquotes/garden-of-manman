extends RigidBody3D
class_name RigidCharacter

var root = self
func _init() -> void:
	setup_body()
func _ready():
	add_to_group(NL.character)
	connect_signals()

var dt := 0.0
func _physics_process(delta):
	dt = delta
	move_body()
	bungee_time()

func body_entered(body):
	set_damp()
func body_exited(body):
	set_damp()

func connect_signals():
	connect("body_entered",body_entered)
	connect("body_exited", body_exited)

func setup_body():
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	max_contacts_reported = 2
	contact_monitor = true
	
	var material := PhysicsMaterial.new()
	material.friction = 0.1
	material.rough = false
	material.bounce = 0.0
	material.absorbent = true
	physics_material_override = material


func set_damp():
	if on_floor:
		linear_damp = 10
		return
	if on_wall:
		linear_damp = 3 
		return
	linear_damp = 1

var bungee_duration := 0.1
var on_floor_bungee := 0.0
var on_wall_bungee := 0.0
var on_ceiling_bungee := 0.0
func bungee_time():
	on_floor_bungee -= dt
	on_wall_bungee -= dt
	on_ceiling_bungee -= dt
	
	on_floor = on_floor_bungee > 0
	on_wall = on_wall_bungee > 0
	on_ceiling = on_ceiling_bungee > 0

var on_floor:=false
var on_wall:=false
var on_ceiling:=false
func _integrate_forces(state: PhysicsDirectBodyState3D):
	for i in state.get_contact_count():
		var normal = state.get_contact_local_normal(i)
		var dist = normal.dot(basis.y)
		if dist > 0.7:#45 degrees
			on_floor_bungee = bungee_duration
			continue
		if dist < -0.7:
			on_ceiling_bungee = bungee_duration
			continue
		on_wall_bungee = bungee_duration

var inverted_velocity := Vector3.ZERO
var local_velocity := Vector3.ZERO
@onready var custom_transform = global_transform
func move_body():
	inverted_velocity= custom_transform.inverse().basis * linear_velocity
	var velo :Vector3=inverted_velocity
	
	var abs_x = abs(local_velocity.x)
	var abs_y = abs(local_velocity.y)
	var abs_z = abs(local_velocity.z)
	abs_x = max(abs_x,abs(velo.x))
	abs_y = max(abs_y,abs(velo.y))
	abs_z = max(abs_z,abs(velo.z))
	
	velo.x = clampf(velo.x + local_velocity.x, -abs_x, abs_x)
	velo.y = clampf(velo.y + local_velocity.y, -abs_y, abs_y)
	velo.z = clampf(velo.z + local_velocity.z, -abs_z, abs_z)
	
	local_velocity = Vector3.ZERO
	linear_velocity = custom_transform.basis * velo
#	var _collided=move_and_slide()
