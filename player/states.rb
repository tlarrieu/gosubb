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
		@can_move
	end

	def cant_move!
		@can_move = false
		@cur_ma   = 0
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
		@can_move and @has_ball and target_player and target_player != self  and target_player.team == @team
	end

	def close_to? player
		return dist(self, player, :infinity) == 1
	end

	def can_block? target_player
		((@can_move and @cur_ma == @stats[:ma]) or @blitz) and target_player and target_player.team != @team and close_to?(target_player)
	end

	def has_ball?
		@has_ball
	end

	def can_blitz?
		not @team.blitz?
	end

	def pos
		to_pitch_coords [@x, @y]
	end

	def screen_pos
		[@x,@y]
	end
end