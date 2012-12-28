require 'chingu'
include Chingu
include Gosu
require 'singleton'

require 'helper'

class Ball < GameObject
	#include Singleton

	def initialize options = {}
		super :x => 0, :y => 0, :image => Image["ball.png"], :zorder => 1000
		@pitch    = options[:pitch] or raise "Unable to fetch pitch for #{self}"
		@velocity = 0.4

		@target_x, @target_y = 0, 0
		@@instance = self
	end

	##
	# Takes pitch coordinates
	def move_to! x, y
		coords = [x, y]
		return nil if coords.nil?
		unless coords == pos
			@pitch.lock
			dist = Measures.dist pos, coords
			@dx  = (x - @x) / dist
			@dy  = (y - @y) / dist
			x, y = Measures.to_screen_coords [x, y]
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
		Measures.to_pitch_coords screen_pos
	end

	def scatter! dist=1, coords=pos
		return nil if coords.nil? or dist == 0 

		res    = pos
		x, y   = coords
		_x, _y = -100, -100
		# Checking that we are within pitch range and
		# TODO: We shall out-of-pitch case by re-scattering the ball from where it went out
		until x + _x >= 0 and x + _x < Pitch::WIDTH \
			and y + _y >= 0 and y + _y < Pitch::HEIGHT \
			and res != pos

			fixed_coord   = :x
			fixed_coord   = :y if rand(2) == 1

			case fixed_coord
			when :x
				_x = dist * (rand(2) - 1)
				_y = rand( 2 * dist ) - dist
			when :y
				_x = rand( 2 * dist ) - dist
				_y = dist * (rand(2) - 1)
			end

			res = [x + _y, y + _y]
		end

		move_to! res[0], res[1]
	end

	def update
		ms = $window.milliseconds_since_last_tick rescue nil
		unless [@target_x, @target_y] == [@x, @y]
			dist = Measures.dist [@target_x, @target_y], [@x, @y], :cartesian

			vx     = (@target_x - @x) / dist * @velocity * ms
			vy     = (@target_y - @y) / dist * @velocity * ms

			if (@x - @target_x).abs < 5 then @x = @target_x else @x = @x + vx end
			if (@y - @target_y).abs < 5 then @y = @target_y else @y = @y + vy end

			if [@target_x, @target_y] == [@x, @y]
				x, y = Measures.to_pitch_coords [@x, @y]
				@pitch[[x,y]].catch! unless @pitch[[x,y]].nil?
				@pitch.unlock
			end
		end
	end
end
