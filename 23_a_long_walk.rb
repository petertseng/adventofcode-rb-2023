# TODO: Consider dynamic programming
# https://www.reddit.com/r/adventofcode/comments/18ysozp/day_23_2023_any_tips_to_further_improve/kgdcc0p/
# https://gist.github.com/Voltara/ae028b17ba5cd69fa9b8b912e41e853b

require_relative 'lib/search'

def inter_neigh(intersections, trails, width, slippery:)
  (intersections.keys.unshift(1)).map { |inter|
    newinter = intersections.merge(inter => false, trails.size - 2 => true)
    Search.bfs([inter], neighbours: ->pos {
      return [] if newinter[pos]
      simple_neigh(pos, trails, width, slippery: slippery)
    }, goal: newinter, num_goals: intersections.size)[:goals].freeze
  }.freeze
end

def simple_neigh(pos, trails, width, slippery:)
  cur = slippery && trails[pos]
  n = []
  # actually my input doesn't have any ^ or <,
  # but I'll look for them anyway.
  # wraparound to negative pos - width is OK, since the only place it could happen is the start,
  # and that column is a #.
  n << pos - width if trails[pos - width] != ?# && (!slippery || cur == ?. || cur == ?^)
  # no need for left/right edge check since left/right edge all have #
  n << pos - 1 if trails[pos - 1] != ?# && (!slippery || cur == ?. || cur == ?<)
  n << pos + 1 if trails[pos + 1] != ?# && (!slippery || cur == ?. || cur == ?>)
  n << pos + width if (c = trails[pos + width]) && c != ?# && (!slippery || cur == ?. || cur == ?v)
  n
end

trails = ARGF.map(&:chomp).map(&:freeze).freeze
widths = trails.map(&:size)
raise "unequal widths #{widths}" if widths.uniq.size != 1
width = widths[0]
trails = trails.join.freeze

intersections = trails.each_char.with_index.filter_map { |c, pos|
  next if c == ?#
  pos if [-width, -1, 1, width].count { |dpos|
    npos = pos + dpos
    npos >= 0 && (nc = trails[npos]) && nc != ?#
  } >= 3
}.to_h { |i| [i, true] }.freeze

goal_neigh = Search.bfs([trails.size - 2], neighbours: ->pos {
  return [] if intersections[pos]
  simple_neigh(pos, trails, width, slippery: false)
}, goal: intersections, num_goals: 2)[:goals]

goal, adjust = goal_neigh.size == 1 ? goal_neigh.to_a[0] : [trails.size - 2, 0]

bit = ([1] + intersections.keys + [trails.size - 2]).each_with_index.to_h.freeze
goal = bit[goal]

[true, false].each { |slippery|
  neigh = inter_neigh(intersections, trails, width, slippery: slippery).map { |ns|
    # Put longer edges first, so we can prune earlier.
    ns.map { |n, d| [bit.fetch(n), d].freeze }.sort_by(&:last).reverse.freeze
  }.freeze
  total_dist = neigh.each_with_index.flat_map { |vs, u|
    vs.map { |v, d|
      [u, v, d].freeze
    }
  }.uniq { |u, v, d| [u, v].sort }.sum(&:last) - adjust
  # I used to have an optimisation where I forbid traveling toward the start along the outside edge,
  # but with the total distance pruning, it no longer makes a difference,
  # so might as well remove it.

  best = 0

  visit = ->(pos, len, path) {
    return best = [len, best].max if pos == goal
    return if len + total_dist <= best

    # As each node can only be visited once,
    # all edges of this node are removed from potential.
    # The edge into this node was both removed from potential and added to actual in caller.
    # This call will add the edge taken out of this node to actual.
    unused_edge = neigh.fetch(pos).sum { |n, dist|
      path[n] == 0 ? dist : 0
    }

    total_dist -= unused_edge
    neigh.fetch(pos).each { |n, dist|
      next if path[n] != 0
      visit[n, len + dist, path | 1 << n]
    }
    total_dist += unused_edge
  }

  visit[0, adjust, 1]
  puts best
}
