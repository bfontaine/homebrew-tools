# -*- coding: UTF-8 -*-
require "formula"
require "tap"

versions_tap = Tap.fetch("homebrew", "versions")
ff = versions_tap.formula_files.map { |f| Formula[f] }
ff.reject! { |f| !f.desc.nil? }

core_ff = Formula.core_names

FileUtils.cd versions_tap.path do
  ff.each do |f|
    basename = f.name.gsub(/\d+$/, "")
    next unless core_ff.include? basename

    origin = Formula[basename]
    next unless origin.desc
    next if "#{f.full_name}: #{origin.desc}".size >= 80

    class_name = f.name.gsub(/[-_]([a-z])/) { $1.upcase }.capitalize

    content = f.path.read
    content.gsub!(/^(class #{class_name} < [^\n]+)\n/, %(\\1\n  desc "#{origin.desc}"\n))
    f.path.open("w") do |file|
      file.write content
    end

    system "git", "add", f.path.basename
    system "git", "commit", "-m", "#{f.name}: desc added"
  end
end
