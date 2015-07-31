describe 'combinators', ->
  describe 'qc.oneOf', ->
    it 'calls one of its generators', ->
      gen = jasmine.createSpy().and.returnValue('a')
      expect(qc.oneOf(gen, gen)(10)).toBe('a')
      expect(gen).toHaveBeenCalledWith(10)
  describe 'qc.except', ->
    it 'never returns the value provided', ->
      expect (n, size) ->
        qc.except(qc.int, n) != n
      .forAll qc.int, (a) -> a
