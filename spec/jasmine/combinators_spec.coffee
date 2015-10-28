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
  describe 'qc.map', ->
    it 'returns the same value if passed identity', ->
      gen = (size) -> 42
      identity = (a) -> a
      expect(qc.map(identity, gen)(10)).toBe(gen(10))
    it 'curries', ->
      gen = (size) -> 42
      identity = qc.map (a) -> a
      expect(identity(gen)(10)).toBe(gen(10))
    it 'returns a double value', ->
      gen = (size) -> 42
      double = qc.map (a) -> 2 * a
      expect(double(gen)(10)).toBe(2 * gen(10))
