require "menus/dice_menu"
require "menus/game_menu"
include Menus

require "pitch/floating_text"
require "pitch/ball"
require "pitch/team"
require "pitch/hud"

require "helpers/measures"

class Pitch < GameState
	include Helpers::Measures

	attr_accessor :active_team, :teams
	attr_reader   :selected

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

		self.input   = { :mouse_right => :action, :mouse_left => :select, :space => :turnover!, :escape => :show_menu, :e => :edit }

		x, y  = to_screen_coords [12, 8]
		@ball = Ball.create :pitch => self
		@ball.set_pos! x, y, false

		@action_coords = nil
		@barrier       = 0

		@players       = []
		@selected      = nil
		@last_selected = nil
		@ma_squares    = []

		@teams = []
		@teams << Team.new( :name => "TROLOLOL", :active => true )
		@teams << Team.new( :name => "OTAILLO" )

		@teams[@active_team].new_turn!

		@hud = HUD.create :teams => @teams

		randomize
	end

	def finalize
		$window.change_cursor :normal
	end

	def show_menu
		push_game_state GameMenu.new
	end

	# FIXME : this is buggy for now as we dont really care yet about chingu's convention
	def edit
		# state = GameStates::Edit.new(:except => [FloatingText, Ball, Player])
		# push_game_state state, :setup => false
	end

	def lock
		@barrier += 1
	end

	def unlock
		@barrier -= 1 if @barrier >= 1
	end

	def new_turn!
		@selected.unselect if @selected
		@selected = nil
		@hud.stick @selected
		@hud.clear
		@turnover = false
		@ma_squares.each { |s| s.destroy! }
		@ma_squares.clear
		@teams[@active_team].active = false
		@active_team = (@active_team + 1) % 2
		@teams[@active_team].new_turn!
	end


	def turnover!
		@turnover = true

	end

	def turnover?
		@turnover
	end

	def [] pos
		@teams.each { |t| return t[pos] if t[pos]}
		nil
	end

	def draw
		super
		@background.draw 0,0,0
		@ma_squares.each { |s| s.draw }
		@hud.draw
	end

	def update
		super
		# Movement allowance
		show_movement if @action_coords.nil? and not @ma_squares.nil? and @ma_squares.empty?

		# Players update
		@teams[@active_team].update

		# HUD update
		found = false
		@teams.each do |t|
			t.each do |p|
				if p.collision_at? $window.mouse_x, $window.mouse_y
					@hud.show p
					found = true
				end
			end
		end
		@hud.clear unless found

		# Cursor selection
		# cursor_pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		# if @selected and @selected.team == @active_team
		# 	if @selected == self[cursor_pos]
		# 		$window.change_cursor :blitz
		# 	elsif self[cursor_pos]
		# 		if self[cursor_pos].team == @selected.team
		# 			if @selected.has_ball?
		# 				if @selected.close_to? self[cursor_pos]
		# 					$window.change_cursor :handoff
		# 				elsif @selected.can_pass_to? self[cursor_pos]
		# 					$window.change_cursor :throw
		# 				end
		# 			else
		# 				$window.change_cursor :normal
		# 			end
		# 		else
		# 			diff = (@selected[:str] - self[cursor_pos][:str]).abs
		# 			if @selected[:str] > self[cursor_pos][:str]
		# 				if diff >= 2 * self[cursor_pos][:str]
		# 					$window.change_cursor :d_3
		# 				else
		# 					$window.change_cursor :d_2
		# 				end
		# 			elsif @selected[:str] < self[cursor_pos][:str]
		# 				if diff >= 3 * @selected[:str]
		# 					$window.change_cursor :d_3_red
		# 				elsif diff >= 2 * @selected[:str]
		# 					$window.change_cursor :d_2_red
		# 				else
		# 					$window.change_cursor :d_1_red
		# 				end
		# 			else
		# 				$window.change_cursor :d_1
		# 			end
		# 		end
		# 	elsif @ball.pos == cursor_pos
		# 		$window.change_cursor :take
		# 	elsif @selected.can_move_to? cursor_pos[0], cursor_pos[1]
		# 		$window.change_cursor :move
		# 	else
		# 		$window.change_cursor :normal
		# 	end
		# else
		# 	$window.change_cursor :normal
		# end

		# Turnover
		if turnover? and @barrier == 0
			new_turn!
			@text = FloatingText.create "Turnover !",
			                            :x => @background.width / 2.0,
			                            :y => $window.height - 100,
			                            :timer => 3000,
			                            :color => 0xFFFF0000,
			                            :size => 40
		end
	end

	def select
		pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		@last_selected = @selected if @selected
		@selected      = self[pos]
		@action_coords = nil
		show_movement
		@hud.stick @selected
	end

	def action
		if @barrier == 0
			x, y = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			unless @selected.nil?
				unless @action_coords == [x,y]
					if @selected.can_move_to? x, y
						show_path x, y
					elsif @selected.can_pass_to? self[[x,y]] or @selected.can_block? self[[x,y]]
						@action_coords = [x,y]
					end
				else
					if @selected.move_to! x, y or @selected.pass self[[x,y]] or @selected.block self[[x,y]]
						@ma_squares.each { |s| s.destroy! }
						@ma_squares.clear
						@last_selected.cant_move! if @last_selected and @last_selected.has_moved? unless @last_selected == @selected
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
				if @selected.can_move?
					w, color = @selected.cur_ma, :green
				else
					w, color = 0, :green
				end
			else
				w, color = 1, :red
			end

			p_rect = Rect.new 1, 1, Pitch::WIDTH - 2, Pitch::HEIGHT - 2
			(-w..w).each do |i|
				(-w..w).each do |j|
					x, y   = [@selected.pos, [i,j]].transpose.map { |c| c.reduce(:+)}
					c_rect = Rect.new x, y, 1, 1
					if self[[x,y]].nil? and p_rect.collide_rect? c_rect
						x, y = to_screen_coords [x,y]
						@ma_squares << Square.create( :x => x, :y => y, :type => :ma, :color => color, :alpha => 180 )
					end
				end
			end
		end
	end

	def show_path x, y
		@ma_squares.each { |s| s.destroy! }
		@ma_squares.clear
		path = a_star self, @selected.pos, [x,y]
		if path.length <= @selected.cur_ma
			path.each do |p|
				i, j = to_screen_coords p
				@ma_squares << Square.create( :x => i, :y => j, :type => :ma, :color => :green )
			end
			@action_coords = [x,y]
		end
	end

	def randomize
		roles = { :human => ["lineman", "blitzer", "catcher", "thrower"], :orc => ["lineman", "blitzer", "thrower"] }
		races = [:human, :orc]

		class << Array
			def sample
				return self[rand(count)]
			end
		end

		race = races.sample
		1.upto(11) do
			role = roles[race].sample
			loop do
				x   = rand(Pitch::WIDTH / 2)
				y   = rand(Pitch::HEIGHT)
				pos = [x, y]
				if self[pos].nil?
					has_ball = @ball.pos == [x,y]
					@teams[0] << Player.create(
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
					@teams[1] << Player.create(
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
