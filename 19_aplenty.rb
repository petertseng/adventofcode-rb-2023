verbose = if ARGV.delete('-vv')
  2
elsif ARGV.delete('-v')
  1
end

MINVAL = 1
MAXVAL = 4000
VALRANGE = MINVAL..MAXVAL

def num_accept(workflows, name, part, indent: 0, verbose: nil)
  if name == ?R
    puts "#{'  ' * indent}reject #{part}" if verbose
    return 0
  end
  if name == ?A
    size = part.values.map(&:size).reduce(1, :*)
    puts "#{'  ' * indent}accept #{part} #{size}" if verbose
    return size
  end

  current_parts = [part.freeze].freeze

  workflows[name].each_with_index.sum { |(cat, rule_range, if_in_range), i|
    new_current_parts = []
    current_parts.sum { |current_part|
      cur_range = current_part.fetch(cat)

      intersected = [rangeinter(cur_range, rule_range)].reject { |v| v.size == 0 }.freeze
      unintersected = rangeminus(cur_range, rule_range)

      intersected.sum { |inter|
        puts "#{'  ' * indent}#{name} #{i}: #{cat} matched #{inter} to #{if_in_range}" if verbose &.> 1
        num_accept(workflows, if_in_range, current_part.merge(cat => inter).freeze, indent: indent + 1, verbose: verbose)
      }.tap {
        # We could have put this concat before the intersected sum,
        # but the debug output ordering is clearer if it happens after the matched.
        new_current_parts.concat(unintersected.map { |u|
          puts "#{'  ' * indent}#{name} #{i}: #{cat} unmatched #{u} to next rule" if verbose &.> 1
          current_part.merge(cat => u).freeze
        })
      }
    }.tap { current_parts = new_current_parts.freeze }
  }.tap { raise "unprocessed parts #{current_parts}" if current_parts.any? }
end

def rule(r)
  return [:a, MINVAL..MAXVAL, r.freeze].freeze unless r.include?(?:)
  cond, if_in_range = r.split(?:)
  arg = Integer(cond[2..])
  range = case cond[1]
  when ?<; MINVAL..(arg - 1)
  when ?>; (arg + 1)..MAXVAL
  else raise "bad rule #{r}"
  end
  [cond[0].to_sym, range, if_in_range.freeze].freeze
end

def brackets(s)
  l, mr = s.split(?{, 2)
  m, bad = mr.split(?}, 2)
  raise "bad extra #{bad}" unless bad.empty?
  [l.freeze, m.split(?,).map(&:freeze).freeze].freeze
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

workflows = ARGF.take_while { |l| !l.chomp.empty? }.to_h { |line|
  name, rules = brackets(line.chomp)
  [name, rules.map(&method(:rule))]
}.freeze

puts ARGF.sum { |line|
  raise "bad part #{line}" unless line.start_with?(?{)
  part = brackets(line.chomp)[1].to_h { |kv|
    k, v = kv.split(?=)
    [k.to_sym, Integer(v)..Integer(v)]
  }
  num_accept(workflows, 'in', part) * part.values.sum(&:begin)
}

puts num_accept(workflows, 'in', {x: VALRANGE, m: VALRANGE, a: VALRANGE, s: VALRANGE}.freeze, verbose: verbose)
