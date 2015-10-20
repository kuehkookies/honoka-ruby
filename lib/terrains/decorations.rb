# ==================================================================================
# Class Decoration
#     part of Block
# 
# Not as solid as Solids and unlike the others, Decorations are passable by
# any means and useful only as decorations. Trees, rocks, buildings, you name it.
# 
# How to make Decoration:
#   Name the asset as 'block-<your_asset_name>'
#   Put your asset into gfx/tiles, and enroll the asset below as example.
#   
#   Example: 
#      If you have a bridge asset named block-tree, then the registered
#      name of the asset is: 
#                            class Tree < Decoration; end
# 
#      That's it. Don't forget the Decoration superclass' name
# ==================================================================================

class GroundBack < Decoration;  def setup; super; @color = Color.new(0xff808080); end; end
class Pillar < Decoration; end
class Pillar_Back < Decoration; end