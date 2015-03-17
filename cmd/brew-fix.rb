# -*- coding: UTF-8 -*-

# Note: this is experimental, use it at your own risk!
# 
# This is an extension to `brew style --fix` which runs more actions on the
# formula:
#  - remove any `require "formula"` at the top
#  - replace the stable checksum with a sha256 if it's not already one

class Pathname
  def write! s
    open("w") { |p| p.write(s) }
  end
end

class FormulaFixer
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

  def fix_checksum
    chk = @f.stable.checksum
    return if chk.hash_type == :sha256

    # from cmd/fetch
    download = @f.fetch
    return unless download.file?

    replace!(/#{chk.hash_type} ["']#{chk.hexdigest}["']/,
             %(sha256 "#{download.sha256}"))
  end

  def fix_required
    remove!(/^require ["']formula["']\n+/)
  end

  def fix!
    fix_checksum
    fix_required
    write!
  end
end

ARGV.formulae.each do |f|
  FormulaFixer.new(f).fix!
end
