CC = g++
CPPFLAGS = -I. -Wall -Werror
CXXFLAGS = -O2
YAGGO = ../bin/yaggo
RY = ruby -I../lib $(YAGGO)

all: count

count: count.o yaggo.o
yaggo.cpp yaggo.hpp: $(YAGGO)
	$(RY) --lib
count_cmdline.hpp _count: count.yaggo $(YAGGO)
	$(RY) --debug --zc _count $<
count.o: count.cpp count_cmdline.hpp yaggo.hpp
clean:
	rm -f *.o count
