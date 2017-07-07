CC = g++
CPPFLAGS = -I. -Wall -Werror
CXXFLAGS = -O2
YAGGO = ../bin/yaggo
RY = ruby -I../lib $(YAGGO)

all: count

count: count.o
count_cmdline.hpp _count: count_cmdline.yaggo $(YAGGO)
	$(RY) --debug --zc _count $<
count.o: count.cpp count_cmdline.hpp

# test_errno.hpp: test_errno.yaggo $(YAGGO)
# 	$(RY) --debug $<
# test_errno: test_errno.o
# test_errno.o: test_errno.cc test_errno.hpp

clean:
	rm -f *.o count *_cmdline.hpp
