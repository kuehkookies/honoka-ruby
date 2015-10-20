# ==================================================================================
# Class Solid
#     part of Block
# 
# There will always be a place to stand, crouch, even die. Solids provide its
# usefulness as a base of any levels (unless you're making a space level, yes.)
# It's impassable by nature, so use this as walls or ceilings, too.
# 
# How to make Solid:
#   Name the asset as 'block-<your_asset_name>'
#   Put your asset into gfx/tiles, and enroll the asset below as example.
#   
#   Example: 
#      If you have a bridge asset named block-soil, then the registered
#      name of the asset is: 
#                            class Soil < Solid; end
# 
#      That's it. Don't forget the Solid superclass' name
# ==================================================================================

class Brick < Solid; end

class Door < GameObject
	trait :bounding_box, :scale => [1, 1],:debug => false
	traits :collision_detection, :timer, :velocity
	def setup
		@door = Chingu::Animation.new( :file => "misc/door.gif", :size => [64,48])
		@image = @door.first
		cache_bounding_box
		self.rotation_center = :bottom_center
	end
end