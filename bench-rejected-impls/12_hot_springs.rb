require 'benchmark'

# A number of interesting approaches to this one.
# In general, the fastest ones are (in order) ltr_groupwise_int, dp_local_cache_int, and nfa_str
# I will likely stick with dp_local_cache_int since its concept is the simplest.

slow = ARGV.delete('-s')

BIT = {?. => 1, ?# => 2, ?? => 3}.freeze

def repeat(s, is, groups, n)
  [([s] * n).join(??), (([BIT.fetch(??)] + is) * n).drop(1), groups * n].map(&:freeze).freeze
end

bench_candidates = []

bench_candidates << def dp_global_cache_int(springs)
  cache = {}

  ways = ->(s, groups) {
    cache[[s, groups]] ||= begin
      if s.empty?
        groups.empty? ? 1 : 0
      elsif groups.empty?
        s.include?(2) ? 0 : 1
      elsif s.size < groups.sum + groups.size - 1
        0
      elsif s[0] == 1
        ways[s[1..], groups]
      elsif s[0] == 2
        group, *rest = groups
        if s[1...group].include?(1) || s[group] == 2
          0
        else
          ways[s[(group + 1)..] || [], rest]
        end
      elsif s[0] == 3
        ways[s[1..].unshift(1), groups] + ways[s[1..].unshift(2), groups]
      else raise "bad s #{s}"
      end
    end
  }

  springs.sum { |_, is, g| ways[is, g] }
end if slow

bench_candidates << def dp_global_cache_str(springs)
  cache = {}

  ways = ->(s, groups) {
    cache[[s, groups]] ||= begin
      if s.empty?
        groups.empty? ? 1 : 0
      elsif groups.empty?
        s.include?(?#) ? 0 : 1
      elsif s.size < groups.sum + groups.size - 1
        0
      elsif s[0] == ?.
        ways[s[1..], groups]
      elsif s[0] == ?#
        group, *rest = groups
        if s[1...group].include?(?.) || s[group] == ?#
          0
        else
          ways[s[(group + 1)..] || '', rest]
        end
      elsif s[0] == ??
        ways[?. + s[1..], groups] + ways[?# + s[1..], groups]
      else raise "bad s #{s}"
      end
    end
  }

  springs.sum { |s, _, g| ways[s, g] }
end if slow

bench_candidates << def dp_local_cache_int(springs)
  springs.sum { |_, s, groups|
    cache = {}

    cur_shift = s.size.bit_length
    gi_shift = groups.size.bit_length

    # i = string index
    # gi = group index
    ways = ->(i, gi, cur_group_size) {
      if i == s.size
        if gi == groups.size && cur_group_size == 0
          return 1
        elsif gi == groups.size - 1 && groups[gi] == cur_group_size
          return 1
        else
          return 0
        end
      end

      cache_key = i << (gi_shift + cur_shift) | gi << cur_shift | cur_group_size
      #@cache_stat[cache.has_key?(cache_key) ? :hit : :miss] += 1
      cache[cache_key] ||= begin
        c = s[i]
        (c & 1 == 0 ? 0 : if cur_group_size == 0
          ways[i + 1, gi, 0]
        elsif cur_group_size == groups[gi]
          ways[i + 1, gi + 1, 0]
        else
          0
        end) + (c & 2 == 0 || gi >= groups.size || cur_group_size >= groups[gi] ? 0 : ways[i + 1, gi, cur_group_size + 1])
      end
    }

    ways[0, 0, 0]
  }
end

bench_candidates << def dp_local_cache_str(springs)
  springs.sum { |s, _, groups|
    cache = {}

    cur_shift = s.size.bit_length
    gi_shift = groups.size.bit_length

    # i = string index
    # gi = group index
    ways = ->(i, gi, cur_group_size) {
      if i == s.size
        if gi == groups.size && cur_group_size == 0
          return 1
        elsif gi == groups.size - 1 && groups[gi] == cur_group_size
          return 1
        else
          return 0
        end
      end

      cache_key = i << (gi_shift + cur_shift) | gi << cur_shift | cur_group_size
      #@cache_stat[cache.has_key?(cache_key) ? :hit : :miss] += 1
      cache[cache_key] ||= begin
        case s[i]
        when ?.
          if cur_group_size == 0
            ways[i + 1, gi, 0]
          elsif cur_group_size == groups[gi]
            ways[i + 1, gi + 1, 0]
          else
            0
          end
        when ?#
          groups[gi]&.>(cur_group_size) ? ways[i + 1, gi, cur_group_size + 1] : 0
        when ??
          (groups[gi]&.>(cur_group_size) ? ways[i + 1, gi, cur_group_size + 1] : 0) + if cur_group_size == 0
            ways[i + 1, gi, 0]
          elsif cur_group_size == groups[gi]
            ways[i + 1, gi + 1, 0]
          else
            0
          end
        else raise "bad char at #{i} #{s[i]}"
        end
      end
    }

    ways[0, 0, 0]
  }
end

bench_candidates << def ltr_cellwise_arrays(springs)
  springs.sum { |_, s, groups|
    s.reduce({[0, 0].freeze => 1}) { |freq, c|
      freq.each_with_object(Hash.new(0)) { |((gi, cur_group_size), v), new_freq|
        if c & 1 != 0
          if cur_group_size == 0
            new_freq[[gi, 0]] += v
          elsif cur_group_size == groups[gi]
            new_freq[[gi + 1, 0]] += v
          end
        end
        if c & 2 != 0 && groups[gi]&.>(cur_group_size)
          new_freq[[gi, cur_group_size + 1]] += v
        end
      }
    }.sum { |(gi, cur_group_size), v|
      gi == groups.size && cur_group_size == 0 || gi == groups.size - 1 && groups[gi] == cur_group_size ? v : 0
    }
  }
end

bench_candidates << def ltr_cellwise_compress(springs)
  springs.sum { |_, s, groups|
    cur_shift = s.size.bit_length
    cur_mask = (1 << cur_shift) - 1
    gi_shift = groups.size.bit_length
    gi_mask = (1 << gi_shift) - 1

    s.reduce({0 => 1}) { |freq, c|
      freq.each_with_object(Hash.new(0)) { |(k, v), new_freq|
        cur_group_size = k & cur_mask
        gi = (k >> cur_shift) & gi_mask
        if c & 1 != 0
          if cur_group_size == 0
            new_freq[gi << cur_shift] += v
          elsif cur_group_size == groups[gi]
            new_freq[(gi + 1) << cur_shift] += v
          end
        end
        if c & 2 != 0 && groups[gi]&.>(cur_group_size)
          new_freq[gi << cur_shift | cur_group_size + 1] += v
        end
      }
    }.sum { |k, v|
      cur_group_size = k & cur_mask
      gi = (k >> cur_shift) & gi_mask
      gi == groups.size && cur_group_size == 0 || gi == groups.size - 1 && groups[gi] == cur_group_size ? v : 0
    }
  }
end

# https://www.reddit.com/r/adventofcode/comments/18ge41g/2023_day_12_solutions/kd0um89/
# https://github.com/szeweq/aoc2023/blob/master/src/bin/12.rs
# https://www.reddit.com/r/adventofcode/comments/18gw8mm/2023_day_12_part_2_what_is_the_fastest_possible/
bench_candidates << def ltr_groupwise_int(springs)
  springs.sum { |_, s, groups|
    s = [1] + s
    s.pop while s[-1] == 1
    s.freeze
    sz = s.size + 1
    oldstate = Array.new(sz, 0)
    newstate = Array.new(sz, 0)
    oldstate[0] = 1
    (1...s.size).each { |i|
      break if s[i] == 2
      oldstate[i] = 1
    }

    groups.each { |group|
      cur_group_size = 0
      s.each_with_index { |c, i|
        if c == 1
          cur_group_size = 0
        else
          cur_group_size += 1
        end
        newstate[i + 1] += newstate[i] if c != 2
        newstate[i + 1] += oldstate[i - group] if cur_group_size >= group && s[i - group] != 2
      }
      oldstate.fill(0)
      newstate, oldstate = [oldstate, newstate]
    }

    oldstate[sz - 1]
  }
end

# https://www.reddit.com/r/adventofcode/comments/18ge41g/2023_day_12_solutions/kd0um89/
# https://github.com/szeweq/aoc2023/blob/master/src/bin/12.rs
# https://www.reddit.com/r/adventofcode/comments/18gw8mm/2023_day_12_part_2_what_is_the_fastest_possible/
bench_candidates << def ltr_groupwise_str(springs)
  springs.sum { |s, _, groups|
    s = ?. + s
    s.delete_suffix!(?.) while s[-1] == ?.
    s.freeze
    sz = s.size + 1
    oldstate = Array.new(sz, 0)
    newstate = Array.new(sz, 0)
    oldstate[0] = 1
    (1...s.size).each { |i|
      break if s[i] == ?#
      oldstate[i] = 1
    }

    groups.each { |group|
      cur_group_size = 0
      s.each_char.with_index { |c, i|
        if c == ?.
          cur_group_size = 0
        else
          cur_group_size += 1
        end
        newstate[i + 1] += newstate[i] if c != ?#
        newstate[i + 1] += oldstate[i - group] if cur_group_size >= group && s[i - group] != ?#
      }
      oldstate.fill(0)
      newstate, oldstate = [oldstate, newstate]
    }

    oldstate[sz - 1]
  }
end

# https://www.reddit.com/r/adventofcode/comments/18ge41g/2023_day_12_solutions/kd93dvp/
# https://github.com/clrfl/AdventOfCode2023/tree/master/12
# NFA with self-transition on the . states.
bench_candidates << def nfa_str(springs)
  springs.sum { |s, _, groups|
    # 1 = #, 0 = .
    # 1, 2, 3 turns into 0b111011010
    states = groups.reverse.reduce(0) { |x, g|
      x << (g + 1) | ((1 << g) - 1) << 1
    }
    nstates = 1 + states.bit_length
    freq = {0 => 1}
    s.each_char { |c|
      next_freq = Hash.new(0)
      freq.each { |state, n|
        case c
        when ??
          next_freq[state + 1] += n if state + 1 < nstates
          next_freq[state] += n if states[state] == 0
        when ?.
          next_freq[state + 1] += n if state + 1 < nstates && states[state + 1] == 0
          next_freq[state] += n if states[state] == 0
        when ?#
          next_freq[state + 1] += n if state + 1 < nstates && states[state + 1] != 0
        else raise "bad #{c}"
        end
      }
      freq = next_freq
    }
    freq.fetch(nstates - 1, 0) + freq.fetch(nstates - 2, 0)
  }
end

# https://www.reddit.com/r/adventofcode/comments/18ge41g/2023_day_12_solutions/kd93dvp/
# https://github.com/clrfl/AdventOfCode2023/tree/master/12
# NFA with self-transition on the . states.
bench_candidates << def nfa_int(springs)
  springs.sum { |_, s, groups|
    # 1 = #, 0 = .
    # 1, 2, 3 turns into 0b111011010
    states = groups.reverse.reduce(0) { |x, g|
      x << (g + 1) | ((1 << g) - 1) << 1
    }
    nstates = 1 + states.bit_length
    freq = {0 => 1}
    s.each { |c|
      next_freq = Hash.new(0)
      freq.each { |state, n|
        next_freq[state] += n if states[state] == 0 && c & 1 != 0
        next_freq[state + 1] += n if state + 1 < nstates && c[states[state + 1]] != 0
      }
      freq = next_freq
    }
    freq.fetch(nstates - 1, 0) + freq.fetch(nstates - 2, 0)
  }
end

results = {}

springs = ARGF.map { |line|
  s, groups = line.split(' ', 2)
  is = s.chars.map { |c| BIT.fetch(c) }.freeze
  groups = groups.split(?,).map(&method(:Integer))
  repeat(s, is, groups, 5)
}.compact

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 1.times { results[f] = send(f, springs) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
