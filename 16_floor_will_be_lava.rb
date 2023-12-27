verbose = ARGV.delete('-v')

grid = ARGF.map { |line|
  # pad left/right with nil for detecting when we walked off the edge
  # without having to % width or similar
  (line.chomp.chars.map(&:to_sym).unshift(nil) << nil).freeze
}.freeze

widths = grid.map(&:size)
raise "inconsistent width #{widths}" if widths.uniq.size != 1
WIDTH = widths[0]
height = grid.size
GRID = grid.flatten.freeze

# any reasonable ordering should make mirrors easy.
# so let's make splitters easy by making vert/horiz have same parity.
DIRS = [-WIDTH, -1, WIDTH, 1].freeze
UP = 0
LEFT = 1
DOWN = 2
RIGHT = 3

def tiles_hit(y0, x0, dir0)
  hit = {}
  beams = [(y0 * WIDTH + x0) << 2 | dir0]
  until beams.empty?
    new_beams = []
    beams.each { |b|
      next if hit[b]
      pos = b >> 2
      # grid[pos] is nil if walking off left/right/bottom edge.
      # we would not want to register a hit if so.
      next unless c = GRID[pos]
      # top edge (negative indexing would have returned non-nil)
      next if pos < 0

      hit[b] = true
      dir = b & 3

      case c = GRID[pos]
      when :'.'
        new_beams << ((pos + DIRS[dir]) << 2 | dir)
      when :/
        # up <-> right, down <-> left
        # 0 <-> 3, 1 <-> 2
        dir = 3 - dir
        new_beams << ((pos + DIRS[dir]) << 2 | dir)
      when :'\\'
        # up <-> left, down <-> right
        # 0 <-> 1, 2 <-> 3
        dir ^= 1
        new_beams << ((pos + DIRS[dir]) << 2 | dir)
      when :|
        if dir & 1 == 0
          new_beams << ((pos + DIRS[dir]) << 2 | dir)
        else
          new_beams << ((pos - WIDTH) << 2 | UP)
          new_beams << ((pos + WIDTH) << 2 | DOWN)
        end
      when :-
        if dir & 1 != 0
          new_beams << ((pos + DIRS[dir]) << 2 | dir)
        else
          new_beams << ((pos - 1) << 2 | LEFT)
          new_beams << ((pos + 1) << 2 | RIGHT)
        end
      else raise "bad #{c} at #{pos.divmod(WIDTH)}"
      end
    }
    beams = new_beams
  end
  hit.keys.map { |u| u >> 2 }.uniq.freeze
end

pgrid = ->(y0, x0, hits) {
  hits = hits.each_with_index.to_h.freeze
  GRID.each_slice(WIDTH).with_index { |row, y|
    puts row.map.with_index { |c, x|
      colour = if y == y0 && x == x0
        '1;31'
      elsif hits[y * WIDTH + x]
        '1;32'
      else
        0
      end
      "\e[#{colour}m#{c}"
    }.join + "\e[0m"
  }
}

# remember we padded each row with nils to each side, so top-left corner is (0, 1).
hit1 = tiles_hit(0, 1, RIGHT)
puts hit1.size
pgrid[0, 1, hit1] if verbose

ups    = (1...(WIDTH - 1)).map { |x| Ractor.new(height - 1, x) { |*args| (args + [tiles_hit(*args, UP)]).freeze } }
downs  = (1...(WIDTH - 1)).map { |x| Ractor.new(0, x)          { |*args| (args + [tiles_hit(*args, DOWN)]).freeze } }
lefts  = (0...height).map      { |y| Ractor.new(y, WIDTH - 2)  { |*args| (args + [tiles_hit(*args, LEFT)]).freeze } }
rights = (0...height).map      { |y| Ractor.new(y, 1)          { |*args| (args + [tiles_hit(*args, RIGHT)]).freeze } }
results = (ups + downs + lefts + rights).map(&:take)
y0, x0, hit2 = results.max_by { |v| v.last.size }

puts hit2.size
pgrid[y0, x0, hit2] if verbose

#ups.each { |y, x, v| puts "up x=#{x} #{v.size} #{v}" }
#downs.each { |y, x, v| puts "down x=#{x} #{v.size} #{v}" }
#lefts.each { |y, x, v| puts "left y=#{y} #{v.size} #{v}" }
#rights.each { |y, x, v| puts "right y=#{y} #{v.size} #{v}" }
