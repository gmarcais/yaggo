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


##############################
# Process an input files. Define the Domain Specific Language.
##############################
$options = []
$opt_hash = {}
$args = []

class NoTarget
  def description str; $description = str; end
  def description= str; $description = str; end
  def method_missing(m, *args)
    raise "'#{m}' used outside of option or arg description"
  end
end
$target = NoTarget.new

def output str; $output = str; end
def name str; $class = str; end
def purpose str; $purpose = str; end
def package str; $package = str; end
def usage str; $usage = str; end
def text str; $after_text = str; end
def description str; $target.description = str; end
def version str; $version = str; end
def posix *args; $posix = true; end
def license str; $license = str; end
$global_variables = [:output, :name, :purpose, :package,
                     :description, :version, :license, :posix]
output = name = purpose = package = description = version = license = nil

# def set_type t
#   raise "More than 1 type specified: '#{$target.type}' and '#{t}'" unless $target.type.nil?
#   $target.type = t
# end

def int32;    $target.type = :int32; end
def int64;    $target.type = :int64; end
def uint32;   $target.type = :uint32; end
def uint64;   $target.type = :uint64; end
def int;      $target.type = :int; end
def long;     $target.type = :long; end
def double;   $target.type = :double; end
def string;   $target.type = :string; end
def c_string; $target.type = :c_string; end
def flag;     $target.type = :flag; end
def enum(*argv); $target.type = :enum; $target.enum = argv; end

def suffix; $target.suffix = true; end
def required; $target.required = true; end
def hidden; $target.hidden = true; end
def secret; $target.secret = true; end
def on; $target.on; end
def off; $target.off; end
def no; $target.no; end
def default str; $target.default = str; end
def typestr str; $target.typestr = str; end
def multiple; $target.multiple = true; end
def at_least n; $target.at_least = n; end
def conflict *a; $target.conflict= a; end
def imply *a; $target.imply= a; end
def access *types; $target.access= types; end
# Define the following local variables and check their value after
# yielding the block to catch syntax such as default="value".
$option_variables = [:default, :typestr, :at_least]
default = typestr = at_least = nil
$main_binding = binding

def default_val(val, type, *argv)
  case type
  when :string, :c_string
    "\"#{val || $type_default[type]}\""
  when :uint32, :uint64, :int32, :int64, :int, :long, :double
    "(#{$type_to_C_type[type]})#{val}"
  else
    val.to_s || $type_default[type]
  end
end

class BaseOptArg
  def at_least=(n)
    multiple = true
    nb = case n
         when Integer
           n
         when String
           n =~ /^\d+$/ ? n.to_i : nil
         else
           nil
         end
    raise "Invalid minimum number for at_least (#{n})" if nb.nil?
    self.multiple = true
    @at_least = nb
  end

  def type=(t)
    raise "More than 1 type specified: '#{type}' and '#{t}'" unless @type.nil? || @type == t
    @type = t
  end

  def suffix=(t)
    case type
    when nil
      raise "A numerical type must be specify before suffix"
    when :flag, :string, :c_string
      raise "Suffix is meaningless with the type #{type}"
    end
    @suffix = t
  end

  def access=(types)
    types.all? { |t| ["read", "write", "exec"].include?(t) } or
      raise "Invalid access type(s): #{types.join(", ")}"
    @access_types = types
  end

  def check
    if !@access_types.empty? && @type != :c_string
      raise "Access checking is valid only with a path (a c_string)"
    end
  end
end

class Option < BaseOptArg
  attr_accessor :description, :required, :typestr
  attr_accessor :hidden, :secret, :conflict, :multiple, :access_types, :noflag
  attr_reader :long, :short, :var, :type, :at_least, :default, :suffix, :enum
  attr_reader :imply

  def initialize(long, short)
    @long, @short = long, short
    @var = (@long || @short).gsub(/[^a-zA-Z0-9_]/, "_")
    @type = nil
    @no = false # Also generate the --noswitch for a flag
    @default = nil
    @suffix = false
    @at_least = nil
    @conflict = []
    @enum = []
    @imply = []
    @access_types = []
  end

  def on
    self.type = :flag
    self.default = "true"
  end

  def off
    self.type = :flag
    self.default = "false"
  end

  def no
    self.type = :flag
    self.noflag = true
  end

  def tf_to_on_off v
    case v
    when "true"
      "on"
    when "false"
      "off"
    else
      v
    end
  end

  def convert_int(x, signed = true)
    x =~ /^([+-]?\d+)([kMGTPE]?)$/ or return nil
    v = $1.to_i
    return nil if v < 0 && !signed
    case $2
    when "k"
      v *= 1000
    when "M"
      v *= 1000_000
    when "G"
      v *= 1000_000_000
    when "T"
      v *= 1000_000_000_000
    when "P"
      v *= 1000_000_000_000_000
    when "E"
      v *= 1000_000_000_000_000_000
    end
    return v
  end

  def convert_double(x)
    x =~ /^([+-]?[\d]+(?:\.\d*))?(?:([afpnumkMGTPE])|([eE][+-]?\d+))?$/ or return nil
    v = "#{$1}#{$3}".to_f
    case $2
    when "a"
      v *= 1e-18
    when "f"
      v *= 1e-15
    when "p"
      v *= 1e-12
    when "n"
      v *= 1e-9
    when "u"
      v *= 1e-6
    when "m"
      v *= 1e-3
    when "k"
      v *= 1e3
    when "M"
      v *= 1e6
    when "G"
      v *= 1e9
    when "T"
      v *= 1e12
    when "P"
      v *= 1e15
    when "E"
      v *= 1e18
    end
    return v
  end

  def default=(v)
    type.nil? and raise "A type must be specified before defining a default value"
    unless default.nil?
      if type == :flag
        v1, v2 = tf_to_on_off(default), tf_to_on_off(v)
      else
        v1, v2 = default, v
      end
      raise "More than 1 default value specified: '#{v1}' and '#{v2}'"
    end
    pref = "Option #{long || ""}|#{short || ""}:"
    bv = v # Backup v for display
    case @type
    when nil
      raise "#{pref} No type specified"
    when :uint32, :uint64
      (Integer === v && v >= 0) || (String === v && v = convert_int(v, false)) or
        raise "#{pref} Invalid unsigned integer '#{bv}'"
    when :int32, :int64, :int, :long
      (Integer === v) || (String === v && v = convert_int(v, true)) or
        raise "#{pref} Invalid integer #{bv}"
    when :double
      (Float === v) || (String === v && v = convert_double(v)) or
        raise "#{pref} Invalid double #{bv}"
    when :enum
      v = v.to_i if v =~ /^\d+$/
      case v
      when Integer
        (v >= 0 && v < @enum.size) or
          raise "Default is out of range [0, #{@enum.size-1}]"
      when String
        nv = @enum.index(v) or
          raise "Unknown constant '#{v}'. Should be one of { #{@enum.join(", ")} }"
        v = nv
      else
        raise "Expected an Integer or a String"
      end
    end
    @default = v
  end

  def enum=(*argv)
    @type == :enum or raise "#{pref} Enum valid only for enum types."
    @enum = argv.flatten
  end

  def conflict= a; @conflict += a.map { |x| x.gsub(/^-+/, "") }; end
  def imply= a; @imply += a.map { |x| x.gsub(/^-+/, "") }; end

  def check
    pref = "Option #{long || ""}|#{short || ""}:"
    raise "#{pref} No type specified" if type.nil?

    if multiple
      raise "#{pref} Multiple is meaningless with a flag" if type == :flag
      raise "#{pref} An option marked multiple cannot have a default value" unless default.nil?
      raise "#{pref} Multiple is incompatible with enum type" if type == :enum
    end

    if @type == :flag && noflag && !short.nil?
      raise "#{pref} flag with 'no' option cannot have a short switch"
    end

    super

    # case @type
    # when nil
    #   raise "#{pref} No type specified"
    # when :uint32, :uint64
    #   @default.nil? || @default =~ /^\d+$/ or
    #     raise "#{pref} Invalid unsigned integer #{@default}"
    # when :int32, :int64, :int, :long
    #   @default.nil? || @default =~ /^[+-]?\d+$/ or
    #     raise "#{pref} Invalid integer #{@default}"
    # when :double
    #   @default.nil? || @default =~ /^[+-]?[\d.]+([eE][+-]?\d+)?$/ or
    #     raise "#{pref} Invalid double #{@default}"
    # when :flag
    #   raise "#{pref} A flag cannot be declared multiple" if @multiple
    #   raise "#{pref} Suffix is meaningless for a flag" if @suffix
    # end
  end

  def static_decl
    a = []
    if @type == :enum
      a << "struct #{@var} {"
      a << "  enum { #{@enum.map { |x| x.gsub(/[^a-zA-Z0-9_]/, "_") }.join(", ")} };"
      a << "  static const char* const  strs[#{@enum.size + 1}];"
      a << "};"
    end
    a
  end

  def var_decl
    if @type == :flag
      ["#{"bool".ljust($typejust)} #{@var}_flag;"]
    else
      a = []
      if @multiple
        c_type = "::std::vector<#{$type_to_C_type[@type]}>"
        a << (c_type.ljust($typejust) + " #{@var}_arg;")
        a << ("typedef #{c_type}::iterator #{@var}_arg_it;")
        a << ("typedef #{c_type}::const_iterator #{@var}_arg_const_it;")
      else
        a << "#{$type_to_C_type[@type].ljust($typejust)} #{@var}_arg;"
      end
      a << "#{"bool".ljust($typejust)} #{@var}_given;"
    end
  end

  def init
    s = "#{@var}_#{@type == :flag ? "flag" : "arg"}("
    s += default_val(@default, @type, @enum) unless @multiple
    s += ")"
    unless @type == :flag
      s += ", #{@var}_given(false)"
    end
    s
  end

  def long_enum
    return nil if !@short.nil?
    res = [@var.upcase + "_OPT"]
    if @type == :flag && noflag
      res << "NO#{@var.upcase}_OPT"
    end
    res
  end

  def struct
    res = ["{\"#{long}\", #{@type == :flag ? 0 : 1}, 0, #{@short ? "'" + @short + "'" : long_enum[0]}}"]
    if @type == :flag && noflag
      res << "{\"no#{long}\", 0, 0, #{long_enum()[1]}}"
    end
    res
  end
  def short_str
    return nil if @short.nil?
    @short + (@type == :flag ? "" : ":")
  end
  def switches
    s  = @short.nil? ? "    " : "-#{@short}"
    s += ", " unless @short.nil? || @long.nil?
    unless @long.nil?
      if @type == :flag && @noflag
        s += "--[no]#{@long}"
      else
        s += "--#{@long}"
      end
      s += "=#{@typestr || dflt_typestr(@type, @enum)}" unless @type == :flag
    end
    s
  end

  def default_str
    return @default unless @type == :enum
    @enum[@default || 0]
  end

  def help
    s  = @required ? "*" : " "
    @description ||= "Switch #{switches}"
    s += @description.gsub(/"/, '\"') || ""
    default = default_str
    s += " (#{default})" unless default.nil?
    s
  end

  def dump
    case @type
    when :flag
      ["\"#{@var}_flag:\"", "#{@var}_flag"]
    when :enum
      ["\"#{@var}_given:\"", "#{@var}_given",
       "\" #{@var}_arg:\"", "#{@var}_arg", '"|"', "#{@var}::strs[#{@var}_arg]"]
    else
      ["\"#{@var}_given:\"", "#{@var}_given", 
       "\" #{@var}_arg:\"", @multiple ? "vec_str(#{@var}_arg)" : "#{@var}_arg"]
    end
  end

  def parse_arg(no = false)
    a = @imply.map { |ios| "#{$opt_hash[ios].var}_flag = true;" }
    a << "#{@var}_given = true;" unless @type == :flag
    case @type
    when :flag
      if @noflag
        a << ["#{@var}_flag = #{no ? "false" : "true"};"]
      else
        a << ["#{@var}_flag = #{@default == "true" ? "false" : "true"};"]
      end
    when :string
      a << (@multiple ? "#{@var}_arg.push_back(#{str_conv("optarg", @type, false)});" : "#{@var}_arg.assign(optarg);")
    when :c_string
      a << (@multiple ? "#{@var}_arg.push_back(#{str_conv("optarg", @type, false)});" : "#{@var}_arg = optarg;")
    when :uint32, :uint64, :int32, :int64, :int, :long, :double
      a << (@multiple ? "#{@var}_arg.push_back(#{str_conv("optarg", @type, @suffix)});" : "#{@var}_arg = #{str_conv("optarg", @type, @suffix)};")
      a << "CHECK_ERR(#{@type}_t, optarg, \"#{switches}\")" 
    when :enum
      a << "#{@var}_arg = #{str_conv("optarg", @type, "#{@var}::strs")};"
      a << "CHECK_ERR(#{@type}, optarg, \"#{switches}\")"
    end
    a
  end
end

class Arg < BaseOptArg
  attr_accessor :description, :type, :typestr, :multiple, :access_types
  attr_reader :name, :at_least, :suffix, :var
  def initialize(str)
    @name = str
    @var = @name.gsub(/[^a-zA-Z0-9_]/, "_")
    @type = nil
    @at_least = 0
    @suffix = false
    @access_types = []
  end

  def type=(t)
    super
    raise "An arg cannot be of type '#{t}'" if t == :flag
  end

  def on; raise "An arg cannot be a flag with default value on"; end
  def off; raise "An arg cannot be a flag with default value off"; end

  def default=(*args)
    raise "An arg cannot have a default value (#{args[0]})"
  end

  def hidden=(*args)
    raise "An arg cannot be marked hidden"
  end

  def secret=(*args)
    raise "An arg cannot be marked secret"
  end

  def required=(*args)
    raise "An arg cannot be marked required"
  end

  def check
    super

    pref = "Arg #{name}:"
    raise "#{pref} No type specified" if type.nil?
  end

  def var_decl
    if @multiple
      c_type = "::std::vector<#{$type_to_C_type[@type]}>"
      [c_type.ljust($typejust) + " #{@var}_arg;",
       "typedef #{c_type}::iterator #{@var}_arg_it;",
       "typedef #{c_type}::const_iterator #{@var}_arg_const_it;"]
    else
      ["#{$type_to_C_type[@type]}".ljust($typejust) + " #{@var}_arg;"]
    end
  end

  def init
    s = "#{@var}_arg("
    s += default_val(@default, @type) unless @multiple
    s += ")"
    s
  end

  def dump
    ["\"#{@var}_arg:\"",
     @multiple ? "vec_str(#{@var}_arg)" : "#{@var}_arg"]
  end

  def parse_arg
    a = []
    off = ""
    if @multiple
      a << "for( ; optind < argc; ++optind) {"
      a << "  #{@var}_arg.push_back(#{str_conv("argv[optind]", @type, @suffix)});"
      off = "  "
    else
      a << "#{@var}_arg = #{str_conv("argv[optind]", @type, @suffix)};"
    end
    unless @type == :string || @type == :c_string
      a << (off + "CHECK_ERR(#{@type}_t, argv[optind], \"#{@var}\")")
    end
    a << (@multiple ? "}" : "++optind;")
    a
  end
end

def option(name1, name2 = nil, &b)
  long = short = nil
  if name1 =~ /^--/ || name1.length >= 2
    long, short = name1, name2
  elsif !name2.nil? && (name2 =~ /^--/ || name2.length >= 2)
    long, short = name2, name1
  else
    long, short = nil, name1
  end

  long.gsub!(/^--/, "") unless long.nil?
  short.gsub!(/^-/, "") unless short.nil?
  o = Option.new(long, short)
  $options.each { |lo| 
    if (!long.nil? && lo.long == long) || (!short.nil? && lo.short == short)
      raise "#{b.source_location.join(":")}: Option #{long}|#{short} conflicts with existing option #{lo.long}|#{lo.short}"
    end
  }
  $options << o
  $target = o
  name  = "Option #{long || ""}|#{short || ""}"
  run_block(name, b)
  $target = NoTarget.new
  begin
    o.check
  rescue => e
    raise "#{b.source_location.join(":")}: #{e.message}"
  end
end

def arg(name, &b)
  a = Arg.new(name)
  $args.any? { |la| la.name == name } and
    raise "#{b.source_location.join(":")}: Arg '#{name}' already exists"
  $args << a
  $target = a
  name = "Arg #{name}"
  run_block(name, b)
  $target = NoTarget.new
  begin
    a.check
  rescue => e
    raise "#{b.source_location.join(":")}: #{e.message}"
  end
end
