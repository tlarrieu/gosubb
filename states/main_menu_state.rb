require 'chingu'
include Chingu
include Gosu

require 'menu'

class MainMenuState < GameState
	def setup
		Sample["pause_in.ogg"].play 0.5
		items = {"Resume" => :close, "Exit" => :exit, "Save" => :save, "Load" => :load}.sort_by { |key,value| key }
		@menu = Menu.create :menu_items => items,
		                    :x => $window.width / 2.0,
		                    :y => $window.height / 2.0,
		                    :zorder => 2,
		                    :select_color => 0xFF0056D6,
		                    :unselect_color => 0xFF000000,
		                    :spacing => 30,
		                    :bg_color => 0x33FFFFFF,
		                    :bg_padding_r => 55,
		                    :bg_padding_l => 55,
		                    :bg_padding_t => 20,
		                    :bg_padding_b => 5,
		                    :anchor => :center_center,
		                    :font => "media/fonts/Colleged.ttf",
		                    :font_size => 40,
		                    :orientation => :vertical

		@bg = GameObject.new :image => "pause_bg.jpg", :x => $window.width / 2.0, :y => $window.height / 2.0, :scale => 0.8, :zorder => 0
		self.input = { :escape => :close }
	end

	def finalize
		Sample["pause_out.ogg"].play 0.5
	end

	def draw
		super
		@bg.draw
		@menu.draw
	end

	def update
		super
		@menu.update
	end

	def exit
		$window.close
	end

	def save

	end

	def load

	end
end
