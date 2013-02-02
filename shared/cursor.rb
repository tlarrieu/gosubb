require 'singleton'

class Cursor < GameObject

	def initialize
		super
		@list =
		{
			:ball    => Image["cursors/ball.png"],
			:blitz   => Image["cursors/blitz.png"],
			:d_1     => Image["cursors/d_1.png"],
			:d_2     => Image["cursors/d_2.png"],
			:d_3     => Image["cursors/d_3.png"],
			:d_1_red => Image["cursors/d_1_red.png"],
			:d_2_red => Image["cursors/d_2_red.png"],
			:d_3_red => Image["cursors/d_3_red.png"],
			:handoff => Image["cursors/handoff.png"],
			:move    => Image["cursors/move.png"],
			:no      => Image["cursors/no.png"],
			:normal  => Image["cursors/normal.png"],
			:red     => Image["cursors/red.png"],
			:select  => Image["cursors/select.png"],
			:standup => Image["cursors/standup.png"],
			:take    => Image["cursors/take.png"],
			:throw   => Image["cursors/throw.png"],
			:wait    => Image["cursors/wait.png"]
		}

		@secondary_list =
		{
			:one   => Image["cursors/plus_one.png"],
			:two   => Image["cursors/plus_two.png"],
			:three => Image["cursors/plus_three.png"],
			:four  => Image["cursors/plus_four.png"],
			:five  => Image["cursors/plus_five.png"],
			:six   => Image["cursors/plus_six.png"],
		}
		@image = @list[:normal]
		rotation_center(:top_left)
		@zorder = 1000
		@x = $window.mouse_x
		@y = $window.mouse_y
	end

	def draw
		super
		@secondary_image.draw $window.mouse_x, $window.mouse_y, @zorder + 1 if @secondary_image
	end

	def set_image key
		raise ArgumentError, "Unknown cursor #{key}" unless @list.key? key
		@image = @list[key]
		@secondary_image = nil
	end

	def set_secondary_image key
		raise ArgumentError, "Unknown secondary cursor #{key}" unless @secondary_list.key? key
		@secondary_image = @secondary_list[key]
	end

	def update
		if $window
			@x = $window.mouse_x
			@y = $window.mouse_y
		end
	end
end