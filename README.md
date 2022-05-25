# Jukebox Index Shuffle

Robert Lee, 24th May 2022

## Rationale

The *Fisher-Yates* Shuffling algorithm is fast, well understood and
provides for "true" shuffling of elements in a uniform distribution;
given a truly random number source with configurable bounds, it will
produce a truly shuffled list, in which the available options for the
Nth value in the list are predictable given the previous (N-1) values,
but the actual Nth value is not predictable.

A "truly" shuffled list is useful for implementing games of chance
like Poker, where the randomness of a shuffle is essential to avoid
cheating, and it may also have some cryptogrophic applications.

However, a truly shuffled list has a non-negligible chance of
"clumping": if the Nth element in the shuffled list is the Mth element
in the original list, then the (N+1)th element could just as easily be
the (M+1)th element - or the (M-1)th element - as any other. For some
applications, this is undesirable: For a jukebox programme, this can
result in songs from the same artist/album being played in a run even
in "shuffle" mode; for interactive fiction, this can result in entry N
saying "turn to N+1", increasing the temptation of cheating.

The chance of "clumping" decreases in exponential decay as the number
of elements in the list increases. But as the number of elements
becomes larger, the cost of fixing this "clumping" by simply testing the
list and reshuffling until the clumping is eliminated, significantly
increases the computation time.

So a new algorithm was developed that:

* Is order(N) to shuffling a list of N elements
* Dramatically reduces or eliminates the chance of adjacent elements
  in the original list being adjacent in the shuffled list
* Is not a true shuffle or cryptographically secure.

NB: The author is developing this algorithm for an application that
requires certain elements to be sorted to known positions in the final
list, and notes on this application will be given throughout.


## Inputs and Outputs

The algorithm requires a pseudo-random number generator, which is
assumed to produce a non-predictable number between configurable
bounds with O(1).

* This will be represented as the function rnd(a,b), where a is the
  lower bound and b is the upper bound. Any number between a
  (inclusive) and b (inclusive) may be returned, in roughly uniform
  distribution.

The algorithm will require swapping of two elements in the array

* This is the function swap(E[i], E[j]), where i and j are 1-based indexes.

The second input is N, which is the number of data to be shuffled.

* The only requirement on the data is that it be a positional and
  contiguous data structure. The data and its container are not
  changed by this algorithm (rather, the algorithm returns a list of
  indicies onto this data structure).


We also need to consider how close in the original list a pair of
elements need to be to be considered clumped. This "target number" is
typically 1 for adjacent entries, but could be higher to enforce more
distance between adjacent entries.

* T represents the target number (typically 1).


The output is an array of size N, which returns offsets into the
original data structure. The offset into the first element may be 0,
1, or any other number (including complex or irrational numbers);
subsequent elements will have an additional offset of 1 per element
from the original.

* E[1..N] represents the output index array.
* O represents the offset of the first element in the original data.

NB: To iterate over the data in shuffled order, the caller should
iterate over the output of this algorithm, and look up the
corresponding value by index in the original data set.


## The algorithm

Let i,j and t be variables of numeric type.

1. Initialise the index array to be sorted

```
for i (1..N)
  let E[i] := i+O-1
```

2. Perform an O(1) Fisher-Yates shuffle on the index array

```
for i (i..N-1)
  let j := rnd(i+1, N)
  swap (E[i], E[j])
```

3. Reduce clumping (forward pass)

```
for i (i..N-2)
  if E[i] = E[i+1] ± 1
    let j := rnd(i+2, N)
    swap (E[i+1], E[j])
```

* The algorithm also performs satisfactorily if the last line is
  replaced with swap(E[i], E[j]); however, E[i+1] is usually preferred
  as it will also eliminate clumps of 3 runs. In the case where
  specific indexes are required, the use of the alternate swap may be
  required to avoid a specific index from being moved.


## Alternates

50000 attempts were tested with each alternative method.

The effectiveness of this algorithm is pretty good; in testing of
N=50,1000,and 10,000 this reduced the number of adjacent indexes (ascending or
descending) to 0 in all cases. The performance remains O(1).

However, improvements are possible with a small performance cost:

# Repeating Step 3

Simply repeating step 3 a second time reduced the number to 0 in over
all test cases.

This remains O(1), although it means a third pass through the loop.

# Reverse pass

4. Reduce clumping (reverse pass)

```
for i (N-2..1)
  if abs(E[i] - E[i+1]) ≤ T
    let j := rnd(1, i-1)
    swap (E[i+1], E[j])
```

This second pass means that all clumps can be removed with roughly equal
probability, as well as providing a second pass.

With a target number of 1, this also reduced the number of "clumps" to 0
in all test cases.

This was expected to outperform the 2-pass forward method; however, in
testing, the results were often comparable, or worse for larger
arrays, unless the number of "clumps" were larger than around 0.5%.

# Increasing target number

For a true jukebox shuffle, it may be desirable to eliminate more
matches than simply adjacent. One method to do this is to increase the
target number, such that adjacent values in the output will be
considered adjacent if they are within T spaces of the original input value.

# Increasing distance

As well as increasing the target number (distance between elements in
the input), there is an argument for also increasing the distance of
elements considered in the output beyond simply comparing adjacent
elements. An application for this algorithm is not readily
apparent, but this could be achieved by replacing step 3 with the
following:

```
for i (i..N-1-T)
  for t in (i+1..i+T)
    if abs(E[i] - E[t]) ≤ T
      let j := rnd(i+T+1, N)
      swap (E[t], E[j])
```

This would increase the algorithmic complexity to O(NT), but as T
must be much smaller than N, this might effectively be considered as
O(N) in most cases.

This approach was not tested, as no application was considered for it.

* Where an entry with a fixed destination is to be supported, this
  becomes harder to accommodate properly. Should E[t] be such an
  entry, it would be necessary to move E[i] instead; however, this
  suggests that we should at this point restart the inner loop for
  t. This would again increase the complexity of the algorithm.


# Test results

The following results were obtained (percentage values shown are the
average number of adjacent pairs set within T spaces of their original
positions, averaged over 50,000 executions):

| T | Number of entries | single fwd | double fwd | fwd & back |
|---|-------------------|------------|------------|------------|
| 1 | 50	              |  0%        | 0%		| 0% |
| 1 | 1000              |  0%        | 0%		| 0% |
| 1 | 10000             |  0%        | 0%		| 0% |
| 2 | 50     	      |  7.058%	   | 3.848%     | 3.83% |
| 2 | 1000	      |  0.348%	   | 0.176%     | 0.218% |
| 2 | 10000             |  0.048%	   | 0.012%     | 0.028% |
| 3 | 50     	      | 25.806%	   | 9.562%     | 8.758% |
| 2 | 1000	      |  1.588%	   | 0.468%     | 0.364% |
| 2 | 10000             |  0.15%     | 0.03%	| 0.038% |
