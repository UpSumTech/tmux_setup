############ Goals ############
.DEFAULT_GOAL := run

############ Vars and functions #############
THIS_FILE = $(lastword $(MAKEFILE_LIST))

DEBUG := off
AT_off := @
AT_on :=
AT = $(AT_$(DEBUG))

GROUP :=

UNAME = $(shell uname -s)
TMUX_EXISTS = $(shell tmux -V 2>/dev/null)

############ PHONY tasks #############
.PHONY: install \
	run \
	stop \
	install-linux \
	install-mac

########### Public targets ############
install:
ifndef TMUX_EXISTS
ifeq ($(UNAME),Linux)
	$(AT)$(MAKE) -f $(THIS_FILE) install-linux
else ifeq ($(UNAME),Darwin)
	echo "wtf"
	$(AT)$(MAKE) -f $(THIS_FILE) install-mac
endif
endif

run: install
	$(AT)tmux start-server
	$(AT)./bin/run.sh -s $(GROUP)

stop:
	$(AT)./bin/run.sh -k $(GROUP)
	$(AT)tmux kill-server

########### Private targets ############

install-linux:
	$(AT)sudo apt-get install tmux
	$(AT)sudo apt-get install jq

install-mac:
	$(AT)brew install tmux
	$(AT)brew install jq
