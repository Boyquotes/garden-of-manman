extends GOAPAction
class_name ActionPuzzle

func name()->StringName:
	return 'A puzzle'

func is_valid(local_state:Dictionary)->bool:
	return local_state.has(NL.puzzle)

func get_cost(local_state:Dictionary)->float:
	return randf_range(0.1,1)

func get_inputs(local_state:Dictionary)->Dictionary:
	return{}

func get_outputs(local_state:Dictionary)->Dictionary:
	return{
		NL.player_tension:1
	}

func perform(local_state: Dictionary, dt: float)->bool:
	var puzzle = local_state[NL.puzzle]
	return puzzle.perform(local_state,dt)