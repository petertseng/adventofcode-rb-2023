engine = ARGF.map(&:chomp).map(&:freeze).freeze
width = engine.map(&:size).max

part_numbers = 0
gear = Hash.new { |h, k| h[k] = [] }

engine.each_with_index { |line, y|
  nums = line.gsub(/\d+/).map { [Integer(_1), Regexp.last_match.begin(0)] }.freeze
  above = y == 0 ? nil : engine[y - 1]
  below = engine[y + 1]

  nums.each { |num, x|
    left = x == 0 ? 0 : x - 1
    right = x + num.to_s.size

    any_sym = false
    [above, line, below].each.with_index(-1) { |row, dy|
      next unless row
      (left..right).each { |xx|
        c = row[xx]
        gear[(y + dy) * width + xx] << num if c == ?*
        any_sym ||= c && c != ?. && !(?0..?9).cover?(c)
      }
    }
    part_numbers += num if any_sym
  }
}

puts part_numbers
puts gear.values.sum { |a, b, c| a * (b || 0) * (c ? 0 : 1) }
