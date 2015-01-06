generators = %w[basic number string array object functions various combinators]
generators.each do |generator|
  str = File.read("src/generators/#{generator}.coffee")
  lines = str.split("\n")
  groups = []

  lines.each{|line|
    if  line[0] == '#'
      if groups.length > 0 && groups.last[:type] == :comment
        groups.last[:content] << "\n" + line[1..-1].strip
      else
        groups << {type: :comment, content: line[1..-1].strip}
      end
    else
      if groups.length > 0  && groups.last[:type] == :code
        groups.last[:content] << "\n" + line
      else
        groups << {type: :code, content: line}
      end
    end
  }

  docs = groups.each_with_index.to_a.select{ |group, i|
    group[:type] == :code && group[:content].match(/^qc\.[\w\.]+\s*=/)
  }.map{ |group, i|
    comment = groups[i - 1]
    [group[:content].match(/^(qc\.[\w\.]+)\s*=/).captures.first, i, comment[:content]] if comment[:type] == :comment
  }

  headers = groups.each_with_index.to_a.select{ |group, i|
    group[:type] == :comment && group[:content].match(/^\s*#+/)
  }

  output = docs.concat(headers).sort_by{|heading, index| index }.map do |heading, index, content|
    if content.nil?
      heading[:content]
    else
      "### `" + heading + "`\n" + content
    end
  end.join("\n\n")
  puts output
end
