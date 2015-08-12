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
		@character[:walk].delay = 120
	end

	def enemy_parameters
		@invincible = false
		@harmful = false
		@hardened = false
		@hp = 12
		@damage = 0
		@speed = 2

		@debug = false

		@target_pos = nil

		@color = Color.new(0xff00bbff)

		@acceleration_y = Orange::Environment::GRAV_ACC
		self.max_velocity = Orange::Environment::GRAV_CAP
		self.rotation_center = :bottom_center
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

	# ==============================================================================
	# Pathfinding stuffs
	# These methods are used for pathfinding, meaning the automated 
	# movements are predefined and executed on the go.
	# Utilizes pathfind module, using A* as macro-level planner
	# ==============================================================================

	def find_position(target)
		unless die?
			path = parent.gridmap.find_path_astar @pos, target.pos
			@target_pos = get_nearest_waypoint path
			check_position(@target_pos, true)
			@status = :move
		end
	end

	def get_nearest_waypoint(path)
		return if path.nil?
		return if path.empty?
		path.pop
		result = [0,0]
		path.each_with_index do |point, id|
			next if point.nil?
			next if point.empty?
			result = point if result[0] < point[0] and result[1] < point[1]
		end
		return result
	end
	
	def check_position(pos, flip = false)
		return if self.destroyed?
		x = pos[0] > @pos[0]
		y = pos[1] > @pos[1]
		@factor_x = x ? $window.factor : -$window.factor if flip
	end

	def in_position(target)
		if target.is_a?(Actor)
			@pos[0] == target.pos[0] and @pos[1] == target.pos[1]
		else
			@pos[0] == @target_pos[0] and @pos[1] == target_pos[1]
		end
	end

	def move_to(pos)
		@image = character_frame(:walk, :next)
		jump if need_jump
	end

	def need_jump
		need = false 
		if in_map and not @jumping
			need = true if jump_is_necessary and @velocity_x.abs > 0.5
		end
		return need
	end

	def in_map
		!parent.gridmap.tiles[[@pos[0],@pos[1]]].nil?
	end
	def jump_is_necessary
		in_front_of_impassable and at_jump_point and
		(is_above @target_pos or is_in_same_level_with @target_pos)
	end
	def at_jump_point
		if x == previous_x
			for i in @pos[0]-1...@pos[0]+1
				next if i >= @pos[0] and in_left_of @target_pos
				next if i <= @pos[0] and in_right_of @target_pos
				return true if parent.gridmap.tiles[[i,@pos[1]-1]] != 0
			end
		else
			(parent.gridmap.tiles[[@pos[0],@pos[1]]] == 2 and in_left_of @target_pos) or
			(parent.gridmap.tiles[[@pos[0],@pos[1]]] == 3 and in_right_of @target_pos) or
			parent.gridmap.tiles[[@pos[0],@pos[1]]] == 4
		end
	end
	def in_front_of_impassable
		return false if parent.gridmap.tiles[[@pos[0]-1,@pos[1]]].nil?
		return false if parent.gridmap.tiles[[@pos[0]-2,@pos[1]]].nil?
		return false if parent.gridmap.tiles[[@pos[0]+1,@pos[1]]].nil?
		return false if parent.gridmap.tiles[[@pos[0]+2,@pos[1]]].nil?
		need = false
		for i in @pos[0]-2...@pos[0]+2
			for j in @pos[1]-2...@pos[1]+2
				next if i > @pos[0] and in_left_of @target_pos
				next if i < @pos[0] and in_right_of @target_pos
				need = true if parent.gridmap.tiles[[i,j]] == 0
				break if need
			end
		end
		return need
	end

	def in_left_of(pos)
		return if pos.nil?
		return if pos.empty?
		pos[0] < @pos[0]
	end
	def in_right_of(pos)
		return if pos.nil?
		return if pos.empty?
		pos[0] > @pos[0]
	end
	def is_in_same_level_with(pos)
		return if pos.nil?
		return if pos.empty?
		pos[1] == @pos[1]
	end
	def is_above(pos)
		return if pos.nil?
		return if pos.empty?
		pos[1] < @pos[1]
	end
	def is_below(pos)
		return if pos.nil?
		return if pos.empty?
		pos[1] > @pos[1]
	end

	def adjust_speed
		if in_position @player
			@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
			if @velocity_x.abs < 0.2 #fix
				@velocity_x = 0
				@image = character_frame(:stand, :first)
				@status = :stand
			end
		else
			@velocity_x -= 0.1 if in_left_of @target_pos
			@velocity_x += 0.1 if in_right_of @target_pos
			@velocity_x = @speed if @velocity_x > @speed; @velocity_x = -@speed if @velocity_x < -@speed
		end
	end

	def update
		super
		land?
		adjust_speed unless @pos.empty?
		if !@pos.empty? and (@target_pos.nil? or !in_position @player)
			find_position @player
			if moving
				unless @invincible or die?
					move_to @target_pos
				end
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
