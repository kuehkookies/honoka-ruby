# ==================================================================================
# Working Modules(TM)
#     part of Orange Core
# 
# Here incorporated the base logics and modules for Orange, also some overrides for
# existing modules provided by Gosu and Chingu.
# ==================================================================================

module Orange
  # --------------------------------------------------------------------------------
  # Basic settings
  # Gravities and duration of invulnerability
  # --------------------------------------------------------------------------------
	module Environment
		GRAV_CAP = 8
		GRAV_ACC = 0.4
		GRAV_WHEN_LAND = 1

    POS_RECORD_INTERVAL = 1
	end
	
	INVULNERABLE_DURATION = 24
	ALLOWED_SUBWEAPON_THROWN = 1

  # --------------------------------------------------------------------------------
  # Music module, which later will be separated and known as MusicManager (Maki)
  # TODO: 
  # - Make music library. Maki, your job.
  # - Make the music loopable
  # - Incorporate fade-in and fade-out effect
  # - Make variable sound volume
  # --------------------------------------------------------------------------------
  class Music
  	BGM =[
      "sol_morrington's theme",
  		"level03-binding",
  		"Gears_and_Chains"
  	]

    @current_bgm = nil

    def self.set(index)
      $window.bgm = Song["bgm/" + BGM[index] + ".ogg"]
    end

    def self.start!; start; end
    def self.start
      return if $window.bgm.nil?
      return if @current_bgm == $window.bgm
      $window.bgm.play true
      @current_bgm = $window.bgm
    end

    def self.stop
      $window.bgm.stop
    end
  end
end


# ==================================================================================
# Chingu overrides
# These are here to make Orange runs the game properly. 
# Maybe known later as CoreOverrides, part of SystemRules (Umi)
# ==================================================================================
module Chingu
	class GameObjectList
		def grep(*object)
			result = @game_objects.grep(*object)
			return result
		end
		def subtract_with(object)
			@game_objects -= object
		end
	end

	class Viewport
		def center_around(object)
			self.x = object.x - ($window.width/2) / 2
			self.y = object.y - ($window.height/2) / 2
		end
		def x=(x)
			@x = x
      l_edge = @game_area.x
      r_edge = @game_area.width-$window.width/2
			if @game_area
				@x = @game_area.x                     if @x < l_edge
				@x = @game_area.width-$window.width/2 if @x > r_edge
			end 
		end

		def y=(y)
			@y = y
      u_edge = @game_area.y
      d_edge = @game_area.height-$window.height/2
			if @game_area
				@y = @game_area.y                       if @y < u_edge
				@y = @game_area.height-$window.height/2 if @y > d_edge
			end
		end
	end

  module Traits
    module Timer
      # ----------------------------------------------------------------------------
      # Executes block each update during frames
      # ----------------------------------------------------------------------------
      def during(time, options = {}, &block)
        if options[:name]
          return if timer_exists?(options[:name]) && options[:preserve]
          stop_timer(options[:name])
        end

        ms = $window.frame # Gosu::milliseconds()
        @_last_timer = [options[:name], ms, ms + time, block]
        @_timers << @_last_timer
        self
      end
      
      # ----------------------------------------------------------------------------
      # Executes block after update during frames
      # ----------------------------------------------------------------------------
      def after(time, options = {}, &block)
        if options[:name]
          return if timer_exists?(options[:name]) && options[:preserve]
          stop_timer(options[:name])
        end

        ms = $window.frame # Gosu::milliseconds()
        @_last_timer = [options[:name], ms + time, nil, block]
        @_timers << @_last_timer
        self
      end

      # ----------------------------------------------------------------------------
      # Executes block each update during 'start_time' and 'end_time'
      # ----------------------------------------------------------------------------
      def between(start_time, end_time, options = {}, &block)
        if options[:name]
          return if timer_exists?(options[:name]) && options[:preserve]
          stop_timer(options[:name])
        end

        ms = $window.frame # Gosu::milliseconds()
        @_last_timer = [options[:name], ms + start_time, ms + end_time, block]
        @_timers << @_last_timer
        self
      end

      # ----------------------------------------------------------------------------
      # Executes block every 'delay' milliseconds
      # ----------------------------------------------------------------------------
      def every(delay, options = {}, &block)
        if options[:name]
          return if timer_exists?(options[:name]) && options[:preserve]
          stop_timer(options[:name])
        end
        
        ms = $window.frame # Gosu::milliseconds()
        @_repeating_timers << [options[:name], ms + delay, delay, 
                              options[:during] ? ms + options[:during] : nil, block]
        if options[:during]
          @_last_timer = [options[:name], nil, ms + options[:during]]
          return self
        end
      end

      # ----------------------------------------------------------------------------
      # Executes block after the last timer ends
      # ...use one-shots start_time for our trailing "then".
      # ...use durable timers end_time for our trailing "then".
      # ----------------------------------------------------------------------------
      def then(&block)
        start_time = @_last_timer[2].nil? ? @_last_timer[1] : @_last_timer[2]
        @_timers << [@_last_timer[0], start_time, nil, block]
      end

      # ----------------------------------------------------------------------------
      # See if a timer with name 'name' exists
      # ----------------------------------------------------------------------------
      def timer_exists?(timer_name = nil)
        return false if timer_name.nil?
        @_timers.each { |name, | return true if timer_name == name }
        @_repeating_timers.each { |name, | return true if timer_name == name }
        return false
      end

      # ----------------------------------------------------------------------------
      # Stop timer with name 'name'
      # ----------------------------------------------------------------------------
      def stop_timer(timer_name)
        @_timers.reject! { |name, start_time, end_time, block| timer_name == name }
        @_repeating_timers.reject! { |name, start_time, end_time, block| 
          timer_name == name }
      end
      
      # ----------------------------------------------------------------------------
      # Stop all timers
      # ----------------------------------------------------------------------------
      def stop_timers
        @_timers.clear
        @_repeating_timers.clear
      end
      
      def update_trait
        ms = $window.frame # Gosu::milliseconds()
        
        @_timers.each do |name, start_time, end_time, block|
          block.call if ms > start_time && (end_time == nil || ms < end_time)
        end
                
        index = 0
        @_repeating_timers.each do |name, start_time, delay, end_time, block|
          if ms > start_time
            block.call  
            @_repeating_timers[index] = [name, ms + delay, delay, end_time, block]
          end
          if end_time && ms > end_time
            @_repeating_timers.delete_at index
          else
            index += 1
          end
        end

        # Remove one-shot timers (only a start_time, no end_time) and all 
        # timers which have expired
        @_timers.reject! { |name, start_time, end_time, block| 
          (ms > start_time && end_time == nil) || (end_time != nil && ms > end_time) 
        }
      
        super
      end
      
    end
  end
end


# ==================================================================================
# Map class
# 
# Provides proper mapping rules of each stages. The map is in nested array format.
# Maybe known later as MapManager, part of SystemRules (Umi)
# ==================================================================================

class Map
  attr_reader :row, :col
  attr_reader :width, :height
  attr_accessor :map
  
  def initialize(options = {})
    @row = options[:row] || 0
    @col = options[:col] || 0    
    @map = options[:map] || [ [ ] ] 
  end

  def create_tiles(area, tiles)
    # The navmesh of every area created here.
    # Each point is always initialized with value 1 (free), and checked whether there is an obstacle such
    # as wall or any other impassable objects. Here also cited the index for jump point and platform edges.
    
    width = area[0] / 16 + 1
    height = area[1] / 16 + 1
    @width = width; @height = height
    has = Array.new(height) {Array.new(width) { 1 }}
    name = []
    $window.enemies.each do |enemy|
      name.push enemy.class.name
    end
    name.uniq!
    tiles.each do |tile|
      clas = Object.const_get(tile.keys[0]).to_s
      next if name.include?(clas)
      x = (tile.values[0].values_at(:x)[0] / 16).to_i
      y = (tile.values[0].values_at(:y)[0] / 16).to_i
      has[y][x] = 0
    end
    
    # And here the magic happens. To identify the jumping point, platform edges and free walkable
    # paths, the navmesh will be reindexed depends on the tiles below.
    # The index are:
    #      0 = impassable
    #      1 = passable, default
    #      2 = passable, left edge
    #      3 = passable, right edge
    #      4 = passable, solo tile

    # Initialize the iteration flag
    platformstart = false
    has.each_with_index do |row, id|
      row.each_with_index do |col, id2|
        # We skip the topmost row; either it will be solid blocked, or it's free.
        next if id == 0
        if platformstart
          # We start calculate the navlinks here.
          # Every navlink identified will fall into impassable if there is another
          # block on top of it; making itself flagged as impassable
          if has[id][id2] == 0 and has[id][id2-1] != 0
            # Identify the leftmost platform edge
            has[id-1][id2] = 2 unless id2 >= has[id].size - 1
            has[id-1][id2] = 0 if has[id-2][id2] != 1
          elsif has[id][id2] == 0 and has[id][id2+1] != 0
            # Identify the rightmost platform edge
            has[id-1][id2] = 3 unless id2 >= has[id].size - 1
            has[id-1][id2] = 0 if has[id-2][id2] != 1
          end
          if has[id-1][id2] == 1 and has[id][id2] == 0
            # Identify the corners of every platform, either left or right.
            # Every navlink identified will fall into impassable if there is another
            # block on top of it; making itself flagged as impassable, too
            if has[id-1][id2-1] == 0
              has[id-1][id2] = 2 if has[id-2][id2] == 1
              has[id-1][id2] = 0 if has[id-2][id2] != 1
            elsif has[id-1][id2+1] == 0
              has[id-1][id2] = 3 if has[id-2][id2] == 1
              has[id-1][id2] = 0 if has[id-2][id2] != 1
            end
          end
          if has[id-1][id2] == 2 and (has[id][id2+1] != 0 or has[id-1][id2] == 0)
            # If the navlink has no neighboring passable navlinks, it will identify itself
            # as a solo navlink, stood on its own with pride and dignity
            has[id-1][id2] = 4 if has[id-2][id2] == 1
            has[id-1][id2] = 0 if has[id-2][id2] != 1
          end
          # Reset the iteration to next row
          platformstart = false if id2 >= has[id].size - 1
        else
          # The first column of every rows identified here.
          # Depending on the blocks, it could be identified as leftmost navlink
          # or impassable.
          has[id][id2] = 0
          has[id][id2] = 2 if has[id][id2] == 1
          # Flag the iteration so it repeats another code instead of this
          platformstart = true
        end
      end
    end

    on_platform = false
    has.each_with_index do |row, id|
      row.each_with_index do |col, id2|
        has[id][id2] = 3 if id2 >= has[id].size - 1 and on_platform
        has[id][id2] = 4 if has[id][id2] == 2 and has[id][id2-1] == 0 and has[id][id2+1] == 0
        on_platform = true if has[id][id2] == 2
        on_platform = false if has[id][id2] == 3 or id2 == row.size - 1
        has[id][id2] = 0 if has[id][id2] == 1 and (not on_platform or has[id][id2-1] == 0)
        # has[id-1][id2] = 0 if has[id][id2] == 2
      end
    end

    name = current.to_s.downcase!
    f = File.new("lib/levels/#{name}.map", "w")
    for i in 0...height
      n = has[i].join(",")
      f.puts n
    end
    f.close   

    return has
  end
  
  def current
    @map[@row][@col] rescue nil
  end

  def current_level
    @row rescue nil
  end
  
  def current_block
    @col rescue nil
  end

  def first_block
    @col = 0
    @map[@row][@col] rescue nil
  end
    
  def next_block
    @col += 1
    current
  end

  def prev_block
    @col -= 1
    current
  end

  def next_level
    @col = 0
    @row += 1
    current
  end

  def prev_level
    @col = 0
    @row -= 1
    current
  end

end