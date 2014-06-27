###*
qc.arrayOf will return a random generator, which will generate an array of types
from that generator.
###
qc.arrayOf =  (generator) ->
  (size) ->
    generator(i) for i in [0..qc.intUpto(size)]

###*
qc.array will generate a random array of any type.
###
qc.array = (size) -> qc.arrayOf(qc.any)(if size > 1 then size - 1 else 0)
