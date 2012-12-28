#!/usr/bin/ruby
require 'rubygems'
require 'chingu'
include Gosu
include Chingu
require 'singleton'

require "player"
require "pitch"
require "helper"
require "ball"
require "floating_text"
require "game_menu.rb"

class Game < Window

	attr_accessor :selected

	def initialize
		super 1384, 784, true
		self.cursor  = true
		self.factor  = 1

		@selected      = nil
		@last_selected = nil
		@ma_squares    = []

		@barrier       = 0
		@turnover      = false
		@action_coords = nil

		@pitch = Pitch.new
		push_game_state @pitch, :setup => true
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
