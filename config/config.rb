class Configuration
	@@config = {}
	@@config[:teams] =
	{
		0 => {
			:race => :human,
			:players => [
				{ :role => :blitzer, :pos => [3,6] },
				{ :role => :blitzer, :pos => [3,8] },
				{ :role => :blitzer, :pos => [7,5] },
				{ :role => :blitzer, :pos => [7,9] },
				{ :role => :thrower, :pos => [10,1] },
				{ :role => :thrower, :pos => [10, 13] },
				{ :role => :catcher, :pos => [12,3] },
				{ :role => :ogre,    :pos => [12,6] },
				{ :role => :catcher, :pos => [12,7] },
				{ :role => :catcher, :pos => [12,8] },
				{ :role => :lineman, :pos => [12,11] }
			]
		},
		1 => {
			:race => :orc,
			:players => [
				{ :role => :blitzer,  :pos => [21,8] },
				{ :role => :blitzer,  :pos => [17,5] },
				{ :role => :blitzer,  :pos => [21,6] },
				{ :role => :blitzer,  :pos => [17,9] },
				{ :role => :thrower,  :pos => [14,1] },
				{ :role => :thrower,  :pos => [14, 13] },
				{ :role => :blackorc, :pos => [13,3] },
				{ :role => :blackorc, :pos => [13,6] },
				{ :role => :blackorc, :pos => [13,7] },
				{ :role => :blackorc, :pos => [13,8] },
				{ :role => :lineman,  :pos => [13,11] }
			]
		}
	}

	def self.[] key
		@@config[key]
	end
end