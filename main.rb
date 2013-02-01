#!/usr/bin/ruby
$: << File.expand_path(File.dirname(__FILE__))
$: << File.join(File.expand_path(File.dirname(__FILE__)), "helpers")
$: << File.join(File.expand_path(File.dirname(__FILE__)), "shared")
$: << File.join(File.expand_path(File.dirname(__FILE__)), "states")
puts $:

require 'rubygems'
require 'chingu'
include Gosu
include Chingu

require "floating_text"
require "play_state"

include GameStates

class Game < Window
	attr_accessor :selected

	def initialize
		super 1384, 984, true
		self.input   = { :q => :close }
		self.cursor  = false
		self.factor  = 1

		FPSText.create "fps", :x => 15, :y => 25, :zorder => 1000

		change_cursor :normal

		push_game_state PlayState.new
	end

	def update
		super
		self.caption = "Bloodbowl (fps : #{fps})"
	end

	def draw
		super
		@cursor_image.draw mouse_x, mouse_y, 1000 if @cursor_image
	end

	def change_cursor symb
		raise ArgumentError, "#{symb}" unless symb.is_a? Symbol
		@cursor_image = Image["cursors/#{symb}.png"]
	end
end

if __FILE__ == $0
	Image.autoload_dirs  += [File.join(File.dirname(__FILE__), "media", "images")]
	Sample.autoload_dirs += [File.join(File.dirname(__FILE__), "media", "sounds")]
	Game.new.show
end
