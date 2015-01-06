# Welcome to quick_check.js. This program is written in CoffeeScript, but the
# source is quite simple and shouldn't be too dificult to understand.
#
# We start by defining our main function, `qc` which performs the actual checking
# and also we use it to namespace all our other public functions. Functions without
# the qc prefix are considered private to this library.
#
# The qc function will generate 100 test cases and run the supplied property.
# Based on the resulting value, we either succeed, fail or skip the test. Additionally
# if a string is returned we classify the tests based on the returned string.
qc = (prop, generators...) ->
  num = 100; skipped = 0; hist = {}
  for i in [0...num]
    examples = (generator(i) for generator in generators)
    result = prop(examples...)
    if result == false
      skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
      return {
        pass: no,
        examples: examples,
        message: "Falsified after #{i} attempts#{skippedString}. Counter-example: #{stringify(examples, generators)}"
      }
    if result == undefined
      num++; skipped++
      if skipped > 200
        return pass: no, examples: examples, message: "Gave up after #{i} (#{skipped} skipped) attempts."
    if typeof result is 'string'
      hist[result] = if hist[result]? then hist[result] + 1 else 1

  skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
  histString = makeHistogram hist, num

  return pass: yes, examples: examples, message: "Passed #{num} tests#{skippedString}.#{histString}"

# When an example fails, we need to convert it to a string to show the user the
# failing test case. Currently if it is a function that failed, we call `toString`
# on it, otherwise we turn it to JSON. This behavior should be more refined for
# custom types.
stringify = (examples) ->
  (if typeof example is 'function' then example.toString() else JSON.stringify(example) for example in examples).join(', ')

# If the user uses categorization for their results, we want to print it out in a
# sorted list with percentages of values that went there.
makeHistogram = (hist, total) ->
  hist = ({label, count} for label, count of hist)
  hist.sort ({count: a}, {count: b}) -> a - b
  "\n" + hist.map(({label, count}) -> "#{((count / total) * 100).toFixed(2)}% #{label}").join("\n")

# `qc.forAll` is a convenience method for executing quick checks, but the return values are
# ignored. This is useful with seperate expectations:
#
#     qc.forAll qc.int, (i) -> expect(i + i).toBe(2 * i)
qc.forAll = (generators..., prop) ->
  for i in [0...100]
    examples = (generator(i) for generator in generators)
    prop(examples...)
  return

# We make our own alias of the random function. When writing your own generators,
# use of this is required, because some planned features in the future may require
# use of a custom generator.
qc.random = Math.random

# We make this globally available.
if @?
  @qc = qc
else if window?
  window.qc = qc

module.exports = qc if module?
