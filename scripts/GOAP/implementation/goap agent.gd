extends Node
class_name GOAPAgent

@onready var root:Node3D=get_parent().root
var local_state:={}
var planner :GOAPPlanner

var goals:=[]:
	get:
		return goals
	set(value):
		goals = value
		goal_size = goals.size()

var current_goal:GOAPGoal
var current_plan:Array:
	get:
		return current_plan
	set(value):
		current_plan = value
		plan_size = current_plan.size()

var goal_size:=0
var plan_size:=0
var current_step:=0

@export var show_local_state := false
@export var planner_limits:=Vector2(3,6)
var loop_plan:= false
@onready var debug_display = get_node_or_null('../debug_display')

func _init() -> void:
	name = 'goap_agent'

func _ready() -> void:
	add_to_group(NL.goap_save_load)
	planner = get_planner()
	set_interface()
	init_local_state()

func _enter_tree() -> void:
	_load()
func _exit_tree() -> void:
	_save()

func init_local_state():
	set_local_state(NL.root,root)
	set_local_state(NL.agent,self)
	set_local_state(NL.plan_width,planner_limits.x)
	set_local_state(NL.plan_depth,planner_limits.y)
	set_local_state(NL.unique_steps,false)

func get_planner() -> GOAPPlanner:
	return Goap.get_action_planner()

func set_interface():
	root.set_meta(NL.toggle_goap_agent,toggle_goap_agent)

func toggle_goap_agent(on:bool):
	var mode = Node.PROCESS_MODE_INHERIT 
	if !on:
		mode =  Node.PROCESS_MODE_DISABLED
	process_mode = mode

var dt:=0.0
func _process(delta: float) -> void:
	dt = delta
	generate_plan()
	follow_plan()

func set_local_state(key,value):
	if local_state.has(key):
		if local_state[key] == value:	return
	local_state[key] = value
	debug_local_state()

func follow_plan():
	if current_step >= plan_size:
		if loop_plan:
			current_step=0
		return
	var action = current_plan[current_step]
	var completed = action.perform(local_state, dt)
	if completed:
		current_step += 1

var generate_cd :=0.0
func generate_plan():
	if generate_cd >0:
		generate_cd -= dt
		return
	if !PerformanceCap.allow_goap_planner(): return
	generate_cd = 1
	
	var best_goal = select_goal()
	if best_goal == null: return
	if best_goal == current_goal: return
	current_goal = best_goal
	current_step = 0
	
	current_goal.perform(local_state,dt)
	current_plan = planner.get_plan(current_goal, local_state)
	
	debug_plan()

func select_goal()-> GOAPGoal:
	goals.sort_custom(compare_goals)
	var iterations:= mini(3,goal_size)
	for i in iterations:
		var best_goal :GOAPGoal= goals[i]
		if !best_goal.is_valid(local_state): 
			continue
		if best_goal.priority(local_state) <= 0: 
			continue
		return best_goal
	return current_goal

func compare_goals(a:GOAPGoal,b:GOAPGoal)->bool:
	if !a.is_valid(local_state):
		return false
	return a.priority(local_state) > b.priority(local_state)


func debug_local_state():
	if !show_local_state: return
	if debug_display == null: return
	var keys = local_state.keys()
	var values = local_state.values()
	var iterations = local_state.size()
	var output:=''
	for i in iterations:
		output += keys[i]
		output += ': '
		output += get_string(values[i])
		output += ', '
	debug_display.set_content('local_state',output)

func debug_plan():
	if debug_display == null: return
	var content = planner.print_plan(current_plan)
	debug_display.set_content('plan',content)
	
	var cost := str(current_goal.priority(local_state))
	var goal_name = current_goal._name()
	goal_name +=", score: " 
	goal_name += cost.left(4)
	debug_display.set_content('goal', goal_name)

func get_string(_value)->String:
	if _value == null:
		return 'null'
	if _value is int:
		return str(_value)
	if _value is float:
		return str(_value)
	if _value is String:
		return _value
	if _value is Node:
		return _value.name
	return ''

func get_closest_node3d(group:StringName, range:=100.0)-> Node3D:
	if local_state.has(group):
		var node = local_state[group]
		if node == null:
			local_state.erase(group)
		else:
			return local_state[group]
	var root_pos = local_state.root.global_position
	var node = WorldState.get_closest_node_3d(group, root_pos, range)
	local_state[group] = node
	return node


func _save():
	if !can_process():
		return
	_print('agent saving goals')
	for goal in goals:
		goal._save()

func _load():
	_print('agent loading goals')
	for goal in goals:
		goal._load()

func _print(line:String):
	return
	print(line)
