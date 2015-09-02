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
		@ammo   = 0
		@damage = 0
		@level  = 0
		@speed  = 1
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
end