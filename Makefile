prefix ?= /usr/local

all: bin/create_yaggo_one_file
	ruby bin/create_yaggo_one_file ./yaggo

install: all
	mkdir -p $(DESTDIR)$(prefix)/bin
	mkdir -p $(DESTDIR)$(prefix)/share/doc/yaggo
	mkdir -p $(DESTDIR)$(prefix)/share/man/man1
	cp ./yaggo $(DESTDIR)$(prefix)/bin
	cp ./README.md $(DESTDIR)$(prefix)/share/doc/yaggo
	./yaggo -m $(DESTDIR)$(prefix)/share/man/man1/yaggo.1
