#!/usr/bin/ruby
require 'rubygems'
require 'chingu'
include Gosu
include Chingu

local = File.expand_path File.dirname(__FILE__)
$LOAD_PATH.unshift local unless $LOAD_PATH.include? local

require "pitch/floating_text"
require "pitch/pitch"

class Array
	def sample
		return self[rand(count)] if count > 0
		nil
	end
end

class Game < Window
	attr_accessor :selected

	def initialize
		super 1384, 984, true
		self.input   = { :q => :close }
		self.cursor  = false
		self.factor  = 1
		self.volume = 0.8

		@fps = FPSText.create "fps", :x => 15, :y => 10, :zorder => 1000

		change_cursor :normal

		push_game_state Pitch.new
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
