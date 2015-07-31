QUnit.module 'qc examples'
QUnit.test 'addition is associative', (assert) ->
  assert.forAll (a, b, c) ->
    (a + b) + c == a + (b + c)
  , qc.int, qc.int, qc.int

QUnit.test 'can show postive message', (assert) ->
  prop = (i) ->
    if i % 2 == 0
      (i + i) % 2 == 0
  assert.ok /Passed \d{3} tests \(\d{1,3} skipped\)/.exec(qc(prop, qc.int).message)

QUnit.test 'can show a histogram', (assert) ->
  prop_double_number_is_divisible_by_two = (i) ->
    if (i + i) % 2 == 0
      if i % 2 == 0 then "even" else "odd"
    else
      false
  assert.ok /\d\d\.\d\d% (even|odd)\n\d\d\.\d\d% (even|odd)/.exec(qc(prop_double_number_is_divisible_by_two, qc.int).message)

QUnit.test  'can execute specifications indepedently', (assert) ->
  qc.forAll qc.int, (i) ->
    assert.equal((i + i) % 2, 0)
