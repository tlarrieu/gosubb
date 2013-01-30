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

		@pitch  = options[:pitch] || raise(ArgumentError, "You did not specify a pitch for #{self}")

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
		@active = true
		@players.each { |p| p.new_turn! }
		inc :turn
		@blitz     = false
	end

	def end_turn!
		@pitch.turnover! if active?
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

	def active= b
		@active = b
		@players.each { |p| p.notify_ring_change }
	end

	def number
		return 0 if @side == :A
		1
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
