extends GridContainer
const WEIGHT_MATRIX = [
	[ 100, -20,  10,   5,   5,  10, -20, 100],
	[ -20, -50,  -2,  -2,  -2,  -2, -50, -20],
	[  10,  -2,  -1,  -1,  -1,  -1,  -2,  10],
	[   5,  -2,  -1,  -1,  -1,  -1,  -2,   5],
	[   5,  -2,  -1,  -1,  -1,  -1,  -2,   5],
	[  10,  -2,  -1,  -1,  -1,  -1,  -2,  10],
	[ -20, -50,  -2,  -2,  -2,  -2, -50, -20],
	[ 100, -20,  10,   5,   5,  10, -20, 100]
]
var grid_data = {}
var AI = 0
var current_player = 1
const NEG_INF= -100000000
const POS_INF= 100000000
const CORNERS = [Vector2i(0,0), Vector2i(7,0), Vector2i(0,7), Vector2i(7,7)]
@export var slot_scene : PackedScene
@export var Scorelable : Label
@export var advantageBar : ProgressBar

var black_time_left = 0
var white_time_left = 0
@onready var game_timer = $GameTimer

@onready var black_lbl = $CanvasLayer/HUD/BlackTimerLabel 
@onready var white_lbl = $CanvasLayer/HUD/WhiteTimerLabel
var history = []
@onready var turn_icon = $CanvasLayer/HUD/TurnDisplay/TurnIcon

@onready var undo_btn = $CanvasLayer/HUD/UndoButton

@onready var game_over_scrn = $CanvasLayer/GameOverScreen
@onready var winner_label = $CanvasLayer/GameOverScreen/WinnerLabel
@onready var restart_btn = $CanvasLayer/GameOverScreen/RestartButton

@onready var back_btn = $CanvasLayer/HUD/BackButton

const DIRECTIONS = [
	Vector2i(0, -1), 
	Vector2i(0, 1),   
	Vector2i(-1, 0),  
	Vector2i(1, 0),   
	Vector2i(-1, -1), 
	Vector2i(1, -1),  
	Vector2i(-1, 1),  
	Vector2i(1, 1)    
]
func _ready():
	
	if GameGlobals.is_ai_mode:
		AI= 1
	else: 
		AI=0
	if GameGlobals.is_timer_enabled:
		
		black_time_left = GameGlobals.timer_duration
		white_time_left = GameGlobals.timer_duration
		black_lbl.show()
		white_lbl.show()
		update_timer_labels()
		game_timer.timeout.connect(_on_timer_tick)
		game_timer.start()
	else:
		black_lbl.hide()
		white_lbl.hide()
	if undo_btn: 
		if GameGlobals.is_undo_enabled:
			undo_btn.show()
			undo_btn.pressed.connect(_on_undo_pressed)
		else:
			undo_btn.hide()
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	for y in range(8):
		for x in range(8):
			var slot= slot_scene.instantiate()
			add_child(slot)
			slot.set_grid_pos(Vector2i(x,y))
			slot.slot_clicked.connect(_on_slot_clicked)
			grid_data[Vector2i(x,y)] = slot
			
	var initial_slot =grid_data[Vector2i(3,3)]
	initial_slot.set_state(2)
	initial_slot =grid_data[Vector2i(4,4)]
	initial_slot.set_state(2)
	initial_slot =grid_data[Vector2i(3,4)]
	initial_slot.set_state(1)
	initial_slot =grid_data[Vector2i(4,3)]
	initial_slot.set_state(1)
	
	#Testing start
	#grid_data[Vector2i(0,0)].set_state(1) 
	#grid_data[Vector2i(1,0)].set_state(2)
	#
	#grid_data[Vector2i(0,1)].set_state(1)
	#grid_data[Vector2i(0,2)].set_state(2) 
	#Testing ends
	
	update_game_logic()
	save_current_state()
	update_turn_indicator()
	restart_btn.pressed.connect(_on_restart_pressed)
	game_over_scrn.hide()
func update_turn_indicator():
	if current_player == 1:
		turn_icon.texture = preload("res://black.png")
	else:
		turn_icon.texture = preload("res://white.jpg")

func _on_back_pressed():
	if game_timer:
		game_timer.stop()
		
	get_tree().change_scene_to_file("res://mainMenu.tscn")	
func save_current_state():
	var state = {
		"grid":{},
		"current_player":current_player,
		"black_time":black_time_left,
		"white_time":white_time_left
	}
	for pos in grid_data:
		state["grid"][pos] = grid_data[pos].state
	history.append(state)	
func restore_state(state):
	for pos in state["grid"]:
		var saved_state = state["grid"][pos]
		grid_data[pos].set_state(saved_state)
	current_player = state["current_player"]
	black_time_left = state["black_time"]
	white_time_left = state["white_time"]
	update_game_logic() 
	if GameGlobals.is_timer_enabled:
		update_timer_labels()
func _on_undo_pressed():
	if history.size()== 0:
		return
	var steps_to_pop = 1
	if AI==1:
		if current_player ==1 : 
			steps_to_pop+=1
		else: 
			return 
	if history.size() < steps_to_pop:
		steps_to_pop = history.size()
	var prev_state = null
	for i in range(steps_to_pop):
		prev_state = history.pop_back()
	if prev_state:
		restore_state(prev_state)
		
func _on_timer_tick():
	if current_player==1:
		black_time_left-=1
		if black_time_left <=0:
			game_over_by_timeout(2)
	else:
		white_time_left -= 1
		if white_time_left <= 0:
			game_over_by_timeout(1)
	update_timer_labels()
func update_timer_labels():
   
	var b_min = int(black_time_left / 60)
	var b_sec = black_time_left % 60
	var w_min = int(white_time_left / 60)
	var w_sec = white_time_left % 60

	black_lbl.text = "Black  : Time: %02d:%02d" % [b_min, b_sec]
	white_lbl.text = "White  : Time: %02d:%02d" % [w_min, w_sec]
	
func game_over_by_timeout(winner):
	game_timer.stop() # Stop the clock!
	print("Time Up! Winner is Player ", winner)
func _on_slot_clicked(pos):
	print("Clicked at: ", pos)	
	
	var states = game_logic(pos,current_player)
	if (states.size()==0):
		print("Not possible to put it ")
		return
	save_current_state()
	var slot_place=  grid_data[pos]
	slot_place.set_state(current_player)
	for state in states:
		grid_data[state].set_state(current_player)
	var is_game_over = update_game_logic()
	if is_game_over:
		return
	switch_turn()
	
	
func game_logic(placed_pos, my_color):
	var captured = []
	var opponent = 3 - my_color
	
	for dir in DIRECTIONS:
		var current_line = []
		var curr_pos = placed_pos + dir
		
		while grid_data.has(curr_pos) and grid_data[curr_pos].state == opponent:
			current_line.append(curr_pos)
			curr_pos += dir
		if grid_data.has(curr_pos) and grid_data[curr_pos].state == my_color:
			if current_line.size() > 0:
				captured.append_array(current_line)

	return captured
			
		
func has_valid_move(player_color):
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x,y)
			if grid_data[pos].state == 0:
				var potential_flips = game_logic(pos,player_color)
				if potential_flips.size() > 0 :
					return true
	return false


func update_game_logic():
	var black_score = 0
	var white_score = 0
	for slot in grid_data.values():
		if slot.state == 1 :
			black_score+=1
		elif slot.state == 2 :
			
			white_score +=1 
	update_ui_visuals(black_score, white_score)
	#if has_node("CanvasLayer/ScoreLabel"):
		#$CanvasLayer/ScoreLabel.text  = "Black: %d | White: %d" % [black_score, white_score]
	if black_score == 0 or white_score == 0 or (black_score + white_score == 64):
		game_over(black_score, white_score)
		return true
	return false
func update_ui_visuals(black,white):
	if Scorelable : 
		Scorelable.text= "BLACK: %d , WHITE: %d" % [black, white]
	if advantageBar:
		var total = black + white
		if total > 0:
			
			var percentage = (float(black) / float(total)) * 100
			
			var tween = create_tween()
			tween.tween_property(advantageBar, "value", percentage, 0.3)

func game_over(b_score, w_score):
	print("GAME OVER!")
	var winner_text = ""
	if b_score > w_score:
		winner_text = "BLACK WINS!"
	elif w_score > b_score:
		winner_text= "WHITE WINS!"
	else:
		winner_text = "IT'S A TIE!"
	winner_label.text = winner_text + "\n%d - %d" % [b_score, w_score]
	game_over_scrn.show()
	game_over_scrn.move_to_front()
func _on_restart_pressed():
	get_tree().reload_current_scene()

func switch_turn():
	var next_player = 3- current_player
	if has_valid_move(next_player):
		current_player = next_player
		print("Turn switched to : ",current_player)
		if AI and current_player==2: 
			make_AI_move(get_board_state(), current_player)
			
	else  :
		if has_valid_move(current_player):
			print("Player ",current_player," goes again")
			if AI and current_player ==2: 
				make_AI_move(get_board_state(), current_player)
		else : 
			game_over_announce()
	update_turn_indicator()
func game_over_announce():
	var black = 0
	var white = 0
	for slot in grid_data.values():
		if slot.state == 1: black += 1
		elif slot.state == 2: white += 1
	game_over(black, white)

func get_board_state():
	var state = {}
	for pos in grid_data:
		state[pos] = grid_data[pos].state 
	return state

func get_valid_moves_virtual(board_state,player):
	print()
	var valid_moves = []
	var opponent = 3- player 
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x,y)
			if board_state[pos]!=0 : 
				continue
			for dir in DIRECTIONS:
				var current = dir + pos
				var dist=  0
				while board_state.has(current) and board_state[current]==opponent:
					current+=dir
					dist +=1 
				if dist > 0 and board_state.has(current)and board_state[current]==player : 
					valid_moves.append(pos)
					break
	return valid_moves

func  simulate_AI(board,player , move_pos):
	var new_board = board.duplicate()
	var opponent = 3 - player
	new_board[move_pos] = player
	
	for dir in DIRECTIONS:
		var captured =[]
		var curr = move_pos + dir 
		while new_board.has(curr) and new_board[curr]==opponent:
			captured.append(curr)
			curr += dir 
		if captured.size()> 0 and new_board.has(curr) and new_board[curr]==player:
			for cap in captured:
				new_board[cap] = player
	return new_board

			
					 
	
func heuristics (curr,opponent):
	return curr - opponent # curr score should be better 
func heuristics_updated(board, player):
	var my_score = 0
	var opponent_score = 0
	var opponent = 3 - player
	
	# --- PHASE 1: END GAME (Greedy Mode) ---
	# If the board is nearly full (>54 pieces), forget strategy and just WIN.
	var empty_spots = 0
	for pos in board:
		if board[pos] == 0: empty_spots += 1
		
	if empty_spots < 10:
		var diff = 0
		for pos in board:
			if board[pos] == player: diff += 1
			elif board[pos] == opponent: diff -= 1
		return diff * 1000 
	
	
	for pos in board:
		var piece = board[pos]
		if piece == player:
			my_score += WEIGHT_MATRIX[pos.y][pos.x]
		elif piece == opponent:
			opponent_score += WEIGHT_MATRIX[pos.y][pos.x]

	
	var my_moves = get_valid_moves_virtual(board, player).size()
	var op_moves = get_valid_moves_virtual(board, opponent).size()
	
	var mobility_score = (my_moves - op_moves) * 15
	
	return (my_score - opponent_score) + mobility_score
func minimax_AI_pruned(board,depth,alpha,beta,is_maximising,active_player):
	var valid_moves = get_valid_moves_virtual(board, active_player)
	if depth == 0 or valid_moves.size() == 0:
		return [heuristics_updated(board,current_player),null]
	
	var best_move = null
	
	if is_maximising: 
		var max_score = NEG_INF
		for valid_move in valid_moves: 
			var new_board= simulate_AI(board,active_player,valid_move)
			
			
			var eval = minimax_AI_pruned(new_board,depth-1,alpha,beta,false,(3-active_player))
			var score = eval[0]
			if score > max_score:
				max_score =score
				best_move = valid_move
			alpha = max(alpha, score)
			if beta<= alpha : 
				break
		return [max_score,best_move]
	else : 
		var min_score = POS_INF
		for valid_move in valid_moves: 
			var new_board= simulate_AI(board,active_player,valid_move)
			
			
			var eval = minimax_AI_pruned(new_board,depth-1,alpha,beta,true,(3-active_player))
			var score = eval[0]
			if score < min_score:
				min_score =score
				best_move = valid_move
			beta = min(beta,score)
			if beta<= alpha : 
				break
		return [min_score,best_move]
			
func make_AI_move(board_state,player):
	print("AI move now")
	await get_tree().create_timer(1.0).timeout
	var best = minimax_AI_pruned(board_state,5,NEG_INF,POS_INF,true,player)
	var score = best[0]
	var path = best[1]
	if path != null :
		print("AI chose ",path)
		_on_slot_clicked(path)
	else : 
		print("AI has no moves")
		switch_turn()
	#print(path)
	#board_state[path] = player
	#var slot = grid_data[path]
	#slot.set_state(path)
	print("AI move completed ")
	
		
		
			
