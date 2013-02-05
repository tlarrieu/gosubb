class Races
	def self.[] key
		@@list[key]
	end

	@@list = {
		:human => {
			:lineman => { :cost => 50, :stats => {:ma => 6, :str => 3, :agi => 3, :arm => 8}, :skills => []},
			:catcher => { :cost => 70, :stats => {:ma => 8, :str => 2, :agi => 3, :arm => 7}, :skills => [:catch, :dodge]},
			:thrower => { :cost => 70, :stats => {:ma => 6, :str => 3, :agi => 3, :arm => 8}, :skills => [:sure_hands, :pass]},
			:blitzer => { :cost => 90, :stats => {:ma => 7, :str => 3, :agi => 3, :arm => 8}, :skills => [:pass, :block]},
			:ogre    => { :cost => 140, :stats => {:ma => 5, :str => 5, :agi => 2, :arm => 9}, :skills => [:loner, :bone_head, :mighty, :blow, :thick_skull, :throw_teammate]}
		},
		:orc   => {
			:lineman  => { :cost => 50, :stats => {:ma => 5, :str => 3, :agi => 3, :arm => 9}, :skills => []},
			:goblin   => { :cost => 40, :stats => {:ma => 6, :str => 2, :agi => 3, :arm => 7}, :skills => [:right_stuff, :dodge, :stunty]},
			:thrower  => { :cost => 70, :stats => {:ma => 5, :str => 3, :agi => 3, :arm => 8}, :skills => [:sure_hands, :pass]},
			:blackorc => { :cost => 80, :stats => {:ma => 4, :str => 4, :agi => 2, :arm => 9}, :skills => []},
			:blitzer  => { :cost => 80, :stats => {:ma => 6, :str => 3, :agi => 3, :arm => 9}, :skills => [:block]},
			:troll    => { :cost => 110, :stats => {:ma => 4, :str => 5, :agi => 1, :arm => 9}, :skills => []}
		}
	}
end