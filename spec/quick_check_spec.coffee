describe 'qc', ->
  describe 'examples', ->
    it 'addition is associative', ->
      expect((a, b, c) -> (a + b) + c == a + (b + c)).forAll(qc.int, qc.int, qc.int)

    it 'functions', ->
      expect((f, g, a) ->  f(g(a)) == g(f(a))).not.forAll(qc.function(qc.string, qc.string), qc.function(qc.string, qc.string), qc.string)

    it 'upcase doesnt match lower case characters', ->
      # Did you know this will actually fail in some cases? Crazy, huh?
      # Well try uncommenting this:
      # console.log "aßß".toUpperCase()
      #qc.forAll qc.string, (str) ->
      #  expect(str.toUpperCase()).not.toMatch(/[a-z]/g)

  it 'can show postive message', ->
    prop = (i) ->
      if i % 2 == 0
        (i + i) % 2 == 0
    expect(qc(prop, qc.int).message).toMatch(/Passed \d{3} tests \(\d{1,3} skipped\)/)

  it 'can show a histogram', ->
    prop_double_number_is_divisible_by_two = (i) ->
      if (i + i) % 2 == 0
        if i % 2 == 0 then "even" else "odd"
      else
        false
    expect(qc(prop_double_number_is_divisible_by_two, qc.int).message).toMatch(/\d\d\.\d\d% (even|odd)\n\d\d\.\d\d% (even|odd)/)

  it 'can execute specifications indepedently', ->
    qc.forAll qc.int, (i) ->
      expect((i + i) % 2).toBe(0)

  it '#odd returns true for odd numbers', ->
    odd = (num) -> num % 2 == 1
    expect((i) -> odd(2 * i + 1)).not.forAll(qc.int)
    expect("e\u001ee".toUpperCase()).toBe('E\u001eE')

  it '#odd returns true for odd numbers', ->
    even = (num) -> num % 2 == 0
    odd = (num) -> num % 2 == 1
    expect((i) -> if not even(i) then odd(i)).not.forAll(qc.int)

  it '#filter will always return a smaller list', ->
    filter = (list, f) -> elem for elem in list when f(elem)
    expect((list, f) -> filter(list, f).length < list.length).not.forAll(qc.arrayOf(qc.int), qc.function(qc.int, qc.bool))
