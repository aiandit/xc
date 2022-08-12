
PREFIX = /var/lib/ai-and-it

PKGNAME = xc

all:

install-all: configure-system

install:
	@echo PWD=$(shell pwd)
	mkdir -p $(DESTDIR)$(PREFIX)
	rm -rf $(DESTDIR)$(PREFIX)/$(PKGNAME)
	git clone $(shell pwd) $(DESTDIR)$(PREFIX)/$(PKGNAME)

configure-system: install
	$(DESTDIR)$(PREFIX)/$(PKGNAME)/ci/config-system.sh

update:

uninstall:

check:
