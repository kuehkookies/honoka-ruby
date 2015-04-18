# ==================================================================================
# Class Level00
#     Part of Scene
# 
# Sample stage with multiple backdrops, and a transition when Actor reaches the
# endmost of the stage.
#
# Once reached the transition point, Actor will be transferred into next block, 
# calling Scene superclass method.
# ==================================================================================

class Level00 < Scene
	def initialize
		Honoka::Music.set(0)

		super
		@area = [512, 240]
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		self.viewport.y = 0
		@player.x = 64
		@player.y = 240
		@player.y_flag = @player.y
		@backdrop << {:image => "parallax/panorama1-1.png", :damping => 10, 
								  :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/bg1-1.png", :damping => 5, :repeat_x => true, 
									:repeat_y => false}
		update
	end
	
	def draw
		@backdrop.draw
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width) - 2 and @player.idle
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