# Return a function that randomly chooses one of the arguments passed to `qc.pick`.
qc.pick =  (range...) ->
  range = range[0] if arguments.length ==  1
  -> range[Math.floor(qc.random() * range.length)]

qc.choose =  (range...) -> qc.pick(range...)()

# ### Generator combinators
# These combinator functions are meant to create new generators out of other generators.

# `qc.oneOf` will choose between all the generators passed to it (accepts also an array of generators)
# and generate a value from it. For example:
#
#     stringOrNumber = qc.oneOf(qc.string, qc.real)
#     stringOrNumber(size) # "frqw"
#     stringOrNumber(size) # 5.54
qc.oneOf =  (generators...) ->
  (size) ->
    qc.choose(generators...)(size)

# `qc.oneOfByPriority` will choose a generator based on a distribution. This is
# used for optimizing cases for simpler generators. See `qc.any` for an example.
qc.oneOfByPriority = (generators...) ->
  (size) ->
    gindex = Math.floor((1 - Math.sqrt(qc.random())) * generators.length)
    generators[gindex](size)

# `qc.except` will run the generator passed to it as normal, but when it generates
# one of the `values` passed to it, it will try the generator again to guarantee that
# the generator will generate a value other then any of the values. So `qc.except(qc.uint, 0)(size)`
# will generate a natural number, since `qc.uint` it will generate a random positive integer,
# and if it generates 0, it will try again.
#
# This is quite a naive implementation as it will simply try again if the generator
# does generate one of the values. If the probability of generating one of these
# values is high, this can really kill performace, so for those cases a custom
# implementation might be better (e.g. the string generator does this).
qc.except =  (generator, values...) ->
  anyMatches = (expect) -> return (true for v in values when v is expect).length > 0
  (size) ->
    loop
      value = generator(size)
      return value unless anyMatches value

# `qc.map` allows you to look into the generator. It is also automatically curried.
map = (fun, gen) -> (size) -> fun(gen(size))
qc.map = (fun, gen) ->
  if arguments.length == 1 then (gen) -> map(fun, gen) else map(fun, gen)

# `qc.modify` is the alias of map for the non-functional-programming crowd.
# The arguments are reversed and it doesn't curry.
qc.modify = (gen, fun) -> map(fun, gen)
