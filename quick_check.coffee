# Welcome to quick_check.js. This program is written in CoffeeScript, but the
# source is quite simple and shouldn't be too dificult to understand.
#
# We start by defining our main function, `qc` which performs the actual checking
# and also we use it to namespace all our other public functions. Functions without
# the qc prefix are considered private to this library.
#
# The qc function will generate 100 test cases and run the supplied property.
# Based on the resulting value, we either succeed, fail or skip the test. Additionally
# if a string is returned we classify the tests based on the returned string.
#
# For failed cases we want to then make the example minimal in a process called
# shrinking (more on this later on).
qc = (prop, generators...) ->
  num = 100; skipped = 0; hist = {}
  for i in [0...num]
    examples = (generator(i) for generator in generators)
    result = prop(examples...)
    if result == false
      if qc._performShrinks
        minimal = findMinimalExample(prop, examples, generators)
        skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
        return {
          pass: no,
          examples: examples,
          minimalExamples: minimal.examples,
          message: "Falsified after #{i + 1} attempt#{if i == 0 then '' else 's'}#{skippedString}. Counter-example (after #{minimal.shrinkCount} shrinks): #{stringify(minimal.examples, generators)}\n\nNon-shrunk counter-example: #{stringify(examples, generators)}"
        }
      else
        skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
        return {
          pass: no,
          examples: examples,
          message: "Falsified after #{i + 1} attempt#{if i == 0 then '' else 's'}#{skippedString}. Counter-example: #{stringify(examples, generators)}"
        }
    if result == undefined
      num++; skipped++
      if skipped > 200
        return pass: no, examples: examples, message: "Gave up after #{i} (#{skipped} skipped) attempts."
    if typeof result is 'string'
      hist[result] = if hist[result]? then hist[result] + 1 else 1

  skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
  histString = makeHistogram hist, num

  return pass: yes, examples: examples, message: "Passed #{num} tests#{skippedString}.#{histString}"

# When an example fails, we need to convert it to a string to show the user the
# failing test case. Currently if it is a function that failed, we call `toString`
# on it, otherwise we turn it to JSON. This behavior should be more refined for
# custom types.
stringify = (examples) ->
  (if typeof example is 'function' then example.toString() else JSON.stringify(example) for example in examples).join(', ')

# If the user uses categorization for their results, we want to print it out in a
# sorted list with percentages of values that went there.
makeHistogram = (hist, total) ->
  hist = ({label, count} for label, count of hist)
  hist.sort ({count: a}, {count: b}) -> a - b
  "\n" + hist.map(({label, count}) -> "#{((count / total) * 100).toFixed(2)}% #{label}").join("\n")

# `qc.forAll` is a convenience method for executing quick checks, but the return values are
# ignored. This is useful with seperate expectations:
#
#     qc.forAll qc.int, (i) -> expect(i + i).toBe(2 * i)
qc.forAll = (generators..., prop) ->
  for i in [0...100]
    examples = (generator(i) for generator in generators)
    prop(examples...)

# We make our own alias of the random function. When writing your own generators,
# use of this is required, because some planned features in the future may require
# use of a custom generator.
qc.random = Math.random

# We make this globally available.
if @?
  @qc = qc
else if window?
  window.qc = qc

module.exports = qc if module?

# # Generators
# This library bundle a number of simple generators that help for testing a lot of
# common functionality but can also be used by composition in your custom generators.
# Finally these generators can be used as examples how to write your own generators.

# A generator is a function that accepts an optional `size` parameter and returns a random value.

# ### Basic generators

# Generates a random boolean.
qc.bool = (size) -> qc.choose(true, false)

# Generates a random integer between 0 and 255.
qc.byte = (size) -> Math.floor(qc.random() * 256)

# Generates random objects by calling the constructor with random arguments.
qc.constructor = (cons, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    new cons(args...)

# Generates a random value by calling a function with random arguments.
qc.fromFunction = (fun, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    fun(args...)

# Return a function that randomly chooses one of the arguments passed to `qc.pick`.
qc.pick =  (range...) ->
  range = range[0] if arguments.length ==  1
  -> range[Math.floor(qc.random() * range.length)]

qc.choose =  (range...) -> qc.pick(range...)()

# ### Generator combinators
# These combinator functions are meant to create new generators out of other generators.

# `qc.oneOf` will choose between all the generators passed to it (accepts also an array of generators)
# and generate a value from it. For example:
#
#     stringOrNumber = qc.oneOf(qc.string, qc.real)
#     stringOrNumber(size) # "frqw"
#     stringOrNumber(size) # 5.54
qc.oneOf =  (generators...) ->
  (size) ->
    qc.choose(generators...)(size)

# `qc.oneOfByPriority` will choose a generator based on a distribution. This is
# used for optimizing cases for simpler generators. See `qc.any` for an example.
qc.oneOfByPriority = (generators...) ->
  (size) ->
    gindex = Math.floor((1 - Math.sqrt(qc.random())) * generators.length)
    generators[gindex](size)

# `qc.except` will run the generator passed to it as normal, but when it generates
# one of the `values` passed to it, it will try the generator again to guarantee that
# the generator will generate a value other then any of the values. So `qc.except(qc.uint, 0)(size)`
# will generate a natural number, since `qc.uint` it will generate a random positive integer,
# and if it generates 0, it will try again.
#
# This is quite a naive implementation as it will simply try again if the generator
# does generate one of the values. If the probability of generating one of these
# values is high, this can really kill performace, so for those cases a custom
# implementation might be better (e.g. the string generator does this).
qc.except =  (generator, values...) ->
  anyMatches = (expect) -> return (true for v in values when v is expect).length > 0
  (size) ->
    loop
      value = generator(size)
      return value unless anyMatches value

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

qc.int = (size) -> qc.choose(1, -1) * qc.intUpto(adjust size * size)
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

# ### Array generators
normalizeOptions = (options = {}) ->
  length: if options.length?
    if typeof options.length is 'function'
      options.length
    else
      -> options.length
  else
    qc.intUpto
  sparse: options.sparse ? false

# This function randomly removes elements from an array so that it will turn sparse.
sparsify = (arr, {sparse}) ->
  if sparse
    arr = arr.slice()
    delete arr[i] for el, i in arr when qc.random() > 0.6
    arr
  else
    arr
# `qc.arrayOf(generator, options={})` will return a random generator, which will generate
# an array from that generator.
#
# options can have (currently) the following keys:
# `length`: should be a generator (or a constant number) that specifies how many elements
# should the array have.
# `sparse`: a boolean, which controls if the array can be sparse.
qc.arrayOf =  (generator, options = {}) ->
  options = normalizeOptions(options)
  (size) ->
    sparsify(generator(i) for i in [0...options.length(size)], options)

# `qc.array` will generate a random array of any type.
qc.array = (size) -> qc.arrayOf(qc.any)(if size > 1 then size - 1 else 0)

# `qc.array.subsetOf(array, options)` will return a random generator that will generate
# a subset of an array.
#
# For example `qc.array.subsetOf([1,2,3,4])(size)` could yield `[3, 1]`.
qc.array.subsetOf = (array, options = {}) ->
  options.length ?= qc.intUpto array.length + 1
  options = normalizeOptions(options)
  (size) ->
    copy = array.slice()
    sparsify(copy.splice(qc.intUpto(copy.length), 1)[0] for i in [0...options.length(size)], options)

# ### Function generators

# Generating a function has several limitations. Firstly we will only want to
# generate pure functions. A pure function can take a number of arguments and returns
# a value. Such a function is fundamentally a lookup table where the return value
# can be found through the arguments. In general the problem is that for some (most)
# functions the table is infinite. However any program that actually runs will only
# ever explore a finite portion of this table. So for a particular run of a program,
# and for a function f that we can represent with the infinite table x, we can
# find a finite table x' that will fully simulate the behavior of the function f.
#
# We exploit this fact in quick check. Our function generator creates an empty table,
# and then returns a function which will lookup the arguments passed to it. If the
# arguments are present in the table, the return value is returned. Otherwise a
# random value is generated and stored with the arguments in the table.
#
# Finally we override the toString method of the returned function to emit human
# readable source code.
qc.function =  (args..., returnGenerator) ->
  generator = (size) ->
    generator.calls = []
    result = (someArgs...) ->
      return value for [callArgs..., value] in generator.calls when arraysEqual(callArgs, someArgs)
      value = returnGenerator(size)
      generator.calls.push([someArgs..., value])
      return value
    result.toString = ->
      calls = generator.calls
      if calls.length == 0
        return "function() { return #{JSON.stringify returnGenerator(10)}; }"
      argNames = (String.fromCharCode(i + 97) for i in [0...calls[0].length-1])
      clauses = for [args..., value], pos in calls
        condition = ("#{argNames[i]} === #{JSON.stringify arg}" for arg, i in args).join(' && ')
        if calls.length == 1
          "return #{JSON.stringify value};"
        else if pos == calls.length - 1
          "{\n    return #{JSON.stringify value};\n  }"
        else
          "if (#{condition}) {\n    return #{JSON.stringify value};\n  }"
      """

      function(#{argNames.join(", ")}) {
        #{clauses.join(" else ")}
      }
      """
    result
  generator

# This alias is for languages that don't like the reserved word as an identifier.
qc.pureFunction = qc.function
# To lookup things in the table we need a notion of equality. QuickCheck currently
# supports only equality testing with `===`, however in future versions we will
# hopefully lift this limitation.
arraysEqual = (a1, a2) ->
  return false if a1.length != a2.length
  for arg, i in a1
    if arg != a2[i]
      return false
    return true

# A procedure is a function composed of discrete operations that has side effects.
#
# As an example, we give a procedure to draw a random image into the canvas
#
#     canvas = qc.procedure class Canvas
#       # Constructor gets called only once
#       constructor: ($args) ->
#         @canvas = document.createElement('canvas')
#         @canvas.width = @width = $args[0]
#         @canvas.height = @height = $args[1]
#         @ctx = canvas.getContext('2d')
#       # A function can have basic types injected
#       lineTo: (uint1, uint2) ->
#         @ctx.lineTo Math.max(uint1, @width), Math.max(uint2, @height)
#       # A $final method will only be called once and its return value
#       # will be the return value of the procedure.
#       $final: ->
#         @canvas.toDataURL()
#
#     expect (drawCanvas) ->
#       isValidPng(drawCanvas(100, 100))
#     .forAll canvas
qc.procedure = (obj, injectorConfig = {}) ->
  FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m;
  FN_ARG_SPLIT = /,/
  FN_ARG = /^\s*(\S+?)\s*$/
  STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg
  extractArgs = (fn) ->
    args = fn.toString().replace(STRIP_COMMENTS, '').match(FN_ARGS)
    if args
      argName.match(FN_ARG)[1] for argName in args[1].split(FN_ARG_SPLIT) when argName isnt ''

  fnKeys = (obj) -> key for key, val of obj when key isnt '$final' and (typeof val is 'function' or typeof val is 'object' and val.length and typeof val[val.length - 1] is 'function')

  getGenerators = (injector, obj, prefix) ->
    for own key, fn of obj
      if typeof fn is 'function' and fn.length is 1 and extractArgs(fn)[0] is 'size'
        injector[prefix + key] = fn
      getGenerators injector, fn, prefix + key + '_'
    return

  initializeInjector = (injectorConfig) ->
    injector = {}
    getGenerators injector, qc, ''
    injector[key] = val for key, val of injectorConfig
    injector

  (size) ->
    injector = initializeInjector(injectorConfig)
    invoke = (key, args, obj, result) ->
      injectors = []
      injector.$args = -> args
      fn = ->
      if typeof obj[key] is 'function'
        fn = obj[key]
        if obj[key].$inject?
          injectors = obj[key].$inject?
        else
          injectors = (injector[name.replace(/\d+$/, '')] for name in extractArgs(obj[key]))
      else
        fn = obj[key][obj[key].length - 1]
        injectors = obj[key].slice(0, -1)
      fnarguments = (gen(size) for gen in injectors)
      result.trace.push({key, args: fnarguments})
      fn.apply(obj, fnarguments)

    result = (args...) ->
      result.trace = []
      result.classMode = typeof obj is 'function'
      callee = if typeof obj is 'function' then new obj(args) else obj
      steps = fnKeys callee
      execution = qc.arrayOf(qc.pick steps)(size)
      invoke(key, args, callee, result) for key in execution
      if callee.$final then invoke('$final', args, callee, result) else undefined

    result.toString = ->
      code = []
      name = obj.name || injector.name || 'Api'
      if result.classMode
        code.push "var obj = new #{name}(arguments);"
        name = 'obj'
      for {key, args} in result.trace
        ret = if key is '$final' then 'return ' else ''
        code.push "#{ret}#{name}.#{key}(#{(JSON.stringify(arg) for arg in args).join(', ')});"

      "function() {\n  #{code.join('\n  ')}\n}"
    result

# ### Object generators

# `qc.objectLike` accepts a template of an object with random generators as values,
# and returns a generator of that form of object.
#
#     qc.objectLike({
#       hello: "world",
#       name: qc.string.matching(/^m(r|s)\. [A-Z][a-z]{3,9}$/)
#     })(size) // generates:
#     {
#       hello: "world",
#       name: "mr. Dasde"
#     }
qc.objectLike = (template) ->
  (size) ->
    result = {}
    for key, value of template
      if typeof value == 'function'
        result[key] = value(size)
      else
        result[key] = value
    result

# `qc.objectOf` generates an object containing the passed type as its values.
qc.objectOf =  (generator, keygen = qc.string) ->
  (size) ->
    result = {}
    for i in [0..qc.intUpto(size)]
      result[keygen(size)] = generator(i)
    result

# `qc.object` generates an object containing random types
qc.object = (size) -> qc.objectOf(qc.any)(size)

# ### String generators

# `qc.char` will return a random string with a single chararcter.
qc.char = (size) -> String.fromCharCode(qc.byte())

# `qc.string` will generate a string of random charachters.
qc.string = (size) ->
  s = ""
  s += qc.char() for i in [0..qc.intUpto(size)]
  s

# `qc.string.ascii` will generate a string of random ascii charachters.
qc.string.ascii = (size) ->
  gen = qc.pick(makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_', ' ', '\n']))
  qc.arrayOf(gen)(size).join('')

# `qc.string.concat` is a generator combinator (see above) that will generate all
# the generators passed to it and then concatenate them into a single string.
qc.string.concat = (gens) ->
  (size) -> (gen(size) for gen in gens).join('')

# `qc.string.matching(regexp)` will generate a random string matching a regular
# expression. In order to do that the regular expression must be parsed and compiled
# into a generator function. This is an example of a very non-trivial generator.
#
# We make use of a number of smaller generators and generator combinators. Some of
# them, which are of general use are exposed publicly above.
#
# In regular expressions the basic elements are:
#
# - literals, which translate to themselves (or to their uppercase variants)
# - dots, which can stand for anything
# - repeaters of various kinds (these are combinators that generate another generator
#   a set amount of times and concat the results)
# - ranges of characters (we can use the `qc.pick` generator to make these). We
#   have two helper functions, one for the `/[a-z]/` style ranges, the other for
#   negated ranges `/[^b]/`.
generator =
  literal: (lit, caseInsensitive) ->
    if caseInsensitive
     -> qc.choose(lit.toLowerCase(), lit.toUpperCase())
    else
     -> lit
  dot: qc.except(qc.char, '\n')
  repeat: (gen, min, max) ->
    (size) ->
      (gen(size) for i in [0...qc.int.between(min, max)(size)]).join('')

makeRange = (from, to, caseInsensitive) ->
  if caseInsensitive
    lowerCase = (String.fromCharCode(charCode) for charCode in [from.toLowerCase().charCodeAt(0)..to.toLowerCase().charCodeAt(0)])
    upperCase = (String.fromCharCode(charCode) for charCode in [from.toUpperCase().charCodeAt(0)..to.toUpperCase().charCodeAt(0)])
    lowerCase.concat(upperCase)
  else
    String.fromCharCode(charCode) for charCode in [from.charCodeAt(0)..to.charCodeAt(0)]

makeComplimentaryRange = (range) ->
  String.fromCharCode(char) for char in [0..256] when not (String.fromCharCode(char) in range)

# Captures in our context are mostly useful for regexps where the use of backrefs
# is made. `/^([a-z]) = (\d) * \(\1 \/ \2\)$` will result in a meaningful string like
# `c = 21 * (c / 21)`.
capture = (gen, captures, captureLevel) ->
  (size) ->
    value = gen(size)
    captures[captureLevel.toString()] ?= []
    captures[captureLevel.toString()].push(value)
    value

# We need some special behavior for characters following the `\`. This function
# provides that.
handleClass = (token, captures, captureLevel) ->
  switch token
    when 'w'
      makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_'])
    when 'W'
      makeComplimentaryRange(makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_']))
    when 'd'
      makeRange('0', '9')
    when 'D'
      makeComplimentaryRange(makeRange('0', '9'))
    when 's'
      [' ', '\f', '\n', '\r', '\t', '\v']
    when 'S'
      makeComplimentaryRange([' ', '\f', '\n', '\r', '\t', '\v'])
    when 'n'
      ["\n"]
    when 't'
      ["\t"]
    when 'v'
      ["\v"]
    when 'b'
      ['\b']
    when 'f'
      ['\f']
    when 'r'
      ['\r']
    when 'c'
      throw 'Control sequences not supported'
    # Captures are stored in a fairly complex data structure. The reason is that
    # members of the data structure often need to be accessed before their parents
    # are finished parsing. So we cannot use a simple array. For example consider
    # the case of `/((a)\2)/`. Here `\2` is requested before `\1` is done being parsed.
    #
    # Therefore we store it in a hash where the recursive depth is the key, and the
    # value is an array of all captures on that level.
    when '1', '2', '3', '4', '5', '6', '7', '8', '9'
      if captures
        index = parseInt(token, 10)
        ->
          offset = 0
          for level in [0..9]
            if captures[level.toString()]?
              if index - offset < captures[level.toString()].length
                return captures[level.toString()][index - offset]
              else
                offset += captures[level.toString()].length
            else
              offset += 1
    else
      [token]

# Now that we have all the basic elements in place we can do the actual parsing.
# This is done recursively for all groups (e.g. anything wrapped with parentheses).
generatorForPattern = (toks, caseInsensitive, captures, captureLevel) ->
  gens = []
  while toks.length > 0
    token = toks.shift()
    if token.match(/[\w\s=]/i)
      gens.push(generator.literal(token, caseInsensitive))
    else if token is '^'
      captures.isHookedFromStart = yes
    else if token is '$'
      captures.isHookedFromEnd = yes
    else if token is '.'
      gens.push(generator.dot)
    else if token is '*'
      # We implement lazy repeaters as generating shorter strings on average.
      # This is not really correct, as a lazy repeater should guarentee that
      # the string generated does not include what's after.
      if toks[0] == '?'
        console.log "Lazy repeaters may provide incorrect results"
        toks.shift()
        gens.push(generator.repeat(gens.pop(), 0, 10))
      else
        gens.push(generator.repeat(gens.pop(), 0, 100))
    else if token is '?'
      gens.push(generator.repeat(gens.pop(), 0, 1))
    else if token is '+'
      if toks[0] == '?'
        console.log "Lazy repeaters may provide incorrect results"
        toks.shift()
        gens.push(generator.repeat(gens.pop(), 1, 10))
      else
        gens.push(generator.repeat(gens.pop(), 1, 100))
    else if token is '|'
      return qc.oneOf(qc.string.concat(gens), generatorForPattern(toks))
    else if token is '[' # Character class
      charachters = []
      negative = false
      loop
        char = toks.shift()
        if char == ']'
          break
        else if char is '^'
          negative = true
        else if char is '\\'
          charachters = charachters.concat(handleClass(toks.shift()))
        else if char is '-'
          charachters = charachters.concat(makeRange(charachters.pop(), toks.shift(), caseInsensitive))
        else
          charachters.push(char)
      if negative
        gens.push(qc.pick(makeComplimentaryRange(charachters)))
      else
        gens.push(qc.pick(charachters))
    else if token is ')'
      break
    else if token is '\\'
      chars = handleClass(toks.shift(), captures, captureLevel)
      if typeof chars is 'function'
        gens.push(chars)
      else
        gens.push(qc.pick(chars))
    else if token is '{'
      subtoken = toks.shift()
      str = ''
      until subtoken == ',' || subtoken == '}'
        str += subtoken
        subtoken = toks.shift()
      from = parseInt(str, 10)
      if subtoken == '}'
        to = from
      else
        str = ''
        subtoken = toks.shift()
        if subtoken == '}'
          to = 100
        else
          until subtoken == '}'
            str += subtoken
            subtoken = toks.shift()
          to = parseInt(str, 10)
      gens.push(generator.repeat(gens.pop(), from, to))
    else if token is '('
      if toks[0] == '?' && (toks[1] == ':' || toks[1] == '=')
        toks.shift()
        toks.shift()
        gens.push(generatorForPattern(toks, caseInsensitive, captures, captureLevel))
      else if toks[0] == '?' && toks[1] == '!'
        toks.shift()
        toks.shift()
        throw "Negative lookahead is not supported."
      else
        gens.push(capture(generatorForPattern(toks, caseInsensitive, captures, captureLevel + 1), captures, captureLevel))
    else
      gens.push(-> token)
  qc.string.concat(gens)

qc.string.matching = (pattern) ->
  toks = pattern.source.split('')
  captures = {}
  patternGenerator = capture(generatorForPattern(toks, pattern.ignoreCase, captures, 1), captures, 0)
  if pattern.global && !captures.isHookedFromStart && !captures.isHookedFromEnd
    generator.repeat(qc.oneOf(patternGenerator, qc.string), 1, 10)
  else if !captures.isHookedFromStart && !captures.isHookedFromEnd
    qc.string.concat([qc.string, patternGenerator, qc.string])
  else if !captures.isHookedFromStart && captures.isHookedFromEnd
    qc.string.concat([qc.string, patternGenerator])
  else if captures.isHookedFromStart && !captures.isHookedFromEnd
    qc.string.concat([patternGenerator, qc.string])
  else
    patternGenerator

# ### Misc generators

# qc.date will generate a random date
qc.date = (size) ->
  y = qc.intUpto 3000
  m = qc.intUpto 12
  d = qc.intUpto if m in [0, 2, 4, 6, 7, 9, 11] then 31 else if m in [3, 5, 8, 10] then 30 else 28
  hh = qc.intUpto 24
  mm = qc.intUpto 60
  ss = qc.intUpto 60
  ms = qc.intUpto 1000
  new Date y, m, d, hh, mm, ss, ms

# qc.any will generate a value of any type. For performance reasons there is a bias
# towards simpler types with the following approx. distribution:
#
# Probability | Type
# ----------|-----------
#        4% | `object`
#        8% | `array`
#       13% | `string`
#       14% | `function`
#       16% | `real`
#       20% | `integer`
#       25% | `boolean`
qc.any = qc.oneOfByPriority qc.bool, qc.int, qc.real, (-> ->), (-> undefined), qc.string, qc.array, qc.object

# qc.any.simple will only generate simple types, i.e. booleans, numbers, strings and null
qc.any.simple = qc.oneOf qc.bool, qc.int, qc.real, qc.string, qc.pick(undefined, null)

# qc.any.datatype will only generate types that are data, not code, i.e. booleans, numbers, strings, null, arrays and objects
qc.any.datatype = qc.oneOf qc.bool, qc.int, qc.real, qc.string, qc.pick(undefined, null), qc.array, qc.object

# Color is a utility for making web colors, i.e. will return a CSS compatible string (#fff).
qc.color = qc.string.matching(/^\#([A-F\d]{6}|[A-F\d]{3})$/i)

# Location calculates a random lat, long pair on the surface of the Earth.
qc.location = (size) ->
  rad2deg = (n) -> 360 * n / (2 * Math.PI)
  x = qc.random() * 2 * Math.PI - Math.PI
  y = Math.PI / 2 - Math.acos(qc.random() * 2 - 1)
  [rad2deg(y), rad2deg(x)]

# # Shrinking
#
# Shrinking is the secret sauce of quick_check.js. It allows examples to be reduced
# to their minimal form.
#
# After many iterations, this code is heavily inspired by Brian Donovan's shrinker.

# This property sets globally whether to perform shrinking. While it is publicly
# exposed, it is expected that integrations will expose a higher-level API over
# merely setting this propert. Hence the underscore in its name.
qc._performShrinks = true

# We store global shrinkers in this private property. A shrinker is an object with
# two functions: `valid` and `shrinker`.
registry = []

# This part of the codebase heavily uses iterators and ES6 generator functions
# (not to be confused with quick_check generators). Here we define an empty iterator
# for returning in cases where we have no sensible data to return.
emptyIterator =
  next: -> value: undefined, done: yes

# This is a method that creates a global shrinker for a particular kind of data.
# It accepts two parameters, which are both functions: the first can be thought
# of as a rule when the shrinker can apply to a particular value, the second
# should be a generator function that actually returns smaller values.
qc.addShrinker = (valid, shrinker) ->
  if typeof valid is 'string'
    valid = (val) -> val.constructor.name == valid
  shrinker = {valid, shrinker}
  registry.push shrinker
  shrinker

# Generates possible shrinks for the given data using the registry rules. As an
# optimization, you can pass in a shrinker as a second argument, which allows
# short-circuiting the detection routine of the normal call (though keep in mind
# that this optimization can also change the result, since shrinking will use the
# first shrinker whose `valid` rule is true, and there is no guarantee that `valid`
# rules will be mutually exclusive).
#
# Finally, you can pass in your own registry of shrinkers, in case you want to
# bypass the builtins.
qc.shrink = (value, hint, shrinkers = registry) ->
  if hint?.valid?(value)
    return hint.shrinker(value)
  else
    for {valid, shrinker} in shrinkers
      return shrinker(value) if valid(value)
  emptyIterator

# The core idea of shrinking is a guided search through the possible smaller values
# while maintaining a property (in this case that the `prop` returns `false`). We
# also want to find an example quickly, so we limit the number of iterations.
findMinimalExample = (prop, examples, generators, limit = 1000) ->
  iterations = 0
  last = examples
  while iterations < limit
    shrunk = false
    iterateGenArray last.map((example) -> qc.shrink(example)), (vals) ->
      unless prop(vals...)
        last = vals
        shrunk = true
        return false
      true
    break unless shrunk
    iterations += 1
  return shrinkCount: iterations, examples: last

# In order to get a list of arguments for the property, we need to iterate through
# possible ones. We get this in the form of a list of iterators, however, we need
# to iterate by lists of values. A problem is that each generator may produce a
# different number of elements. In that case we keep the last of these.
iterateGenArray = (arr, fn) ->
  dones = (false for gen in arr)
  res = []
  atLeastOneValueAssigned = dones.slice()
  while dones.some((a) -> !a)
    for gen, i in arr
      next = gen.next()
      dones[i] = next.done
      unless next.done
        res[i] = next.value
        atLeastOneValueAssigned[i] = true
    stop = fn(res) if atLeastOneValueAssigned.every((a) -> a)
    return if stop == false

# ## Shrinkers
#
# quick_check.js comes with several shrinkers built-in. Currently, the number is
# quite rudimentary, but more will be added in future versions.

# ### Shrinking Integers
#
# If an integer is negative, first we try simplifying by turning it into a positive
# number. If that doesn't work, we try using the stratgy for positive numbers and
# then flip the sign.
#
# For postive numbers we start with zero, and then increase the value exponentially
# until we reach the original number.
intShrinker = qc.addShrinker (val) ->
  typeof val is 'number' and Math.round(val) is val
, (value) ->
  if value < 0
    yield -value
    positives = qc.shrink(-value, intShrinker)
    until (next = positives.next()).done
      yield -next.value
  else
    diff = value
    while diff > 0
      yield value - diff
      diff = Math.floor(diff / 2)

# ### Shrinking Floats
#
# Floats work almost identically with integers, but there is no flooring involved.
floatShrinker = qc.addShrinker (val) ->
  typeof val is 'number' and Math.round(val) isnt val
, (value) ->
  if value < 0
    yield -value
    positives = qc.shrink(-value, floatShrinker)
    next = undefined
    yield -next.value until (next = positives.next()).done
  else
    diff = value
    while value - diff < value
      yield value - diff
      diff = diff / 2

# ### Shrinking Arrays
qc.addShrinker (val) ->
  Object::toString.call(val) is '[object Array]'
, (value) ->
  # The smallest array is the empty array, which we can't shrink further, but we
  # try the first, since if the test fails even on that, we have a very small
  # small example indeed.
  return if value.length == 0
  yield []
  # Next we try to remove various slices of the array. We start by removing half
  # the array in order, slowly decreasing the number of elements to remove.
  toRemove = Math.floor(value.length / 2)
  while toRemove > 0
    offset = 0
    while offset + toRemove <= value.length
      yield value.slice(0, offset).concat(value.slice(offset + toRemove));
      offset += 1
    toRemove = Math.floor(toRemove / 2)
  # Then we shrink the values contained in the array.
  for elem, i in value
    smaller = qc.shrink(elem)
    until (next = smaller.next()).done
      yield value.slice(0, i).concat([next.value], value.slice(i + 1))

# ### Shrinking Strings
#
# Strings use a method very similar to arrays, but without the recursive bit.
qc.addShrinker (val) ->
  typeof val is 'string'
, (value) ->
  return if value.length is 0

  yield ''

  toRemove = Math.floor(value.length / 2)

  while toRemove > 0
    offset = 0
    while offset + toRemove <= value.length
      yield value.slice(0, offset).concat(value.slice(offset + toRemove));
      offset += 1
    toRemove = Math.floor(toRemove / 2)

# # Jasmine integration

# Integrating into Jasmine is very simple. Feel free to contribute adapters for
# other testing toolkits.
if jasmine?
  beforeEach ->
    jasmine.addMatchers
      forAll: ->
        compare: qc
        negativeCompare: (prop, gens...) ->
          orig = qc._performShrinks
          qc._performShrinks = false
          {pass, examples, message} = qc(prop, gens...)
          qc._performShrinks = orig
          {examples, message, pass: !pass}
