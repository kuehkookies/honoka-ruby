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

class Ground < Solid; end
class GroundLower < Solid; end
class GroundLoop < Solid; end
class GroundTiled < Solid; end
class Brick < Solid; end
class Brick_Loop < Solid; end