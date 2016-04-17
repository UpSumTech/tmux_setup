############ Goals ############
.DEFAULT_GOAL := install

############ Vars and functions #############
THIS_FILE = $(lastword $(MAKEFILE_LIST))

DEBUG := off
AT_off := @
AT_on :=
AT = $(AT_$(DEBUG))

UNAME = $(shell uname -s)
TMUX_EXISTS = $(shell tmux -V 2>/dev/null)

############ PHONY tasks #############
.PHONY: install \
	install-linux \
	install-mac

########### Public targets ############
install:
ifndef TMUX_EXISTS
ifeq ($(UNAME),Linux)
	$(AT)$(MAKE) -f $(THIS_FILE) install-linux
else ifeq ($(UNAME),Darwin)
	$(AT)$(MAKE) -f $(THIS_FILE) install-mac
endif
endif

########### Private targets ############

install-linux:
	$(AT)sudo apt-get install -y python-software-properties software-properties-common
	$(AT)sudo add-apt-repository -y ppa:pi-rho/dev
	$(AT)sudo apt-get update
	$(AT)sudo apt-get install tmux
	$(AT)sudo apt-get install jq

install-mac:
	$(AT)brew install tmux
	$(AT)brew install jq
