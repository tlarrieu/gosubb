require 'chingu'
include Gosu
include Chingu

require "player"
require "team"

class HUD < GameObject

	def initialize options = {}
		super :x => 0, :y => 784
		@width  = $window.width
		@height = 200

		teams  = options[:teams]

		@bg = Image["hud2.png"]

		@player = nil

		center_x = @x + @width / 2.0
		center_y = @y + @height / 2.0 + 20

		TeamBlock.create :team => teams[0], :x => @x + 20, :y => center_y, :color => Gosu::Color::BLUE
		TeamBlock.create :team => teams[1], :x => @x + @width - 20, :y => center_y, :color => Gosu::Color::RED, :rotation_center => :center_right

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
end


class TeamBlock < GameObject
	def initialize options = {}
		super
		@team = options[:team]
		color = options[:color] || 0xFFFFFFFF
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

		@elapsed_time = 0
	end

	def update
		super
		@score.text = "#{@team.score}"
		@turn.text  = "#{@team.turn} / 16"

		time = Time.at(@team.time_left / 1000)
		nb_min = time.min
		nb_sec = time.sec
		if @team.active
			@time.text = "#{nb_min}:#{nb_sec}"
		else
			@time.text = ""
		end

		@elapsed_time += $window.milliseconds_since_last_tick
	end
end


class PlayerBlock < GameObject

	def initialize options = {}
		super options.merge( { :rotation_center => :center_center } )
		@txt = {}
	end

	def draw
		@txt.each_value { |txt| txt.draw }
		@image.draw unless @image.nil?
	end

	def set player
		@player = player
		if player.nil?
			@txt = {}
			@image = nil
		else
			@txt[:ma]  = Text.new( "MA  : #{player.stats[:ma]}",  :x => @x - 70, :y => @y - 45, :zorder => 2, :rotation_center => :center_right )
			@txt[:str] = Text.new( "STR : #{player.stats[:str]}", :x => @x - 80, :y => @y - 15, :zorder => 2, :rotation_center => :center_right )
			@txt[:agi] = Text.new( "AGI : #{player.stats[:agi]}", :x => @x - 80, :y => @y + 15, :zorder => 2, :rotation_center => :center_right )
			@txt[:arm] = Text.new( "ARM : #{player.stats[:arm]}", :x => @x - 70, :y => @y + 45, :zorder => 2, :rotation_center => :center_right )
			@image = GameObject.new :x => @x, :y => @y, :image => player.image
			@image.factor = 2
		end
	end
end
