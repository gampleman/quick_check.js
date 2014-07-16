# ### Misc generators

# qc.date will generate a random date
qc.date =  qc.constructor Date, qc.uint.large

# qc.any will generate any value
qc.any = qc.oneOf(qc.bool, qc.int, qc.real, qc.array, qc.function(qc.any), qc.object, qc.string, qc.date)
