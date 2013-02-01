require "combat_state"
require "main_menu_state"

require "measures"
require "barrier"
require "pitch"
require "ball"
require "player"
require "hud"

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

		x, y  = to_screen_coords [12, 8]
		@ball = Ball.create :pitch => @pitch
		@ball.set_pos! x, y, false

		@action_coords = nil

		@selected      = nil
		@last_selected = nil

		@hud = HUD.create :teams => @pitch.teams, :pitch => @pitch

		randomize
	end


	def setup
		# Here we force refresh of the movemement allowance
		# we do that to fix a glitch occuring when leaving dice menu state
		show_movement
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
		# Movement allowance
		show_movement if @action_coords.nil? and not @ma_squares.nil? and @ma_squares.empty?

		# HUD update
		found = false
		@pitch.teams.each do |t|
			t.each do |p|
				if p.collision_at? $window.mouse_x, $window.mouse_y
					@hud.show p
					found = true
				end
			end
		end
		@hud.clear unless found

		# Turnover
		if @pitch.turnover?
			@pitch.unlocked? do
				new_turn!
				Sample["turnover.ogg"].play 0.3
				@text = FloatingText.create "Turnover !",
				                            :x => @pitch.width / 2.0,
				                            :y => $window.height - 100,
				                            :timer => 3000,
				                            :color => 0xFFFF0000,
				                            :size => 40
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

	def randomize
		roles = { :human => ["lineman", "blitzer", "catcher", "thrower"], :orc => ["lineman", "blitzer", "thrower"] }
		races = [:human, :orc]

		positions = [[3,6], [3,8], [7,5], [7,9], [10,1], [10, 13], [12,3], [12,6], [12,7], [12,8], [12,11]]

		race = races.sample
		0.upto(10) do |i|
			role = roles[race].sample
			loop do
				x, y = positions[i]
				pos = [x, y]
				unless @pitch[pos]
					has_ball = @ball.pos == pos
					@pitch.teams[0] << Player.create(
					                      :team => @pitch.teams[0],
					                      :x => x,
					                      :y => y,
					                      :has_ball => has_ball,
					                      :pitch => @pitch,
					                      :ball => @ball,
					                      :race => race,
					                      :role => role,
					                      )
					break
				end
			end
		end

		race = races.sample
		0.upto(10) do |i|
			role = roles[race].sample
			loop do
				x, y = positions[i]
				x = Pitch::WIDTH - x - 1
				pos = [x, y]
				unless @pitch[pos]
					has_ball = @ball.pos == pos
					@pitch.teams[1] << Player.create(
					                      :team => @pitch.teams[1],
					                      :x => x,
					                      :y => y,
					                      :has_ball => has_ball,
					                      :pitch => @pitch,
					                      :ball => @ball,
					                      :race => race,
					                      :role => role
					                      )
					break
				end
			end
		end
	end
end

end
