describe 'monadic interface', ->
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
