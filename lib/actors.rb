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
	
	def setup
		@maxhp = 16
		@hp = 0
		@ammo = 0
		@damage = 0
		@level = 0
	end

	def reset_state(value)
		@hp = value[0] || @maxhp
		@ammo = value[1] || 10
		@level = value[2] || 1
		@damage = value[3] || 1

		$window.clear_temp_data
	end
end