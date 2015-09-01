# # ==================================================================================
# # Class Chaser
# #     part of Actor
# # 
# # A sample actor which can only run and jump. The heart of every platformer.
# # Use this as base of every Actors you'd like to create.
# # ==================================================================================

# class Chaser < Enemy
# 	trait :bounding_box, :scale => [0.5, 0.8], :debug => false

# 	def setup
# 		super
# 	end

# 	def create_character_frame
# 		@character = Chingu::Animation.new( :file => "player/mark.gif", :size => [32,32])
# 		@character.frame_names = {
# 			:stand => 0..2,
# 			:step => 3..3,
# 			:walk => 4..11,
# 			:jump => 12..14,
# 			:hurt => 15..17,
# 			:die => 17..17,
# 			:crouch => 18..19,
# 			:stead => 20..20,
# 			:shoot => 20..23, # 21..23,
# 			:crouch_shoot => 24..27,
# 			:raise => 28..30,
# 			:wall_jump => 31..31
# 		}
# 		@character[:stand].delay = 50
# 		@character[:stand].bounce = true
# 		@character[:walk].delay = 120
# 	end

# 	def enemy_parameters
# 		@invincible = false
# 		@harmful = false
# 		@hardened = false
# 		@hp = 12
# 		@damage = 0
# 		@speed = 2

# 		@debug = false

# 		@target_pos = nil

# 		@color = Color.new(0xff00bbff)

# 		@acceleration_y = Orange::Environment::GRAV_ACC
# 		self.max_velocity = Orange::Environment::GRAV_CAP
# 		self.rotation_center = :bottom_center
# 	end

# 	def stand_still
# 		@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
# 		if @velocity_x.abs <= 0.2
# 			@velocity_x = 0
# 			@image = character_frame(:stand, :first)
# 			@status = :stand
# 		end
# 	end

# 	def move(x,y)
# 		if x != 0 and not jumping
# 			@image = character_frame(:walk, :next)
# 		end
# 		@x += @velocity_x 
# 		@x = previous_x  if at_edge? and not in_event
# 		self.each_collision(*$window.terrains) do |me, stone_wall|
# 			@x = previous_x
# 			break
# 		end
# 		@y += y
# 	end

# 	def die
# 		# pause!
# 		if @hp <= 0
# 			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
# 			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
# 			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
# 			@x += 0
# 			@y += 0
# 			@color.alpha = 128
# 			after(5){destroy}
# 		else
# 			@invincible = true
# 			after(Orange::INVULNERABLE_DURATION) { @invincible = false; } # unpause! }
# 		end
# 	end

# 	# ==============================================================================
# 	# Pathfinding stuffs
# 	# These methods are used for pathfinding, meaning the automated 
# 	# movements are predefined and executed on the go.
# 	# Utilizes pathfind module, using A* as macro-level planner
# 	# ==============================================================================

# 	def find_position(target)
# 		return if parent.gridmap.nil?
# 		unless die?
# 			path = parent.gridmap.find_path_astar @pos, target.pos
# 			@target_pos = get_nearest_waypoint path, target if (@target_pos.nil? or @target_pos.empty?) and
# 															   parent.gridmap.on_move_route target
# 			@status = :move
# 		end
# 	end

# 	def get_nearest_waypoint(path, target)
# 		return if path.nil?
# 		return if path.empty?
# 		return target.pos if @pos == target.pos
# 		path.pop
# 		result = path[0]
# 		nearest_x = result[0]
# 		nearest_y = result[1]
# 		# Checking whether target is above
# 		if target.pos[1] != @pos[1]
# 			parent.gridmap.jump_points.each_with_index do |point, id|
# 				next if point.nil?
# 				next if point.empty?
# 				next if (point[1] - @pos[1]).abs > 4
# 			   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
# 			   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
# 				if get_nearest(@pos[0], point[0]) < nearest_x and
# 				   get_nearest(@pos[1], point[1]) < nearest_y
# 					nearest_x = get_nearest(@pos[0], point[0])
# 					nearest_y = get_nearest(@pos[1], point[1])
# 					result = point if waypoint_in_course? point, target.pos
# 				end
# 			end
# 		else
# 			path.each do |point|
# 				next if point.nil?
# 				next if point.empty?
# 			   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
# 			   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
# 				result = point if waypoint_in_course? point, target.pos
# 			end
# 		end
# 		return result
# 	end

# 	def get_alternate_waypoint(target)
# 		return if parent.gridmap.nil?
# 		return if @pos == target.pos
# 		result = target.pos
# 		nearest_x = result[0]
# 		nearest_y = result[1]
# 		# Checking whether target is above
# 		parent.gridmap.jump_points.each_with_index do |point, id|
# 			next if point.nil?
# 			next if point.empty?
# 		   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
# 		   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
# 			if get_nearest(result[0], point[0]) < nearest_x and
# 			   get_nearest(result[1], point[1]) < nearest_y
# 				nearest_x = get_nearest(result[0], point[0])
# 				nearest_y = get_nearest(result[1], point[1])
# 				result = point if waypoint_in_course? point, target.pos
# 			end
# 		end
# 		return result
# 	end

# 	def get_nearest(a, b)
# 		return (a - b).abs
# 	end

# 	def waypoint_in_course?(target, point)
# 		return true if in_left_of target and point[0] < target[0]
# 		return true if in_right_of target and point[0] > target[0]
# 		return false
# 	end
	
# 	def check_position(pos, flip = false)
# 		return if self.destroyed?
# 		return if pos.nil?
# 		return if pos.empty?
# 		# x = # pos[0] > @pos[0]
# 		# y = # pos[1] > @pos[1]
# 		# @factor_x = x ? $window.factor : -$window.factor if flip
# 		@factor_x = -$window.factor if in_left_of pos
# 		@factor_x = $window.factor if in_right_of pos
# 	end

# 	def in_position(target)
# 		return true if target.nil?
# 		return true if target.is_a? Array and target.empty?
# 		if target.is_a?(Actor)
# 			@pos[0] == target.pos[0] and @pos[1] == target.pos[1]
# 		else
# 			@pos[0] == target[0] # and @pos[1] == target[1]
# 			# @pos[0] >= target[0] - 1 and @pos[0] <= target[0] + 1 # and @pos[1] == target[1]
# 		end
# 	end

# 	def move_to(pos)
# 		@image = character_frame(:walk, :next)
# 		jump if need_jump @player
# 	end

# 	def need_jump(target)
# 		need = false 
# 		if in_map and not @jumping
# 			need = true if jump_is_necessary and @velocity_x.abs > 0.8
# 			need = true if target.is_a? Actor and target.jumping and in_position @target_pos
# 		end
# 		return need
# 	end

# 	def in_map
# 		!parent.gridmap.tiles[[@pos[0],@pos[1]]].nil?
# 	end

# 	def in_sight(target)
# 		return false if @pos.nil?
# 		return false if @pos.empty?
# 		return false if target.nil?
# 		(@pos[0] - target.pos[0]).abs <= 8 and (@pos[1] - target.pos[1]).abs <= 4
# 	end

# 	def jump_is_necessary
# 		in_front_of_impassable and at_jump_point
# 	end
	
# 	def at_jump_point
# 		if x == previous_x
# 			for i in @pos[0]-1...@pos[0]+1
# 				next if i >= @pos[0] and in_left_of @target_pos
# 				next if i <= @pos[0] and in_right_of @target_pos
# 				return true if parent.gridmap.tiles[[i,@pos[1]-1]] != 0
# 			end
# 		else
# 			# (parent.gridmap.tiles[[@pos[0],@pos[1]]] == 2 and in_left_of @target_pos) or
# 			# (parent.gridmap.tiles[[@pos[0],@pos[1]]] == 3 and in_right_of @target_pos) or
# 			# parent.gridmap.tiles[[@pos[0],@pos[1]]] == 4
# 			return true if parent.gridmap.jump_points.include? @pos and 
# 						   (@x >= (@pos[0]-1) * 16 and @x <= (@pos[0]+1) * 16) and
# 						   is_above @target_pos
# 		end
# 	end
	
# 	def in_front_of_impassable
# 		return false if parent.gridmap.tiles[[@pos[0]-1,@pos[1]]].nil?
# 		return false if parent.gridmap.tiles[[@pos[0]-2,@pos[1]]].nil?
# 		return false if parent.gridmap.tiles[[@pos[0]+1,@pos[1]]].nil?
# 		return false if parent.gridmap.tiles[[@pos[0]+2,@pos[1]]].nil?
# 		need = false
# 		for i in @pos[0]-2...@pos[0]+2
# 			for j in @pos[1]-2...@pos[1]+2
# 				next if i > @pos[0] and in_left_of @target_pos
# 				next if i < @pos[0] and in_right_of @target_pos
# 				need = true if parent.gridmap.tiles[[i,j]] == 0
# 				break if need
# 			end
# 		end
# 		return need
# 	end

# 	def in_left_of(pos)
# 		return if pos.nil?
# 		return if pos.is_a?(Array) and pos.empty?
# 		pos[0] < @pos[0]
# 	end
# 	def in_right_of(pos)
# 		return if pos.nil?
# 		return if pos.is_a?(Array) and pos.empty?
# 		pos[0] > @pos[0]
# 	end
# 	def is_in_same_level_with(pos)
# 		return if pos.nil?
# 		return if pos.is_a?(Array) and pos.empty?
# 		pos[1] == @pos[1]
# 	end
# 	def is_above(pos)
# 		return if pos.nil?
# 		return if pos.is_a?(Array) and pos.empty?
# 		pos[1] < @pos[1]
# 	end
# 	def is_below(pos)
# 		return if pos.nil?
# 		return if pos.is_a?(Array) and pos.empty?
# 		pos[1] > @pos[1]
# 	end

# 	def adjust_speed
# 		if in_position @player
# 			@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
# 			stand_still if @velocity_x.abs < 0.2 #fix
# 		else
# 			@velocity_x -= 0.1 if in_left_of @target_pos
# 			@velocity_x += 0.1 if in_right_of @target_pos
# 			@velocity_x = @speed if @velocity_x > @speed; @velocity_x = -@speed if @velocity_x < -@speed
# 		end
# 	end

# 	def update
# 		super
# 		land?
# 		adjust_speed unless @pos.empty?
# 		check_position(@target_pos, true) if in_sight @player
# 		find_position @player if (@target_pos.nil? or @target_pos == @pos) and in_sight @player
# 		if in_position @target_pos
# 			pos = get_alternate_waypoint @player
# 			if @pos[1] == @target_pos[1]
# 				@target_pos = nil
# 				stand_still
# 			else
# 				stand_still
# 				@target_pos = pos
# 			end
# 			# p get_alternate_waypoint @player
# 		end
# 		# p "#{@pos[0]} : #{@player.pos[0]}"
# 		unless @target_pos.nil? or in_position @target_pos
# 			move_to @target_pos if moving and !(@invincible or die?)
# 		end
# 		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle
# 			@status = :fall unless disabled
# 			@image = character_frame(13) if @velocity_y <= 3
# 			@image = character_frame(:jump, :last) if @velocity_y > 3
# 		end
# 		@image = character_frame(:walk, :first) if @velocity_y > Orange::Environment::GRAV_WHEN_LAND
# 	end
# end
