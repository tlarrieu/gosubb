module Helpers

module Dices
	def roll type=:classic
		Sample["dice.ogg"].play 0.2
		_rand = 1 + rand(6)
		case type
		when :block

			case _rand
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

		when :injury
			_rand2 = 1 + rand(5)
			sum = _rand + _rand2
			case sum
			when 2..7
				return Health::STUN_2
			when 8..9
				return Health::KO
			else
				return Health::DEAD
			end
		when :classic
			return _rand
		end
	end

	# TODO: ... and around there too
	def roll_agility agi_score, modifs=[]
		score = roll :classic
		res = :success
		if score == 6
			score = :success
		elsif score == 1
			score = :fumble
		else
			modifs.each do |mod|
				score += mod
			end
			if (score >= 7 - agi_score)
				res = :success
			else
				res = :fail
			end
		end

		return res
	end
end

end
