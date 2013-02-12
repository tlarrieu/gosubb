require "chingu"
include Chingu
include Gosu

class KickoffState < GameState
	def initialize options = {}
		super
		@pitch = options[:pitch] || raise(ArgumentError, "You did not specify a pitch for #{self}")
		add_game_object @pitch
		@pitch.each do |p|
			add_game_object p
			p.input = { :mouse_left => lambda {p.select}}
		end
	end
end