###*
qc.char will return a random string with a single chararcter.
###
qc.char =  -> String.fromCharCode(qc.byte())

###*
qc.string will generate a string of random charachters.
###
qc.string =  (size) -> qc.arrayOf(qc.char)(size).join('')
###*
qc.string.ascii will generate a string of random ascii charachters.
###
qc.string.ascii = (size) ->
  gen = qc.pick(makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_', ' ', '\n']))
  qc.arrayOf(gen)(size).join('')

qc.string.concat = (gens) ->
  (size) -> (gen(size) for gen in gens).join('')

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


capture = (gen, captures, captureLevel) ->
  (size) ->
    value = gen(size)
    captures[captureLevel.toString()] ?= []
    captures[captureLevel.toString()].push(value)
    value


makeRange = (from, to, caseInsensitive) ->
  if caseInsensitive
    lowerCase = (String.fromCharCode(charCode) for charCode in [from.toLowerCase().charCodeAt(0)..to.toLowerCase().charCodeAt(0)])
    upperCase = (String.fromCharCode(charCode) for charCode in [from.toUpperCase().charCodeAt(0)..to.toUpperCase().charCodeAt(0)])
    lowerCase.concat(upperCase)
  else
    String.fromCharCode(charCode) for charCode in [from.charCodeAt(0)..to.charCodeAt(0)]

makeComplimentaryRange = (range) ->
  String.fromCharCode(char) for char in [0..256] when not (String.fromCharCode(char) in range)

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

generatorForPattern = (toks, caseInsensitive, captures, captureLevel) ->
  gens = []
  while toks.length > 0
    token = toks.shift()
    if token.match(/[\w\s]/i)
      gens.push(generator.literal(token, caseInsensitive))
    else if token is '^'
      captures.isHookedFromStart = yes
    else if token is '$'
      captures.isHookedFromEnd = yes
    else if token is '.'
      gens.push(generator.dot)
    else if token is '*'
      if toks[0] == '?'
        toks.shift()
        gens.push(generator.repeat(gens.pop(), 0, 10))
      else
        gens.push(generator.repeat(gens.pop(), 0, 100))
    else if token is '?'
      gens.push(generator.repeat(gens.pop(), 0, 1))
    else if token is '+'
      if toks[0] == '?'
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
      console.log "Usuported characher: '#{token}'"
      throw "Usuported characher: '#{token}'"
  qc.string.concat(gens)


###*
Generates a string that would match the regexp passed in.
Currently only a limited subset of regexp is supported.
###
qc.string.matching = (pattern) ->
  # let's parse the pattern
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
