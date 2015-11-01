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

  c.any? do |c1|
    cs = c - [c1]
    (cs & registered_conflicts[c1]) != cs
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
    conflicts[bin].each do |name2|
      next if name == name2
      next if regconfs.include? name2

      conflicting_names[name2] ||= []
      conflicting_names[name2] << bin
    end
  end

  unless conflicting_names.empty?
    lines = conflicting_names.map do |n, bs|
      cause = case bs.size
              when 1
                "both install `#{bs[0]}` binaries"
              when 2, 3, 4
                "both install #{bs[0..-2].map{|b| "`#{b}`"} * ", "} and `#{bs.last}` binaries"
              else
                "both install the same binaries"
              end

      line = %(  conflicts_with "#{n}", :because => "#{cause}")
      next line if line.length < 80
      %(  conflicts_with "#{n}",\n    :because => "#{cause}")
    end.join("\n")

    ohai name
    p = Formula[name].path
    content = p.read.sub(/\n\n  def install$/, "\n\n#{lines}\n\n  def install")
    p.open("w") { |f| f.write content }
    if ARGV.include? "--commit"
      FileUtils.cd HOMEBREW_PREFIX do
        msg = "#{name}: conflicts with #{conflicting_names.keys * ", "}"
        system "git", "add", p.to_s
        system "git", "commit", "-m", msg
      end
    end
  end
end
