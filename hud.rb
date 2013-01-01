require 'chingu'
include Gosu
include Chingu

require "player"

class HUD

	def initialize options = {}
		@x      = options[:x] || 0
		@y      = options[:y] || 0
		@color  = options[:color] || 0x15FFFFFF
		@width  = options[:width] || $window.width
		@height = options[:height] || 200

		@bg = Image["hud.png"]

		@txt = {}
		@player = nil
	end

	def draw
		# Background layer
		#$window.fill_rect [@x, @y, @width, @height], 0xFFFFFFFF, 1
		@bg.draw @x + (@width - @bg.width) / 2, @y + (@height - @bg.height), 1

		unless @image.nil?
			left = @x + (@width - @image.width) / 2
			top = @y + (@height - @image.height) / 2
			# Player image
			@image.draw unless @image.nil?

		end
		
		@txt.each { |key, txt| txt.draw } unless @txt.nil?
	end

	def stick player
		@player = player
	end

	def show player
		raise ArgumentError, "Wrong parameter for method 'show'. Expected a player but received a #{player.class}" unless player.is_a? Player

		@txt[:ma]  = Text.new( "MA  : #{player.stats[:ma]}",  :x => @x + @width / 2.0 - 60, :y => @y + 65, :zorder => 2, :rotation_center => :center_right )
		@txt[:str] = Text.new( "STR : #{player.stats[:str]}", :x => @x + @width / 2.0 - 78, :y => @y + 90, :zorder => 2, :rotation_center => :center_right )
		@txt[:agi] = Text.new( "AGI : #{player.stats[:agi]}", :x => @x + @width / 2.0 - 78, :y => @y + 115, :zorder => 2, :rotation_center => :center_right )
		@txt[:arm] = Text.new( "ARM : #{player.stats[:arm]}", :x => @x + @width / 2.0 - 60, :y => @y + 140, :zorder => 2, :rotation_center => :center_right )
		@image = GameObject.new :x => @x + @width / 2.0, :y => @y + @height / 2.0, :image => player.image
		@image.factor = 2
	end

	def clear
		@txt.clear
		if @player.nil?
			@image = nil
		else
			show @player
		end
	end
end
