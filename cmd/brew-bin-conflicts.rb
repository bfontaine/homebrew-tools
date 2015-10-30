# -*- coding: UTF-8 -*-

require "cmd/tap"

tap = Tap.fetch("homebrew", "command-not-found")
install_tap(tap.user, tap.repo) unless tap.installed?

conflicts = {}

(tap.path/"executables.txt").each_line do |line|
  name, binaries = line.split(":")
  next if binaries.nil?
  next if name.include? "/" # no taps for now

  binaries.split(" ").each do |bin|
    conflicts[bin] ||= []
    conflicts[bin] << name
  end
end

conflicts.select! do |_, c|
  next false if c.size == 1

  c.all? do |c1|
    cs = c - [c1]
    (cs & Formula[c1].conflicts.map(&:name)) == cs
  end
end

# TODO group conflicts by common names, e.g.:
#   {
#     foo1 => bar, qux
#     foo2 => bar, qux, qux2
#   }
#
#   {
#     [foo1, foo2] => bar, qux
#     foo2 => qux2
#   }

conflicts.each do |bin, names|
  puts "#{bin} is provided by #{names * ", "}"
end
