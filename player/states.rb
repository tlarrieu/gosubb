module States
	def [] symb
		raise ArgumentError, "#{symb}" unless symb.is_a? Symbol
		raise ArgumentError, "#{symb}" unless @stats.keys.include? symb

		stats[symb]
	end

	def moving?
		return [@target_x, @target_y] != [@x, @y]
	end

	def can_move?
		@can_move and @health == Health::OK
	end

	def can_move_to? x, y
		coords = [x, y]
		# Checking that [x, y] is in movement allowance range
		return false if dist(pos, [x,y], :infinity) > @stats[:ma]
		# Checking that coordinates are within pitch range
		return false unless (0..25).include? coords[0] and (0..14).include? coords[1]
		# Checking if player can move
		return false unless can_move? and @team.active?
		# Checking that target location is empty
		return false if @pitch[coords]
		# Checking if a path exists to x, y
		return false if stuck?
		return true
	end

	def cant_move!
		@can_move = false
		@cur_ma   = 0
		notify_ring_change
	end

	def has_moved?
		@has_moved
	end

	def has_moved!
		@has_moved = true
	end

	def stuck?
		(-1..1).each do |x|
			(-1..1).each do |y|
				unless x == 0 and y == 0
					key = [pos, [x,y]].transpose.map { |c| c.reduce(:+) }
					return false if @pitch[key].nil?
				end
			end
		end

		true
	end

	# FIXME : the following condition is not enough, we are missing some cases
	def can_pass_to? target_player
		can_move? and @has_ball and target_player and target_player != self  and target_player.team == @team
	end

	def close_to? player
		return dist(self, player, :infinity) == 1
	end

	def can_block? target_player
		((can_move? and @cur_ma == @stats[:ma]) or @blitz) and target_player and target_player.team != @team and target_player.health == Health::OK and close_to?(target_player)
	end

	def has_ball?
		@has_ball
	end

	def can_blitz?
		not @team.blitz? and can_move?
	end

	def on_pitch?
		return true if @health < Health::KO
		return false
	end

	def pos
		to_pitch_coords [@x, @y]
	end

	def screen_pos
		[@x,@y]
	end
end