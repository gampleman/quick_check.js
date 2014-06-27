###*
qc.objectLike accepts a template of an object with random generators as values,
and returns a generator of that form of object.
###
qc.objectLike =  (template) ->
  (size) ->
    result = {}
    for key, value of template
      if typeof value == 'function'
        result[key] = value(size)
      else
        result[key] = value
    result

###*
qc.objectOf generates an object containing the passed type
###
qc.objectOf =  (generator) ->
  (size) ->
    result = {}
    for i in [0..qc.intUpto(size)]
      result[qc.string(size)] = generator(i)
    result

###*
qc.object generates an object containing random types
###
qc.object = qc.objectOf(qc.any)
