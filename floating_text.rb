require 'chingu'
include Chingu
include Gosu

class FloatingText < Chingu::Text
	traits :timer

	@@size = 25
	@@font = "media/fonts/averia_rg.ttf"

	def initialize text, options = {}
		super text, options

		options = {:timer => 1000}.merge(options)
		@x -= width / 2.0
		after(options[:timer]) { self.destroy! }
	end
end

class FPSText < Chingu::Text
	def update
		super
		self.text = "FPS: #{$window.fps}"
	end
end
