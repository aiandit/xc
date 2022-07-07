
PREFIX = /opt/ai-and-it-test

PKGNAME = xc

all:

install:
	@echo PWD=$(shell pwd)
	mkdir -p $(DESTDIR)$(PREFIX)
	rm -rf $(DESTDIR)$(PREFIX)/$(PKGNAME)
	git clone $(shell pwd) $(DESTDIR)$(PREFIX)/$(PKGNAME)
	$(DESTDIR)$(PREFIX)/$(PKGNAME)/ci/config-system.sh

update:

uninstall:

check:
