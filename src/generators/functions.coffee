
arraysEqual = (a1, a2) ->
  return false if a1.length != a2.length
  for arg, i in a1
    if arg != a2[i]
      return false
    return true

###*
qc.function generates a function that takes args, and returns a random type.
###
qc.function =  (args..., returnGenerator) ->
  seed = qc.random()
  ret = (size) ->
    ret.calls = []
    (someArgs...) ->
      return value for [callArgs..., value] in ret.calls when arraysEqual(callArgs, someArgs)
      value = returnGenerator(size)
      ret.calls.push([someArgs..., value])
      return value
  ret.stringify = (fn) ->
    calls = ret.calls
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
    #clauses = clauses.filter (value, index, self) -> self.indexOf(value) == index # uniq

    """

    function(#{argNames.join(", ")}) {
      #{clauses.join(" else ")}
    }
    """
  ret
