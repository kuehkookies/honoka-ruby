class Level01 < Scene
	def setup		
		super
		@area = [512,192]
		@player.x = 32 # self.viewport.x+(@player.bb.width/2)+16 # 32
		@player.y = 136 # 246
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		self.viewport.center_around(@player)
	end
	
	def draw
		super
	end
	 
	def update
		super
		if @player.x <= 8 and @player.idle
			$window.start_transfer
			to_prev_block
		end
	end
end