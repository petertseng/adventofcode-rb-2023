BIT = {?. => 1, ?# => 2, ?? => 3}.freeze

def repeat(s, groups, n)
  [(([BIT.fetch(??)] + s) * n).drop(1), groups * n].map(&:freeze).freeze
end

#@cache_stat = {hit: 0, miss: 0}

def ways(s, groups)
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
end

puts ARGF.each_with_object([nil, 0, 0]) { |line, part|
  s, groups = line.split(' ', 2)
  s = s.chars.map { |c| BIT.fetch(c) }.freeze
  groups = groups.split(?,).map(&method(:Integer)).freeze

  part[1] += ways(s, groups)
  part[2] += ways(*repeat(s, groups, 5))
}.compact

#$stderr.puts(@cache_stat)
