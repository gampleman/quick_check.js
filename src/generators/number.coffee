###*
qc.intUpto will return a random integer from 0 to size.
###
qc.intUpto =  (size) -> Math.floor(qc.random() * size)

qc.ureal = (size) -> qc.random() * size * size
qc.ureal.large = -> qc.random() * Number.MAX_VALUE

###*
qc.float will return a random floating point number from -size^2 to size^2.
###
qc.real =  (size) -> qc.choose(1, -1) * qc.ureal(size)
qc.real.large = -> qc.choose(1, -1) * qc.ureal.large()

qc.uint = (size) -> qc.intUpto(size * size)
qc.uint.large = -> Math.floor(qc.random() * Number.MAX_VALUE)

###*
qc.int will return a random integer from -size^2 to size^2.
###
qc.int = (size) -> qc.choose(1, -1) * qc.intUpto(size)
qc.int.large = -> qc.choose(1, -1) * qc.uint.large()
qc.int.between = (min, max) ->
  (size) ->
    min + qc.intUpto(Math.min(max + 1 - min, size))
