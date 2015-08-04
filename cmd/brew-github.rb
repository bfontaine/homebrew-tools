# -*- coding: UTF-8 -*-

GH_RE = %r[^https?://github\.com/([^/]+)/([^/]+)]
GH_IO_RE = %r[^https?://([^.]+)\.github\.io/([^/+])]

class Formula
  # Don't do this code at home
  def github_repo
    "https://github.com/#{$1}/#{$2.sub(/\.git$/, "")}" \
      if ([homepage] + [stable, devel, head].map { |r| r && r.url }).any? do |url|
        url && url =~ GH_RE || url =~ GH_IO_RE
      end
  end
end

exec_browser(*ARGV.formulae.map(&:github_repo).compact)
