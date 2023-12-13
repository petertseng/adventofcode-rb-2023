def reflect(xs)
  ls = [xs[0]]
  rs = xs[1..]

  (1...xs.size).map { |i|
    errors = ls.zip(rs).sum { |l, r| r ? l.zip(r).sum { |a, b| a ^ b } : 0 }
    [errors, i].tap { ls.unshift(rs.shift) }
  }
end

using(Module.new { refine(Array) {
  def find_one(&b)
    (found = select(&b)).size == 1 ? found[0] : (raise "didn't find exactly one: #{found}")
  end
}})

BIT = {?. => 0, ?# => 1}.freeze

puts ARGF.each_line("\n\n", chomp: true).with_object([nil, 0, 0]) { |diagram, part|
  vert = diagram.lines(chomp: true).map { |r| r.chars.map { |c| BIT.fetch(c) }.freeze }.freeze
  horiz = vert.transpose.map(&:freeze).freeze

  errors = reflect(vert).each { |ev| ev[1] *= 100 }.concat(reflect(horiz))

  part[1] += errors.find_one { |err, _| err == 0 }[1]
  part[2] += errors.find_one { |err, _| err == 1 }[1]
}.compact
