# ------------------------------------------------------
# Miscellaneous things
# TODO: separating animations and hazards
# ------------------------------------------------------
class Spark < GameObject
	traits :timer
	def setup
		@spark = Chingu::Animation.new( :file => "misc/spark.gif", :size => [15,15])
		@spark.delay = 20
		self.mode = :additive
		self.zorder = 400
		@image = @spark.first
	end
	
	def update
		@image = @spark.next
		after(4){destroy}
	end
end

class Misc_Flame < GameObject
	traits :timer
	def setup
		@fire = Chingu::Animation.new( :file => "misc/fire.gif", :size => [15,20])
		@fire.delay = 50
		self.zorder = 500
		@image = @fire.first
	end
	
	def update
		@image = @fire.next
		after(8){destroy}
	end
end