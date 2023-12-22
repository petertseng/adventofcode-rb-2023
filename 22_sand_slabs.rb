bricks = ARGF.map { |line|
  l, r = line.split(?~, 2).map { |v| v.split(?,, 3).map(&method(:Integer)) }
  l.zip(r).map(&:freeze).freeze
}.freeze

xmin, xmax = bricks.flat_map(&:first).minmax
width = (xmin..xmax).size

highest_id_at = {}
height_at = Hash.new(0)

above = Hash.new { |h, k| h[k] = [] }
below = Hash.new { |h, k| h[k] = [] }

# each_with_index before the sort so as not to renumber bricks
# (the number of each brick does not actually matter so long as they are all unique,
# but keeping the original number does help with debugging)
bricks.each_with_index.sort_by { |(_, _, (z1, _)), _| z1 }.each { |((x1, x2), (y1, y2), (z1, z2)), i|
  xys = (y1..y2).flat_map { |y|
    (x1..x2).map { |x|
      # negative x will alias into previous row, so we must subtract xmin.
      # (even though advent of code inputs have no negative x)
      # negative y is no problem, so no need to subtract ymin
      y * width + (x - xmin)
    }
  }.freeze

  # where does it land?
  z = xys.map(&height_at).max + 1
  top = z + z2 - z1

  seen = {}
  xys.each { |xy|
    # what does it land on top of?
    if height_at[xy] == z - 1 && (below_id = highest_id_at[xy]) && !seen[below_id]
      seen[below_id] = true
      above[below_id] << i
      below[i] << below_id
    end

    height_at[xy] = top
    highest_id_at[xy] = i
  }
}

above.default_proc = nil
above.each_value(&:freeze).freeze
below.each_value(&:freeze).freeze

# Note: "how many bricks fall?" asks for dominators,
# where the graph has an edge if A supports B.
# There are faster algorithms for this but this naive one is fast enough.
how_many_fall = bricks.size.times.map { |seed|
  gone = {seed => true}
  visit = ->x {
    (above[x] || []).each { |y|
      next unless below[y].all?(&gone)
      gone[y] = true
      visit[y]
    }
  }
  visit[seed]
  gone.size - 1
}.freeze

p how_many_fall.count(0)
p how_many_fall.sum
