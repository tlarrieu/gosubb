require "chingu"
include Chingu
include Gosu

require "helpers/measures"
require "pitch/square"

module GameStates

class PostCombatState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		self.input = { :mouse_right => :click }

		@attacker = options[:attacker]
		@defender = options[:defender]
		@pitch    = options[:pitch]

		push      = options[:push] || true

		if push and @defender.on_pitch?
			@areas = {}
			@areas[[-1, -1]] = [[ 0,  1], [ 1,  0], [ 1,  1]]
			@areas[[-1,  0]] = [[ 1, -1], [ 1,  0], [ 1,  1]]
			@areas[[-1,  1]] = [[ 0, -1], [ 1, -1], [ 1,  0]]
			@areas[[ 0, -1]] = [[-1,  1], [ 0,  1], [ 1,  1]]
			@areas[[ 0,  1]] = [[-1, -1], [ 0, -1], [ 1, -1]]
			@areas[[ 1, -1]] = [[-1,  0], [-1,  1], [ 0,  1]]
			@areas[[ 1,  0]] = [[-1, -1], [-1,  0], [-1,  1]]
			@areas[[ 1,  1]] = [[-1,  0], [-1, -1], [ 0, -1]]

			@squares   = []
			x,y = @defender.pos
			dx = @attacker.pos[0] - x
			dy = @attacker.pos[1] - y
			@areas[[dx,dy]].each do |a,b|
				pos = to_screen_coords [x+a, y+b]
				@squares << Square.create(:x => pos[0], :y => pos[1], :type => :square, :color => :blue, :zorder => 2)
			end
		else
			show_menu
		end
	end

	def update
		super
		previous_game_state.update
	end

	def draw
		super
		previous_game_state.draw
	end

	def click
		clicked_square = false
		@squares.each do |square|
			if square.collision_at? $window.mouse_x, $window.mouse_y
				x, y = to_pitch_coords [$window.mouse_x, $window.mouse_y]
				@defender_last_pos = @defender.pos
				show_menu if @defender.push_to! x, y
			end
		end
	end

	def show_menu
		@pitch.hud.stick nil
		@pitch.hud.clear
		@pitch.hud.lock
		@squares.each { |square| square.destroy! } if @squares
		Text.create "Do you want to follow?", :x => $window.width / 2.0 - 120, :y => 844

		items = { "Yes" => :follow, "No" => :close }.sort_by { |key,value| key }
		@menu = Menu.create :menu_items => items,
		                    :x => $window.width / 2.0,
		                    :y => 900,
		                    :zorder => 200,
		                    :select_color => 0xFF0056D6,
		                    :unselect_color => 0xFFFFFFFF,
		                    :spacing => 30,
		                    :bg_padding_r => 5,
		                    :bg_padding_l => 5,
		                    :bg_padding_t => 30,
		                    :bg_padding_b => 5,
		                    :anchor => :center_center,
		                    :font => "media/fonts/averia_rg.ttf",
		                    :font_size => 35,
		                    :orientation => :horizontal
	end

	def close
		super
		@pitch.hud.unlock
	end

	def follow
		x, y = @defender.pos
		x, y = @defender_last_pos if @defender_last_pos

		@attacker.push_to! x, y
		close
	end
end

end
