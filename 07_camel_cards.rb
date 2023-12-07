CARDRANK = %w(2 3 4 5 6 7 8 9 T J Q K A).each_with_index.to_h.freeze

# natural sort order already sorts hand types correctly
# [5], [4, 1], [3, 2], [3, 1, 1], [2, 2, 1], [2, 1, 1, 1], [1, 1, 1, 1, 1]

def hand(ranks, jokers)
  rank_freq = ranks.tally.freeze
  freq_freq = rank_freq.values.sort
  # best choice for joker is to be a copy of the hand's most frequent card
  if freq_freq.empty?
    freq_freq = [jokers]
  else
    freq_freq[-1] += jokers
  end
  freq_freq.reverse.freeze
end

hands_and_bids = ARGF.map { |line|
  cards, bid = line.split
  # original never used again, but keep for ease of understanding
  [cards.freeze, cards.chars.map { |c| CARDRANK.fetch(c) }.freeze, Integer(bid)].freeze
}

winnings = ->hands { hands.each.with_index(1).sum { |(_, _, b), i| b * i } }

hands_and_bids.sort_by! { |_, h, _| [hand(h, 0), h] }
p winnings[hands_and_bids]

joker = CARDRANK[?J]
hands_and_bids.sort_by! { |_, h, _| [hand(h.reject { |c| c == joker }, h.count(joker)), h.map { |c| c == joker ? -Float::INFINITY : c }] }
p winnings[hands_and_bids]
