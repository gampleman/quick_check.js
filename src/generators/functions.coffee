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
#     drawCanvas = qc.procedure () ->
#       t1 = qc.intUpto @w
#       t2 = qc.intUpto @h
#       @ctx.lineTo t1, t2
#     , () ->
#       @ctx.fillStyle = qc.color(@size)
#       @ctx.fill()
#     , () ->
#       @ctx.strokeStyle = qc.color(@size)
#       @ctx.stroke()
#     , () ->
#       @ctx.closePath()
#     , () ->
#       t1 = qc.intUpto @w
#       t2 = qc.intUpto @h
#       @ctx.moveTo @w, @h
#
#     randomPNGDataURL = (size) ->
#       canvas = document.createElement('canvas')
#       canvas.width = w = 4 * qc.intUpto size
#       canvas.height = h = 4 * qc.intUpto size
#       drawCanvas(size)({ctx: canvas.getContext('2d'), w, h})
#       canvas.toDataURL()
qc.procedure = (steps...) ->
  (size) ->
    execution = qc.arrayOf(qc.pick steps)(size)
    (globals) ->
      globals.size = size
      execution.reduce (prevVals, fn) ->
        fn.apply(globals, prevVals)
      , []
