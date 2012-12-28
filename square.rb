require 'chingu'
include Chingu
include Gosu

require 'helper'

class Square < GameObject
	attr_reader :image, :rect

	@@type  = :ma
	@@color = :green

	def initialize options={}
		type = options[:type] or @@type
		color = options[:color] or @@color

		str = "square-"
		case type
			when :ma
				str += ""
			when :state
				str += "select-"
			else
				str += ""
		end
		case color
			when :green
				str += "green"
			when :red
				str += "red"
			when :orange
				str += "orange"
			else
				str += "green"
		end
		str += ".png"

		super(:image => Image[str], :x => options[:x], :y => options[:y]) rescue nil
	end
end
