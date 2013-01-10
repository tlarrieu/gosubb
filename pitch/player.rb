require 'chingu'
include Chingu
include Gosu

require 'menus/post_combat_state'

require 'helpers/measures'
require 'helpers/dices'

require 'pitch/square'
require 'pitch/floating_text'

class Player < GameObject
	include Helpers::Measures
	include Helpers::Dices

	traits :bounding_circle
	attr_reader :team, :cur_ma, :stats, :race, :role

	@@str = 3
	@@agi = 2
	@@ma  = 4
	@@arm = 4

	def initialize options = {}
		super
		@team      = options[:team]  or raise "Missing team number for #{self}"
		@pitch     = options[:pitch] or raise "Unable to fetch pitch for #{self}"
		@ball      = options[:ball]  or raise "Unable to find ball for #{self}"
		@race      = options[:race] || "human"
		@role      = options[:role] || "blitzer"
		side       = @team == 0 ? "A" : "B"
		@image     = Image["teams/#{race}/#{role}#{side}.gif"]
		@x, @y     = to_screen_coords [options[:x], options[:y]] rescue nil
		@target_x  = @x
		@target_y  = @y
		@velocity  = 0.23

		@footsteps = Sample["footsteps.ogg"]

		@selected  = false

		@stats     = {:str => @@str + rand(2), :agi => @@agi + rand(2), :ma => @@ma + rand(2), :arm => @@arm + rand(2)}
		@abilities = []
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
		@cur_node  = 0
		@path      = nil
		@blitz     = false
		# Later we will have to manage injuries recovery down there
	end

	# -------------------------------
	# ----------- Graphic -----------
	# -------------------------------

	def draw
		@square.draw if @square
		super
	end

	def update
		params = {:x => @x, :y => @y, :type => :state, :color => :yellow}

		if @selected
			@square = Square.new  params.merge(:color => :yellow)
		elsif @team == @pitch.active_team
			if can_move?
				@square = Square.new  params.merge(:color => :green)
			else
				@square = Square.new  params.merge(:color => :red)
			end
		else
			@square = nil
		end

		unless @path.nil?
			ms = $window.milliseconds_since_last_tick rescue nil

			t_pos = to_screen_coords @path[@cur_node]
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
				@footsteps.play
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
		if to_pitch_coords( [ $window.mouse_x, $window.mouse_y ] ) == pos
			@selected = true
		else
			@selected = false
		end
	end

	def unselect
		@selected = false
	end

	def move_to! x, y
		return false unless can_move_to? x, y
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
			parent.push_game_state DiceState.new(:attacker => self, :defender => target_player)
			return true
		end
		return false
	end

	def down target_player, push=false
		Sample["ko.ogg"].play
		parent.push_game_state PostCombatState.new @attacker => self, :defender => target_player, :pitch => @pitch if push
		target_player.end_turn if target_player.team == @pitch.active_team
	end

	def push target_player
		Sample["punch.ogg"].play
		parent.push_game_state PostCombatState.new :attacker => self, :defender => target_player, :pitch => @pitch
	end

	def stumble target_player
		if @abilities.include? :dodge
			push target_player
		else
			down target_player, true
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

	def event! symb
		msg = ""
		color = 0xFF00FF00
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
		when :block
			msg = "Block !"
		when :dodge
			msg = "Dodge !"
		end
		@text.destroy! if @text # We do not want to have many text boxes displayed at the same time
		@text = FloatingText.create(msg, :x => @x, :y => @y - height - 22, :timer => 2000, :color => color)
		end_turn unless success if @pitch.active_team == @team
	end

	def end_turn
		if @pitch.active_team == @team
			@pitch.turnover!
			cant_move!
		end
	end

	# -------------------------------
	# ------------ State ------------
	# -------------------------------
	def [] symb
		raise ArgumentError, "#{symb}" unless symb.is_a? Symbol
		raise ArgumentError, "#{symb}" unless @stats.keys.include? symb

		stats[symb]
	end

	def moving?
		return [@target_x, @target_y] == [@x, @y]
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
	end

	def pos
		to_pitch_coords [@x, @y]
	end

	def screen_pos
		[@x,@y]
	end
end
