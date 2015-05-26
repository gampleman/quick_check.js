# ### Array generators
normalizeOptions = (options = {}) ->
  length: if options.length?
    if typeof options.length is 'function'
      options.length
    else
      -> options.length
  else
    qc.intUpto
# `qc.arrayOf(generator, options={})` will return a random generator, which will generate
# an array from that generator.
#
# options can have (currently) a single key:
# `length`: should be a generator (or a constant number) that specifies how many elements
# should the array have
qc.arrayOf =  (generator, options = {}) ->
  (size) ->
    generator(i) for i in [0...normalizeOptions(options).length(size)]

# `qc.array` will generate a random array of any type.
qc.array = (size) -> qc.arrayOf(qc.any)(if size > 1 then size - 1 else 0)

# `qc.array.subsetOf(array, options)` will return a random generator that will generate
# a subset of an array.
#
# For example `qc.array.subsetOf([1,2,3,4])(size)` could yield `[3, 1]`.
qc.array.subsetOf = (array, options = {}) ->
  options.length ?= qc.intUpto array.length
  (size) ->
    copy = array.slice()
    copy.splice(qc.intUpto(copy.length), 1)[0] for i in [0...normalizeOptions(options).length(size)]
