require 'benchmark'

bench_candidates = []

bench_candidates << def diff(hists)
  l = r = 0
  hists.each { |hist|
    lmult = 1

    until hist.all?(0)
      l += hist[0] * lmult
      r += hist[-1]
      lmult = -lmult
      hist = hist.each_cons(2).map { |a, b| b - a }.freeze
    end
  }
  [r, l]
end

# https://www.youtube.com/watch?v=4AuV93LOPcE
# 0 0 0 1 4 10 20
#  0 0 1 3 6 10
#   0 1 2 3 4
#    1 1 1 1
#     0 0 0
# Pascal's triangle
# about 8x faster but I don't understand it as well (yet?) so I won't use it yet
bench_candidates << def binom(hists)
  l = r = 0
  coeff = []
  hists.each { |hist|
    # coeff[k] = k C 1, -(k C 2), k C 3... (k C k) * (-1 ** (k - 1))
    # (we don't need k choose 0)
    coeff[hist.size] ||= begin
      prev = -1
      c = (1..hist.size).map { |i|
        prev = -prev * (hist.size - i + 1) / i
      }.freeze
      [c, c.reverse.freeze].freeze
    end

    hist.zip(*coeff[hist.size]).each { |h, cl, cr|
      r += h * cr
      l += h * cl
    }
  }
  [r, l]
end

hists = ARGF.map { |l| l.split.map(&method(:Integer)).freeze }.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, hists) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
