class Level00 < Scene
	def initialize
		$window.bgm = Sound["bgm/sol_morrington's theme.ogg"]
		super
		@area = [512, 240]
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		self.viewport.y = 64
		@player.x = 64
		@player.y = 240
		@player.y_flag = @player.y
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
		if @player.x >= @area[0]-(@player.bb.width) - 2 and @player.idle # and !$window.waiting
			$window.in_event = true
			@player.move(2,0)
			if @player.x >= @area[0] + 32
				to_next_block; $window.in_event = false
			end
		end
				
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i 
		@backdrop.update
	end
end