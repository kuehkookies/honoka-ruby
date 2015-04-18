# ==================================================================================
# Class Ball
#     Part of Enemy
# 
# Here is sample of unharmful enemy which drops loot when killed. Akin to candles
# in Castlevania, or treasure boxes in Duck Tales.
# 
# Loots should be an Item, but there is no exception for another thing like Enemy
# to appear when it's killed.
# ==================================================================================

class Ball < Enemy
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@damage = 1
		@harmful = false
		cache_bounding_box
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y-(self.height/2))
		after(2){ 
			self.collidable = false
			destroy
			i = rand(1)
			case i
				when 0
				Ammo.create(:x => self.x, :y => self.y)
			end
		} 
	end
	
	def update
		check_collision
	end
end

class Ball_Knife < Ball
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@color = Color.new(0xff00bbff)
		cache_bounding_box
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y-(self.height/2))
		after(2){ 
			self.collidable = false
			destroy
			Item_Knife.create(:x => self.x, :y => self.y)
		}
	end
end

class Ball_Axe < Ball
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@color = Color.new(0xffbb00ff)
		cache_bounding_box
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y-(self.height/2))
		after(2){ 
			self.collidable = false
			destroy
			Item_Axe.create(:x => self.x, :y => self.y)
		}
	end
end

class Ball_Sword < Ball
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@color = Color.new(0xffbbffff)
		cache_bounding_box
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y-(self.height/2))
		after(2){ 
			self.collidable = false
			destroy
			Item_Sword.create(:x => self.x, :y => self.y)
		}
	end
end

class Ball_Rang < Ball
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@color = Color.new(0xffbbff00)
		cache_bounding_box
	end
	
	def die
		Misc_Flame.create(:x => self.x, :y => self.y-(self.height/2))
		after(2){ 
			self.collidable = false
			destroy
			Item_Rang.create(:x => self.x, :y => self.y)
		}
	end
end