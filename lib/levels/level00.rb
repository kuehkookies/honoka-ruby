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
	def setup
		Orange::Music.set(0)
		super
		@area = [256, 160]
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		if $window.playing
			@player.x = 232
			@player.y = 132
			@player.y_flag = @player.y
		else
			$window.start_event
			@player.x = 52
			@player.y = -48
			after(1){
				@player.y_flag = @player.y
				$window.playing = true
				$window.stop_event
			}
		end
		self.viewport.center_around(@player)
		# @backdrop << {:image => "parallax/panorama1-1.png", :damping => 10, 
		# 						  :repeat_x => true, :repeat_y => false}
		# @backdrop << {:image => "parallax/bg1-1.png", :damping => 5, :repeat_x => true, 
		# 							:repeat_y => false}
	end
	
	def draw
		# @backdrop.draw
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width / 2) and @player.idle
			$window.start_transfer
			to_next_block
		end
				
		# @backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i 
		# @backdrop.update
	end
end