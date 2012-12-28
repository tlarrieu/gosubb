require 'chingu'
include Chingu
include Gosu

require 'helper'
require 'square'
require 'dice'
require 'floating_text'

class Player < GameObject
	attr_reader :team, :cur_ma

	@@str = 5
	@@agi = 3
	@@ma  = 5
	@@arm = 5

	def initialize options = {}
		super
		@team      = options[:team]  or raise "Missing team number for #{self}"
		@pitch     = options[:pitch] or raise "Unable to fetch pitch for #{self}"
		@ball      = options[:ball]  or raise "Unable to find ball for #{self}"
		@x, @y     = Measures.to_screen_coords [options[:x], options[:y]] rescue nil
		@target_x  = @x
		@target_y  = @y
		@velocity  = 0.23
		
		@stats     = {:str => @@str, :agi => @@agi, :ma => @@ma, :arm => @@arm}
		@has_ball  = options[:has_ball] or false
		
		new_turn!
	end

	def setup
		self.input = { :mouse_left => :select }
	end

	def new_turn!
		@can_move  = true
		@has_moved = false
		@cur_ma    = @stats[:ma]
		@square    = nil
		@cur_node  = 0
		@path      = nil
		@blitz     = false
		# Later we will have to manage injuries recovery down there
	end

	# -------------------------------
	# ----------- Graphic -----------
	# -------------------------------
	
	def draw
		if @team == @pitch.active_team
			if @cur_ma == @stats[:ma]
				@square = Square.new :x => @x, :y => @y, :type => :state, :color => :green
			elsif @cur_ma == 0 or not can_move?
				@square = Square.new :x => @x, :y => @y, :type => :state, :color => :red
			else
				@square = Square.new :x => @x, :y => @y, :type => :state, :color => :orange
			end
			@square.draw unless @square.nil?
		end
		super
	end

	def update
		ms = $window.milliseconds_since_last_tick rescue nil
		unless @path.nil?
			t_pos = Measures.to_screen_coords @path[@cur_node]
			c_pos = [@x, @y]

			vx, vy = 0, 0

			vx = (t_pos[0] - c_pos[0]) / (t_pos[0] - c_pos[0]).abs * @velocity * ms unless c_pos[0] == t_pos[0]
			vy = (t_pos[1] - c_pos[1]) / (t_pos[1] - c_pos[1]).abs * @velocity * ms unless c_pos[1] == t_pos[1]

			tx, ty = 0, 0

			if (c_pos[0] - t_pos[0]).abs < 5
				tx = t_pos[0]
			else
				tx = @x + vx
			end

			if (c_pos[1] - t_pos[1]).abs < 5
				ty = t_pos[1]
			else
				ty = @y + vy
			end

			if [tx, ty] == t_pos
				catch! if @ball.pos == @path[@cur_node] unless @has_ball
				@cur_node += 1
				@cur_ma   -= 1
			end

			@x, @y = tx, ty
			@ball.set_pos! @x, @y, false if @has_ball

			if @cur_node == @path.size
				@path = nil 
				@pitch.unlock
			end

			cant_move! if @cur_ma == 0 and not @blitz and not @has_ball
		end
	end

	# -------------------------------
	# ----------- Actions -----------
	# -------------------------------
	def select
		if Measures.to_pitch_coords( [ $window.mouse_x, $window.mouse_y ] ) == pos
			@square = Square.new :x => @x, :y => @y, :type => :state
		else
			@square = nil
		end
	end

	def move_to! x, y
		return false unless can_move_to? x, y
		coords = [x, y]

		# Getting @path through A*
		path = Measures.a_star @pitch, pos, coords
		return false unless path.include? coords and path.length <= @cur_ma
		@target_x, @target_y = Measures.to_screen_coords [x, y]
		@cur_node  = 0
		@path      = path
		@has_moved = true
		true

		@pitch.lock
	end

	def can_move_to? x, y
		coords = [x, y]
		return false unless coords.size == 2
		# Checking that coordinates are within pitch range
		return false unless (0..25).include? coords[0] and (0..14).include? coords[1]
		# Checking if player can move
		return false unless can_move? and @team == @pitch.active_team
		# Checking that target location is empty
		return false unless @pitch[coords].nil?
		# Checking if a path exists to
		return false if stuck?

		return true
	end

	def pass target_player
		if can_pass_to? target_player
			@can_move, @has_ball = false, false

			case Dice.roll_agility @stats[:agi]
			when :success
				x, y = target_player.pos
				@ball.move_to! x, y
				event! :pass
			when :fumble
				@ball.scatter!
				event! :fumble
			else
				_coords = @ball.scatter! 3, target_player.pos
				if @pitch[_coords].nil?
					event! :fail
				else
					event! :pass if @pitch[_coords] == target_player
				end
			end
			return true
		end
		return false
	end

	# FIXME : the following condition is not enough, we are missing some cases
	def can_pass_to? target_player
		@can_move and @has_ball and target_player != self  and target_player.team == @team
	end

	def catch! modifiers=[]
		res = Dice.roll_agility @stats[:agi], modifiers
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

	def event! symb
		msg = ""
		color = 0xFF477B28
		success = true
		case symb
		when :pass
			msg = "Pass !"
		when :fumble
			msg = "Fumble !"
			success = false
			color = 0xFFFF0000
		when :fail
			msg = "Fail !"
			success = false
			color = 0xFFFF0000
		when :catch
			msg = "Catch !"
		end
		@text = FloatingText.create(msg, :x => @x, :y => @y - 1.5 * height, :timer => 2000, :color => color)
		end_turn unless success
	end

	def end_turn
		if @pitch.active_team == @team
			@pitch.turnover!
			@can_move = false
		end
	end
	
	# -------------------------------
	# ------------ State ------------
	# -------------------------------
	def moving?
		return [@target_x, @target_y] == [@x, @y]
	end

	def can_move?
		@can_move
	end

	def cant_move!
		@can_move = false
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

	def pos
		Measures.to_pitch_coords [@x, @y]
	end

	def screen_pos
		[@x,@y]
	end
end

class AmazonA < Player
	def initialize options = {}
		options = { :image => Image["amazon/amblitzer1an.gif"], :team => 0 }.merge(options)
		super options
	end
end

class AmazonB < Player
	def initialize options = {}
		options = { :image => Image["amazon/amblitzer1ban.gif"], :team => 1 }.merge(options)
		super options
	end
end
