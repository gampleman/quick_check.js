identity = (a) -> a
describe 'array', ->
  describe 'qc.array', ->
    it 'is an array', ->
      expect(Array.isArray).forAll qc.array
  describe 'qc.arrayOf', ->
    it 'is an array', ->
      expect(Array.isArray).forAll qc.arrayOf(qc.any)
    it 'generates an array that only has values of the provided generator', ->
      expect (v) ->
        v.every (el) -> typeof el is 'number'
      .forAll qc.arrayOf(qc.real)
    it 'accepts a constant value for the length param', ->
      expect (l) ->
        length = l % 100
        qc.arrayOf(qc.any, {length})(100).length == length
      .forAll qc.uint
    it 'accepts a generator for the length param', ->
      expect (v) ->
        10 <= v.length <= 12
      .forAll qc.arrayOf(qc.any, {length: qc.int.between(10, 12)})
  describe 'qc.array.subsetOf', ->
    uniq = (arr) ->
      results = []
      results.push(element) for element in arr when element not in results
      results
    it 'only generates subsets', ->
      expect (arr, size) ->
        arr.length == 0 or qc.array.subsetOf(arr)(size).every (n) -> arr.indexOf(n) >= 0
      .forAll qc.array, identity
    it 'doesnt include things twice unless they are twice in the original array', ->
      expect (arr, size) ->
        arr = uniq(arr)
        subset = qc.array.subsetOf(arr)(size)
        uniq(subset).length is subset.length
      .forAll qc.array, identity
    it 'be default isnt longer than the input', ->
      expect (arr, size) ->
        qc.array.subsetOf(arr)(size).length <= arr.length
      .forAll qc.array, identity
