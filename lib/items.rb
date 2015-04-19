# ==================================================================================
# Class Items
#     Part of GameObject
# 
# Here defined the logics for Items classes. Items are variable objects which has
# variable uses like collectible items (i.e. coins in Mario, hearts in Castlevania)
#
# To define the stage and setting start point for Actor, make the stages 
# in /items folder. Leave this file as mother of all /items files.
#
# TODO: 
# Make variable definitions depending on the game setting
# ==================================================================================

class Items < GameObject
  trait :bounding_box, :debug => false
  traits :collision_detection, :velocity, :timer
	
	def self.descendants
		ObjectSpace.each_object(Class).select { |klass| klass < self }
	end
	
	def setup
		@image = Image["items/#{self.filename}.gif"]
		@player = parent.player
		@acceleration_y = 0.6
		@max_velocity = 8
		self.zorder = 300
		self.rotation_center = :bottom_center
		$window.items << self
		cache_bounding_box
	end

	def land?
		self.each_collision(*$window.terrains, *$window.bridges) do |me, stone_wall|
			if collision_at?(me.x, me.y) and me.y <= stone_wall.y
				me.velocity_y = Orange::Environment::GRAV_WHEN_LAND
				me.y = stone_wall.bb.top - 1 
			end
		end
	end
	
	def update
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		unless destroyed?
			land?
			@player.each_collision(self) do |me, item|
				unless destroyed?
					item.die # unless destroyed?
					if item.is_a?(Item_Sword)
						$window.enemies.each { |enemy| 
							enemy.pause! unless $window.wp_level > 3 # or enemy.paused?
						}
						$window.wp_level = 3 if $window.wp_level > 3
					end
				end
			end
			after(120) {self.destroy}
		end
	end
	
	def destroyed?
		return true if self == nil
	end
	
	def die
		Sound["sfx/klang.wav"].play(0.3)
		self.destroy
	end
end