def ways_to_win(time, dist)
  # hold * (time - hold) - dist = 0
  # a = -1
  # b = 1
  # c = -dist
  sqrt_discrim = Math.sqrt(time ** 2 - 4 * dist)
  ((time + sqrt_discrim) / 2).ceil - ((time - sqrt_discrim) / 2).floor - 1
end

def travel(hold, time)
  hold * (time - hold)
end

verbose = ARGV.delete('-v')

times, dists = ARGF.zip(%w(Time: Distance:)).map { |line, expected|
  label, *nums = line.split
  raise "bad label #{label} != #{expected}" if label != expected
  nums.map(&method(:Integer)).freeze
}

puts times.zip(dists).map { |r| ways_to_win(*r) }.tap { p _1 if verbose }.reduce(1, :*)
puts ways_to_win(Integer(times.join), Integer(dists.join))
