class Cursor < GameObject
	def initialize
		super
		@list =
		{
			:ball    => Image["cursors/ball.png"],
			:blitz   => Image["cursors/blitz.png"],
			1        => Image["cursors/d_1.png"],
			2        => Image["cursors/d_2.png"],
			3        => Image["cursors/d_3.png"],
			-1       => Image["cursors/d_1_red.png"],
			-2       => Image["cursors/d_2_red.png"],
			-3       => Image["cursors/d_3_red.png"],
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
			0 => nil,
			1 => Image["cursors/plus_one.png"],
			2 => Image["cursors/plus_two.png"],
			3 => Image["cursors/plus_three.png"],
			4 => Image["cursors/plus_four.png"],
			5 => Image["cursors/plus_five.png"],
			6 => Image["cursors/plus_six.png"],
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