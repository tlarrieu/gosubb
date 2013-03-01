require "chingu"
include Chingu
include Gosu

require "pre_match_state"
require "pitch"

class LoadingState < GameState
	trait :timer

	def initialize
		super
		Pitch.create
	end

	def setup
		# after(2000) {push_game_state(FadeTo.new(PreMatchState.new, :speed => 10))}
		after(0) {push_game_state PreMatchState.new}
	end

	def draw
		super
		$window.fill_rect [0, 0, $window.width, $window.height], 0xAA000000, 50
	end
end