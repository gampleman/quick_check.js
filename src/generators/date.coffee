# qc.date will generate a random date
# According to spec, JavaScript dates support 100M days backwards and forwards
# in time.
milisecondsPerDay = 86400000
maxDateOffset = 100000000
timeGen = qc.int.between(-maxDateOffset * milisecondsPerDay, maxDateOffset * milisecondsPerDay)
toDate = (time) -> new Date(time)
dateGen = qc.map toDate
qc.date = dateGen timeGen

# qc.date.withUnits allows you to generate custom dates by specifying the generators
# for the various units.
qc.date.withUnits = (year, month, day, hours, minutes, seconds, milliseconds) ->
  if year? and typeof year is 'object'
    {year, month, day, hours, minutes, seconds, milliseconds, timestamp, fullYear} = year
  (size) ->
    get = (val) -> if typeof val is 'function' then val(size) else val
    date = if timestamp? then toDate(get(timestamp)) else qc.date(size)
    # It has to be noted that the default signature (and using `year` key) uses
    # the unfortunate Y2K behavior where years in the 0-99 range map to years 1900-1999.
    # This is done in order that the arguments to this call conceptually map to
    # the Date constructor.
    if year?
      yearVal = get(year)
      date.setYear(yearVal)
      if 0 <= yearVal <= 99
        console.log("The specified value for year in qc.date.withUnits fell between 0-99 (#{yearVal}).
      This in fact means the year #{yearVal + 1900}. It is recommended that you instead use the `fullYear` key, which avoids that problem, as using `year` makes specifiying years in the 0-99 range impossible.")
    date.setFullYear(get(fullYear)) if fullYear?
    date.setMonth(get(month)) if month?
    date.setDate(get(day)) if day?
    date.setHours(get(hours)) if hours?
    date.setMinutes(get(minutes)) if minutes?
    date.setSeconds(get(seconds)) if seconds?
    date.setMilliseconds(get(milliseconds)) if milliseconds?
    date

qc.date.between = (d1, d2) ->
  dateGen qc.int.between(toDate(d1).valueOf(), toDate(d2).valueOf())
