require 'benchmark'

bench_candidates = []

bench_candidates << def lazy_expand_pairs(universe, n)
  galaxy = universe.flat_map.with_index { |line, y|
    line.gsub(?#).map { [y, Regexp.last_match.begin(0)].freeze }.freeze
  }.freeze

  # ys are guaranteed to come in sorted order; xs aren't
  gal_ys = galaxy.map(&:first).tally.freeze
  gal_xs = galaxy.map(&:last).sort.tally.freeze

  [gal_ys, gal_xs].sum { |gals|
    gals.each_with_index.to_a.combination(2).sum { |((l, freql), i), ((r, freqr), j)|
      galaxy_steps = j - i
      non_galaxy_steps = r - l - galaxy_steps
      freql * freqr * (galaxy_steps + non_galaxy_steps * n)
    }
  }
end

bench_candidates << def lazy_expand_single_pass(universe, n)
  galaxy = universe.flat_map.with_index { |line, y|
    line.gsub(?#).map { [y, Regexp.last_match.begin(0)].freeze }.freeze
  }.freeze

  # ys are guaranteed to come in sorted order; xs aren't
  gal_ys = galaxy.map(&:first).tally.freeze
  gal_xs = galaxy.map(&:last).sort.tally.freeze

  [gal_ys, gal_xs].sum { |gals|
    galaxies_to_left = 0
    dists_to_left = 0
    prev = 0
    gals.sum { |x, freq|
      galaxy_steps = 1
      non_galaxy_steps = x - prev - galaxy_steps
      prev = x
      dists_to_left += galaxies_to_left * (galaxy_steps + non_galaxy_steps * n)
      galaxies_to_left += freq
      dists_to_left * freq
    }
  }
end

universe = ARGF.readlines(chomp: true).map(&:freeze).freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, universe, 1_000_000) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
