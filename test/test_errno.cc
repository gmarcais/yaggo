#include <iostream>
#include "test_errno.hpp"

int main(int argc, char *argv[])
{
  args_t args(argc, argv);

  if(argc > 1)
    args_t::error() << "Error" << args_t::error::no;

  return 0;
}
