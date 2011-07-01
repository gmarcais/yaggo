CC = g++
CPPFLAGS = -Wall -Werror
CXXFLAGS = -O2

all: count

count: count.o
count_cmdline.hpp: count.yaggo ../yaggo
	../yaggo $< > $@
count.o: count.cpp count_cmdline.hpp
