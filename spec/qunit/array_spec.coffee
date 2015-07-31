identity = (a) -> a
QUnit.module 'array'
QUnit.test 'qc.array', (assert) ->
  assert.forAll Array.isArray, qc.array
QUnit.test 'qc.arrayOf', (assert) ->
  assert.forAll Array.isArray, qc.arrayOf(qc.any)
  assert.forAll (v) ->
      v.every (el) -> typeof el is 'number'
  , qc.arrayOf(qc.real)
  assert.forAll (l) ->
    length = l % 100
    qc.arrayOf(qc.any, {length})(100).length == length
  , qc.uint
  assert.forAll (v) ->
    10 <= v.length <= 12
  , qc.arrayOf(qc.any, {length: qc.int.between(10, 12)})
QUnit.test 'qc.array.subsetOf', (assert) ->
  uniq = (arr) ->
    results = []
    results.push(element) for element in arr when element not in results
    results
  assert.forAll (arr, size) ->
    arr.length == 0 or qc.array.subsetOf(arr)(size).every (n) -> arr.indexOf(n) >= 0
  , qc.array, identity
  assert.forAll (arr, size) ->
    arr = uniq(arr)
    subset = qc.array.subsetOf(arr)(size)
    uniq(subset).length is subset.length
  , qc.array, identity
  assert.forAll (arr, size) ->
    qc.array.subsetOf(arr)(size).length <= arr.length
  , qc.array, identity
