require "chingu"
include Chingu
include Gosu

require "handoff_state"
require "play_state"
require "measures"

class KickoffState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		@pitch = options[:pitch] || raise(ArgumentError, "You did not specify a pitch for #{self}")
		add_game_object @pitch
		@pitch.each do |p|
			add_game_object p
			if p.can_kickoff? then p.set_halo :green else p.set_halo :none end
		end
		self.input = {
			:escape => lambda {push_game_state MainMenuState.new },
			:mouse_right => :action
		}

		params = { :x => 20, :y => 910, :color => 0xFF0000FF, :zorder => 1000, :rotation_center => :center_left }
		if @pitch.active_team.side == :A
			params.merge! :x => $window.width - 20, :rotation_center => :center_right, :color => 0xFFFF0000
		end
		@text = Text.create "Choose a player to kick the ball", params

		@hud  = HUD.create
		@step = 0
	end

	def update
		super
		cursor_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		unless cursor_coords == @cursor_coords
			@cursor_coords = cursor_coords
			player = @pitch[@cursor_coords]
			@hud.show player
			if @step == 0
				if player and player.can_kickoff?
					$window.change_cursor :ball
				else
					$window.change_cursor :normal
				end
			end
		end
	end

	def action
		@pitch.unlocked? do
			if @action_coords
				case @step
				when 0 # Selecting the player to do the kickoff
					player = @pitch[@action_coords]
					if player and player.can_kickoff?
						x, y = @action_coords
						@ball = Ball.create :pitch => @pitch, :x => x, :y => y
						@pitch.load @ball
					end
					$window.change_cursor :normal
					@text.text = "Kickoff!"
					@step += 1
				when 1 # Kicking off
					x, y = @action_coords
					@ball.scatter_kickoff! [x, y]
					@pitch.on_unlock do
						# Fetching the correct rectangle where the ball shall land
						target_rect = nil
						if @pitch.active_team.side == :A
							target_rect = Rect.new to_screen_coords([0, 0]), to_screen_coords([12,14])
						else
							target_rect = Rect.new to_screen_coords([13, 0]), to_screen_coords([12,14])
						end

						i, j = @ball.screen_pos
						if target_rect.collide_point? i, j
							@ball.on_square_entered { |x,y| @pitch[[x, y]].catch! if @pitch[[x, y]]}
							if @pitch[@ball.pos]
								@pitch[@ball.pos].catch!
							else
								@ball.scatter!
							end
							close
							push_game_state PlayState.new(:pitch => @pitch)
						else
							push_game_state HandoffState.new(:pitch => @pitch, :team => @pitch.active_team)
						end
					end
				end
				@action_coords = nil
			else
				@action_coords = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			end
		end
	end
end