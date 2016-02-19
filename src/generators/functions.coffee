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
