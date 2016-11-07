describe 'date', ->
  describe 'qc.date', ->
    it 'returns a valid date', ->
      expect (date) ->
        !isNaN date.getTime()
      .forAll qc.date
  describe 'qc.date.withUnits', ->
    describe 'with no arguments', ->
      it 'returns a valid date', ->
        expect (date) ->
          !isNaN date.getTime()
        .forAll qc.date.withUnits()
    describe 'with constant arguments', ->
      it 'returns a valid date', ->
        expect (date) ->
          !isNaN date.getTime()
        .forAll qc.date.withUnits(null, 11, 10)
      it 'returns the date specified', ->
        expect (y, m, d, hh, mm, ss, ms, size) ->
          date = qc.date.withUnits(y, m, d, hh, mm, ss, ms)(size)
          date.valueOf() is (new Date(y, m, d, hh, mm, ss, ms)).valueOf()
        .forAll qc.int.between(-10000, 10000), qc.int.between(0, 11), qc.int.between(0, 30),
          qc.int.between(0, 24), qc.int.between(0, 60), qc.int.between(0, 60), qc.int.between(0, 1000), qc.intUpto
    describe 'with generator arguments', ->
      it 'returns a valid date', ->
        expect (date) ->
          !isNaN date.getTime()
        .forAll qc.date.withUnits(qc.int.between(100, 200))
      it 'allows specifying date ranges', ->
        expect (date) ->
          date.getFullYear() is 100 or date.getFullYear() is 101
        .forAll qc.date.withUnits(qc.int.between(100, 101))
  describe 'qc.date.between', ->
    describe 'with valid date arguments', ->
      it 'returns a valid date', ->
        expect ([d1, d2], size) ->
          !isNaN qc.date.between(d1, d2)(size).getTime()
        .forAll qc.date.range(), qc.intUpto
