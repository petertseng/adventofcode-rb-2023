expand_factor = if narg = ARGV.find { |x| x.start_with?('-n') }
  ARGV.delete(narg)
  Integer(narg[2..])
else
  1_000_000
end

galaxy = ARGF.flat_map.with_index { |line, y|
  line.gsub(?#).map { [y, Regexp.last_match.begin(0)].freeze }.freeze
}.freeze

# ys are guaranteed to come in sorted order; xs aren't
gal_ys = galaxy.map(&:first).tally.freeze
gal_xs = galaxy.map(&:last).sort.tally.freeze

puts [2, expand_factor].map { |n|
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
}
