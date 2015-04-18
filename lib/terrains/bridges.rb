# ==================================================================================
# Class Bridge
#     part of Block
# 
# A specific block which acts like Solids, but with special passable trait.
# Actor can jump through the bridges from below, or simply slip off the bridge. 
# Useful for making passable tiles or... guess?
# 
# How to make Bridge:
#   Name the asset as 'block-bridge_<your_asset_name>'
#   Put your asset into gfx/tiles, and enroll the asset below as example.
#   
#   Example: 
#      If you have a bridge asset named block-bridge_wooden, then the registered
#      name of the asset is: 
#                            class BridgeWooden < Bridge; end
# 
#      That's it. Don't forget the Bridge superclass' name
# ==================================================================================

class Bridge_Wood < Bridge; end
class BridgeGray < Bridge; end
class BridgeGrayLeft < Bridge; end
class BridgeGrayRight < Bridge; end
class BridgeGrayMid < Bridge; end