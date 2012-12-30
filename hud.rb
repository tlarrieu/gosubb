require 'chingu'
include Gosu
include Chingu

require "player"

class HUD < BasicGameObject

	def initialize options = {}
		@x      = options[:x] || 0
		@y      = options[:y] || 0
		@color  = options[:color] || 0x15FFFFFF
		@width  = options[:width] || $window.width
		@height = options[:height] || 200

		@txt = {}
	end

	def draw
		$window.fill_rect [@x, @y, @width, @height], @color, 0
		@txt.each { |key, txt| txt.draw }
	end

	def show player
		raise "Wrong parameter for method 'show'. Expected a player but received a #{player.class}" unless player.is_a? Player

		@txt[:ma]  = Text.new( "MA  : #{player.stats[:ma]}",  :x => @x + 10, :y => @y + 10 )
		@txt[:str] = Text.new( "STR : #{player.stats[:str]}", :x => @x + 10, :y => @y + 35 )
		@txt[:agi] = Text.new( "AGI : #{player.stats[:agi]}", :x => @x + 10, :y => @y + 60 )
		@txt[:arm] = Text.new( "ARM : #{player.stats[:arm]}", :x => @x + 10, :y => @y + 85 )
	end

	def clear
		@txt.clear
	end
end
