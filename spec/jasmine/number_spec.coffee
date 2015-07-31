describe 'number', ->
  isInt = (int) -> typeof int == 'number' and Math.round(int) is int
  describe 'intUpto', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.intUpto)
    it 'is smaller than the param', ->
      expect (s) ->
        0 <= qc.intUpto(s) <= s
      .forAll qc.uint

  describe 'qc.ureal', ->
    it 'is a number', ->
      expect((value) -> typeof value == 'number').forAll(qc.ureal)
    it 'is positive', ->
      expect((value) -> value >= 0).forAll(qc.ureal)
  describe 'qc.ureal.large', ->
    it 'is a number', ->
      expect((value) -> typeof value == 'number').forAll(qc.ureal.large)
    it 'is positive', ->
      expect((value) -> value >= 0).forAll(qc.ureal.large)

  describe 'qc.real', ->
    it 'is a number', ->
      expect((value) -> typeof value == 'number').forAll(qc.real)
  describe 'qc.real.large', ->
    it 'is a number', ->
      expect((value) -> typeof value == 'number').forAll(qc.real.large)

  describe 'qc.uint', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.uint)
    it 'is positive', ->
      expect((value) -> value >= 0).forAll(qc.uint)
  describe 'qc.uint.large', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.uint.large)
    it 'is positive', ->
      expect((value) -> value >= 0).forAll(qc.uint.large)

  describe 'qc.int', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.int)
  describe 'qc.int.large', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.int.large)
  describe 'qc.int.between', ->
    it 'is an int', ->
      expect((a, b) -> isInt(qc.int.between(a, b)(100))).forAll(qc.int, qc.int)
    it 'is between its params', ->
      expect ([a, b]) ->
        a <= qc.int.between(a, b)(100) <= b
      .forAll(qc.range(qc.int))

  describe 'qc.natural', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.natural)
    it 'is positive', ->
      expect((value) -> value > 0).forAll(qc.natural)
  describe 'qc.natural.large', ->
    it 'is an int', ->
      expect(isInt).forAll(qc.natural.large)
    it 'is positive', ->
      expect((value) -> value > 0).forAll(qc.natural.large)

  describe 'qc.range', ->
    it 'can generate ranges', ->
      expect(([min, max]) -> min < max).forAll(qc.range())
      expect(([min, max]) -> min <= max).forAll(qc.range.inclusive(qc.real))
      expect(([min, max]) -> 0 <= min < max).forAll(qc.range(qc.ureal))
      expect(([min, max]) -> 0 < min < max).forAll(qc.range(qc.natural))
      
  describe 'dice', ->
    it 'can parse additions of constants', ->
      expect(qc.dice('3 + 5')()).toBe 8
    it 'can create a single die', ->
      cast = qc.dice('d4')()
      expect(cast).toBeLessThan 5
      expect(cast).toBeGreaterThan 0
    it 'can create a two dies', ->
      cast = qc.dice('d3 + d5')()
      expect(cast).toBeLessThan 9
      expect(cast).toBeGreaterThan 1
    it 'can create a multiple dies', ->
      cast = qc.dice('5d3')()
      expect(cast).toBeLessThan 16
      expect(cast).toBeGreaterThan 4
