# ==================================================================================
# Class Ammo
#     Part of Items
# 
# Sample of collectibles which increase amount of Actor's ammo.
# ==================================================================================

class Ammo < Items
	def setup; super; @color = Color.new(0xff00ff00); end
	def die; @player.ammo += 1; @player.ammo = 99 if @player.ammo > 99; super; end
end