require 'chingu'
include Chingu
include Gosu

class Square < GameObject
	attr_reader :image, :rect

	@@type  = :ma
	@@color = :green

	def initialize options={}
		@type = options.delete(:type) || @@type
		@color = options.delete(:color) || @@color


		str = ""
		case @type
			when :state
				str += "selected-"
			else
				str += "square-"
		end
		case @color
			when :red
				str += "red"
			when :orange
				str += "orange"
			when :yellow
				str += "yellow"
			else
				str += "green"
		end
		str += ".png"

		super
		@image = Image[str]
	end
end
