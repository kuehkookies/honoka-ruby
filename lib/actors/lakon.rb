# ==================================================================================
# Class Lakon
#     part from Actor
# ==================================================================================

class Lakon < Actor	
	def setup
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
		@character[:walk].delay = 60 # 65
		@image = @character[:stand].first
		
		super

		self.input = {
			:holding_left => :move_left,
			:holding_right => :move_right,
			:holding_down => :crouch,
			:holding_up => :steady,
			[:released_left, :released_right, :released_down, :released_up] => :stand,
			:z => :jump,
			:x => :fire
		}
		
		# Idle animation? Idle animation.
		make_idle_animation
	end

	# Reset player's flags. Useful when respawning Mark on Scene.
	def reset_state(value)
		super(value)
	end

	def limit_subweapon
		Knife.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Axe.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Torch.size >= Orange::ALLOWED_SUBWEAPON_THROWN || 
		Rang.size >= Orange::ALLOWED_SUBWEAPON_THROWN
	end

	def make_idle_animation
		every(120){
			unless die?
				if @action == :stand && @status == :stand && @last_x == @x
					during(9){
						@image = @character[:stand].next
					}.then{@image = @character[:stand].reset; @image = @character[:stand].first}
				end
			end
		}
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
	
	def change_subweapon
		@sub = @sub.rotate
		@subweapon = @sub[0]
	end
	
	def attack_sword
		@action = :attack
		@image = @character[:shoot].first if not crouching
		@image = @character[:crouch_shoot].first if crouching
		factor = -(self.factor_x^0)
		@sword = Sword.create(:x => @x+(5*factor), :y => (@y-14), :velocity => @direction, :factor_x => -factor, :angle => 90*(-factor_x))
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
				@image = @character[:crouch_shoot][1] if crouching
				@image = @character[:shoot][1] if not crouching
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
				@image = @character[:crouch_shoot][2] if crouching
				@image = @character[:shoot][2] if not crouching
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
				@image = @character[:crouch_shoot][3] if crouching
				@image = @character[:shoot][3] if not crouching
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
				@image = @character[:crouch_shoot].last if crouching
			end
		}.then {
			unless disabled
				@sword.die
				@action = :stand
				unless disabled
					@image = @character[:stand].first if standing or steading
					@image = @character[:crouch].first if crouching
					@image = @character[:jump].last if jumping
				end
				@status = :stand if steading || !holding?(:down)
			end
			@character[:shoot].reset
			@character[:crouch_shoot].reset
		}
	end
	
	def attack_subweapon
		@action = :attack
		@subattack = true
		@image = @character[:shoot][0]
		between(6,12) { 
			@image = @character[:shoot][1]
		}.then{
			@image = @character[:shoot][2]
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
		#~ after(200) { @image = @character[:shoot].last}
		between(12,32) { 
		#~ after(350) {  
			@image = @character[:shoot].last
			@image = @character[:crouch_shoot].last if crouching
		}.then {
			@action = :stand
			@status = :stand if steading
			unless disabled
				@image = @character[:stand].first if standing or steading
				@image = @character[:crouch].first if crouching
				@image = @character[:jump].last if jumping
			end
			@character[:shoot].reset
			@character[:crouch_shoot].reset
		}
	end
	
	def update
		land?
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		if @x == @last_x
			@running = false
			@character[:walk].reset
		end
		if (jumping or on_wall) and idle
			if @last_y > @y 
				@image = @character[:jump].first
				@image = @character[13] if @vert_jump
			else
				@image = @character[13] if @velocity_y <= 2
				@image = @character[:jump].last if @velocity_y > 2
			end
		end
		check_last_direction
		if @velocity_y > Orange::Environment::GRAV_WHEN_LAND + 1 && !jumping && idle && !on_wall
			@status = :fall unless disabled
			@image = @character[13] if @velocity_y <= 3
			@image = @character[:jump].last if @velocity_y > 3
		end
		self.each_collision(Rang) do |me, weapon|
			weapon.die
		end
		@y_flag = @y if @velocity_y == Orange::Environment::GRAV_WHEN_LAND && !@jumping
	end
end