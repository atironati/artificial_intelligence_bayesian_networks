
class Node
  attr_accessor :name, :value, :parents, :children, :prob_table

  def initialize(name)
    @name = name
    prob_table = Hash.new([])
  end

  def add_child(target_node)
    @children << target_node
    target_node.parents << self
  end

  def set_prob_table(nodes, probs)
    index = 0

    nodes.each do |node|
      prob_table[node.name] << probs.slice(index,2)
      index += 2
    end
  end
end
