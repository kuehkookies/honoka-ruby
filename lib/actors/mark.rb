# ==================================================================================
# Class Mark
#     part of Actor
#
# Sample of Actor namely Märk Hammerfist the Warrior Blacksmith of Westerland.
# Mark harnesses basic movements and actions akin to Simon Belmont, in addition
# he also can do walljump.
# ==================================================================================

class Mark < Actor	
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

	def key_inputs
		self.input = {
			:holding_left => :move_left,
			:holding_right => :move_right,
			:holding_down => :crouch,
			:holding_up => :steady,
			[:released_left, :released_right, :released_down, :released_up] => :stand,
			:z => :jump,
			:x => :fire
		}
	end

	def actor_parameters
		@maxhp  = 16
		@hp     = 0
		@ammo   = 0
		@damage = 0
		@level  = 0
		@speed  = 2
		@subweapon = :none
	end

	def make_idle_animation
		every(120){
			unless die?
				if @action == :stand && @status == :stand && @last_x == @x
					during(9){
						@image = character_frame(:stand, :next)
					}.then{@image = character_frame(:stand, :reset); 
						@image = character_frame(:stand, :first) }
				end
			end
		}
	end

	# --------------------------------------------------------------------------------
  # Individual method goes below
  # --------------------------------------------------------------------------------
	
	def reset_state(value=[])
		@sword = nil
		super(value)
	end

	def on_wall;      @status == :walljump; end
	def walljumping;  @action == :walljump; end


	def limit_subweapon
		Knife.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Axe.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Torch.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Rang.size >= Orange::ALLOWED_SUBWEAPON_THROWN
	end

	def move_left
		return if walljumping
		super
	end

	def move_right
		return if walljumping
		super
	end

	def move(x,y)
		return if blinking
		if x != 0 and not (jumping or on_wall)
			@image = character_frame(:step, :first) if !@running
			@image = character_frame(:walk, :next) if @running
			after(2) { @running = true if not @running }
		end
		
		@image = character_frame(:hurt, :first)  if damaged
		
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
				if stone_wall.x < me.x and holding?(:left); @status = :walljump; 
					@jumping = false; end
				if stone_wall.x > me.x and holding?(:right); @status = :walljump; 
					@jumping = false; end
			end
			break
		end
		
		if @x != previous_x and on_wall and !@jumping
			@status = :jump; @jumping = true
		end
		
		@x = previous_x  if at_edge? and not in_event

		@y += y
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
				@image = character_frame(:wall_jump, :first)
				@velocity_y = 0
			}.then{
				@x += 4 * self.factor_x
				@image = character_frame(:jump, :first)
				@status = :jump; @jumping = true
				Sound["sfx/jump.wav"].play
				@velocity_x = 4 * self.factor_x
			}
			between(6,15){
				@velocity_y = -6 if @jumping
				@velocity_y = -2 if !@jumping
			}
			after(15){ @action = :stand; @velocity_y = -2 if @jumping; 
				@y_flag = @y; @velocity_x = 0 }
		elsif crouching_on_bridge
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
			return if on_wall
			@status = :jump
			@jumping = true
			Sound["sfx/jump.wav"].play
			@velocity_y = -4
			during(9){
				@vert_jump = true if !holding_any?(:left, :right)
				if holding?(:z) && @jumping && !disabled
					@velocity_y = -4  unless @velocity_y <= -Orange::Environment::GRAV_CAP or 
																	 !@jumping
				else
					@velocity_y = -1 unless !@jumping
				end
			}
		end
	end
	
	def fire
		unless disabled or walljumping or die?
			if holding?(:up) and holding_subweapon?
				unless attacking || crouching || limit_subweapon
					attack_sword if @ammo == 0
					attack_subweapon if @ammo != 0
				end
			else
				unless Sword.size >= 1
					attack_sword
				end
			end
		end
	end
	
	def attack_sword
		@action = :attack
		@image = character_frame(:shoot, :first) if not crouching
		@image = character_frame(:crouch_shoot, :first) if crouching
		factor = -(self.factor_x^0)
		@sword = Sword.create(:x => @x+(5*factor), :y => (@y-14), 
			:velocity => @direction, :factor_x => -factor, 
			:angle => 90*(-factor_x))
		between(1, 6) {
			unless disabled
				@sword.x = @x+(9*(-factor_x))
				@sword.y = (@y-(self.height/2)-1) if standing
				@sword.y = (@y-(self.height/2)+4) if crouching or jumping
				@sword.angle = 120*(-factor_x)
				@sword.velocity = @direction
			end
		}. then {
			Sound["sfx/swing.wav"].play
			unless disabled
				@image = character_frame(:crouch_shoot, 1) if crouching
				@image = character_frame(:shoot, 1) if not crouching
			end
		}
		between(6,10) {
			unless disabled
				@sword.x = @x+(9*(-factor_x))
				@sword.y = (@y-(self.height/2)+1)
				@sword.y = (@y-(self.height/2)+6) if crouching
				@sword.angle = 140*(-factor_x)
				@sword.velocity = [0,0]
			end
		}.then {
			unless disabled
				@image = character_frame(:crouch_shoot, 2) if crouching
				@image = character_frame(:shoot, 2) if not crouching
			end
			@sword.bb.height = (@sword.bb.width)*-1 + 8
			@sword.angle = 130*(-factor_x)
			@sword.collidable = true
		}
		between(10,15) {
			unless disabled
				@sword.x += (6*factor_x)
				@sword.y = (@y-(self.height/2)-4)
				@sword.y = (@y-(self.height/2)+1) if crouching
				@sword.angle -= 30*(-factor_x)
				@sword.velocity = [0,0]
			end
		}.then {
			unless disabled
				@image = character_frame(:crouch_shoot, 3) if crouching
				@image = character_frame(:shoot, 3) if not crouching
			end
			@sword.bb.height = ((@sword.bb.width*1/10))
		}
		#~ between(175, 350) {
		between(15,32) {
			unless disabled
				@sword.zorder = self.zorder - 1
				@sword.x = @x-(13*factor)+((-1)*factor)
				@sword.x = @x-(11*factor)+((-1)*factor) if crouching
				@sword.y = (@y-(self.height/2)+6)
				@sword.y = (@y-(self.height/2)+11) if crouching
				@sword.angle = 0*(-factor_x/2)
				@image = character_frame(:crouch_shoot, :last) if crouching
			end
		}.then {
			unless disabled
				@sword.die
				@action = :stand
				unless disabled
					@image = character_frame(:stand, :first) if standing or steading
					@image = character_frame(:crouch, :first) if crouching
					@image = character_frame(:jump, :last) if jumping
				end
				@status = :stand if steading || !holding?(:down)
			end
			character_frame(:shoot, :reset)
			character_frame(:crouch_shoot, :reset)
		}
	end
	
	def attack_subweapon
		@action = :attack
		@subattack = true
		@image = character_frame(:shoot, 0)
		between(6,12) { 
			@image = character_frame(:shoot, 1)
		}.then{
			@image = character_frame(:shoot, 2)
			@ammo -= 1
			case @subweapon
				when :knife
					Knife.create(:x => @x+(10*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Knife.size >= Orange::ALLOWED_SUBWEAPON_THROWN
				when :axe
					Axe.create(:x => @x+(8*factor_x), :y => @y-(self.height/2)-4, :velocity => @direction, :factor_x => factor_x) unless Axe.size >= Orange::ALLOWED_SUBWEAPON_THROWN
				when :torch
					Torch.create(:x => @x+(12*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Torch.size >= Orange::ALLOWED_SUBWEAPON_THROWN
				when :rang
					Rang.create(:x => @x+(12*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Rang.size >= Orange::ALLOWED_SUBWEAPON_THROWN
			end
			Sound["sfx/swing.wav"].play
		}
		between(12,32) { 
			@image = character_frame(:shoot, :last)
			@image = character_frame(:crouch_shoot, :reset) if crouching
		}.then {
			@action = :stand
			@status = :stand if steading
			unless disabled
				@image = character_frame(:stand, :first) if standing or steading
				@image = character_frame(:crouch, :first) if crouching
				@image = character_frame(:jump, :last) if jumping
			end
			character_frame(:shoot, :reset)
			character_frame(:crouch_shoot, :reset)
		}
	end
	
	def update
		land?
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		if @x == @last_x
			@running = false
			character_frame(:walk, :reset)
		end
		if (jumping or on_wall) and idle
			if @last_y > @y 
				@image = character_frame(:jump, :first)
				@image = character_frame(13)if @vert_jump
			else
				@image = character_frame(13) if @velocity_y <= 2
				@image = character_frame(:jump, :last) if @velocity_y > 2
			end
		end
		check_last_direction
		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle && !on_wall
			@status = :fall unless disabled
			@image = character_frame(13) if @velocity_y <= 3
			@image = character_frame(:jump, :last) if @velocity_y > 3
		end
		self.each_collision(Rang) do |me, weapon|
			weapon.die
		end
		@y_flag = @y if @velocity_y == Orange::Environment::GRAV_WHEN_LAND && !@jumping
	end
end