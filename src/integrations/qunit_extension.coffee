# # QUnit integration
QUnit?.assert.forAll = (property, generators...) ->
  {pass, examples, message} = qc(property, generators...)
  @push(pass, property, examples, message)

QUnit?.assert.forEach = (args...) ->
  console.warn "assert.forEach is deprecated. Please use assert.forAll."
  QUnit.assert.forAll(args...)
