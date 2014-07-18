# 1. Implementation
idCounter = 0

uniqueId = -> (++idCounter).toString()

hashKey = (value) ->
  type = typeof value
  uid = undefined
  if type is "object" and value isnt null
    uid = value.$$hashKey
    if typeof uid is "function"
      uid = value.$$hashKey()
    else if uid is `undefined`
      uid = value.$$hashKey = uniqueId()
  else
    uid = value
  type + ":" + uid

class HashMap
  put: (key, value) ->
    this[hashKey(key)] = value
  get: (key) ->
    this[hashKey(key)]
  remove: (key) ->
    key = hashKey(key)
    value = this[key]
    delete this[key]
    value

# 2. Generators
hashMaps = (size) ->
  hm = new HashMap()
  i = 0
  l = qc.intUpto(size)

  while i <= l
    hm.put qc.any(size), qc.any(size)
    i++
  hm


# 3. Specs
describe "uniqueId", ->
  it "never gives the same value twice", ->
    expect(->
      uniqueId() isnt uniqueId()
    ).forAll()
    return

  return

describe "hashKey", ->
  it "can turn anything into a string", ->
    expect((anything) ->
      typeof hashKey(anything) is "string"
    ).forAll qc.any
    return

  it "any object will produce the same hash key", ->
    expect((anything) ->
      hashKey(anything) is hashKey(anything)
    ).forAll qc.any
    return

  it "same object will have the same hash key even after modificatoin", ->
    expect((obj, key, val) ->
      origKey = hashKey(obj)
      obj[key] = val
      hashKey(obj) is origKey
    ).forAll qc.object, qc.string, qc.any
    return

  return

describe "HashMap", ->
  it "a value stored can be retrieved", ->
    expect((hm, key, val) ->
      hm.put key, val
      hm.get(key) is val
    ).forAll hashMaps, qc.any, qc.any
    return

  it "a value stored can be deleted", ->
    expect((hm, key, val) ->
      hm.put key, val
      hm.remove key
      hm.get(key) is `undefined`
    ).forAll hashMaps, qc.any, qc.any
    return

  it "a delete returns original value", ->
    expect((hm, key, val) ->
      hm.put key, val
      hm.remove(key) is val
    ).forAll hashMaps, qc.any, qc.any
    return

  return
