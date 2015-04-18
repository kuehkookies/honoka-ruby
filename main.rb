require 'rubygems' rescue nil
require 'bundler/setup'
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
require 'texplay'
include Gosu
include Chingu

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*/*.rb'].each {|file| require file }

# ------------------------------------------------------
# Main process
# Everything started here.
# ------------------------------------------------------
class Game < Chingu::Window
	attr_accessor :level, :block, :lives, :hp, :maxhp, :ammo, :wp_level, :subweapon, :map, :transfer
	attr_accessor :bgm, :enemies, :hazards, :terrains, :bridges, :decorations, :items, :subweapons
	attr_accessor :paused, :waiting, :in_event, :passing_door
	attr_accessor :frame, :frame_last_tick
	
	def initialize
		super(640,480)
		
		@frame = 0
		@frame_last_tick = 0
		
		@bgm = nil
		@enemies = []
		@hazards = []
		@terrains = []
		@bridges = []
		@decorations = []
		@items = []
		@subweapons = []
		@paused = false
		@waiting = false
		@in_event = false
		@passing_door = false
		
		retrofy # THE classy command!
		setup_player
		setup_stage
		set_terrains
		set_enemies
		set_subweapons
		@transfer = true
		transitional_game_state(Transitional, :speed => 32)
		blocks = [
			[Level00, Level01]
		]
		@map = Map.new(:map =>blocks, :row => @level-1, :col => @block-1)
		switch_game_state(@map.current)
		self.caption = "Scene0"
	end

	def cache_assets
		Dir[File.dirname(__FILE__) + 'media/sfx/*.*'].each do |file| 
			Sound[file]
		end
		Dir[File.dirname(__FILE__) + 'media/bgm/*.*'].each do |file| 
			Song[file]
		end
		
		Font["runescape_uf_regular.ttf", 16]
	end
	
	def setup_stage
		@level = 1
		@block = 1 # 1
	end
	
	def reset_stage
		transferring
		setup_player
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
	
	def setup_player
		@hp = @maxhp = 16
		@ammo = 10
		@wp_level = 1
		@subweapon = :none
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
	
	def clear_cache
		@enemies = []
		@hazards = []
		@items = []
	end
	
	# def draw
	# 	scale(2) do
	# 	   super
	# 	end
	# end
	
	def update
		@frame += 1 unless @paused
		super
	end
end

# This is important.
Game.new.show
