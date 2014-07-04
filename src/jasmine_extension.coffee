# # Jasmine integration

# Integrating into Jasmine is very simple. Feel free to contribute adapters for
# other testing toolkits.
beforeEach ->
  jasmine.addMatchers
    forAll: ->
      compare: qc
