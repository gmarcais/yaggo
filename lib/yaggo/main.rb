# This file is part of Yaggo.

# Yaggo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Yaggo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Yaggo.  If not, see <http://www.gnu.org/licenses/>.

require 'optparse'

require 'yaggo/version'
require 'yaggo/man_page'
require 'yaggo/stub'
require 'yaggo/general'
require 'yaggo/library'
require 'yaggo/dsl'
require 'yaggo/parser'
require 'yaggo/zsh_completion'

def main
  $yaggo_options = {
    :output => nil,
    :license => nil,
    :stub => false,
    :zc => nil,
    :extended => false,
    :debug => false,
  }

  parser = OptionParser.new do |o|
    o.version = $yaggo_version
    o.banner = "Usage: #{$0} [options] [file.yaggo]"
    o.separator ""
    o.separator "Specific options:"

    o.on("-o", "--output FILE", "Output file") { |v|
      $yaggo_options[:output] = v
    }
    o.on("-l", "--license PATH", "License file to copy in header") { |v|
      $yaggo_options[:license] = v
    }
    o.on("-m", "--man [FILE]", "Display or write manpage") { |v|
      display_man_page v
      exit 0;
    }
    o.on("-s", "--stub", "Output a stub yaggo file") {
      $yaggo_options[:stub] = true
    }
    o.on("--zc PATH", "Write zsh completion file") { |v|
      $yaggo_options[:zc] = v
    }
    o.on("-e", "--extended-syntax", "Use extended syntax") {
      $yaggo_options[:extended] = true
    }
    o.on("--debug", "Debug yaggo") {
      $yaggo_options[:debug] = true
    }

    o.on_tail("-h", "--help", "Show this message") {
      puts o
      exit 0
    }
  end
  parser.parse! ARGV

  if $yaggo_options[:stub]
    begin
      display_stub_yaggo_file $yaggo_options[:output]
    rescue => e
      STDERR.puts("Failed to write stub: #{e.message}")
      exit 1
    end

    exit
  end

  if !$yaggo_options[:stub] && !$yaggo_options[:manual] && ARGV.empty?
    STDERR.puts "Error: some yaggo files and/or --lib switch is required", parser
    exit 1
  end
  if !$yaggo_options[:output].nil?
    if $yaggo_options[:stub]
      if ARGV.size > 0
        STDERR.puts "Error: no input file needed with the --stub switch", parser
        exit 1
      end
    elsif ARGV.size != 1
      STDERR.puts "Error: output switch meaningfull only with 1 input file", parser
      exit 1
    end
  end

  ARGV.each do |input_file|
    pid = fork do
      begin
        yaggo_script = File.read(input_file)
        if $yaggo_options[:extended]
          yaggo_script.gsub!(/\)\s*\n\s*\{/, ") {")
        end
        eval(File.read(input_file))
        parsed = true
        check_conflict_exclude
      rescue RuntimeError, SyntaxError, Errno::ENOENT, Errno::EACCES => e
        raise e if $yaggo_options[:debug]
        STDERR.puts(e.message.gsub(/^\(eval\)/, input_file))
        exit 1
      rescue NoMethodError => e
        raise e if $yaggo_options[:debug]
        STDERR.puts("Invalid keyword '#{e.name}'")
        exit 1
      end

      fsplit    = File.basename(input_file).split(/\./)
      $klass  ||= fsplit.size > 1 ? fsplit[0..-2].join(".") : fsplit[0]
      $output   = $yaggo_options[:output] if $yaggo_options[:output]
      $output ||= input_file.gsub(/\.yaggo$/, "") + ".hpp"
      
      begin
        out_fd = open($output, "w")
        output_cpp_parser(out_fd, $klass)
      rescue RuntimeError => e
        raise e if $yaggo_options[:debug]
        STDERR.puts("#{input_file}: #{e.message}")
        exit 1
      ensure
        out_fd.close if out_fd
      end

      if $yaggo_options[:zc]
        begin
          out_fd = open($yaggo_options[:zc], "w")
          output_zsh_completion(out_fd, $yaggo_options[:zc])
        rescue RuntimeError => e
          raise e if $yaggo_options[:debug]
          STDERR.puts("#{input_file}: #{e.message}")
          exit 1
        ensure
          out_fd.close if out_fd
        end
      end
    end
    Process.waitpid pid
    exit 1 if !$?.exited? || ($?.exited? && $?.exitstatus != 0)
  end
end
