# ------------------------------------------------------
# Ghouls
# ------------------------------------------------------
class Zombie < Enemy
	trait :bounding_box, :scale => [0.5, 0.7], :debug => false
	def setup
		super
		@animations = Chingu::Animation.new(:file => "enemies/ghouls.png", :size => [32,32])
		@animations.frame_names = {
			:walk => 0..3,
			:attack => 4..5
		}
		@animations[:walk].delay = 150
		@animations[:walk].bounce = true
		@speed = 0.25
		@hp = 5
		@damage = 3
		@action = :idle
		@acceleration_y = Module_Game::Environment::GRAV_ACC
		@max_velocity = Module_Game::Environment::GRAV_CAP # 8
		@velocity_y = 2
		self.rotation_center = :bottom_center
		@image = @animations[:walk].first
		@factor_x = (-@gap_x/(@gap_x.abs).abs)*$window.factor
		cache_bounding_box
	end

	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			next if me.y > stone_wall.y
			if collision_at?(me.x, me.y)
				me.velocity_y = Module_Game::Environment::GRAV_WHEN_LAND
				me.y = stone_wall.bb.top - 1 
			end
		end
	end
	
	def update
		super
		land?
		destroy if self.parent.viewport.outside_game_area?(self)
		unless self.velocity_y > Module_Game::Environment::GRAV_WHEN_LAND or @invincible or die?
			@image = @animations[:walk].next
			@x += @speed*@factor_x
		end
		@image = @animations[:walk].first if @velocity_y > Module_Game::Environment::GRAV_WHEN_LAND
	end
	
	def die
		# pause!
		if @hp <= 0
			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
			@x += 0
			@y += 0
			@color.alpha = 128
			after(5){destroy}
		else
			@invincible = true
			after(Module_Game::INVULNERABLE_DURATION) { @invincible = false; } # unpause! }
		end
	end
end

class Ghoul < Enemy
	trait :bounding_box, :scale => [0.5, 0.7], :debug => false
	def setup
		super
		@animations = Chingu::Animation.new(:file => "enemies/ghouls.png", :size => [32,32])
		@color = Color.new(0xff88DD44)
		@sword = Ghoul_Sword.create(:x => @x+(3*-@factor), :y => (@y-12), :velocity => @direction, :factor_x => -@factor, :zorder => self.zorder + 1)
		@animations.frame_names = {
			:walk => 0..3,
			:attack => 4..5
		}
		@animations[:walk].delay = 150
		@animations[:walk].bounce = true
		@speed = 0.25
		@hp = 6
		@damage = 3
		@action = :idle
		@acceleration_y = Module_Game::Environment::GRAV_ACC
		@max_velocity = Module_Game::Environment::GRAV_CAP # 8
		@velocity_y = 2
		self.rotation_center = :bottom_center
		@image = @animations[:walk].first
		@factor_x = (-@gap_x/(@gap_x.abs).abs)*$window.factor
		cache_bounding_box
	end
		
	def land?
		self.each_collision(*$window.terrains) do |me, stone_wall|
			next if me.y > stone_wall.y
			if collision_at?(me.x, me.y)
				me.velocity_y = Module_Game::Environment::GRAV_WHEN_LAND
				me.y = stone_wall.bb.top - 1 
			end
		end
	end

	def attack
		self.x += 4 * self.factor_x
		@action = :attack
		@animations[:walk].reset
		#~ between(0,200){
		between(0,12){
			unless die?
				@image = @animations[:attack].first
				@sword.x, @sword.y = @x+(3*@sword.factor_x), @y-11
				@sword.factor_x = @factor_x
			end
		}.then{
			unless die?
				@image = @animations[:attack].last
				@sword.x, @sword.y = @x+(14*@sword.factor_x), @y-13
			end
		}
		#~ after(500){
		after(30){
			unless die?
				@image = @animations[:walk].first
				@sword.x, @sword.y = @x+(3*@sword.factor_x), @y-6
			end
		}
		#~ after(1000){@action = :walk unless die?}
		after(60){@action = :walk unless die?}
	end
	
	def update
		super
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		if @gap_x < 0 #and @action != :attack
			@factor_x = $window.factor unless @action == :attack
		else
			@factor_x = -$window.factor unless @action == :attack
		end
		
		land?
		destroy if self.parent.viewport.outside_game_area?(self)
		check_collision
		
		if @gap_x.abs < 40 and @gap_y.abs < 40
			attack unless @action == :attack
		end
		
		unless die? or @action == :attack
			@sword.x = @x+(3*@sword.factor_x)
			@sword.y = @y-6 if @velocity_y > Module_Game::Environment::GRAV_WHEN_LAND
			@sword.factor_x = @factor_x
		end
		
		if @action != :attack
			if (@x - @last_x).abs > 1
				@x += 0
				unless die? or @action == :attack
					@sword.x = @x+(3*@sword.factor_x)
					@sword.y = @y-6
					@sword.factor_x = @factor_x
				end
				#~ after(400){
				after(24){
					@last_x = @x
					@image = @animations[:walk].first if @velocity_y > Module_Game::Environment::GRAV_WHEN_LAND
				}
			else
				unless self.velocity_y > Module_Game::Environment::GRAV_WHEN_LAND or @invincible or @gap_x.abs < 32
					@image = @animations[:walk].next
					@x += @speed*@factor_x
				end
				@image = @animations[:walk].first if @velocity_y > Module_Game::Environment::GRAV_WHEN_LAND
			end
		end
	end
	
	def die
		# pause!
		if @hp <= 0
			Misc_Flame.create(:x => self.x-6*self.factor_x, :y => self.y-(self.height/4) )
			after(1){ Misc_Flame.create(:x => self.x+6*self.factor_x, :y => self.y-(self.height)/2) }
			after(3){ Misc_Flame.create(:x => self.x, :y => self.y-(self.height*6/10))}
			i = rand(2)
			case i
				when 1
				Ammo.create(:x => self.x, :y => self.y)
			end
			@sword.die
			@x += 0
			@y += 0
			@color.alpha = 128
			after(24){destroy}
		else
			@invincible = true
			after(Module_Game::INVULNERABLE_DURATION) { @invincible = false; } # unpause! }
		end
	end
end