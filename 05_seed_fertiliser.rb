verbose = ARGV.delete('-v')

def loc(seeds, maps, verbose: false)
  seeds = case seeds.map(&:class).uniq
  when [Integer]; seeds.map { |v| v..v }.freeze
  when [Range]; seeds.freeze
  else raise "bad seeds #{seeds}"
  end

  maps.reduce(seeds) { |currents, map|
    currents.flat_map { |cur_range|
      intersected = map.filter_map { |range, diff|
        [rangeinter(cur_range, range), diff].freeze if rangeinter?(cur_range, range)
      }.freeze
      unintersected = rangeminus(cur_range, intersected.map(&:first))
      puts "#{cur_range} intersected: #{intersected}, unintersected: #{unintersected}" if verbose
      merge((intersected.map { |rng, diff| (rng.begin + diff)..(rng.end + diff) } + unintersected).sort_by(&:begin))
    }.tap { |v| puts "step: #{v}" if verbose }
  }.map(&:begin).min
end

# Assumes without checking that input intervals are sorted by start time.
def merge(intervals, merge_adjacent: true)
  prev_min = intervals[0].begin
  prev_max = intervals[0].end
  (intervals.each_with_object([]) { |r, merged|
    if r.begin > prev_max + (merge_adjacent ? 1 : 0)
      merged << (prev_min..prev_max)
      prev_min = r.begin
      prev_max = r.end
    else
      prev_max = [prev_max, r.end].max
    end
  } << (prev_min..prev_max)).freeze
end

def rangeminus(a, bs)
  bs = [bs] unless bs.is_a?(Array)
  # Kind of like 2016 day 20, but now need to output intervals
  unintersected_start = a.begin
  bs.sort_by(&:begin).filter_map { |b|
    (b.begin > unintersected_start && (unintersected_start..[b.begin - 1, a.end].min)).tap {
      unintersected_start = [b.end + 1, unintersected_start].max
    }
  }.tap { |unintersected|
    unintersected << (unintersected_start..a.end) if unintersected_start <= a.end
  }.freeze
end

def rangeinter(a, b)
  [a.begin, b.begin].max..[b.end, a.end].min
end

def rangeinter?(a, b)
  a.begin <= b.end && b.begin <= a.end
end

seeds_line = ARGF.readline("\n\n", chomp: true)
raise "bad seeds line #{seeds_line}" unless seeds_line.start_with?('seeds: ')
seeds = seeds_line.split(?:, 2)[1].split.map(&method(:Integer)).freeze

expected_map = 'seed'.freeze

maps = ARGF.each_line("\n\n", chomp: true).map { |map|
  ranges = map.lines(chomp: true)
  desc = ranges.shift
  raise "bad map #{desc} wasn't #{expected_map}" unless desc.start_with?("#{expected_map}-to-") && desc.end_with?(' map:')
  expected_map = desc.split[0].split(?-)[2].freeze
  ranges.map { |r|
    a, b, c = r.split.map(&method(:Integer))
    [b..(b + c - 1), a - b].freeze
  }.freeze
}.freeze

raise "last map to #{expected_map} wasn't location" if expected_map != 'location'

p loc(seeds, maps, verbose: verbose)
p loc(seeds.each_slice(2).map { |a, b| a..(a + b - 1) }, maps, verbose: verbose)
