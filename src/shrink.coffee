# # Shrinking
#
# Shrinking is the secret sauce of quick_check.js. It allows examples to be reduced
# to their minimal form.
#
# After many iterations, this code is heavily inspired by Brian Donovan's shrinker.

# This property sets globally whether to perform shrinking. While it is publicly
# exposed, it is expected that integrations will expose a higher-level API over
# merely setting this propert. Hence the underscore in its name.
qc._performShrinks = true

# We store global shrinkers in this private property. A shrinker is an object with
# two functions: `valid` and `shrinker`.
registry = []

# This part of the codebase heavily uses iterators and ES6 generator functions
# (not to be confused with quick_check generators). Here we define an empty iterator
# for returning in cases where we have no sensible data to return.
emptyIterator =
  next: -> value: undefined, done: yes

# This is a method that creates a global shrinker for a particular kind of data.
# It accepts two parameters, which are both functions: the first can be thought
# of as a rule when the shrinker can apply to a particular value, the second
# should be a generator function that actually returns smaller values.
qc.addShrinker = (valid, shrinker) ->
  if typeof valid is 'string'
    valid = (val) -> val.constructor.name == valid
  shrinker = {valid, shrinker}
  registry.push shrinker
  shrinker

# Generates possible shrinks for the given data using the registry rules. As an
# optimization, you can pass in a shrinker as a second argument, which allows
# short-circuiting the detection routine of the normal call (though keep in mind
# that this optimization can also change the result, since shrinking will use the
# first shrinker whose `valid` rule is true, and there is no guarantee that `valid`
# rules will be mutually exclusive).
#
# Finally, you can pass in your own registry of shrinkers, in case you want to
# bypass the builtins.
qc.shrink = (value, hint, shrinkers = registry) ->
  if hint?.valid?(value)
    return hint.shrinker(value)
  else
    for {valid, shrinker} in shrinkers
      return shrinker(value) if valid(value)
  emptyIterator

# The core idea of shrinking is a guided search through the possible smaller values
# while maintaining a property (in this case that the `prop` returns `false`). We
# also want to find an example quickly, so we limit the number of iterations.
findMinimalExample = (prop, examples, generators, limit = 1000) ->
  iterations = 0
  last = examples
  while iterations < limit
    shrunk = false
    iterateGenArray last.map((example) -> qc.shrink(example)), (vals) ->
      unless prop(vals...)
        last = vals
        shrunk = true
        return false
      true
    break unless shrunk
    iterations += 1
  return shrinkCount: iterations, examples: last

# In order to get a list of arguments for the property, we need to iterate through
# possible ones. We get this in the form of a list of iterators, however, we need
# to iterate by lists of values. A problem is that each generator may produce a
# different number of elements. In that case we keep the last of these.
iterateGenArray = (arr, fn) ->
  dones = (false for gen in arr)
  res = []
  atLeastOneValueAssigned = dones.slice()
  while dones.some((a) -> !a)
    for gen, i in arr
      next = gen.next()
      dones[i] = next.done
      unless next.done
        res[i] = next.value
        atLeastOneValueAssigned[i] = true
    stop = fn(res) if atLeastOneValueAssigned.every((a) -> a)
    return if stop == false

# ## Shrinkers
#
# quick_check.js comes with several shrinkers built-in. Currently, the number is
# quite rudimentary, but more will be added in future versions.

# ### Shrinking Integers
#
# If an integer is negative, first we try simplifying by turning it into a positive
# number. If that doesn't work, we try using the stratgy for positive numbers and
# then flip the sign.
#
# For postive numbers we start with zero, and then increase the value exponentially
# until we reach the original number.
intShrinker = qc.addShrinker (val) ->
  typeof val is 'number' and Math.round(val) is val
, (value) ->
  if value < 0
    yield -value
    positives = qc.shrink(-value, intShrinker)
    until (next = positives.next()).done
      yield -next.value
  else
    diff = value
    while diff > 0
      yield value - diff
      diff = Math.floor(diff / 2)

# ### Shrinking Floats
#
# Floats work almost identically with integers, but there is no flooring involved.
floatShrinker = qc.addShrinker (val) ->
  typeof val is 'number' and Math.round(val) isnt val
, (value) ->
  if value < 0
    yield -value
    positives = qc.shrink(-value, floatShrinker)
    next = undefined
    yield -next.value until (next = positives.next()).done
  else
    diff = value
    while value - diff < value
      yield value - diff
      diff = diff / 2

# ### Shrinking Arrays
qc.addShrinker (val) ->
  Object::toString.call(val) is '[object Array]'
, (value) ->
  # The smallest array is the empty array, which we can't shrink further, but we
  # try the first, since if the test fails even on that, we have a very small
  # small example indeed.
  return if value.length == 0
  yield []
  # Next we try to remove various slices of the array. We start by removing half
  # the array in order, slowly decreasing the number of elements to remove.
  toRemove = Math.floor(value.length / 2)
  while toRemove > 0
    offset = 0
    while offset + toRemove <= value.length
      yield value.slice(0, offset).concat(value.slice(offset + toRemove));
      offset += 1
    toRemove = Math.floor(toRemove / 2)
  # Then we shrink the values contained in the array.
  for elem, i in value
    smaller = qc.shrink(elem)
    until (next = smaller.next()).done
      yield value.slice(0, i).concat([next.value], value.slice(i + 1))

# ### Shrinking Strings
#
# Strings use a method very similar to arrays, but without the recursive bit.
qc.addShrinker (val) ->
  typeof val is 'string'
, (value) ->
  return if value.length is 0

  yield ''

  toRemove = Math.floor(value.length / 2)

  while toRemove > 0
    offset = 0
    while offset + toRemove <= value.length
      yield value.slice(0, offset).concat(value.slice(offset + toRemove));
      offset += 1
    toRemove = Math.floor(toRemove / 2)
