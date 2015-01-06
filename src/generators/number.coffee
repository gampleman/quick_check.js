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
#     expect(([min, max]) -> min < max).forAll(qc.range())
#     expect(([min, max]) -> min <= max).forAll(qc.range.inclusive(qc.real))
#     expect(([min, max]) -> 0 <= min < max).forAll(qc.range(qc.ureal))
#     expect(([min, max]) -> 0 < min < max).forAll(qc.range(qc.natural))
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

# The dice generator takes a D&D style dice string and transforms it into a random
# number generator. This can serve as a very quick method how to quickly approximate
# distributions.
#
#     qc.dice('d3') == -> Math.ceil(qc.random() * 3)
#     qc.dice('d2 + d4 + 3') == ->
#       Math.ceil(qc.random() * 2) + Math.ceil(qc.random() * 4) + 3
#     qc.dice('2d6') == ->
#       Math.ceil(qc.random() * 6) + Math.ceil(qc.random() * 6)
qc.dice = (config) ->
  new Function (config.split(/\s*\+\s*/).reduce (code, arg) ->
    if match = arg.match(/(\d*)d(\d+)/)
      num = parseInt(match[1], 10) or 1
      max = parseInt match[2], 10
      if num < 5
        str = ''
        str += " + Math.ceil(qc.random() * #{max})" for i in [1..num]
        code + str
      else # we do not want to inline this loop
        code + " + (function() {
          var sum = 0;
          for (var i = 0; i < #{num}; i++) {
            sum += Math.ceil(qc.random() * #{max});
          }
          return sum;
        })()"
    else
      code + " + #{parseInt(arg)}"
  , 'return ') + ';'
