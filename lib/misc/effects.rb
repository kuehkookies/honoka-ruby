# ==================================================================================
# Useful effects
#     Part of GameObject
# 
# Useful objects to add more fancy in certain segments. Here are sample of
# animation effects when enemies got hit and when they're dead.
#
# What else Orange needs when on stage? :P
# ==================================================================================

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