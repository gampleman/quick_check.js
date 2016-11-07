# ### Misc generators

# qc.any will generate a value of any type. For performance reasons there is a bias
# towards simpler types with the following approx. distribution:
#
# Probability | Type
# ----------|-----------
#        4% | `object`
#        8% | `array`
#       13% | `string`
#       14% | `function`
#       16% | `real`
#       20% | `integer`
#       25% | `boolean`
qc.any = qc.oneOfByPriority qc.bool, qc.int, qc.real, (-> ->), (-> undefined), qc.string, qc.array, qc.object

# qc.any.simple will only generate simple types, i.e. booleans, numbers, strings and null
qc.any.simple = qc.oneOf qc.bool, qc.int, qc.real, qc.string, qc.pick(undefined, null)

# qc.any.datatype will only generate types that are data, not code, i.e. booleans, numbers, strings, null, arrays and objects
qc.any.datatype = qc.oneOf qc.bool, qc.int, qc.real, qc.string, qc.pick(undefined, null), qc.array, qc.object

# Color is a utility for making web colors, i.e. will return a CSS compatible string (#fff).
qc.color = qc.string.matching(/^\#([A-F\d]{6}|[A-F\d]{3})$/i)

# Location calculates a random lat, long pair on the surface of the Earth.
qc.location = (size) ->
  rad2deg = (n) -> 360 * n / (2 * Math.PI)
  x = qc.random() * 2 * Math.PI - Math.PI
  y = Math.PI / 2 - Math.acos(qc.random() * 2 - 1)
  [rad2deg(y), rad2deg(x)]
