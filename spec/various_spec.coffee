describe 'various', ->
  describe 'location', ->
    it 'is a valid location', ->
      expect(([lat, long]) -> -90 <= lat <= 90 and -180 <= long <= 180).forAll(qc.location)
  describe 'date', ->
    it 'returns a valid date', ->
      expect (date) ->
        !isNaN date.getTime()
      .forAll qc.date
