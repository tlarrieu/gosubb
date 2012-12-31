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

		@txt = {}
		@player = nil
	end

	def draw
		# Background layer
		$window.fill_rect [@x, @y, @width, @height], 0x15FFFFFF, 1
		# Left rect
		$window.fill_rect [@x + 10, @y + 15, @height - 20, @height - 25], 0x33FFFFFF, 1

		unless @image.nil?
			left = @x + (@width - @image.width) / 2
			top = @y + (@height - @image.height) / 2
			# lefty rect
			$window.fill_rect [left - @height + 10, @y + 15, @height - 20, @height - 25], 0x33FFFFFF, 1
			# Player image
			@image.draw left, top, 1 unless @image.nil?
			# righty rect
			$window.fill_rect [left + @image.width + 10, @y + 15, @height - 20, @height - 25], 0x33FFFFFF, 1
		end
		#Right rect
		$window.fill_rect [@width - @height + 10 , @y + 15, @height - 20, @height - 25], 0x33FFFFFF, 1

	end

	def stick player
		@player = player
	end

	def show player
		raise "Wrong parameter for method 'show'. Expected a player but received a #{player.class}" unless player.is_a? Player

		@txt[:ma]  = Text.new( "MA  : #{player.stats[:ma]}",  :x => @x + 20, :y => @y + 20, :zorder => 2 )
		@txt[:str] = Text.new( "STR : #{player.stats[:str]}", :x => @x + 20, :y => @y + 45, :zorder => 2 )
		@txt[:agi] = Text.new( "AGI : #{player.stats[:agi]}", :x => @x + 20, :y => @y + 70, :zorder => 2 )
		@txt[:arm] = Text.new( "ARM : #{player.stats[:arm]}", :x => @x + 20, :y => @y + 95, :zorder => 2 )
		@image = Image["#{player.race}/#{player.role}.gif"]
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
