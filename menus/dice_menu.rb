require "chingu"
include Chingu
include Gosu

require "helpers"

module Menus

class DiceMenu < GameState

	def initialize options = {}
		super
		self.input = { :mouse_left => :click }
		@color = 0xAA000000

		@nb_dices = options[:dices] || 1

		@attacker = options[:attacker]
		@defender = options[:defender]

		x = ($window.width - (@nb_dices - 1) * 50) / 2.0
		y = ($window.height - 37) / 2.0

		@dices = []
		@nb_dices.times do
			@dices << DiceObject.create( :value => Dice.roll(:block), :x => x, :y => y, :zorder => 1001 )
			x += 50
		end

		@caption = Text.create "Select a dice", :x => $window.width / 2.0 - 60, :y => $window.height / 2.0 + 30, :zorder => 1001
	end

	def update
		super
		previous_game_state.update
	end

	def draw
		super
		previous_game_state.draw
		$window.fill_rect([0, 0, $window.width, $window.height], @color, 1000)
	end

	def click
		found = false
		@dices.each do |dice|
			if dice.collision_at? $window.mouse_x, $window.mouse_y
				case dice.value
				when :attacker_down
					@attacker.down
					found = true
				when :both_down
					@attacker.down
					@defender.down
					found = true
				when :defender_stumble
					@defender.stumble
					found = true
				when :defender_down
					@defender.down
					found = true
				when :pushed
					@defender.push
					found = true
				break
				end
			end
		end

		if found
			@attacker.cant_move!
			close
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
