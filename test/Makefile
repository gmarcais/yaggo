CC = g++
CPPFLAGS = -I. -Wall -Werror
CXXFLAGS = -O2

all: count

count: count.o yaggo.o
yaggo.cpp yaggo.hpp: ../yaggo
	../yaggo --lib
count_cmdline.hpp _count: count.yaggo ../yaggo
	../yaggo --debug --zc _count $<
count.o: count.cpp count_cmdline.hpp yaggo.hpp
clean:
	rm -f *.o count
