extends Resource
class_name GOAPGoal

func name() -> StringName:
	return 'G default'

func is_valid(local_state:Dictionary)->bool:
	return true

func priority(local_state:Dictionary)->float:
	return 1

func get_result(local_state:Dictionary)->Dictionary:
	return{}
