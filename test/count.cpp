#include <iostream>
#include "count_cmdline.hpp"

#define CONV(type)                                                      \
  try {                                                                 \
    std::cout << "as_" << #type << ": "                                 \
              << args.verra_arg.as_ ## type () << std::endl;            \
  } catch(std::exception &e) {                                           \
    std::cerr << "Conv to " << #type << " failed: "                     \
              << e.what() << std::endl;                                  \
  }


int main(int argc, char *argv[])
{
  count_cmdline args(argc, argv);
  args.dump(std::cout);
  CONV(uint32);
  CONV(uint64);
  CONV(int32);
  CONV(int64);
  CONV(double);
  if(args.severity_arg == count_cmdline::low)
    std::cout << "Pfiou!\n";
  try {
    std::cout << args.verra_arg.as_enum(count_cmdline::severity_strs) << "\n";
  } catch(std::exception& e) {
    std::cerr << "Conv to enum failed: " << e.what() << std::endl;
  }
  return 0;
}
