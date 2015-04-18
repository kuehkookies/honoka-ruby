# ==================================================================================
# Class Drops
#     Part of Items
# 
# Here is sample of collectibles which change Actor's subweapons. 
# ==================================================================================

class Item_Sword < Items
	def setup; super; end
	def die
		unless @player.status == :hurt
			super
			@player.level += 1
			@player.weapon_up unless @player.wp_level > 3
		end
	end
end

class Item_Knife < Items
	def setup; super; end
	def die; super; @player.subweapon = :knife; end
end

class Item_Axe < Items
	def setup; super; end
	def die; super; @player.subweapon = :axe; end
end

class Item_Rang < Items
	def setup; super; end
	def die; super; @player.subweapon = :rang; end
end