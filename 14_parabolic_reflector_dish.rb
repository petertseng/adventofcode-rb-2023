# In this implementation, the top-left is the most-significant,
# followed by the rest of its row,
# with the bottom-right being least-significant.

def load(rocks, width)
  load = 0
  y = 1
  row = (1 << width) - 1
  until rocks == 0
    load += y * (rocks & row).to_s(2).count(?1)
    rocks >>= width
    y += 1
  end
  load
end

height = 0
width = nil

blocks = 0
rocks = 0

ARGF.each_line(chomp: true) { |line|
  height += 1
  width ||= line.size
  raise "inconsistent width #{width} != #{line.size}" if width != line.size

  line.each_char { |c|
    rocks <<= 1
    blocks <<= 1
    case c
    when ?#; blocks |= 1
    when ?O; rocks |= 1
    when ?.; #ok
    else raise "bad char #{c}"
    end
  }
}

size = height * width

each_row = height.times.reduce(0) { |a, c| a << width | 1 }
each_col = (1 << width) - 1

left_col = (1 << (width - 1)) * each_row
right_col = 1 * each_row
top_row = each_col << (size - width)
bottom_row = 1 * each_col

last_seen = {}
hist = []

1.step { |t|
  loop {
    can_move_up = rocks & ~((blocks | rocks) >> width) & ~top_row
    if can_move_up == 0
      puts load(rocks, width) if t == 1
      break
    end
    rocks = rocks & ~can_move_up | can_move_up << width
  }
  loop {
    can_move_left = rocks & ~((blocks | rocks) >> 1) & ~left_col
    break if can_move_left == 0
    rocks = rocks & ~can_move_left | can_move_left << 1
  }
  loop {
    can_move_down = rocks & ~((blocks | rocks) << width) & ~bottom_row
    break if can_move_down == 0
    rocks = rocks & ~can_move_down | can_move_down >> width
  }
  loop {
    can_move_right = rocks & ~((blocks | rocks) << 1) & ~right_col
    break if can_move_right == 0
    rocks = rocks & ~can_move_right | can_move_right >> 1
  }

  if prev = last_seen[rocks]
    target = 1000000000
    cycle_len = t - prev
    part_cycles = (target - t) % cycle_len
    # remember, this element hasn't been added to hist yet.
    puts load(hist[-cycle_len + part_cycles], width)
    break
  end

  hist[t] = rocks
  last_seen[rocks] = t
}
