# ------------------------------------------------------
# Terrains
# When you need place to place your foot
# Also there's decorations and bridges
# ------------------------------------------------------

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

