
class Node
  attr_accessor :name, :value, :parents, :children, :prob_table

  def initialize(name)
    @name = name
    @children = []
    @parents = []
    @prob_table = Hash.new([])
  end

  def add_child(target_node)
    @children << target_node
    target_node.parents << self
  end

  def set_prob_table(prob_table)
    @prob_table = prob_table
  end
end
