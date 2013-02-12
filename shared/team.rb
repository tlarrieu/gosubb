require 'chingu'
include Gosu
include Chingu

class Team
	attr_accessor :time, :active
	attr_reader   :side, :image, :race, :points
	alias :score :points

	@@loaded = {}

	def initialize options = {}
		@name   = options[:name]   || ""
		@ai     = options[:ai]     || false

		@active = options[:active] || false

		@side   = options[:side]   || :A
		@race   = options[:race]   || raise(ArgumentError, "You did not specify a race for #{self}")

		@@loaded[@race] = Image["teams/logos/#{@race}.gif"] unless @@loaded[@race]
		@image  = @@loaded[@race]

		@pitch = options[:pitch]   || raise(ArgumentError, "You did not specify a pitch for #{self}")

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
		inc :turn
		@active  = true
		@blitz   = false
		@pass    = false
		@handoff = false
		@players.each { |p| p.new_turn! }
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

	def pass!
		@pass = true
	end

	def pass?
		@pass
	end

	def handoff!
		@handoff = true
	end

	def handoff?
		@handoff
	end

	def inc symb
		case symb
		when :score
			@points += 1
			@score_listener.call(@points) if @score_listener
		when :turn
			@turns += 1
			@turn_listener.call(@turns) if @turn_listener
		end
	end

	def turn
		@turn
	end

	def active?
		@active
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
