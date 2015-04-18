class Item_Sword < Items
	def setup; super; end
	def die
		unless @player.status == :hurt
			super
			$window.wp_level += 1
			@player.weapon_up unless $window.wp_level > 3
		end
	end
end

class Item_Knife < Items
	def setup; super; end
	def die; super; $window.subweapon = :knife; end
end

class Item_Axe < Items
	def setup; super; end
	def die; super; $window.subweapon = :axe; end
end

class Item_Rang < Items
	def setup; super; end
	def die; super; $window.subweapon = :rang; end
end