require 'benchmark'

bench_candidates = []

bench_candidates << def bsearch(time, dist)
  mid = time / 2
  left = (1..mid).bsearch { |hold| travel(hold, time) > dist }
  right = (mid..time).bsearch { |hold| travel(hold, time) <= dist }
  right - left
end

bench_candidates << def quadratic(time, dist)
  # hold * (time - hold) - dist = 0
  # a = -1
  # b = 1
  # c = -dist
  b2m4ac = Math.sqrt(time ** 2 - 4 * dist)
  ((time + b2m4ac) / 2).ceil - ((time - b2m4ac) / 2).floor - 1
end

def travel(hold, time)
  hold * (time - hold)
end

times, dists = ARGF.zip(%w(Time: Distance:)).map { |line, expected|
  label, *nums = line.split
  raise "bad label #{label} != #{expected}" if label != expected
  nums.map(&method(:Integer)).freeze
}

time = Integer(times.join)
dist = Integer(dists.join)

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 1000.times { results[f] = send(f, time, dist) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
