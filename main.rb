require 'rubygems' rescue nil
require 'bundler/setup'
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
require 'texplay'
include Gosu
include Chingu

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*/*/*.rb'].each {|file| require file }

include AStar

SCALE = 1

# ==================================================================================
# Main stage is here!
#
# The main process of the game. Also provided in this main process the timer logic,
# event handler and caching processes.
# ==================================================================================

class Game < Chingu::Window
	attr_accessor :level, :block, :lives, :hp, :maxhp, :ammo, :wp_level, :subweapon, 
								:map, :transfer
	attr_accessor :bgm, :enemies, :hazards, :terrains, :bridges, :decorations, 
								:items, :subweapons
	attr_accessor :paused, :waiting, :passing_door, :playing
	attr_accessor :frame, :frame_last_tick
	attr_accessor :selected_actor, :actor_temp_data
	attr_reader   :minute, :second
	attr_reader   :in_event
	
	def initialize
		super(800,600)
		
		@frame = 0
		@frame_last_tick = 0
		
		@selected_actor = nil
		@actor_temp_data = []

		@second = 0
		@minute = 0

		@bgm = nil
		@enemies = []
		@hazards = []
		@terrains = []
		@bridges = []
		@decorations = []
		@items = []
		@subweapons = []
		@playing = false
		@paused = false
		@waiting = false
		@in_event = false
		@passing_door = false
		
		retrofy # THE classy command!
		setup_stage
		set_actor(Runner)
		set_terrains
		set_enemies
		set_subweapons
		@transfer = true
		transitional_game_state(Transitional, :speed => 32)
		blocks = [
			[Level01, Level01]
		]
		@map = Map.new(:map =>blocks, :row => @level-1, :col => @block-1)
		switch_game_state(@map.current)
		self.caption = "Pangaburan 0.2"
	end

  # --------------------------------------------------------------------------------
  # This is believed to cache all assets, lightening up the game's processes.
  # --------------------------------------------------------------------------------
	def cache_assets
		Dir[File.dirname(__FILE__) + 'media/sfx/*.*'].each do |file| 
			Sound[file]
		end
		Dir[File.dirname(__FILE__) + 'media/bgm/*.*'].each do |file| 
			Song[file]
		end
		
		Font["runescape_uf_regular.ttf", 16]
	end

	def start_event
		@in_event = true
	end	

	def stop_event
		@in_event = false
	end	
	
	def reset_stage
		transferring
		switch_game_state($window.map.first_block)
		@block = 1
	end
	
	def transferring
		@transfer == true
	end
	
	def start_transfer
		@transfer = true
	end
	
	def stop_transfer
		@transfer = false
	end
	
	def reset_frame
		@frame = 0
	end
	
	def set_actor(character)
		@selected_actor = character
	end

	def setup_stage
		@level = 1
		@block = 1 # 1
	end

	def set_terrains
		@terrains = Solid.descendants
		@bridges = Bridge.descendants
		@decorations = Decoration.descendants
		@items = Items.descendants
	end
	
	def set_enemies
		@enemies = Enemy.descendants
		@hazards = Hazard.descendants
	end
	
	def set_subweapons
		@subweapons = Subweapons.descendants
	end

	def make_temp_data(actor)
		@actor_temp_data = [
				actor.hp,
				actor.ammo,
				actor.level,
				actor.damage, 
				actor.subweapon,
				actor.factor_x
			]
	end
	
	def clear_temp_data
		@actor_temp_data.clear
	end

	def clear_terrains
		@terrains.clear
		@bridges.clear
		@decorations.clear
	end

	def clear_cache
		@enemies.clear
		@hazards.clear
		@items.clear
	end

	def get_time
		sec = (@frame % 60).to_i
		min = (@frame % 3600).to_i
		@second += 1 if sec == 0 and @frame > 59
		if min == 0 and @frame > 3599
			@minute += 1 
			@second = 0
		end
	end
	
	def draw
		scale(SCALE) do
		   super
		end
	end
	
	def update
		unless @paused
			@frame += 1 
			get_time
		end
		super
	end
end

# ==================================================================================
# Show on!
# ==================================================================================
Game.new.show
