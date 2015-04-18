# ==================================================================================
# Class Ghoul_Sword
#     Part of Hazard
# 
# Here is sample of harmful object, whose purpose is to subdue our Actors. It can 
# be stationery, but in this case, the object is carried by Ghoul, variant of 
# Zombie.
# ==================================================================================

class Ghoul_Sword < Hazard
	trait :bounding_box, :debug => false
	
	def setup
		super
		@image = Image["weapons/sword-small.png"]
		self.rotation_center = :center_left
		@velocity_x *= 1
		@velocity_y *= 1
		@max_velocity = Honoka::Environment::GRAV_CAP
		@damage = 4
		@rotation = 0
		@color = Color.new(0xff88DD44)
		cache_bounding_box
	end
	
	def die
		@acceleration_y = Honoka::Environment::GRAV_ACC # 0.3
		self.rotation_center = :center_center
		@velocity_x = -@factor_x
		@velocity_y = -6
		@rotation = 20*@factor_x
		@collidable = false
		after(60){destroy}
	end
	
	def update
		super
		@angle += @rotation
	end
end