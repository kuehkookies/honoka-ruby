# ==================================================================================
# Class Chaser
#     part of Actor
# 
# A sample actor which can only run and jump. The heart of every platformer.
# Use this as base of every Actors you'd like to create.
# ==================================================================================

class Chaser < Enemy
	trait :bounding_box, :scale => [0.4, 0.8], :debug => false

	def setup
		super
	end

	def record_pos
		return if self.destroyed?
		x = ((@x+8) / 16).round
		y = (@y / 16).round
		save_pos [x, y]
	end

	def create_character_frame
		@character = Chingu::Animation.new( :file => "enemies/pcandi.png", :size => [40,32])
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
		@hp = 3
		@damage = 0
		@speed = 2

		@debug = false

		# @color = Color.new(0xff00bbff)

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
			@action = :stand
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

	def hit(weapon, x, y, side)
		@status = :hurt
		@action = :stand
		unless die?
			y -= 16 if weapon.is_a? Torch_Fire
			Spark.create(:x => x, :y => y, :angle => rand(30)*side)
			Sound["sfx/hit.wav"].play(0.5) if !@hardened
			Sound["sfx/klang.wav"].play(0.3) if @hardened
			@hp -= weapon.damage
			knockback
			after(4){die}
		end
	end

	def knockback
		return if @invincible
		@invincible = true
		@status = :hurt
		@action = :stand
		self.velocity_x = (self.factor_x*-1)
		land?
	end

	def die
		if @hp <= 0
			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
			@x += 0
			@y += 0
			@color.alpha = 128
			after(5){
				@status = :dead
				@image = character_frame(:die, :first)
				@color.alpha = 255 
			}
		else
			@invincible = true
			empty_command
			@velocity_x = 0
			@velocity_y = 0
			@image = character_frame(:crouch, :first)
			after(300){
				stand_still
				@knocked = false
				after(Orange::INVULNERABLE_DURATION) { 
					@invincible = false; 
				}
			}
		end
	end

	def attack
		@action = :attack
		between(0,6){
			unless die?
				@image = character_frame(:shoot, 0)
			end
		}.then{
			unless die?
				@image = character_frame(:shoot, 1)
			end
		}
		between(9,30){
			unless die?
				@image = character_frame(:shoot, 2)
			end
		}.then{
			unless die?
				@image = character_frame(:shoot, 3)
			end
		}
		after(60){ stand_still }
	end

	def update
		super
		land?
		adjust_speed unless @pos.empty? or @knocked or dead
		unless @knocked or dead or near_of @player
			# if in_position @target_pos
			# 	push_command([:stop]) 
			# 	pull_command
			# elsif in_sight @player and !near_of @player and
			# 	push_command([:get_waypoint, @player])
			# 	push_command([:move_to_target, @target_pos])
			# 	move_to @target_pos
			# elsif in_sight @target_pos and !near_of @target_pos
			# 	push_command([:move_to_target, @target_pos])
			# 	move_to @target_pos
			# elsif near_of @player
			# 	push_command([:attack])
			# 	pull_command
			# end
			if in_position @target_pos
				push_command([:stop]) 
				pull_command
				push_command([:get_waypoint, @player]) unless near_of @player
			elsif near_of @target_pos
				push_command([:stop]) 
				pull_command
				push_command([:get_waypoint, @player]) if near_of @target_pos
			else
				if in_sight @player
					push_command([:get_waypoint, @player])
					push_command([:move_to_target, @target_pos])
				end
				move_to @target_pos
			end
			@image = character_frame(:walk, :first) if @velocity_y > Orange::Environment::GRAV_WHEN_LAND
			@image = character_frame(:crouch, :first) if @velocity_y > Orange::Environment::GRAV_WHEN_LAND and disabled
		end
		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle
			@status = :fall unless disabled
			@image = character_frame(13) if @velocity_y <= 3
			@image = character_frame(:jump, :last) if @velocity_y > 3
		end
		if dead
			@image = character_frame(:die, :first)
			@velocity_x = 0
			@velocity_y = Orange::Environment::GRAV_WHEN_LAND
		end
	end
end
