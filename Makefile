# name to install as
name = bashenv

# the install location
prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

########################################

INSTALL = $(shell which install)
INSTALL_SCRIPT = $(INSTALL)

BIN_MODE = 755

SRC = bashenv
DST = $(bindir)/$(name)

########################################


.PHONY: all
all: help

.PHONY: help
help:
	@echo "Run 'make install' as root to install 'bashenv',"
	@echo "the optional management tool."
	@echo ""
	@echo "      $ make install"
	@echo ""
	@echo "By defailt, it will be installed into: "
	@echo ""
	@echo "      bindir=$(bindir)"
	@echo ""
	@echo "The install location can easily be changed by"
	@echo "setting one of the GNU-autotools-style variables"
	@echo "at the top of this Makefile."
	@echo ""
	@echo "Optionally, instead of installing into $(bindir),"
	@echo "You could simply alias the the script in your .bashrc"
	@echo ""
	@echo '      alias bashenv="$HOME/some/path/to/bashenv"'
	@echo ""
	@echo ""


install:
	$(INSTALL_SCRIPT) --mode=$(BIN_MODE) $(SRC) $(DST)

uninstall:
	echo $(BINS)
	rm -f $(DST)
