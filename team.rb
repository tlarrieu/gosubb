require 'chingu'
include Gosu
include Chingu

class Team
	attr_accessor :active, :time_left

	def initialize options = {}
		@name = options[:name] || ""
		@ai   = options[:ai]   || false
		@image = options[:image]

		@active = options[:active] || false

		@players = []

		@time_left = 0

		new_period!
	end

	def << player
		@players << player
	end

	def [] pos
		@players.each { |p| return p if p.pos == pos}
		nil
	end

	def each
		@players.each { |p| yield(p) }
	end

	def new_turn!
		@players.each { |p| p.new_turn! }
		@time_left = 240_000
		@active = true
		@turn += 1
	end

	def update
		if @time_left > 0
			@time_left -= $window.milliseconds_since_last_tick
		end
	end

	def new_period!
		@points = 0
		@turn   = 0
	end

	def inc symb
		case symb
		when :point
			@points += 1
		when :turn
			@turns += 1
		end
	end

	def score
		@points
	end

	def turn
		@turn
	end
end
