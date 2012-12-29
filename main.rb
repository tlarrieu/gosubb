#!/usr/bin/ruby
require 'rubygems'
require 'chingu'
include Gosu
include Chingu

$LOAD_PATH.unshift File.dirname(__FILE__)
require "pitch"

class Game < Window

	attr_accessor :selected

	def initialize
		super 1384, 784, true
		self.cursor  = true
		self.factor  = 1

		push_game_state Pitch.new, :setup => true
	end

	def update
		super
		self.caption = "Bloodbowl (fps : #{fps})"
	end

end

if __FILE__ == $0
	Image.autoload_dirs  += [File.join(File.dirname(__FILE__), "media", "images")]
	Sample.autoload_dirs += [File.join(File.dirname(__FILE__), "media", "sounds")]
	Game.new.show
end
