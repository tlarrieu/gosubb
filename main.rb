#!/usr/bin/ruby
$: << File.expand_path(File.dirname(__FILE__))
$: << File.join(File.expand_path(File.dirname(__FILE__)), "helpers")
$: << File.join(File.expand_path(File.dirname(__FILE__)), "shared")
$: << File.join(File.expand_path(File.dirname(__FILE__)), "states")
$: << File.join(File.expand_path(File.dirname(__FILE__)), "config")

require 'rubygems'
require 'chingu'
include Gosu
include Chingu

require "floating_text"
require "play_state"
require "cursor"

include GameStates

class Game < Window
	attr_accessor :selected

	def initialize
		super 1384, 984, true
		self.input   = { :q => :close }
		self.cursor  = false
		self.factor  = 1

		FPSText.create "fps", :x => 15, :y => 25, :zorder => 1000

		@cursor_image = Cursor.create

		push_game_state PlayState.new
	end

	def update
		super
		self.caption = "Bloodbowl (fps : #{fps})"
	end

	def change_cursor symb
		@cursor_image.set_image symb
	end
end

if __FILE__ == $0
	Image.autoload_dirs  += [File.join(File.dirname(__FILE__), "media", "images")]
	Sample.autoload_dirs += [File.join(File.dirname(__FILE__), "media", "sounds")]
	Sample.autoload_dirs += [File.join(File.dirname(__FILE__), "media", "cursors")]
	Game.new.show
end
