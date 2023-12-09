puts ARGF.each_with_object([nil, 0, 0]) { |line, part|
  hist = line.split.map(&method(:Integer)).freeze
  l = r = 0
  lmult = 1

  until hist.all?(0)
    l += hist[0] * lmult
    r += hist[-1]
    lmult = -lmult
    hist = hist.each_cons(2).map { |a, b| b - a }.freeze
  end

  part[1] += r
  part[2] += l
}.compact
