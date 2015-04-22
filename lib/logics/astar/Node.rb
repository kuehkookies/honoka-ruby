module AStar
  class Node
    #class Node provides a node on a map which can be used for pathfinding. 
    #For Node to work with PriorityQueue and AMap it needs to implement the following
    # <= used for comparing g values
    # == used for finding the same node - using the x,y co-ordinates
    attr_accessor :parent
    attr_reader :x,:y,:g,:h,:m
    
    def initialize(x,y,move_cost=0)
      @x,@y,@m=x,y,move_cost
      @g=@m
      @h=0
    end
    
    def to_s
      #prints the node in the following format [x,y] f:g:h
      "[#{@x},#{@y}] #{@g+@h}:#{@g}:#{@h}"
    end
    
    def <=>(other)
      #can be used for ordering the priority list
      #puts "using <=>" #currently unused - can delete this line if required
      self.f<=>other.f
    end
    
    def <=(other)
      #used for comparing cost so far
      @g<=other.g
    end
     
    def ==(other)
      # nodes are == if x and y are the same - used for finding and removing same node
      return false if other==nil
      return (@x==other.x)&(@y==other.y)
    end
    
    def calc_g(previous)
      #cost so far is total cost of previous step plus the movement cost of this one
      @g=previous.g+@m
    end
    
    def calc_h(goal)
      #using manhattan distance to generate a heuristic value
      @h=(@x-goal.x).abs+(@y-goal.y).abs
    end
    def f
      @g+@h
    end
    def better?(other,tbmul=1.01)
      #which is better, self or other
      #can pass a tie-breaker multiplier (tbmul) if required
      if other==nil then return false end
      if self==other then return false end
      if f<other.f then 
        return true
      #here's the tie-breaker
      elsif f==other.f then
        nf=@g+tbmul*@h
        bf=other.g+tbmul*other.h
        if nf<bf then return true end
      end
      false
    end      
  end
end
  