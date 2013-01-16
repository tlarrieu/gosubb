require 'chingu'
include Gosu
include Chingu

class Team < GameObjectList
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

	def >> player
		@players.delete player
		@kos.delete player
		@dead.delete player

		case player.state
		when :ko
			@kos << player
			player.destroy!
		when :dead
			@dead << player
			player.destroy!
		else
			@players << player
		end
	end

	def update
		@players.each { |p| p.update }
	end

	def draw
		@players.each { |p| p.draw }
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
			#@score_listeners.each { |listener| listener.call(@points) }
			@score_listener.call(@points) if @score_listener
		when :turn
			@turns += 1
			#@turn_listeners.each { |listener| listener.call(@turns) }
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
		#@turn_listeners << block
		@turn_listener = block
	end

	def on_score_change &block
		#@score_listeners << block
		@turn_listener = block
	end
end
