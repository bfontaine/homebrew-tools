# -*- coding: UTF-8 -*-
# 
# [WIP] Find formulae needing 'bottle :unneeded'
#
#

require "formula"

compile_patterns = [
  /system "rake", "compile"/,
]

%w[make ./configure gcc cc].each { |cmd| compile_patterns << /system "#{cmd}"/ }
%w[ENV.cc ENV.cxx byte_compile].each { |cmd| compile_patterns << /\b#{cmd}\b/ }

fix = ARGV.include? "--fix"

(ARGV.formulae || Formula.core_files).each do |f|
  f = Formula[f] unless f.is_a? Formula
  next if f.bottle || !f.bottle_specification.collector.keys.empty?
  next if f.bottle_disabled? || f.bottle_unneeded?
  next unless f.patchlist.empty? && f.resources.empty?

  # let's do only the simple formulae without deps for now
  next unless f.deps.empty?

  content = f.path.read

  # extract the 'def install' code
  install_fn = content[/  def install\n.*?\n  end/m]

  next if compile_patterns.any? { |p| install_fn =~ p }

  ohai f.name
  next unless fix

  prev_clause = content =~ /^ +head / ? "head" : "sha256"
  content.gsub!(/^( +)(#{prev_clause} .*\n)/, "\\1\\2\n\\1bottle :unneeded\n")
  f.path.open("w") { |file| file.write content }
  FileUtils.cd f.tap.path do
    system "git", "add", f.path
    system "git", "commit", "-m", "#{f.name}: bottle is unneeded"
  end
end
