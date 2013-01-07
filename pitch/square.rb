require 'chingu'
include Chingu
include Gosu

class Square < GameObject
	traits :bounding_box

	attr_reader :image, :rect

	@@type  = :state
	@@color = :green

	def initialize options={}
		@type = options.delete(:type) || @@type
		@color = options.delete(:color) || @@color

		valid_types = [:state, :square]
		raise ArgumentError, "Wrong type #{@type}" unless valid_types.include? @type
		valid_colors = { :state => [:red, :green, :yellow], :square => [:green, :blue, :gray]}
		raise ArgumentError, "Wrong color #{@color}" unless valid_colors[@type].include? @color

		@image = Image["#{@type}-#{@color}.png"]
		super
	end
end
