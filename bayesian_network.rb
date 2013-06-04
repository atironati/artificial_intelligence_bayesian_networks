#!/usr/bin/env ruby
require './node'

class BayesianNetwork
  attr_accessor :nodes, :weighted_counts

  def initialize
    @nodes = []
    @weighted_counts = Hash.new(0)
  end

  def add_node(node)
    @nodes << node
  end

  def set_initial_weighting_count
    keys = initial_weighting_count(nodes, [])
    keys.each do |key|
      @weighted_counts[key] = 0
    end
  end

  def initial_weighting_count(rem_nodes, rows)
    if rem_nodes.size == 0
      return rows
    else
      curr_node = rem_nodes.shift
      puts curr_node.name

      node_values = [{curr_node.name => true},
                     {curr_node.name => false}]
      puts node_values.inspect

      # need to add more nodes in
      if rows.size == 0
        initial_weighting_count(rem_nodes, node_values)
      else
        new_rows = []
        rows.each do |row|
          node_values.each do |nv|
            new_rows << nv.merge(row)
          end
        end
        initial_weighting_count(rem_nodes, new_rows)
      end
    end
  end

end

bn = BayesianNetwork.new()
cloudy    = Node.new("cloudy")
rain      = Node.new("rain")
sprinkler = Node.new("sprinkler")
wet_grass = Node.new("wet_grass")

bn.add_node(cloudy)
bn.add_node(rain)
bn.add_node(sprinkler)
bn.add_node(wet_grass)

rows = bn.set_initial_weighting_count
puts "weighting done"
bn.weighted_counts.each do |r|
  puts r.inspect
end
