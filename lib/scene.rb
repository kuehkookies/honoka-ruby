# ------------------------------------------------------
# Scenes
# What's happening in each blocks?
# ------------------------------------------------------
class Scene < GameState
	traits :viewport, :timer
	attr_reader :player, :terrain, :area, :backdrop, :hud

	def initialize
		super
		self.input = { :escape => :exit, :e => :edit, :r => :restart, :space => :pause }
		@backdrop = Parallax.new(:rotation_center => :top_left, :zorder => 10)
		@area = [0,0]
		@tiles = []
		@recorded_tilemap = nil
		@file = File.join(ROOT, "levels/#{self.class.to_s.downcase}.yml")
		$window.clear_cache
		player_start
		@hud = HUD.create(:player => @player) # if @hud == nil
		@player.sword = nil

		# Better to say this in Honoka's voice :D
		Honoka::Music.start!

		clear_game_terrains
		clear_subweapon_projectile
		game_objects.select { |game_object| !game_object.is_a? Player }.each { |game_object| game_object.destroy }
		load_game_objects(:file => @file) unless self.class.to_s == "Zero"
		for i in 0..$window.terrains.size
			@tiles += game_objects.grep($window.terrains[i])
		end
		for i in 0..$window.bridges.size
			@tiles += game_objects.grep($window.bridges[i])
		end
		for i in 0..$window.decorations.size
			@tiles += game_objects.grep($window.decorations[i])
		end
		game_objects.subtract_with(@tiles)
		after(15) { $window.stop_transfer }
		
		@hud.update
	end
	
	def draw
		@hud.draw unless @hud == nil
		# Draw the static tilemap all at once and ONLY once.
		@recorded_tilemap ||= $window.record 1, 1 do
			@tiles.each &:draw
		end
		@recorded_tilemap.draw 0, 0, 0

		super
	end
	
	def edit
		push_game_state(GameStates::Edit.new(:grid => [8,8], :classes => [Ball, Zombie, Ground, GroundTiled, GroundLower, GroundLoop, Brick, Brick_Loop, Brick_Loop_Back, Brick_Window, Brick_Window_Small, Bridge_Wood] ))
	end
	
	def clear_game_terrains
		@tiles.each {|me| me.destroy}
		$window.hazards.each {|me|me.destroy_all}
		$window.items.each {|me|me.destroy}
	end
	
	def clear_subweapon_projectile
		Sword.destroy_all
		$window.subweapons.each {|me|me.destroy_all}
	end
	
	def restart
		clear_subweapon_projectile
		clear_game_terrains
		$window.reset_stage
	end
	
	def pause
		$window.transfer
		$window.paused = true
		$window.frame_last_tick = $window.frame
		game_objects.each { |game_object| game_object.pause }
		push_game_state(Pause)
	end
	
	def player_start
		@player = Player.create
		@player.reset_state
	end
	
	def to_next_block
		clear_game_terrains
		@player.status = :blink
		@player.sword.die if @player.sword != nil
		$window.transfer
		#~ $window.block += 1
		switch_game_state($window.map.next_block)
		$window.block += 1
	end
	
	def to_next_level
		@player.status = :blink
		@player.sword.die if @player.sword != nil
		clear_game_terrains
		$window.transfer
		switch_game_state($window.map.next_level)
		$window.level += 1
		$window.block  = 1
	end
	
	def update
		game_objects.each { |game_object| game_object.unpause } if !$window.paused and !$window.transferring
		super
		@hud.update
		self.viewport.center_around(@player) unless $window.passing_door
		Knife.destroy_if {|knife| 
			knife.x > self.viewport.x + $window.width/2 or 
			knife.x < self.viewport.x or 
			self.viewport.outside_game_area?(knife)
		}
		Axe.destroy_if {|axe| 
			axe.y > self.viewport.y + $window.height/2 or 
			axe.x < self.viewport.x or 
			axe.x > self.viewport.x + $window.width/2
		}
		Rang.destroy_if {|rang| 
			(self.viewport.outside_game_area?(rang) or
				rang.x < self.viewport.x or 
				rang.x > self.viewport.x + $window.width/2
			) and rang.turn_back 
		}
		Torch.destroy_if {|torch| 
			self.viewport.outside_game_area?(torch) or
			torch.x < self.viewport.x or 
			torch.x > self.viewport.x + $window.width/2
		}
		if @player.y > self.viewport.y + $window.height/2 + (2*@player.height)
			@player.dead 
		end
	end
end