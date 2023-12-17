POS_SHIFT = 1
VERT = 0
HORIZ = 1
HORIZ_OR_VERT = 1
COST_SIZE = 9.bit_length
COST_MASK = (1 << COST_SIZE) - 1

def dijkstras(starts, goal, width, cost, max_straight, min_turn = 1, verbose: false)
  g_score = Hash.new(Float::INFINITY)
  starts.each { |start| g_score[start] = 0 }

  # Distances all < 9,
  # so can just use an array.
  opens = Array.new(10 * max_straight) { [] }
  opens[0].concat(starts)
  prev = {}

  dirs = [
    [-width, width],
    [-1, 1],
  ].map(&:freeze).freeze

  while (open = opens.shift)
    open.each { |current|
      horiz = current & HORIZ_OR_VERT
      pos = current >> POS_SHIFT

      my_closed_bit = 1 << (COST_SIZE + horiz)
      next if cost[pos] & my_closed_bit != 0
      cost[pos] |= my_closed_bit

      return [g_score[current], path_of(prev, current)] if pos == goal

      dirs[horiz].each { |dpos|
        total_cost = 0

        (1..max_straight).each { |straights|
          new_pos = pos + dpos * straights
          break if new_pos < 0
          break unless new_cost = cost[new_pos]
          total_cost += new_cost & COST_MASK
          next if straights < min_turn

          new_horiz = horiz ^ 1
          their_closed_bit = 1 << (COST_SIZE + new_horiz)
          next if new_cost & their_closed_bit != 0

          neighbour = new_pos << POS_SHIFT | new_horiz
          tentative_g_score = g_score[current] + total_cost
          next if tentative_g_score >= g_score[neighbour]

          prev[neighbour] = current if verbose
          g_score[neighbour] = tentative_g_score
          opens[total_cost - 1] << neighbour
        }
      }
    }
    opens << []
  end

  nil
end

def path_of(prevs, n)
  path = [n]
  current = n
  while (current = prevs[current])
    path.unshift(current)
  end
  path.freeze
end

# Pad rows left and right so we don't wrap from end of one row to start of next.
def pad_rows(heat_loss)
  # intentionally no freeze (dijkstras modifies)
  heat_loss.map { |r| r.dup.unshift(nil) << nil }.flatten
end

verbose = ARGV.delete('-v')

heat_loss = ARGF.map { |line| line.chomp.chars.map(&method(:Integer)).freeze }.freeze
height = heat_loss.size
width = heat_loss[0].size
raise "inconsistent width #{heat_loss.map(&:size)}" if heat_loss.any? { |row| row.size != width }

# start position +1 for padding
# allowed to go either direction from start
starts = [1 << POS_SHIFT | VERT, 1 << POS_SHIFT | HORIZ].freeze
# -1 for 0-indexing, -1 for padding
goal = height * (width + 2) - 2

[
  [3, 1],
  [10, 4],
].each { |max_straight, min_turn|
  cost, path = dijkstras(starts, goal, width + 2, pad_rows(heat_loss), max_straight, min_turn, verbose: verbose)
  puts cost
  next unless verbose

  # path only contains points where we turn, so we need to fill in the spaces in between.
  in_path = path.each_cons(2).flat_map { |pos1, pos2|
    y1, x1 = ((pos1 >> POS_SHIFT) - 1).divmod(width + 2)
    y2, x2 = ((pos2 >> POS_SHIFT) - 1).divmod(width + 2)
    if y1 == y2 && x1 != x2
      Range.new(*[x1, x2].minmax).map { |x| [y1, x].freeze }
    elsif x1 == x2 && y1 != y2
      Range.new(*[y1, y2].minmax).map { |y| [y, x1].freeze }
    else raise "bad path #{y1} #{x1} #{y2} #{x2}"
    end
  }.to_h { |k| [k, true] }.freeze

  heat_loss.each_with_index { |row, y|
    puts row.map.with_index { |hl, x|
      colour = in_path[[y, x]] ? '1;32' : 0
      "\e[#{colour}m#{hl & COST_MASK}"
    }.join + "\e[0m"
  }
}
