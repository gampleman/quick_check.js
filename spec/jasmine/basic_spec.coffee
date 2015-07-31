describe 'basic', ->
  describe 'qc.bool', ->
    it 'generates either true or false', ->
      expect (v) ->
        v is true or v is false
      .forAll qc.bool

  describe 'qc.byte', ->
    it 'is between 0 and 255', ->
      expect (v) ->
        0 <= v <= 255
      .forAll qc.byte

  describe 'qc.constructor', ->
    it 'instantiates classes', ->
      class Test
        constructor: (@a) ->
      expect (v) ->
        v instanceof Test and typeof v.a is 'number'
      .forAll qc.constructor Test, qc.int

  describe 'qc.fromFunction', ->
    it 'call functions', ->
      expect (v) ->
        v == 1
      .forAll qc.fromFunction ((a) -> a), -> 1
