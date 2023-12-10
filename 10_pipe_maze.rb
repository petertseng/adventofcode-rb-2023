verbose = ARGV.delete('-v')

maze = ARGF.map(&:chomp).map(&:freeze).freeze
widths = maze.map(&:size)
raise "unequal widths #{widths}" if widths.uniq.size != 1
width = widths[0]
height = maze.size
maze = maze.join

starts = maze.chars.each_with_index.filter_map { |c, i| i if c == ?S }.freeze
raise "not one start: #{starts}" if starts.size != 1
start = starts[0]
y0, x0 = start.divmod(width)
start_conns = [
  (-width if y0 > 0 && '|F7'.include?(maze[start - width])),
  (-1 if x0 > 0 && '-FL'.include?(maze[start - 1])),
  (1 if x0 < width - 1 && '-7J'.include?(maze[start + 1])),
  (width if y0 < height - 1 && '|LJ'.include?(maze[start + width])),
].compact.map(&:freeze).freeze

maze[start] = case start_conns
when [-width, -1]; ?J
when [-width, 1]; ?L
when [-width, width]; ?|
when [-1, 1]; ?-
when [-1, width]; ?7
when [1, width]; ?F
else raise "bad start conns #{start_conns}"
end
maze.freeze

pipe = {start => true}
pos = start
dir = start_conns[0]

dirs = {
  ?| => {-width => -width, width => width},
  ?- => {-1 => -1, 1 => 1},
  ?L => {-1 => -width, width => 1},
  ?F => {-width => 1, -1 => width},
  ?J => {1 => -width, width => -1},
  ?7 => {-width => -1, 1 => width},
}.each_value(&:freeze).freeze

until pos == start && pipe.size > 1
  pos += dir
  dir = dirs.fetch(maze[pos]).fetch(dir)
  pipe[pos] = true
end
pipe.freeze

raise "odd path length #{pipe.size} is impossible because of parity" if pipe.size.odd?
puts pipe.size / 2

inside = {}
# Checking either |LJ or |F7 is sufficient
# (checking the top half or bottom half of every tile)
edge = '|LJ'.chars.to_h { |c| [c, true] }.freeze
maze.chars.each_slice(width).with_index { |row, y|
  out = true
  row.each_with_index { |c, x|
    pos = y * width + x
    if pipe[pos]
      out ^= edge[c]
    elsif !out
      inside[pos] = true
    end
  }
}
inside.freeze

puts inside.size

maze.chars.each_slice(width).with_index { |row, y|
  row.each_with_index { |c, x|
    pos = y * width + x
    colour = pipe[pos] ? '1;32' : inside[pos] ? '1;31' : 0
    print "\e[#{colour}m#{c}"
  }
  puts
} if verbose
