# # QUnit integration
QUnit?.assert.forAll = (property, generators...) ->
  {pass, examples, message} = qc(property, generators...)
  @push(pass, property, examples, message)
