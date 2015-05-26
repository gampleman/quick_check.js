# ### Number generators

adjust = (size) -> if size < 1 then Math.abs(size) + 1 else size
# Almost all number generators have a large variant for generating larger numbers,
# as the standard generators tend not to generate numbers bigger than 10,000. The
# generators prefixed with `u` generate only positive numbers.
qc.intUpto = (size) -> Math.floor(qc.random() * adjust size)

qc.ureal = (size) -> qc.random() * adjust(size * size)
qc.ureal.large = (size) -> qc.random() * Number.MAX_VALUE

qc.real =  (size) -> qc.choose(1, -1) * qc.ureal(size)
qc.real.large = (size) -> qc.choose(1, -1) * qc.ureal.large()

qc.uint = (size) -> qc.intUpto(adjust size * size)
qc.uint.large = (size) -> Math.floor(qc.random() * Number.MAX_VALUE)

qc.int = (size) -> qc.choose(1, -1) * qc.intUpto(adjust size)
qc.int.large = (size) -> qc.choose(1, -1) * qc.uint.large()
qc.int.between = (min, max) ->
  (size) ->
    min + qc.intUpto(Math.min(max + 1 - min, adjust size))

qc.natural = (size) -> qc.intUpto(adjust size * size) + 1
qc.natural.large = (size) -> Math.ceil(qc.random() * Number.MAX_VALUE)

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
  toks = config.trim()
  code = ''
  isConditional = no
  declaration = no
  consume = (n) -> toks = toks.substring(n)
  while toks.length > 0
    token = toks[0]
    switch
      when token is '+' then code += ' + '
      when token is '-' then code += ' - '
      when token is '*' then code += ' * '
      when token is '/' then throw new Error 'Division is currently not supported'
      when token is ' ' then code
      when token is '(' then code += '('
      when token is ')' then code += ')'
      when token is '?'
        isConditional = yes
        code += ' > 0 ? '
      when token is ':' and isConditional
        isConditional = no
        code += ' : '
      when match = toks.match(/^(\d*)d(\d+)/)
        num = parseInt(match[1], 10) or 1
        max = parseInt match[2], 10
        consume match[0].length - 1
        if num < 5
          code += '(' + ("Math.ceil(qc.random() * #{max})" for i in [1..num]).join(' + ') + ')'
        else # we do not want to inline this loop
          declaration = yes
          code += "d(#{num}, #{max})"
      when match = toks.match(/^(\d*)F/)
        num = parseInt(match[1], 10) or 1
        consume match[0].length - 1
        code += "(qc.random() <= #{Math.pow(0.5, num)} ? 1 : 0)"
      when match = toks.match(/^\d+/)
        num = parseInt(match[0], 10)
        consume match[0].length - 1
        code += num
      else
        throw new Error "Unexpected token '#{token}'."
    consume 1
  if declaration
    new Function """
      function d(num, max) {
        var sum = 0;
        for (var i = 0; i < num; i++) {
          sum += Math.ceil(qc.random() * max);
        }
        return sum;
      }

      return #{code};
    """
  else
    new Function "return #{code};"
