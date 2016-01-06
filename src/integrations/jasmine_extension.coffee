# # Jasmine integration

# Integrating into Jasmine is very simple. Feel free to contribute adapters for
# other testing toolkits.
if jasmine?
  beforeEach ->
    jasmine.addMatchers
      forAll: ->
        compare: qc
        negativeCompare: (prop, gens...) ->
          orig = qc._performShrinks
          qc._performShrinks = false
          {pass, examples, message} = qc(prop, gens...)
          qc._performShrinks = orig
          {examples, message, pass: !pass}
