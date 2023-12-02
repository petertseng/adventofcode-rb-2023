puts ARGF.each_with_object([nil, 0, 0]) { |line, part|
  game, cubes = line.split(?:, 2)

  raise "bad #{game}" unless game.start_with?('Game ')
  id = Integer(game[5..])

  r = g = b = 0
  cubes.split(/[,;]/).each { |v|
    n, c = v.split
    n = Integer(n)
    raise "bad #{n} in #{v}" if n <= 0
    case c
    when 'red';   r = [r, n].max
    when 'green'; g = [g, n].max
    when 'blue';  b = [b, n].max
    else raise "bad #{c} in #{v}"
    end
  }

  part[1] += id if r <= 12 && g <= 13 && b <= 14
  part[2] += r * g * b
}.compact
