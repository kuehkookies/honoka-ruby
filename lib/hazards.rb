# ==================================================================================
# Class Hazard
#     Part of GameObject
# 
# Here defined the logics for Hazard classes. Unlike items, Hazards are dangerous
# things an Actor (or Enemy) may suffer the consequences. 
#
# To define the stage and setting start point for Actor, make the stages 
# in /hazards folder. Leave this file as mother of all /hazards files.
#
# TODO: 
# Make a harmful Hazard option for enemies
# ==================================================================================
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