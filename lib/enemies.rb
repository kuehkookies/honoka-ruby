# ==================================================================================
# Class Enemies
#     Part of GameObject
# 
# Here defined the base logics for enemies, also some other functions like hazardous
# flag and invincibility flag.
#
# To create and define enemies, make it in /enemies folder. Leave this file as 
# mother of all /enemies files.
# ==================================================================================

class Enemy < GameObject
	traits :collision_detection, :effect, :velocity, :timer
	attr_reader :invincible, :hp, :damage, :harmful
	
	def self.descendants
		ObjectSpace.each_object(Class).select { |klass| klass < self }
	end
	
	def setup
		@player = parent.player
		@invincible = false
		@harmful = true
		@hardened = false
		@hp = 0
		@damage = 0
		self.zorder = 200
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		@last_x, @last_y = @x, @y
	  $window.enemies << self
	end
	
	def hit(weapon, x, y, side)
		unless die?
			y -= 16 if weapon.is_a? Torch_Fire
			Spark.create(:x => x, :y => y, :angle => rand(30)*side)
			Sound["sfx/hit.wav"].play(0.5) if !@hardened
			Sound["sfx/klang.wav"].play(0.3) if @hardened
			@hp -= weapon.damage
			die
		end
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y)
		destroy
		$window.enemies.delete(self) rescue nil
	end
	
	def die?
		return @hp <= 0
	end
	
	def destroyed?
		return true if self == nil
	end
	
	def harmful?
		return @harmful
	end
	
	def land?
	end
	
	def check_collision
		self.each_collision(Sword, *$window.subweapons) do |enemy, weapon|
			if collision_at?(enemy.x, enemy.y)
				unless enemy.invincible
					if !weapon.is_a?(Sword)
						enemy.hit(weapon, weapon.x, weapon.y, weapon.factor_x*30)
					else
						enemy.hit(weapon, weapon.x - (weapon.x - enemy.x) - (weapon.factor_x*(enemy.width/4)), weapon.y - (weapon.y - enemy.y) - (enemy.height*3/5), weapon.factor_x*30) # unless weapon.is_a?(Torch) and weapon.on_ground
					end
					weapon.lit_fire if weapon.is_a?(Torch) and not die?
					weapon.die if weapon.is_a?(Knife) and !@hardened
					weapon.deflect if weapon.is_a?(Axe) or weapon.is_a?(Knife) and @hardened
				end
			end
		end
		if @harmful
			self.each_collision(@player) do |enemy, me|
				if collision_at?(enemy.x, enemy.y)
					me.knockback(@damage) unless me.invincible or enemy.die?
				end
			end
		end
	end
	
	def update
		@velocity_y = Orange::Environment::GRAV_CAP if @velocity_y > Orange::Environment::GRAV_CAP
		check_collision
	end
end