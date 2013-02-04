require "helpers/dices"

module Helpers
module Cursor
	def update_cursor options={}
		raise ArgumentError unless [:play].include? options[:state]
		case options[:state]
		when :play
			raise ArgumentError unless options[:cursor_pos]
			update_play_cursor options[:cursor_pos]
		end
	end

	def update_play_cursor cursor_pos
		if @pitch[cursor_pos]
			@hud.show @pitch[cursor_pos] # Update HUD
			if @selected and @selected.team.active?
				unless @pitch[cursor_pos].team.active?
					if @selected.can_block? @pitch[cursor_pos]
						attacker = @selected.stats[:str]
						defender = @pitch[cursor_pos].stats[:str]
						highest = [attacker, defender].max
						lowest  = [attacker, defender].min
						if attacker >= defender
							if highest >= 2 * lowest
								$window.change_cursor :d_3
							elsif highest > lowest
								$window.change_cursor :d_2
							else
								$window.change_cursor :d_1
							end
						else
							if highest >= 2 * lowest
								$window.change_cursor :d_3_red
							elsif highest > lowest
								$window.change_cursor :d_2_red
							else
								$window.change_cursor :d_1_red
							end
						end
					else
						$window.change_cursor :red
					end
				else
					if @selected == @pitch[cursor_pos]
						if @selected.can_blitz?
							$window.change_cursor :blitz
						else
							$window.change_cursor :normal
						end
					elsif @selected.can_handoff_to? @pitch[cursor_pos]
						$window.change_cursor :handoff
					elsif @selected.can_pass_to? @pitch[cursor_pos]
						$window.change_cursor :ball
					else
						$window.change_cursor :normal
					end
				end
			else
				if @pitch[cursor_pos].team.active?
					$window.change_cursor :select
				else
					$window.change_cursor :red
				end
			end
		else
			@hud.clear # Update HUD
			if @pitch.ball.pos == cursor_pos and @selected and @selected.team.active?
				$window.change_cursor :take
			else
				unless @selected and @selected.team.active?
					$window.change_cursor :normal
				else
					roll = false
					nb_opponents = 0
					@pitch.active_players_around(@selected.pos).each do |pl|
						unless pl.team == @selected.team
							nb_opponents += 1
						end
					end
					if nb_opponents > 0
						mod  = -nb_opponents
						mod += 1 if @selected.skills.include? :dodge
						res  = min_dice_score_required @selected.stats[:agi], mod
						$window.change_cursor :move, res
					else
						$window.change_cursor :move
					end
				end
			end
		end
	end
end
end