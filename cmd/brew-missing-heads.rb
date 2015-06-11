# -*- coding: UTF-8 -*-

require "formula"

Formula.each do |f|
  next if f.tap? || f.stable.nil? || f.stable.url !~ /github\.com/ || !f.head.nil? || !f.test_defined?

  puts f.full_name
end
