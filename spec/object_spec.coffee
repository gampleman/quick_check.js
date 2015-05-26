describe 'object', ->
  describe 'qc.objectLike', ->
    it 'creates an equal object when no generators present', ->
      qc.forAll qc.objectOf(qc.any.simple), ((a) -> a), (obj, size) ->
        expect(qc.objectLike(obj)(size)).toEqual(obj)
    it 'replaces functions with their results', ->
      expect(qc.objectLike({
        static: 1,
        dynamic: -> 2
      })(10)).toEqual({
        static: 1
        dynamic: 2
      })
  describe 'qc.objectOf', ->
    it 'creates an object where values are of a type', ->
      expect (v) ->
        return false for k, val of v when typeof val isnt 'number'
        true
      .forAll qc.objectOf(qc.int)
    it 'creates an object where keys are based on a specified generator', ->
      expect (v) ->
        return false for k, val of v when k isnt 'key'
        true
      .forAll qc.objectOf(qc.int, -> 'key')
  describe 'qc.object', ->
    it 'creates an object', ->
      expect (v) ->
        typeof v is 'object'
      .forAll qc.object
