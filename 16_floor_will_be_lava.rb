verbose = ARGV.delete('-v')

grid = ARGF.map { |line|
  # pad left/right with nil for detecting when we walked off the edge
  # without having to % width or similar
  (line.chomp.chars.map(&:to_sym).unshift(nil) << nil).freeze
}.freeze

widths = grid.map(&:size)
raise "inconsistent width #{widths}" if widths.uniq.size != 1
width = widths[0]
height = grid.size
grid = grid.flatten.freeze

# any reasonable ordering should make mirrors easy.
# so let's make splitters easy by making vert/horiz have same parity.
DIRS = [-width, -1, width, 1].freeze
UP = 0
LEFT = 1
DOWN = 2
RIGHT = 3

# I want to cache the reachable count per (position, direction) pair,
# but this is foiled by loops:
# -|
# |-
#
# /-\
# \./
#
# We need to compress all loops into a single cell.
# Loops are strongly-connected components in the directed graph.
#
# The compressed graph will then be directed acyclic.
# Then we can apply a similar procedure as in
# https://stackoverflow.com/questions/48389163/how-to-count-all-reachable-nodes-in-a-directed-graph
#
# But unlike there, we cannot take a sum.
# We have four nodes in the graph per tile (one per direction),
# and taking the sum overcounts tiles entered from multiple directions.
# Instead, we have to take a set union of tiles hit.
# Achieve by caching a bitfield where each bit represents one tile.
# Combining cache entries is done by bitwise or.
def compress_loops(grid, height, width)
  size = height * width
  # Compute strongly connected components, using procedure described in
  # https://stackoverflow.com/questions/33590974/how-to-find-strongly-connected-components-in-a-graph
  # 1. Compute finishing times in the DFS of G (the order in which the DFS stack frame for that node finishes)
  # 2. Compute transpose(G)
  # 3. DFS on transpose(G), in descending order of finishing time from step 1

  # Create tranpose(G) (called gt here)
  gt = Array.new(size * 4) { [] }
  g = (size * 4).times.map { |posdir|
    pos = posdir >> 2
    dir = posdir & 3

    succs = case c = grid[pos]
    when :'.'
      [(pos + DIRS[dir]) << 2 | dir]
    when :/
      # up <-> right, down <-> left
      # 0 <-> 3, 1 <-> 2
      dir = 3 - dir
      [(pos + DIRS[dir]) << 2 | dir]
    when :'\\'
      # up <-> left, down <-> right
      # 0 <-> 1, 2 <-> 3
      dir ^= 1
      [(pos + DIRS[dir]) << 2 | dir]
    when :|
      if dir & 1 == 0
        [(pos + DIRS[dir]) << 2 | dir]
      else
        [
          ((pos - width) << 2 | UP),
          ((pos + width) << 2 | DOWN),
        ]
      end
    when :-
      if dir & 1 != 0
        [(pos + DIRS[dir]) << 2 | dir]
      else
        [
          ((pos - 1) << 2 | LEFT),
          ((pos + 1) << 2 | RIGHT),
        ]
      end
    when nil; []
    else raise "bad #{c} at #{pos.divmod(width)}"
    end

    succs.filter { |sposdir|
      spos = sposdir >> 2
      (0...size).cover?(spos) && grid[spos]
    }.each { |succ| gt[succ] << posdir }.freeze
  }.freeze
  gt.freeze

  # DFS on G to calculate finishing time
  finish = Array.new(size * 4)
  finish_so_far = -1
  visiting = {}
  visit = ->posdir {
    return if visiting[posdir]
    visiting[posdir] = true
    finish[posdir] ||= begin
      g[posdir].each(&visit)
      finish_so_far += 1
    end
  }
  (size * 4).times(&visit)

  # DFS on transpose(G) finds strongly connected components
  gt.each { |neigh| neigh.sort_by! { |n| -finish[n] }.freeze }
  visiting = {}
  visit = ->(posdir, my_scc = []) {
    return if visiting[posdir]
    visiting[posdir] = true
    my_scc << posdir
    gt[posdir].each { |neigh| visit[neigh, my_scc] }
    my_scc
  }
  sccs = (0...(size * 4)).sort_by { |n| -finish[n] }.filter_map(&visit).map(&:freeze).freeze

  # compressed_g is a map with one kv pair per SCC.
  # key is posdir of the representative
  # value is [edges_out, bitfield of tiles hit]
  # (as discussed above, we need to take a set union of tiles hit,
  # so the bitfield is necessary)
  #
  # Edges out of an SCC: Union of edges out of its members to any non-members.
  compressed_g = sccs.to_h { |scc|
    [scc[0], [scc.flat_map { |n| g[n] }.uniq - scc, scc.map { |n| 1 << (n >> 2) }.reduce(0, :|)].freeze]
  }
  # Edges into any member of an SCC must go into the representative.
  scc_of = sccs.flat_map { |scc|
    scc.map { |n| [n, scc[0]] }
  }.to_h.freeze
  compressed_g.each_value { |outs, _set|
    outs.map!(&scc_of).freeze
  }

  [scc_of, compressed_g]
end

#t0 = Time.now
scc_of, g = compress_loops(grid, height, width)
#$stderr.puts(Time.now - t0)

#fmt_posdir = ->posdir { "#{(posdir >> 2).divmod(width)} moving #{%i(up left down right)[posdir & 3]}" }
#fmt_bitfield = ->bits { bits.digits(2).each_with_index.filter_map { |d, i| i.divmod(width) if d != 0 } }

pgrid = ->(y0, x0, hits) {
  grid.each_slice(width).with_index { |row, y|
    puts row.map.with_index { |c, x|
      colour = if y == y0 && x == x0
        '1;31'
      elsif hits[y * width + x] != 0
        '1;32'
      else
        0
      end
      "\e[#{colour}m#{c}"
    }.join + "\e[0m"
  }
}

#cache_stat = {hit: 0, miss: 0}
cache = {}
tiles_hit_intern = ->(posdir, verbose: false) {
  #puts "#{posdir} #{fmt_posdir[posdir]} cache hit: #{fmt_bitfield[cache[posdir]]}" if verbose && cache[posdir]
  #cache_stat[cache.has_key?(posdir) ? :hit : :miss] += 1
  cache[posdir] ||= begin
    neigh, own_hits = g[posdir]
    neigh.reduce(own_hits) { |a, v| a | tiles_hit_intern[v, verbose: verbose] }
    #.tap { puts "#{posdir} #{fmt_posdir[posdir]} cache miss: #{fmt_bitfield[_1]}" if verbose }
  end
}

tiles_hit = ->(y0, x0, dir0, verbose: false) {
  tiles_hit_intern[scc_of[(y0 * width + x0) << 2 | dir0], verbose: verbose]
}

# remember we padded each row with nils to each side, so top-left corner is (0, 1).
hit1 = tiles_hit[0, 1, RIGHT]
puts hit1.to_s(2).count(?1)
pgrid[0, 1, hit1] if verbose

ups    = (1...(width - 1)).map { |x| ((args = [height - 1, x]) + [tiles_hit[*args, UP]]).freeze }
downs  = (1...(width - 1)).map { |x| ((args = [0, x])          + [tiles_hit[*args, DOWN]]).freeze }
lefts  = (0...height).map      { |y| ((args = [y, width - 2])  + [tiles_hit[*args, LEFT]]).freeze }
rights = (0...height).map      { |y| ((args = [y, 1])          + [tiles_hit[*args, RIGHT]]).freeze }
y0, x0, hit2 = (ups + downs + lefts + rights).max_by { |v| v.last.to_s(2).count(?1) }

puts hit2.to_s(2).count(?1)
pgrid[y0, x0, hit2] if verbose

#ups.each { |y, x, v| puts "up x=#{x} #{v.size} #{v}" }
#downs.each { |y, x, v| puts "down x=#{x} #{v.size} #{v}" }
#lefts.each { |y, x, v| puts "left y=#{y} #{v.size} #{v}" }
#rights.each { |y, x, v| puts "right y=#{y} #{v.size} #{v}" }

#$stderr.puts(cache_stat)
