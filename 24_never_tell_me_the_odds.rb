require 'matrix'

verbose = ARGV.delete('-v')

testarea = if narg = ARGV.find { |x| x.start_with?('-n') }
  ARGV.delete(narg)
  Range.new(*narg[2..].split(?,, 2).map(&method(:Integer)))
else
  200000000000000..400000000000000
end

hail = ARGF.map { |line|
  ps, vs = line.split(' @ ', 2)
  [ps, vs].map { |xs| xs.split(', ', 3).map(&method(:Integer)) }.freeze
}.freeze

puts hail.map { |(px, py, _), (vx, vy, _)|
  [slope = Rational(vy, vx), py - slope * px, px, vx].freeze
}.combination(2).count { |(slope1, yinter1, px1, vx1), (slope2, yinter2, px2, vx2)|
  # m1x + b1 = m2x + b2
  # m1x - m2x = b2 - b1
  # x = (b2 - b1) / (m1 - m2)
  next false if slope1 == slope2
  x = Rational(yinter2 - yinter1, slope1 - slope2)
  y = slope1 * x + yinter1
  testarea.include?(y) && testarea.include?(x) && (x - px1) / vx1 > 0 && (x - px2) / vx2 > 0
}

# 6 unknowns: components of pr, components of vr
# each hailstone adds 3 equations and 1 unknown (ti)
# 3 hailstones is 9 equations and 9 unknowns
#
# pr + vr * ti = pi + vi * ti
# (pr - pi) = ti * (vi - vr)
# ti is a scalar, so pr - pi and vi - vr are parallel
# parallel vectors have cross product 0
# (pr - pi) x (vr - vi) = 0
# cross product distributes over addition
# pr x vr - pr x vi - pi x vr + pi x vi = 0
# pr x vr are common to all hailstones,
# so set the pr x vr of two hailstones equal to one another.
# 1 and 2
# pr x v1 + p1 x vr - p1 x v1 = pr x v2 + p2 x vr - p2 x v2
# (remember cross product is anticommutative)
# pr x (v1 - v2) + vr x (p2 - p1) = p1 x v1 - p2 x v2
# same for 1 and 3

#  A      x    =  b
# [...]  [pxr]   [...]
# [...]  [pyr]   [...]
# [...]  [pzr] = [...]
# [...]  [vxr]   [...]
# [...]  [vyr]   [...]
# [...]  [vzr]   [...]

def cross_product_matrix(v)
  # using the form defined in https://en.wikipedia.org/wiki/Cross_product#Conversion_to_matrix_multiplication:
  Matrix[
    [0, v[2], -v[1]],
    [-v[2], 0, v[0]],
    [v[1], -v[0], 0],
  ]
end

(p1, v1), (p2, v2), (p3, v3) = hail.take(3).map { |pv| pv.map { |vec| Vector[*vec] } }

apr12 = cross_product_matrix(v1 - v2)
avr12 = cross_product_matrix(p2 - p1)
a12 = apr12.hstack(avr12)
apr13 = cross_product_matrix(v1 - v3)
avr13 = cross_product_matrix(p3 - p1)
a13 = apr13.hstack(avr13)
a = a12.vstack(a13)

b12 = p1.cross_product(v1) - p2.cross_product(v2)
b13 = p1.cross_product(v1) - p3.cross_product(v3)
b = Matrix.column_vector(b12).vstack(Matrix.column_vector(b13))

x = a.inverse * b

puts x if verbose

puts x.column(0)[0..2].sum { |r| r.denominator == 1 ? r.to_i : (raise "#{r} non-integer") }
