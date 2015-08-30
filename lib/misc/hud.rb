# ==================================================================================
# Class HUD
#     Part of GameObject
# 
# Heads-up Display. Player needs to know informations like scores, Actor's weapons,
# time, and stuffs.
# This is a sample in horizontally-aligned Castlevanian style HUD
# ==================================================================================

class HUD < GameObject
	traits :timer
	attr_reader :gap, :rect
	def initialize(options={})
		super
		@player = options[:player] || parent.player
		@x = options[:x]; @y = options[:y]
		@old_hp = @player.maxhp
		@image = Image["misc/hud.gif"]
		get_subweapon
		get_time
		@second = @minute = 0
		@time = Text.new("#{@minute} : #{@second}", :x => $window.width / 2 - 112, :y => 16, 
										 :align => :right, :max_width => 108, :size => 12, 
										 :color => Color.new(0xFFDADADA), :factor => 1)
		@ammo = Text.new(@player.ammo, :x => 27, :y => 30, :zorder => 300, 
										 :align => :right, :max_width => 12, :size => 12, 
										 :color => Color.new(0xFFDADADA), :factor => 1)
		@level = Text.new("Stage #{$window.level} - #{$window.block}",
										 :x => $window.width / 2 - 64, :y => $window.height / 2 - 16, 
										 :zorder => 500, 
										 :align => :right, :max_width => 60, :size => 12, 
										 :color => Color.new(0xFFDADADA), :factor => 1)
		@rect = Rect.new(32,16,84*@player.hp/@player.maxhp,5)
		@gap = (@rect.width - 168*@player.hp/@player.maxhp).to_f
	end
	
	def draw
		@image.draw(8,8,300)
		@sub.draw(12,12,299) unless @sub == nil
		@ammo.draw
		@time.draw
		@level.draw
		parent.fill_gradient(:from => Color.new(255,20,20), :to => Color.new(160,20,20), 
			:rect => @rect, :orientation => :vertical, :zorder => 290 )
	end
		
	def get_subweapon
		if @player.subweapon == :none
			@sub = nil
		else
			@sub = Image["misc/hud_#{@player.subweapon}.gif"] 
		end
	end

	def get_time
		sec = ($window.frame / 60).to_i
		@second = sec
	end
	
	def update
		get_subweapon
		get_time
		@ammo.text = @player.ammo.to_s unless @player.ammo.to_s == @ammo.text
		@time.text = "#{@minute} : #{@second}"
		unless @rect.width <= 84*@player.hp/@player.maxhp
			@rect.width -= 1 # if @gap <= 2
		end
		unless @rect.width >= 84*@player.hp/@player.maxhp and !@resetter
			@rect.width += 1 # if @gap >= -2hp
		end
		if @resetter 
			@old_hp = @player.maxhp; @rect.width = 84; 
			@resetter = false
		end
	end
end