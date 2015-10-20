# ==================================================================================
# Class Runner
#     part of Actor
# 
# A sample actor which can only run and jump. The heart of every platformer.
# Use this as base of every Actors you'd like to create.
# ==================================================================================

class Runner < Actor	
	def create_character_frame
		@character = Chingu::Animation.new( :file => "player/sutisna.gif", :size => [32,32])
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

	def actor_parameters
		@maxhp  = 16
		@hp     = 0
		@ammo   = 10
		@damage = 0
		@level  = 0
		@speed  = 1
		@subweapon = :batu
	end

	def fire
		unless disabled or die?
			if holding?(:up) and holding_subweapon?
				unless attacking || crouching || limit_subweapon
					# attack_sword if @ammo == 0
					attack_subweapon if @ammo != 0
				end
			# else
			# 	unless Sword.size >= 1
			# 		attack_sword
			# 	end
			end
		end
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
				when :batu
					Batu.create(:x => @x+(10*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Batu.size >= Orange::ALLOWED_SUBWEAPON_THROWN
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
end