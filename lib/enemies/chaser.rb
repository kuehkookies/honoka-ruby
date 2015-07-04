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
		@character[:walk].delay = 100
	end

	def enemy_parameters
		@invincible = false
		@harmful = false
		@hardened = false
		@hp = 12
		@damage = 0
		@speed = 2

		@color = Color.new(0xff00bbff)

		@acceleration_y = Orange::Environment::GRAV_ACC
		self.max_velocity = Orange::Environment::GRAV_CAP
		self.rotation_center = :bottom_center
	end

	def find_position(target)
		check_position(target, true)
		# parent.gridmap.find_path_astar @pos, target.pos
		@status = :move
	end

	def move(x,y)
		if x != 0 and not jumping
			@image = character_frame(:walk, :next)
		end
		
		self.factor_x = self.factor_x.abs   if x > 0
		self.factor_x = -self.factor_x.abs  if x < 0
	
		unless parent.gridmap.nil? or parent.gridmap.tiles.nil? or parent.gridmap.tiles[@pos].nil?
			if (!parent.gridmap.tiles[[@pos[0]-1,@pos[1]]].nil? and parent.gridmap.tiles[[@pos[0]-1,@pos[1]]] > 1 and x < 0) or 
			   (!parent.gridmap.tiles[[@pos[0]+1,@pos[1]]].nil? and parent.gridmap.tiles[[@pos[0]+1,@pos[1]]] > 1 and x > 0) or 
			   parent.gridmap.tiles[[@pos[0],@pos[1]]] > 1 and 
			   not @jumping
				@velocity_y = -6
				@velocity_x = self.factor_x
				@jumping = true
			end
		end

		@x += x
		@x += x/2 if falling
		@x = previous_x  if at_edge? and not in_event
		@y += y
	end

	def move_to(target)
		if @pos[0] != target.pos[0] # and not jumping
			@image = character_frame(:walk, :next)
		end
	
		move(@speed * self.factor_x , 0)
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
		if moving
			unless @invincible or die?
				move_to @player
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
