require 'chingu'
include Chingu
include Gosu

require 'helpers/measures'
require 'helpers/dices'
require 'menus/combat_state'

require 'pitch/square'
require 'pitch/floating_text'

require 'player/actions'
require 'player/states'

class Player < GameObject
	include Helpers::Measures
	include Helpers::Dices

	include Actions
	include States

	traits :bounding_circle
	attr_reader :team, :cur_ma, :stats, :race, :role, :state

	@@str = 3
	@@agi = 2
	@@ma  = 4
	@@arm = 6

	def initialize options = {}
		super
		@team      = options[:team]  or raise "Missing team number for #{self}"
		@pitch     = options[:pitch] or raise "Unable to fetch pitch for #{self}"
		@ball      = options[:ball]  or raise "Unable to find ball for #{self}"
		@race      = options[:race] || "human"
		@role      = options[:role] || "blitzer"
		@image     = Image["teams/#{race}/#{role}#{@team.side}.gif"]
		@x, @y     = to_screen_coords [options[:x], options[:y]] rescue nil
		@target_x  = @x
		@target_y  = @y
		@velocity  = 0.23

		@footsteps = Sample["footsteps.ogg"]

		@selected  = false

		@stats     = {:str => @@str + rand(2), :agi => @@agi + rand(2), :ma => @@ma + rand(2), :arm => @@arm + rand(2)}
		@abilities = []
		@has_ball  = options[:has_ball] or false
		@state     = :heathy

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
		super
		params = {:x => @x, :y => @y, :color => :yellow}
		if @selected
			@square = StateSquare.new params.merge(:color => :yellow)
		elsif @team == @pitch.active_team
			if can_move?
				@square = StateSquare.new params.merge(:color => :green)
			else
				@square = StateSquare.new params.merge(:color => :red)
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
				success = true
				success = catch! if @ball.pos == @path[@cur_node] unless @has_ball
				unless success
					@cur_node = @path.size
				else
					@cur_node += 1
				end
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
		end_turn unless success
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


	# -------------------------------
	# ---------- Listeners ----------
	# -------------------------------

	private
	def on_state_change
		@team >> self
	end
end
