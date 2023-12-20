def components(io)
  dests = io.to_h { |line|
    name, my_dests = line.chomp.split(' -> ')
    [name.freeze, my_dests.split(', ').map(&:to_sym).freeze]
  }.to_h

  srcs = Hash.new { |h, k| h[k] = [] }
  dests.each { |s, ds| ds.each { |d| srcs[d] << s[1..].to_sym }}
  srcs.default_proc = nil
  srcs.each_value(&:freeze).freeze

  components = {
    rx: ->(_, _) { [].freeze },
    output: ->(_, _) { [].freeze },
  }.merge(dests.to_h { |name, my_dests|
    type = name[0]
    # NB: as a consequence, broadcaster will be renamed to roadcaster.
    name = name[1..].to_sym

    f = case type
    when ?&
      mem = srcs.fetch(name).to_h { |src| [src, false] }
      ->(sig, from) {
        mem[from] = sig
        out = !mem.values.all?
        my_dests.map { |d| [d, name, out].freeze }.freeze
      }
    when ?%
      mem = false
      ->(sig, _) {
        return [] if sig
        mem = !mem
        my_dests.map { |d| [d, name, mem].freeze }.freeze
      }
    when ?b
      raise "bad component #{name}" if name != :roadcaster
      ->(sig, _) {
        my_dests.map { |d| [d, name, sig].freeze }.freeze
      }
    else raise "bad component #{name}"
    end

    [name, f]
  }).freeze

  [srcs, components]
end

verbose = ARGV.delete('-v')
srcs, components = components(ARGF)

sigs = {true => 0, false => 0}

1000.times {
  q = [[:roadcaster, :button, false].freeze].freeze
  until q.empty?
    q = q.flat_map { |to, from, sig|
      sigs[sig] += 1
      components.fetch(to)[sig, from]
    }.freeze
  end
}

p sigs if verbose
puts sigs[true] * sigs[false]

# OK to be nil because examples do not have rx
rx_src = srcs[:rx]
raise 'rx has no inputs' if rx_src&.empty?
raise "rx has multiple #{rx_src}" if rx_src&.size &.> 1

unless rx_src = rx_src&.first
  puts 'no rx'
  exit(0)
end

high_time = srcs[rx_src].to_h { |s| [s, []] }.freeze

1001.step { |t|
  q = [[:roadcaster, :button, false].freeze].freeze
  until q.empty?
    q = q.flat_map { |to, from, sig|
      if sig && to == rx_src
        high_time[from] << t
        if high_time.values.all? { |v| v.size >= 3 }
          periods = high_time.values.map { |hts|
            hts.each.with_index(1).all? { |ht, i| ht == hts[0] * i } ? hts[0] : (raise "no period #{hts}")
          }.freeze
          p periods if verbose
          puts periods.reduce(1) { |a, b| a.lcm(b) }
          exit(0)
        end
      end
      components.fetch(to)[sig, from]
    }.freeze
  end
}
