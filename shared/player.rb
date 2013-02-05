require 'chingu'
include Chingu
include Gosu

require "combat_state"
require "measures"
require "dices"
require "actions"
require "states"
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

class Player < GameObject
	include Helpers::Measures
	include Helpers::Dices

	include Actions
	include States

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
		@health_txt = FloatingText.new("", :x => @x + 5, :y => @y + 5, :timer => 0, :color => 0xFFFF0000)
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
		update_image
	end

	def unselect
		@selected = false
		update_image
	end

	def new_turn!
		@can_move  = true
		@has_moved = false
		@cur_ma    = @stats[:ma]
		@cur_node  = 0
		@path      = nil
		@blitz     = false
		update_image

		if (Health::STUN_1..Health::STUN_2).member? @health
			@health -= 1
			notify_health_change
		end
	end

	def end_turn
		@team.end_turn!
	end

	def draw
		if on_pitch?
			@health_txt.draw if @health_txt
			super
		end
	end

	def update
		super
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
			update_image
			notify_health_change
		else
			update_image
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

	def notify_health_change
		@health_txt.color = case @health - 1
		when 2
			0xFFFF0000
		when 1
			0xFFE96900
		when 0
			0xFF00FF00
		else
			0xFFFFFFFF
		end
			@health_txt.x    = @x + 5
			@health_txt.y    = @y + 5
		if (Health::STUN_0..Health::STUN_2).member? @health
			@health_txt.text = "#{@health - 1}"
		else
			@health_txt.text = ""
		end
	end

	def update_image
		key = "#{@race}/#{@role}#{@team.side}"
		if @selected
			key << "-yellow"
		elsif @team.active?
			if @can_move then key << "-green" else key << "-red" end
		end
		@image = @@loaded[key]
	end

	def default_image
		@@loaded["#{@race}/#{@role}#{@team.side}"]
	end
end
