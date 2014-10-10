# # Jasmine integration

# Integrating into Jasmine is very simple. Feel free to contribute adapters for
# other testing toolkits.
if jasmine?
  beforeEach ->
    jasmine.addMatchers
      forAll: ->
        compare: qc
