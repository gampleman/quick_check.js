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


  it 'can generate functions that create stable objects', ->
    expect((f, a) -> f(a).hello == f(a).hello).forAll(qc.function(qc.int, qc.objectLike({hello: qc.int})), qc.int)

  it 'can show postive message', ->
    prop = (i) ->
      if i % 2 == 0
        (i + i) % 2 == 0
    expect(qc(prop, qc.int).message).toMatch(/Passed \d{3} tests \(\d{1,3} skipped\)/)

  it 'can show a histogram', ->
    # console.log(JSON.stringify("vÄeHÝ sÕPûÃRWÜ/ÃK\rûðÿB%Á\u0012ùRü\u0015·õÏK\u0004ªqÔh¿xa\u0007Æ¸äà*ø¾$À\u001a~K>3ü#o§1\u001e%mEAßöÒß".toUpperCase()))
    prop_double_number_is_divisible_by_two = (i) ->
      if (i + i) % 2 == 0
        if i % 2 == 0 then "even" else "odd"
      else
        false
    expect(qc(prop_double_number_is_divisible_by_two, qc.int).message).toMatch(/\d\d\.\d\d% (even|odd)\n\d\d\.\d\d% (even|odd)/)

  it 'can execute specifications indepedently', ->
    qc.forAll qc.int, (i) ->
      expect((i + i) % 2).toBe(0)

  describe 'string', ->
    it 'generates a string', ->
      expect((i) -> typeof qc.string(i) is 'string').forAll(qc.uint)

    describe 'ascii', ->
      it 'is composed of reasonable characters', ->
        reasonable = /^\w*$/i
        expect((i) -> reasonable.exec qc.string.ascii(i)).forAll(qc.uint)

    describe 'matching', ->
      it 'can generate a static string', ->
        expect(qc.string.matching(/^abc$/)(3)).toEqual('abc')
      it 'can generate stuff with random characters', ->
        expect(qc.string.matching(/.../)(5)).toMatch(/.../)
      it 'can use multipliers', ->
        expect(qc.string.matching(/^a+$/)(5)).toMatch(/a/)
        expect(qc.string.matching(/^a?$/)(5)).toMatch(/^(a$|$)/)
        expect(qc.string.matching(/^a*$/)(5)).toMatch(/^(a+$|$)/)
        amount = qc.string.matching(/^a+?$/)(150).length
        expect(amount).toBeLessThan(11)
        expect(amount).toBeGreaterThan(0)
        amount = qc.string.matching(/^a+$/)(150).length
        expect(amount).toBeLessThan(101)
        expect(amount).toBeGreaterThan(0)
        amount = qc.string.matching(/^(cc){1,2}$/i)(10).length
        expect(amount).toBeLessThan(5)
        expect(amount).toBeGreaterThan(1)
        amount = qc.string.matching(/^(c){4,}$/i)(10).length
        expect(amount).toBeGreaterThan(3)
        amount = qc.string.matching(/^(c){4}$/i)(10).length
        expect(amount).toBe(4)
      it 'can use subexpressions', ->
        expect(qc.string.matching(/^((abc)\2)\1$/)(5)).toEqual('abcabcabcabc')
        expect(qc.string.matching(/^((abc)\2(def)\3)\1$/)(5)).toEqual('abcabcdefdefabcabcdefdef')
        expect(qc.string.matching(/^((abc)\2(def)\3)\1\2$/)(5)).toEqual('abcabcdefdefabcabcdefdefabc')
      it 'can use subexpressions and non-capturing groups', ->
        expect(qc.string.matching(/^((?:g)(abc)\2)\1$/)(5)).toEqual('gabcabcgabcabc')
        expect(qc.string.matching(/^ab(?=c)$/)(5)).toEqual('abc')
      it 'can use character classes and ranges', ->
        expect(qc.string.matching(/^[a-g\d]+$/)(5)).toMatch(/^[a-g\d]+$/)
        expect(qc.string.matching(/^[^a-g\d]+$/)(5)).toMatch(/^[^a-g\d]+$/)

  describe 'any', ->
    it 'can be of any type', ->
      expect((any) -> [any].pop() == any).forAll(qc.any)

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
