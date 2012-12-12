$typejust = 30
$switchesjust = 40

$type_to_C_type = { 
  :uint32 => "uint32_t",
  :uint64 => "uint64_t",
  :int32 => "int32_t",
  :int64 => "int64_t",
  :int => "int",
  :long => "long",
  :double => "double",
  :string => "string",
  :c_string => "const char *",
  :enum => "int",
}
$type_default = {
  :uint32 => "0",
  :uint64 => "0",
  :int32 => "0",
  :int64 => "0",
  :int => "0",
  :long => "0",
  :double => "0.0",
  :string => "",
  :c_string => "",
  :enum => "0",
}

def dflt_typestr(type, *argv)
  case type
  when :c_string
    "string"
  when :enum
    argv[0].join("|")
  else
    type.to_s
  end
end

def suffix_arg(suffix)
  case suffix
  when true
    "true"
  when false
    "false"
  when String
    suffix
  else
    raise "Invalid suffix specifier"
  end
end

def str_conv(arg, type, *argv)
  case type
  when :string
    "string(#{arg})"
  when :c_string
    arg
  when :uint32, :uint64
    "conv_uint<#{$type_to_C_type[type]}>((const char*)#{arg}, err, #{suffix_arg(argv[0])})"
  when :int32, :int64, :long, :int
    "conv_int<#{$type_to_C_type[type]}>((const char*)#{arg}, err, #{suffix_arg(argv[0])})"
  when :double
    "conv_double((const char*)#{arg}, err, #{suffix_arg(argv[0])})"
  when :enum
    # Convert a string to its equivalent enum value
    "conv_enum((const char*)#{arg}, err, #{argv[0]})"
  end
end

def find_error_header bt
  bt.each { |l| l =~ /^\(eval\):\d+:/ and return $& }
  return ""
end

def run_block(name, b)
  eval("#{$option_variables.join(" = ")} = nil", $main_binding)
  b.call
  $option_variables.each { |n| eval("#{n} #{n} unless #{n}.nil?", $main_binding) }
rescue NoMethodError => e
  header = find_error_header(e.backtrace)
  raise "#{header} In #{name}: invalid keyword '#{e.name}' in statement '#{e.name} #{e.args.map { |s| "\"#{s}\"" }.join(" ")}'"
rescue NameError => e
  header = find_error_header(e.backtrace)
  raise "#{header} In #{name}: invalid keyword '#{e.name}'"
rescue RuntimeError, ArgumentError => e
  header = find_error_header(e.backtrace)
  raise "#{header} In #{name}: #{e.message}"
end


def check_conflict_exclude
  $options.each { |o|
    $opt_hash[o.long] = o unless o.long.nil?
    $opt_hash[o.short] = o unless o.short.nil?
  }
  $options.each { |o|
    o.conflict.each { |co|
      $opt_hash[co] or 
      raise "Unknown conflict option '#{co}' for switch #{o.long}|#{o.short}"
    }
  }
  $options.each { |o|
    o.imply.each { |ios|
      io = $opt_hash[ios] or
      raise "Unknown implied option '#{io}' for switch #{o.long}|#{o.short}"
      io.type == :flag or
      raise "Implied option '#{io}' for switch #{o.long}|#{o.short} is not a flag"
    }
  }
end
