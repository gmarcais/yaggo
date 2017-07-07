# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubygems/package_task'
load 'lib/yaggo/version.rb'
load 'bin/create_yaggo_one_file'

spec = Gem::Specification.new do |s|
  s.name        = "yaggo"
  s.version     = $yaggo_version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Guillaume Marçais"]
  s.email       = ["gmarcais@umd.edu"]
  s.homepage    = "https://github.com/gmarcais/yaggo"
  s.summary     = "Yet Another Generator for getopt"
  s.licenses    = ['GPL-3.0']
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

desc "Run yaggo"
task :yaggo do |t|
  ARGV.shift if ARGV[0] == "yaggo"
  ruby("-Ilib", "./bin/yaggo", *ARGV)
end

task :default => :yaggo

desc "Create a distribution tarball"
task :dist do |t|
  system("tar", "-zc", "-f", "yaggo-#{spec.version}.tar.gz",
         "--transform", "s|^|yaggo-#{spec.version}/|",
         "README", "COPYING", "setup.rb", "bin", "lib")
end

desc "Create a single file executable"
task :exec do |t|
  out = "pkg/yaggo"
  puts("Creating #{out}")
  create_binary("lib/yaggo/main.rb", out)
end
