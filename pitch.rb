require 'chingu'
include Chingu
include Gosu

require "player"
require "ball"
require "game_menu"
require "hud"

class Pitch < GameState

	attr_accessor :active_team, :teams

	WIDTH       = 26
	HEIGHT      = 15
	SQUARE_W    = 49.7	
	SQUARE_H    = 48.8
	SPACE_X     = 3
	SPACE_Y     = 3
	MARGIN_LEFT = 8
	MARGIN_TOP  = 5

	def initialize
		super
		@background  = Image["pitch.jpg"]
		@sound       = Sample["turnover.ogg"]
		@active_team = 0

		@fps = FPSText.create "fps", :x => 15, :y => 10
		
		self.input   = { :mouse_right => :action, :mouse_left => :select, :return => :turnover!, :escape => :show_menu, :e => :edit }

		x, y  = Measures.to_screen_coords [12, 8]
		@ball = Ball.create :pitch => self
		@ball.set_pos! x, y, false

		@action_coords = nil
		@barrier       = 0

		@players       = []
		@selected      = nil
		@last_selected = nil
		@ma_squares    = []

		@hud = HUD.new :x => 0, :y => 784

		randomize
	end

	def show_menu
		push_game_state GameMenu.new
	end

	# FIXME : this is buggy for now as we dont really care yet about chingu's convention
	def edit
		state = GameStates::Edit.new(:except => [FloatingText, Ball, Player])
		push_game_state state, :setup => false
	end

	def lock
		@barrier += 1
	end

	def unlock
		@barrier -= 1 if @barrier >= 1
	end

	def new_turn!
		@selected = nil
		@turnover = false
		@ma_squares.each { |s| s.destroy! }
		@ma_squares.clear
		@active_team = (@active_team + 1) % 2
		@players.each { |p| p.new_turn! if p.team == @active_team }
	end


	def turnover!
		unless turnover?
			lock
			new_turn!
			@text = FloatingText.create "Turnover !", :x => @background.width / 2.0, :y => $window.height - 100, :timer => 3000, :color => 0xFFFF0000, :size => 40
			@text.after(2200) { unlock }
		end
	end

	def turnover?
		@turnover
	end

	def [] pos
		@players.each { |p| return p if p.pos == pos}
		nil
	end

	def << player
		@players << player
	end

	def draw
		@background.draw 0,0,0
		@ma_squares.each { |s| s.draw }
		@hud.draw
		super
	end

	def update
		super
		show_movement if @action_coords.nil? and not @ma_squares.nil? and @ma_squares.empty?
		found = false
		@players.each do |p|
			if p.collision_at? $window.mouse_x, $window.mouse_y
				@hud.show p
				found = true
			end
		end
		@hud.clear unless found
	end

	def select
		pos = Measures.to_pitch_coords [$window.mouse_x, $window.mouse_y]
		if @barrier == 0
			@last_selected = @selected unless @selected.nil?
			@selected      = self[pos]
			@action_coords = nil
			show_movement
			@hud.stick @selected
		end
	end

	def action
		if @barrier == 0
			x, y = Measures.to_pitch_coords [$window.mouse_x, $window.mouse_y]
			unless @selected.nil?
				if @action_coords.nil? or @action_coords != [x,y]
					if @selected.can_move_to? x, y
						show_path x, y
					elsif @selected.can_pass_to? self[[x,y]]
						@action_coords = [x,y]
					end
				else
					if @selected.move_to! x, y or @selected.pass self[[x,y]]
						@ma_squares.each { |s| s.destroy! }
						@ma_squares.clear
						@last_selected.cant_move! if @last_selected.has_moved? unless @last_selected.nil?
					end
					@action_coords = nil
				end
			end
		end
	end

	private

	def show_movement
		@ma_squares.each { |s| s.destroy! }
		@ma_squares.clear
		
		
		unless @selected.nil? or not @selected.moving?# or not @selected.can_move?
			if @selected.team == @active_team
				w, color = @selected.cur_ma, :green
			else
				w, color = 1, :red
			end

			p_rect = Rect.new 1, 1, Pitch::WIDTH - 2, Pitch::HEIGHT - 2
			(-w..w).each do |i|
				(-w..w).each do |j|
					x, y   = [@selected.pos, [i,j]].transpose.map { |c| c.reduce(:+)}
					c_rect = Rect.new x, y, 1, 1
					if self[[x,y]].nil? and p_rect.collide_rect? c_rect
						x, y = Measures.to_screen_coords [x,y]
						@ma_squares << Square.create( :x => x, :y => y, :type => :ma, :color => color, :alpha => 180 )
					end
				end
			end
		end
	end

	def show_path x, y
		@ma_squares.each { |s| s.destroy! }
		@ma_squares.clear
		path = Measures.a_star self, @selected.pos, [x,y]
		if path.length <= @selected.cur_ma
			path.each do |p| 
				i, j = Measures.to_screen_coords p
				@ma_squares << Square.create( :x => i, :y => j, :type => :ma, :color => :green ) 
			end
			@action_coords = [x,y]
		end
	end

	def randomize
		roles = { :human => ["lineman", "blitzer", "catcher", "thrower"], :orc => ["lineman", "blitzer", "thrower"] }
		races = [:human, :orc]

		race = races.sample
		1.upto(11) do
			role = roles[race].sample
			loop do
				x   = rand(Pitch::WIDTH / 2)
				y   = rand(Pitch::HEIGHT)
				pos = [x, y]
				if self[pos].nil?
					has_ball = @ball.pos == [x,y]
					self << Player.create( 
					                      :team => 0, 
					                      :x => x, 
					                      :y => y, 
					                      :has_ball => has_ball, 
					                      :pitch => self, 
					                      :ball => @ball, 
					                      :race => race, 
					                      :role => role 
					                      )
					break
				end
			end
		end

		race = races.sample
		1.upto(11) do
			role = roles[race].sample
			loop do
				x   = rand(Pitch::WIDTH / 2) + Pitch::WIDTH / 2
				y   = rand(Pitch::HEIGHT)
				pos = [x, y]
				if self[pos].nil?
					has_ball = @ball.pos == [x,y]
					self << Player.create( 
					                      :team => 1, 
					                      :x => x, 
					                      :y => y, 
					                      :has_ball => has_ball, 
					                      :pitch => self, 
					                      :ball => @ball, 
					                      :race => race, 
					                      :role => role 
					                      )
					break
				end
			end
		end
	end
end
