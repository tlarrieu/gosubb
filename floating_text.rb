require 'chingu'
include Chingu
include Gosu

class FloatingText < Chingu::Text
	traits :timer

	@@size = 25
	@@font = "media/fonts/letratista_rg.ttf"

	def initialize text, options = {}
		super text, options

		options = {:timer => 1000}.merge(options)
		@x -= width / 2.0
		after(options[:timer]) { self.destroy! }
	end
end
