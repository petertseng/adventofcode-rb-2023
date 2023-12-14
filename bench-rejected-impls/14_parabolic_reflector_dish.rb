require 'benchmark'

def cycle1bil
  t = 0
  target = 1_000_000_000
  seen = {}
  while t < target
    v = yield t
    if prev = seen[v]
      cycle_len = t - prev
      t += (target - 1 - t) / cycle_len * cycle_len
    end
    seen[v] = t
    t += 1
  end
  raise "overshot #{t}" if t > target
end

bench_candidates = []

bench_candidates << def two_bigint(grid)
  height = 0
  width = nil

  blocks = 0
  rocks = 0

  grid.each_line(chomp: true) { |line|
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

  cycle1bil { |t|
    loop {
      can_move_up = rocks & ~((blocks | rocks) >> width) & ~top_row
      break if can_move_up == 0
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

    rocks
  }

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

bench_candidates << def int_per_row(grid)
  width = nil

  blocks, rocks = grid.each_line(chomp: true).map { |line|
    width ||= line.size
    raise "inconsistent width #{width} != #{line.size}" if width != line.size

    b = 0
    r = 0

    line.each_char { |c|
      b <<= 1
      r <<= 1
      case c
      when ?#; b |= 1
      when ?O; r |= 1
      when ?.; #ok
      else raise "bad char #{c}"
      end
    }

    [b, r]
  }.transpose

  height = blocks.size

  blocks.freeze

  left_col = 1 << (width - 1)
  right_col = 1

  cycle1bil { |t|
    loop {
      any_move = false
      (1...height).each { |i|
        can_move_up = rocks[i] & ~rocks[i - 1] & ~blocks[i - 1]
        any_move ||= can_move_up != 0
        rocks[i] &= ~can_move_up
        rocks[i - 1] |= can_move_up
      }
      break unless any_move
    }
    loop {
      any_move = false
      rocks.each_index { |i|
        rocksi = rocks[i]
        can_move_left = rocksi & ~((rocksi | blocks[i]) >> 1) & ~left_col
        any_move ||= can_move_left != 0
        rocks[i] = rocksi & ~can_move_left | can_move_left << 1
      }
      break unless any_move
    }
    loop {
      any_move = false
      (1...height).each { |negi|
        i = height - 1 - negi
        can_move_down = rocks[i] & ~rocks[i + 1] & ~blocks[i + 1]
        any_move ||= can_move_down != 0
        rocks[i] &= ~can_move_down
        rocks[i + 1] |= can_move_down
      }
      break unless any_move
    }
    loop {
      any_move = false
      rocks.each_index { |i|
        rocksi = rocks[i]
        can_move_right = rocksi & ~((rocksi | blocks[i]) << 1) & ~right_col
        any_move ||= can_move_right != 0
        rocks[i] = rocksi & ~can_move_right | can_move_right >> 1
      }
      break unless any_move
    }

    rocks.dup.freeze
  }

  rocks.each_with_index.sum { |row, y| (height - y) * row.to_s(2).count(?1) }
end

results = {}

grid = ARGF.read.chomp.freeze

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, grid) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
