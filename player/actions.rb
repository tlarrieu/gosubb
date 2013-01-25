
module Actions
	def blitz!
		@blitz = true if can_blitz
	end

	# ----------------------
	# ------- Moves --------
	# ----------------------

	def move_to! x, y
		return false unless can_move_to?(x, y)
		coords = [x, y]

		# Getting @path through A*
		path = a_star @pitch, pos, coords
		return false unless path.include? coords and path.length <= @cur_ma
		@target_x, @target_y = to_screen_coords [x, y]
		@cur_node  = 0
		@path      = path
		@has_moved = true

		@pitch.lock
		true
	end

	def push_to! x, y
		return false if @pitch[[x,y]]

		@target_x, @target_y = to_screen_coords [x,y]
		@path     = [[x, y]]
		@cur_node = 0

		@pitch.lock
		true
	end

	# ----------------------
	# ---- Ball Handling ---
	# ----------------------

	def pass target_player
		if can_pass_to? target_player
			@can_move, @has_ball = false, false

			case roll_agility @stats[:agi]
			when :success
				x, y = target_player.pos
				Sample["pass_med.ogg"].play
				@ball.move_to! x, y
				event! :pass
			when :fumble
				@ball.scatter!
				event! :fumble
			else
				coords = @ball.scatter! 3, target_player.pos
				if @pitch[coords] == target_player
					event! :pass
				else
					event! :fail
				end
			end
			return true
		end
		return false
	end

	def catch! modifiers=[]
		res = roll_agility @stats[:agi], modifiers
		if res == :success
			@has_ball = true
			event! :catch
			return true
		else
			@ball.scatter!
			event! :fail
		end
		false
	end

	# ----------------------
	# ------- Fight --------
	# ----------------------

	def tackle target_player
		target_player.end_turn
	end

	def block target_player
		if can_block? target_player
			parent.push_game_state CombatState.new( :attacker => self, :defender => target_player, :pitch => @pitch )
			return true
		end
		return false
	end

	def down target_player
		target_player.end_turn if target_player.team == @pitch.active_team
		target_player.injure!
	end

	def injure!
		if roll + roll > stats[:arm]
			@state = roll :injury
			case @state
			when Health::STUN_0, Health::STUN_1, Health::STUN_2
				Sample["fall.ogg"].play
			when Health::KO
				Sample["ko.ogg"].play
			when Health::DEAD
				Sample["hurt.ogg"].play
			end
		else
			@state = Health::STUN_1
			Sample["fall.ogg"].play
		end
	end

	def push target_player
		Sample["punch.ogg"].play
	end

	def stumble target_player
		if @abilities.include? :dodge
			push target_player
		else
			down target_player
		end
	end
end