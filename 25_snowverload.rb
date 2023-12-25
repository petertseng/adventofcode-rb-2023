# Tried to implement Stoer-Wagner, but it's too slow
# O(nm + n^2 log n)

# Other working ideas:
#
# 1. For each edge, remove it and calculate the distance between the edges it connected.
# Take the max 3 to be the bridges.
# https://www.reddit.com/r/adventofcode/comments/18qbsxs/2023_day_25_solutions/keum2ff/
# https://www.reddit.com/r/adventofcode/comments/18qbsxs/2023_day_25_solutions/keuppa3/
# Implemented this, but a bit slow at 1 second
#
# 2. Karger's algorithm (random), repeat it until finding the cut of size 3
# Community has said it works well and only takes about 200 tries,
# but I have a slight distaste for random algorithms
#
# 3. Edmonds-Karp is known to need 3 BFS since we know the cut size in advance.
# TBD: Selecting s and t

# This idea:
# https://www.reddit.com/r/adventofcode/comments/18qbsxs/2023_day_25_solutions/keump60/
# Seed one component with one node,
# then greedily add the node most likely to be in the component
# (min by # edges outside - # edges inside)
# Surely this can be defeated with some constructed input?
# but good enough for today.

verbose = ARGV.delete('-v')

neigh = Hash.new { |h, k| h[k] = [] }

ARGF.each_line(chomp: true) { |line|
  l, rs = line.split(?:)
  l = l.to_sym
  rs.strip.split.map(&:to_sym).each { |r|
    neigh[l] << r
    neigh[r] << l
  }
}

neigh.each_value(&:freeze).freeze

# TODO: Best start node?
# Just keep trying until it finds the right one.
# For my input the first try is correct,
# but I wanted to avoid a case where it accidentally joins the two components.
bridge, left = neigh.each_key { |start|
  left = {start => true}
  bridge = neigh[start].to_h { |r| [[start, r].freeze, true] }
  while bridge.size > 3
    add = bridge.keys.map(&:last).uniq.min_by { |u| neigh[u].sum { |v| left[v] ? -1 : 1 } }
    left[add] = true
    neigh[add].each { |v|
      if left[v]
        bridge.delete([v, add])
      else
        bridge[[add, v].freeze] = true
      end
    }
  end
  break [bridge.freeze, left.freeze] if bridge.size == 3
}

# This might help determine how likely it is that it makes the wrong choice
bridge.each_key { |u, v|
  puts "#{u}: #{neigh[u].map { |un| [un, neigh[un].size] }}"
  puts "#{v}: #{neigh[v].map { |vn| [vn, neigh[vn].size] }}"
} if false

p bridge.keys if verbose
p [left.size, neigh.size - left.size] if verbose
p left.size * (neigh.size - left.size)
