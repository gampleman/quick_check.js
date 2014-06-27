stringify = (examples, generators) ->
  (for example, i in examples
    generator = generators[i]
    if generator.stringify
      generator.stringify(example)
    else
      JSON.stringify(example)
  ).join(', ')

makeHistogram = (hist, total) ->
  hist = ({label, count} for label, count of hist)
  hist.sort ({count: a}, {count: b}) -> a - b
  "\n" + hist.map(({label: label, count: count}) -> "#{((count / total) * 100).toFixed(2)}% #{label}").join("\n")


qc = (prop, generators...) ->
  num = 100; skipped = 0; hist = {}
  for i in [0...num]
    examples = (generator(i) for generator in generators)
    result = prop(examples...)
    if result == false
      # Okay, we have failed, now let's try to shrink the result
      skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
      return pass: no, message: "Falsified after #{i} attempts#{skippedString}. Counter-example: #{stringify(examples, generators)}"
    if result == undefined
      num++; skipped++
    if typeof result is 'string'
      hist[result] = if hist[result]? then hist[result] + 1 else 1

  skippedString = if skipped > 0 then " (#{skipped} skipped)" else ""
  histString = makeHistogram hist, num

  return pass: yes, message: "Passed #{num} tests#{skippedString}.#{histString}"

###*
qc.forAll is a convenience method for executing quick checks, but the return values are
ignored. This is useful with seperate expections.
###
qc.forAll = (generators..., prop) ->
  for i in [0...100]
    examples = (generator(i) for generator in generators)
    prop(examples...)
  return

qc.random = Math.random







window.qc = qc
