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
    keys = initial_weighting_count(@nodes.dup, [])
    keys.each do |key|
      @weighted_counts[key] = 0
    end
  end

  def initial_weighting_count(rem_nodes, rows)
    if rem_nodes.size == 0
      return rows
    else
      curr_node = rem_nodes.shift

      node_values = [{curr_node.name => true},
                     {curr_node.name => false}]

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

  def likelihood_weighting(query_x, events, n)
    # we want to start iterating from the parent nodes
    parent_nodes = get_parent_nodes

    # because events are fixed, we can filter out unused entries in weighted_counts
    local_weighted_counts = @weighted_counts

    events.each do |e_k, e_v|
      local_weighted_counts = local_weighted_counts.reject{ |w_k, w_v|
        w_k[e_k] != e_v
      }

      # set node value
      @nodes.each do |node|
        if node.name == e_k
          node.value = e_v
          break
        end
      end
    end

    n.times do
      fix_event_values(events)

      x,w = weighted_sample(parent_nodes, {}, events, 1.0)
      local_weighted_counts[x] += w

      reset_network_values
    end

    #puts "WEIGHTED COUNTS"
    #local_weighted_counts.each do |k, v|
      #puts "k: #{k},   v: #{v}"
    #end

    # return an array containing normalized probability of [x = true, x = false] given the events
    normalize_over(query_x, local_weighted_counts)
  end

  # use BFS to traverse tree, select random sample, and update weight value
  def weighted_sample(nodes_to_traverse, traversed_nodes, events, weight)
    if nodes_to_traverse == []
      return [traversed_nodes, weight]
    else
      next_nodes = []

      nodes_to_traverse.each do |node|
        # gather parent nodes into useful hash
        key = Hash.new()
        node.parents.each do |p|
          key[p.name] = p.value
        end

        # if this node doesn't have a value then it isn't an event node
        if node.value == nil
          # randomly select value of current node
          rand_num = Random.rand.round(3)
          # P( node = true | parents(node) )
          curr_true_prob = node.prob_table[key.merge({node.name => true})]

          #puts "name: #{node.name}"
          #puts "RAND VALUE: #{rand_num}"
          #puts "CURR_TRUE_PROB: #{curr_true_prob}"

          # store value selection for this node, based on random number selection
          value_selection = nil
          if curr_true_prob > rand_num
            value_selection = true
          else
            value_selection = false
          end
          traversed_nodes[node.name] = value_selection

          # set value for this node
          node.value = value_selection

          #puts "VALUE SELECTION: #{value_selection}"
        else
          # store value selection for this node
          traversed_nodes[node.name] = node.value
          # P( node = node.value | parents(node) )
          #puts "event node #{node.name} weight change: #{key.merge({node.name => node.value})}"
          curr_prob = node.prob_table[key.merge({node.name => node.value})]

          # update weights if this is an event node (it should be, but I am checking just in case)
          if events[node.name]
            weight *= curr_prob
          end
        end

        # add this node's children to the list of nodes to traverse in the next layer
        next_nodes.concat(node.children)
      end

      # traverse the next level of nodes
      weighted_sample(next_nodes.uniq, traversed_nodes, events, weight)
    end
  end

  def get_parent_nodes
    parent_nodes = @nodes.reject do |node|
      node.parents != []
    end

    parent_nodes
  end

  def reset_network_values
    @nodes.each do |node|
      node.value = nil
    end
  end

  def fix_event_values(events)
    events.each do |k, v|
      @nodes.each do |node|
        node.value = v if node.name == k
      end
    end
  end

  def normalize_over(x, weighted_counts)
    a = [0,0]
    weighted_counts.each do |k, v|
      if k[x] == true
        a[0] += v
      else
        a[1] += v
      end
    end

    total = a[0] + a[1]
    a = a.map do |e|
      (e.to_f / total).round(3)
    end
    a
  end
end

# -------------------------------------------------------------------------

bn = BayesianNetwork.new()
cloudy    = Node.new("cloudy")
rain      = Node.new("rain")
sprinkler = Node.new("sprinkler")
wet_grass = Node.new("wet_grass")

cloudy.add_child(sprinkler)
cloudy.add_child(rain)
sprinkler.add_child(wet_grass)
rain.add_child(wet_grass)

cloudy.set_prob_table(   {{"cloudy" => true}  => 0.5,
                          {"cloudy" => false} => 0.5})
# -------------------------------------------------------------------------
rain.set_prob_table(     {{"cloudy" => true,  "rain" => true}  => 0.8,
                          {"cloudy" => true,  "rain" => false} => 0.2,
                          {"cloudy" => false, "rain" => true}  => 0.2,
                          {"cloudy" => false, "rain" => true}  => 0.8})
# -------------------------------------------------------------------------
sprinkler.set_prob_table({{"cloudy" => true,  "sprinkler" => true}  => 0.1,
                          {"cloudy" => true,  "sprinkler" => false} => 0.9,
                          {"cloudy" => false, "sprinkler" => true}  => 0.5,
                          {"cloudy" => false, "sprinkler" => true}  => 0.88})
# -------------------------------------------------------------------------
wet_grass.set_prob_table({{"sprinkler" => true,  "rain" => true,  "wet_grass" => true}  => 0.99,
                          {"sprinkler" => true,  "rain" => true,  "wet_grass" => false} => 0.01,
                          {"sprinkler" => true,  "rain" => false, "wet_grass" => true}  => 0.90,
                          {"sprinkler" => true,  "rain" => false, "wet_grass" => false} => 0.10,
                          {"sprinkler" => false, "rain" => true,  "wet_grass" => false} => 0.90,
                          {"sprinkler" => false, "rain" => true,  "wet_grass" => true}  => 0.10,
                          {"sprinkler" => false, "rain" => false, "wet_grass" => false} => 0.00,
                          {"sprinkler" => false, "rain" => false, "wet_grass" => true}  => 1.00})
# -------------------------------------------------------------------------

bn.add_node(cloudy)
bn.add_node(rain)
bn.add_node(sprinkler)
bn.add_node(wet_grass)

rows = bn.set_initial_weighting_count

n_values = [10, 100, 500, 1000]
n_values.each do |n_value|
  puts "n = #{n_value}"

  count = 0
  sum = [0,0]
  sum_sqr = [0,0]

  n_value.times do
    post_prob = bn.likelihood_weighting("cloudy", {"sprinkler" => true, "wet_grass" => true}, n_value)
    sum[0] += post_prob[0]
    sum[1] += post_prob[1]
    count += 1

    sum_sqr[0] += post_prob[0]*post_prob[0]
    sum_sqr[1] += post_prob[1]*post_prob[1]
  end

  avg = sum.map do |e|
    (e.to_f / count).round(3)
  end
  puts "Average (true, false): #{avg.inspect}"

  sum_sqr_i = -1
  var = sum.map do |e|
    sum_sqr_i += 1
    ((sum_sqr[sum_sqr_i] - ((e*e)/count.to_f))/(count - 1)).round(4)
  end
  puts "Variance (true, false): #{var.inspect}"
end
#puts "post_prob"
#puts post_prob.inspect
