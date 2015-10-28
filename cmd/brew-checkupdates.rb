#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "net/ftp"
require "open-uri"
require "pathname"

# brew
require "formula"
require "version"

# need to be installed with "gem"
require "nokogiri"

module GnuFTP
  class << self
    @@ftp = nil

    attr_reader :ftp

    def connection(force=false)
      if force || @@ftp.nil?
        @@ftp = Net::FTP.open("ftp.gnu.org")
        @@ftp.login
      end
      @@ftp
    end
  end
end

module BrewCheckUpdates

  class Checker

    def initialize(checks, **flags)
      @checks = checks.map { |c| [c.name, c.new] }
      @flags = flags
    end

    def all_formulae
      # we don't support taps for now
      Formula.core_files.map { |f| Formula[f] }
    end

    def formulae(names)
      names.map {|f| Formula[f] }
    end

    def check(names=[])
      (names.empty? ? all_formulae : formulae(names)).each do |f|
        check_formula f
      end
    end

    private

    def check_formula formula
      return if formula.tap? # no tap for now

      for name, ch in @checks
        if ch.can_check formula
          version = formula.version
          #puts "checking #{basename} (v#{version}) with #{name}"
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
    def name s=nil
      @name = s || @name
    end

    def pattern p=nil
      @pattern = p || @pattern
    end
  end

  class Check
    extend CheckDSL

    def can_check formula
      pattern && formula.stable.url =~ pattern
    end

    def check formula; end

    def pattern;self.class.pattern;end

    def get_page url
      begin
        Nokogiri::HTML(open(url))
      rescue
      end
    end

    def latest_version formula, candidates
      best = {:name => nil, :version => formula.stable.version}
      nope = [/\.sig$/, /\.asc$/, /\.diff/, /\.patch/, /win32/, /mingw32/]

      candidates.each do |s|
        next if nope.any? { |r| s =~ r }

        v = Version::parse(s)

        if v && v > best[:version]
          best[:name], best[:version] = s, v
        end
      end

      best.values_at(:name, :version)
    end

    class << self
      def inherited child
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
    pattern %r(^https?://github\.com/.+?/.+?/)

    def check formula
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

  class GnuFtp < Check
    name "GNU FTP"
    pattern %r(^http://ftpmirror\.gnu\.org/)

    def check formula
      name = formula.name.downcase
      version = formula.version
      url = URI::parse(formula.stable.url)
      co = GnuFTP.connection

      dir = url.path.split("/")[1]

      co.chdir("/gnu/#{dir}")

      files = co.list("#{name}*").map { |l| l.split(/\s+/).last }

      archive, version = latest_version formula, files

      [version, "#{url.scheme}://#{url.host}/#{dir}/#{archive}"] if archive
    rescue => e
      opoo "#{name}: #{e}"
    end
  end

  # Since Google Code doesn't allow new code uploads we can't find new
  # versions. This class is an empty trap for the Google Code formulae.
  class GoogleCodeCheck < Check
    name "Google Code"
    pattern %r(googlecode\.com)
  end

  class GnuSavannahCheck < Check
    name "GNU Savannah"
    pattern %r(^http://download\.savannah\.gnu\.org/releases/.)

    def check formula
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
    def run(formulae=nil)
      Checker.new(Check.all).check formulae
    end
  end
end

# run
BrewCheckUpdates.run ARGV
