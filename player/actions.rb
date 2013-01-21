
module Actions
	def select
		if to_pitch_coords( [ $window.mouse_x, $window.mouse_y ] ) == pos
			@selected = true
		else
			@selected = false
		end
	end

	def unselect
		@selected = false
	end

	def blitz!
		@blitz = true if can_blitz
	end

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

	def can_move_to? x, y
		coords = [x, y]
		# Checking that [x, y] is in movement allowance range
		return false if dist(pos, [x,y], :infinity) > @stats[:ma]
		# Checking that coordinates are within pitch range
		return false unless (0..25).include? coords[0] and (0..14).include? coords[1]
		# Checking if player can move
		return false unless can_move? and @team == @pitch.active_team
		# Checking that target location is empty
		return false unless @pitch[coords].nil?
		# Checking if a path exists to x, y
		return false if stuck?
		return true
	end

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
			when :stun
				Sample["fall.ogg"].play
			when :ko
				Sample["ko.ogg"].play
			when :out
				Sample["hurt.ogg"].play
			end
		else
			@state = :hit
			Sample["fall.ogg"].play
		end
		on_state_change
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
end