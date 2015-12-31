# -*- coding: UTF-8 -*-

require "date"
require "fileutils"
require "set"

def git(*args)
  `git -C "#{HOMEBREW_PREFIX}" #{args * " "}`
end

def contributors(**kw)
  args = %w[shortlog -nse]
  args << "--since" << kw[:since] if kw.has_key? :since
  args << "--until" << kw[:until] if kw.has_key? :until

  git(args).lines.map do |line|
    line.split("\t", 2)[1].chomp
  end
end

def year_contributors(y)
  contributors since: "#{y}-01-01", until: "#{y+1}-01-01"
end

MIN_YEAR = 2009
MAX_YEAR = Date.today.year

years = Hash[(MIN_YEAR..MAX_YEAR).map { |y| [y, year_contributors(y)] }]

all_previous_contributors = []

years.each do |y, contribs|
  facts = ["#{contribs.count} contributors"]

  if y-1 >= MIN_YEAR
    prev_contribs = years[y-1]
    overlap = (contribs & prev_contribs).count*100.0/prev_contribs.count
    facts << "overlap of %.1f%%" % overlap
  end

  new_contributors = contribs - all_previous_contributors
  all_previous_contributors += contribs

  facts << "#{new_contributors.count} first-time contributors"

  puts "#{y}: #{facts * ", "}"
end
