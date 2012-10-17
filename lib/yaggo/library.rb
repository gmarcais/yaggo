def output_library_header file
  open(file, "w") do |fd|
    fd.puts(<<EOS)
/* Copyright (c) 2011 Guillaume Marcais
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef __YAGGO_HPP__
#define __YAGGO_HPP__

#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <errno.h>
#include <string.h>
#include <stdexcept>
#include <string>
#include <limits>
#include <vector>
#include <iostream>
#include <sstream>

namespace yaggo {
  class string : public std::string {
  public:
    string() : std::string() {}
    string(const std::string &s) : std::string(s) {}
    string(const char *s) : std::string(s) {}
    int as_enum(const char* const strs[]);

EOS

      [:uint32, :uint64, :int32, :int64, :int, :long, :double].each do |type|
        fd.puts(<<EOS)
    #{$type_to_C_type[type]} as_#{type}_suffix() const { return as_#{type}(true); }
    #{$type_to_C_type[type]} as_#{type}(bool si_suffix = false) const;
EOS
      end
      fd.puts(<<EOS)
  };

  bool adjust_double_si_suffix(double &res, const char *unit);
  double conv_double(const char *str, std::string &err, bool si_suffix);
  int conv_enum(const char* str, std::string& err, const char* const strs[]);

  template<typename T>
  static bool adjust_int_si_suffix(T &res, const char *suffix) {
    if(*suffix == '\\0')
      return true;
    if(*(suffix + 1) != '\\0')
      return false;

    switch(*suffix) {
    case 'k': res *= (T)1000; break;
    case 'M': res *= (T)1000000; break;
    case 'G': res *= (T)1000000000; break;
    case 'T': res *= (T)1000000000000; break;
    case 'P': res *= (T)1000000000000000; break;
    case 'E': res *= (T)1000000000000000000; break;
    default: return false;
    }
    return true;
  }

  template<typename T>
  static T conv_int(const char *str, std::string &err, bool si_suffix) {
    char *endptr = 0;
    errno = 0;
    long long int res = strtoll(str, &endptr, 0);
    if(errno) {
      err.assign(strerror(errno));
      return (T)0;
    }
    bool invalid = 
      si_suffix ? !adjust_int_si_suffix(res, endptr) : *endptr != '\\0';
    if(invalid) {
      err.assign("Invalid character");
      return (T)0;
    }
    if(res > std::numeric_limits<T>::max() || 
       res < std::numeric_limits<T>::min()) {
      err.assign("Value out of range");
      return (T)0;
    }
    return (T)res;
  }

  template<typename T>
  static T conv_uint(const char *str, std::string &err, bool si_suffix) {
    char *endptr = 0;
    errno = 0;
    while(isspace(*str)) { ++str; }
    if(*str == '-') {
      err.assign("Negative value");
      return (T)0;
    }
    unsigned long long int res = strtoull(str, &endptr, 0);
    if(errno) {
      err.assign(strerror(errno));
      return (T)0;
    }
    bool invalid =
      si_suffix ? !adjust_int_si_suffix(res, endptr) : *endptr != '\\0';
    if(invalid) {
      err.assign("Invalid character");
      return (T)0;
    }
    if(res > std::numeric_limits<T>::max() || 
       res < std::numeric_limits<T>::min()) {
      err.assign("Value out of range");
      return (T)0;
    }
    return (T)res;
  }

  template<typename T>
  static std::string vec_str(const std::vector<T> &vec) {
    std::ostringstream os;
    for(typename std::vector<T>::const_iterator it = vec.begin();
        it != vec.end(); ++it) {
      if(it != vec.begin())
        os << ",";
      os << *it;
    }
    return os.str();
  }
  
}

#endif
EOS
    end
  end
    
def output_library_code file
  open(file, "w") do |fd|
    fd.puts(<<EOS)
/* Copyright (c) 2011 Guillaume Marcais
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#include #{$inc_path}

namespace yaggo {
EOS

    [:uint32, :uint64, :int32, :int64, :int, :long, :double].each do |type|
      fd.puts(<<EOS)
  #{$type_to_C_type[type]} string::as_#{type}(bool si_suffix) const {
    std::string err;
    #{$type_to_C_type[type]} res = #{str_conv("this->c_str()", type, "si_suffix")};
    if(!err.empty()) {
      std::string msg("Invalid conversion of '");
      msg += *this;
      msg += "' to #{type}_t: ";
      msg += err;
      throw std::runtime_error(msg);
    }
    return res;
  }

EOS
    end

    fd.puts(<<EOS)
  int string::as_enum(const char* const strs[]) {
    std::string err;
    int res = #{str_conv("this->c_str()", :enum, "strs")};
    if(!err.empty())
      throw std::runtime_error(err);
    return res;
  }

  bool adjust_double_si_suffix(double &res, const char *suffix) {
    if(*suffix == '\\0')
      return true;
    if(*(suffix + 1) != '\\0')
      return false;

    switch(*suffix) {
    case 'a': res *= 1e-18; break;
    case 'f': res *= 1e-15; break;
    case 'p': res *= 1e-12; break;
    case 'n': res *= 1e-9;  break;
    case 'u': res *= 1e-6;  break;
    case 'm': res *= 1e-3;  break;
    case 'k': res *= 1e3;   break;
    case 'M': res *= 1e6;   break;
    case 'G': res *= 1e9;   break;
    case 'T': res *= 1e12;  break;
    case 'P': res *= 1e15;  break;
    case 'E': res *= 1e18;  break;
    default: return false;
    }
    return true;
  }

  double conv_double(const char *str, std::string &err, bool si_suffix) {
    char *endptr = 0;
    errno = 0;
    double res = strtod(str, &endptr);
    if(errno) {
      err.assign(strerror(errno));
      return (double)0.0;
    }
    bool invalid =
      si_suffix ? !adjust_double_si_suffix(res, endptr) : *endptr != '\\0';
    if(invalid) {
      err.assign("Invalid character");
      return (double)0.0;
    }
    return res;
  }

  int conv_enum(const char* str, std::string& err, const char* const strs[]) {
    int res = 0;
    for(const char* const* cstr = strs; *cstr; ++cstr, ++res)
      if(!strcmp(*cstr, str))
        return res;
    err += "Invalid constant '";
    err += str;
    err += "'. Expected one of { ";
    for(const char* const* cstr = strs; *cstr; ++cstr) {
      if(cstr != strs)
        err += ", ";
      err += *cstr;
    }
    err += " }";
    return -1;
  }
}
EOS
  end
end
