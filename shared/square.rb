require 'chingu'
include Chingu
include Gosu

class Square < GameObject
	traits :bounding_box

	attr_reader :image, :rect

	@@loaded = {}

	def initialize options={}
		options = {:color => :green}.merge(options)
		config options
		options.delete(:color)
		super
	end

	def config options = {}
		@x     = options[:x]     || @x
		@y     = options[:y]     || @y
		@color = options[:color] || @color

		valid_colors = [:green, :blue, :gray]
		raise ArgumentError, "Wrong color #{@color}" unless valid_colors.include? @color

		key = "#{@type}-#{@color}"
		unless @@loaded[key]
			@@loaded[key] = Image["square-#{@color}.png"]
		end
		@image = @@loaded[key]
	end
end
