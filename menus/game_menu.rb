require 'chingu'
include Chingu
include Gosu

module Menus

class GameMenu < GameState
	def setup
		Sample["pause_in.ogg"].play 0.5
		@text = ""
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
		                    :font_size => 40

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

class Menu < BasicGameObject
	include Chingu::Helpers::InputClient, Chingu::Helpers::RotationCenter
	attr_accessor :menu_items, :visible, :width, :height, :x, :y

	def initialize(options = {})
		super

		@font_size      = options.delete(:font_size) || 30
		@menu_items     = options.delete(:menu_items)
		@anchor         = options.delete(:anchor) || :center_center
		@x              = options.delete(:x) || 0
		@y              = options.delete(:y) || 0
		@spacing        = options.delete(:spacing) || 100
		@items          = []
		@visible        = options.delete(:visible) || true
		@select_color   = options.delete(:select_color) || Gosu::Color::RED
		@unselect_color = options.delete(:unselect_color) || Gosu::Color::WHITE
		@bg_color       = options.delete(:bg_color) || 0x00000000
		@bg_padding_l   = options.delete(:bg_padding_l) || 0
		@bg_padding_r   = options.delete(:bg_padding_r) || 0
		@bg_padding_t   = options.delete(:bg_padding_t) || 0
		@bg_padding_b   = options.delete(:bg_padding_b) || 0


		@zorder         = options.delete(:zorder) || 0

		@width  = 0
		@height = 0

		menu_items.each do |key, value|
			item = if key.is_a? String
				opt = {:size => @font_size}.merge(options.dup)
				opt[:color] = @unselect_color
				Text.new key, opt
			elsif key.is_a? Image
				GameObject.new options.merge!(:image => key)
			elsif key.is_a? GameObject
				key.options.merge! options.dup
				key
			end

			item.options[:on_select]   = method(:on_select)
			item.options[:on_deselect] = method(:on_deselect)
			item.options[:action]      = value

			item.rotation_center = @anchor
			item.zorder = @zorder + 1
			@items << item

			@width   = item.width if item.width > @width
			@height += item.height
		end
		@height += (@items.count - 1) * @spacing unless @items.nil?

		y = @y - @height / 2.0 + @spacing

		anchor_x, anchor_y = rotation_center(@anchor)
		anchor_x -= 0.5
		anchor_y -= 0.5

		@items.each do |item|
			item.rotation_center = @anchor
			item.x = @x + anchor_x * @width
			item.y = y + anchor_y * item.height
			y += item.height + @spacing
		end

		@selected = options[:selected] || 0
		step(0)

		self.input = {
			[:up, :s] => lambda{step(-1)},
			[:down, :t] => lambda{step(1)},
			[:return, :space, :mouse_left] => :select
		}
	end

	#
	# Moves selection within the menu. Can be called with negative or positive values. -1 and 1 makes most sense.
	#
	def step(value)
		selected.options[:on_deselect].call(selected)
		@selected += value
		@selected %= @items.count
		selected.options[:on_select].call(selected)
	end

	def select
		dispatch_action(selected.options[:action], self.parent)
	end

	def selected
		@items[@selected]
	end

	def on_deselect(object)
		object.color = @unselect_color
	end

	def on_select(object)
		Sample["menu_select.ogg"].play 0.6
		object.color = @select_color
	end

	def update
		i = 0
		# This should be done with :bounding_box trait but I cant seem
		# to add a trait to items for some reasons
		begin
			@items.each do |item|
				y = $window.mouse_y
				if item.y - item.height / 2.0 <= y and item.y +  item.height / 2.0 >= y
					step(i - @selected) if @selected != i
				end
				i += 1
			end
		rescue
			nil
		end
	end

	def draw
		parent.fill_rect(
						[
							@x - 20 - @bg_padding_l - @width / 2.0,
							@y - @bg_padding_t - @height / 2.0,
							@width + 40 + @bg_padding_l + @bg_padding_r,
							@height + @bg_padding_t + @spacing + @bg_padding_b
						],
						@bg_color,
						@zorder) rescue nil
		@items.each { |item| item.draw }
	end

	private

	def dispatch_action(action, object)
		case action
		when Symbol, String
			object.send(action)
		when Proc, Method
			action[]
		when Chingu::GameState
			game_state.push_game_state(action)
		when Class
			if action.ancestors.include?(Chingu::GameState)
				game_state.push_game_state(action)
			end
		else
			# TODO possibly raise an error? This ought to be handled when the input is specified in the first place.
		end
	end
end

end
