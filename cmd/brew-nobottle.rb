# -*- coding: UTF-8 -*-
# 
# [WIP] Find formulae needing 'bottle :unneeded'
#
#

require "formula"

compile = %w[make ./configure gcc cc].map { |cmd| /system "#{cmd}"/ }

Formula.full_names.reject { |name| name.include? "/" }.each do |name|
  f = Formula[name]
  next if f.bottle || !f.bottle_specification.collector.keys.empty?
  next if f.bottle_disabled? || f.bottle_unneeded?
  next unless f.patchlist.empty? && f.resources.empty?

  # let's do only the simple formulae without deps for now
  next unless f.deps.empty?

  # extract the 'def install' code
  install_fn = f.path.read[/  def install\n.*?\n  end/m]

  next if compile.any? { |step| install_fn =~ step }
  next if install_fn.include? "ENV.cc"

  puts f.name
end
