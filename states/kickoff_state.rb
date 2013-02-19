require "chingu"
include Chingu
include Gosu

require "play_state"

class KickoffState < GameState
	def initialize options = {}
		super
		@pitch = options[:pitch] || raise(ArgumentError, "You did not specify a pitch for #{self}")
		add_game_object @pitch
		@pitch.each { |p| add_game_object p }
		self.input = { :space => lambda{push_game_state PlayState.new(:pitch => @pitch) }}

		@hud = HUD.create
	end
end