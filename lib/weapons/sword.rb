# ==================================================================================
# Class Sword
#     Part of GameObject
# 
# A kinda large bar of sharpened steel. A sample of basic, upgradable weapon.
# The parameter depends on Actor's strike level.
# ==================================================================================

class Sword < GameObject
	trait :bounding_box, :debug => false
	traits :collision_detection, :timer, :velocity
	attr_reader :damage
	attr_accessor :zorder
	
	def initialize(options={})
		super
		@player = parent.player
		@image = Image["weapons/sword-#{$window.wp_level}.gif"]
		self.rotation_center = :center_left
		@zorder = @player.zorder
		@velocity_x *= 1
		@velocity_y *= -1 if self.velocity_y > 0
		@velocity_y *= 1
		@collidable = false
		@damage = $window.wp_level*2
		@damage = 4 if $window.wp_level >= 3
		cache_bounding_box
	end
	
	def die
		self.destroy
	end
end