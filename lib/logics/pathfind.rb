class GridMap
  def initialize
    filename = "lib/levels/" + $window.map.current.to_s + ".map"
    @map_path = AMap.load(filename)
    @map_height = 0
    @tiles = Hash.new
    File.open(filename).readlines.each do |line|
      line = line.chomp.split(",")
      if !defined?(@map_width)
        @map_width = line.size
      end

      for x in 0...@map_width
        @tiles[[x, @map_height]] = line[x].to_i
      end
      @map_height += 1  
    end
  end

  def find_path_dijkstra(from_position, to_position)
    # returns an array of [x, y]
    if to_position[0] < @map_width and to_position[1] < @map_height
      start = @map_path.co_ord(from_position[0], from_position[1])
      finish = @map_path.co_ord(to_position[0], to_position[1])
      goal = @map_path.dijkstra(start, finish)
      curr = goal
      path = Array.new
      if curr != nil
        while curr.parent do
          path << [curr.x, curr.y]
          curr = curr.parent
        end    
        return path
      else
        return nil
      end
    else
      return nil
    end
  end

  def find_path_bfs(from_position, to_position)
    # returns an array of [x, y]
    if to_position[0] < @map_width and to_position[1] < @map_height
      start = @map_path.co_ord(from_position[0], from_position[1])
      finish = @map_path.co_ord(to_position[0], to_position[1])
      goal = @map_path.bfs(start, finish)
      curr = goal
      path = Array.new
      if curr != nil
        while curr.parent do
          path << [curr.x, curr.y]
          curr = curr.parent
        end    
        return path
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def find_path_astar(from_position, to_position)
    # returns an array of [x, y]
    if to_position[0] < @map_width and to_position[1] < @map_height
      start = @map_path.co_ord(from_position[0], from_position[1])
      finish = @map_path.co_ord(to_position[0], to_position[1])
      goal = @map_path.astar(start, finish)
      curr = goal
      path = Array.new
      if curr != nil
        while curr.parent do
          path << [curr.x, curr.y]
          curr = curr.parent
        end    
        return path
      else
        return nil
      end
    else
      return nil
    end
  end
end