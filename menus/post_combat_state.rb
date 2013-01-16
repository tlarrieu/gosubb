require "chingu"
include Chingu
include Gosu

require "helpers/measures"
require "pitch/square"

module Menus

class PostCombatState < GameState
	include Helpers::Measures

	def initialize options = {}
		super
		self.input = { :mouse_right => :click }

		@attacker = options[:attacker]
		@defender = options[:defender]
		@pitch    = options[:pitch]

		@squares   = []
		x, y = @defender.pos
		(-1..1).each do |i|
			(-1..1).each do |j|
				if i != 0 or j != 0
					pos = [x + i, y + j]
					if dist(pos, @attacker.pos, :infinity) > 1 and @pitch[pos].nil?
						spos = to_screen_coords pos
						@squares << Square.create(:x => spos[0], :y => spos[1], :type => :square, :color => :blue, :zorder => 300)
					end
				end
			end
		end

	end

	def update
		super
		previous_game_state.update
	end

	def draw
		super
		previous_game_state.draw
		@squares.each { |square| square.draw }
	end

	def click
		@squares.each do |square|
			if square.collision_at? $window.mouse_x, $window.mouse_y
				x, y = to_pitch_coords [$window.mouse_x, $window.mouse_y]
				@defender.push_to! x, y
				close
			end
		end
	end
end

end
