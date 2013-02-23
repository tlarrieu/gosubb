require "chingu"
include Chingu
include Gosu

require "play_state"
require "measures"

class KickoffState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		@pitch = options[:pitch] || raise(ArgumentError, "You did not specify a pitch for #{self}")
		add_game_object @pitch
		@pitch.each { |p| add_game_object p }

		self.input = {
			:escape => lambda {push_game_state MainMenuState.new },
			:mouse_right => :action
		}

		@hud  = HUD.create
		@step = 0
	end

	def update
		super
		cursor_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		unless cursor_coords == @cursor_coords
			@cursor_coords = cursor_coords
			player = @pitch[@cursor_coords]
			if @step == 0
				if player and player.can_kickoff?
					$window.change_cursor :ball
				else
					$window.change_cursor :normal
				end
			else
			end
		end
	end

	def action
		@pitch.unlocked? do
			if @action_coords
				case @step
				when 0
					player = @pitch[@action_coords]
					place_ball @action_coords if player and player.can_kickoff?
					$window.change_cursor :normal
					@step += 1
				when 1
					kickoff @action_coords
				end
				@action_coords = nil
			else
				@action_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			end
		end
	end

	def place_ball coords
		x, y = coords
		@ball = Ball.create :pitch => @pitch, :x => x, :y => y
		@pitch.load @ball
	end

	def kickoff coords
		x, y = coords
		@ball.on_square_entered { |x,y| @pitch[[x, y]].catch! if @pitch[[x, y]]}
		@ball.scatter_kickoff! [x, y]
		@pitch.on_unlock do
			close
			push_game_state PlayState.new(:pitch => @pitch)
			@ball.on_square_entered {}
			@pitch.on_unlock {}
		end
	end
end