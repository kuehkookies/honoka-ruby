# ==================================================================================
# Class Enemies
#     Part of GameObject
# 
# Here defined the base logics for enemies, also some other functions like hazardous
# flag and invincibility flag.
#
# To create and define enemies, make it in /enemies folder. Leave this file as 
# mother of all /enemies files.
# ==================================================================================

class Enemy < GameObject
	attr_reader :invincible, :hp, :damage, :harmful, :pathfinder, :pos
	attr_accessor	:y_flag, :status, :action, :moving, :character
	traits :collision_detection, :effect, :velocity, :timer
	
	def self.descendants
		ObjectSpace.each_object(Class).select { |klass| klass < self }
	end
	
	def setup
		create_character_frame
		@blank = TexPlay.create_image($window, 1, 1)
		@image = character_frame(:stand, :first)
		
		enemy_parameters
		enemy_properties

		cache_bounding_box

	
		every(Orange::Environment::POS_RECORD_INTERVAL){
			record_pos
		}
	end

	def record_pos
		return if self.destroyed?
		x = ((@x+8) / 16).floor
		y = (@y / 16).floor
		save_pos [x, y]
	end

	def save_pos(array)
		@pos = array
	end

	def gridmap
		parent.gridmap
	end

	def enemy_parameters
		@invincible = false
		@harmful = true
		@hardened = false
		@hp = 0
		@damage = 0
		@speed = 1
	end

	def enemy_properties
		@player = parent.player
		@status = :stand; @action = :stand
		@invincible = false
		@jumping = false
		@vert_jump = false
		@moving = false
		self.zorder = 200
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		@last_x, @last_y = @x, @y
		@y_flag = @y
		
		@pos = []
		@target_pos = nil

		@command = []
		@current_command = nil

	 	$window.enemies << self
	end

	def create_character_frame; end
	def character_frame(symbol, number = nil)
		chara = @character.nil? ? @blank : @character[symbol]
		unless @character.nil?
			case number
			when :first
				return chara.first
			when :next
				return chara.next
			when :last
				return chara.last
			when :reset
				return chara.reset
			when nil
				return chara
			else
				return chara[number]
			end
		end
		return chara
	end

	# ==============================================================================
	# Basic behaviors
	# Complete set of the enemy's behaviors for some occassions
	# ==============================================================================
	
	def standing;     @status == :stand;    end
	def moving;       @status == :move and @moving == true;  end
	def jumping;      @status == :jump;     end
	def falling;      @status == :fall;     end
	def damaged;      @status == :hurt;     end
	def attacking;    @action == :attack;   end
	def idle;         @action == :stand;    end
	def die?;         @hp <= 0;             end
	def crouching_on_bridge
		@status == :crouch_on_bridge
	end
	def disabled
		@status == :hurt or @status == :die
	end

	def knocked_back; @status == :hurt and moved?; end
	def destroyed?; return true if self.nil? ; end
	def harmful?; return @harmful; end
	def in_event; $window.in_event; end
	
	def hit(weapon, x, y, side)
		@status = :hurt
		@action = :stand
		unless die?
			y -= 16 if weapon.is_a? Torch_Fire
			Spark.create(:x => x, :y => y, :angle => rand(30)*side)
			Sound["sfx/hit.wav"].play(0.5) if !@hardened
			Sound["sfx/klang.wav"].play(0.3) if @hardened
			@hp -= weapon.damage
			die
		end
	end
	
	def die
		@hp == 0
		Misc_Flame.create(:x => self.x, :y => self.y)
		destroy
		$window.enemies.delete(self) rescue nil
	end

	def jump
		return if self.velocity_y > Orange::Environment::GRAV_WHEN_LAND # 1
		return if jumping 
		return if damaged or die? 
		return unless idle 
		@status = :jump
		@jumping = true
		Sound["sfx/jump.wav"].play
		@velocity_y = -4.5
		during(9){
			@velocity_y = -4.5  unless @velocity_y <=  -Orange::Environment::GRAV_CAP || !@jumping
		}
	end

	def crouch
		unless jumping or disabled or attacking or die? or disabled
	  		@image = character_frame(:crouch, :first)
	  	end
	end
	
	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			if me.y >= stone_wall.bb.bottom and self.velocity_y < 0 # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
				@jumping = false
			else  # Land on ground
				land
				me.velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
				me.y = stone_wall.bb.top - 1
			end
		end
		self.each_collision(*$window.bridges) do |me, bridge|
			if me.y <= bridge.y+2 && me.velocity_y > 0
				land
				me.velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
				me.y = bridge.bb.top - 1
			end
		end
	end

	def land
		delay = 18
		delay = 24 if attacking
		if (@y - @y_flag > 48 or (@y - @y_flag > 32 && jumping ) ) && !die?
			Sound["sfx/step.wav"].play
			between(1,delay) { 
				@velocity_x = 0
				@status = :crouch; crouch
			}.then { 
				@status = :stand unless die?
			}
		else
			if jumping or falling
				@image = character_frame(:stand, :first)
				@status = :stand 
			elsif @velocity_y >= Orange::Environment::GRAV_WHEN_LAND + 1
				@image = character_frame(:stand, :first)
				@velocity_y = Orange::Environment::GRAV_WHEN_LAND
			end
		end
		@jumping = false if @jumping
		@vert_jump = false if !@jumping
		@y_flag = @y
	end
	
	def check_collision
		self.each_collision(Sword, *$window.subweapons) do |enemy, weapon|
			if collision_at?(enemy.x, enemy.y)
				unless enemy.invincible
					if !weapon.is_a?(Sword)
						enemy.hit(weapon, weapon.x, weapon.y, weapon.factor_x*30)
					else
						enemy.hit(weapon, weapon.x - (weapon.x - enemy.x) - (weapon.factor_x*(enemy.width/4)), weapon.y - (weapon.y - enemy.y) - (enemy.height*3/5), weapon.factor_x*30) # unless weapon.is_a?(Torch) and weapon.on_ground
					end
					weapon.lit_fire if weapon.is_a?(Torch) and not die?
					weapon.die if weapon.is_a?(Knife) and !@hardened
					weapon.deflect if weapon.is_a?(Axe) or weapon.is_a?(Knife) and @hardened
				end
			end
		end
		if @harmful
			self.each_collision(@player) do |enemy, me|
				if collision_at?(enemy.x, enemy.y)
					me.knockback(@damage) unless me.invincible or enemy.die?
				end
			end
		end
	end

	def at_edge?
		@x < (bb.width/2)  || @x > parent.area[0]-(bb.width/2)
	end

	# ==============================================================================
	# Pathfinding stuffs
	# These methods are used for pathfinding, meaning the automated 
	# movements are predefined and executed on the go.
	# Utilizes pathfind module, using A* as macro-level planner
	# ==============================================================================
	def record_position(target)
		return if parent.gridmap.nil?
		return if target.nil?
		unless die?
			path = parent.gridmap.find_path_astar @pos, target.pos
			@target_pos = get_nearest_waypoint path, target if (@target_pos.nil? or @target_pos.empty?) and
															   parent.gridmap.on_move_route target
		end
	end

	def get_nearest_waypoint(path, target)
		return if path.nil?
		return if path.empty?
		return target.pos if @pos == target.pos
		path.pop
		result = path[0]
		nearest_x = result[0]
		nearest_y = result[1]
		# Checking whether target is above
		# if target.pos[1] != @pos[1]
		# 	parent.gridmap.jump_points.each_with_index do |point, id|
		# 		next if point.nil?
		# 		next if point.empty?
		# 		next if (point[1] - @pos[1]).abs > 4
		# 	   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
		# 	   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
		# 		if get_nearest(@pos[0], point[0]) < nearest_x and
		# 		   get_nearest(@pos[1], point[1]) < nearest_y
		# 			nearest_x = get_nearest(@pos[0], point[0])
		# 			nearest_y = get_nearest(@pos[1], point[1])
		# 			result = point if waypoint_in_course? point, target.pos
		# 		end
		# 	end
		# else
			# path.each do |point|
			# 	next if point.nil?
			# 	next if point.empty?
			#    	next if point[0] == 0 or point[0] == parent.gridmap.map_width
			#    	next if point[1] == 0 or point[1] == parent.gridmap.map_height
			# 	result = point if waypoint_in_course? point, target.pos
			# end
		# end

		path.each do |point|
			next if point.nil?
			next if point.empty?
		   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
		   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
			if get_nearest(target.pos[0], point[0]) < nearest_x and
			   get_nearest(target.pos[1], point[1]) < nearest_y
				nearest_x = get_nearest(target.pos[0], point[0])
				nearest_y = get_nearest(target.pos[1], point[1])
				result = point if waypoint_in_course? point, target.pos
			end
		end
		presult = get_alternate_waypoint(target)
		result = presult if result[1] != presult[1] and (get_nearest(presult[1], result[1]) < 3 and
														 get_nearest(presult[1], result[1]) != 0 )
		return result
	end

	def get_alternate_waypoint(target)
		presult = []
		result = nil
		nearest_y = nil
		parent.gridmap.jump_points.each_with_index do |point, id|
			next if point.nil?
			next if point.empty?
			# next if (point[1] - result[1]).abs > 3
		   	next if point[0] == 0 or point[0] == parent.gridmap.map_width
		   	next if point[1] == 0 or point[1] == parent.gridmap.map_height
			if get_nearest(@pos[0], point[0]) < 6 and
			   get_nearest(@pos[1], point[1]) < 6
				presult.push point if get_nearest(@pos[1], point[1]) < 4 # if waypoint_in_course? point, target.pos
			end
		end
		presult.each do |res|
			if nearest_y.nil? or get_nearest(target.pos[1], res[1]) < nearest_y
				nearest_y = get_nearest(target.pos[1], res[1])
				result = res 
			end
		end
		return result
	end

	def get_nearest(a, b)
		return (a - b).abs
	end

	def waypoint_in_course?(target, point)
		return true if in_left_of target and point[0] < target[0]
		return true if in_right_of target and point[0] > target[0]
		return false
	end
	
	def check_position(pos, flip = false)
		return if self.destroyed?
		return if pos.nil?
		return if pos.is_a? Array and pos.empty?
		@factor_x = -$window.factor if in_left_of pos
		@factor_x = $window.factor if in_right_of pos
	end

	def move_to(pos)
		jump if need_jump @player
	end

	def need_jump(target)
		need = false 
		if in_map and not @jumping
			need = true if jump_is_necessary and @velocity_x.abs > 0.8
			need = true if target.is_a? Actor and target.jumping and in_position @target_pos
		end
		return need
	end

	def in_map
		!parent.gridmap.tiles[[@pos[0],@pos[1]]].nil?
	end

	def in_sight(target)
		return false if @pos.nil?
		return false if @pos.empty?
		return false if target.nil?
		(@pos[0] - target.pos[0]).abs <= 8 and (@pos[1] - target.pos[1]).abs <= 4
	end

	def jump_is_necessary
		in_front_of_impassable and at_jump_point
	end
	
	def at_jump_point
		if x == previous_x
			for i in @pos[0]-1...@pos[0]+1
				next if i >= @pos[0] and in_left_of @target_pos
				next if i <= @pos[0] and in_right_of @target_pos
				return true if parent.gridmap.tiles[[i,@pos[1]-1]] != 0
			end
		else
			return true if parent.gridmap.jump_points.include? @pos and 
						   (@x >= (@pos[0]-1) * 16 and @x <= (@pos[0]+1) * 16) and
						   is_above @target_pos
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

	def in_position(target)
		return false if target.nil?
		return false if target.is_a? Array and target.empty?
		return false if @pos.empty?
		if target.is_a?(Array)
			target[0] == @pos[0] and target[1] == @pos[1]
		else
			target.pos[0] == @pos[0] and target.pos[1] == @pos[1]
		end
	end
	def in_left_of(pos)
		return if pos.nil?
		return if pos.is_a?(Array) and pos.empty?
		return pos[0] < @pos[0] if pos.is_a?(Array)
		return pos.pos[0] < @pos[0] unless pos.is_a?(Array)
	end
	def in_right_of(pos)
		return if pos.nil?
		return if pos.is_a?(Array) and pos.empty?
		return pos[0] > @pos[0] if pos.is_a?(Array)
		return pos.pos[0] > @pos[0] unless pos.is_a?(Array)
	end
	def is_in_same_level_with(pos)
		return if pos.nil?
		return if pos.is_a?(Array) and pos.empty?
		return pos[1] == @pos[1] if pos.is_a?(Array)
		return pos.pos[1] == @pos[1] unless pos.is_a?(Array)
	end
	def is_above(pos)
		return if pos.nil?
		return if pos.is_a?(Array) and pos.empty?
		return pos[1] < @pos[1] if pos.is_a?(Array)
		return pos.pos[1] < @pos[1] unless pos.is_a?(Array)
	end
	def is_below(pos)
		return if pos.nil?
		return if pos.is_a?(Array) and pos.empty?
		return pos[1] > @pos[1] if pos.is_a?(Array)
		return pos.pos[1] > @pos[1] unless pos.is_a?(Array)
	end

	def adjust_speed
		if @moving
			@velocity_x -= 0.1 if in_left_of @target_pos
			@velocity_x += 0.1 if in_right_of @target_pos
			@velocity_x = @speed if @velocity_x > @speed; @velocity_x = -@speed if @velocity_x < -@speed
			if in_position @target_pos
				@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
				if @velocity_x.abs < 0.2 #fix
					stand_still 
				end
			end
		else
			@velocity_x += 0.2 if @velocity_x < 0; @velocity_x -= 0.2 if @velocity_x > 0
			if @velocity_x.abs < 0.2 #fix
				stand_still 
			end
		end
	end

	# ==============================================================================
	# Decision making stuffs
	# The command shall follow the rule:
	#     [:command_name, [param1, [param2...]]]
	# ==============================================================================
	def push_command(command)
		@command.push command
		return @command.uniq!
	end
	def pull_command
		@command.shift
	end
	def is_current_command?(command)
		return false if @command.empty?
		return false if @current_command.nil?
		@command.each do |com|
			return true if @current_command == com[0]
		end
		return false
	end

	def command_exist?(command)
		return false if @command.empty?
		@command.each do |com|
			return true if com[0] == command
		end
		return false
	end

	def execute_command
		return if @command.empty?
		return if @current_command == @command[0][0]
		case @command[0][0]
			when :check_position
				record_position @command[0][1] # produces @target_pos value
				check_position @target_pos, true
			when :move_to_target
				@moving = true
			when :stop
				@moving = false
				@target_pos = nil
		end
		@current_command = @command[0][0]
		pull_command
	end

	# ==============================================================================
	# And it's up!
	# ==============================================================================	
	def update
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		@y_flag = @y if @velocity_y == Orange::Environment::GRAV_WHEN_LAND && !@jumping
		check_collision
		execute_command
	end
end