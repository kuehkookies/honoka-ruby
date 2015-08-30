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
	attr_reader 	:direction, :invincible, :last_x, :pos
	trait :bounding_box, :scale => [0.5, 0.8], :debug => false
	traits :timer, :collision_detection, :velocity
	
	def setup
		create_character_frame
		@blank = TexPlay.create_image($window, 1, 1)
		@image = character_frame(:stand, :first)
		
		make_idle_animation
		key_inputs
		actor_properties
		actor_parameters

		# Trait feature that creates a bounding box for collision detection and stuffs.
		# Without this, Actor can't stand on very ground.
		cache_bounding_box

		every(Orange::Environment::POS_RECORD_INTERVAL){
			record_pos
		}
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

	def make_idle_animation; end
	
	def key_inputs
		self.input = {
			:holding_left => :move_left,
			:holding_right => :move_right,
			:holding_down => :crouch,
			:holding_up => :steady,
			[:released_left, :released_right, :released_down, :released_up] => :stand,
			:z => :jump
		}
	end

	def actor_parameters
		@maxhp  = 16
		@hp     = 0
		@ammo   = 0
		@damage = 0
		@level  = 0
		@speed  = 1
		@subweapon = :none
	end

	def actor_properties
		@status = :stand
		@action = :stand
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false
		self.zorder = 250

		@acceleration_y = Orange::Environment::GRAV_ACC
		self.max_velocity = Orange::Environment::GRAV_CAP

		self.rotation_center = :bottom_center

		@pos = [0,0]

		@last_x, @last_y = @x, @y
		@y_flag = @y
	end

	def reset_state(value=[])
		@hp        = value[0] || @maxhp
		@ammo      = value[1] || 10
		@level     = value[2] || 1
		@damage    = value[3] || 1
		@subweapon = value[4] || :none

		@status = :stand; @action = :stand
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false

		$window.clear_temp_data
	end

	def record_pos
		x = ((@x+4) / 16).to_i
		y = (@y / 16).to_i
		save_pos [x,y]
	end

	def save_pos(array)
		@pos = array
	end
	
	def blinking;     @status == :blink;    end
	def standing;     @status == :stand;    end
	def jumping;      @status == :jump;     end
	def falling;      @status == :fall;     end
	def crouching;    @status == :crouch;   end
	def steading;     @status == :stead;    end
	def damaged;      @status == :hurt; 	  end
	
	def crouching_on_bridge
		@status == :crouch_on_bridge
	end

	def disabled
		@status == :hurt or @status == :die
	end

	def attacking;    @action == :attack;   end
	def idle;         @action == :stand;    end

	def die?;         @hp <= 0;           end

	def knocked_back; @status == :hurt and moved?; end
	def moving_to_another_area; $window.transfer; end
	def in_event; $window.in_event; end
	
	def holding_subweapon?; @subweapon != :none; end

	def attacking_on_ground
		@action == :attack && @status == :stand && 
			@velocity_y < Orange::Environment::GRAV_WHEN_LAND + 1
	end
	
	def at_edge?
		@x < (bb.width/2)  || @x > parent.area[0]-(bb.width/2) unless blinking
	end

	def stand
		unless jumping or disabled or die? or @y != @y_flag or not idle
			@image = character_frame(:stand, :first)
			@status = :stand
			@running = false
			@jumping = false
		end
	end
	
	def crouch
		unless jumping or disabled or attacking or die? or disabled
			@image = character_frame(:crouch, :first)
		end
	end
	
	def steady
		unless jumping or disabled or attacking or die? or disabled
			@image = character_frame(:stead, :first)
			@status = :stead
		end
	end
	
	def land
		delay = 18
		delay = 24 if attacking
		if (@y - @y_flag > 56 or (@y - @y_flag > 48 && jumping ) ) && !die?
			Sound["sfx/step.wav"].play
			between(1,delay) { 
				@velocity_x = 0
				@status = :crouch; crouch
			}.then { 
				if !die?; @status = :stand; @image = character_frame(:stand, :first); end
			}
		else
			if jumping or falling
				@image = character_frame(:stand, :first) unless Sword.size >= 1
				@status = :stand 
			elsif @velocity_y >= Orange::Environment::GRAV_WHEN_LAND + 1 # 2
				@image = character_frame(:stand, :first) unless Sword.size >= 1
				@velocity_y = Orange::Environment::GRAV_WHEN_LAND # 1
			end
		end
		@jumping = false if @jumping
		@vert_jump = false if !@jumping
		@y_flag = @y
	end

	def move_left
		return if attacking_on_ground
		return if crouching_on_bridge or crouching or steading
		return if moving_to_another_area or in_event
		return if die? or disabled
		move(-@speed, 0)
	end
	
	def move_right
		return if attacking_on_ground
		return if crouching_on_bridge or crouching or steading
		return if moving_to_another_area or in_event
		return if die? or disabled
		move(@speed, 0)
	end

	def adjust_speed
		speed = @speed; speed *= 2 if holding?(:c)
		if holding_any?(:left, :right)
			@velocity_x -= 0.1 if holding?(:left)
			@velocity_x += 0.1 if holding?(:right)
			@velocity_x = speed if @velocity_x > speed; @velocity_x = -speed if @velocity_x < -speed
		else
			unless @velocity_x == 0.0
				@velocity_x += 0.1 if @velocity_x < 0; @velocity_x -= 0.1 if @velocity_x > 0
				if @velocity_x.abs < 0.1 and not (@jumping or falling) #fix
					@velocity_x = 0
					@image = character_frame(:stand, :first)
					stand
				end
			end
		end
		@velocity_x = 0 if die?
	end

	def move(x,y)
		return if blinking
		if x != 0 and not jumping
			@image = character_frame(:step, :first) if !@running
			@image = character_frame(:walk, :next) if @running
			after(2) { @running = true if not @running }
		end
		
		@image = character_frame(:hurt, :first)  if damaged
		
		unless attacking or damaged or (jumping and @velocity_y < 0)
			self.factor_x = self.factor_x.abs   if holding?(:right)
			self.factor_x = -self.factor_x.abs  if holding?(:left)
		end

		velocity = @velocity_x
		
		@x += velocity

		self.each_collision(*$window.terrains) do |me, stone_wall|
			@x = previous_x
			break
		end
		
		@x = previous_x  if at_edge? and not in_event
		@y += y
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
			@velocity_y = -4.5
			during(9){
				@vert_jump = true if !holding_any?(:left, :right)
				if holding?(:z) && @jumping && !disabled
					@velocity_y = -4.5  unless @velocity_y <=  -Orange::Environment::GRAV_CAP || !@jumping
				else
					@velocity_y = -1 unless !@jumping
				end
			}
		end
	end

	def jumping?
		@jumping
	end

	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			if me.y >= stone_wall.bb.bottom and self.velocity_y < 0 # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
				@jumping = false
			else  # Land on ground
				@status = :crouch if holding?(:down)
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
				@status = :crouch_on_bridge if holding?(:down)
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
			}.then { @status = :stand; @image = character_frame(:stand, :first)}
			between(30,120){@color.alpha = 128}.then{@invincible = false; @color.alpha = 255}
		else
			dead
		end
	end

	def dead
		@hp = 0
		@sword.die if @sword != nil
		@status = :die
		@image = character_frame(:stand, :last)
		after(6){@image = @character[16]}
		after(12){
			@image = character_frame(:die, :first)
			@x += 8*@factor_x unless @y > ($window.height/2) + parent.viewport.y
			game_state.after(90) { 
				@sword.die if @sword != nil
				reset_state
				$window.reset_stage
				parent.clear_game_terrains
			}
		}
	end
	
	def check_last_direction
		if @x == @last_x && @y == @last_y or @subattack
			@direction = [self.factor_x*(2), 0]
		else
			@direction = [@x - @last_x, @y - @last_y]
		end
		@last_x, @last_y = @x, @y
	end

	def update
		land?
		adjust_speed
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		if @x == @last_x
			@running = false
			character_frame(:walk, :reset)
		end
		if jumping and idle
			if @last_y > @y 
				@image = character_frame(:jump, :first)
				@image = character_frame(13)if @vert_jump
			else
				@image = character_frame(13) if @velocity_y <= 2
				@image = character_frame(:jump, :last) if @velocity_y > 2
			end
		end
		check_last_direction
		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle
			@status = :fall unless disabled
			@image = character_frame(13) if @velocity_y <= 3
			@image = character_frame(:jump, :last) if @velocity_y > 3
		end
		@y_flag = @y if @velocity_y == Orange::Environment::GRAV_WHEN_LAND && !@jumping
	end
end