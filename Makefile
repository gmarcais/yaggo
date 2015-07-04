prefix ?= /usr/local

all: bin/create_yaggo_one_file
	ruby bin/create_yaggo_one_file ./yaggo

install: all
	mkdir -p $(prefix)/bin
	mkdir -p $(prefix)/share/doc/yaggo
	mkdir -p $(prefix)/share/man/man1
	cp ./yaggo $(prefix)/bin
	cp ./README.md $(prefix)/share/doc/yaggo
	./yaggo -m $(prefix)/share/man/man1/yaggo.1
