def hash(str)
  str.each_char.reduce(0) { |cv, c|
    (cv + c.ord) * 17 & 0xff
  }
end

ops = ARGF.read.chomp.split(?,).map(&:freeze).freeze
puts ops.sum(&method(:hash))

boxes = Hash.new { |h, k| h[k] = {} }
ops.each { |op|
  if op.include?(?=)
    label, foc = op.split(?=, 2).map(&:freeze)
    boxes[hash(label)][label] = Integer(foc)
  elsif op.end_with?(?-)
    label = op.delete_suffix(?-).freeze
    boxes[hash(label)].delete(label)
  end
}

puts boxes.sum { |boxno, lenses| (boxno + 1) * lenses.each_value.with_index(1).sum { |foc, i| foc * i } }
