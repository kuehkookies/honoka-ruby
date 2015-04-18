# ==================================================================================
# Class Block
#     also known as: Terrains
# 
# Blocks are base for any levels, where the Actors, Enemies even sceneries set
# their foot on and wander around. Simply, Blocks is a main part of ZA WARUDO.
# 
# The Blocks are divided into three parts:
# - Solid:      Solid blocks which mainly impassable and helps shape the scenes.
#               Things like soils, bricks, walls goes here.
# - Bridge:     As solid as previous one, but can be passable in certain fashion.
#               Consider a... yeah, bridge.
# - Decoration: Almost-useless blocks fall in this categories. It is said on the 
#               label, Decoration has... decorative purposes (d'oh)
#
# Refer to /terrains folder to make Blocks. Leave this file as mother of all the
# objects in there.
# ==================================================================================

class Block < GameObject
  trait :bounding_box, :scale => [1,0.9], :debug => false
  trait :collision_detection
  
  def self.solid
    all.select { |block| block.alpha == 128 }
  end

  def self.inside_viewport
    all.select { |block| block.game_state.viewport.inside?(block) }
  end

  def self.descendants
	  ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

  def setup
    @image = Image["tiles/block-#{self.filename}.png"]
    cache_bounding_box
  end

  def update; end
end

class Solid < Block; end
class Bridge < Block; end
class Decoration < Block; end

