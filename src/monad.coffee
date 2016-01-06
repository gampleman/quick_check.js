# ## Monadic Interface
#
# While generators are defined as procedures that take a `size` argument, and return
# a value, we can also think of them as monads. Here we implement a monadic interface
# for our generators.

# `qc.of` wraps a value into a generator. It is actually the `constant` function.
qc.of = (value) -> (size) -> value

# `qc.map` allows you to look into the generator. It is also automatically curried.
map = (fun, gen) -> (size) -> fun(gen(size))
qc.map = (fun, gen) ->
  if arguments.length == 1 then (gen) -> map(fun, gen) else map(fun, gen)

# `qc.modify` is the alias of map for the non-functional-programming crowd.
# The arguments are reversed and it doesn't curry.
qc.modify = (gen, fun) -> map(fun, gen)

# `qc.join` is needed to be a 'real' mondad.
qc.join = (gen) -> (size) -> gen(size)(size)
