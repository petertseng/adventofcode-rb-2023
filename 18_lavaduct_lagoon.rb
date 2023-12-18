def area(ys, xs, steps)
  perimeter = steps.sum
  internal_area = (xs.zip(ys.rotate(1)).sum { |a, b| a * b } - ys.zip(xs.rotate(1)).sum { |a, b| a * b }).abs
  (perimeter + internal_area) / 2 + 1
end

y1 = 0
x1 = 0
y2 = 0
x2 = 0

ys1, xs1, steps1, ys2, xs2, steps2 = ARGF.map { |line|
  dir1, steps1, colour = line.split
  steps1 = Integer(steps1)

  case dir1
  when ?U; y1 -= steps1
  when ?D; y1 += steps1
  when ?L; x1 -= steps1
  when ?R; x1 += steps1
  else raise "bad dir #{dir1}"
  end

  raise "bad colour #{colour}" unless colour.size == 9 && colour.start_with?('(#') && colour.end_with?(?))

  steps2 = Integer(colour[2, 5], 16)
  case colour[-2]
  when ?0; x2 += steps2
  when ?1; y2 += steps2
  when ?2; x2 -= steps2
  when ?3; y2 -= steps2
  else raise "bad colour dir #{colour}"
  end

  [y1, x1, steps1, y2, x2, steps2]
}.transpose.map(&:freeze)

puts area(ys1, xs1, steps1)
puts area(ys2, xs2, steps2)
