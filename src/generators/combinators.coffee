###*
qc.pick will return a function that randomly chooses one of its arguments.
###
qc.pick =  (range...) ->
  range = range[0] if arguments.length ==  1
  -> range[Math.floor(qc.random() * range.length)]
###*
qc.choose will randomly choose one of its arguments. If only one argument is passed,
it is assumed that that argument is an array of possibilities.
###
qc.choose =  (range...) -> qc.pick(range...)()


###*
qc.oneOf combines generators into one generator.
###
qc.oneOf =  (generators...) ->
  (size) ->
    qc.choose(generators...)(size)

###*
qc.except will generate a value, but not any of the normal types
###
qc.except =  (generator, values...) ->
  anyMatches = (expect) -> return (true for v in values when v is expect).length > 0
  (size) ->
    loop
      value = generator(size)
      return value unless anyMatches value
