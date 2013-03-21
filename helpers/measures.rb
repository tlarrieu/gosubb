module Helpers
module Measures
	def to_pitch_coords coords
		x = (coords[0] - Pitch::MARGIN_LEFT) / (Pitch::SQUARE_W + Pitch::SPACE_X)
		y = (coords[1] - Pitch::MARGIN_TOP - 15) / (Pitch::SQUARE_H + Pitch::SPACE_Y)
		[x.floor, y.floor]
	end

	def to_screen_coords coords
		x = coords[0] * (Pitch::SQUARE_W + Pitch::SPACE_X) + Pitch::MARGIN_LEFT + Pitch::SQUARE_W / 2
		y = coords[1] * (Pitch::SQUARE_H + Pitch::SPACE_Y) + Pitch::MARGIN_TOP + Pitch::SQUARE_H / 2 + 15
		[x, y]
	end

	def dist a, b, type = :infinity
		if a.is_a?(Player) and b.is_a?(Player) then
			return dist a.pos, b.pos, type
		else
			case type
			when :infinity
				return [(a[0] - b[0]).abs, (a[1] - b[1]).abs].max
			when :manhattan
				return (a[0] - b[0]).abs + (a[1] - b[1]).abs
			when :cartesian
				return ((a[0] - b[0])**2 + (a[1] - b[1])**2)**(1.0/2.0)
			else
				raise  "Unknown type " + type.to_s + "."
			end
		end
	end

	# TODO: handle non connexity (infinite loop involved there :( )
	# TODO 2: include a way to take tackle zones into account (we still have to decide how much we want to help human player)
	def a_star pitch, start, goal
		# The set of nodes already evaluated.
		closedset = []
		# The set of tentative nodes to be evaluated.
		openset   = []
		# Visited nodes
		frontier = []
		openset << start
		# The map of navigated nodes.
		came_from                 = { }
		# Distance from start along optimal path.
		g_score, h_score, f_score = { }, { }, { }
		g_score[start]              = 0
		h_score[start]              = dist start, goal, :manhattan
		# Estimated total distance from start to goal through y.
		f_score[start]              = h_score[start]

		# Main loop
		while not openset.empty?
			# Fetching the node among openset with the least f_score
			x, _value = [], 1_000_000
			openset.each do |key|
				x, _value = key, f_score[key] if f_score[key] < _value
			end

			break if x == goal # We reached target point and thus finished looking for it !!

			# Moving x from openset to closedset
			openset.delete x
			closedset << x

			(-1..1).each do |i|
				(-1..1).each do |j|
					y = [x[0] + i, x[1] + j]
					unless i == 0 and y == 0
						if pitch[y].nil? # We only want to explore neighbours
							next if closedset.include? y # If already in closedset, we skip it

							better = false
							h      = dist x, y, :manhattan
							g      = g_score[x] + h

							if not openset.include? y then
								return [] if frontier.include? y
								frontier << y
								openset << y # Adding current neighbours to openset
								better = true
							elsif g < g_score[y]
								better = true
							else
								better = false
							end

							# Updating what needs to be
							if better then
								came_from[y] = x
								g_score[y]   = g
								h_score[y]   = dist y, goal, :manhattan # heuristic estimate of distance (y, coords)
								f_score[y]   = g_score[y] + h_score[y]
							end
						end
					end
				end
			end
		end

		# Finally assembling path and returning it
		path      = []
		_cur      = goal
		while _cur != start do
			path << _cur
			_cur = came_from[_cur]
		end

		return path.reverse
	end
end
end
