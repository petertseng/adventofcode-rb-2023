verbose = ARGV.delete('-v')

left = {}
right = {}
dir = {?L => left, ?R => right}.freeze
dirs = ARGF.readline("\n\n", chomp: true).each_char.map { |c| dir.fetch(c) }.freeze

node = /^([A-Z0-9]{3}) = \(([A-Z0-9]{3}), ([A-Z0-9]{3})\)$/
ARGF.each_line(chomp: true) { |line|
  raise "bad #{line}" unless m = node.match(line)
  left[m[1]] = m[2].freeze
  right[m[1]] = m[3].freeze
}

left.freeze
right.freeze

def lens(dirs, start, ends, n: 5)
  current = start
  t = 0
  ts = []
  dirs.cycle { |map|
    current = map[current]
    t += 1
    if ends[current]
      ts << t
      return ts if ts.size >= n
    end
  }
end

puts lens(dirs, 'AAA', {'ZZZ' => true}.freeze, n: 1)
as = left.keys.select { |k| k.end_with?(?A) }.freeze
zs = left.select { |k| k.end_with?(?Z) }.freeze

# This would have been like 2020 day 13 or 2016 day 15,
# but for this day all offsets are 0.
# There is the matter of the example inputs that impose a minimum, though
periods, mins = as.map { |a|
  ls = lens(dirs, a, zs)
  diffs = ls.each_cons(2).map { |a, b| b - a }
  raise "unequal diffs #{diffs}" if diffs.uniq.size != 1
  raise "first hit not divisible by diff: #{ls} #{diffs}" if ls[0] % diffs[0] != 0
  [diffs[0], ls[0]]
}.transpose.map(&:freeze)
p periods if verbose

period = periods.reduce(1) { |a, b| a.lcm(b) }
min = mins.max
t = period + 0 # would be some other number if there were offsets
puts t >= min ? t : t + Rational(min - t, period).ceil * period
