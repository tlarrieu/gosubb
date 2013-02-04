module Actions
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

		@untackleable = true

		@pitch.lock
		true
	end

	def stand_up!
		if @health == Health::STUN_0
			@has_moved = true
			@health = Health::OK
			@cur_ma -= 3
			notify_health_change
			true
		else
			false
		end
	end

	def blitz!
		if can_blitz?
			@team.blitz!
		else
			false
		end
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
			return @team.pass!
		end
		return false
	end

	def handoff target_player
		if can_handoff_to? target_player
			@can_move, @has_ball = false, false
			x, y = target_player.pos
			Sample["pass_fast.ogg"].play
			@ball.move_to! x, y
			event! :pass
			return @team.handoff!
		end
		return false
	end

	def catch! modifiers=0
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

	def lose_ball
		if has_ball?
			@ball.scatter!
			@has_ball = false
		end
	end

	# ----------------------
	# ------- Fight --------
	# ----------------------

	def tackle
		end_turn
	end

	def block target_player
		if can_block? target_player
			parent.push_game_state CombatState.new( :attacker => self, :defender => target_player, :pitch => @pitch )
			return true
		end
		return false
	end

	def down target_player
		target_player.end_turn
		target_player.injure!
	end

	def injure!
		if roll + roll > stats[:arm]
			@health = roll :injury
			case @health
			when Health::STUN_0..Health::STUN_2
				Sample["fall.ogg"].play
			when Health::KO
				Sample["ko.ogg"].play
			when Health::DEAD
				Sample["hurt.ogg"].play
			end
		else
			@health = Health::STUN_1
			Sample["fall.ogg"].play
		end
		lose_ball
		notify_health_change
	end

	def push target_player
		Sample["punch.ogg"].play
	end

	def stumble target_player
		if @skills.include? :dodge
			push target_player
		else
			down target_player
		end
	end
end