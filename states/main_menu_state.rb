require 'chingu'
include Chingu
include Gosu

require 'menu'

class MainMenuState < GameState
	def setup
		Sample["pause_in.ogg"].play 0.5

		# Since we cant ensure order on hash keys, we will use the following array
		# combined with Hash#sort_by to key the same order, no matter what
		a = ["Resume", "Load", "Save", "Exit"]
		items = {"Resume" => :close, "Exit" => lambda { close_game }, "Save" => :save, "Load" => :load}.sort_by { |key,value| a.index(key) }
		GameObject.create :image => "pause_bg.jpg",
			:x => $window.width / 2.0,
			:y => $window.height / 2.0,
			:scale => 0.8,
			:zorder => 0
		Menu.create :menu_items => items,
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

		self.input = { :escape => :close }
	end

	def finalize
		Sample["pause_out.ogg"].play 0.5
	end

	def save
	end

	def load
	end
end
