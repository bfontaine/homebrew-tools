# -*- coding: UTF-8 -*-

require "formula"

Formula.core_files.each do |file|
  f = Formula[file]
  keys = f.bottle_specification.collector.keys
  next if keys.empty? || keys.include?(:el_capitan)
  next if f.requirements.any? do |r|
    r.is_a?(MaximumMacOSRequirement) && !r.tags.include?(:el_capitan)
  end
  puts f
end
