module Helpers
module Images
	def dice_image symb
		valid_symbols = [
							:attacker_down,
							:both_down,
							:pushed,
							:defender_stumble,
							:defender_down
						]

		raise "Invalid argument '#{symb}' for method dice_image" unless valid_symbols.include? symb
		"dices/#{symb}.gif"
	end
end
end
