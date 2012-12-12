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


def zsh_conflict_option o
  conflict_options = o.conflict + $options.map { |co|
    (co.conflict.include?(o.short) || co.conflict.include?(o.long)) ? (co.short || co.long) : nil
  }.compact.uniq
  return "" if conflict_options.empty?
  "'(" + conflict_options.map { |co_name|
    co = $opt_hash[co_name]
    [co.short && "-#{co.short}", co.long && "--#{co.long}"]
  }.flatten.compact.uniq.join(" ") + ")'"
end

def zsh_switches_option o
  switches = if o.type == :flag 
               [o.short && "-#{o.short}", o.long && "--#{o.long}"]
             else
               [o.short && "-#{o.short}+", o.long && "--#{o.long}="]
             end
  switches.compact!
  swstr = switches.size > 1 ? "{#{switches.join(",")}}" : switches[0]
  swstr = "\\*#{swstr}" if o.multiple
  swstr
end

def zsh_type_completion o, with_type = true
  typedescr = o.typestr || o.type.id2name
  typename = with_type ? ":" + typedescr : ""
  guard_help = "#{typedescr} #{o.description || ""}"
  case o.type
  when :flag
    return ""
  when :enum
    return "#{typename}:(#{o.enum.join(" ")})"
  when :string, :c_string
    case o.typestr || ""
    when /file|path/i
      return "#{typename}:_files"
    when /dir/i
      return "#{typename}:_files -/"
    else
      return typename
    end
  when :int32, :int64, :int, :long
    suffixes = o.suffix ? "[kMGTPE]" : ""
    return "#{typename}:_guard \"[0-9+-]##{suffixes}\" \"#{guard_help}\""
  when :uint32, :uint64
    suffixes = o.suffix ? "[kMGTPE]" : ""
    return "#{typename}:_guard \"[0-9+]##{suffixes}\" \"#{guard_help}\""
  when :double
    suffixes = "[munpfakMGTPE]" if o.suffix
    return "#{typename}:_guard \"[0-9.eE+-]##{suffixes}\" \"#{guard_help}\""
  else
    return default
  end
end

def output_zsh_completion(fd, filename)
  cmdname = File.basename(filename).gsub(/^_/, "")
  
  fd.puts("#compdef #{cmdname}", "",
          "local context state state_descr line",
          "typeset -A opt_args", "")
  return if $options.empty? && $args.empty?
  fd.puts("_arguments -s -S \\") 
  $options.each { |o|
    conflicts = zsh_conflict_option o
    switches = zsh_switches_option o
    descr = o.description ? "[#{o.description}]" : ""
    action = zsh_type_completion o, true
    fd.puts("#{conflicts}#{switches}'#{descr}#{action}' \\")
  }
  $args.each { |a|
    descr = a.description || " "
    action = zsh_type_completion a, false
    many = a.multiple ? "*" : ""
    fd.puts("'#{many}:#{descr}#{action}' \\")
  }
  fd.puts(" && return 0")
end
