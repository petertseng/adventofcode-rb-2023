steps1, steps2 = if narg = ARGV.find { |x| x.start_with?('-n') }
  ARGV.delete(narg)
  Integer(narg[2..]).then { [_1, _1] }
else
  [64, 26501365]
end

start = nil

height = 0
width = nil

rockpos = ARGF.flat_map.with_index { |line, y|
  line.chomp!
  height += 1
  width ||= line.size
  raise "inconsistent width #{width} != #{line.size}" if width != line.size

  line.gsub(?S).map {
    x = Regexp.last_match.begin(0)
    raise "multi start #{start} #{y} #{x}" if start
    start = [y, x].freeze
  }.freeze

  line.gsub(?#).map { [y, Regexp.last_match.begin(0)].freeze }.freeze
}.freeze

rock = Array.new(height * width)
rockpos.each { |y, x| rock[y * width + x] = true }

def reach((sy, sx), rock, orig_height, orig_width, steps, wrap: false)
  width = wrap ? orig_width << 30 : orig_width
  orig_size = orig_height * orig_width
  # need to shift x coord, otherwise going to negative x is treated as subtracting 1 from y.
  poses = [sy * width + sx + (wrap ? orig_width << 29 : 0)]
  seen = {}
  dposes = [-width, -1, 1, width].freeze

  reach = Array.new(Array(steps).max + 1, 0)

  (1..Array(steps).max).each { |t|
    # poses = poses.flat_map { dposes.map { ... } } is 20% slower
    new_poses = []
    poses.each { |pos|
      dposes.each { |dpos|
        npos = pos + dpos
        next if seen[npos]
        ny, nx = npos.divmod(width)
        if wrap
          next if rock[(ny % orig_height) * orig_width + (nx % orig_width)]
        else
          next unless (0...orig_size).cover?(npos)
          next if dpos.abs == 1 && pos / orig_width != npos / orig_width
          next if rock[ny * orig_width + nx]
        end
        seen[npos] = true
        new_poses << npos
      }
    }
    poses = new_poses.freeze
    reach[t] = poses.size + reach[t - 2]
  }

  steps.is_a?(Array) ? steps.map { |s| reach[s] } : reach[steps]
end

puts reach(start, rock, height, width, steps1)
raise "non-square #{height} #{width}" if height != width

if steps2 <= width
  puts reach(start, rock, height, width, steps2, wrap: true)
  return
end

t, x0 = steps2.divmod(width)
# TODO: might it not be wiser to detect when accel has gone constant?
if width < 100
  adj = 4
  x0 += width * adj
  t -= adj
end
x1 = x0 + width
x2 = x1 + width
y0, y1, y2 = reach(start, rock, height, width, [x0, x1, x2], wrap: true)
vel = y1 - y0
accel = y2 - 2 * y1 + y0
puts y0 + vel * t + accel * t * (t - 1) / 2
