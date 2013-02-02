require 'singleton'

class Cursor < GameObject

	def initialize
		super
		@list =
		{
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
		@image = @list[:normal]
		rotation_center(:top_left)
		@zorder = 1000
		@x = $window.mouse_x
		@y = $window.mouse_y
	end

	def set_image key
		raise ArgumentError, "Unknown cursor #{key}" unless @list.key? key
		@image = @list[key]
	end

	def update
		@x = $window.mouse_x
		@y = $window.mouse_y
	end
end