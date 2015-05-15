# # Generators
# This library bundle a number of simple generators that help for testing a lot of
# common functionality but can also be used by composition in your custom generators.
# Finally these generators can be used as examples how to write your own generators.

# A generator is a function that accepts an optional `size` parameter and returns a random value.

# ### Basic generators

# Generates a random boolean.
qc.bool = (size) -> qc.choose(true, false)

# Generates a random integer between 0 and 255.
qc.byte = (size) -> Math.floor(qc.random() * 256)


# Generates random objects by calling the constructor with random arguments.
qc.constructor = (cons, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    new cons(args...)

# Generates a random value by calling a function with random arguments.
qc.fromFunction = (fun, arggens...) ->
  (size) ->
    args = (arggen(size - 1) for arggen in arggens)
    fun(args...)
