# ==================================================================================
# Class HUD
#     Part of GameObject
# 
# Heads-up Display. Player needs to know informations like scores, Actor's weapons,
# time, and stuffs.
# This is a sample in horizontally-aligned Castlevanian style HUD
# ==================================================================================

class HUD < GameObject
	attr_reader :gap, :rect
	def initialize(options={})
		super
		@player = options[:player] || parent.player
		@x = options[:x]; @y = options[:y]
		@old_hp = $window.maxhp
		@image = Image["misc/hud.gif"]
		get_subweapon
		@ammo = Text.new($window.ammo, :x => 27, :y => 30, :zorder => 300, 
										 :align => :right, :max_width => 12, :size => 12, 
										 :color => Color.new(0xFFDADADA), :factor => 1)
		@rect = Rect.new(32,16,84*$window.hp/$window.maxhp,5)
		@gap = (@rect.width - 168*$window.hp/$window.maxhp).to_f
	end
	
	def draw
		@image.draw(8,8,300)
		@sub.draw(12,12,299) unless @sub == nil
		@ammo.draw
		parent.fill_gradient(:from => Color.new(255,20,20), :to => Color.new(160,20,20), 
			:rect => @rect, :orientation => :vertical, :zorder => 290 )
	end
		
	def get_subweapon
		if $window.subweapon == :none
			@sub = nil
		else
			@sub = Image["misc/hud_#{$window.subweapon}.gif"] 
		end
	end
	
	def update
		get_subweapon
		@ammo.text = $window.ammo.to_s unless $window.ammo.to_s == @ammo.text
		unless @rect.width <= 84*$window.hp/$window.maxhp
			@rect.width -= 1 # if @gap <= 2
		end
		unless @rect.width >= 84*$window.hp/$window.maxhp and !@resetter
			@rect.width += 1 # if @gap >= -2hp
		end
		if @resetter 
			@old_hp = $window.maxhp; @rect.width = 84; 
			@resetter = false
		end
	end
end