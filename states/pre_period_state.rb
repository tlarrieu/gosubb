require "chingu"
include Gosu
include Chingu

require "main_menu_state"
require "kickoff_state"
require "pitch"
require "player"


class PrePeriodState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		@pitch = options[:pitch]
		@teams = options[:teams]
		@pitch.load @teams

		add_game_object @pitch
		@pitch.each { |p| add_game_object p }
		self.input = {
			:escape => lambda {push_game_state MainMenuState.new },
			:space => :next_step,
			:mouse_left => :select,
			:mouse_right => :move
		}

		@texts = []

		@hud = HUD.create
	end

	def update
		super
		overred = @pitch[to_pitch_coords [$window.mouse_x, $window.mouse_y]]
		if overred then @hud.show overred else @hud.clear end
	end

	def select
		@selected.unselect if @selected
		mouse_pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		@selected = @pitch[mouse_pos]

		@hud.stick @selected
		if @selected
			@selected.select
			@hud.show @selected
		else
			@hud.clear
		end
	end

	def move
		if @selected
			mouse_pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			if @pitch[mouse_pos]
				target = @pitch[mouse_pos]
				@selected.x, target.x = target.x, @selected.x
				@selected.y, target.y = target.y, @selected.y
			else
				@selected.x, @selected.y = to_screen_coords mouse_pos
			end
		end
	end

	def next_step
		if validate
			@selected.unselect if @selected
			close
			push_game_state KickoffState.new(:pitch => @pitch)
		end
	end

	def validate
		valid = true
		@texts.each { |t| t.destroy! }
		@texts.clear
		@teams.each do |team|
			top_players       = 0
			middle_players    = 0
			bottom_players    = 0
			misplaced_players = 0
			team.each do |pl|
				x, y = pl.pos
				if (x > 12 && team.side == :A) || (x < 13 && team.side == :B)
					misplaced_players += 1
				elsif y < 4
					top_players += 1
				elsif y <= 10 and x == 12
					middle_players += 1
				elsif y > 10
					bottom_players += 1
				end
			end

			unless top_players == 2 and bottom_players == 2 and middle_players >= 3 and misplaced_players == 0
				valid = false
				params = { :x => 20, :y => 870, :color => 0xFF0000FF, :zorder => 1000, :rotation_center => :center_left }
				if team.side == :B
					params.merge :x => $window.width - 20, :rotation_center => :center_right, :color => 0xFFFF0000
				end

				if top_players < 2
					str = "Not enough players on top row"
					@texts << Text.create(str, params)
				elsif top_players > 2
					str = "Too much players on top row"
					@texts << Text.create(str, params)
				end

				params[:y] += 30
				if middle_players < 3
					str = "Not enough players on middle line"
					@texts << Text.create(str, params)
				end

				params[:y] += 30
				if bottom_players < 2
					str = "Not enough players on bottom row"
					@texts << Text.create(str, params)
				elsif bottom_players > 2
					str = "Too much players on bottom row"
					@texts << Text.create(str, params)
				end

				params[:y] += 30
				if misplaced_players > 0
					str = "You can't start with players in opponent's side"
					@texts << Text.create(str, params)
				end
				false
			end
		end
		return valid
	end
end
