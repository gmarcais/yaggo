# What is yaggo?

Yaggo is a tool to generate command line parsers for C++. Yaggo stands
for "Yet Another GenGetOpt" and is inspired by [GNU Gengetopt](https://www.gnu.org/software/gengetopt/gengetopt.html).

It reads a configuration file describing the switches and argument for
a C++ program and it generates one header file that parses the command
line using getopt_long(3). See the Example section below for more details.

# Installation

## Quick and easy

Download the standalone script called `yaggo` from the [release](https://github.com/gmarcais/yaggo/releases)
and copy it into a directory in your PATH (e.g. `~/bin`)

From the source tree, the same is achieved with:

```Shell
make install prefix=$HOME/bin
```

## As a gem

Install directly with the gem command:
```Shell
gem install yaggo
```
(Use the `--user-install` to install in your home instead of globally).

Alternatively, download the gem from the [release](https://github.com/gmarcais/yaggo/releases) and install it
with `sudo gem install ./yaggo-x.x.x.gem` (adjust the version!).

Similarly, from the source tree, first generate the gem
and then install it. For example:

```Shell
rake gem
sudo gem install ./pkg/yaggo-x.x.x.gem
```

# Documentation

After installation, documentation is available with `yaggo --man`.

# Simple example

Given the following configuration file 'parser.yaggo':

```Ruby
purpose "Demonstrate yaggo capabilities"
description "This simple configuration file shows some of the capabilities of yaggo.
This is supposed to be a longer description of the program.
"

option("f", "flag") {
  description "This is a flag"
  off
}
option("i", "int") {
  description "This take an integer"
  int
  default 20
}
arg("path") {
  description "Path to file"
  c_string
}
```

The following C++ program ('parser.cc') does switch parsing, generate
appropriate errors and has an automatically generated help (accessible
with '-h' or '--help').

```C
#include <iostream>
#include "parser.hpp"

int main(int argc, char* argv[]) {
  parser args(argc, argv); // Does all the parsing

  std::cout << "--flag " << (args.flag_flag ? "not passed" : "passed") << "\n"
            << "--int: " << args.int_arg << "\n"
            << "path: " << args.path_arg << "\n";

  return 0;
}
```

All of this is compiled with:

```Shell
yaggo parser.yaggo
g++ -o parser parser.cc
```

Then, './parser --help' returns:

```
Usage: parser [options] path:string

Demonstrate yaggo capabilities

This simple configuration file shows some of the capabilities of yaggo.
This is supposed to be a longer description of the program.

Options (default value in (), *required):
 -f, --flag                               This is a flag (false)
 -i, --int=int                            This take an integer (20)
 -U, --usage                              Usage
 -h, --help                               This message
 -V, --version                            Version
```
