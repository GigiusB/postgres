.PHONY: help b10 b11 b12 b13 c12 p12 r10 r11 r12 r13
.DEFAULT_GOAL := help

SHELL := /bin/bash

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+[0-9]*):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

.clean:
	@echo "Cleaning ${VER}"
	sed -i '/\s\+\*\.conf) echo \".*$$/d' ${VER}/docker-entrypoint.sh ;
	sed -i '/\s\+\*\.conf) echo \".*$$/d' ${VER}/alpine/docker-entrypoint.sh ;

.prepare:
	@echo "Preparing ${VER}"
	@if [ `grep '\*\.conf) echo ' ${VER}/docker-entrypoint.sh | wc -l` -eq 0 ]; then \
		echo "Modifying entrypoint" ; \
		sed -i '/\t\t\t\*.sql.xz.*/a \\t\t\t\*.conf) echo "$$0: replacing conf $$f"; cp "$$f" "$$PGDATA"; echo ;;' ${VER}/docker-entrypoint.sh ; \
	fi
	@if [ `grep '\*\.conf) echo ' ${VER}/alpine/docker-entrypoint.sh | wc -l` -eq 0 ]; then \
		echo "Modifying alpine entrypoint" ; \
		sed -i '/\t\t\t\*.sql.xz.*/a \\t\t\t\*.conf) echo "$$0: replacing conf $$f"; cp "$$f" "$$PGDATA"; echo ;;' ${VER}/alpine/docker-entrypoint.sh ; \
	fi

.zap:
	@-docker rmi $$(docker images -f "reference=gigiusb/postgres:*" -q)
	@-docker rmi $$(docker images -f "dangling=true" -q)

.build: .prepare
	@echo "Building ${VER}"
	@cd ${VER} && docker build -t gigiusb/postgres:${VER} .
	@cd ${VER}/alpine && docker build -t gigiusb/postgres:${VER}-alpine .

.release:
	pass dockerhub/gigiusb | docker login -u gigiusb --password-stdin
	docker push gigiusb/postgres:${VER}
	docker push gigiusb/postgres:${VER}-alpine

p12:  ## Prepares version 12
	VER=12 $(MAKE) .prepare

b10:  ## Builds version 10
	VER=10 $(MAKE) .build

b11:  ## Builds version 11
	VER=11 $(MAKE) .build

b12:  ## Builds version 12
	VER=12 $(MAKE) .build

b13:  ## Builds version 13
	VER=13 $(MAKE) .build

r10: b10  ## Builds and releases version 10
	VER=10 $(MAKE) .build

r11: b11  ## Builds and releases version 11
	VER=11 $(MAKE) .release

r12: b12  ## Builds and releases version 12
	VER=12 $(MAKE) .release

r13: b13  ## Builds and releases version 13
	VER=13 $(MAKE) .release

c12:  ## Cleans version 12
	VER=12 $(MAKE) .clean
