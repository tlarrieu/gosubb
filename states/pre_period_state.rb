require "chingu"
include Gosu
include Chingu

require "main_menu_state"
require "kickoff_state"
require "pitch"
require "player"


class PrePeriodState < GameState
	def initialize options = {}
		super
		@pitch = options[:pitch]
		@pitch.load options[:teams]

		add_game_object @pitch
		@pitch.each { |p| add_game_object p }
		self.input = { :escape => lambda {push_game_state MainMenuState.new }, :return => lambda { close; push_game_state KickoffState.new :pitch => @pitch} }
	end
end
