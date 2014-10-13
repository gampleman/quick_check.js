# ### Number generators

# Almost all number generators have a large variant for generating larger numbers,
# as the standard generators tend not to generate numbers bigger than 10,000. The
# generators prefixed with `u` generate only positive numbers.
qc.intUpto =  (size) -> Math.floor(qc.random() * size)

qc.ureal = (size) -> qc.random() * size * size
qc.ureal.large = -> qc.random() * Number.MAX_VALUE

qc.real =  (size) -> qc.choose(1, -1) * qc.ureal(size)
qc.real.large = -> qc.choose(1, -1) * qc.ureal.large()

qc.uint = (size) -> qc.intUpto(size * size)
qc.uint.large = -> Math.floor(qc.random() * Number.MAX_VALUE)

qc.int = (size) -> qc.choose(1, -1) * qc.intUpto(size)
qc.int.large = -> qc.choose(1, -1) * qc.uint.large()
qc.int.between = (min, max) ->
  (size) ->
    min + qc.intUpto(Math.min(max + 1 - min, size))

qc.natural = (size) -> qc.intUpto(size * size) + 1
qc.natural.large = -> Math.ceil(qc.random() * Number.MAX_VALUE)

# Range generators will generate an array of two numbers where the second is
# guaranteed to be larger than the first. i.e.
#
#    expect(function(r) { return r[0] < r[1]}).forAll(qc.range());
#    expect(function(r) { return r[0] <= r[1]}).forAll(qc.range.inclusive(qc.real));
#    expect(function(r) { return r[0] < r[1] && r[0] >= 0}).forAll(qc.range(qc.ureal));
#    expect(function(r) { return r[0] < r[1] && r[0] > 0}).forAll(qc.range(qc.natural));
qc.range = (gen = qc.real) ->
  (size) ->
    start = gen(size)
    end = start + Math.abs(gen(size))
    end += 1 if start is end
    [start, end]

qc.range.inclusive = (gen = qc.real) ->
  (size) ->
    start = gen(size)
    [start, start + Math.abs(gen(size))]
