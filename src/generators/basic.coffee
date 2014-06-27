###*
qc.bool will randomly return `true` or `false`.
###
qc.bool =  -> qc.choose(true, false)

###*
qc.byte will return a random integer from 0 to 255.
###
qc.byte = -> Math.floor(qc.random() * 256)

###*
qc.constructor will generate random objects by calling the constructor randomly
###
qc.constructor = (cons, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    new cons(args...)

###*
qc.fromFunction will generate random values by calling a function with random args
###
qc.fromFunction = (fun, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    fun(args...)
