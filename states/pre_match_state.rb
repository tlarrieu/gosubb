require "chingu"
include Chingu
include Gosu

require "team"
require "config"
require "pitch"
require "menu"
require "pre_period_state"

class PreMatchState < GameState
	def initialize options = {}
		super
		@choice = rand(0..1)

		@pitch = Pitch.create

		@teams = options[:teams]
		unless @teams
			@teams = []
			@teams << Team.new( :name => "TROLOLOL", :race => Configuration[:teams][0][:race], :side => :A, :pitch => @pitch )
			@teams << Team.new( :name => "OTAILLO", :race => Configuration[:teams][1][:race], :side => :B, :pitch => @pitch )
		end

		@image = @teams[@choice].image
		@circle_r = [@image.width, @image.height].max + 2
		@circle_x = $window.width / 2
		@circle_y = $window.height / 2 - 100
		@circle_c = if @choice == 0 then 0xFF0000FF else 0xFFFF0000 end

		self.input = { :escape => lambda {push_game_state MainMenuState.new } }

		show_menu
	end

	def draw
		super
		$window.fill_rect [0, 0, $window.width, $window.height], 0xAA000000, 50
		$window.draw_circle @circle_x, @circle_y, @circle_r, @circle_c
		@image.draw @circle_x - @image.width / 2, @circle_y - @image.height / 2, 100 if @image
	end

	def show_menu
		items = { "Kick-off" => lambda{ choose :kickoff }, "Catch" => lambda{ choose :catch } }.sort_by { |key,value| key }
		@menu = Menu.create :menu_items => items,
			:x => $window.width / 2.0 + 50,
			:y => @circle_y + @circle_r + 20 ,
			:zorder => 200,
			:select_color => 0xFF0056D6,
			:unselect_color => 0xFFFFFFFF,
			:spacing => 30,
			:bg_padding_r => 5,
			:bg_padding_l => 5,
			:bg_padding_t => 30,
			:bg_padding_b => 5,
			:anchor => :center_center,
			:font => "media/fonts/averia_rg.ttf",
			:font_size => 35,
			:orientation => :horizontal
	end

	def choose action
		close

		if action == :catch
			@teams[@choice].active = true
		else
			@teams[(@choice + 1) % 2].active = true
		end

		push_game_state PrePeriodState.new(:pitch => @pitch, :teams => @teams)
	end
end