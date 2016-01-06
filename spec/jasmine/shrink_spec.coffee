describe 'shrinking', ->
  describe 'properly shrinks arrays of', ->
    sum = (arr) -> arr.reduce(((a, b) -> a + b), 0)
    prop = (arr) -> sum(arr) > -1000

    it 'ints', ->
      result = qc(prop, qc.arrayOf(qc.int))
      expect(sum(result.minimalExamples[0])).toEqual(-1000)
    it 'reals', ->
      result = qc(prop, qc.arrayOf(qc.real))
      expect(sum(result.minimalExamples[0])).toEqual(-1000)

  it 'shrinks strings', ->
    prop = (str) -> !str.match(/a.*b/)
    expect(qc(prop, qc.string).minimalExamples[0]).toEqual('ab')
