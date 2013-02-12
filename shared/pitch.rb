require "chingu"
include Chingu
include Gosu

require "barrier"
require "team"
require "player"
require "config"
require "ball"

class Pitch < GameObject
	include Helpers::Measures
	include Helpers::Barrier

	attr_reader :teams, :active_team, :ball

	WIDTH       = 26
	HEIGHT      = 15
	SQUARE_W    = 49.7
	SQUARE_H    = 48.8
	SPACE_X     = 3
	SPACE_Y     = 3
	MARGIN_LEFT = 8
	MARGIN_TOP  = 5

	def initialize
		super
		@image  = Image["pitch.jpg"]
		@y      = 15
		@zorder = 1
		rotation_center(:top_left)
	end

	def start_new_game ball
		raise ArgumentError unless ball.is_a? Ball
		@ball = ball
		each { |p| p.set_stage :stage => :play, :ball => @ball }
	end

	def new_turn!
		@turnover = false
		@active_team.active = false
		@active_team = @teams[(@active_team.number + 1) % 2]
		@active_team.new_turn!
	end

	def turnover!
		@turnover = true
	end

	def turnover?
		@turnover
	end

	def [] pos
		@teams.each { |t| return t[pos] if t[pos]}
		nil
	end

	def each &block
		@teams.each do |team|
			team.each do |player|
				yield player
			end
		end
	end

	def active_players_around pos, filter = :none
		filter = :none unless self[pos] # Filters have no sense unless there is a player at pos
		res = []
		-1.upto 1 do |i|
			-1.upto 1 do |j|
				unless i == 0 and i == 0
					x, y = pos[0] + i, pos[1] + j
					if self[[x,y]] and self[[x,y]].health == Health::OK
						case filter
						when :allies
							res << self[[x,y]] if self[[x,y]].team == self[pos].team
						when :opponents
							res << self[[x,y]] unless self[[x,y]].team == self[pos].team
						when :none
							res << self[[x,y]]
						end
					end
				end
			end
		end
		res
	end

	def unlock
		super
		@unlock_listener.call if @unlock_listener
	end

	def on_unlock &block
		@unlock_listener = block
	end

	def load teams
		@teams = teams
		Configuration[:teams].each do |num, team|
			race = team[:race]
			team[:players].each do |player|
				role = player[:role]
				x, y  = player[:pos]
				@teams[num] << Player.create(
					:team => @teams[num],
					:x => x,
					:y => y,
					:pitch => self,
					:race => race,
					:role => role
				)
			end
		end
		@teams.each { |t| @active_team = t if t.active? }
		@active_team.new_turn!
	end
end