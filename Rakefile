# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |s|
  s.name        = "yaggo"
  s.version     = "1.3.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Guillaume Marçais"]
  s.email       = ["gmarcais@umd.edu"]
  s.homepage    = "https://github.com/gmarcais/yaggo"
  s.summary     = "Yet Another Generator for getopt"
  s.description = "Yaggo defines a DSL to generate GNU compatible command line parsers for C++ using getopt."

  s.required_rubygems_version = ">= 1.3.6"

  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'

  # If you need an executable, add it here
  s.executables = ["yaggo"]
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

task :yaggo do |t|
  ARGV.shift if ARGV[0] == "yaggo"
  ruby("-Ilib", "./bin/yaggo", *ARGV)
end

task :default => :yaggo

task :dist do |t|
  system("tar", "-zc", "-f", "yaggo-#{spec.version}.tar.gz",
         "--transform", "s|^|yaggo-#{spec.version}/|",
         "README", "COPYING", "setup.rb", "bin", "lib")
end

def inline_includes ifd, ofd, loaded
  ifd.lines.each { |l|
    if l =~ /^\s*require\s+['"]yaggo\/(\w+)['"]\s*$/
      file = $1
      unless loaded[file]
        loaded[file] = true
        ofd.puts("", "# Loading yaggo/#{file}", "")
        open(File.join("lib", "yaggo", file + ".rb"), "r") { |nfd|
          inline_includes(nfd, ofd, loaded)
        }
      end
    else
      ofd.print(l)
    end
  }
end

task :exec do |t|
  loaded = {}
  open("yaggo", "w", 0755) do |wfd|
    open("bin/yaggo", "r") do |rfd|
      inline_includes(rfd, wfd, loaded)
    end
  end
end
