require "chingu"
include Gosu
include Chingu

require "main_menu_state"
require "play_state"
require "pitch"
require "player"


class OrganizeState < GameState
	def initialize
		super
		@pitch = Pitch.create
		self.input = { :escape => lambda {push_game_state MainMenuState.new }, :return => lambda { close; push_game_state PlayState.new :pitch => @pitch} }
	end
end
