describe 'functions', ->
  describe 'qc.function', ->
    it 'creates a function that returns a value of a type', ->
      expect (fn) ->
        typeof fn() is 'number'
      .forAll qc.function qc.int
    it 'can generate functions that create stable objects', ->
      expect (f, a) ->
        f(a) == f(a)
      .forAll(qc.function(qc.int, qc.objectLike({hello: qc.int})), qc.int)
  describe 'qc.procedure', ->
    it 'runs', ->
      spy = jasmine.createSpy('spy')
      qc.procedure({spy})(10)()
      expect(spy).toHaveBeenCalled()
    it 'injects basic types', ->
      qc.procedure({
        spy: (int1, int2, char) ->
          expect(typeof int1).toBe 'number'
          expect(typeof int2).toBe 'number'
          expect(typeof char).toBe 'string'
      })(10)()
    it 'injcets custom types', ->
      spy = jasmine.createSpy('spy').and.returnValue('TEST')
      qc.procedure({
        spy: [spy, (x) ->
          expect(x).toBe('TEST')
          expect(spy).toHaveBeenCalled()
        ]
      })(10)()
    it 'injects arguments', ->
      qc.procedure({
        spy: ($args) ->
          expect($args).toEqual [1,2,3]
      })(40)(1, 2, 3)
    it 'works with classes', ->
      procedure = qc.procedure class Test
        constructor: ($args) ->
          @x = $args[0]
        method: ->
          # do something
        $final: ->
          @x
      expect(procedure(10)(4)).toBe(4)
    it 'prints a reasonable function', ->
      expect (initialState, transformer) ->
        finalState = transformer(initialState)
        eval 'var a = ' + transformer.toString()
        a(initialState) is finalState
      .forAll qc.pick('car', 'robot'), qc.procedure class Transformer
        name: 'Transformer'
        constructor: ($args) ->
          @state = $args[0]
        carMode: ->
          @state = 'car'
        robotMode: ->
          @state = 'robot'
        $final: ->
          @state
