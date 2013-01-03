require 'chingu'
include Chingu
include Gosu
require 'singleton'

require 'helpers'

class Ball < GameObject
	include Helpers::Measures

	def initialize options = {}
		super :x => 0, :y => 0, :image => Image["ball.gif"], :zorder => 1000
		@pitch    = options[:pitch] or raise "Unable to fetch pitch for #{self}"
		@velocity = 0.4

		@target_x, @target_y = 0, 0
		@@instance = self
	end

	##
	# Takes pitch coordinates
	# TODO : we gotta handle the case when the ball leaves the pitch
	def move_to! x, y
		coords = [x, y]
		return nil if coords.nil?
		unless coords == pos
			@pitch.lock
			dist = dist pos, coords
			@dx  = (x - @x) / dist
			@dy  = (y - @y) / dist
			x, y = to_screen_coords [x, y]
			set_pos! x, y, true
		end
	end

	##
	# Takes pitch coordinates
	def move_by! x, y
		move_to! @x + y, @y + y
	end

	##
	# Takes screen coordinates
	def set_pos! x, y, animate=false
		@target_x = x
		@target_y = y
		unless animate
			@x = x
			@y = y
		end
	end

	def screen_pos
		[@x, @y]
	end

	def pos
		to_pitch_coords screen_pos
	end

	def scatter! dist=1, coords=pos
		return nil if coords.nil? or dist == 0

		t_x, t_y = coords
		x, y = 0, 0
		dist.times do
			while [x, y] == [0,0]
				x = [-1, 0, 1].sample
				y = [-1, 0, 1].sample
			end
			t_x += x
			t_y += y
		end

		move_to! t_x, t_y
	end

	def update
		ms = $window.milliseconds_since_last_tick rescue nil
		unless [@target_x, @target_y] == [@x, @y]
			_dist = dist [@target_x, @target_y], [@x, @y], :cartesian

			vx     = (@target_x - @x) / _dist * @velocity * ms
			vy     = (@target_y - @y) / _dist * @velocity * ms

			if (@x - @target_x).abs < 5 then @x = @target_x else @x = @x + vx end
			if (@y - @target_y).abs < 5 then @y = @target_y else @y = @y + vy end

			if [@target_x, @target_y] == [@x, @y]
				x, y = to_pitch_coords [@x, @y]
				@pitch[[x,y]].catch! unless @pitch[[x,y]].nil?
				@pitch.unlock
			end
		end
	end
end
