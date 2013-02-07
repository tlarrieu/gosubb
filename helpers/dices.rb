module Helpers
module Dices
	def roll type=:classic, dest_pos=nil
		Sample["dice.ogg"].play 0.2
		score = rand(1..6)
		case type
		when :block
			case score
				when 1
					return :attacker_down
				when 2
					return :both_down
				when 5
					return :defender_stumble
				when 6
					return :defender_down
				else return :pushed
			end

		when :pass, :move, :catch, :pickup
			if score == 6
				return :success
			elsif score == 1
				return :fumble
			else
				score += modifs
				if score >= evaluate(type, dest_pos)
					return :success
				else
					return :fail
				end
			end

		when :injury
			score2 = rand(1..6)
			sum = score + score2
			case sum
			when 2..7
				return Health::STUN_2
			when 8..9
				return Health::KO
			else
				return Health::DEAD
			end

		when :classic
			return score
		end
	end
end
end
