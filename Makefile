CC ?= gcc
CC_BIN := $(firstword $(CC))
CPPFLAGS ?=
CFLAGS ?= -std=c11 -O2 -Wall -Wextra -pedantic
LDFLAGS ?=

TARGET := matrix
SRC := matrix.c

PREFIX ?= ~
BINDIR ?= $(PREFIX)/bin

PKG_NAME ?= $(TARGET)
PKG_VERSION ?= 1.0.0
PKG_ARCH ?= $(shell dpkg --print-architecture 2>/dev/null || echo amd64)
PKG_MAINTAINER ?= KorotaevGV
PKG_DIR := build/$(PKG_NAME)_$(PKG_VERSION)_$(PKG_ARCH)
PKG_FILE := dist/$(PKG_NAME)_$(PKG_VERSION)_$(PKG_ARCH).deb

.PHONY: all clean run install deb deb-build check-toolchain

all: check-toolchain $(TARGET)

check-toolchain:
	@command -v "$(CC_BIN)" >/dev/null 2>&1 || { \
		echo "Компилятор не найден."; \
		exit 1; \
	}
	@printf '#include <stdio.h>\nint main(void){return 0;}\n' | \
	"$(CC)" -x c - -o /dev/null >/dev/null 2>&1 || { \
		echo "Библиотеки не найдены."; \
		exit 1; \
	}

$(TARGET): $(SRC)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $<

run: all
	./$(TARGET)

install: $(TARGET)
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 0755 "$(TARGET)" "$(DESTDIR)$(BINDIR)/$(TARGET)"

deb-build: all
	@command -v dpkg-deb >/dev/null 2>&1 || { \
		echo "dpkg-deb не найдено. Установите dpkg-dev."; \
		exit 1; \
	}
	rm -rf "$(PKG_DIR)"
	install -d "$(PKG_DIR)/DEBIAN" "$(PKG_DIR)/usr/bin" "dist"
	install -m 0755 "$(TARGET)" "$(PKG_DIR)/usr/bin/$(TARGET)"
	@printf "Package: $(PKG_NAME)\nVersion: $(PKG_VERSION)\nSection: utils\nPriority: optional\nArchitecture: $(PKG_ARCH)\nDepends: glibc\nMaintainer: $(PKG_MAINTAINER)\nDescription: Matrix analyzer\n Checks if a matrix is a Latin square.\n" > "$(PKG_DIR)/DEBIAN/control"
	dpkg-deb --build --root-owner-group "$(PKG_DIR)" "$(PKG_FILE)"
	@echo "Created $(PKG_FILE)"

deb:
	@command -v apt-get >/dev/null 2>&1 || { \
		echo "apt-get не найдено."; \
		exit 1; \
	}
	sudo apt update && sudo apt-get install -y build-essential dpkg-dev
	$(MAKE) deb-build
	sudo apt-get install "./$(PKG_FILE)"

clean:
	rm -f "$(TARGET)"
	rm -rf "build" "dist"