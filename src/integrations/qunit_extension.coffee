# # QUnit integration

QUnit?.assert.forEach = (property, generators...) ->
  {pass, examples, message} = qc(property, generators...)
  QUnit.push(pass, property, examples, message)
