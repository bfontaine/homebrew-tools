# -*- coding: UTF-8 -*-

require "cmd/tap"

tap = Tap.fetch("homebrew", "command-not-found")
install_tap(tap.user, tap.repo) unless tap.installed?

conflicts = {}
registered_conflicts = {}

(tap.path/"executables.txt").each_line do |line|
  name, binaries = line.split(":")
  next if binaries.nil?
  next if name.include? "/" # no taps for now

  f = Formula[name]

  next if f.keg_only?

  registered_conflicts[name] ||= f.conflicts.map(&:name)
  binaries.split(" ").each do |bin|
    conflicts[bin] ||= []
    conflicts[bin] << name
  end
end

conflicts.select! do |_, c|
  next false if c.size == 1

  # FIXME
  c.all? do |c1|
    cs = c - [c1]
    (cs & registered_conflicts[c1]) == cs
  end
end

binaries = {}
conflicts.each do |bin, names|
  names.each do |name|
    binaries[name] ||= []
    binaries[name] << bin
  end
end

binaries.each do |name, bins|
  conflicting_names = {}
  regconfs = registered_conflicts[name]

  bins.each do |bin|
    conflicts[bin].delete name
    conflicts[bin].each do |name2|
      next if regconfs.include? name2

      conflicting_names[name2] ||= []
      conflicting_names[name2] << bin
    end
  end

  unless conflicting_names.empty?
    ohai name
    conflicting_names.each do |n, bs|
      cause = case bs.size
              when 1
                "both install `#{bs[0]}` binaries"
              when 2, 3, 4
                "both install #{bs[0..-2].map{|b| "`#{b}`"} * ", "} and `#{bs.last}` binaries"
              else
                "both install the same binaries"
              end

      puts %(conflicts_with "#{n}", :because => "#{cause}")
    end
  end
end
