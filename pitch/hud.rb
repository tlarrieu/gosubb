require 'chingu'
include Gosu
include Chingu

require "player/player"
require "pitch/team"

require "helpers/barrier"

class HUD < GameObject

	def initialize options = {}
		super :x => 0, :y => 784
		@width  = $window.width
		@height = 200

		teams  = options[:teams] || raise(ArgumentError, "Missing argument :teams")
		pitch  = options[:pitch] || raise(ArgumentError, "Missing argument :pitch")

		@bg = Image["hud2.png"]

		@player = nil

		center_x = @x + @width / 2.0
		center_y = @y + @height / 2.0 + 20

		TeamBlock.create :team => teams[0],
						 :x => @x + 20,
						 :y => center_y,
						 :color => Gosu::Color::BLUE,
						 :pitch => pitch

		TeamBlock.create :team => teams[1],
						 :x => @x + @width - 20,
						 :y => center_y,
						 :color => Gosu::Color::RED,
						 :rotation_center => :center_right,
						 :pitch => pitch

		@player_block = PlayerBlock.create :x => center_x, :y => center_y
	end

	def draw
		super
		@bg.draw @x + (@width - @bg.width) / 2, @y + (@height - @bg.height), 1
	end

	def stick player
		@player = player
	end

	def show player
		raise ArgumentError, "Wrong parameter for method 'show'. Expected a player but received a #{player.class}" unless player.is_a? Player

		@player_block.set player
	end

	def clear
		@player_block.set @player
	end

	def lock
		@player_block.lock
	end

	def unlock
		@player_block.unlock
	end
end


class TeamBlock < GameObject
	def initialize options = {}
		super
		@team    = options[:team]
		@pitch   = options[:pitch]
		color    = options[:color] || 0xFFFFFFFF
		rot_cent = options[:rotation_center] || :center_left

		a_x, a_y = rotation_center(rot_cent)
		a_x -= 0.5

		@score = Text.create "#{@team.score}", :x => @x, :y => @y - 30, :rotation_center => rot_cent, :color => color, :size => 40
		@turn  = Text.create "#{@team.turn} / 16", :x =>  @x, :y => @y + 30, :rotation_center => rot_cent, :color => color, :size => 35
		if @team.active
			@time = Text.create "4:00", :x => @x - a_x * 280, :y => @y, :rotation_center => rot_cent, :color => color, :size => 40
		else
			@time = Text.create "", :x => @x - a_x * 280, :y => @y, :rotation_center => rot_cent, :color => color, :size => 40
		end

		@team.on_turn_change { |turn| @turn.text = "#{turn} / 16" }
		@team.on_score_change { |score| @score.text = "#{score}" }

		@elapsed_time = 0
	end

	def update
		super
		time = Time.at((@team.time - @elapsed_time) / 1000)
		nb_min = time.min
		nb_sec = time.sec
		nb_sec = "0#{nb_sec}" if nb_sec < 10
		if @team.active?
			@time.text = "#{nb_min}:#{nb_sec}"
			if @team.time - @elapsed_time <= 0
				@elapsed_time = 0
				@pitch.turnover!
			end
			@elapsed_time += $window.milliseconds_since_last_tick
		else
			@time.text = ""
		end
	end
end

class PlayerBlock < GameObject
	include Barrier

	def initialize options = {}
		super options.merge( { :rotation_center => :center_center } )
		@txt = {}
		@txt[:ma]  = Text.create( "",  :x => @x - 70, :y => @y - 45, :zorder => 2, :rotation_center => :center_right )
		@txt[:str] = Text.create( "", :x => @x - 80, :y => @y - 15, :zorder => 2, :rotation_center => :center_right )
		@txt[:agi] = Text.create( "", :x => @x - 80, :y => @y + 15, :zorder => 2, :rotation_center => :center_right )
		@txt[:arm] = Text.create( "", :x => @x - 70, :y => @y + 45, :zorder => 2, :rotation_center => :center_right )
	end

	def set player
		@player = player
		@portrait.destroy if @portrait
		if player.nil?
			@txt.each { |key,value| @txt[key].text = ""}
		else
			unlocked? do
				@txt[:ma].text  = "MA  : #{player.stats[:ma]}"
				@txt[:str].text = "STR : #{player.stats[:str]}"
				@txt[:agi].text = "AGI : #{player.stats[:agi]}"
				@txt[:arm].text = "ARM : #{player.stats[:arm]}"
				@portrait = GameObject.create :x => @x, :y => @y, :image => player.image, :factor => 2
			end
		end
	end
end
