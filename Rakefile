# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |s|
  s.name        = "yaggo"
  s.version     = "1.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Guillaume Marçais"]
  s.email       = ["gmarcais@umd.edu"]
#  s.homepage    = "http://github.com/carlhuda/newgem"
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
