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
