require 'chingu'
include Gosu
include Chingu

class Team
	attr_accessor :time, :active
	attr_reader   :side

	def initialize options = {}
		@name   = options[:name]   || ""
		@ai     = options[:ai]     || false
		@image  = options[:image]

		@active = options[:active] || false

		@side   = options[:side] || :A

		@players = []

		@turn_listeners  = []
		@score_listeners = []

		@time  = 240_000
		@turns = 0

		new_period!
	end

	def << player
		@players << player
	end

	def [] pos
		@players.each { |p| return p if p.pos == pos and p.on_pitch? }
		nil
	end

	def each
		@players.each { |p| yield p }
	end

	def new_period!
		@points = 0
		@turn   = 0
		@blitz  = false
	end

	def new_turn!
		@players.each { |p| p.new_turn! }
		@active = true
		inc :turn
		@blitz     = false
	end

	def end_turn!
		@pitch.turnover!
	end

	def blitz!
		@blitz = true
	end

	def blitz?
		@blitz
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

	def active?
		@active
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
