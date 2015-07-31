describe 'string', ->
  describe 'qc.char', ->
    it 'generates a string', ->
      expect((str) -> typeof str is 'string').forAll(qc.char)

    it 'has length one', ->
      expect((str) -> str.length is 1).forAll(qc.char)

  describe 'qc.string', ->
    it 'generates a string', ->
      expect((str) -> typeof str is 'string').forAll(qc.string)

  describe 'qc.string.ascii', ->
    it 'is composed of reasonable characters', ->
      reasonable = /^[\w\s]*$/i
      expect((str) -> reasonable.test str).forAll(qc.string.ascii)

  describe 'qc.string.concat', ->
    it 'concats 2 strings', ->
      expect(qc.string.concat([(-> 'a'), (-> 'b')])(10)).toEqual('ab')

  describe 'qc.string.matching', ->
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
