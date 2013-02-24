require "combat_state"
require "main_menu_state"

require "measures"
require "barrier"
require "pitch"
require "ball"
require "player"
require "hud"
require "races"

class PlayState < GameState
	include Helpers::Measures
	include Helpers::Barrier
	include Helpers::Dices

	attr_reader :teams

	def initialize options = {}
		@pitch = options.delete(:pitch) || Pitch.create
		super
		@sound       = Sample["turnover.ogg"]

		self.input   = {
			:mouse_right => :action,
			:mouse_left => :select,
			:space => lambda{ @pitch.turnover! },
			:escape => :show_menu
		}

		add_game_object @pitch.ball
		add_game_object @pitch
		@pitch.each do |p|
			add_game_object p
			p.set_stage :play
		end
		@pitch.on_unlock { show_movement }
		@pitch.ball.on_square_entered { |x, y| @pitch[[x, y]].catch! if @pitch[[x, y]]}

		@action_coords = nil
		@selected      = nil
		@last_selected = nil

		@hud = HUD.create :teams => @pitch.teams, :pitch => @pitch
	end


	def setup
		# Here we force refresh of the movemement allowance
		# we do that to fix a glitch occuring when leaving dice menu state
		show_movement
	end

	def finalize
		$window.change_cursor :normal
	end

	def show_menu
		push_game_state MainMenuState.new
	end

	def debug
		push_game_state GameStates::Debug.new
	end

	def new_turn!
		@selected.unselect if @selected
		@selected = nil
		@hud.stick nil
		@hud.clear

		Square.destroy_all

		@pitch.new_turn!
	end

	def unlock
		super
		show_movement
	end

	def update
		super

		# Turnover
		if @pitch.turnover?
			@pitch.unlocked? do
				new_turn!
				Sample["turnover.ogg"].play 0.3
				@text = FloatingText.create(
					"Turnover !",
					:x => $window.width / 2.0,
					:y => $window.height - 100,
					:timer => 3000,
					:color => 0xFFFF0000,
					:size => 40
				)
			end
		end

		update_cursor
	end

	def update_cursor
		cursor_pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		return if cursor_pos == @cursor_pos # Nothing to do if we did not move the cursor far enough to have to update it
		@cursor_pos = cursor_pos
		if @pitch[@cursor_pos]
			overred =  @pitch[@cursor_pos]
			@hud.show overred # Update HUD
			if @selected and @selected.team.active?
				unless overred.team.active?
					if @selected.could_block? overred
						$window.change_cursor @selected.nb_block_dices(overred)
					else
						$window.change_cursor :red
					end
				else
					if @selected == overred
						if @selected.can_blitz?
							$window.change_cursor :blitz
						elsif @selected.health == Health::STUN_0
							$window.change_cursor :standup
						else
							$window.change_cursor :normal
						end
					elsif @selected.can_handoff_to? overred
						$window.change_cursor :handoff
					elsif @selected.can_pass_to? overred
						$window.change_cursor :ball, @selected.evaluate(:pass, @cursor_pos)
					else
						$window.change_cursor :normal
					end
				end
			else
				if overred.team.active?
					$window.change_cursor :select
				else
					$window.change_cursor :red
				end
			end
		else
			@hud.clear # Update HUD
			if @pitch.ball.pos == @cursor_pos and @selected and @selected.team.active?
				$window.change_cursor :take
			else
				unless @selected and @selected.can_move?and @selected.team.active?
					$window.change_cursor :normal
				else
					$window.change_cursor :move, @selected.evaluate(:move, @cursor_pos)
				end
			end
		end
	end

	def select
		pos = to_pitch_coords [$window.mouse_x, $window.mouse_y]
		if @selected
			@selected.unselect
			@last_selected = @selected
		end
		@selected      = @pitch[pos]
		@selected.select if @selected
		@action_coords = nil
		show_movement
		@hud.stick @selected
		@cursor_pos = nil # Force cursor refresh
	end

	def action
		@pitch.unlocked? do
			x, y = to_pitch_coords [$window.mouse_x, $window.mouse_y]
			unless @selected.nil?
				unless @action_coords == [x,y]
					show_path x, y if @selected.can_move_to? x, y
					@action_coords = [x, y]
				else
					if @selected.move_to! x, y or
						@selected.handoff @pitch[[x,y]] or
						@selected.pass @pitch[[x,y]] or
						@selected.block @pitch[[x,y]] or
						(@action_coords == @selected.pos and (@selected.stand_up! or @selected. blitz!))

						Square.destroy_all
						@last_selected.cant_move! if @last_selected and @last_selected.has_moved? unless @last_selected == @selected
					end

					@action_coords = nil
					@cursor_pos = nil # force cursor refresh
					show_movement
				end
			end
		end
	end

	private

	def show_movement
		Square.destroy_all
		unless @selected.nil? or @selected.moving?
			if @selected.team.active?
				if @selected.can_move?
					w, color = @selected.cur_ma, :green
				else
					w, color = 0, :green
				end
			else
				if @selected.health == Health::OK
					w, color = 1, :gray
				else
					w, color = 0, :gray
				end
			end

			p_rect = Rect.new 1, 1, Pitch::WIDTH - 2, Pitch::HEIGHT - 2
			(-w..w).each do |i|
				(-w..w).each do |j|
					x, y   = [@selected.pos, [i,j]].transpose.map { |c| c.reduce(:+)}
					c_rect = Rect.new x, y, 1, 1
					if @pitch[[x,y]].nil? and p_rect.collide_rect? c_rect
						x, y = to_screen_coords [x,y]
						Square.create( :x => x, :y => y, :color => color, :alpha => 180 )
					end
				end
			end
		end
	end

	def show_path x, y
		Square.destroy_all
		path = a_star @pitch, @selected.pos, [x,y]
		if path.length <= @selected.cur_ma
			path.each do |p|
				i, j = to_screen_coords p
				Square.create :x => i, :y => j, :type => :square, :color => :green
			end
			@action_coords = [x,y]
		end
	end
end
