part_2_only = ARGV.delete('-2')

# Note: no zero.
name = %w(one two three four five six seven eight nine).each.with_index(1).to_h.merge((?1..?9).to_h { |v| [v, Integer(v)] }).freeze
rev_name = name.transform_keys(&:reverse).freeze

fwd_regex = Regexp.union(*name.keys)
rev_regex = Regexp.union(*rev_name.keys)

puts ARGF.each_with_object([nil, part_2_only ? nil : 0, 0]) { |line, part|
  rev = line.reverse
  raise "zeroes in #{line}" if line.include?(?0)
  part[1] += Integer(line[/\d/] + rev[/\d/]) unless part_2_only
  part[2] += name.fetch(line[fwd_regex]) * 10 + rev_name.fetch(rev[rev_regex])
}.compact
