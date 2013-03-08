require "chingu"
include Chingu
include Gosu

require "hud"

class HandoffState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		@pitch = options[:pitch]
		@team = options[:team]
		add_game_object @pitch
		@pitch.each {|p| add_game_object p}

		self.input = {
			:escape => lambda {push_game_state MainMenuState.new },
			:mouse_right => :action
		}

		@hud = HUD.create

		@pitch.each { |p| if p.team == @team then p.set_halo :green else p.set_halo :none end }
		@team.each { |p| p.set_halo :green }
		params = { :x => 20, :y => 910, :color => 0xFF0000FF, :zorder => 1000, :rotation_center => :center_left }
		if @team.side == :B
			params.merge! :x => $window.width - 20, :rotation_center => :center_right, :color => 0xFFFF0000
		end
		@text = Text.create "Choose a player to give the ball to", params
	end

	def update
		super
		cursor_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		unless cursor_coords == @cursor_coords
			@cursor_coords = cursor_coords
			player = @pitch[@cursor_coords]
			@hud.show player
			if player and player.team == @team
				$window.change_cursor :ball
			else
				$window.change_cursor :normal
			end
		end
	end

	def action
		if @action_coords and @pitch[@action_coords]
			x, y = @action_coords
			@ball = Ball.create :pitch => @pitch, :x => x, :y => y
			@pitch.load @ball
			@pitch[@action_coords].has_ball = true
			close
			push_game_state PlayState.new(:pitch => @pitch)
		else
			@action_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		end
	end
end