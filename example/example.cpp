#include <iostream>
#include "example_args.hpp"

int main(int argc, char *argv[]) {
  example_args args(argc, argv);

  std::cout << "Integer switch: " << args.int_arg << "\n";
  if(args.string_given)
    std::cout << "Number of string(s): " << args.string_arg.size() << "\n";
  else
    std::cout << "No string switch\n";
  std::cout << "Flag is " << (args.flag_flag ? "on" : "off") << "\n";
  std::cout << "First arg: " << args.first_arg << "\n";
  std::cout << "Rest:";
  for(example_args::rest_arg_it it = args.rest_arg.begin(); it != args.rest_arg.end(); ++it)
    std::cout << " " << *it;
  std::cout << std::endl;

  return 0;
}
