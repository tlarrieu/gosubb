require "chingu"
include Chingu
include Gosu

require "barrier"
require "team"

class Pitch < GameObject
	include Helpers::Measures
	include Helpers::Barrier

	attr_reader :teams, :active_team

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

		@teams = []
		@teams << Team.new( :name => "TROLOLOL", :active => true, :side => :A, :pitch => self )
		@teams << Team.new( :name => "OTAILLO", :side => :B, :pitch => self )
		@active_team = @teams[0]
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
		@teams.each { |t| return t[pos] unless t[pos].paused? if t[pos]}
		nil
	end

	def active_players_around pos
		res = []
		-1.upto 1 do |i|
			-1.upto 1 do |j|
				unless i == 0 and i == 0
					x, y = pos[0] + i, pos[1] + j
					res << self[[x,y]] if self[[x,y]] and self[[x,y]].health == Health::OK
				end
			end
		end
		res
	end

	def active_team= team
		@teams.each { |t| t.active = false }
		@active_team = team
		@active_team.new_turn!
	end

	def unlock
		super
		@unlock_listener.call if @unlock_listener
	end

	def on_unlock &block
		@unlock_listener = block
	end
end