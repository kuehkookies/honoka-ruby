# ==================================================================================
# Class Raven
#     Part of Enemy
# 
# Here is sample of harmful enemy with absolute passability, meaning it can through
# walls and solids. Also, this demonstrates a flying-type enemy.
# ==================================================================================
class Raven < Enemy
	trait :bounding_box, :debug => false
	
	def setup
		super
		@animations = Chingu::Animation.new( :file => "enemies/raven.png", :size => [16,16])
		@animations.frame_names = {:idle => 0..0, :flutter => 1..3}
		@image = @animations[:idle].first
		@max_velocity = 5
		@acceleration_y = 0
		@hp = 1
		@damage = 2
		cache_bounding_box
		wait
	end
	
	def wait
		self.velocity_x = 0
		self.velocity_y = 0
		self.factor_x = (-@gap_x/(@gap_x.abs).abs)*$window.factor
		unless @flutter != nil
		every(5){ 
			if @gap_x > -150 and @gap_x < 150 and @flutter == nil
				during(2) { @image = @animations[:flutter].next; self.velocity_x = 0.5*self.factor; self.velocity_y = -0.5 }.then {flutter}
			end
			}
		end
	end
	
	def dive(flip, dist, alt)
		return if die?
		dist_scale = (dist/20)
		alt_scale = (alt/20)
		dist_scale = 3 if dist_scale.abs.to_i < 3
		self.velocity_x = dist_scale.abs.to_i < 4 ? dist_scale.abs*flip : 4*flip
		self.velocity_x *= -1
		self.velocity_y = alt_scale.abs.to_i < 4 ? alt_scale.abs : 4
		during(60) { @image = @animations[:flutter].first; self.velocity_y -= 0.1; self.velocity_y = -3 if self.velocity_y < -3 }.then {flutter}
	end
	
	def flutter
		return if die?
		@flutter = true
		if @flutter
			self.velocity_x = 0
			self.velocity_y = 0
				every(3) {
				@gap_x = @x - @player.x
				@gap_y = @y - @player.y
				@gap_x = self.factor_x if @gap_x == 0
				self.factor_x = (-@gap_x/(@gap_x.abs).abs)*$window.factor
			}
			after(30) { @flutter = false;	dive(-self.factor_x, @gap_x, @gap_y) }
		end
	end
	
	def update
		super
		unless @flutter != nil
			@gap_x = @x - @player.x
			@gap_y = @y - @player.y
		end
		@image = @animations[:flutter].next if @flutter
		@image = @animations[:flutter].first if !@flutter
		@image = @animations[:idle].first if @flutter == nil
		destroy if self.parent.viewport.outside_game_area?(self)
		check_collision
	end
	
	def die
		if die?
			@flutter = false
			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
			self.velocity_x = 0 if self.velocity_x != 0 
			self.velocity_y = 0 if self.velocity_y != 0 
			self.collidable = false
			self.factor_y = -$window.factor
			# self.velocity_x = self.velocity_x
			self.velocity_y = 2
			self.velocity_x = 0.2*-self.factor
			@acceleration_y = 0
			i = rand(2)
			case i
				when 1
				Ammo.create(:x => self.x, :y => self.y)
			end
			after(20) {
				destroy
			}
		end
	end
end