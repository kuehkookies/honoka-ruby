class Level01 < Scene
	def initialize		
		super
		@area = [320,368]
		@player.x = 16 # self.viewport.x+(@player.bb.width/2)+16 # 32
		@player.y = 296 # 246
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		self.viewport.y = 80
		@backdrop << {:image => "parallax/panorama1-1.png", :damping => 10, :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/bg1-1.png", :damping => 5, :repeat_x => true, :repeat_y => false}
		update
	end
	
	def draw
		@backdrop.draw
		super
	end
	 
	def update
		super
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.update
	end
end