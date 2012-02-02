module Tree
  class Node < Array
    # func (self Node) initialize(parent *Node, value, type string)
    def initialize(parent, value, type)
      if parent == nil
        @depth = 0
      else
        @depth = parent.depth + 1
      end
      @parent = parent
      @value = value
      @type = type
      @index = 0
    end
    attr_reader :depth, :parent, :value, :type, :children
    attr_accessor :index

    def add_child(value, type)
      super Node.new(self, value, type)
    end

    def inspect
      "#{"  " * @depth}#{@type}: #{@value}"
    end

    def print_all
      return if empty?
      current = self
      current.index = 0
      current = current[current.index]

      while true
        if current.empty?
          p current
          current = current.parent
          current.index += 1
        end

        if current.index >= current.size or current.empty?
          if current.parent == nil
            break
          else
            current = current.parent
            current.index += 1
          end
        else
          p current unless current.index > 0
          current = current[current.index]
          #p current
        end
      end
    end
  end

  class Root < Node
    def initialize
      super nil, nil, nil
    end
  end
end

=begin
root = Tree::Root.new
root.push "(0)", "level 1"
root[0].push "(0, 0)", "level 2"
root[0][0].push "(0, 0, 0)", "level 3"
root.push "(1)", "level 1"
root[1].push "(1, 0)", "level 2"
root[1].push "(1, 1)", "level 2"
root[1][1].push "(1, 1, 0)", "level 3"
root[1][1].push "(1, 1, 1)", "level 3"
root[1].push "(1, 2)", "level 2"
root.push "(2)", "level 1"

root.print_all

#Tracer.off
=end
