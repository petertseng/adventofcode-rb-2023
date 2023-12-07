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

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Past solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).
