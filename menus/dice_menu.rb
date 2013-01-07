require "chingu"
include Chingu
include Gosu

require "helpers/dices"
require "helpers/images"

module Menus

# TODO implement reroll

class DiceMenu < GameState
	include Helpers::Dices

	def initialize options = {}
		super
		self.input = { :mouse_left => :click }
		@color = 0xAA000000


		@attacker = options[:attacker]
		@defender = options[:defender]
		diff = (@attacker.stats[:str] - @defender.stats[:str]).abs
		lowest = [@attacker.stats[:str], @defender.stats[:str]].min
		nb_dices = if diff >= 3 * lowest
			4
		elsif diff >= 2 * lowest
			3
		elsif diff > lowest
			2
		else
			1
		end

		x = ($window.width - (nb_dices - 1) * 50) / 2.0
		y = ($window.height - 37) / 2.0

		@dices = []
		nb_dices.times do
			@dices << DiceObject.create( :value => roll(:block), :x => x, :y => y, :zorder => 201 )
			x += 50
		end

		@caption = Text.create "Select a dice", :x => $window.width / 2.0 - 60, :y => $window.height / 2.0 + 30, :zorder => 201
	end

	def finalize
		previous_game_state.update
	end

	def update
		super
		previous_game_state.update
	end

	def draw
		super
		previous_game_state.draw
		$window.fill_rect([0, 0, $window.width, $window.height], @color, 200)
	end

	def click
		@dices.each do |dice|
			if dice.collision_at? $window.mouse_x, $window.mouse_y
				@attacker.cant_move!
				close
				case dice.value
				when :attacker_down
					@defender.down @attacker
				when :both_down
					@attacker.down @defender
					@defender.down @attacker
				when :defender_stumble
					@attacker.stumble @defender
				when :defender_down
					@attacker.down @defender
				when :pushed
					@attacker.push @defender
				break
				end
			end
		end
	end
end

class DiceObject < GameObject
	include Helpers::Images
	traits :bounding_box

	attr_reader :value

	def initialize options = {}
		@value = options.delete(:value)
		super({:image => dice_image(@value)}.merge(options))
	end
end

end
