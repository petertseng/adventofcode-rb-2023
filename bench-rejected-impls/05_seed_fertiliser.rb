require 'benchmark'

bench_candidates = []

def interval_maybe_merge(seeds, maps, merge: false)
  maps.reduce(seeds) { |currents, map|
    currents.flat_map { |cur_range|
      intersected = map.filter_map { |range, diff|
        [rangeinter(cur_range, range), diff].freeze if rangeinter?(cur_range, range)
      }.sort_by { |range, _| range.begin }.freeze
      # Kind of like 2016 day 20, but now need to output intervals
      unintersected_start = cur_range.begin
      unintersected = intersected.filter_map { |range, _|
        # range.begin <= cur_range.end, because it's an intersection with cur_range.
        # so don't need to do [range.begin - 1, cur_range.end].min
        (range.begin > unintersected_start && (unintersected_start..(range.begin - 1))).tap {
          # ranges don't overlap here, so range.end + 1 would be sufficient
          # nothing like 1-100, 10-20,
          # in which case unintersected_start should remain 101 instead of reverting to 21,
          # but I'll keep it general so this remains usable in other contexts.
          unintersected_start = [range.end + 1, unintersected_start].max
        }
      }
      unintersected << (unintersected_start..cur_range.end) if unintersected_start <= cur_range.end
      if merge
        merge(intersected.map { |rng, diff| (rng.begin + diff)..(rng.end + diff) } + unintersected).sort_by(&:begin)
      else
        intersected.map { |rng, diff| (rng.begin + diff)..(rng.end + diff) } + unintersected
      end
    }
  }.map(&:begin).min
end

bench_candidates << def interval_no_merge(seeds, maps)
  interval_maybe_merge(seeds, maps, merge: false)
end

bench_candidates << def interval_yes_merge(seeds, maps)
  interval_maybe_merge(seeds, maps, merge: true)
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

def rangeinter(a, b)
  [a.begin, b.begin].max..[b.end, a.end].min
end

def rangeinter?(a, b)
  a.begin <= b.end && b.begin <= a.end
end

seeds_line = ARGF.readline(chomp: true)
raise "bad seeds line #{seeds_line}" unless seeds_line.start_with?('seeds: ')
seeds = seeds_line.split(?:, 2)[1].split.map(&method(:Integer)).freeze
seeds = seeds.each_slice(2).map { |a, b| a..(a + b - 1) }.freeze

ARGF.readline(chomp: true).tap { |s| raise "line 2 should be empty not #{s}" unless s.empty? }

expected_map = 'seed'.freeze

maps = ARGF.each_line("\n\n", chomp: true).map { |map|
  ranges = map.lines(chomp: true)
  desc = ranges.shift
  raise "bad map #{desc}" unless desc.start_with?("#{expected_map}-to-") && desc.end_with?(' map:')
  expected_map = desc.split[0].split(?-)[2].freeze
  ranges.map { |r|
    a, b, c = r.split.map(&method(:Integer))
    [b..(b + c - 1), a - b].freeze
  }.freeze
}.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, seeds, maps) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
