#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "open-uri"
require "pathname"

# brew
require "formula"
require "version"

# installed as part of 'brew style'
require "nokogiri"

module BrewCheckUpdates
  class Checker
    def initialize(checks, **flags)
      @checks = checks.map { |c| [c.name, c.new] }
      @flags = flags
    end

    def all_formulae
      # we don't support taps for now
      formulae Formula.core_names
    end

    def formulae(names)
      names.map { |f| Formula[f] }
    end

    def check(names = [])
      (names.empty? ? all_formulae : formulae(names)).each do |f|
        check_formula f
      end
    end

    private

    def check_formula(formula)
      ohai formula.name
      version = formula.version

      # we can't easily detect updates when a version can't be parsed from
      # the URL
      return unless version.detected_from_url?

      for name, ch in @checks
        if ch.can_check formula
          result = ch.check formula
          if result
            latest, url = result
            puts "(#{name}) #{formula.name} #{version} -> #{latest}: #{url}"
          end
          return
        end
      end
    end
  end

  module CheckDSL
    def name(s = nil)
      @name = s || @name
    end

    def pattern(p = nil)
      @pattern = p || @pattern
    end
  end

  class Check
    extend CheckDSL

    def can_check(formula)
      pattern && formula.stable.url =~ pattern
    end

    def check(formula); end

    def pattern
      self.class.pattern
    end

    def get_page(url)
      Nokogiri::HTML(open(url))
    rescue
      nil
    end

    def latest_version(formula, candidates)
      best = { :name => nil, :version => formula.stable.version }
      nope = [/\.sig$/, /\.asc$/, /\.diff/, /\.patch/, /win32/, /mingw32/]

      candidates.each do |s|
        next if nope.any? { |r| s =~ r }

        v = Version.parse(s)

        if v && v > best[:version]
          best[:name] = s
          best[:version] = v
        end
      end

      best.values_at(:name, :version)
    end

    class << self
      def inherited(child)
        @checks ||= []
        @checks << child
      end

      def all
        @checks || []
      end
    end
  end

  class GitHubCheck < Check
    name "GitHub"
    pattern %r{^https?://github\.com/.+?/.+?/}

    def check(formula)
      repo = formula.stable.url[pattern]
      page = get_page "#{repo}releases"

      return if page.nil?

      tags = [".tag-name", ".tag-references .css-truncate-target"].map do |t|
        page.css(t).first
      end.compact.map(&:text)

      latest, version = latest_version formula, tags

      [version, "#{repo}archive/#{latest}.tar.gz"] if latest
    end
  end

  # Since Google Code doesn't allow new code uploads we can't find new
  # versions. This class is an empty trap for the Google Code formulae.
  class GoogleCodeCheck < Check
    name "Google Code"
    pattern /googlecode\.com/
  end

  class GnuSavannahCheck < Check
    name "GNU Savannah"
    pattern %r{^http://download\.savannah\.gnu\.org/releases/.}

    def check(formula)
      name_re = /^#{formula.name}-/
      url = Pathname.new(formula.stable.url).dirname.to_s
      page = get_page url
      return if page.nil?

      files = page.css("td a[href]").map(&:text).select { |t| t =~ name_re }

      archive, version = latest_version formula, files

      [version, "#{url}/#{archive}"] if archive
    end
  end

  class << self
    def run(formulae = nil)
      Checker.new(Check.all).check formulae
    end
  end
end

# run
BrewCheckUpdates.run ARGV
