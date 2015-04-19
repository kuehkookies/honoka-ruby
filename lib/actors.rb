# ==================================================================================
# Class Actor
#     part from GameObject
#
# Here defined the Actor object and its methods, behaviors and available actions.
# To define an Actor and available actions and behaviors, make the Actor
# in /actors folder. Leave this file as mother of all /actors files.
# ==================================================================================
class Actor < Chingu::GameObject
	attr_accessor :maxhp, :hp, :damage, :level, :ammo
	attr_accessor	:y_flag, :sword, :status, :action, :running, :character, :subweapon
	attr_reader 	:direction, :invincible, :last_x
	trait :bounding_box, :scale => [0.3, 0.8], :debug => false
	traits :timer, :collision_detection, :velocity
	
	def setup
		self.input = {
			:holding_left => :move_left,
			:holding_right => :move_right,
			:holding_down => :crouch,
			:holding_up => :steady,
			[:released_left, :released_right, :released_down, :released_up] => :stand,
			:z => :jump
		}

		@maxhp  = 16
		@hp     = 0
		@ammo   = 0
		@damage = 0
		@level  = 0
		@speed  = 2

		@status = :stand
		@action = :stand
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false
		@sub = []
		self.zorder = 250

		@acceleration_y = Orange::Environment::GRAV_ACC
		self.max_velocity = Orange::Environment::GRAV_CAP

		self.rotation_center = :bottom_center

		# Yet other flags
		@last_x, @last_y = @x, @y
		@y_flag = @y

		# Trait feature that creates a bounding box for collision detection and stuffs.
		# Without this, Mark can't stand on very ground.
		cache_bounding_box
	end

	def reset_state(value)
		@hp        = value[0] || @maxhp
		@ammo      = value[1] || 10
		@level     = value[2] || 1
		@damage    = value[3] || 1
		@subweapon = value[4] || :none

		@status = :stand; @action = :stand
		@sword = nil
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false

		$window.clear_temp_data
	end
	
	def disabled
		@status == :hurt or @status == :die
	end
	
	def blinking;     @status == :blink;    end
	def standing;     @status == :stand;    end
	def jumping;      @status == :jump;     end
	def falling;      @status == :fall;     end
	def crouching;    @status == :crouch;   end
	def steading;     @status == :stead;    end
	def on_wall;      @status == :walljump; end
	def damaged;      @status == :hurt; 	  end

	def attacking;    @action == :attack;   end
	def idle;         @action == :stand;    end
	def walljumping;  @action == :walljump; end

	def die?;         @hp <= 0;           end

	def knocked_back; @status == :hurt and moved?; end
	def moving_to_another_area; $window.transfer; end
	def in_event; $window.in_event; end
	
	def holding_subweapon?; @subweapon != :none; end

	def attacking_on_ground
		@action == :attack && @status == :stand && @velocity_y < Orange::Environment::GRAV_WHEN_LAND + 1
	end
	
	def at_edge?
		@x < (bb.width/2)  || @x > parent.area[0]-(bb.width/2) unless @status == :blink
	end

	def stand
		unless jumping or disabled or die? or @y != @y_flag or not idle
			@image = @character[:stand].first
			@status = :stand
			@running = false
			@jumping = false
		end
	end
	
	def crouch
		unless jumping or disabled or attacking or die? or disabled
			@image = @character[:crouch].first
			@status = :crouch
		end
	end
	
	def steady
		unless jumping or disabled or attacking or die? or disabled
			@image = @character[:stead].first
			@status = :stead
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
				if !die?; @status = :stand; @image = @character[:stand].first; end
			}
		else
			if jumping or on_wall or falling
				@image = @character[:stand].first unless Sword.size >= 1
				@status = :stand 
			elsif @velocity_y >= Orange::Environment::GRAV_WHEN_LAND + 1 # 2
				@image = @character[:stand].first unless Sword.size >= 1
				@velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
			end
		end
		@jumping = false if @jumping
		@vert_jump = false if !@jumping
		@velocity_x = 0
		@y_flag = @y
	end

	def move_left
		return if attacking_on_ground or walljumping
		return if crouching or steading
		return if moving_to_another_area or in_event
		return if die? or disabled
		move(-@speed, 0)
	end
	
	def move_right
		return if attacking_on_ground or walljumping
		return if crouching or steading
		return if moving_to_another_area or in_event
		return if die? or disabled
		move(@speed, 0)
	end
	
	def jump
		return if on_wall and @jumping
		if on_wall and not attacking and not @jumping and holding_any?(:left, :right)
			@action = :walljump
			@sword.die if @sword != nil
			@y_flag = @y
			self.factor_x *= -self.factor_x.abs
			@velocity_y = 0
			between(1,6){ 
				@image = @character[:wall_jump].first
				@velocity_y = 0
			}.then{
				@x += 4 * self.factor_x
				@image = @character[:jump].first
				@status = :jump; @jumping = true
				Sound["sfx/jump.wav"].play
				@velocity_x = 4 * self.factor_x
			}
			between(6,15){
				@velocity_y = -6 if @jumping
				@velocity_y = -2 if !@jumping
			}
			after(15){ @action = :stand; @velocity_y = -2 if @jumping; @y_flag = @y; @velocity_x = 0}
		else
			return if self.velocity_y > Orange::Environment::GRAV_WHEN_LAND # 1
			return if crouching or jumping or damaged or die? or not idle or on_wall
			@status = :jump
			@jumping = true
			Sound["sfx/jump.wav"].play
			@velocity_y = -4
			during(9){
				@vert_jump = true if !holding_any?(:left, :right)
				if holding?(:z) && @jumping && !disabled
					@velocity_y = -4  unless @velocity_y <=  -Orange::Environment::GRAV_CAP || !@jumping
				else
					@velocity_y = -1 unless !@jumping
				end
			}
		end
	end

	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			if me.y >= stone_wall.bb.bottom and self.velocity_y < 0 # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
				@jumping = false
			elsif walljumping
				@jumping = false
				me.x = stone_wall.bb.right + (me.image.width/4) if me.x > stone_wall.x
				me.x = stone_wall.bb.left - (me.image.width/4) if me.x < stone_wall.x
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

	def knockback(damage)
		return if @invincible
		@invincible = true
		@status = :hurt
		@action = :stand
		@sword.destroy if @sword != nil
		Sound["sfx/grunt.ogg"].play(0.8)
		@hp -= damage # 3
		@hp = 0 if @hp <= 0
		self.velocity_x = (self.factor_x*-1)
		self.velocity_y = -4
		land?
	end
	
	def hurt
		@velocity_x = 0
		@jumping = false
		if not die?
			between(1,30) { 
				@status = :crouch; crouch
			}.then { @status = :stand; @image = @character[:stand].first}
			between(30,120){@color.alpha = 128}.then{@invincible = false; @color.alpha = 255}
		else
			dead
		end
	end

	def dead
		@hp = 0
		@sword.die if @sword != nil
		@status = :die
		@image = @character[:stand].last
		after(6){@image = @character[16]}
		after(12){
			@image = @character[:die].first
			@x += 8*@factor_x unless @y > ($window.height/2) + parent.viewport.y
			#~ game_state.after(1500) { 
			game_state.after(90) { 
				@sword.die if @sword != nil
				reset_state
				$window.reset_stage
				parent.clear_game_terrains
			}
		}
	end
	
	def move(x,y)
		return if blinking
		if x != 0 and not (jumping or on_wall)
			@image = @character[:step].first if !@running
			@image = @character[:walk].next if @running
			after(2) { @running = true if not @running }
		end
		
		@image = @character[:hurt].first  if damaged
		
		unless attacking or damaged or on_wall
			self.factor_x = self.factor_x.abs   if x > 0
			self.factor_x = -self.factor_x.abs  if x < 0
		end
		
		unless (on_wall and @jumping)
			@x += x if !@vert_jump and not falling
			@x += x/2 if @vert_jump or falling
		end

		self.each_collision(*$window.terrains) do |me, stone_wall|
			@x = previous_x
			if @jumping
				if stone_wall.x < me.x and holding?(:left); @status = :walljump; @jumping = false; end
				if stone_wall.x > me.x and holding?(:right); @status = :walljump; @jumping = false; end
			end
			break
		end
		
		if @x != previous_x and on_wall and !@jumping
			@status = :jump; @jumping = true
		end
		
		@x = previous_x  if at_edge? and not in_event

		@y += y
	end
	
	def check_last_direction
		if @x == @last_x && @y == @last_y or @subattack
			@direction = [self.factor_x*(2), 0]
		else
			@direction = [@x - @last_x, @y - @last_y]
		end
		@last_x, @last_y = @x, @y
	end

end