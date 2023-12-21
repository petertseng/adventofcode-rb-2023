# adventofcode-rb-2023

For the ninth year in a row, it's the time of the year to do [Advent of Code](http://adventofcode.com) again.

The solutions are written with the following goals, with the most important goal first:

1. **Speed**.
   Where possible, use efficient algorithms for the problem.
   Solutions that take more than a second to run are treated with high suspicion.
   This need not be overdone; micro-optimisation is not necessary.
2. **Readability**.
3. **Less is More**.
   Whenever possible, write less code.
   Especially prefer not to duplicate code.
   This helps keeps solutions readable too.

All solutions are written in Ruby.
Features from 3.0.x will be used, with no regard for compatibility with past versions.
`Enumerable#to_h` with block is anticipated to be the most likely reason for incompatibility (will make it incompatible with 2.5).

# Input

In general, all solutions can be invoked in both of the following ways:

* Without command-line arguments, takes input on standard input.
* With command-line arguments, reads input from the named files (- indicates standard input).

Some may additionally support other ways:

* None yet

# Highlights

Favourite problems:

* None yet.

Interesting approaches:

* None yet.

# Takeaways

* Day 03 (Gear Ratios):
  Actually the first day in recent memory where my language knowledge was insufficient.
  I didn't know you could do a regex search that also tracked all matching indices.
  I thus tried to implement it myself
  (remembering to handle a number occurring twice in a line),
  but got it wrong in cases where a line contains both a number and a substring of that same number (81...8).
* Day 06 (Wait For It):
  I selected times between 0..7 instead of 0..t for some reason
  (because that was the time range of the example's first race)
  so I wasn't even getting the right answer on the full example.
  Very careless.
* Day 07 (Camel Cards):
  May have saved some time by copying a poker ranking I'd previously written,
  but then needed to tear out the full poker ranking
  (based on the ranks of the cards involved in making the hand its type).
  Still placed on part 1, so I guess it went okay.
  Wasted a lot of time on incorrect strategies for the jokers that were difficult to reason about,
  before coming up with one that was much simpler and obviously correct:
  Just case-by-case based on 5, 4, 3, 2, or 1 jokers.
  May be good to look for other simple and obviously correct solutions like that.
* Day 13 (Point of Incidence):
  Lost time on not removing newlines
  (I forgot to do it because the split was on \n\n this day instead of the more usual \n),
  and therefore some reflections were missed because \n is not equal to . or #.
* Day 15 (Lens Library):
  Lost a minute again on not removing the newline (since today's was a single line).
  Would have placed on both parts were it not for that.
* Day 16 (The Floor Will Be Lava):
  Some bug whose exact nature I don't remember,
  but that I failed to debug before printing out the visualisation of what cells were energised.
  Useful tool.
* Day 17 (Clumsy Crucible):
  I initially was worried that having to add direction and tiles traveled straight to state would mean the graph search would take too long.
  Thus I spent a few minutes deciding whether there was some viable dynamic programming solution instead.
  Failing to find one, only then did I decide to just implement the graph search and see how it went.
  I guess as long as it prunes previously-visited states, it's fine.
  Surprisingly still fast enough to place for part 2.
  (Note that I since improved my solution to only store one extra boolean in the state,
  but this discussion is about my day-of impressions)
* Day 18 (Lavaduct Lagoon):
  Actually, I forgot what I learned in day 10 for how to count points within polygon,
  since I forgot you only count vertical edges crossed and not horizontal.
  I needed to learn a new approach (shoelace formula) for part 2 anyway though.
  I'm surprised to see that this is applicable for any polygons, so this could be useful in the future.
  Alternative formulations for the same are the trapezoid formula and the triangle formula,
  all described at https://en.wikipedia.org/wiki/Shoelace_formula
* Day 19 (Aplenty):
  Unfortunate part 2 bug where I was carrying over the original range instead of the non-matching range to the next rule.
  Found the bug rather quickly when I started printing out the part intervals being considered at each step.
* Day 20 (Pulse Propagation):
  I believe I quickly understood the necessary task for part 2
  (look at what sends to rx, look at what sends to *that*, and look at when those go high).
  However, I had an unfortunate off-by-one
  (I was storing zero-indexed times instead of one-indexed number of button presses),
  so my first attempt was off by one and I didn't realize it for a number of minutes.
  Nevertheless I was still fast enough to place.
* Day 21 (Step Counter):
  Lost a bit of time on part 1 by thinking the elf can only step on `#` instead of `.`.
  That's just misreading on my part and I should have known it was out of character for Advent of Code,
  since traditionally `#` has always been inaccessible.
  I needed to go through a lot of failed part 2 approaches before I found the right one.
  I thought about counting the number of times a position is reached across all parallel universes,
  but a count is insufficient because you need to deduplicate points reached multiple times.
  I tried keeping the full list of parallel universes that have visited each position,
  but the lists grew too large to handle.
  Only after these two failed attempts did I give up and look for patterns every grid length steps.
  I lost a little more time by using an incorrectly-optimised algorithm that got step counts wrong.
  I reverted to the known-correct naive algorithm to actually get correct counts for 65, 196, and 327.

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Past solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).
