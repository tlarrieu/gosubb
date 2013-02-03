require 'chingu'
include Chingu
include Gosu

class Square < GameObject
	traits :bounding_box

	attr_reader :image, :rect

	@@type  = :state
	@@color = :green

	@@loaded = {}

	def initialize options={}
		options = {:type => @@type, :color => @@color}.merge(options)
		config options
		options.delete(:color)
		super
	end

	def config options = {}
		@x     = options[:x]     || @x
		@y     = options[:y]     || @y
		@type  = options[:type]  || @type
		@color = options[:color] || @color

		valid_types = [:state, :square]
		raise ArgumentError, "Wrong type #{@type}" unless valid_types.include? @type
		valid_colors = { :state => [:red, :green, :yellow], :square => [:green, :blue, :gray]}
		raise ArgumentError, "Wrong color #{@color}" unless valid_colors[@type].include? @color

		key = "#{@type}-#{@color}"
		unless @@loaded[key]
			@@loaded[key] = Image["#{@type}-#{@color}.png"]
		end
		@image = @@loaded[key]
	end
end

class MovementSquare < Square
	def initialize options={}
		super options.merge({:type => :square})
	end
end

class StateSquare < Square
	def initialize options={}
		super options.merge({:type => :state})
	end
end