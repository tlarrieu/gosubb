module Helpers
module Barrier
	def lock
		@barrier = 0 unless @barrier
		@barrier += 1
	end

	def unlock
		@barrier = 0 unless @barrier
		@barrier -= 1 if @barrier > 0
	end

	def unlocked? &block
		block.call if @barrier == 0 or @barrier.nil?
	end
end
end