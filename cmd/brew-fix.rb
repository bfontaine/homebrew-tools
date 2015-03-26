# -*- coding: UTF-8 -*-

# Note: this is experimental, use it at your own risk!
#
# This is an extension to `brew style --fix` which runs more actions on the
# formula:
#  - remove any `require "formula"` at the top
#  - replace the stable checksum with a sha256 if it's not already one
#  - replace `system "make install"` with `system "make", "install"`

require "fileutils"

# from Homebrew
require "utils"
require "extend/pathname"

class Pathname
  def write! s
    open("w") { |p| p.write(s) }
  end
end

class FormulaFixer
  include FileUtils

  def initialize(f)
    system "brew", "style", "--fix", f.name
    @f = f
    @source = @f.path.open(&:read)
  end

  def replace!(pattern, repl)
    @source.gsub!(pattern, repl)
  end

  def remove!(pattern)
    replace! pattern, ""
  end

  def write!
    @f.path.write! @source
  end

  def fix_url_https(http)
    # see https://gist.github.com/vszakats/663dc8ccf1d49b903f8e
    return unless http && http =~ %r(^http://) && http !~ %r(\.git$)

    https = http.sub(/^http:/, "https:")

    has_https = mktemp("brew-fix-https") do
      curl http, "-s", "--connect-timeout", "2", "-o", "http"

      begin
        curl https, "-s", "--connect-timeout", "2", "-o", "https"
      rescue ErrorDuringExecution
        false
      else
        Pathname.new("http").sha256 == Pathname.new("https").sha256
      end
    end

    if has_https
      replace! http, https
    end
  end

  def fix_https
    urls = [@f.homepage, @f.stable.url] + @f.stable.mirrors
    urls << @f.head.url if @f.head
    urls.each do |url|
      fix_url_https url
    end
  end

  def fix_common_https_urls
    [
      %r[github\.com/],
      %r[code\.google\.com/],
      %r[(?:www|ftp)\.gnu\.org/],
      %r[(?:(?:trac|tools|www)\.)?ietf\.org],
      %r[(?:www\.)?gnupg\.org/],
      %r[wiki\.freedesktop\.org],
      %r[packages\.debian\.org],
      %r[[^/]*github\.io/],
      %r[[^/]*\.apache\.org],
      %r[fossies\.org/],
      %r[mirrors\.kernel\.org/],
      %r[([^/]*\.|)bintray\.com/],
      %r[tools\.ietf\.org/],
    ].each do |domain|
      replace!(%r[["']http://(#{domain})], %("https://\\1))
    end
  end

  def fix_deps
    %w[git ruby].each do |dep|
      remove!(/^\s+depends_on\s+["']#{dep}["']\n+/)
    end

    {"mercurial" => ":hg", "gfortran" => ":fortran"}.each do |bad, good|
      good = "\"#{good}\"" unless good =~ /^:/
      replace!(/^(\s+depends_on)\s+["']#{bad}["']$/, %(\\1 #{good}))
    end
  end

  def fix_checksum
    chk = @f.stable.checksum
    return if !chk || chk.hash_type == :sha256

    # from cmd/fetch
    download = @f.fetch
    return unless download.file?

    replace!(/#{chk.hash_type} ["']#{chk.hexdigest}["']/,
             %(sha256 "#{download.sha256}"))
  end

  def fix_required
    remove!(/^require ["']formula["']\n+/)
  end

  def fix_make_install
    replace!(/^(\s+)system "make ([a-z]+)"$/, %(\\1system "make", "\\2"))
  end

  def fix!
    fix_checksum
    fix_required
    fix_make_install
    fix_deps
    fix_common_https_urls
    fix_https
    write!
  end
end

ARGV.formulae.each do |f|
  FormulaFixer.new(f).fix!
end
