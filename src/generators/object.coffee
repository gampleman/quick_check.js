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
qc.objectOf =  (generator) ->
  (size) ->
    result = {}
    for i in [0..qc.intUpto(size)]
      result[qc.string(size)] = generator(i)
    result

# `qc.object` generates an object containing random types
qc.object = qc.objectOf(qc.any)
