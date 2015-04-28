# ==================================================================================
# Class Chaser
#     part of Actor
# 
# A sample actor which can only run and jump. The heart of every platformer.
# Use this as base of every Actors you'd like to create.
# ==================================================================================

class Chaser < Enemy
	trait :bounding_box, :scale => [0.3, 0.8], :debug => false

	def setup
		super
		after(180){
			la = parent.gridmap.find_path_astar @pos, @player.pos
		}
		every(60){
			record_pos
			check_position(@player, true)
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
		@speed = 1
	end

	def move(x,y)
		if x != 0 and not (jumping or on_wall)
			@image = character_frame(:walk, :next)
		end
		
		self.factor_x = self.factor_x.abs   if x > 0
		self.factor_x = -self.factor_x.abs  if x < 0
	
		@x += x if !@vert_jump and not falling
		@x = previous_x  if at_edge? and not in_event
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
		destroy if self.parent.viewport.outside_game_area?(self)
		# unless self.velocity_y > Orange::Environment::GRAV_WHEN_LAND or @invincible or die?
		# 	@image = character_frame(:walk, :next)
		# 	@x += @speed*@factor_x
		# end
		# @image = character_frame(:walk, :first) if @velocity_y > Orange::Environment::GRAV_WHEN_LAND
	end
end
