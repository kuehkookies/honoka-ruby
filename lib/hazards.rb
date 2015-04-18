# ------------------------------------------------------
# Inanimated enemies goes by Hazard class.
# Dangerous by nature, it's neither Enemy nor Item nor
# Terrain.
# ------------------------------------------------------
class Hazard < GameObject
	traits :collision_detection, :timer, :velocity
	attr_reader :damage
	attr_accessor :zorder
	
	def self.descendants
		ObjectSpace.each_object(Class).select { |klass| klass < self }
	end
	
	def setup
		@player = parent.player
	end
	
	def die
		self.destroy
	end

	def update
		self.each_collision(@player) do |enemy, me|
			me.knockback(@damage) unless me.invincible # or (enemy.is_a? Enemy and enemy.hp <= 0)
		end
	end
end