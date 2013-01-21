require 'chingu'
include Gosu
include Chingu

class Team
	attr_accessor :time_left, :active
	attr_reader   :side

	def initialize options = {}
		@name   = options[:name]   || ""
		@ai     = options[:ai]     || false
		@image  = options[:image]

		@active = options[:active] || false

		@side   = options[:side] || :A

		@players = []
		@kos     = []
		@dead    = []

		@turn_listeners  = []
		@score_listeners = []

		@time_left = 0

		@turns = 0

		new_period!
	end

	def << player
		@players << player
	end

	def kill player
		if @players.include? player
			@dead << @players.delete(player)
			player.destroy!
		end
	end

	def knock_out player
		if @players.include? player
			@kos << @players.delete(player)
			player.destroy!
		end
	end

	def wake_up player
		if @kos.include? player
			@players << @kos.delete(player)
		end
	end

	def [] pos
		@players.each { |p| return p if p.pos == pos}
		nil
	end

	def each
		@players.each { |p| yield p }
	end

	def new_turn!
		@players.each { |p| p.new_turn! }
		@active = true
		@time_left = 240_000
		inc :turn
		@blitz     = false
	end

	def blitz!
		@blitz = true
	end

	def blitz?
		@blitz
	end

	def update
		if @time_left > 0
			@time_left -= $window.milliseconds_since_last_tick
		end
	end

	def new_period!
		@points = 0
		@turn   = 0
		@blitz  = false
	end

	def inc symb
		case symb
		when :point
			@points += 1
			@score_listener.call(@points) if @score_listener
		when :turn
			@turns += 1
			@turn_listener.call(@turns) if @turn_listener
		end
	end

	def score
		@points
	end

	def turn
		@turn
	end

	# ---------- Listeners ----------

	def on_turn_change &block
		block.call(@turns)
		@turn_listener = block
	end

	def on_score_change &block
		block.call(@points)
		@score_listener = block
	end
end
