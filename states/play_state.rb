require "combat_state"
require "main_menu_state"

require "measures"
require "barrier"
require "pitch"
require "ball"
require "player"
require "hud"
require "races"

module GameStates

class PlayState < GameState
	include Helpers::Measures
	include Helpers::Barrier

	attr_reader :teams

	def initialize
		super
		@sound       = Sample["turnover.ogg"]

		self.input   = { :mouse_right => :action, :mouse_left => :select, :space => lambda{ @pitch.turnover! }, :escape => :show_menu }

		@pitch = Pitch.create
		@pitch.on_unlock { show_movement }


		@action_coords = nil
		@selected      = nil
		@last_selected = nil

		@hud = HUD.create :teams => @pitch.teams, :pitch => @pitch
	end


	def setup
		# Here we force refresh of the movemement allowance
		# we do that to fix a glitch occuring when leaving dice menu state
		show_movement
	end

	def finalize
		$window.change_cursor :normal
	end

	def show_menu
		push_game_state MainMenuState.new
	end

	def debug
		push_game_state GameStates::Debug.new
	end

	def new_turn!
		@selected.unselect if @selected
		@selected = nil
		@hud.stick nil
		@hud.clear

		MovementSquare.destroy_all

		@pitch.new_turn!
	end

	def unlock
		super
		show_movement
	end

	def update
		super
		# Turnover
		if @pitch.turnover?
			@pitch.unlocked? do
				new_turn!
				Sample["turnover.ogg"].play 0.3
				@text = FloatingText.create(
					"Turnover !",
					:x => $window.width / 2.0,
					:y => $window.height - 100,
					:timer => 3000,
					:color => 0xFFFF0000,
					:size => 40
				)
			end
		end

		# Cursor management
		cursor_pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		if @pitch[cursor_pos]
			@hud.show @pitch[cursor_pos] # Update HUD
			if @selected and @selected.team.active?
				unless @pitch[cursor_pos].team.active?
					attacker = @selected
					defender = @pitch[cursor_pos]
					highest = [attacker.stats[:str], defender.stats[:str]].max
					lowest  = [attacker.stats[:str], defender.stats[:str]].min
					if attacker.stats[:str] >= defender.stats[:str]
						if highest >= 2 * lowest
							$window.change_cursor :d_3
						elsif highest > lowest
							$window.change_cursor :d_2
						else
							$window.change_cursor :d_1
						end
					else
						if highest >= 2 * lowest
							$window.change_cursor :d_3_red
						elsif highest > lowest
							$window.change_cursor :d_2_red
						else
							$window.change_cursor :d_1_red
						end
					end
				else
					if @selected == @pitch[cursor_pos]
						if @selected.can_blitz?
							$window.change_cursor :blitz
						else
							$window.change_cursor :normal
						end
					elsif @selected.has_ball?
						if @selected.close_to? @pitch[cursor_pos]
							$window.change_cursor :handoff
						else
							$window.change_cursor :ball
						end
					else
						$window.change_cursor :normal
					end
				end
			else
				if @pitch[cursor_pos].team.active?
					$window.change_cursor :select
				else
					$window.change_cursor :red
				end
			end
		else
			@hud.clear # Update HUD
			if @pitch.ball.pos == cursor_pos and @selected and @selected.team.active?
				$window.change_cursor :take
			else
				unless @selected and @selected.team.active?
					$window.change_cursor :normal
				else
					roll = false
					@pitch.active_players_around(@selected.pos).each do |pl|
						unless pl.team == @selected.team
							roll = true
							break
						end
					end
					if roll
						res = 7 - @selected.stats[:agi]
						case res
						when 6
							$window.change_cursor :move, :six
						when 5
							$window.change_cursor :move, :five
						when 4
							$window.change_cursor :move, :four
						when 3
							$window.change_cursor :move, :three
						when 2
							$window.change_cursor :move, :two
						when 1
							$window.change_cursor :move, :one
						end
					else
						$window.change_cursor :move
					end
				end
			end
		end

	end

	def select
		pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		@last_selected = @selected if @selected
		@selected      = @pitch[pos]
		@action_coords = nil
		show_movement
		@hud.stick @selected
	end

	def action
		@pitch.unlocked? do
			x, y = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			unless @selected.nil?
				unless @action_coords == [x,y]
					show_path x, y if @selected.can_move_to? x, y
					@action_coords = [x, y]
				else
					if @selected.move_to! x, y or @selected.pass @pitch[[x,y]] or @selected.block @pitch[[x,y]]
						MovementSquare.destroy_all
						@last_selected.cant_move! if @last_selected and @last_selected.has_moved? unless @last_selected == @selected
					elsif @action_coords == @selected.pos
						if @selected.stand_up! or @selected. blitz!
							@last_selected.cant_move! if @last_selected and @last_selected.has_moved? unless @last_selected == @selected
						end
					end
					@action_coords = nil
					show_movement
				end
			end
		end
	end

	private

	def show_movement
		MovementSquare.destroy_all
		unless @selected.nil? or @selected.moving?
			if @selected.team == @pitch.active_team
				if @selected.can_move?
					w, color = @selected.cur_ma, :green
				else
					w, color = 0, :green
				end
			else
				if @selected.health == Health::OK
					w, color = 1, :gray
				else
					w, color = 0, :gray
				end
			end

			p_rect = Rect.new 1, 1, Pitch::WIDTH - 2, Pitch::HEIGHT - 2
			(-w..w).each do |i|
				(-w..w).each do |j|
					x, y   = [@selected.pos, [i,j]].transpose.map { |c| c.reduce(:+)}
					c_rect = Rect.new x, y, 1, 1
					if @pitch[[x,y]].nil? and p_rect.collide_rect? c_rect
						x, y = to_screen_coords [x,y]
						MovementSquare.create( :x => x, :y => y, :color => color, :alpha => 180 )
					end
				end
			end
		end
	end

	def show_path x, y
		MovementSquare.destroy_all
		path = a_star @pitch, @selected.pos, [x,y]
		if path.length <= @selected.cur_ma
			path.each do |p|
				i, j = to_screen_coords p
				MovementSquare.create( :x => i, :y => j, :type => :square, :color => :green )
			end
			@action_coords = [x,y]
		end
	end
end

end
