# -*- coding: UTF-8 -*-

require "formula"

Formula.core_files.each do |file|
  f = Formula[file]
  keys = f.bottle_specification.collector.keys
  puts f if keys.include?(:yosemite) && !keys.include?(:el_capitan)
end
