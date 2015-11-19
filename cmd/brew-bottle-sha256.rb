# This is based on Xu Cheng program here:
#   https://gist.github.com/xu-cheng/49877859eff07181dbf7

require "formula"

Formula.core_files.each do |fi|
  f = Formula[fi]
  next unless f.bottle_defined?

  formula = f.path
  source = formula.read
  updated = false

  bottle_spec = f.stable.bottle_specification
  bottle_spec.collector.keys.each do |os|
    checksum = bottle_spec.collector[os]
    next unless checksum.hash_type == :sha1
    filename = Bottle::Filename.create(f, os, bottle_spec.revision)
    url = "#{bottle_spec.root_url}/#{filename}"
    sha1 = checksum.hexdigest

    file = HOMEBREW_CACHE/filename
    FileUtils.rm_f file

    begin
      curl url, "-o", file
      file.verify_checksum(checksum)
    rescue ErrorDuringExecution
      opoo "Failed to download #{url}"
      next
    rescue ChecksumMismatchError => e
      opoo e
      FileUtils.rm_f file
      next
    end

    source.gsub!(/sha1 ["']#{sha1}["']/, %(sha256 "#{file.sha256}"))
    updated = true
    # I don't have unlimited disk space ;)
    FileUtils.rm_f file
  end

  next unless updated

  ohai "Update #{formula.basename(".rb")}"
  formula.open("w") { |io| io.write source }
end
