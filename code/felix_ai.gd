extends AI

enum {Eatery, Storage, Way, Kitchen, Corr}

func move_options() -> void:
	match step:
		0:
			var way_now: int = randi_range(0, 2)
			match way_now:
				0:
					if _is_room_empty(Storage):
						move_to(Storage)
						print('moved')
				1:
					if _is_room_empty(Way):
						move_to(Way)
						print('moved')
				2:
					# Returns to start position.
					move_to(Eatery, State.PRESENT, -step)
					print('moved')
		1:
			var way_now: int = randi_range(0, 2)
			match way_now:
				0:
					if _is_room_empty(Kitchen):
						move_to(Kitchen)
						print('moved')
				1:
					if _is_room_empty(Corr):
						move_to(Corr)
						print('moved')
				2:
					# Returns to start position.
					move_to(Eatery, State.PRESENT, -step)
					print('moved')
		_:
			# Defensive reset if step gets out of expected range.
			step = 0
