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
	trait :bounding_box, :debug => false
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
		
	end

	def record_pos
		x = (@x / 16).to_i
		y = (@y / 16).to_i
		save_pos [x, y]
	end

	def save_pos(array)
		@pos = array
	end

	def check_position(object, flip = false)
		x = object.pos[0] - @pos[0]
		y = object.pos[1] - @pos[1]
		@factor_x = x >= 0 ? $window.factor : -$window.factor if flip
	end

	def find_position(target)
		check_position(target, true)
		parent.gridmap.find_path_astar @pos, target.pos
		@status = :move
	end

	def move_to(target)
		while not in_position target
			@x += @speed * @factor_x
		end
	end

	def in_position(pos)
		@pos[0] != pos[0] and @pos[1] != pos[1]
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
	
	def standing;     @status == :stand;    end
	def moving;       @status == :move;     end
	def jumping;      @status == :jump;     end
	def falling;      @status == :fall;     end
	def damaged;      @status == :hurt; 	  end
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
		Misc_Flame.create(:x => self.x, :y => self.y)
		destroy
		$window.enemies.delete(self) rescue nil
	end

	def jump
		if crouching_on_bridge
			return if self.velocity_y > Orange::Environment::GRAV_WHEN_LAND # 1
			return if jumping or damaged or die? or not idle
			@status = :jump
			@jumping = true
			@velocity_y = -1
			@y += 12
		else
			return if self.velocity_y > Orange::Environment::GRAV_WHEN_LAND # 1
			return if crouching or jumping 
			return if damaged or die? 
			return unless idle 
			@status = :jump
			@jumping = true
			Sound["sfx/jump.wav"].play
			@velocity_y = -4
			during(9){
				@velocity_y = -4  unless @velocity_y <=  -Orange::Environment::GRAV_CAP || !@jumping
			}
		end
	end
	
	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			if me.y >= stone_wall.bb.bottom and self.velocity_y < 0 # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
				@jumping = false
			else  # Land on ground
				if damaged
					hurt
				else
					land
				end
				me.velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
				me.y = stone_wall.bb.top - 1 # unless me.y > stone_wall.y
			end
		end
		self.each_collision(*$window.bridges) do |me, bridge|
			if me.y <= bridge.y+2 && me.velocity_y > 0
				if damaged
					hurt
				else
					land
				end
				me.velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
				me.y = bridge.bb.top - 1
			end
		end
	end

	def land
		delay = 18
		delay = 24 if attacking
		if (@y - @y_flag > 56 or (@y - @y_flag > 48 && jumping ) ) && !die?
			Sound["sfx/step.wav"].play
			between(1,delay) { 
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
		@velocity_x = 0
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
	
	def update
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		@y_flag = @y if @velocity_y == Orange::Environment::GRAV_WHEN_LAND && !@jumping
		check_collision
	end
end