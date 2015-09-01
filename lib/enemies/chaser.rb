# ==================================================================================
# Class Chaser
#     part of Actor
# 
# A sample actor which can only run and jump. The heart of every platformer.
# Use this as base of every Actors you'd like to create.
# ==================================================================================

class Chaser < Enemy
	trait :bounding_box, :scale => [0.5, 0.8], :debug => false

	def setup
		super
		every(15){ 
			if @moving and is_current_command? :move_to_target 
				@target_pos = nil
				record_position @player
				check_position @target_pos, true
			end
		}
	end

	def create_character_frame
		@character = Chingu::Animation.new( :file => "player/mark.gif", :size => [32,32])
		@character.frame_names = {
			:stand => 0..2,
			:step => 3..3,
			:walk => 4..11,
			:jump => 12..14,
			:hurt => 15..17,
			:die => 17..17,
			:crouch => 18..19,
			:stead => 20..20,
			:shoot => 20..23, # 21..23,
			:crouch_shoot => 24..27,
			:raise => 28..30,
			:wall_jump => 31..31
		}
		@character[:stand].delay = 50
		@character[:stand].bounce = true
		@character[:walk].delay = 60
	end

	def enemy_parameters
		@invincible = false
		@harmful = false
		@hardened = false
		@hp = 12
		@damage = 0
		@speed = 2

		@debug = false

		@color = Color.new(0xff00bbff)

		@acceleration_y = Orange::Environment::GRAV_ACC
		self.max_velocity = Orange::Environment::GRAV_CAP
		self.rotation_center = :bottom_center
	end

	def stand_still
		@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
		if @velocity_x.abs <= 0.2
			@velocity_x = 0
			@image = character_frame(:stand, :first)
			@status = :stand
		end
	end

	def move(x,y)
		if x != 0 and not jumping
			@image = character_frame(:walk, :next)
		end
		@x += @velocity_x 
		@x = previous_x  if at_edge? and not in_event
		self.each_collision(*$window.terrains) do |me, stone_wall|
			@x = previous_x
			break
		end
		@y += y
	end

	def die
		# pause!
		if @hp <= 0
			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
			@x += 0
			@y += 0
			@color.alpha = 128
			after(5){destroy}
		else
			@invincible = true
			after(Orange::INVULNERABLE_DURATION) { @invincible = false; } # unpause! }
		end
	end

	def update
		super
		land?
		adjust_speed unless @pos.empty?
		push_command([:check_position, @player]) if in_sight @player and @target_pos.nil? and !is_current_command? :idle
		unless @target_pos.nil?
			if is_current_command? :move_to_target and in_position @target_pos
				push_command([:stop]) 
				pull_command
			else
				push_command([:move_to_target, @player])
				move_to @target_pos if @moving
			end
		end
		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle
			@status = :fall unless disabled
			@image = character_frame(13) if @velocity_y <= 3
			@image = character_frame(:jump, :last) if @velocity_y > 3
		end
		@image = character_frame(:walk, :first) if @velocity_y > Orange::Environment::GRAV_WHEN_LAND
	end
end
