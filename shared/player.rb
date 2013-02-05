require 'chingu'
include Chingu
include Gosu

require "combat_state"
require "measures"
require "dices"
require "square"
require "races"

class Health
	OK      = 0 # Good shape
	STUN_0  = 1 # Ready to stand up
	STUN_1  = 2 # On the back
	STUN_2  = 3 # On the front
	KO      = 4 # KO (out of pitch)
	DEAD    = 5 # Dead (out of pitch)
end

##########
# Actions and states splitted into module to increase readability
# and to enable easy code folding
###
module PlayerActions
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

module PlayerStates
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

	def can_pass_to? target_player
		can_move? and @has_ball and not @team.pass? and target_player and target_player != self  and target_player.team == @team and target_player.health == Health::OK
	end

	def can_handoff_to? target_player
		can_move? and @has_ball and not @team.handoff? and target_player and target_player != self  and target_player.team == @team and target_player.health == Health::OK and close_to?(target_player)
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
		not @team.blitz? and @stats[:ma] == @cur_ma and @health == Health::OK
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

class Player < GameObject
	include Helpers::Measures
	include Helpers::Dices

	include PlayerActions
	include PlayerStates

	traits :bounding_circle
	attr_reader :team, :cur_ma, :stats, :skills, :race, :role, :health

	@@loaded = {}

	def initialize options = {}
		super
		@team       = options[:team]  or raise ArgumentError, "Missing team number for #{self}"
		@pitch      = options[:pitch] or raise ArgumentError, "Unable to fetch pitch for #{self}"
		@race       = options[:race]  or raise ArgumentError, "You did not specifiy a race for #{self}"
		@role       = options[:role]  or raise ArgumentError, "You did not specifiy a role for #{self}"
		key = "#{race}/#{role}#{@team.side}"
		unless @@loaded[key]
			["-yellow", "-red", "-green", ""].each do |color|
				@@loaded[key + color] = @@loaded[key] = Image["teams/#{race}/#{role}#{@team.side}#{color}.png"]
			end
		end
		@image = @@loaded[key]
		unless @@loaded[:health]
			@@loaded[:health] = {:red => Image["health_red.png"], :yellow => Image["health_yellow.png"], :green => Image["health_green.png"]}
		end
		@x, @y      = to_screen_coords [options[:x], options[:y]] rescue nil
		@target_x   = @x
		@target_y   = @y
		@velocity   = 0.23

		@footsteps  = Sample["footsteps.ogg"]

		@selected   = false

		@stats      = Races[race][role][:stats]
		@skills     = Races[race][role][:skills]
		@has_ball   = options[:has_ball] or false
		@stage      = options[:stage] or :configure
		@health     = Health::OK
	end

	def set_stage options={}
		raise ArgumentError unless [:play, :configure].include? options[:stage]
		raise ArgumentError if options[:stage] == :play and not options[:ball].is_a? Ball
		if options[:stage] == :play
			@ball = options[:ball]
			@has_ball = @ball.pos == pos
		end
		@stage = options[:stage]
	end

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

	def new_turn!
		@can_move  = true
		@has_moved = false
		@cur_ma    = @stats[:ma]
		@cur_node  = 0
		@path      = nil
		@blitz     = false
		@health -= 1 if (Health::STUN_1..Health::STUN_2).member? @health
	end

	def end_turn
		@team.end_turn!
	end

	def draw
		if on_pitch?
			@health_image.draw @x + @image.width / 2 - @health_image.width - 2, @y + @image.height / 2 - @health_image.height - 2, @zorder + 1 if @health_image
			super
		end
	end

	def update
		super
		# Image update
		if @stage == :play
			key = "#{@race}/#{@role}#{@team.side}"
			if @selected
				key << "-yellow"
			elsif @team.active?
				if @can_move then key << "-green" else key << "-red" end
			end
			@image = @@loaded[key]

			case @health
			when Health::STUN_2
				@health_image = @@loaded[:health][:red]
			when Health::STUN_1
				@health_image = @@loaded[:health][:yellow]
			when Health::STUN_0
				@health_image = @@loaded[:health][:green]
			else
				@health_image = nil
			end
		end

		# Position update (aka movement)
		unless @path.nil?
			ms = $window.milliseconds_since_last_tick rescue nil

			t_pos = to_screen_coords @path[@cur_node]
			c_pos = [@x, @y]

			unless @has_left_square or @untackleable
				@has_left_square = true
				count = 0
				@pitch.active_players_around(pos).each { |p| count += 1 if p.team != @team }
				if count > 0
					unless roll_agility(@stats[:agi]) == :success
						injure!
						@has_left_square = false
						@path = nil
						end_turn
						@pitch.unlock
						return nil
					end
				end
			end

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
				@has_left_square = false
				success = true
				success = catch! if @ball.pos == @path[@cur_node] unless @has_ball
				unless success
					@cur_node = @path.size
				else
					@cur_node += 1
				end
				@cur_ma   -= 1 if @cur_ma
				@footsteps.play

				x, y = to_pitch_coords [tx, ty]
				unless (0..25).include? x and (0..14).include? y
					injure!
					@x, @y = to_screen_coords [-10, -10]
				else
					@x, @y = tx, ty
					@team.inc :score if (@team.side == :A and x == Pitch::WIDTH - 1) or (@team.side == :B and x == 0) if has_ball?
				end
			else
				@x, @y = tx, ty
			end

			@ball.set_pos! @x, @y, false if @has_ball

			if @cur_node == @path.size
				@path = nil
				@pitch.unlock
			end

			cant_move! if @cur_ma == 0 and not @blitz and not @has_ball
		end
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
		end_turn unless success
	end

	def default_image
		@@loaded["#{@race}/#{@role}#{@team.side}"]
	end
end
