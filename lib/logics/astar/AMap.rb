#AStar Map
#by Marcin Coles
#27/Sep/2007
require_relative 'PriorityQueue'
require_relative 'Node'

module AStar

  class AMap
    attr_reader :nodes
    def initialize(costmap)
      #cost map is a 2D array - eg a 2x2 map is AMap.new([[3,5],[3,2]])
      # the values are the movement cost for the node at those co-ordinates
      #should do some error checking for size of the map, but anyway
      # note that the costmap array is indexed @costmap[y][x], 
      # which is the opposite way to Node(x,y)
      ##note that it's probably easier to use AMap.load(file)
      @costmap=costmap
      @height=costmap.size
      @width=costmap.first.size
      @nodes=[]
      @output="\n"
      costmap.each_index do |row|
        costmap[row].each_index do |col|
          @nodes.push(Node.new(col,row,costmap[row][col]))
          @output<<"|#{costmap[row][col]}"
        end
        @output<<"|\n"
      end
    end
    
    def self.load(filename)
      mmap=[]
      File.open(filename) do |f|
        f.each_line do |line|
          linearr=[]
          line.chomp.split(',').each do |e|
            linearr.push(e.to_i)
          end
          mmap.push(linearr)
        end
      end
      return AMap.new(mmap)
    end
    
    def generate_successor_nodes(anode)
      # determine nodes bordering this one - only North,S,E,W for now
      # no boundary condition check, eg if anode.x==-4
      # considers a wall to be a 0 so therefore not allow that to be a neighbour
      north=@costmap[anode.y-1][(anode.x)] unless (anode.y-1)<0 #boundary check for -1
      south=@costmap[anode.y+1][(anode.x)] unless (anode.y+1)>(@height-1)
      east=@costmap[anode.y][(anode.x+1)] unless (anode.x+1)>(@width-1)
      west=@costmap[anode.y][(anode.x-1)] unless (anode.x-1)<0 #boundary check for -1
      
      if (west && west>0) then # not on left edge, so provide a left-bordering node
        newnode=Node.new((anode.x-1),anode.y,@costmap[anode.y][(anode.x-1)])
        yield newnode
      end
      if (east && east>0) then # not on right edge, so provide a right-bordering node
        newnode=Node.new((anode.x+1),anode.y,@costmap[anode.y][(anode.x+1)])
        yield newnode
      end
      if (north && north>0) then # not on left edge, so provide a left-bordering node
        newnode=Node.new(anode.x,(anode.y-1),@costmap[(anode.y-1)][anode.x])
        yield newnode
      end
      if (south && south>0) then # not on right edge, so provide a right-bordering node
        newnode=Node.new(anode.x,(anode.y+1),@costmap[(anode.y+1)][anode.x])
        yield newnode
      end    
    end

    def astar(node_start,node_goal)
      iterations=0
      open=PriorityQueue.new()
      closed=PriorityQueue.new()
      node_start.calc_h(node_goal)
      open.push(node_start)
      while !open.empty? do
        iterations+=1 #keep track of how many times this itersates
        node_current=open.find_best
        if node_current==node_goal then #found the solution
          #~ puts "Iterations: #{iterations}"
          return node_current 
        end       
        generate_successor_nodes(node_current) do |node_successor|
          #now doing for each successor node of node_current
          node_successor.calc_g(node_current)
          #skip to next node_successor if better one already on open or closed list
          if open_successor=open.find(node_successor) then 
            if open_successor<=node_successor then next end  #need to account for nil result
          end
          if closed_successor=closed.find(node_successor) then
            if closed_successor<=node_successor then next end 
          end
          #still here, then there's no better node yet, so remove any copies of this node on open/closed lists
          open.remove(node_successor)
          closed.remove(node_successor)
          # set the parent node of node_successor to node_current
          node_successor.parent=node_current
          # set h to be the estimated distance to node_goal using the heuristic
          node_successor.calc_h(node_goal)
          # so now we know this is the best copy of the node so far, so put it onto the open list
          open.push(node_successor)
        end
        #now we've gone through all the successors, so the current node can be closed
        closed.push(node_current)
      end
    end

    def dijkstra(node_start,node_goal)
      iterations=0
      open=PriorityQueue.new()
      # node_start.calc_h(node_goal)
      open.push(node_start)
      while !open.empty? do
        iterations+=1
        node_current=open.find_best
        if node_current==node_goal then
          #~ puts "Iterations: #{iterations}"
          return node_current 
        end

        generate_successor_nodes(node_current) do |node_successor|
          node_successor.calc_g(node_current)
          open.remove(node_successor)
          node_successor.parent=node_current
          open.push(node_successor)
        end
      end
    end

    def bfs(node_start,node_goal)
      iterations=0
      open=PriorityQueue.new()
      node_start.calc_h(node_goal)
      open.push(node_start)
      while !open.empty? do
        iterations+=1
        node_current=open.find_best
        if node_current==node_goal then
          #~ puts "Iterations: #{iterations}"
          return node_current 
        end

        generate_successor_nodes(node_current) do |node_successor|
          node_successor.calc_g(node_current)
          if open_successor=open.find(node_successor) then 
            if open_successor<=node_successor then next end
          end
          open.remove(node_successor)
          node_successor.parent=node_current
          node_successor.calc_h(node_goal)
          open.push(node_successor)
        end
      end
    end
      
    def co_ord(x,y)
      a=Node.new(x,y)
      @nodes.find {|n| n==a}
    end
    
    def to_s
      @output
    end
    
    def show_path(anode)
      #shows the path back from node 'anode' by following the parent pointer
      curr=anode
      pathmap=@costmap.clone
      while curr.parent do
        pathmap[curr.y][curr.x]='*'
        curr=curr.parent
      end
      pathmap[curr.y][curr.x]='*'
      pathstr="\n"
      pathmap.each_index do |row|
        pathmap[row].each_index do |col|
          pathstr<<"|#{pathmap[row][col]}"
        end
        pathstr<<"|\n"
      end
      pathstr
    end
  end
end