require 'chingu'
include Chingu
include Gosu

class FloatingText < Chingu::Text
	traits :timer

	@@size = 25
	@@font = "media/fonts/averia_rg.ttf"

	def initialize text, options = {}
		@bg_color = options.delete(:background)
		super text, {:zorder => 199}.merge(options)

		options = {:timer => 1000}.merge(options)
		@x -= width / 2.0
		after(options[:timer]) { self.destroy! }
	end

	def draw
		super
		$window.fill_rect([@x - 5, @y - 5, width + 10, height + 10], @bg_color, 198) if @bg_color
	end
end

class FPSText < Chingu::Text
	def update
		begin
			super
			self.text = "FPS: #{$window.fps}"
		rescue
			nil
		end
	end
end
