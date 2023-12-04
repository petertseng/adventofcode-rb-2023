upcoming_mults = []

puts ARGF.each_with_object([nil, 0, 0]) { |line, part|
  cardno, card = line.split(?:)
  raise "not a card #{line}" unless cardno.match?(/^Card\s+\d+$/)
  win, mine = card.split(?|).map { |nums| nums.split.map(&method(:Integer)).freeze }
  win = win.to_h { |v| [v, true] }.freeze
  win_count = mine.count(&win)

  # Ruby does allow a left shift by -1 to mean a right shift by 1.
  part[1] += 1 << (win_count - 1)

  my_mult = 1 + (upcoming_mults.shift || 0)
  upcoming_mults.fill(0, upcoming_mults.size...win_count)
  win_count.times { |i| upcoming_mults[i] += my_mult }
  part[2] += my_mult
}.compact
