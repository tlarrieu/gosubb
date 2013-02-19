require "chingu"
include Chingu
include Gosu

require "helpers/dices"
require "states/post_combat_state"

# TODO implement reroll

class CombatState < GameState
	include Helpers::Dices

	def initialize options = {}
		super
		self.input = { :mouse_left => :click }

		@attacker = options[:attacker]
		@defender = options[:defender]

		nb_dices = @attacker.nb_block_dices(@defender).abs

		x = ($window.width - (nb_dices - 1) * 50) / 2.0
		y = ($window.height - 37) / 2.0

		@dices = []
		nb_dices.times do
			@dices << DiceObject.create(
				:value => roll(:block),
				:x => x,
				:y => y,
				:zorder => 201,
				:defender => @defender,
				:attacker => @attacker,
			)
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
		$window.change_cursor :normal
	end

	def draw
		super
		previous_game_state.draw
		$window.fill_rect([0, 0, $window.width, $window.height], 0xAA000000, 200)
	end

	def click
		@dices.each do |dice|
			if dice.collision_at? $window.mouse_x, $window.mouse_y
				@attacker.cant_move!
				dice.select
				break
			end
		end
	end
end

class DiceObject < GameObject
	traits :bounding_box

	attr_reader :value

	def initialize options = {}
		@value    = options.delete(:value)
		@attacker = options.delete(:attacker)
		@defender = options.delete(:defender)

		valid_symbols = [
			:attacker_down,
			:both_down,
			:pushed,
			:defender_stumble,
			:defender_down
		]

		raise "Invalid argument '#{@value}' for method dice_image" unless valid_symbols.include? @value

		super({:image => "dices/#{@value}.gif"}.merge(options))
	end

	def select
		push = false
		case @value
		when :attacker_down
			@defender.down @attacker
		when :both_down
			if @defender.skills.include? :block
				@defender.event! :block
			else
				@attacker.down @defender
			end
			if @attacker.skills.include? :block
				@attacker.event! :block
			else
				@defender.down @attacker
			end
		when :defender_stumble
			@attacker.stumble @defender
			push = true
		when :defender_down
			@attacker.down @defender
			push = true
		when :pushed
			@attacker.push @defender
			push = true
		end
		parent.close
		parent.push_game_state PostCombatState.new(:attacker => @attacker, :defender => @defender) if push
	end
end
